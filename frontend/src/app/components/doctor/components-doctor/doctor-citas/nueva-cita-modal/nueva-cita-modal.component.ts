import { Component, EventEmitter, Input, OnDestroy, OnInit, Output, SimpleChanges } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, NgForm } from '@angular/forms';
import { Subject, of } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { Cita, CitaService, CreateCitaPayload, CitaAvailabilityDay } from '../../../../../services/cita.service';
import {
  AvailabilityStatus,
  CalendarAvailability,
  applyOpacity,
  formatDate,
  formatDateDisplay,
  formatTime,
  generateTimeSlots,
  getStatusColor,
  normalizeTime,
  startOfDay,
  startOfMonth,
  toDateFromString,
} from '../doctor-citas-utils';
import { CalendarDay, DayAvailabilityRecord } from '../doctor-citas-types';

@Component({
  selector: 'app-nueva-cita-modal',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './nueva-cita-modal.component.html',
})
export class NuevaCitaModalComponent implements OnInit, OnDestroy {
  @Input() visible = false;
  @Output() close = new EventEmitter<void>();
  @Output() created = new EventEmitter<Cita>();

  readonly timeSlots: string[] = generateTimeSlots();
  readonly totalSlotsPerDay = this.timeSlots.length;
  readonly weekDays: string[] = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
  readonly today = formatDate(new Date());

  createStep: 1 | 2 | 3 = 1;
  currentMonth: Date = startOfMonth(new Date());
  calendarWeeks: CalendarDay[][] = [];
  availabilityMap: Map<string, DayAvailabilityRecord> = new Map();

  formData: Partial<CreateCitaPayload & { numero_control: string }> = {
    fecha_cita: '', hora_cita: '', motivo: '', numero_control: '',
  };
  submitMessage: string | null = null;
  isSubmitting = false;

  private destroy$ = new Subject<void>();

  constructor(private citaService: CitaService) {}

  ngOnInit(): void {
    this.buildCalendar();
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['visible'] && changes['visible'].currentValue) {
      this.createStep = 1;
      this.submitMessage = null;
      this.loadAvailability();
    }
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  get calendarLabel(): string {
    return new Intl.DateTimeFormat('es-MX', { month: 'long', year: 'numeric' }).format(this.currentMonth);
  }

  get isCurrentMonth(): boolean {
    const now = new Date();
    return this.currentMonth.getFullYear() === now.getFullYear() && this.currentMonth.getMonth() === now.getMonth();
  }

  get selectedDayWarning(): string | null {
    const fecha = this.formData.fecha_cita;
    if (!fecha) return null;
    const rec = this.availabilityMap.get(fecha);
    if (!rec || rec.status !== 'partial') return null;
    const baseMsg = rec.label ? `Atención reducida hoy: ${rec.label}` : 'Este día tiene atención reducida.';
    return rec.horaCierre ? `${baseMsg} (cierre a las ${rec.horaCierre})` : baseMsg;
  }

  get hasAvailableSlotsForSelectedDate(): boolean {
    if (!this.formData.fecha_cita) return false;
    const record = this.availabilityMap.get(this.formData.fecha_cita);
    if (record?.status === 'full') return false;
    const takenSlots = record?.takenSlots ?? new Set<string>();
    return this.timeSlots.some(slot => !takenSlots.has(normalizeTime(slot)));
  }

  isSelectedDate(date: string): boolean { return this.formData.fecha_cita === date; }

  isDayUnavailable(day: CalendarDay): boolean {
    return !day.isCurrentMonth || day.isPast || day.availability === 'full';
  }

  getDayStyle(day: CalendarDay): { [key: string]: string } | null {
    if (day.availability === 'none') return null;
    const baseColor = day.color ?? getStatusColor(day.availability);
    const background = applyOpacity(baseColor, day.availability === 'full' ? 0.25 : 0.15);
    const border = applyOpacity(baseColor, 0.6);
    const style: { [key: string]: string } = { 'background-color': background, 'border-color': border };
    if (day.isToday) style['box-shadow'] = `0 0 0 2px ${applyOpacity('#1e88e5', 0.4)}`;
    return style;
  }

  isSlotUnavailable(slot: string): boolean {
    if (!this.formData.fecha_cita) return false;
    const normalizedSlot = normalizeTime(slot);
    if (this.formData.fecha_cita === this.today) {
      const [hours, minutes] = normalizedSlot.split(':').map(Number);
      const slotDate = new Date();
      slotDate.setHours(hours ?? 0, minutes ?? 0, 0, 0);
      if (slotDate.getTime() <= new Date().getTime()) return true;
    }
    const record = this.availabilityMap.get(this.formData.fecha_cita);
    if (record?.status === 'full') return true;
    if (record?.horaCierre && normalizedSlot >= record.horaCierre) return true;
    return !!record?.takenSlots.has(normalizedSlot);
  }

  changeMonth(direction: number): void {
    this.currentMonth = startOfMonth(new Date(this.currentMonth.getFullYear(), this.currentMonth.getMonth() + direction, 1));
    this.availabilityMap = new Map();
    this.buildCalendar();
    this.loadAvailability();
  }

  selectCalendarDay(day: CalendarDay): void {
    if (day.isPast || !day.isCurrentMonth || day.availability === 'full') return;
    this.formData.fecha_cita = day.date;
    if (this.formData.hora_cita && this.isSlotUnavailable(this.formData.hora_cita)) {
      this.formData.hora_cita = '';
    }
    this.submitMessage = null;
    this.buildCalendar();
  }

  selectTimeSlot(slot: string): void {
    if (!this.formData.fecha_cita || this.isSlotUnavailable(slot)) return;
    this.formData.hora_cita = normalizeTime(slot);
    this.submitMessage = null;
  }

  stepNext(): void {
    if (this.createStep === 1) {
      if (!this.formData.numero_control?.trim()) {
        this.submitMessage = 'Ingresa el número de control del alumno.';
        return;
      }
      this.submitMessage = null;
      this.createStep = 2;
    } else if (this.createStep === 2) {
      if (!this.formData.fecha_cita) {
        this.submitMessage = 'Selecciona una fecha.';
        return;
      }
      if (!this.formData.hora_cita) {
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

  onCreateCita(_form: NgForm): void {
    const noCtrl = this.formData.numero_control?.trim();
    if (!noCtrl || !this.formData.fecha_cita || !this.formData.hora_cita) {
      this.submitMessage = 'Completa todos los campos requeridos.';
      return;
    }
    const normalizedTime = normalizeTime(this.formData.hora_cita!);
    if (this.isSlotUnavailable(normalizedTime)) {
      this.submitMessage = 'La hora seleccionada ya está ocupada.';
      return;
    }
    const payload: CreateCitaPayload = {
      fecha_cita: this.formData.fecha_cita!,
      hora_cita: normalizedTime,
      motivo: this.formData.motivo || undefined,
      numero_control: noCtrl,
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
            const msgs = (errores as { [k: string]: string[] })[first];
            if (Array.isArray(msgs) && msgs.length > 0) { this.submitMessage = msgs[0]; return of(null); }
          }
          this.submitMessage = error?.error?.message || 'No se pudo agendar la cita.';
          return of(null);
        }),
        finalize(() => { this.isSubmitting = false; })
      )
      .subscribe(response => {
        if (response?.cita) {
          this.created.emit(response.cita);
          this.resetForm();
          this.close.emit();
        }
      });
  }

  onClose(): void {
    this.resetForm();
    this.close.emit();
  }

  formatTime = formatTime;
  formatDateDisplay = formatDateDisplay;
  normalizeTime = normalizeTime;

  private resetForm(): void {
    this.formData = { fecha_cita: '', hora_cita: '', motivo: '', numero_control: '' };
    this.createStep = 1;
  }

  private loadAvailability(): void {
    const month = this.currentMonth.getMonth() + 1;
    const year = this.currentMonth.getFullYear();
    this.citaService.getAvailability(month, year)
      .pipe(takeUntil(this.destroy$), catchError(() => of(null)))
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
      const takenSlots = new Set<string>((day.taken_slots || []).map(s => normalizeTime(s)));
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
    const reference = startOfMonth(this.currentMonth);
    const firstDayIndex = reference.getDay();
    const calendarStart = new Date(reference);
    calendarStart.setDate(calendarStart.getDate() - firstDayIndex);

    const today = startOfDay(new Date());
    const weeks: CalendarDay[][] = [];
    const cursor = new Date(calendarStart);

    for (let week = 0; week < 6; week++) {
      const weekDays: CalendarDay[] = [];
      for (let dayIndex = 0; dayIndex < 7; dayIndex++) {
        const date = new Date(cursor);
        const dateStr = formatDate(date);
        const isCurrentMonth = date.getMonth() === reference.getMonth();
        const isPast = startOfDay(date).getTime() < today.getTime();
        const isToday = startOfDay(date).getTime() === today.getTime();
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
    if (toDateFromString(dateStr).getDay() === 0) return { availability: 'full', color: '#ef5350', labelText: 'Cerrado' };
    const record = this.availabilityMap.get(dateStr);
    if (!record) return { availability: 'available', color: getStatusColor('available'), labelText: null };
    return { availability: record.status, color: record.color ?? getStatusColor(record.status), labelText: record.label ?? null };
  }
}
