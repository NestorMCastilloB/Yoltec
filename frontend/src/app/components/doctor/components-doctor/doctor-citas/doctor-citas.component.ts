import { Component, OnDestroy, OnInit, Output, EventEmitter, ViewEncapsulation } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subject, of } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { Cita, CitaService } from '../../../../services/cita.service';
import { ConsultaService } from '../../../../services/consulta.service';
import { PerfilMedicoService, PerfilMedico, ConsultaHistorial } from '../../../../services/perfil-medico.service';
import { PollingService } from '../../../../services/polling.service';
import { CitasFiltro } from './doctor-citas-types';
import {
  formatDate,
  formatFechaCorta,
  formatTime,
  generateTimeSlots,
  getCitaInitials,
  getCitaName,
  normalizeTime,
  toDateFromString,
  trackByCita,
} from './doctor-citas-utils';
import { DoctorCitasFiltrosComponent } from './filtros/doctor-citas-filtros.component';
import { DoctorCitasWeekGridComponent } from './week-grid/doctor-citas-week-grid.component';
import { DoctorCitasDetailDrawerComponent } from './detail-drawer/doctor-citas-detail-drawer.component';
import { NuevaCitaModalComponent } from './nueva-cita-modal/nueva-cita-modal.component';

@Component({
  selector: 'app-doctor-citas',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    DoctorCitasFiltrosComponent,
    DoctorCitasWeekGridComponent,
    DoctorCitasDetailDrawerComponent,
    NuevaCitaModalComponent,
  ],
  templateUrl: './doctor-citas.component.html',
  styleUrls: ['./doctor-citas.component.css'],
  encapsulation: ViewEncapsulation.None,
})
export class DoctorCitasComponent implements OnInit, OnDestroy {
  @Output() openFicha = new EventEmitter<number>();

  citas: Cita[] = [];
  isLoadingCitas = false;
  citasError: string | null = null;
  pendingCitas: Cita[] = [];
  handledCitas: Cita[] = [];

  filtro: CitasFiltro = { search: '', estatus: '', fechaDesde: '', fechaHasta: '' };

  showCreateForm = false;

  // Modal consulta
  showConsultaForm = false;
  consultaCitaId: number | null = null;
  consultaCitaLabel = '';
  consultaForm = { diagnostico: '', tratamiento: '', observaciones: '' };
  consultaMsg: string | null = null;
  isSubmittingConsulta = false;

  // Modal perfil alumno
  showPerfilAlumnoModal = false;
  perfilAlumnoData: PerfilMedico | null = null;
  historialAlumno: ConsultaHistorial[] = [];
  isLoadingPerfilAlumno = false;
  historialAlumnoExpandido: number | null = null;

  // Paginación client-side del historial
  historialPagina = 1;
  readonly historialPorPagina = 10;

  // Drawer de detalle
  drawerCita: Cita | null = null;
  drawerCitaAbierto = false;

  // Modal reprogramar
  showReprogramarModal = false;
  reprogramarCitaId: number | null = null;
  reprogramarFecha = '';
  reprogramarHora = '';
  reprogramarMsg: string | null = null;
  isSubmittingReprogramar = false;

  isSubmitting = false;
  submitMessage: string | null = null;

  readonly timeSlots: string[] = generateTimeSlots();
  readonly today = formatDate(new Date());
  readonly trackByCita = trackByCita;
  readonly getCitaInitials = getCitaInitials;
  readonly getCitaName = getCitaName;
  readonly formatTime = formatTime;
  readonly formatFechaCorta = formatFechaCorta;
  readonly normalizeTime = normalizeTime;

  // Bind necesario para pasar al sub-componente como Input
  readonly citaMatchaFiltro = (c: Cita) => this.filterCitas([c]).length > 0;

  private destroy$ = new Subject<void>();

  constructor(
    private citaService: CitaService,
    private consultaService: ConsultaService,
    private perfilMedicoService: PerfilMedicoService,
    private polling: PollingService,
  ) { }

  ngOnInit(): void {
    this.loadCitas();
    // Refresca cada 20s mientras la pestana este visible — citas nuevas/canceladas aparecen sin recargar
    this.polling.poll(20).pipe(takeUntil(this.destroy$)).subscribe(() => this.loadCitas());
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  get filteredPendingCitas(): Cita[] { return this.filterCitas(this.pendingCitas); }
  get filteredHandledCitas(): Cita[] { return this.filterCitas(this.handledCitas); }

  get hayFiltroActivo(): boolean {
    const f = this.filtro;
    return !!(f.search.trim() || f.estatus || f.fechaDesde || f.fechaHasta);
  }

  get pagedHandledCitas(): Cita[] {
    const start = (this.historialPagina - 1) * this.historialPorPagina;
    return this.filteredHandledCitas.slice(start, start + this.historialPorPagina);
  }

  get totalPaginasHistorial(): number {
    return Math.max(1, Math.ceil(this.filteredHandledCitas.length / this.historialPorPagina));
  }

  cambiarPaginaHistorial(p: number): void {
    if (p < 1 || p > this.totalPaginasHistorial) return;
    this.historialPagina = p;
  }

  get citasHoy(): number {
    return this.citas.filter(c => c.fecha_cita === this.today).length;
  }

  get proximaCitaObj(): Cita | null {
    return this.pendingCitas.find(c => c.fecha_cita >= this.today) ?? null;
  }

  get canceladasMes(): number {
    const ahora = new Date();
    return this.citas.filter(c => {
      if (c.estatus !== 'cancelada') return false;
      const [y, m] = c.fecha_cita.split('-').map(Number);
      return y === ahora.getFullYear() && (m ?? 0) === ahora.getMonth() + 1;
    }).length;
  }

  estatusLabelHistorial(c: Cita): string {
    return c.estatus === 'atendida' ? 'Atendida' : c.estatus === 'cancelada' ? 'Cancelada' : 'No asistió';
  }

  limpiarFiltros(): void {
    this.filtro = { search: '', estatus: '', fechaDesde: '', fechaHasta: '' };
    this.historialPagina = 1;
  }

  onFiltroChange(filtro: CitasFiltro): void {
    this.filtro = filtro;
    this.historialPagina = 1;
  }

  toggleCreateForm(): void {
    this.showCreateForm = !this.showCreateForm;
  }

  onCitaCreated(): void {
    this.showCreateForm = false;
    this.loadCitas();
  }

  onCancelCita(cita: Cita): void {
    if (this.isSubmitting) return;
    this.isSubmitting = true;
    this.citaService.cancelCita(cita.id)
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => { this.submitMessage = error?.error?.message || 'No se pudo cancelar la cita.'; return of(null); }),
        finalize(() => { this.isSubmitting = false; })
      )
      .subscribe(response => {
        if (response?.cita) {
          this.submitMessage = 'Cita cancelada correctamente.';
          this.loadCitas();
        }
      });
  }

  onMarkAsAttended(cita: Cita): void {
    this.consultaCitaId = cita.id;
    this.consultaCitaLabel = `${cita.alumno?.nombre ?? ''} ${cita.alumno?.apellido ?? ''} — ${cita.fecha_cita}`;
    this.consultaForm = { diagnostico: '', tratamiento: '', observaciones: '' };
    this.consultaMsg = null;
    this.showConsultaForm = true;
  }

  closeConsultaForm(): void {
    this.showConsultaForm = false;
    this.consultaCitaId = null;
    this.consultaMsg = null;
  }

  submitConsulta(): void {
    if (!this.consultaCitaId) return;
    if (!this.consultaForm.diagnostico.trim() || !this.consultaForm.tratamiento.trim()) {
      this.consultaMsg = 'Diagnóstico y tratamiento son obligatorios.';
      return;
    }
    this.isSubmittingConsulta = true;
    this.consultaMsg = null;
    this.consultaService.guardar(this.consultaCitaId, this.consultaForm)
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => { this.consultaMsg = error?.error?.message || 'Error al guardar la consulta.'; return of(null); }),
        finalize(() => { this.isSubmittingConsulta = false; })
      )
      .subscribe(response => {
        if (response) {
          this.consultaMsg = 'Consulta guardada y cita marcada como atendida.';
          this.loadCitas();
          this.closeConsultaForm();
        }
      });
  }

  onMarkAsNoShow(cita: Cita): void {
    if (this.isSubmitting) return;
    this.isSubmitting = true;
    this.citaService.markAsNoShow(cita.id)
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => { this.submitMessage = error?.error?.message || 'No se pudo marcar como no asistida.'; return of(null); }),
        finalize(() => { this.isSubmitting = false; })
      )
      .subscribe(response => {
        if (response?.cita) {
          this.submitMessage = 'Cita marcada como no asistida.';
          this.loadCitas();
        }
      });
  }

  openPerfilAlumno(alumnoId: number): void {
    this.showPerfilAlumnoModal = true;
    this.perfilAlumnoData = null;
    this.historialAlumno = [];
    this.historialAlumnoExpandido = null;
    this.isLoadingPerfilAlumno = true;

    this.perfilMedicoService.getPerfilAlumno(alumnoId)
      .pipe(takeUntil(this.destroy$), catchError(() => of(null)), finalize(() => { this.isLoadingPerfilAlumno = false; }))
      .subscribe(res => { if (res) this.perfilAlumnoData = res.perfil; });

    this.perfilMedicoService.getHistorialAlumno(alumnoId)
      .pipe(takeUntil(this.destroy$), catchError(() => of(null)))
      .subscribe(res => { if (res) this.historialAlumno = res.historial; });
  }

  closePerfilAlumno(): void {
    this.showPerfilAlumnoModal = false;
    this.perfilAlumnoData = null;
    this.historialAlumno = [];
  }

  toggleHistorialAlumnoItem(id: number): void {
    this.historialAlumnoExpandido = this.historialAlumnoExpandido === id ? null : id;
  }

  openReprogramar(cita: Cita): void {
    this.reprogramarCitaId = cita.id;
    this.reprogramarFecha = cita.fecha_cita;
    this.reprogramarHora = normalizeTime(cita.hora_cita);
    this.reprogramarMsg = null;
    this.showReprogramarModal = true;
  }

  closeReprogramar(): void {
    this.showReprogramarModal = false;
    this.reprogramarCitaId = null;
    this.reprogramarMsg = null;
  }

  submitReprogramar(): void {
    if (!this.reprogramarCitaId || !this.reprogramarFecha || !this.reprogramarHora) {
      this.reprogramarMsg = 'Selecciona fecha y hora.';
      return;
    }
    this.isSubmittingReprogramar = true;
    this.reprogramarMsg = null;
    this.citaService.reprogramarCita(this.reprogramarCitaId, this.reprogramarFecha, this.reprogramarHora)
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => { this.reprogramarMsg = error?.error?.message || 'No se pudo reprogramar.'; return of(null); }),
        finalize(() => { this.isSubmittingReprogramar = false; })
      )
      .subscribe(response => {
        if (response) {
          this.reprogramarMsg = 'Cita reprogramada correctamente.';
          this.loadCitas();
          this.closeReprogramar();
        }
      });
  }

  openDrawer(cita: Cita): void {
    this.drawerCita = cita;
    this.drawerCitaAbierto = true;
  }

  closeDrawer(): void {
    this.drawerCita = null;
    this.drawerCitaAbierto = false;
  }

  drawerAtender(cita: Cita): void { this.closeDrawer(); this.onMarkAsAttended(cita); }
  drawerCancelar(cita: Cita): void { this.closeDrawer(); this.onCancelCita(cita); }
  drawerNoAsistio(cita: Cita): void { this.closeDrawer(); this.onMarkAsNoShow(cita); }
  drawerReprogramar(cita: Cita): void { this.closeDrawer(); this.openReprogramar(cita); }

  // Filtra slots a futuras si fecha == hoy; devuelve todos si es fecha posterior.
  slotsParaFecha(fecha: string): string[] {
    if (fecha !== this.today) return this.timeSlots;
    const now = new Date();
    const horaActual = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
    return this.timeSlots.filter(s => s > horaActual);
  }

  private filterCitas(citas: Cita[]): Cita[] {
    let result = citas;
    const q = this.filtro.search.trim().toLowerCase();
    if (q) {
      result = result.filter(c => {
        const nombre = `${c.alumno?.nombre ?? ''} ${c.alumno?.apellido ?? ''}`.toLowerCase();
        return nombre.includes(q) || (c.alumno?.numero_control ?? '').toLowerCase().includes(q) || (c.motivo ?? '').toLowerCase().includes(q);
      });
    }
    if (this.filtro.estatus) {
      result = result.filter(c => c.estatus === this.filtro.estatus);
    }
    if (this.filtro.fechaDesde) {
      result = result.filter(c => c.fecha_cita >= this.filtro.fechaDesde);
    }
    if (this.filtro.fechaHasta) {
      result = result.filter(c => c.fecha_cita <= this.filtro.fechaHasta);
    }
    return result;
  }

  private loadCitas(): void {
    this.isLoadingCitas = true;
    this.citasError = null;
    this.citaService.getCitas()
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => { this.citasError = error?.error?.message || 'No se pudieron obtener las citas.'; return of([] as Cita[]); }),
        finalize(() => { this.isLoadingCitas = false; })
      )
      .subscribe(citas => {
        this.citas = citas;
        this.pendingCitas = citas
          .filter(c => c.estatus === 'programada')
          .sort((a, b) => toDateFromString(a.fecha_cita, a.hora_cita).getTime() - toDateFromString(b.fecha_cita, b.hora_cita).getTime());
        this.handledCitas = citas
          .filter(c => c.estatus !== 'programada')
          .sort((a, b) => toDateFromString(b.fecha_cita, b.hora_cita).getTime() - toDateFromString(a.fecha_cita, a.hora_cita).getTime());
      });
  }
}
