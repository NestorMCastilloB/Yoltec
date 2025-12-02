import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_BASE_URL } from './api-config';

export interface Cita {
  id: number;
  clave_cita: string;
  alumno_id: number | null;
  doctor_id: number | null;
  fecha_cita: string;
  hora_cita: string;
  motivo?: string | null;
  estatus: string;
  fecha_hora_atencion?: string | null;
  notas?: string | null;
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

export interface CreateCitaPayload {
  fecha_cita: string;
  hora_cita: string;
  motivo?: string;
  alumno_id?: number;
  numero_control?: string;
}

@Injectable({
  providedIn: 'root'
})
export class CitaService {
  private readonly baseUrl = `${API_BASE_URL}/citas`;

  constructor(private http: HttpClient) {}

  getCitas(): Observable<Cita[]> {
    return this.http.get<Cita[]>(this.baseUrl);
  }

  createCita(payload: CreateCitaPayload): Observable<{ message: string; cita: Cita }> {
    return this.http.post<{ message: string; cita: Cita }>(this.baseUrl, payload);
  }

  cancelCita(id: number): Observable<{ message: string; cita: Cita }> {
    return this.http.post<{ message: string; cita: Cita }>(`${this.baseUrl}/${id}/cancelar`, {});
  }

  markAsAttended(id: number): Observable<{ message: string; cita: Cita }> {
    return this.http.post<{ message: string; cita: Cita }>(`${this.baseUrl}/${id}/atender`, {});
  }
}
