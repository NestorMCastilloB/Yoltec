import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { API_BASE_URL } from './api-config';

export interface Alumno {
  id: number;
  numero_control: string;
  nombre: string;
  apellido: string;
  email: string;
  telefono?: string | null;
  fecha_nacimiento?: string | null;
  created_at: string;
}

export interface Doctor {
  id: number;
  username: string;
  nombre: string;
  apellido: string;
  email: string;
  telefono?: string | null;
  created_at: string;
}

@Injectable({ providedIn: 'root' })
export class AdminService {
  private base = `${API_BASE_URL}/admin`;

  constructor(private http: HttpClient) {}

  getAlumnos(): Observable<Alumno[]> {
    return this.http.get<{ alumnos: Alumno[] }>(`${this.base}/alumnos`).pipe(map(r => r.alumnos));
  }

  createAlumno(data: any): Observable<any> {
    return this.http.post(`${this.base}/alumnos`, data);
  }

  updateAlumno(id: number, data: any): Observable<any> {
    return this.http.put(`${this.base}/alumnos/${id}`, data);
  }

  deleteAlumno(id: number): Observable<any> {
    return this.http.delete(`${this.base}/alumnos/${id}`);
  }

  getDoctores(): Observable<Doctor[]> {
    return this.http.get<{ doctores: Doctor[] }>(`${this.base}/doctores`).pipe(map(r => r.doctores));
  }

  createDoctor(data: any): Observable<any> {
    return this.http.post(`${this.base}/doctores`, data);
  }

  updateDoctor(id: number, data: any): Observable<any> {
    return this.http.put(`${this.base}/doctores/${id}`, data);
  }

  deleteDoctor(id: number): Observable<any> {
    return this.http.delete(`${this.base}/doctores/${id}`);
  }
}
