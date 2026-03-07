import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable, throwError, BehaviorSubject } from 'rxjs';
import { catchError, tap, map } from 'rxjs/operators';
import { environment } from '../../environments/environment';

export interface DocumentoMedico {
  id: number;
  paciente_id: number;
  subido_por: number;
  tipo_documento: 'laboratorio' | 'rayos_x' | 'receta_externa' | 'historial' | 'notas_clinicas' | 'otro';
  nombre_archivo: string;
  ruta_archivo: string;
  mime_type: string;
  tamano_bytes: number;
  tamano_legible?: string;
  texto_extraido?: string;
  estatus_procesamiento: 'pendiente' | 'procesando' | 'completado' | 'error';
  datos_extraidos?: any;
  created_at: string;
  updated_at: string;
  paciente?: {
    id: number;
    nombre: string;
    apellido: string;
    email: string;
  };
  subido_por_user?: {
    id: number;
    nombre: string;
    apellido: string;
  };
  analisis_ia?: AnalisisIA;
  url?: string;
}

export interface AnalisisIA {
  id: number;
  documento_id: number;
  documento?: {
    id: number;
    paciente_id: number;
    paciente?: {
      id: number;
      nombre: string;
      apellido: string;
      email: string;
    };
    nombre_archivo: string;
    tipo_documento: string;
    tamano_bytes?: number;
    url?: string;
  };
  estatus: string;
  datos_detectados: {
    [key: string]: {
      valor: string;
      unidad: string;
      rango_normal: string;
      estado: 'normal' | 'alto' | 'bajo' | 'no_evaluable';
    }
  };
  diagnostico_sugerido: string;
  descripcion_analisis: string;
  nivel_confianza: number;
  palabras_clave_detectadas: string[];
  validado_por?: number;
  estatus_validacion: 'pendiente' | 'aprobado' | 'rechazado' | 'corregido';
  comentario_doctor?: string;
  diagnostico_final?: string;
  fecha_validacion?: string;
  doctor_validador?: {
    id: number;
    nombre: string;
    apellido: string;
  };
  created_at: string;
  updated_at: string;
}

export interface ValidacionRequest {
  accion: 'aprobar' | 'rechazar' | 'corregir';
  diagnostico_final?: string;
  comentario?: string;
}

@Injectable({
  providedIn: 'root'
})
export class DocumentoMedicoService {
  private apiUrl = environment.apiUrl + '/documentos';
  private analisisUrl = environment.apiUrl + '/analisis-ia';

  constructor(private http: HttpClient) {}

  // ============ DOCUMENTOS ============

  getDocumentos(pacienteId?: number, tipo?: string, estatus?: string): Observable<any> {
    let params = new HttpParams();
    
    if (pacienteId) {
      params = params.set('paciente_id', pacienteId.toString());
    }
    if (tipo) {
      params = params.set('tipo', tipo);
    }
    if (estatus) {
      params = params.set('estatus', estatus);
    }

    return this.http.get(`${this.apiUrl}`, { params }).pipe(
      catchError(this.handleError)
    );
  }

  getDocumento(id: number): Observable<DocumentoMedico> {
    return this.http.get<DocumentoMedico>(`${this.apiUrl}/${id}`).pipe(
      catchError(this.handleError)
    );
  }

  subirDocumento(formData: FormData): Observable<any> {
    return this.http.post(`${this.apiUrl}`, formData).pipe(
      tap(response => console.log('Documento subido:', response)),
      catchError(this.handleError)
    );
  }

  descargarDocumento(id: number): Observable<Blob> {
    return this.http.get(`${this.apiUrl}/${id}/download`, {
      responseType: 'blob'
    }).pipe(
      catchError(this.handleError)
    );
  }

  eliminarDocumento(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${id}`).pipe(
      catchError(this.handleError)
    );
  }

  reprocesarDocumento(id: number): Observable<any> {
    return this.http.post(`${this.apiUrl}/${id}/reprocesar`, {}).pipe(
      catchError(this.handleError)
    );
  }

  // ============ ANÁLISIS IA ============

  getPendientesValidacion(): Observable<any> {
    return this.http.get(`${this.analisisUrl}/pendientes`).pipe(
      catchError(this.handleError)
    );
  }

  validarDiagnostico(analisisId: number, data: ValidacionRequest): Observable<any> {
    return this.http.post(`${this.analisisUrl}/${analisisId}/validar`, data).pipe(
      tap(response => console.log('Validación enviada:', response)),
      catchError(this.handleError)
    );
  }

  getEstadisticas(): Observable<any> {
    return this.http.get(`${this.analisisUrl}/estadisticas`).pipe(
      catchError(this.handleError)
    );
  }

  // ============ UTILIDADES ============

  private handleError(error: any) {
    console.error('Error en servicio de documentos:', error);
    
    let errorMessage = 'Ha ocurrido un error';
    
    if (error.error instanceof ErrorEvent) {
      // Error del lado del cliente
      errorMessage = error.error.message;
    } else if (error.error?.message) {
      // Error del servidor
      errorMessage = error.error.message;
    } else if (error.error?.errors) {
      // Errores de validación
      const validationErrors = Object.values(error.error.errors).flat();
      errorMessage = validationErrors.join(', ');
    }
    
    return throwError(() => new Error(errorMessage));
  }

  // Helper para descargar archivo
  descargarArchivo(blob: Blob, nombreArchivo: string) {
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = nombreArchivo;
    document.body.appendChild(a);
    a.click();
    window.URL.revokeObjectURL(url);
    document.body.removeChild(a);
  }

  // Helper para obtener badge color según estatus
  getBadgeColor(estatus: string): string {
    const colores: { [key: string]: string } = {
      'pendiente': 'bg-yellow-100 text-yellow-800',
      'procesando': 'bg-blue-100 text-blue-800',
      'completado': 'bg-green-100 text-green-800',
      'error': 'bg-red-100 text-red-800',
    };
    return colores[estatus] || 'bg-gray-100 text-gray-800';
  }

  // Helper para obtener badge de validación
  getBadgeValidacion(estatus: string): { texto: string; clase: string } {
    const badges: { [key: string]: { texto: string; clase: string } } = {
      'pendiente': { texto: 'Pendiente', clase: 'bg-gray-100 text-gray-800' },
      'aprobado': { texto: 'Aprobado', clase: 'bg-green-100 text-green-800' },
      'rechazado': { texto: 'Rechazado', clase: 'bg-red-100 text-red-800' },
      'corregido': { texto: 'Corregido', clase: 'bg-blue-100 text-blue-800' },
    };
    return badges[estatus] || { texto: 'Desconocido', clase: 'bg-gray-100' };
  }
}
