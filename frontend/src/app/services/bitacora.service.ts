import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { map, tap } from 'rxjs/operators';
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

  private bitacorasCache: Bitacora[] | null = null;
  private bitacorasCacheExpiry = 0;
  private readonly CACHE_TTL_MS = 5 * 60 * 1000;

  constructor(private http: HttpClient) {}

  // Carga todas las bitácoras sin filtros y cachea; el filtrado ocurre en el componente
  getBitacoras(): Observable<Bitacora[]> {
    if (this.bitacorasCache && Date.now() < this.bitacorasCacheExpiry) {
      return of(this.bitacorasCache);
    }
    return this.http.get<{ bitacoras: Bitacora[] }>(this.baseUrl).pipe(
      map(res => res.bitacoras ?? []),
      tap(bitacoras => {
        this.bitacorasCache = bitacoras;
        this.bitacorasCacheExpiry = Date.now() + this.CACHE_TTL_MS;
      })
    );
  }

  invalidarBitacoras(): void {
    this.bitacorasCache = null;
  }

  createBitacora(payload: CreateBitacoraPayload): Observable<{ message: string; bitacora: Bitacora }> {
    return this.http.post<{ message: string; bitacora: Bitacora }>(this.baseUrl, payload).pipe(
      tap(() => { this.bitacorasCache = null; })
    );
  }

  updateBitacora(id: number, payload: Partial<CreateBitacoraPayload>): Observable<{ message: string; bitacora: Bitacora }> {
    return this.http.put<{ message: string; bitacora: Bitacora }>(`${this.baseUrl}/${id}`, payload).pipe(
      tap(() => { this.bitacorasCache = null; })
    );
  }
}
