// Utilidades puras compartidas entre el padre y los sub-componentes de doctor-citas.
import { Cita } from '../../../../services/cita.service';

export type AvailabilityStatus = 'available' | 'partial' | 'full';
export type CalendarAvailability = 'none' | AvailabilityStatus;

export function getCitaInitials(cita: Cita): string {
  const n = cita.alumno?.nombre ?? '';
  const a = cita.alumno?.apellido ?? '';
  return (n.charAt(0) + a.charAt(0)).toUpperCase();
}

export function getCitaName(cita: Cita): string {
  const n = cita.alumno?.nombre ?? '';
  const a = cita.alumno?.apellido ?? '';
  return `${n} ${a}`.trim();
}

export function getGridCitaClass(cita: Cita): 'ok' | 'cancel' | 'warn' {
  switch (cita.estatus) {
    case 'programada': return 'ok';
    case 'atendida': return 'ok';
    case 'cancelada': return 'cancel';
    case 'no_asistio': return 'cancel';
    default: return 'warn';
  }
}

export function trackByCita(_: number, c: Cita): number {
  return c.id;
}

export function weekLabelFromStart(weekStart: Date): string {
  const end = new Date(weekStart);
  end.setDate(end.getDate() + 5);
  const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
  return `Semana del ${weekStart.getDate()} al ${end.getDate()} ${months[end.getMonth()]}`;
}

export function buildWeekDays(weekStart: Date, today: string): { date: string; label: string; isToday: boolean }[] {
  const dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
  const days: { date: string; label: string; isToday: boolean }[] = [];
  for (let i = 0; i < 6; i++) {
    const d = new Date(weekStart);
    d.setDate(d.getDate() + i);
    const dateStr = formatDate(d);
    days.push({ date: dateStr, label: `${dayNames[i]} ${d.getDate()}`, isToday: dateStr === today });
  }
  return days;
}

export function normalizeTime(hora: string): string {
  const [hours, minutes] = hora.split(':');
  return `${hours?.padStart(2, '0')}:${(minutes ?? '00').padStart(2, '0')}`;
}

export function formatDate(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

export function toDateFromString(fecha: string, hora?: string): Date {
  const [year, month, day] = fecha.split('-').map(Number);
  if (hora) {
    const [h, min] = normalizeTime(hora).split(':').map(Number);
    return new Date(year, (month ?? 1) - 1, day ?? 1, h ?? 0, min ?? 0);
  }
  return new Date(year, (month ?? 1) - 1, day ?? 1);
}

export function startOfDay(date: Date): Date {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

export function startOfMonth(date: Date): Date {
  return new Date(date.getFullYear(), date.getMonth(), 1);
}

export function getMonday(date: Date): Date {
  const d = new Date(date);
  const day = d.getDay();
  const diff = day === 0 ? -6 : 1 - day;
  d.setDate(d.getDate() + diff);
  d.setHours(0, 0, 0, 0);
  return d;
}

export function formatTime(hora: string): string {
  const [hours, minutes] = normalizeTime(hora).split(':').map(Number);
  const date = new Date();
  date.setHours(hours, minutes || 0, 0, 0);
  return new Intl.DateTimeFormat('es-MX', { hour: '2-digit', minute: '2-digit', hour12: false }).format(date);
}

export function formatDateDisplay(fecha: string): string {
  const date = toDateFromString(fecha);
  return new Intl.DateTimeFormat('es-MX', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' }).format(date);
}

export function formatFechaCorta(fecha: string): string {
  if (!fecha) return '—';
  const [y, m, d] = fecha.split('-').map(Number);
  return new Intl.DateTimeFormat('es-MX', { day: 'numeric', month: 'short', year: 'numeric' })
    .format(new Date(y, (m ?? 1) - 1, d ?? 1)).toUpperCase();
}

export function generateTimeSlots(): string[] {
  const slots: string[] = [];
  for (let hour = 8; hour < 17; hour++) {
    ['00', '15', '30', '45'].forEach(min => slots.push(`${String(hour).padStart(2, '0')}:${min}`));
  }
  return slots;
}

export function getStatusColor(status: CalendarAvailability): string {
  switch (status) {
    case 'available': return '#1e88e5';
    case 'partial': return '#ffb300';
    case 'full': return '#ef5350';
    default: return '#cfd8dc';
  }
}

export function applyOpacity(hexColor: string, alpha: number): string {
  const rgb = hexToRgb(hexColor);
  if (!rgb) return hexColor;
  return `rgba(${rgb.r}, ${rgb.g}, ${rgb.b}, ${alpha})`;
}

function hexToRgb(hex: string): { r: number; g: number; b: number } | null {
  let h = hex.replace('#', '');
  if (h.length === 3) h = h.split('').map(c => c + c).join('');
  if (h.length !== 6) return null;
  const n = parseInt(h, 16);
  return { r: (n >> 16) & 255, g: (n >> 8) & 255, b: n & 255 };
}
