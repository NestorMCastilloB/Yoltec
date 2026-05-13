import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { API_BASE_URL } from '../../../../services/api-config';

export interface RecetaItem {
  id: number;
  cita_id: number;
  alumno_id: number;
  fecha_emision: string;
  medicamentos: string;
  indicaciones?: string | null;
  cita?: { id: number; fecha_cita: string; hora_cita: string } | null;
  alumno?: { id: number; nombre: string; apellido: string; numero_control?: string } | null;
}

export interface PaginatedRecetas {
  data: RecetaItem[];
  total: number;
  current_page: number;
  last_page: number;
}

export interface RecetaPayload {
  cita_id: number;
  medicamentos: string;
  indicaciones?: string;
  fecha_emision: string;
}

@Injectable({ providedIn: 'root' })
export class DoctorRecetasService {
  private readonly base = `${API_BASE_URL}/doctor/recetas`;

  constructor(private http: HttpClient) {}

  // GET /api/doctor/recetas?page=&search= — soporta array plano o respuesta paginada
  getRecetas(page = 1, search = ''): Observable<PaginatedRecetas> {
    let params = new HttpParams().set('page', page);
    if (search.trim()) params = params.set('search', search.trim());
    return this.http.get<any>(this.base, { params }).pipe(
      map(res => Array.isArray(res)
        ? { data: res, total: res.length, current_page: 1, last_page: 1 }
        : res
      )
    );
  }

  // GET /api/doctor/recetas/{id}
  getReceta(id: number): Observable<RecetaItem> {
    return this.http.get<RecetaItem>(`${this.base}/${id}`);
  }

  // POST /api/doctor/recetas
  crearReceta(payload: RecetaPayload): Observable<{ message: string; receta: RecetaItem }> {
    return this.http.post<{ message: string; receta: RecetaItem }>(this.base, payload);
  }

  // PUT /api/doctor/recetas/{id}
  actualizarReceta(id: number, payload: RecetaPayload): Observable<{ message: string; receta: RecetaItem }> {
    return this.http.put<{ message: string; receta: RecetaItem }>(`${this.base}/${id}`, payload);
  }
}
