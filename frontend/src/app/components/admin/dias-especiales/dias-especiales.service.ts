import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { environment } from '../../../../environments/environment';

export type TipoDiaEspecial = 'holiday' | 'vacation' | 'reduced';

export interface DiaEspecialItem {
  id: number;
  fecha: string;
  tipo: TipoDiaEspecial;
  etiqueta: string | null;
}

export interface DiaEspecialPayload {
  fecha: string;
  tipo: TipoDiaEspecial;
  etiqueta?: string | null;
}

@Injectable({ providedIn: 'root' })
export class DiasEspecialesService {
  private base = `${environment.apiUrl}/admin/calendario`;

  constructor(private http: HttpClient) {}

  private headers(): { headers: HttpHeaders } {
    const token = localStorage.getItem('auth_token');
    return { headers: new HttpHeaders({ Authorization: `Bearer ${token}` }) };
  }

  // GET /api/admin/calendario?month=X&year=Y → días del mes
  getDias(month: number, year: number): Observable<DiaEspecialItem[]> {
    const params = new HttpParams().set('month', month).set('year', year);
    return this.http.get<{ dias: DiaEspecialItem[] }>(this.base, { ...this.headers(), params })
      .pipe(map(res => res.dias));
  }

  // POST /api/admin/calendario → registra/actualiza día especial
  agregar(payload: DiaEspecialPayload): Observable<DiaEspecialItem> {
    return this.http.post<{ dia: DiaEspecialItem }>(this.base, payload, this.headers())
      .pipe(map(res => res.dia));
  }

  // DELETE /api/admin/calendario/{id} → eliminar
  eliminar(id: number): Observable<void> {
    return this.http.delete<void>(`${this.base}/${id}`, this.headers());
  }
}
