import { Component, OnInit, OnDestroy, ViewChild, ElementRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Subject, of } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { Chart, registerables } from 'chart.js';
import { EstadisticasService, Estadisticas, MesStats } from '../../../../services/estadisticas.service';

Chart.register(...registerables);

@Component({
  selector: 'app-doctor-estadisticas',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './doctor-estadisticas.component.html',
  styleUrls: ['./doctor-estadisticas.component.css']
})

export class DoctorEstadisticasComponent implements OnInit, OnDestroy {
  @ViewChild('barCanvas') barCanvas!: ElementRef<HTMLCanvasElement>;
  @ViewChild('doughnutCanvas') doughnutCanvas!: ElementRef<HTMLCanvasElement>;

  estadisticas: Estadisticas | null = null;
  isLoadingEstadisticas = false;
  estadisticasError: string | null = null;

  deltaAtendidas: string | null = null;
  deltaAtenidasPositivo = true;
  deltaCancelaciones: string | null = null;
  deltaCancelacionesPositivo = true;

  private barChart: Chart | null = null;
  private doughnutChart: Chart | null = null;
  private chartsRendered = false;
  private destroy$ = new Subject<void>();

  constructor(private estadisticasService: EstadisticasService) { }

  ngOnInit(): void {
    this.loadEstadisticas();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
    this.barChart?.destroy();
    this.doughnutChart?.destroy();
  }

  loadEstadisticas(): void {
    this.isLoadingEstadisticas = true;
    this.estadisticasError = null;
    this.chartsRendered = false;

    this.estadisticasService.getEstadisticas()
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => {
          this.estadisticasError = error?.error?.message || 'No se pudieron cargar las estadísticas.';
          return of(null);
        }),
        finalize(() => { this.isLoadingEstadisticas = false; })
      )
      .subscribe(data => {
        this.estadisticas = data;
        if (data) this.computeDeltas(data.citas_por_mes);
        if (data && !this.chartsRendered) {
          setTimeout(() => {
            if (this.barCanvas && this.doughnutCanvas) {
              this.renderCharts();
              this.chartsRendered = true;
            }
          }, 0);
        }
      });
  }

  private computeDeltas(meses: MesStats[]): void {
    if (!meses || meses.length < 2) return;
    const curr = meses[meses.length - 1];
    const prev = meses[meses.length - 2];
    if (prev.atendidas > 0) {
      const pct = Math.round((curr.atendidas - prev.atendidas) / prev.atendidas * 100);
      this.deltaAtendidas = pct >= 0 ? `▲ +${pct}% vs mes pasado` : `▼ ${pct}% vs mes pasado`;
      this.deltaAtenidasPositivo = pct >= 0;
    }
    const diffCancel = curr.canceladas - prev.canceladas;
    if (diffCancel !== 0) {
      this.deltaCancelaciones = diffCancel > 0 ? `▲ +${diffCancel} vs mes pasado` : `▼ ${Math.abs(diffCancel)} vs mes pasado`;
      this.deltaCancelacionesPositivo = diffCancel <= 0;
    }
  }

  private renderCharts(): void {
    if (!this.estadisticas) return;

    const meses = this.estadisticas.citas_por_mes;
    this.barChart?.destroy();
    this.doughnutChart?.destroy();

    this.barChart = new Chart(this.barCanvas.nativeElement, {
      type: 'bar',
      data: {
        labels: meses.map(m => m.label),
        datasets: [
          { label: 'Atendidas', data: meses.map(m => m.atendidas), backgroundColor: 'rgba(76, 175, 80, 0.7)', borderColor: '#388E3C', borderWidth: 1 },
          { label: 'Canceladas', data: meses.map(m => m.canceladas), backgroundColor: 'rgba(239, 83, 80, 0.7)', borderColor: '#C62828', borderWidth: 1 },
          { label: 'No asistió', data: meses.map(m => m.no_asistio), backgroundColor: 'rgba(255, 179, 0, 0.7)', borderColor: '#F57F17', borderWidth: 1 }
        ]
      },
      options: {
        responsive: true,
        plugins: { legend: { position: 'top' } },
        scales: { y: { beginAtZero: true, ticks: { stepSize: 1 } } }
      }
    });

    const r = this.estadisticas.resumen_estados;
    this.doughnutChart = new Chart(this.doughnutCanvas.nativeElement, {
      type: 'doughnut',
      data: {
        labels: ['Atendidas', 'Canceladas', 'No asistió', 'Programadas'],
        datasets: [{
          data: [r.atendida, r.cancelada, r.no_asistio, r.programada],
          backgroundColor: ['rgba(76, 175, 80, 0.8)', 'rgba(239, 83, 80, 0.8)', 'rgba(255, 179, 0, 0.8)', 'rgba(33, 150, 243, 0.8)'],
          borderColor: ['#388E3C', '#C62828', '#F57F17', '#1565C0'],
          borderWidth: 2
        }]
      },
      options: { responsive: true, plugins: { legend: { position: 'bottom' } } }
    });
  }
}
