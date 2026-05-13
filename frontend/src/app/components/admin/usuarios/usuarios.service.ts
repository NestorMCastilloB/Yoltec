import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';

export interface Usuario {
  id: number;
  nombre: string;
  apellido: string;
  email: string;
  rol: 'alumno' | 'doctor';
  suspendido: boolean;
  numero_control?: string;
  username?: string;
  ultima_sesion?: string;
}

export interface UsuariosPaginados {
  data: Usuario[];
  total: number;
  per_page: number;
  current_page: number;
  last_page: number;
  from: number;
  to: number;
}

@Injectable({ providedIn: 'root' })
export class UsuariosService {
  private base = `${environment.apiUrl}/admin`;

  constructor(private http: HttpClient) {}

  private headers(): { headers: HttpHeaders } {
    const token = localStorage.getItem('auth_token');
    return { headers: new HttpHeaders({ Authorization: `Bearer ${token}` }) };
  }

  // GET /api/admin/usuarios — lista paginada con filtros
  getUsuarios(params: { rol?: string; suspendido?: boolean; page?: number; search?: string }): Observable<UsuariosPaginados> {
    let p = new HttpParams();
    if (params.rol) p = p.set('rol', params.rol);
    if (params.suspendido !== undefined) p = p.set('suspendido', String(params.suspendido));
    if (params.page) p = p.set('page', String(params.page));
    if (params.search) p = p.set('search', params.search);
    return this.http.get<UsuariosPaginados>(`${this.base}/usuarios`, { ...this.headers(), params: p });
  }

  // PUT /api/admin/usuarios/{id}/suspender
  suspender(id: number): Observable<any> {
    return this.http.put(`${this.base}/usuarios/${id}/suspender`, {}, this.headers());
  }

  // PUT /api/admin/usuarios/{id}/reactivar
  reactivar(id: number): Observable<any> {
    return this.http.put(`${this.base}/usuarios/${id}/reactivar`, {}, this.headers());
  }

  // POST /api/admin/usuarios
  crearUsuario(payload: any): Observable<any> {
    return this.http.post(`${this.base}/usuarios`, payload, this.headers());
  }

  // PUT /api/admin/usuarios/{id}
  actualizarUsuario(id: number, payload: any): Observable<any> {
    return this.http.put(`${this.base}/usuarios/${id}`, payload, this.headers());
  }
}
