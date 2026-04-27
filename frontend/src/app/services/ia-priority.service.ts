import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_BASE_URL } from './api-config';

export interface ClasificacionPrioridad {
  cita: {
    id: number;
    clave_cita: string;
    fecha_cita: string;
    hora_cita: string;
    motivo: string;
    alumno: {
      id: number;
      nombre: string;
      numero_control: string;
    };
  };
  prioridad: 'alta' | 'media' | 'baja';
  puntuacion: number;
  justificacion_resumida: string;
  justificacion?: string;
  factores?: string[];
}

export interface ResumenPrioridad {
  message: string;
  total_citas: number;
  resumen: { alta: number; media: number; baja: number };
  citas: ClasificacionPrioridad[];
}

@Injectable({ providedIn: 'root' })
export class IaPriorityService {
  private base = `${API_BASE_URL}/ia/priority`;

  constructor(private http: HttpClient) {}

  getPendientesPorPrioridad(): Observable<ResumenPrioridad> {
    return this.http.get<ResumenPrioridad>(`${this.base}/pendientes`);
  }

  clasificarCita(citaId: number): Observable<any> {
    return this.http.post(`${this.base}/clasificar/${citaId}`, {});
  }
}
