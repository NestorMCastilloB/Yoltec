import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
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

  // GET /api/admin/calendario?month=X&year=Y → días del mes. AuthInterceptor agrega Bearer.
  getDias(month: number, year: number): Observable<DiaEspecialItem[]> {
    const params = new HttpParams().set('month', month).set('year', year);
    return this.http.get<{ dias: DiaEspecialItem[] }>(this.base, { params })
      .pipe(map(res => res.dias));
  }

  agregar(payload: DiaEspecialPayload): Observable<DiaEspecialItem> {
    return this.http.post<{ dia: DiaEspecialItem }>(this.base, payload)
      .pipe(map(res => res.dia));
  }

  eliminar(id: number): Observable<void> {
    return this.http.delete<void>(`${this.base}/${id}`);
  }
}
