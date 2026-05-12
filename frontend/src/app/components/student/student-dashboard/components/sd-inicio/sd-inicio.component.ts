import { Component, EventEmitter, OnDestroy, OnInit, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Subject } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { of } from 'rxjs';
import { Cita, CitaService } from '../../../../../services/cita.service';
import { PreEvaluacionIAService, PreEvaluacion } from '../../../../../services/pre-evaluacion-ia.service';

@Component({
  selector: 'app-sd-inicio',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './sd-inicio.component.html',
})
export class SdInicioComponent implements OnInit, OnDestroy {
  @Output() navegarACitas = new EventEmitter<void>();

  nextCitaInfo: { fecha: string; hora: string; motivo?: string } | null = null;
  totalCitasProgramadas = 0;
  citasPendientesSinEvaluacion = 0;

  private destroy$ = new Subject<void>();

  constructor(
    private citaService: CitaService,
    private preEvaluacionService: PreEvaluacionIAService,
  ) {}

  ngOnInit(): void {
    this.cargarResumen();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private cargarResumen(): void {
    this.citaService.getCitas()
      .pipe(takeUntil(this.destroy$), catchError(() => of([])))
      .subscribe((citas: Cita[]) => {
        const programadas = citas.filter(c => c.estatus === 'programada');
        this.totalCitasProgramadas = programadas.length;

        const proxima = programadas.sort((a, b) =>
          new Date(a.fecha_cita).getTime() - new Date(b.fecha_cita).getTime()
        )[0];

        if (proxima) {
          this.nextCitaInfo = {
            fecha: new Intl.DateTimeFormat('es-MX', { dateStyle: 'long' }).format(new Date(proxima.fecha_cita)),
            hora: proxima.hora_cita,
            motivo: proxima.motivo ?? undefined,
          };
        }
      });

    this.preEvaluacionService.getPreEvaluaciones()
      .pipe(takeUntil(this.destroy$), catchError(() => of([])))
      .subscribe((res: any) => { const evals: PreEvaluacion[] = res?.pre_evaluaciones ?? [];
        this.citasPendientesSinEvaluacion = evals.filter(e => !e.estatus_validacion).length;
      });
  }
}
