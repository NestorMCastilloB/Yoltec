import { Alumno, Doctor } from '../../../services/admin.service';
import { DiaEspecial } from '../../../services/calendario-admin.service';

export interface UsuarioRow {
  key: string;
  id: number;
  initials: string;
  nombre: string;
  sub: string;
  email: string;
  rol: 'alumno' | 'doctor';
}

export interface CalendarCellAdmin {
  date: string;
  label: number;
  isCurrentMonth: boolean;
  isPast: boolean;
  diaEspecial: DiaEspecial | null;
}

export function formatFechaDia(iso: string): string {
  if (!iso) return '';
  const [y, m, d] = iso.split('T')[0].split('-').map(Number);
  if (!y || !m || !d) return iso;
  return new Intl.DateTimeFormat('es-MX', { day: 'numeric', month: 'short' }).format(new Date(y, m - 1, d));
}

export function todayYmd(): string {
  const t = new Date();
  return `${t.getFullYear()}-${String(t.getMonth() + 1).padStart(2, '0')}-${String(t.getDate()).padStart(2, '0')}`;
}

export function toAlumnoRow(a: Alumno): UsuarioRow {
  return {
    key: `a-${a.id}`,
    id: a.id,
    initials: `${a.nombre[0] ?? ''}${a.apellido[0] ?? ''}`.toUpperCase(),
    nombre: `${a.nombre} ${a.apellido}`,
    sub: a.numero_control,
    email: a.email,
    rol: 'alumno',
  };
}

export function toDoctorRow(d: Doctor): UsuarioRow {
  return {
    key: `d-${d.id}`,
    id: d.id,
    initials: `${d.nombre[0] ?? ''}${d.apellido[0] ?? ''}`.toUpperCase(),
    nombre: `${d.nombre} ${d.apellido}`,
    sub: d.username,
    email: d.email,
    rol: 'doctor',
  };
}

export function buildCalGridAdmin(currentMonth: Date, diasEspeciales: DiaEspecial[]): CalendarCellAdmin[][] {
  const year = currentMonth.getFullYear();
  const month = currentMonth.getMonth();
  const dow = new Date(year, month, 1).getDay();
  const daysBack = dow === 0 ? 6 : dow - 1;
  const cursor = new Date(year, month, 1 - daysBack);
  const todayStr = todayYmd();
  const diasMap = new Map(diasEspeciales.map(d => [d.fecha, d]));
  const weeks: CalendarCellAdmin[][] = [];

  for (let w = 0; w < 6; w++) {
    const week: CalendarCellAdmin[] = [];
    while (week.length < 6) {
      if (cursor.getDay() !== 0) {
        const ds = `${cursor.getFullYear()}-${String(cursor.getMonth() + 1).padStart(2, '0')}-${String(cursor.getDate()).padStart(2, '0')}`;
        week.push({
          date: ds,
          label: cursor.getDate(),
          isCurrentMonth: cursor.getMonth() === month,
          isPast: ds < todayStr,
          diaEspecial: diasMap.get(ds) ?? null,
        });
      }
      cursor.setDate(cursor.getDate() + 1);
    }
    weeks.push(week);
  }
  return weeks;
}

export function filterDiasProximos(dias: DiaEspecial[], limit = 3): DiaEspecial[] {
  const todayStr = todayYmd();
  return dias.filter(d => d.fecha >= todayStr).slice(0, limit);
}
