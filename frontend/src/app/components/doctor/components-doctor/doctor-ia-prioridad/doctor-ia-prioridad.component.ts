import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Subject, of } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { IaPriorityService, ResumenPrioridad } from '../../../../services/ia-priority.service';

@Component({
  selector: 'app-doctor-ia-prioridad',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './doctor-ia-prioridad.component.html',
  styleUrls: ['./doctor-ia-prioridad.component.css']   // ← Línea necesaria
})
export class DoctorIaPrioridadComponent implements OnDestroy, OnInit {
  prioridadResumen: ResumenPrioridad | null = null;
  isLoadingPrioridad = false;
  prioridadError: string | null = null;

  private destroy$ = new Subject<void>();

  constructor(private iaPriorityService: IaPriorityService) { }

  ngOnInit(): void {
    // Opcional: cargar automáticamente al iniciar
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
}