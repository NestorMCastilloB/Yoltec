import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Disponibilidad {
  libres: number;
  total: number;
}

export interface Slot {
  id: number;
  hora_inicio: string;
  hora_fin: string;
}

export interface Cita {
  id: number;
  fecha: string;
  slot_id: number;
  motivo: string;
  alumno_id: number;
  hora_inicio?: string;
  hora_fin?: string;
}

export interface AlumnoBusqueda {
  id: number;
  nombre: string;
  numero_control: string;
  carrera?: string;
}

import { API_BASE_URL } from '../../../services/api-config';

const API = API_BASE_URL;

@Injectable({ providedIn: 'root' })
export class AgendarCitaService {
  private http = inject(HttpClient);

  // GET /api/alumnos/buscar?q=
  buscarAlumno(q: string): Observable<AlumnoBusqueda[]> {
    return this.http.get<AlumnoBusqueda[]>(`${API}/alumnos/buscar`, { params: { q } });
  }

  // GET /api/disponibilidad?mes=YYYY-MM → { "2026-05-12": { libres, total } }
  getDisponibilidad(mes: string): Observable<Record<string, Disponibilidad>> {
    return this.http.get<Record<string, Disponibilidad>>(`${API}/disponibilidad`, { params: { mes } });
  }

  // GET /api/slots?fecha=YYYY-MM-DD
  getSlots(fecha: string): Observable<Slot[]> {
    return this.http.get<Slot[]>(`${API}/slots`, { params: { fecha } });
  }

  // POST /api/citas
  confirmarCita(body: { fecha: string; slot_id: number; motivo: string; alumno_id?: number }): Observable<Cita> {
    return this.http.post<Cita>(`${API}/citas`, body);
  }
}
