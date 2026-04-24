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
  styleUrls: ['./doctor-pre-evaluaciones.component.css']   // ← Línea agregada
})
export class DoctorPreEvaluacionesComponent implements OnInit, OnDestroy {
  @Output() pendientesChange = new EventEmitter<number>();

  preEvaluaciones: PreEvaluacion[] = [];
  preEvaluacionesHistorial: PreEvaluacion[] = [];
  isLoadingPreEvaluaciones = false;
  preEvaluacionesError: string | null = null;
  totalPendientes = 0;

  showPreEvaluacionModal = false;
  selectedPreEvaluacion: PreEvaluacion | null = null;
  isSubmittingValidacion = false;
  comentarioValidacion = '';

  private destroy$ = new Subject<void>();

  constructor(private preEvaluacionIAService: PreEvaluacionIAService) { }

  ngOnInit(): void {
    this.load();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  load(): void {
    this.isLoadingPreEvaluaciones = true;
    this.preEvaluacionesError = null;

    this.preEvaluacionIAService.getPendientes()
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => {
          this.preEvaluacionesError = error?.error?.message || 'No se pudieron cargar las pre-evaluaciones';
          return of({ pendientes: [], total: 0 });
        }),
        finalize(() => { this.isLoadingPreEvaluaciones = false; })
      )
      .subscribe(response => {
        this.preEvaluaciones = response.pendientes;
        this.totalPendientes = response.total;
        this.pendientesChange.emit(this.totalPendientes);
      });

    this.preEvaluacionIAService.getPreEvaluaciones()
      .pipe(takeUntil(this.destroy$), catchError(() => of({ pre_evaluaciones: [] })))
      .subscribe(response => {
        this.preEvaluacionesHistorial = (response.pre_evaluaciones ?? [])
          .filter((p: PreEvaluacion) => p.estatus_validacion !== 'pendiente');
      });
  }

  openPreEvaluacionModal(preEvaluacion: PreEvaluacion): void {
    this.selectedPreEvaluacion = preEvaluacion;
    this.showPreEvaluacionModal = true;
    this.comentarioValidacion = '';
  }

  closePreEvaluacionModal(): void {
    this.showPreEvaluacionModal = false;
    this.selectedPreEvaluacion = null;
    this.comentarioValidacion = '';
    this.isSubmittingValidacion = false;
  }

  validarPreEvaluacion(accion: 'validar' | 'descartar'): void {
    if (!this.selectedPreEvaluacion) return;
    this.isSubmittingValidacion = true;

    this.preEvaluacionIAService.validarPreEvaluacion(this.selectedPreEvaluacion.id, accion, this.comentarioValidacion)
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => {
          this.preEvaluacionesError = error?.error?.message || 'Error al validar la pre-evaluación';
          return of(null);
        }),
        finalize(() => { this.isSubmittingValidacion = false; })
      )
      .subscribe(response => {
        if (response) {
          this.preEvaluaciones = this.preEvaluaciones.filter(p => p.id !== this.selectedPreEvaluacion?.id);
          this.totalPendientes--;
          this.pendientesChange.emit(this.totalPendientes);
          this.closePreEvaluacionModal();
        }
      });
  }

  getConfianzaClass(confianza: number): string {
    if (confianza >= 0.8) return 'confianza-alta';
    if (confianza >= 0.6) return 'confianza-media';
    if (confianza >= 0.4) return 'confianza-baja';
    return 'confianza-muy-baja';
  }

  formatDateDisplay(fecha: string): string {
    const [year, month, day] = fecha.split('-').map(Number);
    return new Intl.DateTimeFormat('es-MX', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })
      .format(new Date(year, (month ?? 1) - 1, day ?? 1));
  }

  formatTime(hora: string): string {
    const [h, m] = hora.split(':').map(Number);
    const d = new Date();
    d.setHours(h, m || 0, 0, 0);
    return new Intl.DateTimeFormat('es-MX', { hour: '2-digit', minute: '2-digit', hour12: false }).format(d);
  }
}
