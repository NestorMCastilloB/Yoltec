import { Component, Input, Output, EventEmitter, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AgendarCitaService, Cita, Slot, Disponibilidad, AlumnoBusqueda } from './agendar-cita.service';
import { AuthService } from '../../../services/auth.service';

interface GridDay {
  empty?: boolean;
  day?: number;
  dateStr?: string;
  status?: 'good' | 'mid' | 'none' | 'past';
  libres?: number;
  isToday?: boolean;
}

@Component({
  selector: 'app-agendar-cita',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './agendar-cita.component.html',
  styleUrl: './agendar-cita.component.css'
})
export class AgendarCitaComponent implements OnInit {
  @Input() modo: 'alumno' | 'doctor' = 'alumno';
  @Input() alumnoId?: number;
  @Input() alumnoInfo?: AlumnoBusqueda;
  @Output() citaAgendada = new EventEmitter<Cita>();

  private svc = inject(AgendarCitaService);
  private auth = inject(AuthService);

  // 1=buscar alumno (doctor), 2=calendario+slots, 3=modal confirmación
  currentStep = 2;

  // Step 1
  searchQuery = '';
  searchResults: AlumnoBusqueda[] = [];
  alumnoSeleccionado: AlumnoBusqueda | null = null;
  searchError = '';
  searching = false;

  // Step 2 — calendario
  currentYear = new Date().getFullYear();
  currentMonth = new Date().getMonth() + 1;
  disponibilidad: Record<string, Disponibilidad> = {};
  gridDays: GridDay[] = [];
  fechaSeleccionada: string | null = null;
  slots: Slot[] = [];
  slotSeleccionado: Slot | null = null;
  loadingSlots = false;
  loadingDisp = false;

  readonly meses = ['Enero','Febrero','Marzo','Abril','Mayo','Junio',
                    'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
  readonly dias = ['Domingo','Lunes','Martes','Miércoles','Jueves','Viernes','Sábado'];
  readonly mesesMin = ['enero','febrero','marzo','abril','mayo','junio',
                       'julio','agosto','septiembre','octubre','noviembre','diciembre'];

  // Step 3 — modal
  motivo = '';
  motivoError = '';
  confirmando = false;

  // Toast
  toastMsg = '';
  private toastTimer: ReturnType<typeof setTimeout> | null = null;

  ngOnInit(): void {
    if (this.modo === 'doctor' && this.alumnoId && this.alumnoInfo) {
      // Alumno ya seleccionado externamente — ir directo al calendario
      this.alumnoSeleccionado = this.alumnoInfo;
      this.currentStep = 2;
      this.cargarDisponibilidad();
    } else if (this.modo === 'doctor') {
      this.currentStep = 1;
    } else {
      this.currentStep = 2;
      this.cargarDisponibilidad();
    }
  }

  // ─── Step 1 ───────────────────────────────────────────────
  buscarAlumno(): void {
    if (!this.searchQuery.trim()) return;
    this.searchError = '';
    this.searchResults = [];
    this.searching = true;
    this.svc.buscarAlumno(this.searchQuery.trim()).subscribe({
      next: (results) => {
        this.searchResults = results;
        this.searching = false;
        if (!results.length) this.searchError = 'No se encontró ningún alumno con ese criterio.';
      },
      error: () => {
        this.searching = false;
        this.searchError = 'Error al buscar alumno. Intenta de nuevo.';
      }
    });
  }

  seleccionarAlumno(alumno: AlumnoBusqueda): void {
    this.alumnoSeleccionado = alumno;
    this.alumnoId = alumno.id;
    this.currentStep = 2;
    this.cargarDisponibilidad();
  }

  // ─── Step 2 ───────────────────────────────────────────────
  cargarDisponibilidad(): void {
    const mes = `${this.currentYear}-${String(this.currentMonth).padStart(2, '0')}`;
    this.loadingDisp = true;
    this.svc.getDisponibilidad(mes).subscribe({
      next: (data) => { this.disponibilidad = data; this.loadingDisp = false; this.buildGrid(); },
      error: () => { this.loadingDisp = false; this.buildGrid(); }
    });
  }

  buildGrid(): void {
    const cells: GridDay[] = [];
    const today = new Date();
    const todayStr = this.fmt(today.getFullYear(), today.getMonth() + 1, today.getDate());
    const daysInMonth = new Date(this.currentYear, this.currentMonth, 0).getDate();
    const firstDow = new Date(this.currentYear, this.currentMonth - 1, 1).getDay();

    // Relleno inicial: Lun=0..Sáb=5. Dom (0) → sin relleno
    const pad = firstDow === 0 ? 0 : firstDow - 1;
    for (let i = 0; i < pad; i++) cells.push({ empty: true });

    for (let d = 1; d <= daysInMonth; d++) {
      const dow = new Date(this.currentYear, this.currentMonth - 1, d).getDay();
      if (dow === 0) continue; // Omitir domingos

      const dateStr = this.fmt(this.currentYear, this.currentMonth, d);
      const disp = this.disponibilidad[dateStr];
      const isPast = dateStr < todayStr;

      let status: GridDay['status'];
      if (isPast) {
        status = 'past';
      } else if (!disp || disp.libres === 0) {
        status = 'none';
      } else if (disp.libres / disp.total >= 0.5) {
        status = 'good';
      } else {
        status = 'mid';
      }

      cells.push({ day: d, dateStr, status, libres: disp?.libres ?? 0, isToday: dateStr === todayStr });
    }
    this.gridDays = cells;
  }

  seleccionarDia(cell: GridDay): void {
    if (!cell.dateStr || cell.status === 'past' || cell.status === 'none') return;
    this.fechaSeleccionada = cell.dateStr;
    this.slotSeleccionado = null;
    this.slots = [];
    this.loadingSlots = true;
    this.svc.getSlots(cell.dateStr).subscribe({
      next: (slots) => { this.slots = slots; this.loadingSlots = false; },
      error: () => { this.loadingSlots = false; }
    });
  }

  seleccionarSlot(slot: Slot): void {
    this.slotSeleccionado = slot;
    this.currentStep = 3;
  }

  mesAnterior(): void {
    if (this.currentMonth === 1) { this.currentMonth = 12; this.currentYear--; }
    else this.currentMonth--;
    this.resetCalendario();
  }

  mesSiguiente(): void {
    if (this.currentMonth === 12) { this.currentMonth = 1; this.currentYear++; }
    else this.currentMonth++;
    this.resetCalendario();
  }

  private resetCalendario(): void {
    this.fechaSeleccionada = null;
    this.slots = [];
    this.slotSeleccionado = null;
    this.cargarDisponibilidad();
  }

  // ─── Step 3 ───────────────────────────────────────────────
  cerrarModal(): void {
    this.currentStep = 2;
    this.slotSeleccionado = null;
    this.motivo = '';
    this.motivoError = '';
  }

  confirmarCita(): void {
    if (!this.motivo.trim()) { this.motivoError = '* El motivo es obligatorio'; return; }
    if (!this.fechaSeleccionada || !this.slotSeleccionado) return;

    this.motivoError = '';
    this.confirmando = true;

    const payload: { fecha: string; slot_id: number; motivo: string; alumno_id?: number } = {
      fecha: this.fechaSeleccionada,
      slot_id: this.slotSeleccionado.id,
      motivo: this.motivo.trim()
    };

    if (this.modo === 'doctor' && this.alumnoId) {
      payload.alumno_id = this.alumnoId;
    } else if (this.modo === 'alumno') {
      const user = this.auth.getCurrentUser();
      if (user?.id) payload.alumno_id = user.id;
    }

    this.svc.confirmarCita(payload).subscribe({
      next: (cita) => {
        this.confirmando = false;
        this.citaAgendada.emit(cita);
        this.cerrarModal();
        this.mostrarToast('Cita agendada exitosamente');
        this.cargarDisponibilidad();
      },
      error: () => {
        this.confirmando = false;
        this.motivoError = 'Error al confirmar la cita. Intenta de nuevo.';
      }
    });
  }

  private mostrarToast(msg: string): void {
    this.toastMsg = msg;
    if (this.toastTimer) clearTimeout(this.toastTimer);
    this.toastTimer = setTimeout(() => { this.toastMsg = ''; }, 3500);
  }

  // ─── Helpers ──────────────────────────────────────────────
  private fmt(y: number, m: number, d: number): string {
    return `${y}-${String(m).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
  }

  get mesLabel(): string {
    return `${this.meses[this.currentMonth - 1]} ${this.currentYear}`;
  }

  get fechaLabel(): string {
    if (!this.fechaSeleccionada) return '';
    const [y, m, d] = this.fechaSeleccionada.split('-').map(Number);
    const dow = new Date(y, m - 1, d).getDay();
    return `${this.dias[dow]}, ${d} de ${this.mesesMin[m - 1]} ${y}`;
  }

  get slotResumen(): string {
    if (!this.slotSeleccionado || !this.fechaSeleccionada) return '';
    const [y, m, d] = this.fechaSeleccionada.split('-').map(Number);
    const dow = new Date(y, m - 1, d).getDay();
    return `${this.dias[dow]} ${d} de ${this.mesesMin[m - 1]} · ${this.slotSeleccionado.hora_inicio} – ${this.slotSeleccionado.hora_fin}`;
  }
}
