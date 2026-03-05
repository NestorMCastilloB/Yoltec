<?php

namespace App\Http\Controllers;

use App\Models\DocumentoMedico;
use App\Models\AnalisisDocumentoIA;
use App\Models\User;
use App\Services\DocumentAnalyzerIAService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

/**
 * Controller para gestión de documentos médicos y análisis de IA
 */
class DocumentoMedicoController extends Controller
{
    protected $iaService;

    public function __construct(DocumentAnalyzerIAService $iaService)
    {
        $this->iaService = $iaService;
    }

    /**
     * Listar documentos de un paciente (acceso: doctor, admin, o el mismo paciente)
     */
    public function index(Request $request)
    {
        $user = $request->user();
        $pacienteId = $request->query('paciente_id');

        // Verificar permisos
        if (!$this->puedeVerDocumentos($user, $pacienteId)) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $query = DocumentoMedico::with(['subidoPor', 'analisisIa']);

        // Si es paciente, solo ve sus documentos
        if ($user->esAlumno()) {
            $query->where('paciente_id', $user->id);
        } elseif ($pacienteId) {
            $query->where('paciente_id', $pacienteId);
        }

        // Filtros opcionales
        if ($request->has('tipo')) {
            $query->where('tipo_documento', $request->tipo);
        }

        if ($request->has('estatus')) {
            $query->where('estatus_procesamiento', $request->estatus);
        }

        $documentos = $query->orderBy('created_at', 'desc')->paginate(20);

        return response()->json([
            'data' => $documentos,
            'message' => 'Documentos obtenidos exitosamente'
        ], 200);
    }

    /**
     * Subir nuevo documento médico (acceso: doctor, admin)
     */
    public function store(Request $request)
    {
        $user = $request->user();

        // Solo doctores y admins pueden subir documentos
        if (!$user->esDoctor() && !$user->esAdmin()) {
            return response()->json(['message' => 'Solo doctores y administradores pueden subir documentos'], 403);
        }

        $validator = Validator::make($request->all(), [
            'paciente_id' => 'required|exists:users,id',
            'tipo_documento' => 'required|in:laboratorio,rayos_x,receta_externa,historial,notas_clinicas,otro',
            'documento' => 'required|file|mimes:pdf,doc,docx|max:10240', // Máximo 10MB
            'notas' => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $paciente = User::find($request->paciente_id);

        // Verificar que el usuario destino sea un paciente (alumno)
        if (!$paciente->esAlumno()) {
            return response()->json(['message' => 'El usuario seleccionado no es un paciente'], 400);
        }

        try {
            // Subir archivo
            $archivo = $request->file('documento');
            $nombreOriginal = $archivo->getClientOriginalName();
            $extension = $archivo->getClientOriginalExtension();
            
            // Generar nombre único
            $nombreUnico = time() . '_' . uniqid() . '.' . $extension;
            $ruta = $archivo->storeAs('documentos_medicos/' . $paciente->id, $nombreUnico, 'private');

            // Extraer texto del documento
            $textoExtraido = $this->extraerTextoDocumento($archivo, $extension);

            // Crear registro en BD
            $documento = DocumentoMedico::create([
                'paciente_id' => $request->paciente_id,
                'subido_por' => $user->id,
                'tipo_documento' => $request->tipo_documento,
                'nombre_archivo' => $nombreOriginal,
                'ruta_archivo' => $ruta,
                'mime_type' => $archivo->getMimeType(),
                'tamano_bytes' => $archivo->getSize(),
                'texto_extraido' => $textoExtraido,
                'estatus_procesamiento' => 'pendiente',
            ]);

            // Procesar con IA (puede ser asíncrono en producción)
            try {
                $analisis = $this->iaService->analizarDocumento($documento);
            } catch (\Exception $e) {
                \Log::error('Error en análisis IA: ' . $e->getMessage());
                // El documento se guarda igual aunque falle la IA
            }

            return response()->json([
                'message' => 'Documento subido y procesado exitosamente',
                'documento' => $documento->load('analisisIa'),
                'analisis_ia' => $analisis ?? null,
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Error al procesar documento',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Ver documento específico
     */
    public function show(Request $request, $id)
    {
        $user = $request->user();
        $documento = DocumentoMedico::with(['paciente', 'subidoPor', 'analisisIa.doctorValidador'])->findOrFail($id);

        if (!$this->puedeVerDocumento($user, $documento)) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        // Registrar acceso en auditoría (si está implementado)
        $this->registrarAcceso($user, $documento, 'view');

        return response()->json([
            'documento' => $documento,
            'url_descarga' => $documento->url,
        ], 200);
    }

    /**
     * Descargar archivo
     */
    public function download(Request $request, $id)
    {
        $user = $request->user();
        $documento = DocumentoMedico::findOrFail($id);

        if (!$this->puedeVerDocumento($user, $documento)) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $this->registrarAcceso($user, $documento, 'download');

        return Storage::disk('private')->download($documento->ruta_archivo, $documento->nombre_archivo);
    }

    /**
     * Validar diagnóstico sugerido por IA (solo doctores)
     */
    public function validarDiagnostico(Request $request, $analisisId)
    {
        $user = $request->user();

        // Solo doctores pueden validar
        if (!$user->esDoctor() && !$user->esAdmin()) {
            return response()->json(['message' => 'Solo doctores pueden validar diagnósticos'], 403);
        }

        $validator = Validator::make($request->all(), [
            'accion' => 'required|in:aprobar,rechazar,corregir',
            'diagnostico_final' => 'required_if:accion,corregir|string|max:500',
            'comentario' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $analisis = AnalisisDocumentoIA::findOrFail($analisisId);

        // Mapear acción a estatus
        $mapeoEstatus = [
            'aprobar' => 'aprobado',
            'rechazar' => 'rechazado',
            'corregir' => 'corregido',
        ];

        $datosUpdate = [
            'estatus_validacion' => $mapeoEstatus[$request->accion],
            'validado_por' => $user->id,
            'fecha_validacion' => now(),
            'comentario_doctor' => $request->comentario,
        ];

        if ($request->accion === 'corregir' && $request->diagnostico_final) {
            $datosUpdate['diagnostico_final'] = $request->diagnostico_final;
        }

        $analisis->update($datosUpdate);

        return response()->json([
            'message' => 'Diagnóstico validado exitosamente',
            'analisis' => $analisis->fresh(['doctorValidador']),
        ], 200);
    }

    /**
     * Listar análisis pendientes de validación (para doctores)
     */
    public function pendientesValidacion(Request $request)
    {
        $user = $request->user();

        if (!$user->esDoctor() && !$user->esAdmin()) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $pendientes = AnalisisDocumentoIA::with(['documento.paciente', 'documento.subidoPor'])
            ->where('estatus_validacion', 'pendiente')
            ->where('estatus', 'completado')
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json([
            'pendientes' => $pendientes,
            'total' => $pendientes->total(),
        ], 200);
    }

    /**
     * Reprocesar documento con IA (si falló o se quiere regenerar)
     */
    public function reprocesar(Request $request, $id)
    {
        $user = $request->user();
        $documento = DocumentoMedico::findOrFail($id);

        // Solo admin o quien subió el documento puede reprocesar
        if (!$user->esAdmin() && $documento->subido_por !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $documento->update(['estatus_procesamiento' => 'procesando']);

        try {
            $analisis = $documento->analisisIa;
            
            if ($analisis) {
                $analisis = $this->iaService->regenerarAnalisis($analisis);
            } else {
                $analisis = $this->iaService->analizarDocumento($documento);
            }

            return response()->json([
                'message' => 'Documento reprocesado exitosamente',
                'analisis' => $analisis,
            ], 200);

        } catch (\Exception $e) {
            $documento->update(['estatus_procesamiento' => 'error']);
            return response()->json([
                'message' => 'Error al reprocesar',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Eliminar documento (solo admin o quien lo subió)
     */
    public function destroy(Request $request, $id)
    {
        $user = $request->user();
        $documento = DocumentoMedico::findOrFail($id);

        if (!$user->esAdmin() && $documento->subido_por !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        // Eliminar archivo físico
        Storage::disk('private')->delete($documento->ruta_archivo);

        // Eliminar registro (cascada eliminará análisis)
        $documento->delete();

        return response()->json(['message' => 'Documento eliminado exitosamente'], 200);
    }

    /**
     * Estadísticas de uso del sistema de IA
     */
    public function estadisticas(Request $request)
    {
        $user = $request->user();

        if (!$user->esAdmin() && !$user->esDoctor()) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $stats = [
            'total_documentos' => DocumentoMedico::count(),
            'procesados' => DocumentoMedico::where('estatus_procesamiento', 'completado')->count(),
            'pendientes' => DocumentoMedico::where('estatus_procesamiento', 'pendiente')->count(),
            'con_error' => DocumentoMedico::where('estatus_procesamiento', 'error')->count(),
            'analisis_completados' => AnalisisDocumentoIA::where('estatus', 'completado')->count(),
            'validados' => AnalisisDocumentoIA::whereIn('estatus_validacion', ['aprobado', 'corregido'])->count(),
            'rechazados' => AnalisisDocumentoIA::where('estatus_validacion', 'rechazado')->count(),
            'por_validar' => AnalisisDocumentoIA::where('estatus_validacion', 'pendiente')->count(),
        ];

        return response()->json(['estadisticas' => $stats], 200);
    }

    // ==================== MÉTODOS PRIVADOS ====================

    /**
     * Verificar si usuario puede ver documentos de un paciente
     */
    private function puedeVerDocumentos($user, $pacienteId): bool
    {
        if ($user->esAdmin()) return true;
        if ($user->esDoctor()) return true;
        if ($user->id == $pacienteId) return true;
        
        return false;
    }

    /**
     * Verificar si usuario puede ver un documento específico
     */
    private function puedeVerDocumento($user, DocumentoMedico $documento): bool
    {
        if ($user->esAdmin()) return true;
        if ($user->esDoctor()) return true;
        if ($user->id === $documento->paciente_id) return true;
        
        return false;
    }

    /**
     * Extraer texto de documentos PDF o Word
     * Nota: En producción, usar librerías como pdftotext, pdfplumber, o Apache Tika
     */
    private function extraerTextoDocumento($archivo, string $extension): ?string
    {
        try {
            // Para PDF - usar pdftotext si está disponible
            if ($extension === 'pdf') {
                return $this->extraerTextoPDF($archivo);
            }
            
            // Para Word - nota: requiere librería como phpoffice/phpword
            if (in_array($extension, ['doc', 'docx'])) {
                return $this->extraerTextoWord($archivo);
            }

            return null;
        } catch (\Exception $e) {
            \Log::error('Error extrayendo texto: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Extraer texto de PDF (versión básica)
     */
    private function extraerTextoPDF($archivo): ?string
    {
        // En producción: usar pdftotext o librería como smalot/pdfparser
        // Para demo: simulamos extracción basica
        
        $tempPath = $archivo->getPathname();
        
        // Intentar usar pdftotext si está instalado
        if (shell_exec('which pdftotext')) {
            $output = shell_exec('pdftotext ' . escapeshellarg($tempPath) . ' - 2>/dev/null');
            return $output ?: null;
        }

        // Fallback: leer como texto plano (funciona para PDFs simples)
        $content = file_get_contents($tempPath);
        
        // Extraer texto entre tags stream...endstream
        if (preg_match_all('/stream\s*(.*?)\s*endstream/s', $content, $matches)) {
            $texto = '';
            foreach ($matches[1] as $stream) {
                // Limpiar contenido binario
                $limpio = preg_replace('/[^\x20-\x7E\s]/', '', $stream);
                if (strlen($limpio) > 10) {
                    $texto .= $limpio . " ";
                }
            }
            return trim($texto) ?: null;
        }

        return null;
    }

    /**
     * Extraer texto de Word
     */
    private function extraerTextoWord($archivo): ?string
    {
        // Requiere: composer require phpoffice/phpword
        // Por ahora, retornamos null o simulación
        
        try {
            // Si está instalado phpword
            if (class_exists('PhpOffice\PhpWord\IOFactory')) {
                $phpWord = \PhpOffice\PhpWord\IOFactory::load($archivo->getPathname());
                $texto = '';
                
                foreach ($phpWord->getSections() as $section) {
                    foreach ($section->getElements() as $element) {
                        if (method_exists($element, 'getText')) {
                            $texto .= $element->getText() . " ";
                        }
                    }
                }
                
                return trim($texto) ?: null;
            }
        } catch (\Exception $e) {
            \Log::error('Error con PHPWord: ' . $e->getMessage());
        }

        // Fallback: intentar leer como XML (docx son zips XML)
        if ($archivo->getClientOriginalExtension() === 'docx') {
            return $this->extraerTextoDocxDirecto($archivo->getPathname());
        }

        return null;
    }

    /**
     * Extraer texto de docx leyendo XML directamente
     */
    private function extraerTextoDocxDirecto(string $path): ?string
    {
        try {
            $zip = new \ZipArchive();
            if ($zip->open($path) === true) {
                $xml = $zip->getFromName('word/document.xml');
                $zip->close();
                
                if ($xml) {
                    // Eliminar tags XML
                    $texto = strip_tags(str_replace('</w:p>', "\n\n", $xml));
                    return trim($texto) ?: null;
                }
            }
        } catch (\Exception $e) {
            \Log::error('Error leyendo docx: ' . $e->getMessage());
        }

        return null;
    }

    /**
     * Registrar acceso en auditoría
     */
    private function registrarAcceso($user, DocumentoMedico $documento, string $accion): void
    {
        // Aquí se integraría con el sistema de AuditLog
        \Log::info('Acceso a documento médico', [
            'user_id' => $user->id,
            'documento_id' => $documento->id,
            'paciente_id' => $documento->paciente_id,
            'accion' => $accion,
            'ip' => request()->ip(),
            'timestamp' => now(),
        ]);
    }
}
