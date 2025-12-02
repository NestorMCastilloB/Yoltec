import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
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

  constructor(private http: HttpClient) {}

  getRecetas(): Observable<Receta[]> {
    return this.http.get<Receta[]>(this.baseUrl);
  }

  createReceta(payload: CreateRecetaPayload): Observable<{ message: string; receta: Receta }> {
    return this.http.post<{ message: string; receta: Receta }>(this.baseUrl, payload);
  }

  updateReceta(id: number, payload: CreateRecetaPayload): Observable<{ message: string; receta: Receta }> {
    return this.http.put<{ message: string; receta: Receta }>(`${this.baseUrl}/${id}`, payload);
  }
}
