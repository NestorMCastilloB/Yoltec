import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, NgForm } from '@angular/forms';
import { Subject, of } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import {
  Cita, CitaService, CreateCitaPayload,
  AvailabilityStatus, CitaAvailabilityDay
} from '../../../../../services/cita.service';
import {
  PreEvaluacionIAService, ChatMessage,
  ChatResponse, PreEvaluacion, PreEvaluacionResult
} from '../../../../../services/pre-evaluacion-ia.service';

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
  selector: 'app-sd-citas',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './sd-citas.component.html',
})
export class SdCitasComponent implements OnInit, OnDestroy {
  citas: Cita[] = [];
  isLoadingCitas = false;
  citasError: string | null = null;
  pendingCitas: Cita[] = [];
  handledCitas: Cita[] = [];

  showCreateForm = false;
  createFormData: Partial<CreateCitaPayload> = { fecha_cita: '', hora_cita: '', motivo: '' };
  readonly timeSlots: string[] = this.generateTimeSlots();
  readonly totalSlotsPerDay = this.timeSlots.length;
  readonly weekDays = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
  currentMonth: Date = this.startOfMonth(new Date());
  calendarWeeks: CalendarDay[][] = [];
  availabilityMap = new Map<string, DayAvailabilityRecord>();
  isLoadingAvailability = false;
  isSubmitting = false;
  submitMessage: string | null = null;

  // Chat IA
  chatMensajes: ChatMessage[] = [];
  chatInput = '';
  isChatLoading = false;
  showPreEvaluacionForm = false;
  selectedCita: Cita | null = null;
  resultadoPreEvaluacion: PreEvaluacionResult | null = null;
  preEvaluaciones: PreEvaluacion[] = [];
  isLoadingPreEvaluaciones = false;
  preEvaluacionError: string | null = null;

  private destroy$ = new Subject<void>();

  constructor(
    private citaService: CitaService,
    private preEvaluacionIAService: PreEvaluacionIAService,
  ) {}

  ngOnInit(): void {
    this.buildCalendar();
    this.loadAvailability();
    this.loadCitas();
    this.loadPreEvaluaciones();
  }

  ngOnDestroy(): void { this.destroy$.next(); this.destroy$.complete(); }

  // ── Citas ────────────────────────────────────────────────────────────────────

  loadCitas(): void {
    this.isLoadingCitas = true;
    this.citasError = null;
    this.citaService.getCitas()
      .pipe(takeUntil(this.destroy$), catchError(err => { this.citasError = err?.error?.message || 'Error al cargar citas.'; return of([]); }), finalize(() => this.isLoadingCitas = false))
      .subscribe(data => {
        this.citas = data;
        this.pendingCitas = data.filter(c => c.estatus === 'programada');
        this.handledCitas = data.filter(c => c.estatus !== 'programada');
      });
  }

  toggleCreateForm(): void {
    this.showCreateForm = !this.showCreateForm;
    if (!this.showCreateForm) {
      this.createFormData = { fecha_cita: '', hora_cita: '', motivo: '' };
      this.submitMessage = null;
    }
  }

  onCreateCita(form: NgForm): void {
    if (form.invalid || !this.createFormData.fecha_cita || !this.createFormData.hora_cita) return;
    this.isSubmitting = true;
    this.submitMessage = null;
    this.citaService.createCita(this.createFormData as CreateCitaPayload)
      .pipe(takeUntil(this.destroy$), catchError(err => { this.submitMessage = err?.error?.message || 'Error al agendar.'; return of(null); }), finalize(() => this.isSubmitting = false))
      .subscribe(res => {
        if (res) {
          this.submitMessage = 'Cita agendada correctamente.';
          this.showCreateForm = false;
          this.createFormData = { fecha_cita: '', hora_cita: '', motivo: '' };
          this.loadCitas();
          this.loadAvailability();
        }
      });
  }

  onCancelCita(cita: Cita): void {
    if (!confirm('¿Seguro que deseas cancelar esta cita?')) return;
    this.isSubmitting = true;
    this.citaService.cancelCita(cita.id)
      .pipe(takeUntil(this.destroy$), catchError(() => of(null)), finalize(() => this.isSubmitting = false))
      .subscribe(res => { if (res) { this.loadCitas(); this.loadAvailability(); } });
  }

  // ── Calendario ───────────────────────────────────────────────────────────────

  get calendarLabel(): string {
    return this.currentMonth.toLocaleDateString('es-MX', { month: 'long', year: 'numeric' });
  }

  get isCurrentMonth(): boolean {
    const now = new Date();
    return this.currentMonth.getFullYear() === now.getFullYear() && this.currentMonth.getMonth() === now.getMonth();
  }

  changeMonth(delta: number): void {
    const d = new Date(this.currentMonth);
    d.setMonth(d.getMonth() + delta);
    this.currentMonth = this.startOfMonth(d);
    this.buildCalendar();
    this.loadAvailability();
  }

  selectCalendarDay(day: CalendarDay): void {
    if (this.isDayUnavailable(day)) return;
    this.createFormData.fecha_cita = day.date;
    this.createFormData.hora_cita = '';
  }

  selectTimeSlot(slot: string): void {
    this.createFormData.hora_cita = this.normalizeTime(slot);
  }

  isSelectedDate(date: string): boolean { return this.createFormData.fecha_cita === date; }

  isDayUnavailable(day: CalendarDay): boolean {
    return !day.isCurrentMonth || day.isPast || day.availability === 'full' || day.availability === 'none';
  }

  // Aviso para días con atención reducida — null si el día es normal o no seleccionado
  get selectedDayWarning(): string | null {
    const fecha = this.createFormData.fecha_cita;
    if (!fecha) return null;
    const rec = this.availabilityMap.get(fecha);
    if (!rec || rec.status !== 'partial') return null;
    const baseMsg = rec.label ? `Atención reducida hoy: ${rec.label}` : 'Este día tiene atención reducida.';
    return rec.horaCierre ? `${baseMsg} (cierre a las ${rec.horaCierre})` : baseMsg;
  }

  get hasAvailableSlotsForSelectedDate(): boolean {
    if (!this.createFormData.fecha_cita) return false;
    const rec = this.availabilityMap.get(this.createFormData.fecha_cita);
    return !rec || rec.takenSlots.size < this.totalSlotsPerDay;
  }

  isSlotUnavailable(slot: string): boolean {
    if (!this.createFormData.fecha_cita) return true;
    const rec = this.availabilityMap.get(this.createFormData.fecha_cita);
    if (!rec) return false;
    const normalized = this.normalizeTime(slot);
    if (rec.horaCierre && normalized >= rec.horaCierre) return true;
    return rec.takenSlots.has(normalized);
  }

  getDayStyle(day: CalendarDay): Record<string, string> {
    if (!day.color) return {};
    return { '--day-custom-color': day.color };
  }

  private buildCalendar(): void {
    const today = this.formatDate(new Date());
    const year = this.currentMonth.getFullYear();
    const month = this.currentMonth.getMonth();
    const firstDay = new Date(year, month, 1).getDay();
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const daysInPrev = new Date(year, month, 0).getDate();

    const days: CalendarDay[] = [];
    for (let i = firstDay - 1; i >= 0; i--) {
      const date = `${year}-${String(month).padStart(2, '0')}-${String(daysInPrev - i).padStart(2, '0')}`;
      days.push({ date, label: daysInPrev - i, isCurrentMonth: false, isToday: false, isPast: true, availability: 'none' });
    }
    for (let d = 1; d <= daysInMonth; d++) {
      const date = `${year}-${String(month + 1).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
      const rec = this.availabilityMap.get(date);
      days.push({
        date, label: d, isCurrentMonth: true,
        isToday: date === today, isPast: date < today,
        availability: rec?.status ?? (date < today ? 'none' : 'available'),
        color: rec?.color ?? null, labelText: rec?.label ?? null,
      });
    }
    const remaining = 42 - days.length;
    for (let d = 1; d <= remaining; d++) {
      const date = `${year}-${String(month + 2).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
      days.push({ date, label: d, isCurrentMonth: false, isToday: false, isPast: false, availability: 'none' });
    }

    this.calendarWeeks = [];
    for (let i = 0; i < days.length; i += 7) {
      this.calendarWeeks.push(days.slice(i, i + 7));
    }
  }

  private loadAvailability(): void {
    this.isLoadingAvailability = true;
    const month = this.currentMonth.getMonth() + 1;
    const year = this.currentMonth.getFullYear();
    this.citaService.getAvailability(month, year)
      .pipe(takeUntil(this.destroy$), catchError(() => of(null)), finalize(() => this.isLoadingAvailability = false))
      .subscribe(response => {
        if (response?.days) this.applyAvailability(response.days);
        else this.availabilityMap = new Map();
        this.buildCalendar();
      });
  }

  private applyAvailability(days: CitaAvailabilityDay[]): void {
    const map = new Map<string, DayAvailabilityRecord>();
    days.forEach(day => {
      const takenSlots = new Set<string>((day.taken_slots || []).map(s => this.normalizeTime(s)));
      let status: AvailabilityStatus;
      if (day.special?.status) status = day.special.status;
      else if (takenSlots.size === 0) status = 'available';
      else if (takenSlots.size >= this.totalSlotsPerDay) status = 'full';
      else status = 'partial';
      map.set(day.date, { takenSlots, status, color: day.special?.color ?? undefined, label: day.special?.label ?? null, horaCierre: day.special?.hora_cierre ?? null });
    });
    this.availabilityMap = map;
  }

  // ── Chat IA ──────────────────────────────────────────────────────────────────

  loadPreEvaluaciones(): void {
    this.isLoadingPreEvaluaciones = true;
    this.preEvaluacionIAService.getPreEvaluaciones()
      .pipe(takeUntil(this.destroy$), catchError(() => of([])), finalize(() => this.isLoadingPreEvaluaciones = false))
      .subscribe((res: any) => this.preEvaluaciones = res?.pre_evaluaciones ?? []);
  }

  toggleChat(cita?: Cita): void {
    if (cita) this.selectedCita = cita;
    this.showPreEvaluacionForm = !this.showPreEvaluacionForm;
    if (this.showPreEvaluacionForm) {
      this.chatMensajes = [{ role: 'assistant', content: '¡Hola! Soy tu asistente médico de pre-evaluación. ¿Cuál es tu principal molestia o síntoma hoy?' }];
      this.chatInput = '';
      this.isChatLoading = false;
      this.resultadoPreEvaluacion = null;
      this.preEvaluacionError = null;
    } else {
      this.selectedCita = null;
      this.chatMensajes = [];
      this.resultadoPreEvaluacion = null;
    }
  }

  enviarMensaje(): void {
    if (!this.chatInput.trim() || this.isChatLoading || !this.selectedCita) return;
    const msg = this.chatInput.trim();
    this.chatInput = '';
    this.chatMensajes.push({ role: 'user', content: msg });
    this.isChatLoading = true;
    this.preEvaluacionError = null;
    this.scrollChat();
    this.preEvaluacionIAService.chat(this.selectedCita.id, this.chatMensajes)
      .pipe(takeUntil(this.destroy$), catchError(err => { this.preEvaluacionError = err?.error?.message || 'Error de conexión con IA.'; return of(null); }), finalize(() => { this.isChatLoading = false; this.scrollChat(); }))
      .subscribe((res: ChatResponse | null) => {
        if (res) {
          this.chatMensajes.push({ role: 'assistant', content: res.message });
          if (res.finished && res.diagnostico) {
            this.resultadoPreEvaluacion = res.diagnostico;
            if (res.pre_evaluacion) this.preEvaluaciones.unshift(res.pre_evaluacion);
          }
        }
      });
  }

  forzarDiagnostico(): void {
    if (!this.selectedCita || this.isChatLoading) return;
    this.chatMensajes.push({ role: 'user', content: 'Por favor genera el diagnóstico final con la información que tienes.' });
    this.isChatLoading = true;
    this.scrollChat();
    this.preEvaluacionIAService.chat(this.selectedCita.id, this.chatMensajes)
      .pipe(takeUntil(this.destroy$), catchError(err => { this.preEvaluacionError = err?.error?.message || 'Error.'; return of(null); }), finalize(() => { this.isChatLoading = false; this.scrollChat(); }))
      .subscribe((res: ChatResponse | null) => {
        if (res) {
          this.chatMensajes.push({ role: 'assistant', content: res.message });
          if (res.finished && res.diagnostico) {
            this.resultadoPreEvaluacion = res.diagnostico;
            if (res.pre_evaluacion) this.preEvaluaciones.unshift(res.pre_evaluacion);
          }
        }
      });
  }

  onChatEnter(event: KeyboardEvent): void {
    if (event.key === 'Enter' && !event.shiftKey) { event.preventDefault(); this.enviarMensaje(); }
  }

  get mensajesUsuario(): number { return this.chatMensajes.filter(m => m.role === 'user').length; }

  tienePreEvaluacion(citaId: number): boolean { return this.preEvaluaciones.some(e => e.cita_id === citaId); }

  getConfianzaClass(c: number): string {
    if (c >= 0.8) return 'confianza-alta';
    if (c >= 0.6) return 'confianza-media';
    if (c >= 0.4) return 'confianza-baja';
    return 'confianza-muy-baja';
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  formatDateDisplay(fecha: string): string {
    return new Intl.DateTimeFormat('es-MX', { day: '2-digit', month: '2-digit', year: '2-digit' }).format(this.toDate(fecha));
  }

  formatTime(hora: string): string {
    const [h, m] = this.normalizeTime(hora).split(':').map(Number);
    const d = new Date(); d.setHours(h, m || 0, 0, 0);
    return new Intl.DateTimeFormat('es-MX', { hour: '2-digit', minute: '2-digit', hour12: false }).format(d);
  }

  normalizeTime(t: string): string { return t.length === 5 ? t : t.substring(0, 5); }

  private scrollChat(): void {
    setTimeout(() => { const el = document.querySelector('.chat-messages'); if (el) el.scrollTop = el.scrollHeight; }, 60);
  }

  private formatDate(d: Date): string {
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  }

  private startOfMonth(d: Date): Date { return new Date(d.getFullYear(), d.getMonth(), 1); }

  private toDate(s: string): Date { const [y, m, d] = s.split('-').map(Number); return new Date(y, m - 1, d); }

  private generateTimeSlots(): string[] {
    const slots: string[] = [];
    for (let h = 8; h < 17; h++) {
      for (let m = 0; m < 60; m += 15) {
        slots.push(`${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`);
      }
    }
    return slots;
  }
}
