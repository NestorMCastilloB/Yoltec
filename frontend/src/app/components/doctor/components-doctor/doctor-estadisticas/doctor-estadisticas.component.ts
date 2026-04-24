import { Component, AfterViewChecked, OnDestroy, ViewChild, ElementRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Subject, of } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { Chart, registerables } from 'chart.js';
import { EstadisticasService, Estadisticas } from '../../../../services/estadisticas.service';

Chart.register(...registerables);

@Component({
  selector: 'app-doctor-estadisticas',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './doctor-estadisticas.component.html',
  styleUrls: ['./doctor-estadisticas.component.css']   // ← Agregar
})

export class DoctorEstadisticasComponent implements AfterViewChecked, OnDestroy {
  @ViewChild('barCanvas') barCanvas!: ElementRef<HTMLCanvasElement>;
  @ViewChild('doughnutCanvas') doughnutCanvas!: ElementRef<HTMLCanvasElement>;

  estadisticas: Estadisticas | null = null;
  isLoadingEstadisticas = false;
  estadisticasError: string | null = null;

  private barChart: Chart | null = null;
  private doughnutChart: Chart | null = null;
  private chartsRendered = false;
  private destroy$ = new Subject<void>();

  constructor(private estadisticasService: EstadisticasService) { }

  ngAfterViewChecked(): void {
    if (this.estadisticas && !this.chartsRendered && this.barCanvas && this.doughnutCanvas) {
      this.renderCharts();
      this.chartsRendered = true;
    }
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
      .subscribe(data => { this.estadisticas = data; });
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
