import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of, throwError } from 'rxjs';
import { map } from 'rxjs/operators';
import { API_BASE_URL } from '../../../services/api-config';

export interface Disponibilidad {
  libres: number;
  total: number;
}

export interface Slot {
  id: number;
  hora_inicio: string;
  hora_fin: string;
}

export interface Cita {
  id: number;
  fecha: string;          // alias de fecha_cita para compatibilidad
  fecha_cita: string;
  hora_cita: string;
  hora_inicio: string;    // alias de hora_cita para compatibilidad
  hora_fin: string;       // hora_cita + 15min
  motivo: string;
  alumno_id: number;
}

export interface AlumnoBusqueda {
  id: number;
  nombre: string;
  numero_control: string;
  carrera?: string;
}

// Slots fijos del consultorio: 08:00 a 16:45 cada 15min (36 slots)
const HORA_INICIO = 8;
const HORA_FIN = 17;
const STEP_MINUTOS = 15;

interface BackendDay {
  date: string;
  taken_slots: string[];
  special?: { type: string; label?: string | null; status?: 'available' | 'partial' | 'full'; hora_cierre?: string | null } | null;
}

interface DayInfo {
  takenSlots: Set<string>;
  horaCierre: string | null;
  isFull: boolean;
}

const API = API_BASE_URL;

@Injectable({ providedIn: 'root' })
export class AgendarCitaService {
  private http = inject(HttpClient);

  // Cache por mes (key "YYYY-MM") con info por día para generar slots sin segunda llamada
  private monthCache = new Map<string, Map<string, DayInfo>>();
  // Map sintético slot_id → "HH:MM" — necesario porque el componente trabaja con slot.id
  private slotIdToHora = new Map<number, string>();
  private slotCounter = 0;

  // GET /api/alumnos/buscar?q= — solo doctor
  buscarAlumno(q: string): Observable<AlumnoBusqueda[]> {
    return this.http.get<{ alumnos: AlumnoBusqueda[] }>(`${API}/alumnos/buscar`, { params: { q } })
      .pipe(map(r => r.alumnos ?? []));
  }

  // Wrapper sobre /api/citas/disponibilidad que adapta a la interfaz Disponibilidad esperada
  getDisponibilidad(mes: string): Observable<Record<string, Disponibilidad>> {
    const [yearStr, monthStr] = mes.split('-');
    const year = Number(yearStr);
    const month = Number(monthStr);
    return this.http.get<{ days: BackendDay[] }>(`${API}/citas/disponibilidad`, { params: { month, year } })
      .pipe(map(r => this.buildDispRecord(year, month, r.days || [])));
  }

  // Slots calculados localmente desde el cache del mes (no requiere endpoint adicional)
  // Si la fecha es hoy, excluye horas que ya pasaron
  getSlots(fecha: string): Observable<Slot[]> {
    const monthKey = fecha.substring(0, 7);
    const dayInfo = this.monthCache.get(monthKey)?.get(fecha)
      ?? { takenSlots: new Set<string>(), horaCierre: null, isFull: false };
    if (dayInfo.isFull) return of([]);

    const now = new Date();
    const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
    const ahoraHHMM = fecha === todayStr
      ? `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`
      : null;

    const slots: Slot[] = this.allSlots()
      .filter(h =>
        !dayInfo.takenSlots.has(h)
        && (!dayInfo.horaCierre || h < dayInfo.horaCierre)
        && (!ahoraHHMM || h > ahoraHHMM)
      )
      .map(h => {
        const id = ++this.slotCounter;
        this.slotIdToHora.set(id, h);
        return { id, hora_inicio: h, hora_fin: this.addMinutes(h, STEP_MINUTOS) };
      });
    return of(slots);
  }

  // POST /api/citas — traduce slot_id (sintético) a hora_cita antes de enviar
  confirmarCita(body: { fecha: string; slot_id: number; motivo: string; alumno_id?: number }): Observable<Cita> {
    const hora_cita = this.slotIdToHora.get(body.slot_id);
    if (!hora_cita) return throwError(() => new Error('Slot no encontrado. Recarga la página.'));
    const payload: Record<string, any> = {
      fecha_cita: body.fecha,
      hora_cita,
      motivo: body.motivo,
    };
    if (body.alumno_id) payload['alumno_id'] = body.alumno_id;
    return this.http.post<{ cita: any }>(`${API}/citas`, payload).pipe(map(r => {
      const fechaCita = (r.cita.fecha_cita || '').split('T')[0];
      const horaCita = (r.cita.hora_cita || '').substring(0, 5);
      return {
        id: r.cita.id,
        fecha: fechaCita,
        fecha_cita: fechaCita,
        hora_cita: horaCita,
        hora_inicio: horaCita,
        hora_fin: this.addMinutes(horaCita, STEP_MINUTOS),
        motivo: r.cita.motivo,
        alumno_id: r.cita.alumno_id,
      };
    }));
  }

  private buildDispRecord(year: number, month: number, days: BackendDay[]): Record<string, Disponibilidad> {
    const total = this.allSlots().length;
    const result: Record<string, Disponibilidad> = {};
    const info = new Map<string, DayInfo>();
    const daysInMonth = new Date(year, month, 0).getDate();

    for (let d = 1; d <= daysInMonth; d++) {
      const date = `${year}-${String(month).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
      const dow = new Date(year, month - 1, d).getDay();
      if (dow === 0) continue; // domingo cerrado
      result[date] = { libres: total, total };
      info.set(date, { takenSlots: new Set(), horaCierre: null, isFull: false });
    }

    days.forEach(day => {
      const dateKey = (day.date || '').split('T')[0];
      if (!result[dateKey]) return;
      const isFull = day.special?.status === 'full';
      const horaCierre = day.special?.hora_cierre ?? null;
      const takenSlots = new Set(day.taken_slots ?? []);
      info.set(dateKey, { takenSlots, horaCierre, isFull });
      if (isFull) {
        result[dateKey] = { libres: 0, total };
      } else {
        const libres = this.allSlots().filter(s =>
          !takenSlots.has(s) && (!horaCierre || s < horaCierre)
        ).length;
        result[dateKey] = { libres, total };
      }
    });

    this.monthCache.set(`${year}-${String(month).padStart(2, '0')}`, info);
    return result;
  }

  private allSlots(): string[] {
    const slots: string[] = [];
    for (let h = HORA_INICIO; h < HORA_FIN; h++) {
      for (let m = 0; m < 60; m += STEP_MINUTOS) {
        if (h === HORA_FIN - 1 && m > 45) break; // último slot 16:45
        slots.push(`${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`);
      }
    }
    return slots;
  }

  private addMinutes(hhmm: string, mins: number): string {
    const [h, m] = hhmm.split(':').map(Number);
    const total = h * 60 + m + mins;
    return `${String(Math.floor(total / 60)).padStart(2, '0')}:${String(total % 60).padStart(2, '0')}`;
  }
}
