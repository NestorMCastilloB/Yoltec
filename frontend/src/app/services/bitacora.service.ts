import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_BASE_URL } from './api-config';

export interface Bitacora {
  id: number;
  cita_id: number;
  alumno_id: number;
  doctor_id: number;
  diagnostico?: string | null;
  tratamiento?: string | null;
  observaciones?: string | null;
  peso?: string | null;
  altura?: string | null;
  temperatura?: string | null;
  presion_arterial?: string | null;
  created_at: string;
  updated_at: string;
  cita?: {
    id: number;
    fecha_cita: string;
    hora_cita: string;
    motivo?: string | null;
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

export interface CreateBitacoraPayload {
  cita_id: number;
  diagnostico?: string;
  tratamiento?: string;
  observaciones?: string;
  peso?: string;
  altura?: string;
  temperatura?: string;
  presion_arterial?: string;
}

@Injectable({
  providedIn: 'root'
})
export class BitacoraService {
  private readonly baseUrl = `${API_BASE_URL}/bitacoras`;

  constructor(private http: HttpClient) {}

  getBitacoras(): Observable<Bitacora[]> {
    return this.http.get<Bitacora[]>(this.baseUrl);
  }

  createBitacora(payload: CreateBitacoraPayload): Observable<{ message: string; bitacora: Bitacora }> {
    return this.http.post<{ message: string; bitacora: Bitacora }>(this.baseUrl, payload);
  }

  updateBitacora(id: number, payload: Partial<CreateBitacoraPayload>): Observable<{ message: string; bitacora: Bitacora }> {
    return this.http.put<{ message: string; bitacora: Bitacora }>(`${this.baseUrl}/${id}`, payload);
  }
}
