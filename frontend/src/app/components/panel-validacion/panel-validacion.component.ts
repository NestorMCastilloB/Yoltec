import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { DocumentoMedicoService, AnalisisIA, ValidacionRequest } from '../../services/documento-medico.service';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-panel-validacion',
  templateUrl: './panel-validacion.component.html',
  styleUrls: ['./panel-validacion.component.css'],
  standalone: true,
  imports: [CommonModule, FormsModule]
})
export class PanelValidacionComponent implements OnInit {
  pendientes: AnalisisIA[] = [];
  estadisticas: any = null;
  
  isLoading = true;
  isValidating = false;
  error: string | null = null;
  
  // Modal de validación
  modalAbierto = false;
  analisisSeleccionado: AnalisisIA | null = null;
  formValidacion = {
    accion: 'aprobar' as 'aprobar' | 'rechazar' | 'corregir',
    diagnostico_final: '',
    comentario: ''
  };
  
  // Filtros
  filtroConfianza: string = 'todos';
  busqueda: string = '';

  constructor(
    private documentoService: DocumentoMedicoService,
    private authService: AuthService
  ) {}

  ngOnInit() {
    this.cargarPendientes();
    this.cargarEstadisticas();
  }

  cargarPendientes() {
    this.isLoading = true;
    this.error = null;

    this.documentoService.getPendientesValidacion().subscribe({
      next: (response: any) => {
        this.pendientes = response.pendientes?.data || [];
        this.isLoading = false;
      },
      error: (error) => {
        this.error = error.message || 'Error cargando análisis pendientes';
        this.isLoading = false;
        console.error('Error:', error);
      }
    });
  }

  cargarEstadisticas() {
    this.documentoService.getEstadisticas().subscribe({
      next: (response: any) => {
        this.estadisticas = response.estadisticas;
      },
      error: (error) => {
        console.error('Error cargando estadísticas:', error);
      }
    });
  }

  abrirModalValidacion(analisis: AnalisisIA) {
    this.analisisSeleccionado = analisis;
    this.formValidacion = {
      accion: 'aprobar',
      diagnostico_final: analisis.diagnostico_sugerido,
      comentario: ''
    };
    this.modalAbierto = true;
  }

  cerrarModal() {
    this.modalAbierto = false;
    this.analisisSeleccionado = null;
    this.isValidating = false;
  }

  onAccionChange() {
    // Resetear diagnóstico final según acción
    if (this.formValidacion.accion === 'aprobar') {
      this.formValidacion.diagnostico_final = this.analisisSeleccionado?.diagnostico_sugerido || '';
    } else if (this.formValidacion.accion === 'rechazar') {
      this.formValidacion.diagnostico_final = '';
    }
    // Si es corregir, dejar que el doctor escriba
  }

  validarDiagnostico() {
    if (!this.analisisSeleccionado) return;

    // Validaciones
    if (this.formValidacion.accion === 'corregir' && !this.formValidacion.diagnostico_final.trim()) {
      alert('Debes proporcionar un diagnóstico corregido');
      return;
    }

    if (this.formValidacion.accion === 'rechazar' && !this.formValidacion.comentario.trim()) {
      alert('Debes indicar el motivo del rechazo');
      return;
    }

    this.isValidating = true;

    const request: ValidacionRequest = {
      accion: this.formValidacion.accion,
      diagnostico_final: this.formValidacion.diagnostico_final,
      comentario: this.formValidacion.comentario
    };

    this.documentoService.validarDiagnostico(this.analisisSeleccionado.id, request).subscribe({
      next: (response) => {
        this.isValidating = false;
        this.cerrarModal();
        this.cargarPendientes(); // Recargar lista
        this.cargarEstadisticas(); // Actualizar stats
        
        // Mostrar mensaje de éxito
        const mensajes: { [key: string]: string } = {
          'aprobar': 'Diagnóstico aprobado correctamente',
          'rechazar': 'Diagnóstico rechazado',
          'corregir': 'Diagnóstico corregido y guardado'
        };
        alert(mensajes[this.formValidacion.accion]);
      },
      error: (error) => {
        this.isValidating = false;
        alert('Error al validar: ' + (error.message || 'Inténtalo de nuevo'));
        console.error('Error validando:', error);
      }
    });
  }

  // Filtros
  get pendientesFiltrados(): AnalisisIA[] {
    return this.pendientes.filter(p => {
      // Filtro por confianza
      if (this.filtroConfianza !== 'todos') {
        const confianza = p.nivel_confianza;
        switch (this.filtroConfianza) {
          case 'alta':
            if (confianza < 0.8) return false;
            break;
          case 'media':
            if (confianza < 0.6 || confianza >= 0.8) return false;
            break;
          case 'baja':
            if (confianza >= 0.6) return false;
            break;
        }
      }

      // Búsqueda
      if (this.busqueda) {
        const termino = this.busqueda.toLowerCase();
        const paciente = p.documento?.paciente;
        const textoBusqueda = `
          ${p.diagnostico_sugerido.toLowerCase()}
          ${paciente?.nombre?.toLowerCase() || ''}
          ${paciente?.apellido?.toLowerCase() || ''}
          ${p.palabras_clave_detectadas?.join(' ').toLowerCase() || ''}
        `;
        if (!textoBusqueda.includes(termino)) return false;
      }

      return true;
    });
  }

  // Helpers
  getConfianzaClass(confianza: number): string {
    if (confianza >= 0.9) return 'bg-green-100 text-green-800';
    if (confianza >= 0.7) return 'bg-blue-100 text-blue-800';
    if (confianza >= 0.5) return 'bg-yellow-100 text-yellow-800';
    return 'bg-red-100 text-red-800';
  }

  // Helper para obtener keys de datos_detectados de forma segura
  getDatosKeys(datos: any): string[] {
    if (!datos) return [];
    return Object.keys(datos);
  }

  formatDate(dateString: string): string {
    if (!dateString) return '';
    const date = new Date(dateString);
    return date.toLocaleDateString('es-MX', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  formatFileSize(bytes: number): string {
    if (!bytes) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  getDocumentTypeIcon(tipo: string): string {
    const icons: { [key: string]: string } = {
      'laboratorio': '🔬',
      'rayos_x': '🩻',
      'receta_externa': '💊',
      'historial': '📋',
      'notas_clinicas': '📝',
      'otro': '📄'
    };
    return icons[tipo] || '📄';
  }

  getDocumentTypeLabel(tipo: string): string {
    const labels: { [key: string]: string } = {
      'laboratorio': 'Laboratorio',
      'rayos_x': 'Rayos X',
      'receta_externa': 'Receta Externa',
      'historial': 'Historial Médico',
      'notas_clinicas': 'Notas Clínicas',
      'otro': 'Otro'
    };
    return labels[tipo] || tipo;
  }
}
