import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Subject, of } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { IaPriorityService, ResumenPrioridad, ClasificacionPrioridad } from '../../../../services/ia-priority.service';

@Component({
  selector: 'app-doctor-ia-prioridad',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './doctor-ia-prioridad.component.html',
  styleUrls: ['./doctor-ia-prioridad.component.css']
})
export class DoctorIaPrioridadComponent implements OnDestroy, OnInit {
  prioridadResumen: ResumenPrioridad | null = null;
  isLoadingPrioridad = false;
  prioridadError: string | null = null;

  filtroActivo: 'todas' | 'alta' | 'media' | 'baja' = 'todas';
  expandedCards = new Set<number>();

  private destroy$ = new Subject<void>();

  constructor(private iaPriorityService: IaPriorityService) { }

  ngOnInit(): void {
    this.loadPrioridad();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadPrioridad(): void {
    this.isLoadingPrioridad = true;
    this.prioridadError = null;

    this.iaPriorityService.getPendientesPorPrioridad()
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => {
          this.prioridadError = error?.error?.message || 'No se pudo cargar la clasificación de prioridad.';
          return of(null);
        }),
        finalize(() => { this.isLoadingPrioridad = false; })
      )
      .subscribe(res => { this.prioridadResumen = res; });
  }

  get citasFiltradas(): ClasificacionPrioridad[] {
    if (!this.prioridadResumen) return [];
    if (this.filtroActivo === 'todas') return this.prioridadResumen.citas;
    return this.prioridadResumen.citas.filter(c => c.prioridad === this.filtroActivo);
  }

  setFiltro(filtro: 'todas' | 'alta' | 'media' | 'baja'): void {
    this.filtroActivo = filtro;
  }

  toggleCard(citaId: number): void {
    if (this.expandedCards.has(citaId)) {
      this.expandedCards.delete(citaId);
    } else {
      this.expandedCards.add(citaId);
    }
  }

  isExpanded(citaId: number): boolean {
    return this.expandedCards.has(citaId);
  }
}
