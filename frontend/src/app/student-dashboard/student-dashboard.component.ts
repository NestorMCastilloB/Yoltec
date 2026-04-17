import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { FormsModule, NgForm } from '@angular/forms';
import { Subject, of } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { AuthService } from '../services/auth.service';
import { Cita, CitaService, CreateCitaPayload, AvailabilityStatus, CitaAvailabilityDay } from '../services/cita.service';
import { Bitacora, BitacoraService } from '../services/bitacora.service';
import { Receta, RecetaService } from '../services/receta.service';
import { PreEvaluacionIAService, ChatMessage, ChatResponse, PreEvaluacion, PreEvaluacionResult } from '../services/pre-evaluacion-ia.service';
import { PerfilMedicoService, PerfilMedico, ConsultaHistorial } from '../services/perfil-medico.service';

type CalendarAvailability = 'none' | AvailabilityStatus;

interface DayAvailabilityRecord {
  takenSlots: Set<string>;
  status: AvailabilityStatus;
  color?: string;
  label?: string | null;
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
  selector: 'app-student-dashboard',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule],
  templateUrl: './student-dashboard.component.html',
  styleUrls: ['./student-dashboard.component.css']
})
export class StudentDashboardComponent implements OnInit, OnDestroy {
  activeSection: string = 'inicio';
  studentName: string = '';
  today: string = this.formatDate(new Date());

  citas: Cita[] = [];
  isLoadingCitas = false;
  citasError: string | null = null;

  pendingCitas: Cita[] = [];
  handledCitas: Cita[] = [];

  bitacoras: Bitacora[] = [];
  isLoadingBitacoras = false;
  bitacorasError: string | null = null;

  recetas: Receta[] = [];
  isLoadingRecetas = false;
  recetasError: string | null = null;

  nextCitaInfo: { fecha: string; hora: string; motivo?: string } | null = null;
  totalCitasProgramadas = 0;

  showCreateForm = false;
  createFormData: Partial<CreateCitaPayload> = {
    fecha_cita: '',
    hora_cita: '',
    motivo: ''
  };
  readonly timeSlots: string[] = this.generateTimeSlots();
  readonly totalSlotsPerDay = this.timeSlots.length;
  readonly weekDays: string[] = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
  currentMonth: Date = this.startOfMonth(new Date());
  calendarWeeks: CalendarDay[][] = [];
  availabilityMap: Map<string, DayAvailabilityRecord> = new Map();
  isLoadingAvailability = false;

  isSubmitting = false;
  submitMessage: string | null = null;

  // Chat IA - Pre-evaluación
  chatMensajes: ChatMessage[] = [];
  chatInput = '';
  isChatLoading = false;
  showPreEvaluacionForm = false;
  selectedCitaForEvaluacion: Cita | null = null;
  resultadoPreEvaluacion: PreEvaluacionResult | null = null;
  preEvaluaciones: PreEvaluacion[] = [];
  isLoadingPreEvaluaciones = false;
  preEvaluacionError: string | null = null;

  // Perfil médico e historial
  perfilMedico: PerfilMedico | null = null;
  isLoadingPerfil = false;
  perfilMsg: string | null = null;
  perfilForm = { tipo_sangre: '', alergias: '', enfermedades_cronicas: '' };
  isSubmittingPerfil = false;
  historial: ConsultaHistorial[] = [];
  isLoadingHistorial = false;
  historialExpandido: number | null = null;

  // Foto de perfil
  fotoPreview: string | null = null;
  isUploadingFoto = false;
  fotoMsg: string | null = null;

  // Datos personales (edición)
  personalForm = { nombre: '', apellido: '', email: '', telefono: '', fecha_nacimiento: '' };
  isSubmittingPersonal = false;
  personalMsg: string | null = null;
  editandoPersonal = false;

  // Cambiar contraseña
  passwordForm = { password_actual: '', password_nuevo: '', password_nuevo_confirmation: '' };
  isSubmittingPassword = false;
  passwordMsg: string | null = null;

  private destroy$ = new Subject<void>();

  constructor(
    private router: Router,
    private authService: AuthService,
    private citaService: CitaService,
    private bitacoraService: BitacoraService,
    private recetaService: RecetaService,
    private preEvaluacionIAService: PreEvaluacionIAService,
    private perfilMedicoService: PerfilMedicoService
  ) {}

  ngOnInit(): void {
    const user = this.authService.getCurrentUser();
    this.studentName = user ? `${user.nombre} ${user.apellido}` : 'Alumno';
    this.buildCalendar();
    this.loadAvailability();
    this.loadCitas();
    this.loadBitacoras();
    this.loadRecetas();
    this.loadPreEvaluaciones();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  setActiveSection(section: string) {
    this.activeSection = section;
    if (section === 'citas') {
      this.loadCitas();
      this.loadAvailability();
    }
    if (section === 'bitacora') {
      this.loadBitacoras();
    }
    if (section === 'recetas') {
      this.loadRecetas();
    }
    if (section === 'perfil') {
      this.loadPerfil();
    }
    if (section === 'historial') {
      this.loadHistorial();
    }
  }

  loadPerfil(): void {
    this.isLoadingPerfil = true;
    this.perfilMedicoService.getPerfil()
      .pipe(takeUntil(this.destroy$), catchError(() => of(null)), finalize(() => this.isLoadingPerfil = false))
      .subscribe(res => {
        if (res) {
          this.perfilMedico = res.perfil;
          this.perfilForm = {
            tipo_sangre: res.perfil.tipo_sangre ?? '',
            alergias: res.perfil.alergias ?? '',
            enfermedades_cronicas: res.perfil.enfermedades_cronicas ?? ''
          };
        }
      });
  }

  submitPerfil(): void {
    this.isSubmittingPerfil = true;
    this.perfilMsg = null;
    this.perfilMedicoService.updatePerfil(this.perfilForm)
      .pipe(takeUntil(this.destroy$), catchError(err => {
        this.perfilMsg = err?.error?.message || 'Error al guardar.';
        return of(null);
      }), finalize(() => this.isSubmittingPerfil = false))
      .subscribe(res => {
        if (res) { this.perfilMsg = 'Perfil médico actualizado.'; this.loadPerfil(); }
      });
  }

  startEditPersonal(): void {
    if (!this.perfilMedico) return;
    this.personalForm = {
      nombre: this.perfilMedico.nombre,
      apellido: this.perfilMedico.apellido,
      email: this.perfilMedico.email,
      telefono: this.perfilMedico.telefono ?? '',
      fecha_nacimiento: this.perfilMedico.fecha_nacimiento ?? ''
    };
    this.editandoPersonal = true;
    this.personalMsg = null;
  }

  cancelEditPersonal(): void {
    this.editandoPersonal = false;
    this.personalMsg = null;
  }

  submitDatosPersonales(): void {
    this.isSubmittingPersonal = true;
    this.personalMsg = null;
    this.perfilMedicoService.updateDatosPersonales(this.personalForm)
      .pipe(takeUntil(this.destroy$), catchError(err => {
        this.personalMsg = err?.error?.message || 'Error al guardar.';
        return of(null);
      }), finalize(() => this.isSubmittingPersonal = false))
      .subscribe(res => {
        if (res) {
          this.personalMsg = 'Datos actualizados correctamente.';
          this.editandoPersonal = false;
          this.loadPerfil();
        }
      });
  }

  submitCambiarPassword(): void {
    this.isSubmittingPassword = true;
    this.passwordMsg = null;
    this.perfilMedicoService.cambiarPassword(this.passwordForm)
      .pipe(takeUntil(this.destroy$), catchError(err => {
        this.passwordMsg = err?.error?.message || 'Error al cambiar contraseña.';
        return of(null);
      }), finalize(() => this.isSubmittingPassword = false))
      .subscribe(res => {
        if (res) {
          this.passwordMsg = 'Contraseña actualizada correctamente.';
          this.passwordForm = { password_actual: '', password_nuevo: '', password_nuevo_confirmation: '' };
        }
      });
  }

  loadHistorial(): void {
    this.isLoadingHistorial = true;
    this.perfilMedicoService.getHistorial()
      .pipe(takeUntil(this.destroy$), catchError(() => of(null)), finalize(() => this.isLoadingHistorial = false))
      .subscribe(res => { if (res) this.historial = res.historial; });
  }

  toggleHistorialItem(id: number): void {
    this.historialExpandido = this.historialExpandido === id ? null : id;
  }

  onFotoChange(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = () => { this.fotoPreview = reader.result as string; };
    reader.readAsDataURL(file);

    this.isUploadingFoto = true;
    this.fotoMsg = null;
    this.perfilMedicoService.subirFoto(file)
      .pipe(
        takeUntil(this.destroy$),
        catchError(err => {
          this.fotoMsg = err?.error?.message || 'Error al subir foto.';
          this.fotoPreview = null;
          return of(null);
        }),
        finalize(() => { this.isUploadingFoto = false; })
      )
      .subscribe(res => {
        if (res) {
          this.fotoMsg = 'Foto actualizada.';
          if (this.perfilMedico) {
            this.perfilMedico = { ...this.perfilMedico, foto_perfil: res.foto_url };
          }
        }
      });
  }

  toggleCreateForm(): void {
    this.showCreateForm = !this.showCreateForm;
    this.submitMessage = null;
    if (this.showCreateForm) {
      this.loadAvailability();
    } else {
      this.resetForm();
    }
  }

  onCreateCita(form: NgForm): void {
    if (form.invalid) {
      return;
    }

    const payload: CreateCitaPayload = {
      fecha_cita: this.createFormData.fecha_cita!,
      hora_cita: this.normalizeTime(this.createFormData.hora_cita!),
      motivo: this.createFormData.motivo || undefined
    };

    if (this.isSlotUnavailable(payload.hora_cita)) {
      this.submitMessage = 'La hora seleccionada ya está ocupada. Elige otro bloque disponible.';
      return;
    }

    this.isSubmitting = true;
    this.submitMessage = null;

    this.citaService.createCita(payload)
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => {
          const errores = error?.error?.errors;
          if (errores && typeof errores === 'object') {
            const firstKey = Object.keys(errores)[0];
            const mensajes = (errores as any)[firstKey];
            if (Array.isArray(mensajes) && mensajes.length > 0) {
              this.submitMessage = mensajes[0];
              return of(null);
            }
          }
          this.submitMessage = error?.error?.message || error?.message || 'No se pudo agendar la cita.';
          return of(null);
        }),
        finalize(() => {
          this.isSubmitting = false;
        })
      )
      .subscribe(response => {
        if (response?.cita) {
          this.submitMessage = 'Cita agendada correctamente.';
          this.loadCitas();
          this.loadAvailability();
          this.resetForm();
          this.showCreateForm = false;
        }
      });
  }

  onCancelCita(cita: Cita): void {
    if (this.isSubmitting) {
      return;
    }

    this.isSubmitting = true;
    this.citaService.cancelCita(cita.id)
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => {
          this.submitMessage = error?.error?.message || 'No se pudo cancelar la cita.';
          return of(null);
        }),
        finalize(() => {
          this.isSubmitting = false;
        })
      )
      .subscribe(response => {
        if (response?.cita) {
          this.submitMessage = 'Cita cancelada correctamente.';
          this.loadCitas();
          this.loadAvailability();
        }
      });
  }

  logout() {
    this.authService.logout();
    this.router.navigate(['/login']);
  }

  private loadPreEvaluaciones(): void {
    this.preEvaluacionIAService.getPreEvaluaciones()
      .pipe(
        takeUntil(this.destroy$),
        catchError(() => of({ pre_evaluaciones: [] as PreEvaluacion[] }))
      )
      .subscribe(response => {
        this.preEvaluaciones = response.pre_evaluaciones;
      });
  }

  get citasPendientesSinEvaluacion(): number {
    return this.pendingCitas.filter(c => !this.tienePreEvaluacion(c.id)).length;
  }

  private loadCitas(): void {
    this.isLoadingCitas = true;
    this.citasError = null;

    this.citaService.getCitas()
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => {
          this.citasError = error?.error?.message || 'No se pudieron obtener las citas.';
          return of([] as Cita[]);
        }),
        finalize(() => {
          this.isLoadingCitas = false;
        })
      )
      .subscribe(citas => {
        this.citas = citas;
        this.updateStats();
        this.updateCitaGroups();
        this.buildCalendar();
      });
  }

  private loadBitacoras(): void {
    this.isLoadingBitacoras = true;
    this.bitacorasError = null;

    this.bitacoraService.getBitacoras()
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => {
          this.bitacorasError = error?.error?.message || 'No se pudieron obtener las bitácoras.';
          return of([] as Bitacora[]);
        }),
        finalize(() => {
          this.isLoadingBitacoras = false;
        })
      )
      .subscribe(bitacoras => {
        // Ordenar de la más reciente a la más antigua
        this.bitacoras = [...bitacoras].sort((a, b) =>
          new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
        );
      });
  }

  private loadRecetas(): void {
    this.isLoadingRecetas = true;
    this.recetasError = null;

    this.recetaService.getRecetas()
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => {
          this.recetasError = error?.error?.message || 'No se pudieron obtener las recetas.';
          return of([] as Receta[]);
        }),
        finalize(() => {
          this.isLoadingRecetas = false;
        })
      )
      .subscribe(recetas => {
        // Ordenar de la más reciente a la más antigua por fecha de emisión
        this.recetas = [...recetas].sort((a, b) =>
          new Date(b.fecha_emision).getTime() - new Date(a.fecha_emision).getTime()
        );
      });
  }

  private resetForm(): void {
    this.createFormData = {
      fecha_cita: '',
      hora_cita: '',
      motivo: ''
    };
  }

  private updateStats(): void {
    const upcoming = this.citas
      .filter(cita => cita.estatus === 'programada')
      .map(cita => ({
        cita,
        date: this.toDate(cita.fecha_cita, cita.hora_cita)
      }))
      .filter(item => item.date >= new Date())
      .sort((a, b) => a.date.getTime() - b.date.getTime());

    if (upcoming.length > 0) {
      const next = upcoming[0];
      this.nextCitaInfo = {
        fecha: this.formatFullDate(next.cita.fecha_cita),
        hora: next.cita.hora_cita,
        motivo: next.cita.motivo || undefined
      };
    } else {
      this.nextCitaInfo = null;
    }

    this.totalCitasProgramadas = this.citas.filter(cita => cita.estatus === 'programada').length;
  }

  private updateCitaGroups(): void {
    this.pendingCitas = this.citas
      .filter(cita => cita.estatus === 'programada')
      .sort((a, b) => this.toDate(a.fecha_cita, a.hora_cita).getTime() - this.toDate(b.fecha_cita, b.hora_cita).getTime());

    this.handledCitas = this.citas
      .filter(cita => cita.estatus !== 'programada')
      .sort((a, b) => this.toDate(b.fecha_cita, b.hora_cita).getTime() - this.toDate(a.fecha_cita, a.hora_cita).getTime());
  }

  private formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  private formatFullDate(fecha: string): string {
    const date = this.toDate(fecha);
    return new Intl.DateTimeFormat('es-MX', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    }).format(date);
  }

  private toDate(fecha: string, hora?: string): Date {
    const [year, month, day] = fecha.split('-').map(Number);
    if (hora) {
      const [hours, minutes] = this.normalizeTime(hora).split(':').map(Number);
      return new Date(year, month - 1, day, hours, minutes || 0, 0);
    }
    return new Date(year, month - 1, day);
  }

  onDateChange(date: string): void {
    this.createFormData.fecha_cita = date;
    if (this.createFormData.hora_cita && this.isSlotUnavailable(this.createFormData.hora_cita)) {
      this.createFormData.hora_cita = '';
    }
    this.submitMessage = null;
    this.buildCalendar();
  }

  selectTimeSlot(slot: string): void {
    if (!this.createFormData.fecha_cita || this.isSlotUnavailable(slot)) {
      return;
    }

    this.createFormData.hora_cita = this.normalizeTime(slot);
    this.submitMessage = null;
  }

  get calendarLabel(): string {
    return new Intl.DateTimeFormat('es-MX', {
      month: 'long',
      year: 'numeric'
    }).format(this.currentMonth);
  }

  get isCurrentMonth(): boolean {
    const now = new Date();
    return this.currentMonth.getFullYear() === now.getFullYear() &&
           this.currentMonth.getMonth() === now.getMonth();
  }

  get hasAvailableSlotsForSelectedDate(): boolean {
    if (!this.createFormData.fecha_cita) {
      return false;
    }

    const record = this.getDayRecord(this.createFormData.fecha_cita);
    if (record?.status === 'full') {
      return false;
    }

    const takenSlots = record?.takenSlots ?? new Set<string>();
    return this.timeSlots.some(slot => !takenSlots.has(this.normalizeTime(slot)));
  }

  changeMonth(direction: number): void {
    this.currentMonth = this.startOfMonth(
      new Date(this.currentMonth.getFullYear(), this.currentMonth.getMonth() + direction, 1)
    );
    this.availabilityMap = new Map<string, DayAvailabilityRecord>();
    this.buildCalendar();
    this.loadAvailability();
  }

  selectCalendarDay(day: CalendarDay): void {
    if (day.isPast || !day.isCurrentMonth || day.availability === 'full') {
      return;
    }

    this.onDateChange(day.date);
  }

  private generateTimeSlots(): string[] {
    const slots: string[] = [];
    // Horario 8am a 5pm — último slot inicia a las 16:45 (termina a las 17:00)
    for (let hour = 8; hour < 17; hour++) {
      ['00', '15', '30', '45'].forEach(minute => {
        slots.push(`${String(hour).padStart(2, '0')}:${minute}`);
      });
    }
    return slots;
  }

  public normalizeTime(hora: string): string {
    const [hours, minutes] = hora.split(':');
    return `${hours?.padStart(2, '0')}:${(minutes ?? '00').padStart(2, '0')}`;
  }

  isSlotUnavailable(slot: string): boolean {
    if (!this.createFormData.fecha_cita) {
      return false;
    }

    const normalizedSlot = this.normalizeTime(slot);

    // Si la cita es para hoy, no permitir seleccionar horarios que ya pasaron
    if (this.createFormData.fecha_cita === this.today) {
      const [hours, minutes] = normalizedSlot.split(':').map(Number);
      const now = new Date();
      const slotDate = new Date();
      slotDate.setHours(hours ?? 0, minutes ?? 0, 0, 0);

      if (slotDate.getTime() <= now.getTime()) {
        return true;
      }
    }

    const record = this.getDayRecord(this.createFormData.fecha_cita);

    if (record?.status === 'full') {
      return true;
    }

    if (record?.takenSlots.has(normalizedSlot)) {
      return true;
    }

    return this.citas.some(cita =>
      cita.fecha_cita === this.createFormData.fecha_cita &&
      cita.estatus === 'programada' &&
      this.normalizeTime(cita.hora_cita) === normalizedSlot
    );
  }

  isSelectedDate(date: string): boolean {
    return this.createFormData.fecha_cita === date;
  }

  isDayUnavailable(day: CalendarDay): boolean {
    return !day.isCurrentMonth || day.isPast || day.availability === 'full';
  }

  private startOfDay(date: Date): Date {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate());
  }

  private startOfMonth(date: Date): Date {
    return new Date(date.getFullYear(), date.getMonth(), 1);
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
      for (let day = 0; day < 7; day++) {
        const date = new Date(cursor);
        const dateStr = this.formatDate(date);
        const isCurrentMonth = date.getMonth() === reference.getMonth();
        const isPast = this.startOfDay(date).getTime() < today.getTime();
        const isToday = this.startOfDay(date).getTime() === today.getTime();
        const meta = this.resolveCalendarMetadata(dateStr, isCurrentMonth, isPast);

        weekDays.push({
          date: dateStr,
          label: date.getDate(),
          isCurrentMonth,
          isToday,
          isPast,
          availability: meta.availability,
          color: meta.color,
          labelText: meta.label
        });

        cursor.setDate(cursor.getDate() + 1);
      }
      weeks.push(weekDays);
    }

    this.calendarWeeks = weeks;
  }

  private resolveCalendarMetadata(
    dateStr: string,
    isCurrentMonth: boolean,
    isPast: boolean
  ): { availability: CalendarAvailability; color: string; label: string | null } {
    if (!isCurrentMonth || isPast) {
      return {
        availability: 'none',
        color: this.getStatusColor('none'),
        label: null
      };
    }

    // Domingos: día no laborable, marcado en rojo y como lleno
    const date = this.toDate(dateStr);
    if (date.getDay() === 0) {
      return {
        availability: 'full',
        color: '#ef5350',
        label: 'Cerrado'
      };
    }

    const record = this.getDayRecord(dateStr);
    if (!record) {
      return {
        availability: 'available',
        color: this.getStatusColor('available'),
        label: null
      };
    }

    const availability = record.status;
    const color = record.color ?? this.getStatusColor(availability);

    return {
      availability,
      color,
      label: record.label ?? null
    };
  }

  getDayStyle(day: CalendarDay): { [key: string]: string } | null {
    if (day.availability === 'none') {
      return null;
    }

    const baseColor = day.color ?? this.getStatusColor(day.availability);
    const background = this.applyOpacity(baseColor, day.availability === 'full' ? 0.25 : 0.15);
    const border = this.applyOpacity(baseColor, 0.6);

    const style: { [key: string]: string } = {
      ['background-color']: background,
      ['border-color']: border
    };

    if (day.isToday) {
      style['box-shadow'] = `0 0 0 2px ${this.applyOpacity('#1e88e5', 0.4)}`;
    }

    return style;
  }

  private getDayRecord(date: string): DayAvailabilityRecord | undefined {
    return this.availabilityMap.get(date);
  }

  private getStatusColor(status: CalendarAvailability): string {
    switch (status) {
      case 'available':
        return '#1e88e5';
      case 'partial':
        return '#ffb300';
      case 'full':
        return '#ef5350';
      default:
        return '#cfd8dc';
    }
  }

  private applyOpacity(hexColor: string, alpha: number): string {
    const rgb = this.hexToRgb(hexColor);
    if (!rgb) {
      return hexColor;
    }

    const { r, g, b } = rgb;
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
  }

  private hexToRgb(hexColor: string): { r: number; g: number; b: number } | null {
    let hex = hexColor.replace('#', '');
    if (hex.length === 3) {
      hex = hex.split('').map(char => char + char).join('');
    }

    if (hex.length !== 6) {
      return null;
    }

    const bigint = parseInt(hex, 16);
    return {
      r: (bigint >> 16) & 255,
      g: (bigint >> 8) & 255,
      b: bigint & 255
    };
  }

  private loadAvailability(): void {
    this.isLoadingAvailability = true;
    const month = this.currentMonth.getMonth() + 1;
    const year = this.currentMonth.getFullYear();

    this.citaService.getAvailability(month, year)
      .pipe(
        takeUntil(this.destroy$),
        catchError(() => of(null)),
        finalize(() => {
          this.isLoadingAvailability = false;
        })
      )
      .subscribe(response => {
        if (response?.days) {
          this.applyAvailability(response.days);
        } else {
          this.availabilityMap = new Map<string, DayAvailabilityRecord>();
        }
        this.buildCalendar();
      });
  }

  private applyAvailability(days: CitaAvailabilityDay[]): void {
    const map = new Map<string, DayAvailabilityRecord>();

    days.forEach(day => {
      const takenSlots = new Set<string>((day.taken_slots || []).map(slot => this.normalizeTime(slot)));

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

      map.set(day.date, {
        takenSlots,
        status,
        color: day.special?.color ?? undefined,
        label: day.special?.label ?? null
      });
    });

    this.availabilityMap = map;
  }

  formatDateDisplay(fecha: string): string {
    return new Intl.DateTimeFormat('es-MX', {
      day: '2-digit',
      month: '2-digit',
      year: '2-digit'
    }).format(this.toDate(fecha));
  }

  formatBitacoraDate(fecha: string): string {
    return new Intl.DateTimeFormat('es-MX', {
      dateStyle: 'medium',
      timeStyle: 'short'
    }).format(new Date(fecha));
  }

  formatRecetaDate(fecha: string): string {
    const date = new Date(fecha);
    return new Intl.DateTimeFormat('es-MX', {
      day: '2-digit',
      month: '2-digit',
      year: '2-digit'
    }).format(date);
  }

  formatTime(hora: string): string {
    const [hours, minutes] = this.normalizeTime(hora).split(':').map(Number);
    const date = new Date();
    date.setHours(hours, minutes || 0, 0, 0);
    return new Intl.DateTimeFormat('es-MX', {
      hour: '2-digit',
      minute: '2-digit',
      hour12: false
    }).format(date);
  }

  // ===== MÉTODOS DE PRE-EVALUACIÓN IA (CHAT) =====

  togglePreEvaluacionForm(cita?: Cita): void {
    if (cita) {
      this.selectedCitaForEvaluacion = cita;
    }
    this.showPreEvaluacionForm = !this.showPreEvaluacionForm;

    if (this.showPreEvaluacionForm) {
      this.chatMensajes = [{
        role: 'assistant',
        content: '¡Hola! Soy tu asistente médico de pre-evaluación. ¿Cuál es tu principal molestia o síntoma hoy?'
      }];
      this.chatInput = '';
      this.isChatLoading = false;
      this.resultadoPreEvaluacion = null;
      this.preEvaluacionError = null;
    } else {
      this.selectedCitaForEvaluacion = null;
      this.chatMensajes = [];
      this.resultadoPreEvaluacion = null;
    }
  }

  enviarMensajeChat(): void {
    if (!this.chatInput.trim() || this.isChatLoading || !this.selectedCitaForEvaluacion) return;

    const userMessage = this.chatInput.trim();
    this.chatInput = '';
    this.chatMensajes.push({ role: 'user', content: userMessage });
    this.isChatLoading = true;
    this.preEvaluacionError = null;
    this.scrollChat();

    this.preEvaluacionIAService.chat(
      this.selectedCitaForEvaluacion.id,
      this.chatMensajes
    ).pipe(
      takeUntil(this.destroy$),
      catchError(error => {
        this.preEvaluacionError = error?.error?.message || error?.error?.detail || 'Error al conectar con la IA. Verifica que Ollama esté corriendo.';
        return of(null);
      }),
      finalize(() => {
        this.isChatLoading = false;
        this.scrollChat();
      })
    ).subscribe((response: ChatResponse | null) => {
      if (response) {
        this.chatMensajes.push({ role: 'assistant', content: response.message });
        if (response.finished && response.diagnostico) {
          this.resultadoPreEvaluacion = response.diagnostico;
          if (response.pre_evaluacion) {
            this.preEvaluaciones.unshift(response.pre_evaluacion);
          }
        }
      }
    });
  }

  get mensajesUsuario(): number {
    return this.chatMensajes.filter(m => m.role === 'user').length;
  }

  forzarDiagnostico(): void {
    if (!this.selectedCitaForEvaluacion || this.isChatLoading) return;

    this.chatMensajes.push({
      role: 'user',
      content: 'Por favor genera el diagnóstico final con la información que tienes.'
    });
    this.isChatLoading = true;
    this.preEvaluacionError = null;
    this.scrollChat();

    this.preEvaluacionIAService.chat(
      this.selectedCitaForEvaluacion.id,
      this.chatMensajes
    ).pipe(
      takeUntil(this.destroy$),
      catchError(error => {
        this.preEvaluacionError = error?.error?.message || error?.error?.detail || 'Error al generar diagnóstico.';
        return of(null);
      }),
      finalize(() => {
        this.isChatLoading = false;
        this.scrollChat();
      })
    ).subscribe((response: ChatResponse | null) => {
      if (response) {
        this.chatMensajes.push({ role: 'assistant', content: response.message });
        if (response.finished && response.diagnostico) {
          this.resultadoPreEvaluacion = response.diagnostico;
          if (response.pre_evaluacion) {
            this.preEvaluaciones.unshift(response.pre_evaluacion);
          }
        }
      }
    });
  }

  onChatEnter(event: KeyboardEvent): void {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      this.enviarMensajeChat();
    }
  }

  private scrollChat(): void {
    setTimeout(() => {
      const el = document.querySelector('.chat-messages');
      if (el) el.scrollTop = el.scrollHeight;
    }, 60);
  }

  getEstatusPreEvaluacion(citaId: number): string | null {
    const evaluacion = this.preEvaluaciones.find(e => e.cita_id === citaId);
    return evaluacion ? evaluacion.estatus_validacion : null;
  }

  tienePreEvaluacion(citaId: number): boolean {
    return this.preEvaluaciones.some(e => e.cita_id === citaId);
  }

  getConfianzaClass(confianza: number): string {
    if (confianza >= 0.8) return 'confianza-alta';
    if (confianza >= 0.6) return 'confianza-media';
    if (confianza >= 0.4) return 'confianza-baja';
    return 'confianza-muy-baja';
  }
}