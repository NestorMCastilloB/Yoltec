import { Component, Input, Output, EventEmitter, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Subject, of, forkJoin } from 'rxjs';
import { catchError, takeUntil } from 'rxjs/operators';
import { Cita, CitaService } from '../../../../services/cita.service';
import { RecetaService } from '../../../../services/receta.service';
import { PollingService } from '../../../../services/polling.service';

interface ActividadItem {
  tipo: string;
  icono: string;
  titulo: string;
  detalle: string;
  tiempo: string;
}

@Component({
  selector: 'app-doctor-inicio',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './doctor-inicio.component.html',
  styleUrls: ['./doctor-inicio.component.css']
})
export class DoctorInicioComponent implements OnInit, OnDestroy {
  @Input() doctorName = 'Doctor';
  @Output() openCita = new EventEmitter<Cita>();

  todayAppointments = 0;
  patientsAttended = 0;
  totalRecetas = 0;
  asistenciaPct = 0;
  proximaCita: Cita | null = null;
  todayCitas: Cita[] = [];
  todayFormatted = '';
  actividadReciente: ActividadItem[] = [];

  private readonly today = this.formatDate(new Date());
  private destroy$ = new Subject<void>();

  constructor(
    private citaService: CitaService,
    private recetaService: RecetaService,
    private polling: PollingService,
  ) {}

  ngOnInit(): void {
    this.todayFormatted = this.formatDisplayDate(new Date());
    this.recargarDatos();
    // Refresca cada 20s mientras la pestana este visible — doctor necesita ver citas nuevas sin recargar
    this.polling.poll(20).pipe(takeUntil(this.destroy$)).subscribe(() => this.recargarDatos());
  }

  private recargarDatos(): void {
    forkJoin({
      citas: this.citaService.getCitas().pipe(catchError(() => of([] as Cita[]))),
      recetas: this.recetaService.getRecetas().pipe(catchError(() => of([] as any[])))
    })
    .pipe(takeUntil(this.destroy$))
    .subscribe(({ citas, recetas }) => {
      const ahora = new Date();

      // KPIs
      this.todayCitas = citas.filter(c => c.fecha_cita === this.today);
      this.todayAppointments = citas.filter(c => c.estatus === 'programada' && c.fecha_cita === this.today).length;
      this.patientsAttended = citas.filter(c => c.estatus === 'atendida').length;
      this.totalRecetas = recetas.length;

      // Asistencia: atendidas / (atendidas + no_asistio) * 100
      const atendidas = citas.filter(c => c.estatus === 'atendida').length;
      const noAsistio = citas.filter(c => c.estatus === 'no_asistio').length;
      this.asistenciaPct = (atendidas + noAsistio) > 0
        ? Math.round((atendidas / (atendidas + noAsistio)) * 100)
        : 100;

      // Próxima cita
      const pending = citas
        .filter(c => c.estatus === 'programada')
        .sort((a, b) => this.toDate(a.fecha_cita, a.hora_cita).getTime() - this.toDate(b.fecha_cita, b.hora_cita).getTime());
      this.proximaCita = pending.find(c => this.toDate(c.fecha_cita, c.hora_cita) >= ahora) ?? pending[0] ?? null;

      // Actividad reciente
      this.actividadReciente = this.buildActividad(citas, recetas);
    });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  getInitials(cita: Cita): string {
    const nombre = cita.alumno?.nombre ?? '';
    const apellido = cita.alumno?.apellido ?? '';
    return (nombre.charAt(0) + apellido.charAt(0)).toUpperCase();
  }

  private buildActividad(citas: Cita[], recetas: any[]): ActividadItem[] {
    const items: ActividadItem[] = [];

    // Últimas citas atendidas
    const atendidas = citas
      .filter(c => c.estatus === 'atendida')
      .sort((a, b) => this.toDate(b.fecha_cita, b.hora_cita).getTime() - this.toDate(a.fecha_cita, a.hora_cita).getTime())
      .slice(0, 2);

    for (const c of atendidas) {
      items.push({
        tipo: 'cita',
        icono: '⊞',
        titulo: 'Cita atendida',
        detalle: `${c.alumno?.nombre ?? ''} ${c.alumno?.apellido ?? ''} · ${c.hora_cita}`,
        tiempo: this.relativeTime(c.fecha_cita, c.hora_cita)
      });
    }

    // Últimas recetas
    const recentRecetas = recetas.slice(-2).reverse();
    for (const r of recentRecetas) {
      items.push({
        tipo: 'receta',
        icono: '℞',
        titulo: 'Receta emitida',
        detalle: r.alumno ? `${r.alumno.nombre ?? ''} ${r.alumno.apellido ?? ''}` : 'Paciente',
        tiempo: r.created_at ? this.relativeDate(r.created_at) : ''
      });
    }

    // Últimas cancelaciones
    const canceladas = citas
      .filter(c => c.estatus === 'cancelada')
      .sort((a, b) => this.toDate(b.fecha_cita, b.hora_cita).getTime() - this.toDate(a.fecha_cita, a.hora_cita).getTime())
      .slice(0, 1);

    for (const c of canceladas) {
      items.push({
        tipo: 'cancel',
        icono: '✕',
        titulo: 'Cita cancelada',
        detalle: `${c.alumno?.nombre ?? ''} ${c.alumno?.apellido ?? ''} · ${c.fecha_cita}`,
        tiempo: this.relativeTime(c.fecha_cita, c.hora_cita)
      });
    }

    return items.slice(0, 5);
  }

  private relativeTime(fecha: string, hora?: string): string {
    const d = this.toDate(fecha, hora);
    const diff = Date.now() - d.getTime();
    const mins = Math.floor(diff / 60000);
    if (mins < 60) return `${mins}m`;
    const hrs = Math.floor(mins / 60);
    if (hrs < 24) return `${hrs}h`;
    return fecha === this.today ? 'Hoy' : 'Ayer';
  }

  private relativeDate(dateStr: string): string {
    const d = new Date(dateStr);
    const diff = Date.now() - d.getTime();
    const hrs = Math.floor(diff / 3600000);
    if (hrs < 1) return 'Ahora';
    if (hrs < 24) return `${hrs}h`;
    if (hrs < 48) return 'Ayer';
    return `${Math.floor(hrs / 24)}d`;
  }

  private formatDate(date: Date): string {
    const y = date.getFullYear();
    const m = String(date.getMonth() + 1).padStart(2, '0');
    const d = String(date.getDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
  }

  private formatDisplayDate(date: Date): string {
    const days = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return `${days[date.getDay()]}, ${date.getDate()} ${months[date.getMonth()]} ${date.getFullYear()}`;
  }

  private toDate(fecha: string, hora?: string): Date {
    const [year, month, day] = fecha.split('-').map(Number);
    if (hora) {
      const [h, min] = hora.split(':').map(Number);
      return new Date(year, (month ?? 1) - 1, day ?? 1, h ?? 0, min ?? 0);
    }
    return new Date(year, (month ?? 1) - 1, day ?? 1);
  }
}
