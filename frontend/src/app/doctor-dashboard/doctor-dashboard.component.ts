import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { FormsModule, NgForm } from '@angular/forms';
import { Subject, of } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { AuthService } from '../services/auth.service';
import { Cita, CitaService, CreateCitaPayload, AvailabilityStatus, CitaAvailabilityDay } from '../services/cita.service';
import { Bitacora, BitacoraService, CreateBitacoraPayload } from '../services/bitacora.service';
import { Receta, RecetaService, CreateRecetaPayload } from '../services/receta.service';

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
  selector: 'app-doctor-dashboard',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule],
  templateUrl: './doctor-dashboard.component.html',
  styleUrls: ['./doctor-dashboard.component.css']
})
export class DoctorDashboardComponent implements OnInit, OnDestroy {
  activeSection: string = 'inicio';
  doctorName: string = 'Doctor';
  today: string = this.formatDate(new Date());

  citas: Cita[] = [];
  isLoadingCitas = false;
  citasError: string | null = null;

  pendingCitas: Cita[] = [];
  handledCitas: Cita[] = [];

  showCreateForm = false;
  isSubmitting = false;
  submitMessage: string | null = null;

  createFormData: Partial<CreateCitaPayload & { numero_control: string }> = {
    fecha_cita: '',
    hora_cita: '',
    motivo: '',
    numero_control: ''
  };
  readonly timeSlots: string[] = this.generateTimeSlots();
  readonly totalSlotsPerDay = this.timeSlots.length;
  readonly weekDays: string[] = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
  currentMonth: Date = this.startOfMonth(new Date());
  calendarWeeks: CalendarDay[][] = [];
  availabilityMap: Map<string, DayAvailabilityRecord> = new Map();
  isLoadingAvailability = false;

  todayAppointments = 0;
  patientsAttended = 0;
  pendingBitacoras = 0;

  bitacoras: Bitacora[] = [];
  isLoadingBitacoras = false;
  bitacorasError: string | null = null;
  showBitacoraForm = false;
  isSubmittingBitacora = false;
  bitacoraMessage: string | null = null;
  editingBitacoraId: number | null = null;
  bitacoraFormData: Partial<CreateBitacoraPayload> = {
    cita_id: undefined,
    diagnostico: '',
    tratamiento: '',
    observaciones: '',
    peso: '',
    altura: '',
    temperatura: '',
    presion_arterial: ''
  };

  recetas: Receta[] = [];
  isLoadingRecetas = false;
  recetasError: string | null = null;
  showRecetaForm = false;
  isSubmittingReceta = false;
  recetaMessage: string | null = null;
  editingRecetaId: number | null = null;
  recetaFormData: Partial<CreateRecetaPayload> = {
    cita_id: undefined,
    medicamentos: '',
    indicaciones: '',
    fecha_emision: this.formatDate(new Date())
  };

  private destroy$ = new Subject<void>();

  constructor(
    private router: Router,
    private authService: AuthService,
    private citaService: CitaService,
    private bitacoraService: BitacoraService,
    private recetaService: RecetaService
  ) {}

  ngOnInit(): void {
    const user = this.authService.getCurrentUser();
    this.doctorName = user ? `${user.nombre} ${user.apellido}` : 'Doctor';
    this.buildCalendar();
    this.loadAvailability();
    this.loadCitas();
    this.loadBitacoras();
    this.loadRecetas();
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
    if (section === 'bitacoras') {
      this.loadBitacoras();
    }
    if (section === 'recetas') {
      this.loadRecetas();
    }
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

  toggleBitacoraForm(): void {
    this.showBitacoraForm = !this.showBitacoraForm;
    this.bitacoraMessage = null;
    if (!this.showBitacoraForm) {
      this.editingBitacoraId = null;
      this.resetBitacoraForm();
    }
  }

  toggleRecetaForm(): void {
    this.showRecetaForm = !this.showRecetaForm;
    this.recetaMessage = null;
    if (!this.showRecetaForm) {
      this.editingRecetaId = null;
      this.resetRecetaForm();
    }
  }

  get calendarLabel(): string {
    return new Intl.DateTimeFormat('es-MX', {
      month: 'long',
      year: 'numeric'
    }).format(this.currentMonth);
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

  selectTimeSlot(slot: string): void {
    if (!this.createFormData.fecha_cita || this.isSlotUnavailable(slot)) {
      return;
    }

    this.createFormData.hora_cita = this.normalizeTime(slot);
    this.submitMessage = null;
  }

  onCreateCita(form: NgForm): void {
    if (form.invalid || !this.createFormData.numero_control?.trim()) {
      this.submitMessage = 'Ingresa el número de control del alumno.';
      return;
    }

    const normalizedTime = this.normalizeTime(this.createFormData.hora_cita!);

    if (this.isSlotUnavailable(normalizedTime)) {
      this.submitMessage = 'La hora seleccionada ya está ocupada. Elige otro bloque disponible.';
      return;
    }

    const payload: CreateCitaPayload = {
      fecha_cita: this.createFormData.fecha_cita!,
      hora_cita: normalizedTime,
      motivo: this.createFormData.motivo || undefined,
      numero_control: this.createFormData.numero_control.trim()
    };

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

  onMarkAsAttended(cita: Cita): void {
    if (this.isSubmitting) {
      return;
    }

    this.isSubmitting = true;
    this.citaService.markAsAttended(cita.id)
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => {
          this.submitMessage = error?.error?.message || 'No se pudo marcar como atendida.';
          return of(null);
        }),
        finalize(() => {
          this.isSubmitting = false;
        })
      )
      .subscribe(response => {
        if (response?.cita) {
          this.submitMessage = 'Cita marcada como atendida.';
          this.loadCitas();
          this.loadBitacoras();
          this.loadRecetas();
        }
      });
  }

  onCreateBitacora(form: NgForm): void {
    if (form.invalid) {
      if (!this.bitacoraFormData.cita_id) {
        this.bitacoraMessage = 'Selecciona la cita atendida correspondiente.';
      } else {
        this.bitacoraMessage = 'Por favor completa todos los campos obligatorios de la bitácora.';
      }
      return;
    }

    const payload: CreateBitacoraPayload = {
      cita_id: Number(this.bitacoraFormData.cita_id),
      diagnostico: this.bitacoraFormData.diagnostico || undefined,
      tratamiento: this.bitacoraFormData.tratamiento || undefined,
      observaciones: this.bitacoraFormData.observaciones || undefined,
      peso: this.bitacoraFormData.peso || undefined,
      altura: this.bitacoraFormData.altura || undefined,
      temperatura: this.bitacoraFormData.temperatura || undefined,
      presion_arterial: this.bitacoraFormData.presion_arterial || undefined
    };

    this.isSubmittingBitacora = true;
    this.bitacoraMessage = null;

    const request$ = this.editingBitacoraId
      ? this.bitacoraService.updateBitacora(this.editingBitacoraId, payload)
      : this.bitacoraService.createBitacora(payload);

    request$
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => {
          const errores = error?.error?.errors;
          if (errores && typeof errores === 'object') {
            const firstKey = Object.keys(errores)[0];
            const mensajes = (errores as any)[firstKey];
            if (Array.isArray(mensajes) && mensajes.length > 0) {
              this.bitacoraMessage = mensajes[0];
              return of(null);
            }
          }

          this.bitacoraMessage = error?.error?.message || 'No se pudo registrar la bitácora.';
          return of(null);
        }),
        finalize(() => {
          this.isSubmittingBitacora = false;
        })
      )
      .subscribe(response => {
        if (response?.bitacora) {
          this.bitacoraMessage = this.editingBitacoraId
            ? 'Bitácora actualizada correctamente.'
            : 'Bitácora registrada correctamente.';
          this.loadBitacoras();
          this.editingBitacoraId = null;
          this.resetBitacoraForm();
          this.showBitacoraForm = false;
        }
      });
  }

  onCreateReceta(form: NgForm): void {
    if (form.invalid) {
      if (!this.recetaFormData.cita_id) {
        this.recetaMessage = 'Selecciona la cita atendida correspondiente.';
      } else if (!this.recetaFormData.medicamentos?.trim()) {
        this.recetaMessage = 'Captura los medicamentos recetados.';
      } else if (!this.recetaFormData.indicaciones?.trim()) {
        this.recetaMessage = 'Captura las indicaciones para el paciente.';
      } else if (!this.recetaFormData.fecha_emision) {
        this.recetaMessage = 'Selecciona la fecha de emisión de la receta.';
      } else {
        this.recetaMessage = 'Por favor completa todos los campos obligatorios de la receta.';
      }
      return;
    }

    const payload: CreateRecetaPayload = {
      cita_id: Number(this.recetaFormData.cita_id),
      medicamentos: this.recetaFormData.medicamentos!.trim(),
      indicaciones: this.recetaFormData.indicaciones?.trim() || undefined,
      fecha_emision: this.recetaFormData.fecha_emision || this.formatDate(new Date())
    };

    this.isSubmittingReceta = true;
    this.recetaMessage = null;

    const request$ = this.editingRecetaId
      ? this.recetaService.updateReceta(this.editingRecetaId, payload)
      : this.recetaService.createReceta(payload);

    request$
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => {
          const errores = error?.error?.errors;
          if (errores && typeof errores === 'object') {
            const firstKey = Object.keys(errores)[0];
            const mensajes = (errores as any)[firstKey];
            if (Array.isArray(mensajes) && mensajes.length > 0) {
              this.recetaMessage = mensajes[0];
              return of(null);
            }
          }

          this.recetaMessage = error?.error?.message || 'No se pudo registrar la receta.';
          return of(null);
        }),
        finalize(() => {
          this.isSubmittingReceta = false;
        })
      )
      .subscribe(response => {
        if (response?.receta) {
          this.recetaMessage = this.editingRecetaId
            ? 'Receta actualizada correctamente.'
            : 'Receta registrada correctamente.';
          this.loadRecetas();
          this.editingRecetaId = null;
          this.resetRecetaForm();
          this.showRecetaForm = false;
        }
      });
  }

  logout() {
    this.authService.logout();
    this.router.navigate(['/login']);
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
      });
  }

  private loadBitacoras(): void {
    if (this.isLoadingBitacoras) {
      return;
    }

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
        this.updateStats();
      });
  }

  private loadRecetas(): void {
    if (this.isLoadingRecetas) {
      return;
    }

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
        this.updateStats();
      });
  }

  private resetForm(): void {
    this.createFormData = {
      fecha_cita: '',
      hora_cita: '',
      motivo: '',
      numero_control: ''
    };
  }

  private resetBitacoraForm(): void {
    this.bitacoraFormData = {
      cita_id: undefined,
      diagnostico: '',
      tratamiento: '',
      observaciones: '',
      peso: '',
      altura: '',
      temperatura: '',
      presion_arterial: ''
    };
  }

  public startEditBitacora(bitacora: Bitacora): void {
    this.showBitacoraForm = true;
    this.editingBitacoraId = bitacora.id;
    this.bitacoraMessage = null;
    this.bitacoraFormData = {
      cita_id: bitacora.cita_id,
      diagnostico: bitacora.diagnostico || '',
      tratamiento: bitacora.tratamiento || '',
      observaciones: bitacora.observaciones || '',
      peso: bitacora.peso || '',
      altura: bitacora.altura || '',
      temperatura: bitacora.temperatura || '',
      presion_arterial: bitacora.presion_arterial || ''
    };
  }

  private resetRecetaForm(): void {
    this.recetaFormData = {
      cita_id: undefined,
      medicamentos: '',
      indicaciones: '',
      fecha_emision: this.formatDate(new Date())
    };
  }

  public startEditReceta(receta: Receta): void {
    this.showRecetaForm = true;
    this.editingRecetaId = receta.id;
    this.recetaMessage = null;
    this.recetaFormData = {
      cita_id: receta.cita_id,
      medicamentos: receta.medicamentos,
      indicaciones: receta.indicaciones || '',
      fecha_emision: receta.fecha_emision
    };
  }

  private updateStats(): void {
    // Citas del día: solo citas programadas para la fecha actual
    this.todayAppointments = this.citas.filter(
      cita => cita.estatus === 'programada' && cita.fecha_cita === this.today
    ).length;

    // Pacientes atendidos: total de citas marcadas como atendidas
    this.patientsAttended = this.citas.filter(cita => cita.estatus === 'atendida').length;

    // Citas pendientes: total de citas con estatus "programada",
    // igual que el conteo que ve el alumno en su panel
    this.pendingBitacoras = this.citas.filter(cita => cita.estatus === 'programada').length;
  }

  private updateCitaGroups(): void {
    this.pendingCitas = this.citas
      .filter(cita => cita.estatus === 'programada')
      .sort(
        (a, b) =>
          this.toDate(a.fecha_cita, a.hora_cita).getTime() -
          this.toDate(b.fecha_cita, b.hora_cita).getTime()
      );

    this.handledCitas = this.citas
      .filter(cita => cita.estatus !== 'programada')
      .sort(
        (a, b) =>
          this.toDate(b.fecha_cita, b.hora_cita).getTime() -
          this.toDate(a.fecha_cita, a.hora_cita).getTime()
      );
  }

  public formatDateDisplay(fecha: string): string {
    return this.formatFullDate(fecha);
  }

  public formatBitacoraDate(fecha: string): string {
    return this.formatDateTime(new Date(fecha));
  }

  public formatRecetaDate(fecha: string): string {
    return new Intl.DateTimeFormat('es-MX', {
      dateStyle: 'medium'
    }).format(new Date(fecha));
  }

  public onRecetaCitaChange(citaId: number | string): void {
    const id = Number(citaId);
    const cita = this.citas.find(c => c.id === id);
    if (cita) {
      // Usar la fecha de la cita como fecha de emisión por defecto (YYYY-MM-DD)
      this.recetaFormData.fecha_emision = cita.fecha_cita;
    }
  }

  public get availableCitasForBitacora(): Cita[] {
    const bitacoraCitaIds = new Set(this.bitacoras.map(bitacora => bitacora.cita_id));
    return this.citas.filter(
      cita => cita.estatus === 'atendida' && !bitacoraCitaIds.has(cita.id)
    );
  }

  public get availableCitasForReceta(): Cita[] {
    // Si estamos editando una receta, mostramos todas las citas atendidas.
    // La validación de "una receta por cita" ya está controlada por el backend
    // y el select está deshabilitado en modo edición.
    if (this.editingRecetaId !== null) {
      return this.citas.filter(cita => cita.estatus === 'atendida');
    }

    // Al crear una receta nueva, solo permitir citas atendidas que aún no tengan receta.
    const recetaCitaIds = new Set(this.recetas.map(receta => receta.cita_id));
    return this.citas.filter(
      cita => cita.estatus === 'atendida' && !recetaCitaIds.has(cita.id)
    );
  }

  public formatTime(hora: string): string {
    const [hours, minutes] = this.normalizeTime(hora).split(':').map(Number);
    const date = new Date();
    date.setHours(hours, minutes || 0, 0, 0);
    return new Intl.DateTimeFormat('es-MX', {
      hour: '2-digit',
      minute: '2-digit',
      hour12: false
    }).format(date);
  }

  public isSelectedDate(date: string): boolean {
    return this.createFormData.fecha_cita === date;
  }

  public isDayUnavailable(day: CalendarDay): boolean {
    return !day.isCurrentMonth || day.isPast || day.availability === 'full';
  }

  public getDayStyle(day: CalendarDay): { [key: string]: string } | null {
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

  public onDateChange(date: string): void {
    this.createFormData.fecha_cita = date;
    if (this.createFormData.hora_cita && this.isSlotUnavailable(this.createFormData.hora_cita)) {
      this.createFormData.hora_cita = '';
    }
    this.submitMessage = null;
    this.buildCalendar();
  }

  public isSlotUnavailable(slot: string): boolean {
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

  private formatDateTime(date: Date): string {
    return new Intl.DateTimeFormat('es-MX', {
      dateStyle: 'medium',
      timeStyle: 'short'
    }).format(date);
  }

  private toDate(fecha: string, hora?: string): Date {
    const [year, month, day] = fecha.split('-').map(Number);
    if (hora) {
      const [hours, minutes] = this.normalizeTime(hora).split(':').map(Number);
      return new Date(year, (month ?? 1) - 1, day ?? 1, hours ?? 0, minutes ?? 0, 0, 0);
    }
    return new Date(year, (month ?? 1) - 1, day ?? 1);
  }

  private generateTimeSlots(): string[] {
    const slots: string[] = [];
    for (let hour = 7; hour <= 20; hour++) {
      ['00', '15', '30', '45'].forEach(minute => {
        slots.push(`${String(hour).padStart(2, '0')}:${minute}`);
      });
    }
    slots.push('21:00');
    return slots;
  }

  public normalizeTime(hora: string): string {
    const [hours, minutes] = hora.split(':');
    return `${hours?.padStart(2, '0')}:${(minutes ?? '00').padStart(2, '0')}`;
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
      for (let dayIndex = 0; dayIndex < 7; dayIndex++) {
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

    // Domingos: día no laborable
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
}