import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_BASE_URL } from './api-config';

export interface PerfilMedico {
  id: number;
  nombre: string;
  apellido: string;
  numero_control: string;
  email: string;
  telefono: string | null;
  fecha_nacimiento: string | null;
  tipo_sangre: string | null;
  alergias: string | null;
  enfermedades_cronicas: string | null;
  foto_perfil: string | null;
}

export interface ConsultaHistorial {
  id: number;
  clave_cita: string;
  fecha_cita: string;
  hora_cita: string;
  motivo: string;
  doctor: { nombre: string; apellido: string } | null;
  consulta: { diagnostico: string; tratamiento: string; observaciones: string | null } | null;
  receta: { medicamento: string; dosis: string; indicaciones: string } | null;
}

@Injectable({ providedIn: 'root' })
export class PerfilMedicoService {
  constructor(private http: HttpClient) {}

  getPerfil(): Observable<{ perfil: PerfilMedico }> {
    return this.http.get<{ perfil: PerfilMedico }>(`${API_BASE_URL}/perfil-medico`);
  }

  updatePerfil(data: Partial<PerfilMedico>): Observable<any> {
    return this.http.put(`${API_BASE_URL}/perfil-medico`, data);
  }

  getHistorial(): Observable<{ historial: ConsultaHistorial[]; total: number }> {
    return this.http.get<{ historial: ConsultaHistorial[]; total: number }>(`${API_BASE_URL}/perfil-medico/historial`);
  }

  getPerfilAlumno(alumnoId: number): Observable<{ perfil: PerfilMedico }> {
    return this.http.get<{ perfil: PerfilMedico }>(`${API_BASE_URL}/perfil-medico/alumno/${alumnoId}`);
  }

  getHistorialAlumno(alumnoId: number): Observable<{ historial: ConsultaHistorial[]; total: number }> {
    return this.http.get<{ historial: ConsultaHistorial[]; total: number }>(`${API_BASE_URL}/perfil-medico/alumno/${alumnoId}/historial`);
  }

  subirFoto(file: File): Observable<{ message: string; foto_url: string }> {
    const fd = new FormData();
    fd.append('foto', file);
    return this.http.post<{ message: string; foto_url: string }>(`${API_BASE_URL}/perfil/foto`, fd);
  }

  getPropioPerfil(): Observable<{ perfil: any }> {
    return this.http.get<{ perfil: any }>(`${API_BASE_URL}/perfil`);
  }

  updateDatosPersonales(data: { nombre?: string; apellido?: string; email?: string; telefono?: string; fecha_nacimiento?: string }): Observable<any> {
    return this.http.put(`${API_BASE_URL}/perfil`, data);
  }

  cambiarPassword(data: { password_actual: string; password_nuevo: string; password_nuevo_confirmation: string }): Observable<any> {
    return this.http.post(`${API_BASE_URL}/perfil/cambiar-password`, data);
  }
}
