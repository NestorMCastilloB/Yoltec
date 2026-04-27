import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { environment } from '../../environments/environment';

export interface User {
  id: number;
  nombre: string;
  apellido: string;
  email: string;
  tipo: 'alumno' | 'doctor' | 'admin';
  es_admin?: boolean;
  created_at?: string;
  updated_at?: string;
}

@Injectable({
  providedIn: 'root'
})
export class UserService {
  private apiUrl = `${environment.apiUrl}/users`;

  constructor(private http: HttpClient) {}

  private getHeaders(): HttpHeaders {
    const token = localStorage.getItem('token');
    return new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    });
  }

  // Obtener todos los usuarios (solo doctores y admins)
  getUsers(): Observable<User[]> {
    return this.http.get<User[]>(this.apiUrl, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  // Obtener pacientes (alumnos)
  getPacientes(): Observable<User[]> {
    return this.http.get<User[]>(`${this.apiUrl}/pacientes`, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  // Obtener doctores
  getDoctores(): Observable<User[]> {
    return this.http.get<User[]>(`${this.apiUrl}/doctores`, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  // Obtener alumnos (pacientes)
  getAlumnos(): Observable<{alumnos: User[]}> {
    return this.http.get<{alumnos: User[]}>(`${this.apiUrl}/alumnos`, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }
  getUser(id: number): Observable<User> {
    return this.http.get<User>(`${this.apiUrl}/${id}`, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  private handleError(error: any): Observable<never> {
    return throwError(() => error);
  }
}
