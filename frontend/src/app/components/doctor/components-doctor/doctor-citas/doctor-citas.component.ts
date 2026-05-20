import { Component, OnDestroy, OnInit, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, NgForm } from '@angular/forms';
import { Subject, of } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { Cita, CitaService, CreateCitaPayload, AvailabilityStatus, CitaAvailabilityDay } from '../../../../services/cita.service';
import { ConsultaService } from '../../../../services/consulta.service';
import { PerfilMedicoService, PerfilMedico, ConsultaHistorial } from '../../../../services/perfil-medico.service';

type CalendarAvailability = 'none' | AvailabilityStatus;

interface DayAvailabilityRecord {
  takenSlots: Set<string>;
  status: AvailabilityStatus;
  color?: string;
  label?: string | null;
  horaCierre?: string | null;
}

interface CalendarDay {
  date: string;
  label: number;
  isCurrentMonth: boolean;
  isToday: boolean;
  isPast: boolean;
  availability: CalendarAvailability;
  color?: string | null;
  labelText?: string | null;
}

@Component({
  selector: 'app-doctor-citas',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './doctor-citas.component.html',
  styleUrls: ['./doctor-citas.component.css']   // <-- Línea faltante
})

export class DoctorCitasComponent implements OnInit, OnDestroy {
  @Output() openFicha = new EventEmitter<number>();

  citas: Cita[] = [];
  isLoadingCitas = false;
  citasError: string | null = null;
  pendingCitas: Cita[] = [];
  handledCitas: Cita[] = [];
  searchCitas = '';

  showCreateForm = false;
  isSubmitting = false;
  submitMessage: string | null = null;

  createFormData: Partial<CreateCitaPayload & { numero_control: string }> = {
    fecha_cita: '', hora_cita: '', motivo: '', numero_control: ''
  };

  readonly timeSlots: string[] = this.generateTimeSlots();
  readonly totalSlotsPerDay = this.timeSlots.length;
  readonly weekDays: string[] = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
  currentMonth: Date = this.startOfMonth(new Date());
  calendarWeeks: CalendarDay[][] = [];
  availabilityMap: Map<string, DayAvailabilityRecord> = new Map();
  isLoadingAvailability = false;

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

  // Filtros
  filtroEstatus = '';
  filtroFechaDesde = '';
  filtroFechaHasta = '';

  // Paginación client-side del historial
  historialPagina = 1;
  readonly historialPorPagina = 10;

  // Drawer de detalle
  drawerCita: Cita | null = null;
  drawerCitaAbierto = false;

  // Modal nueva cita — pasos
  createStep: 1 | 2 | 3 = 1;

  // Modal reprogramar
  showReprogramarModal = false;
  reprogramarCitaId: number | null = null;
  reprogramarFecha = '';
  reprogramarHora = '';
  reprogramarMsg: string | null = null;
  isSubmittingReprogramar = false;

  // Vista semanal grid
  currentWeekStart: Date = this.getMonday(new Date());
  readonly hourGridSlots: number[] = [8, 9, 10, 11, 12, 13, 14, 15, 16];
  readonly gridDayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

  readonly today = this.formatDate(new Date());
  private destroy$ = new Subject<void>();

  constructor(
    private citaService: CitaService,
    private consultaService: ConsultaService,
    private perfilMedicoService: PerfilMedicoService
  ) { }

  ngOnInit(): void {
    this.buildCalendar();
    this.loadAvailability();
    this.loadCitas();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  get filteredPendingCitas(): Cita[] { return this.filterCitas(this.pendingCitas); }
  get filteredHandledCitas(): Cita[] { return this.filterCitas(this.handledCitas); }

  // True si hay algún filtro activo — usado para atenuar el calendario
  get hayFiltroActivo(): boolean {
    return !!(this.searchCitas.trim() || this.filtroEstatus || this.filtroFechaDesde || this.filtroFechaHasta);
  }

  // True si la cita matchea los filtros activos — para atenuar grid semanal
  citaMatchaFiltro(cita: Cita): boolean {
    return this.filterCitas([cita]).length > 0;
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

  private filterCitas(citas: Cita[]): Cita[] {
    let result = citas;
    const q = this.searchCitas.trim().toLowerCase();
    if (q) {
      result = result.filter(c => {
        const nombre = `${c.alumno?.nombre ?? ''} ${c.alumno?.apellido ?? ''}`.toLowerCase();
        return nombre.includes(q) || (c.alumno?.numero_control ?? '').toLowerCase().includes(q) || (c.motivo ?? '').toLowerCase().includes(q);
      });
    }
    if (this.filtroEstatus) {
      result = result.filter(c => c.estatus === this.filtroEstatus);
    }
    if (this.filtroFechaDesde) {
      result = result.filter(c => c.fecha_cita >= this.filtroFechaDesde);
    }
    if (this.filtroFechaHasta) {
      result = result.filter(c => c.fecha_cita <= this.filtroFechaHasta);
    }
    return result;
  }

  limpiarFiltros(): void {
    this.filtroEstatus = '';
    this.filtroFechaDesde = '';
    this.filtroFechaHasta = '';
    this.searchCitas = '';
    this.historialPagina = 1;
  }

  get calendarLabel(): string {
    return new Intl.DateTimeFormat('es-MX', { month: 'long', year: 'numeric' }).format(this.currentMonth);
  }

  get isCurrentMonth(): boolean {
    const now = new Date();
    return this.currentMonth.getFullYear() === now.getFullYear() && this.currentMonth.getMonth() === now.getMonth();
  }

  // Aviso para días con atención reducida — null si el día es normal o no seleccionado
  get selectedDayWarning(): string | null {
    const fecha = this.createFormData.fecha_cita;
    if (!fecha) return null;
    const rec = this.getDayRecord(fecha);
    if (!rec || rec.status !== 'partial') return null;
    const baseMsg = rec.label ? `Atención reducida hoy: ${rec.label}` : 'Este día tiene atención reducida.';
    return rec.horaCierre ? `${baseMsg} (cierre a las ${rec.horaCierre})` : baseMsg;
  }

  get hasAvailableSlotsForSelectedDate(): boolean {
    if (!this.createFormData.fecha_cita) return false;
    const record = this.getDayRecord(this.createFormData.fecha_cita);
    if (record?.status === 'full') return false;
    const takenSlots = record?.takenSlots ?? new Set<string>();
    return this.timeSlots.some(slot => !takenSlots.has(this.normalizeTime(slot)));
  }

  toggleCreateForm(): void {
    this.showCreateForm = !this.showCreateForm;
    this.createStep = 1;
    this.submitMessage = null;
    if (this.showCreateForm) {
      this.loadAvailability();
    } else {
      this.resetForm();
    }
  }

  changeMonth(direction: number): void {
    this.currentMonth = this.startOfMonth(new Date(this.currentMonth.getFullYear(), this.currentMonth.getMonth() + direction, 1));
    this.availabilityMap = new Map();
    this.buildCalendar();
    this.loadAvailability();
  }

  selectCalendarDay(day: CalendarDay): void {
    if (day.isPast || !day.isCurrentMonth || day.availability === 'full') return;
    this.onDateChange(day.date);
  }

  selectTimeSlot(slot: string): void {
    if (!this.createFormData.fecha_cita || this.isSlotUnavailable(slot)) return;
    this.createFormData.hora_cita = this.normalizeTime(slot);
    this.submitMessage = null;
  }

  onCreateCita(form: NgForm): void {
    const noCtrl = this.createFormData.numero_control?.trim();
    if (!noCtrl || !this.createFormData.fecha_cita || !this.createFormData.hora_cita) {
      this.submitMessage = 'Completa todos los campos requeridos.';
      return;
    }

    const normalizedTime = this.normalizeTime(this.createFormData.hora_cita!);
    if (this.isSlotUnavailable(normalizedTime)) {
      this.submitMessage = 'La hora seleccionada ya está ocupada.';
      return;
    }

    const payload: CreateCitaPayload = {
      fecha_cita: this.createFormData.fecha_cita!,
      hora_cita: normalizedTime,
      motivo: this.createFormData.motivo || undefined,
      numero_control: (this.createFormData.numero_control ?? '').trim()
    };

    this.isSubmitting = true;
    this.submitMessage = null;

    this.citaService.createCita(payload)
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => {
          const errores = error?.error?.errors;
          if (errores && typeof errores === 'object') {
            const first = Object.keys(errores)[0];
            const msgs = (errores as any)[first];
            if (Array.isArray(msgs) && msgs.length > 0) { this.submitMessage = msgs[0]; return of(null); }
          }
          this.submitMessage = error?.error?.message || 'No se pudo agendar la cita.';
          return of(null);
        }),
        finalize(() => { this.isSubmitting = false; })
      )
      .subscribe(response => {
        if (response?.cita) {
          this.createStep = 1;
          this.loadCitas();
          this.loadAvailability();
          this.resetForm();
          this.showCreateForm = false;
        }
      });
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
          this.loadAvailability();
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
    this.reprogramarHora = this.normalizeTime(cita.hora_cita);
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
          this.loadAvailability();
          this.closeReprogramar();
        }
      });
  }

  // === Drawer de detalle ===

  openDrawer(cita: Cita): void {
    this.drawerCita = cita;
    this.drawerCitaAbierto = true;
  }

  closeDrawer(): void {
    this.drawerCita = null;
    this.drawerCitaAbierto = false;
  }

  drawerAtender(cita: Cita): void {
    this.closeDrawer();
    this.onMarkAsAttended(cita);
  }

  drawerCancelar(cita: Cita): void {
    this.closeDrawer();
    this.onCancelCita(cita);
  }

  drawerNoAsistio(cita: Cita): void {
    this.closeDrawer();
    this.onMarkAsNoShow(cita);
  }

  drawerReprogramar(cita: Cita): void {
    this.closeDrawer();
    this.openReprogramar(cita);
  }

  stepNext(): void {
    if (this.createStep === 1) {
      if (!this.createFormData.numero_control?.trim()) {
        this.submitMessage = 'Ingresa el número de control del alumno.';
        return;
      }
      this.submitMessage = null;
      this.createStep = 2;
    } else if (this.createStep === 2) {
      if (!this.createFormData.fecha_cita) {
        this.submitMessage = 'Selecciona una fecha.';
        return;
      }
      if (!this.createFormData.hora_cita) {
        this.submitMessage = 'Selecciona una hora.';
        return;
      }
      this.submitMessage = null;
      this.createStep = 3;
    }
  }

  stepBack(): void {
    if (this.createStep > 1) this.createStep = (this.createStep - 1) as 1 | 2 | 3;
    this.submitMessage = null;
  }

  formatFechaCorta(fecha: string): string {
    if (!fecha) return '—';
    const [y, m, d] = fecha.split('-').map(Number);
    return new Intl.DateTimeFormat('es-MX', { day: 'numeric', month: 'short', year: 'numeric' })
      .format(new Date(y, (m ?? 1) - 1, d ?? 1)).toUpperCase();
  }

  // === Vista semanal ===

  get weekGridDays(): { date: string; label: string; isToday: boolean }[] {
    const days: { date: string; label: string; isToday: boolean }[] = [];
    const dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    for (let i = 0; i < 6; i++) {
      const d = new Date(this.currentWeekStart);
      d.setDate(d.getDate() + i);
      const dateStr = this.formatDate(d);
      days.push({
        date: dateStr,
        label: `${dayNames[i]} ${d.getDate()}`,
        isToday: dateStr === this.today
      });
    }
    return days;
  }

  get weekLabel(): string {
    const end = new Date(this.currentWeekStart);
    end.setDate(end.getDate() + 5);
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    const startDay = this.currentWeekStart.getDate();
    const endDay = end.getDate();
    const month = months[end.getMonth()];
    return `Semana del ${startDay} al ${endDay} ${month}`;
  }

  changeWeek(direction: number): void {
    const next = new Date(this.currentWeekStart);
    next.setDate(next.getDate() + (direction * 7));
    this.currentWeekStart = next;
  }

  goToThisWeek(): void {
    this.currentWeekStart = this.getMonday(new Date());
  }

  getCitasForSlot(date: string, hour: number): Cita[] {
    return this.citas.filter(c => {
      if (c.fecha_cita !== date) return false;
      const h = parseInt(c.hora_cita.split(':')[0], 10);
      return h === hour;
    });
  }

  getGridCitaClass(cita: Cita): string {
    switch (cita.estatus) {
      case 'programada': return 'ok';
      case 'atendida': return 'ok';
      case 'cancelada': return 'cancel';
      case 'no_asistio': return 'cancel';
      default: return 'warn';
    }
  }

  getGridCitaInitials(cita: Cita): string {
    const n = cita.alumno?.nombre ?? '';
    const a = cita.alumno?.apellido ?? '';
    return (n.charAt(0) + a.charAt(0)).toUpperCase();
  }

  getGridCitaName(cita: Cita): string {
    const n = cita.alumno?.nombre ?? '';
    const a = cita.alumno?.apellido ?? '';
    return `${n} ${a}`.trim();
  }

  private getMonday(date: Date): Date {
    const d = new Date(date);
    const day = d.getDay();
    const diff = day === 0 ? -6 : 1 - day;
    d.setDate(d.getDate() + diff);
    d.setHours(0, 0, 0, 0);
    return d;
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
        const ahora = new Date();
        this.pendingCitas = citas
          .filter(c => c.estatus === 'programada')
          .sort((a, b) => this.toDate(a.fecha_cita, a.hora_cita).getTime() - this.toDate(b.fecha_cita, b.hora_cita).getTime());
        this.handledCitas = citas
          .filter(c => c.estatus !== 'programada')
          .sort((a, b) => this.toDate(b.fecha_cita, b.hora_cita).getTime() - this.toDate(a.fecha_cita, a.hora_cita).getTime());
      });
  }

  private loadAvailability(): void {
    this.isLoadingAvailability = true;
    const month = this.currentMonth.getMonth() + 1;
    const year = this.currentMonth.getFullYear();
    this.citaService.getAvailability(month, year)
      .pipe(
        takeUntil(this.destroy$),
        catchError(() => of(null)),
        finalize(() => { this.isLoadingAvailability = false; })
      )
      .subscribe(response => {
        if (response?.days) {
          this.applyAvailability(response.days);
        } else {
          this.availabilityMap = new Map();
        }
        this.buildCalendar();
      });
  }

  private applyAvailability(days: CitaAvailabilityDay[]): void {
    const map = new Map<string, DayAvailabilityRecord>();
    days.forEach(day => {
      const takenSlots = new Set<string>((day.taken_slots || []).map(s => this.normalizeTime(s)));
      let status: AvailabilityStatus;
      if (day.special?.status) {
        status = day.special.status;
      } else if (takenSlots.size === 0) {
        status = 'available';
      } else if (takenSlots.size >= this.totalSlotsPerDay) {
        status = 'full';
      } else {
        status = 'partial';
      }
      map.set(day.date, { takenSlots, status, color: day.special?.color ?? undefined, label: day.special?.label ?? null, horaCierre: day.special?.hora_cierre ?? null });
    });
    this.availabilityMap = map;
  }

  private buildCalendar(): void {
    const reference = this.startOfMonth(this.currentMonth);
    const firstDayIndex = reference.getDay();
    const calendarStart = new Date(reference);
    calendarStart.setDate(calendarStart.getDate() - firstDayIndex);

    const today = this.startOfDay(new Date());
    const weeks: CalendarDay[][] = [];
    let cursor = new Date(calendarStart);

    for (let week = 0; week < 6; week++) {
      const weekDays: CalendarDay[] = [];
      for (let dayIndex = 0; dayIndex < 7; dayIndex++) {
        const date = new Date(cursor);
        const dateStr = this.formatDate(date);
        const isCurrentMonth = date.getMonth() === reference.getMonth();
        const isPast = this.startOfDay(date).getTime() < today.getTime();
        const isToday = this.startOfDay(date).getTime() === today.getTime();
        const meta = this.resolveCalendarMetadata(dateStr, isCurrentMonth, isPast);
        weekDays.push({ date: dateStr, label: date.getDate(), isCurrentMonth, isToday, isPast, ...meta });
        cursor.setDate(cursor.getDate() + 1);
      }
      weeks.push(weekDays);
    }
    this.calendarWeeks = weeks;
  }

  private resolveCalendarMetadata(dateStr: string, isCurrentMonth: boolean, isPast: boolean): { availability: CalendarAvailability; color: string | null; labelText: string | null } {
    if (!isCurrentMonth || isPast) return { availability: 'none', color: null, labelText: null };
    if (this.toDate(dateStr).getDay() === 0) return { availability: 'full', color: '#ef5350', labelText: 'Cerrado' };
    const record = this.getDayRecord(dateStr);
    if (!record) return { availability: 'available', color: this.getStatusColor('available'), labelText: null };
    return { availability: record.status, color: record.color ?? this.getStatusColor(record.status), labelText: record.label ?? null };
  }

  private getDayRecord(date: string): DayAvailabilityRecord | undefined {
    return this.availabilityMap.get(date);
  }

  public isSelectedDate(date: string): boolean { return this.createFormData.fecha_cita === date; }

  public isDayUnavailable(day: CalendarDay): boolean {
    return !day.isCurrentMonth || day.isPast || day.availability === 'full';
  }

  public getDayStyle(day: CalendarDay): { [key: string]: string } | null {
    if (day.availability === 'none') return null;
    const baseColor = day.color ?? this.getStatusColor(day.availability);
    const background = this.applyOpacity(baseColor, day.availability === 'full' ? 0.25 : 0.15);
    const border = this.applyOpacity(baseColor, 0.6);
    const style: { [key: string]: string } = { 'background-color': background, 'border-color': border };
    if (day.isToday) style['box-shadow'] = `0 0 0 2px ${this.applyOpacity('#1e88e5', 0.4)}`;
    return style;
  }

  public onDateChange(date: string): void {
    this.createFormData.fecha_cita = date;
    if (this.createFormData.hora_cita && this.isSlotUnavailable(this.createFormData.hora_cita)) {
      this.createFormData.hora_cita = '';
    }
    this.submitMessage = null;
    this.buildCalendar();
  }

  public isSlotUnavailable(slot: string): boolean {
    if (!this.createFormData.fecha_cita) return false;
    const normalizedSlot = this.normalizeTime(slot);
    if (this.createFormData.fecha_cita === this.today) {
      const [hours, minutes] = normalizedSlot.split(':').map(Number);
      const slotDate = new Date();
      slotDate.setHours(hours ?? 0, minutes ?? 0, 0, 0);
      if (slotDate.getTime() <= new Date().getTime()) return true;
    }
    const record = this.getDayRecord(this.createFormData.fecha_cita);
    if (record?.status === 'full') return true;
    if (record?.horaCierre && normalizedSlot >= record.horaCierre) return true;
    if (record?.takenSlots.has(normalizedSlot)) return true;
    return this.citas.some(c =>
      c.fecha_cita === this.createFormData.fecha_cita &&
      c.estatus === 'programada' &&
      this.normalizeTime(c.hora_cita) === normalizedSlot
    );
  }

  public formatDateDisplay(fecha: string): string {
    const date = this.toDate(fecha);
    return new Intl.DateTimeFormat('es-MX', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' }).format(date);
  }

  public formatTime(hora: string): string {
    const [hours, minutes] = this.normalizeTime(hora).split(':').map(Number);
    const date = new Date();
    date.setHours(hours, minutes || 0, 0, 0);
    return new Intl.DateTimeFormat('es-MX', { hour: '2-digit', minute: '2-digit', hour12: false }).format(date);
  }

  public normalizeTime(hora: string): string {
    const [hours, minutes] = hora.split(':');
    return `${hours?.padStart(2, '0')}:${(minutes ?? '00').padStart(2, '0')}`;
  }

  private resetForm(): void {
    this.createFormData = { fecha_cita: '', hora_cita: '', motivo: '', numero_control: '' };
  }

  private formatDate(date: Date): string {
    const y = date.getFullYear();
    const m = String(date.getMonth() + 1).padStart(2, '0');
    const d = String(date.getDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
  }

  private toDate(fecha: string, hora?: string): Date {
    const [year, month, day] = fecha.split('-').map(Number);
    if (hora) {
      const [h, min] = this.normalizeTime(hora).split(':').map(Number);
      return new Date(year, (month ?? 1) - 1, day ?? 1, h ?? 0, min ?? 0);
    }
    return new Date(year, (month ?? 1) - 1, day ?? 1);
  }

  private startOfDay(date: Date): Date { return new Date(date.getFullYear(), date.getMonth(), date.getDate()); }
  private startOfMonth(date: Date): Date { return new Date(date.getFullYear(), date.getMonth(), 1); }

  private getStatusColor(status: CalendarAvailability): string {
    switch (status) {
      case 'available': return '#1e88e5';
      case 'partial': return '#ffb300';
      case 'full': return '#ef5350';
      default: return '#cfd8dc';
    }
  }

  private applyOpacity(hexColor: string, alpha: number): string {
    const rgb = this.hexToRgb(hexColor);
    if (!rgb) return hexColor;
    return `rgba(${rgb.r}, ${rgb.g}, ${rgb.b}, ${alpha})`;
  }

  private hexToRgb(hex: string): { r: number; g: number; b: number } | null {
    let h = hex.replace('#', '');
    if (h.length === 3) h = h.split('').map(c => c + c).join('');
    if (h.length !== 6) return null;
    const n = parseInt(h, 16);
    return { r: (n >> 16) & 255, g: (n >> 8) & 255, b: n & 255 };
  }

  private generateTimeSlots(): string[] {
    const slots: string[] = [];
    for (let hour = 8; hour < 17; hour++) {
      ['00', '15', '30', '45'].forEach(min => slots.push(`${String(hour).padStart(2, '0')}:${min}`));
    }
    return slots;
  }

  // Filtra slots a futuras si fecha == hoy; devuelve todos si es fecha posterior.
  slotsParaFecha(fecha: string): string[] {
    if (fecha !== this.today) return this.timeSlots;
    const now = new Date();
    const horaActual = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
    return this.timeSlots.filter(s => s > horaActual);
  }
}
