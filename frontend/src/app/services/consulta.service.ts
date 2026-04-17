import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_BASE_URL } from './api-config';

export interface Consulta {
  id: number;
  cita_id: number;
  doctor_id: number;
  alumno_id: number;
  diagnostico: string;
  tratamiento: string;
  observaciones: string | null;
  created_at: string;
  doctor?: { nombre: string; apellido: string };
}

@Injectable({ providedIn: 'root' })
export class ConsultaService {
  constructor(private http: HttpClient) {}

  guardar(citaId: number, data: { diagnostico: string; tratamiento: string; observaciones?: string }): Observable<{ message: string; consulta: Consulta }> {
    return this.http.post<{ message: string; consulta: Consulta }>(`${API_BASE_URL}/citas/${citaId}/consulta`, data);
  }

  obtener(citaId: number): Observable<{ consulta: Consulta }> {
    return this.http.get<{ consulta: Consulta }>(`${API_BASE_URL}/citas/${citaId}/consulta`);
  }
}
