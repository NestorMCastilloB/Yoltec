// Utilidades de formato compartidas — elimina duplicación en 8+ componentes

const FECHA_FORMATTER = new Intl.DateTimeFormat('es-MX', { day: '2-digit', month: 'short', year: 'numeric' });
const FECHA_HORA_FORMATTER = new Intl.DateTimeFormat('es-MX', { dateStyle: 'medium', timeStyle: 'short' });

// "2026-05-27" o "2026-05-27T14:30:00" → "27 MAY 2026"
export function formatFecha(fecha: string | null | undefined): string {
  if (!fecha) return '—';
  const datePart = fecha.split('T')[0];
  const [y, m, d] = datePart.split('-').map(Number);
  if (!y || !m || !d || isNaN(y) || isNaN(m) || isNaN(d)) return '—';
  return FECHA_FORMATTER.format(new Date(y, m - 1, d)).toUpperCase();
}

// "2026-05-27T14:30:00" → "27 may 2026, 14:30"
export function formatFechaHora(fecha: string | null | undefined): string {
  if (!fecha) return '—';
  return FECHA_HORA_FORMATTER.format(new Date(fecha));
}

// "nombre apellido" → "NA", o (nombre, apellido) → "NA"
export function iniciales(nombre?: string, apellido?: string): string {
  if (!nombre && !apellido) return '?';
  if (apellido) return ((nombre?.[0] ?? '') + (apellido[0])).toUpperCase() || '?';
  return nombre!.split(' ').slice(0, 2).map(p => p[0]).join('').toUpperCase() || '?';
}
