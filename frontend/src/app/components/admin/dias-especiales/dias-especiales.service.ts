import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';

export interface DiaEspecialItem {
  id: number;
  fecha: string;
  motivo: string;
}

@Injectable({ providedIn: 'root' })
export class DiasEspecialesService {
  private base = `${environment.apiUrl}/admin/dias-especiales`;

  constructor(private http: HttpClient) {}

  private headers(): { headers: HttpHeaders } {
    const token = localStorage.getItem('auth_token');
    return { headers: new HttpHeaders({ Authorization: `Bearer ${token}` }) };
  }

  // GET /api/admin/dias-especiales → lista completa
  getDias(): Observable<DiaEspecialItem[]> {
    return this.http.get<DiaEspecialItem[]>(this.base, this.headers());
  }

  // POST /api/admin/dias-especiales → agregar
  agregar(fecha: string, motivo: string): Observable<DiaEspecialItem> {
    return this.http.post<DiaEspecialItem>(this.base, { fecha, motivo }, this.headers());
  }

  // DELETE /api/admin/dias-especiales/{id} → eliminar
  eliminar(id: number): Observable<void> {
    return this.http.delete<void>(`${this.base}/${id}`, this.headers());
  }
}
