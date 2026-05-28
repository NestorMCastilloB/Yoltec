import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
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

  // AuthInterceptor agrega Bearer a todas las peticiones — no se requieren headers manuales.
  getUsuarios(params: { rol?: string; suspendido?: boolean; page?: number; search?: string }): Observable<UsuariosPaginados> {
    let p = new HttpParams();
    if (params.rol) p = p.set('rol', params.rol);
    if (params.suspendido !== undefined) p = p.set('suspendido', String(params.suspendido));
    if (params.page) p = p.set('page', String(params.page));
    if (params.search) p = p.set('search', params.search);
    return this.http.get<UsuariosPaginados>(`${this.base}/usuarios`, { params: p });
  }

  suspender(id: number): Observable<any> {
    return this.http.put(`${this.base}/usuarios/${id}/suspender`, {});
  }

  reactivar(id: number): Observable<any> {
    return this.http.put(`${this.base}/usuarios/${id}/reactivar`, {});
  }

  crearUsuario(payload: any): Observable<any> {
    return this.http.post(`${this.base}/usuarios`, payload);
  }

  actualizarUsuario(id: number, payload: any): Observable<any> {
    return this.http.put(`${this.base}/usuarios/${id}`, payload);
  }
}
