import { AvailabilityStatus, CalendarAvailability } from './doctor-citas-utils';

export interface DayAvailabilityRecord {
  takenSlots: Set<string>;
  status: AvailabilityStatus;
  color?: string;
  label?: string | null;
  horaCierre?: string | null;
}

export interface CalendarDay {
  date: string;
  label: number;
  isCurrentMonth: boolean;
  isToday: boolean;
  isPast: boolean;
  availability: CalendarAvailability;
  color?: string | null;
  labelText?: string | null;
}

export interface CitasFiltro {
  search: string;
  estatus: string;
  fechaDesde: string;
  fechaHasta: string;
}

export type { AvailabilityStatus, CalendarAvailability };
