import { Component, EventEmitter, OnDestroy, OnInit, Output } from '@angular/core';
import { CommonModule, DatePipe, registerLocaleData } from '@angular/common';
import { Subject } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { of } from 'rxjs';
import localeEs from '@angular/common/locales/es-MX';
import {
  StudentDashboardService,
  DashboardAlumno,
  DashboardCita,
  RecetaActiva,
} from './student-dashboard.service';
import { AuthService } from '../../../services/auth.service';

registerLocaleData(localeEs, 'es-MX');

@Component({
  selector: 'app-student-dashboard-inicio',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './student-dashboard.component.html',
  styleUrls: ['./student-dashboard.component.css'],
  providers: [DatePipe],
})
export class StudentDashboardInicioComponent implements OnInit, OnDestroy {
  @Output() navegarACitas = new EventEmitter<void>();
  @Output() navegarAAgendar = new EventEmitter<void>();
  @Output() navegarARecetas = new EventEmitter<void>();

  loading = true;
  nombre = '';
  fechaHoy = '';

  // KPIs
  totalProximas = 0;
  proximaCitaTexto = '';
  ultimaVisitaDia = '';
  ultimaVisitaMes = '';
  ultimaVisitaDiagnostico = '';
  recetasActivasCount = 0;
  diasProximaVencer = 0;

  // Tabla
  citas: DashboardCita[] = [];
  recetas: RecetaActiva[] = [];
  recordatorio: { titulo: string; mensaje: string } | null = null;

  // Modal cancelar
  citaCancelarId: number | null = null;
  cancelando = false;

  private destroy$ = new Subject<void>();

  constructor(
    private dashboardService: StudentDashboardService,
    private authService: AuthService,
    private datePipe: DatePipe,
  ) {}

  ngOnInit(): void {
    const user = this.authService.getCurrentUser();
    this.nombre = user?.nombre ?? 'Alumno';
    this.fechaHoy = this.formatearFechaHoy();
    this.cargarDashboard();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  cargarDashboard(): void {
    this.loading = true;
    this.dashboardService.getDashboard()
      .pipe(
        takeUntil(this.destroy$),
        catchError(() => of({
          proximas_citas: [],
          ultima_visita: null,
          recetas_activas: [],
          recordatorio: null,
        } as DashboardAlumno)),
        finalize(() => this.loading = false),
      )
      .subscribe(data => this.procesarDashboard(data));
  }

  // Abre modal de confirmación para cancelar
  confirmarCancelar(citaId: number): void {
    this.citaCancelarId = citaId;
  }

  cerrarModal(): void {
    this.citaCancelarId = null;
  }

  // Ejecuta cancelación tras confirmación
  cancelarCita(): void {
    if (!this.citaCancelarId) return;
    this.cancelando = true;
    this.dashboardService.cancelarCita(this.citaCancelarId)
      .pipe(
        takeUntil(this.destroy$),
        finalize(() => {
          this.cancelando = false;
          this.citaCancelarId = null;
        }),
      )
      .subscribe(() => this.cargarDashboard());
  }

  // Formatea fecha ISO a componentes para la celda de tabla
  getDia(fecha: string): string {
    return new Date(fecha).getDate().toString();
  }

  getMesCorto(fecha: string): string {
    const meses = ['ENE','FEB','MAR','ABR','MAY','JUN','JUL','AGO','SEP','OCT','NOV','DIC'];
    return meses[new Date(fecha).getMonth()];
  }

  getDiaSemana(fecha: string): string {
    const dias = ['domingo','lunes','martes','miércoles','jueves','viernes','sábado'];
    return dias[new Date(fecha).getDay()];
  }

  getAnio(fecha: string): string {
    return new Date(fecha).getFullYear().toString();
  }

  // Formatea hora "HH:mm:ss" → "HH:mm"
  formatHora(hora: string): string {
    return hora?.substring(0, 5) ?? '';
  }

  private procesarDashboard(data: DashboardAlumno): void {
    this.citas = data.proximas_citas ?? [];
    this.totalProximas = this.citas.length;

    if (this.citas.length > 0) {
      const p = this.citas[0];
      const d = new Date(p.fecha_cita);
      const dias = ['domingo','lunes','martes','miércoles','jueves','viernes','sábado'];
      const meses = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
      this.proximaCitaTexto = `${dias[d.getDay()]} ${d.getDate()} ${meses[d.getMonth()]}, ${this.formatHora(p.hora_cita)}`;
    }

    if (data.ultima_visita) {
      const uv = new Date(data.ultima_visita.fecha);
      const meses = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
      this.ultimaVisitaDia = uv.getDate().toString();
      this.ultimaVisitaMes = `${meses[uv.getMonth()]} ${uv.getFullYear()}`;
      this.ultimaVisitaDiagnostico = data.ultima_visita.diagnostico ?? 'Sin diagnóstico';
    }

    this.recetas = data.recetas_activas ?? [];
    this.recetasActivasCount = this.recetas.length;
    if (this.recetas.length > 0) {
      this.diasProximaVencer = Math.min(...this.recetas.map(r => r.dias_restantes));
    }

    this.recordatorio = data.recordatorio;
  }

  private formatearFechaHoy(): string {
    const hoy = new Date();
    const dias = ['domingo','lunes','martes','miércoles','jueves','viernes','sábado'];
    const meses = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];
    return `${dias[hoy.getDay()]} ${hoy.getDate()} de ${meses[hoy.getMonth()]} de ${hoy.getFullYear()}`;
  }
}
