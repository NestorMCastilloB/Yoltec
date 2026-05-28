import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subject, of } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { IaPriorityService, ResumenPrioridad, ClasificacionPrioridad } from '../../../../services/ia-priority.service';

@Component({
  selector: 'app-doctor-ia-prioridad',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './doctor-ia-prioridad.component.html',
  styleUrls: ['./doctor-ia-prioridad.component.css']
})
export class DoctorIaPrioridadComponent implements OnDestroy, OnInit {
  prioridadResumen: ResumenPrioridad | null = null;
  isLoadingPrioridad = false;
  prioridadError: string | null = null;
  hasError = false;
  errorMessage = '';

  filtroActivo: 'todas' | 'alta' | 'media' | 'baja' = 'todas';
  busqueda = '';
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

  // Reintenta la clasificación tras un error de conexión
  reintentar(): void {
    this.hasError = false;
    this.errorMessage = '';
    this.loadPrioridad();
  }

  loadPrioridad(): void {
    this.isLoadingPrioridad = true;
    this.hasError = false;
    this.errorMessage = '';

    this.iaPriorityService.getPendientesPorPrioridad()
      .pipe(
        takeUntil(this.destroy$),
        catchError((err) => {
          this.hasError = true;
          if (err?.status === 0 || err?.status === 502 || err?.status === 503) {
            this.errorMessage = 'El servidor esta iniciando. Espera unos segundos y reintenta.';
          } else if (err?.status >= 500) {
            this.errorMessage = 'Ocurrio un problema al clasificar las citas. Reintenta en un momento.';
          } else {
            this.errorMessage = 'No se pudo conectar con el servicio de prioridad. Verifica tu conexion.';
          }
          return of(null);
        }),
        finalize(() => { this.isLoadingPrioridad = false; })
      )
      .subscribe(res => { this.prioridadResumen = res; });
  }

  get citasFiltradas(): ClasificacionPrioridad[] {
    if (!this.prioridadResumen) return [];
    const busq = this.busqueda.toLowerCase().trim();
    return this.prioridadResumen.citas.filter(c => {
      if (this.filtroActivo !== 'todas' && c.prioridad !== this.filtroActivo) return false;
      if (!busq) return true;
      const nombre = `${c.cita.alumno.nombre ?? ''} ${c.cita.alumno.apellido ?? ''}`.toLowerCase();
      const ctrl = c.cita.alumno.numero_control?.toLowerCase() ?? '';
      return nombre.includes(busq) || ctrl.includes(busq);
    });
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
