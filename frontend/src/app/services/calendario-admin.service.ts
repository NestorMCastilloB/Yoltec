import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { API_BASE_URL } from './api-config';

export interface DiaEspecial {
  id: number;
  fecha: string;
  tipo: 'holiday' | 'vacation' | 'reduced';
  etiqueta: string | null;
}

export const TIPO_LABELS: Record<string, { label: string; color: string }> = {
  holiday:  { label: 'Festivo',     color: '#ef5350' },
  vacation: { label: 'Vacaciones',  color: '#ef5350' },
  reduced:  { label: 'Día reducido', color: '#ffca28' },
};

@Injectable({ providedIn: 'root' })
export class CalendarioAdminService {
  private base = `${API_BASE_URL}/admin/calendario`;

  constructor(private http: HttpClient) {}

  getDias(month: number, year: number): Observable<DiaEspecial[]> {
    return this.http.get<{ dias: DiaEspecial[] }>(this.base, { params: { month, year } })
      .pipe(map(r => r.dias));
  }

  saveDia(fecha: string, tipo: string, etiqueta: string): Observable<any> {
    return this.http.post(this.base, { fecha, tipo, etiqueta });
  }

  deleteDia(id: number): Observable<any> {
    return this.http.delete(`${this.base}/${id}`);
  }
}
