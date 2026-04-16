import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { API_BASE_URL } from './api-config';

export interface MesStats {
  mes: string;
  label: string;
  total: number;
  atendidas: number;
  canceladas: number;
  no_asistio: number;
  programadas: number;
}

export interface ResumenEstados {
  programada: number;
  atendida: number;
  cancelada: number;
  no_asistio: number;
}

export interface Estadisticas {
  citas_por_mes: MesStats[];
  resumen_estados: ResumenEstados;
  tasa_asistencia: number;
  total_citas: number;
}

@Injectable({ providedIn: 'root' })
export class EstadisticasService {
  private baseUrl = API_BASE_URL;

  constructor(private http: HttpClient) {}

  getEstadisticas(): Observable<Estadisticas> {
    return this.http.get<Estadisticas>(`${this.baseUrl}/estadisticas`);
  }
}
