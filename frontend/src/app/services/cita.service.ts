import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { map, tap } from 'rxjs/operators';
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

export type AvailabilityStatus = 'available' | 'partial' | 'full';

export interface AvailabilitySpecial {
  type: string;
  label?: string | null;
  status?: AvailabilityStatus;
  color?: string;
}

export interface CitaAvailabilityDay {
  date: string;
  taken_slots: string[];
  special?: AvailabilitySpecial | null;
}

export interface CitaAvailabilityResponse {
  month: number;
  year: number;
  days: CitaAvailabilityDay[];
}

@Injectable({
  providedIn: 'root'
})
export class CitaService {
  private readonly baseUrl = `${API_BASE_URL}/citas`;

  private citasCache: Cita[] | null = null;
  private citasCacheExpiry = 0;
  private readonly CACHE_TTL_MS = 5 * 60 * 1000;

  constructor(private http: HttpClient) {}

  // Devuelve caché instantáneo si tiene menos de 5 min; refresca en background si es fresco
  getCitas(): Observable<Cita[]> {
    if (this.citasCache && Date.now() < this.citasCacheExpiry) {
      return of(this.citasCache);
    }
    return this.http.get<{ citas: Cita[] }>(this.baseUrl).pipe(
      map(r => r.citas ?? []),
      tap(citas => {
        this.citasCache = citas;
        this.citasCacheExpiry = Date.now() + this.CACHE_TTL_MS;
      })
    );
  }

  invalidarCitas(): void {
    this.citasCache = null;
  }

  createCita(payload: CreateCitaPayload): Observable<{ message: string; cita: Cita }> {
    return this.http.post<{ message: string; cita: Cita }>(this.baseUrl, payload).pipe(
      tap(() => { this.citasCache = null; })
    );
  }

  cancelCita(id: number): Observable<{ message: string; cita: Cita }> {
    return this.http.post<{ message: string; cita: Cita }>(`${this.baseUrl}/${id}/cancelar`, {}).pipe(
      tap(() => { this.citasCache = null; })
    );
  }

  reprogramarCita(id: number, fecha_cita: string, hora_cita: string): Observable<{ message: string; cita: Cita }> {
    return this.http.put<{ message: string; cita: Cita }>(`${this.baseUrl}/${id}/reprogramar`, { fecha_cita, hora_cita }).pipe(
      tap(() => { this.citasCache = null; })
    );
  }

  markAsAttended(id: number): Observable<{ message: string; cita: Cita }> {
    return this.http.post<{ message: string; cita: Cita }>(`${this.baseUrl}/${id}/atender`, {}).pipe(
      tap(() => { this.citasCache = null; })
    );
  }

  markAsNoShow(id: number): Observable<{ message: string; cita: Cita }> {
    return this.http.post<{ message: string; cita: Cita }>(`${this.baseUrl}/${id}/no-asistio`, {}).pipe(
      tap(() => { this.citasCache = null; })
    );
  }

  getAvailability(month?: number, year?: number): Observable<CitaAvailabilityResponse> {
    const params: Record<string, string> = {};
    if (month) params['month'] = String(month);
    if (year) params['year'] = String(year);
    return this.http.get<CitaAvailabilityResponse>(`${this.baseUrl}/disponibilidad`, { params });
  }
}
