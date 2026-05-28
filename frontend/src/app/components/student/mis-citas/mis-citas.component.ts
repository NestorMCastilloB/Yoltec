import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Subject, of } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { MisCitasService, CitaMisCitas } from './mis-citas.service';
import { AgendarCitaComponent } from '../../shared/agendar-cita/agendar-cita.component';
import { PollingService } from '../../../services/polling.service';

type TabId = 'proximas' | 'pasadas' | 'canceladas';

@Component({
  selector: 'app-mis-citas',
  standalone: true,
  imports: [CommonModule, AgendarCitaComponent],
  templateUrl: './mis-citas.component.html',
  styleUrls: ['./mis-citas.component.css'],
})
export class MisCitasComponent implements OnInit, OnDestroy {
  activeTab: TabId = 'proximas';
  readonly tabs: { id: TabId; label: string }[] = [
    { id: 'proximas', label: 'Próximas' },
    { id: 'pasadas', label: 'Pasadas' },
    { id: 'canceladas', label: 'Canceladas' },
  ];

  proximas: CitaMisCitas[] = [];
  pasadas: CitaMisCitas[] = [];
  canceladas: CitaMisCitas[] = [];
  isLoading = false;
  error: string | null = null;
  mensaje: string | null = null;

  showAgendar = false;

  citaCancelando: CitaMisCitas | null = null;
  isCancelling = false;

  private destroy$ = new Subject<void>();
  private readonly MESES = ['ENE','FEB','MAR','ABR','MAY','JUN','JUL','AGO','SEP','OCT','NOV','DIC'];

  constructor(
    private misCitasService: MisCitasService,
    private polling: PollingService,
  ) {}

  ngOnInit(): void {
    this.loadCitas();
    // Refresca cada 45s mientras la pestana este visible — sincroniza cambios hechos por el doctor sin recargar
    this.polling.poll(45).pipe(takeUntil(this.destroy$)).subscribe(() => this.loadCitas());
  }
  ngOnDestroy(): void { this.destroy$.next(); this.destroy$.complete(); }

  onCitaAgendada(): void {
    this.showAgendar = false;
    this.loadCitas();
    this.mostrarMensaje('Cita agendada correctamente.');
  }

  loadCitas(): void {
    this.isLoading = true;
    this.error = null;
    this.misCitasService.getCitasFiltradas()
      .pipe(
        takeUntil(this.destroy$),
        catchError(err => {
          this.error = err?.error?.message || 'Error al cargar citas.';
          return of({ proximas: [], pasadas: [], canceladas: [] });
        }),
        finalize(() => this.isLoading = false),
      )
      .subscribe(data => {
        this.proximas = data.proximas;
        this.pasadas = data.pasadas;
        this.canceladas = data.canceladas;
      });
  }

  get citasActivas(): CitaMisCitas[] {
    const map: Record<TabId, CitaMisCitas[]> = {
      proximas: this.proximas, pasadas: this.pasadas, canceladas: this.canceladas,
    };
    return map[this.activeTab];
  }

  // Agrupa canceladas por mes para reducir saturación visual en historiales largos
  get canceladasAgrupadas(): { mes: string; citas: CitaMisCitas[] }[] {
    const grupos: { mes: string; citas: CitaMisCitas[] }[] = [];
    for (const cita of this.canceladas) {
      const etiqueta = this.formatearMes(cita.fecha_cita);
      const ultimo = grupos[grupos.length - 1];
      if (ultimo && ultimo.mes === etiqueta) {
        ultimo.citas.push(cita);
      } else {
        grupos.push({ mes: etiqueta, citas: [cita] });
      }
    }
    return grupos;
  }

  private formatearMes(fechaIso: string): string {
    const [y, m] = fechaIso.split('-').map(Number);
    if (!y || !m) return fechaIso;
    const txt = new Intl.DateTimeFormat('es-MX', { month: 'long', year: 'numeric' })
      .format(new Date(y, m - 1, 1));
    return txt.charAt(0).toUpperCase() + txt.slice(1);
  }

  getCount(tab: TabId): number {
    const map: Record<TabId, CitaMisCitas[]> = {
      proximas: this.proximas, pasadas: this.pasadas, canceladas: this.canceladas,
    };
    return map[tab].length;
  }

  // -- Cancelar --

  abrirModalCancelar(cita: CitaMisCitas): void { this.citaCancelando = cita; }
  cerrarModalCancelar(): void { this.citaCancelando = null; }

  confirmarCancelar(): void {
    if (!this.citaCancelando) return;
    this.isCancelling = true;
    this.misCitasService.cancelarCita(this.citaCancelando.id)
      .pipe(
        takeUntil(this.destroy$),
        catchError(() => { this.mostrarMensaje('Error al cancelar la cita.'); return of(null); }),
        finalize(() => { this.isCancelling = false; this.citaCancelando = null; }),
      )
      .subscribe(res => {
        if (res) {
          this.mostrarMensaje('Cita cancelada correctamente.');
          this.loadCitas();
        }
      });
  }

  // -- Formateo --

  getDia(fecha: string): string { return fecha.split('-')[2]; }
  getMes(fecha: string): string { return this.MESES[+fecha.split('-')[1] - 1]; }
  getAnio(fecha: string): string { return fecha.split('-')[0]; }

  getDiaSemana(fecha: string): string {
    const [y, m, d] = fecha.split('-').map(Number);
    return new Intl.DateTimeFormat('es-MX', { weekday: 'long' }).format(new Date(y, m - 1, d));
  }

  formatTime(hora: string): string { return hora.substring(0, 5); }

  doctorNombre(cita: CitaMisCitas): string {
    return cita.doctor ? `Dr(a). ${cita.doctor.nombre} ${cita.doctor.apellido}` : '';
  }

  estatusLabel(estatus: string): string {
    const labels: Record<string, string> = {
      programada: 'Pendiente', confirmada: 'Confirmada',
      atendida: 'Atendida', cancelada: 'Cancelada', no_asistio: 'No asistió',
    };
    return labels[estatus] ?? estatus;
  }

  estatusClass(estatus: string): string {
    const classes: Record<string, string> = {
      programada: 'warn', confirmada: 'ok',
      atendida: 'attended', cancelada: 'cancel', no_asistio: 'noshow',
    };
    return classes[estatus] ?? '';
  }

  trackByCita(_: number, c: any): number { return c.id; }

  private mostrarMensaje(msg: string): void {
    this.mensaje = msg;
    setTimeout(() => this.mensaje = null, 4000);
  }
}
