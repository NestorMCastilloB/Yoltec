import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';

export interface AdminStats {
  total_usuarios: number;
  total_alumnos: number;
  total_doctores: number;
  citas_hoy: number;
  citas_completadas_hoy: number;
  citas_pendientes_hoy: number;
  alumnos_activos: number;
  ultimo_acceso_hora: string;
  ultimo_acceso_email: string;
}

@Injectable({ providedIn: 'root' })
export class AdminDashboardService {
  private base = environment.apiUrl;

  constructor(private http: HttpClient) {}

  // GET /api/admin/stats — métricas generales del sistema
  getStats(): Observable<AdminStats> {
    const token = localStorage.getItem('auth_token');
    const headers = new HttpHeaders({ Authorization: `Bearer ${token}` });
    return this.http.get<AdminStats>(`${this.base}/admin/stats`, { headers });
  }
}
