import { Component, EventEmitter, OnDestroy, OnInit, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subject, of } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { PreEvaluacionIAService, PreEvaluacion } from '../../../../services/pre-evaluacion-ia.service';

@Component({
  selector: 'app-doctor-pre-evaluaciones',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './doctor-pre-evaluaciones.component.html',
  styleUrls: ['./doctor-pre-evaluaciones.component.css']
})
export class DoctorPreEvaluacionesComponent implements OnInit, OnDestroy {
  @Output() pendientesChange = new EventEmitter<number>();

  tab: 'pendientes' | 'historial' = 'pendientes';
  pendientes: PreEvaluacion[] = [];
  historial: PreEvaluacion[] = [];
  cargando = false;
  error: string | null = null;
  totalPendientes = 0;

  // Modal validar
  modalValidar: PreEvaluacion | null = null;
  comentarioValidar = '';
  // Modal descartar
  modalDescartar: PreEvaluacion | null = null;
  motivoDescartar = '';
  motivoError = false;

  enviando = false;

  // Toast
  toast: { mensaje: string; tipo: 'ok' | 'error' } | null = null;
  private toastTimer: any;

  // Filtros historial
  filtroBusqueda = '';
  filtroEstatus = '';

  private destroy$ = new Subject<void>();

  constructor(private svc: PreEvaluacionIAService) {}

  ngOnInit(): void {
    this.cargar();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
    clearTimeout(this.toastTimer);
  }

  cargar(): void {
    this.cargando = true;
    this.error = null;

    this.svc.getPendientes()
      .pipe(
        takeUntil(this.destroy$),
        catchError(err => {
          this.error = err?.error?.message || 'No se pudieron cargar las pre-evaluaciones';
          return of({ pendientes: [], total: 0 });
        }),
        finalize(() => { this.cargando = false; })
      )
      .subscribe(res => {
        this.pendientes = res.pendientes;
        this.totalPendientes = res.total;
        this.pendientesChange.emit(this.totalPendientes);
      });

    this.svc.getPreEvaluaciones()
      .pipe(takeUntil(this.destroy$), catchError(() => of({ pre_evaluaciones: [] })))
      .subscribe(res => {
        this.historial = (res.pre_evaluaciones ?? [])
          .filter((p: PreEvaluacion) => p.estatus_validacion !== 'pendiente');
      });
  }

  // --- Historial filtrado ---

  get historialFiltrado(): PreEvaluacion[] {
    return this.historial.filter(p => {
      const nombre = `${p.cita?.alumno?.nombre ?? ''} ${p.cita?.alumno?.apellido ?? ''}`.toLowerCase();
      const ctrl = p.cita?.alumno?.numero_control ?? '';
      const busq = this.filtroBusqueda.toLowerCase().trim();
      if (busq && !nombre.includes(busq) && !ctrl.includes(busq)) return false;
      if (this.filtroEstatus && p.estatus_validacion !== this.filtroEstatus) return false;
      return true;
    });
  }

  limpiarFiltros(): void {
    this.filtroBusqueda = '';
    this.filtroEstatus = '';
  }

  // --- Modales ---

  abrirValidar(pe: PreEvaluacion): void {
    this.modalValidar = pe;
    this.comentarioValidar = '';
  }

  cerrarValidar(): void {
    this.modalValidar = null;
    this.comentarioValidar = '';
    this.enviando = false;
  }

  abrirDescartar(pe: PreEvaluacion): void {
    this.modalDescartar = pe;
    this.motivoDescartar = '';
    this.motivoError = false;
  }

  cerrarDescartar(): void {
    this.modalDescartar = null;
    this.motivoDescartar = '';
    this.motivoError = false;
    this.enviando = false;
  }

  // --- Acciones ---

  confirmarValidar(): void {
    if (!this.modalValidar || this.enviando) return;
    const pe = this.modalValidar;
    this.enviando = true;

    // Optimista: remover de pendientes
    this.pendientes = this.pendientes.filter(p => p.id !== pe.id);
    this.totalPendientes = this.pendientes.length;
    this.pendientesChange.emit(this.totalPendientes);
    this.cerrarValidar();

    this.svc.validarPreEvaluacion(pe.id, 'validar', this.comentarioValidar)
      .pipe(
        takeUntil(this.destroy$),
        catchError(err => {
          // Revertir
          this.pendientes = [pe, ...this.pendientes];
          this.totalPendientes = this.pendientes.length;
          this.pendientesChange.emit(this.totalPendientes);
          this.mostrarToast(err?.error?.message || 'Error al validar. Intenta de nuevo.', 'error');
          return of(null);
        }),
        finalize(() => { this.enviando = false; })
      )
      .subscribe(res => {
        if (res) {
          this.historial = [res.pre_evaluacion, ...this.historial];
          this.mostrarToast('Pre-evaluación validada correctamente.', 'ok');
        }
      });
  }

  confirmarDescartar(): void {
    if (!this.modalDescartar || this.enviando) return;
    if (this.motivoDescartar.trim().length < 10) {
      this.motivoError = true;
      return;
    }
    const pe = this.modalDescartar;
    const motivo = this.motivoDescartar.trim();
    this.enviando = true;

    // Optimista: remover de pendientes
    this.pendientes = this.pendientes.filter(p => p.id !== pe.id);
    this.totalPendientes = this.pendientes.length;
    this.pendientesChange.emit(this.totalPendientes);
    this.cerrarDescartar();

    this.svc.validarPreEvaluacion(pe.id, 'descartar', motivo)
      .pipe(
        takeUntil(this.destroy$),
        catchError(err => {
          // Revertir
          this.pendientes = [pe, ...this.pendientes];
          this.totalPendientes = this.pendientes.length;
          this.pendientesChange.emit(this.totalPendientes);
          this.mostrarToast(err?.error?.message || 'Error al descartar. Intenta de nuevo.', 'error');
          return of(null);
        }),
        finalize(() => { this.enviando = false; })
      )
      .subscribe(res => {
        if (res) {
          this.historial = [res.pre_evaluacion, ...this.historial];
          this.mostrarToast('Pre-evaluación descartada.', 'ok');
        }
      });
  }

  // --- Helpers ---

  iniciales(pe: PreEvaluacion): string {
    const n = pe.cita?.alumno?.nombre?.[0] ?? '';
    const a = pe.cita?.alumno?.apellido?.[0] ?? '';
    return (n + a).toUpperCase() || '?';
  }

  nombreCompleto(pe: PreEvaluacion): string {
    const n = pe.cita?.alumno?.nombre ?? '';
    const a = pe.cita?.alumno?.apellido ?? '';
    return `${n} ${a}`.trim() || 'Sin nombre';
  }

  tieneAlumno(pe: PreEvaluacion): boolean {
    return !!(pe.cita?.alumno?.nombre || pe.cita?.alumno?.apellido);
  }

  formatFecha(iso: string): string {
    if (!iso) return '—';
    const [y, m, d] = iso.split('-').map(Number);
    return new Intl.DateTimeFormat('es-MX', { day: '2-digit', month: 'short', year: 'numeric' })
      .format(new Date(y, (m ?? 1) - 1, d ?? 1));
  }

  private mostrarToast(mensaje: string, tipo: 'ok' | 'error'): void {
    clearTimeout(this.toastTimer);
    this.toast = { mensaje, tipo };
    this.toastTimer = setTimeout(() => { this.toast = null; }, 4000);
  }
}
