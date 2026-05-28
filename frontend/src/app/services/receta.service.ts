import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { map, tap } from 'rxjs/operators';
import { API_BASE_URL } from './api-config';

export interface Receta {
  id: number;
  cita_id: number;
  alumno_id: number;
  doctor_id: number;
  medicamentos: string;
  indicaciones?: string | null;
  fecha_emision: string;
  created_at: string;
  updated_at: string;
  cita?: {
    id: number;
    fecha_cita: string;
    hora_cita: string;
  } | null;
  alumno?: {
    id: number;
    nombre: string;
    apellido: string;
    numero_control?: string;
  } | null;
  doctor?: {
    id: number;
    nombre: string;
    apellido: string;
    username?: string;
  } | null;
}

export interface CreateRecetaPayload {
  cita_id: number;
  medicamentos: string;
  indicaciones?: string;
  fecha_emision: string;
}

@Injectable({
  providedIn: 'root'
})
export class RecetaService {
  private readonly baseUrl = `${API_BASE_URL}/recetas`;

  private recetasCache: Receta[] | null = null;
  private recetasCacheExpiry = 0;
  private readonly CACHE_TTL_MS = 5 * 60 * 1000;

  constructor(private http: HttpClient) {}

  // Backend devuelve array plano para alumno y paginado {data:[...]} para doctor — normalizar aqui
  getRecetas(): Observable<Receta[]> {
    if (this.recetasCache && Date.now() < this.recetasCacheExpiry) {
      return of(this.recetasCache);
    }
    return this.http.get<Receta[] | { data: Receta[] }>(this.baseUrl).pipe(
      map(res => Array.isArray(res) ? res : (res?.data ?? [])),
      tap(recetas => {
        this.recetasCache = recetas;
        this.recetasCacheExpiry = Date.now() + this.CACHE_TTL_MS;
      })
    );
  }

  invalidarRecetas(): void {
    this.recetasCache = null;
  }

  createReceta(payload: CreateRecetaPayload): Observable<{ message: string; receta: Receta }> {
    return this.http.post<{ message: string; receta: Receta }>(this.baseUrl, payload).pipe(
      tap(() => { this.recetasCache = null; })
    );
  }

  updateReceta(id: number, payload: CreateRecetaPayload): Observable<{ message: string; receta: Receta }> {
    return this.http.put<{ message: string; receta: Receta }>(`${this.baseUrl}/${id}`, payload).pipe(
      tap(() => { this.recetasCache = null; })
    );
  }
}
