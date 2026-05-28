import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
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

  // AuthInterceptor agrega Bearer + Content-Type automaticamente.
  getUsers(): Observable<User[]> {
    return this.http.get<User[]>(this.apiUrl).pipe(catchError(this.handleError));
  }

  getPacientes(): Observable<User[]> {
    return this.http.get<User[]>(`${this.apiUrl}/pacientes`).pipe(catchError(this.handleError));
  }

  getDoctores(): Observable<User[]> {
    return this.http.get<User[]>(`${this.apiUrl}/doctores`).pipe(catchError(this.handleError));
  }

  getAlumnos(): Observable<{alumnos: User[]}> {
    return this.http.get<{alumnos: User[]}>(`${this.apiUrl}/alumnos`).pipe(catchError(this.handleError));
  }

  getUser(id: number): Observable<User> {
    return this.http.get<User>(`${this.apiUrl}/${id}`).pipe(catchError(this.handleError));
  }

  private handleError(error: any): Observable<never> {
    return throwError(() => error);
  }
}
