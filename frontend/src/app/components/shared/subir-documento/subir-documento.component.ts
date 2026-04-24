import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { DocumentoMedicoService, DocumentoMedico, AnalisisIA } from '../../../services/documento-medico.service';
import { UserService } from '../../../services/user.service';

@Component({
  selector: 'app-subir-documento',
  templateUrl: './subir-documento.component.html',
  styleUrls: ['./subir-documento.component.css'],
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule]
})
export class SubirDocumentoComponent implements OnInit {
  uploadForm!: FormGroup;
  selectedFile: File | null = null;
  pacientes: any[] = [];
  
  isLoading = false;
  isUploading = false;
  uploadProgress = 0;
  
  // Estados de subida
  uploadSuccess = false;
  uploadError: string | null = null;
  documentoSubido: DocumentoMedico | null = null;
  analisisIA: AnalisisIA | null = null;

  // Tipos de documentos disponibles
  tiposDocumento = [
    { value: 'laboratorio', label: 'Resultados de Laboratorio', icon: '🔬' },
    { value: 'rayos_x', label: 'Rayos X / Imágenes', icon: '🩻' },
    { value: 'receta_externa', label: 'Receta Externa', icon: '💊' },
    { value: 'historial', label: 'Historial Médico', icon: '📋' },
    { value: 'notas_clinicas', label: 'Notas Clínicas', icon: '📝' },
    { value: 'otro', label: 'Otro Documento', icon: '📄' },
  ];

  constructor(
    private fb: FormBuilder,
    private documentoService: DocumentoMedicoService,
    private userService: UserService
  ) {}

  ngOnInit() {
    this.initForm();
    this.cargarPacientes();
  }

  initForm() {
    this.uploadForm = this.fb.group({
      paciente_id: ['', [Validators.required]],
      tipo_documento: ['laboratorio', [Validators.required]],
      notas: ['']
    });
  }

  cargarPacientes() {
    this.isLoading = true;
    // Aquí deberías cargar la lista de pacientes (alumnos)
    // Por ahora simulamos con el servicio de usuario
    this.userService.getAlumnos().subscribe({
      next: (response: any) => {
        this.pacientes = response.alumnos || [];
        this.isLoading = false;
      },
      error: (error: any) => {
        console.error('Error cargando pacientes:', error);
        this.isLoading = false;
        // Datos de ejemplo para desarrollo
        this.pacientes = [
          { id: 1, nombre: 'Juan', apellido: 'Pérez', email: 'juan@test.com' },
          { id: 2, nombre: 'María', apellido: 'García', email: 'maria@test.com' },
        ];
      }
    });
  }

  onFileSelected(event: any) {
    const file = event.target.files[0];
    
    if (file) {
      // Validar tipo de archivo
      const tiposPermitidos = ['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'];
      
      if (!tiposPermitidos.includes(file.type)) {
        this.uploadError = 'Solo se permiten archivos PDF o Word (.doc, .docx)';
        this.selectedFile = null;
        return;
      }

      // Validar tamaño (máximo 10MB)
      if (file.size > 10 * 1024 * 1024) {
        this.uploadError = 'El archivo no puede superar los 10MB';
        this.selectedFile = null;
        return;
      }

      this.selectedFile = file;
      this.uploadError = null;
    }
  }

  onSubmit() {
    if (this.uploadForm.invalid || !this.selectedFile) {
      return;
    }

    this.isUploading = true;
    this.uploadSuccess = false;
    this.uploadError = null;

    // Crear FormData
    const formData = new FormData();
    formData.append('paciente_id', this.uploadForm.get('paciente_id')?.value);
    formData.append('tipo_documento', this.uploadForm.get('tipo_documento')?.value);
    formData.append('documento', this.selectedFile);
    
    const notas = this.uploadForm.get('notas')?.value;
    if (notas) {
      formData.append('notas', notas);
    }

    this.documentoService.subirDocumento(formData).subscribe({
      next: (response: any) => {
        this.isUploading = false;
        this.uploadSuccess = true;
        this.documentoSubido = response.documento;
        this.analisisIA = response.analisis_ia;
        
        console.log('Documento subido exitosamente:', response);
      },
      error: (error) => {
        this.isUploading = false;
        this.uploadError = error.message || 'Error al subir el documento';
        console.error('Error subiendo documento:', error);
      }
    });
  }

  resetForm() {
    this.uploadForm.reset({
      tipo_documento: 'laboratorio'
    });
    this.selectedFile = null;
    this.uploadSuccess = false;
    this.uploadError = null;
    this.documentoSubido = null;
    this.analisisIA = null;
    
    // Resetear input de archivo
    const fileInput = document.getElementById('documento') as HTMLInputElement;
    if (fileInput) {
      fileInput.value = '';
    }
  }

  getTipoDocumentoLabel(value: string): string {
    const tipo = this.tiposDocumento.find(t => t.value === value);
    return tipo ? `${tipo.icon} ${tipo.label}` : value;
  }

  getConfianzaClass(confianza: number): string {
    if (confianza >= 0.9) return 'bg-green-100 text-green-800';
    if (confianza >= 0.7) return 'bg-yellow-100 text-yellow-800';
    if (confianza >= 0.5) return 'bg-orange-100 text-orange-800';
    return 'bg-red-100 text-red-800';
  }

  getBadgeColor(estatus: string): string {
    const colores: { [key: string]: string } = {
      'pendiente': 'bg-yellow-100 text-yellow-800',
      'procesando': 'bg-blue-100 text-blue-800',
      'completado': 'bg-green-100 text-green-800',
      'error': 'bg-red-100 text-red-800',
    };
    return colores[estatus] || 'bg-gray-100 text-gray-800';
  }

  // Helper para obtener keys de datos_detectados de forma segura
  getDatosKeys(): string[] {
    if (!this.analisisIA?.datos_detectados) return [];
    return Object.keys(this.analisisIA.datos_detectados);
  }

  // Helper para obtener entries de datos_detectados
  getDatosEntries(): { key: string; value: any }[] {
    if (!this.analisisIA?.datos_detectados) return [];
    return Object.entries(this.analisisIA.datos_detectados).map(([key, value]) => ({
      key,
      value
    }));
  }

  formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }
}
