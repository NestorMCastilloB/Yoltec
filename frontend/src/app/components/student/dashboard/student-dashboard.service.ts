import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_BASE_URL } from '../../../services/api-config';

export interface DashboardAlumno {
  proximas_citas: DashboardCita[];
  ultima_visita: UltimaVisita | null;
  recetas_activas: RecetaActiva[];
  recordatorio: Recordatorio | null;
}

export interface DashboardCita {
  id: number;
  fecha_cita: string;
  hora_cita: string;
  motivo: string | null;
  estatus: string;
  doctor_nombre: string;
}

export interface UltimaVisita {
  fecha: string;
  diagnostico: string | null;
}

export interface RecetaActiva {
  id: number;
  medicamento: string;
  indicaciones: string;
  dias_restantes: number;
}

export interface Recordatorio {
  titulo: string;
  mensaje: string;
}

@Injectable({
  providedIn: 'root'
})
export class StudentDashboardService {
  private readonly baseUrl = `${API_BASE_URL}/dashboard/alumno`;

  constructor(private http: HttpClient) {}

  // GET /api/dashboard/alumno — resumen completo del dashboard
  getDashboard(): Observable<DashboardAlumno> {
    return this.http.get<DashboardAlumno>(this.baseUrl);
  }

  // DELETE /api/citas/{id}/cancelar — cancela una cita
  cancelarCita(citaId: number): Observable<{ message: string }> {
    return this.http.delete<{ message: string }>(`${API_BASE_URL}/citas/${citaId}/cancelar`);
  }
}
