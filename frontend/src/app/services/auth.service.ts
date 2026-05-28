import { Injectable, OnDestroy } from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { BehaviorSubject, Observable, throwError } from 'rxjs';
import { tap, catchError } from 'rxjs/operators';
import { Router } from '@angular/router';
import { API_BASE_URL } from './api-config';
import { IdleService } from './idle.service';

interface User {
  id: number;
  nombre: string;
  apellido: string;
  email: string;
  tipo: string;
  numero_control?: string;
  username?: string;
  genero?: 'masculino' | 'femenino' | 'otro' | null;
}

interface LoginResponse {
  message: string;
  user: User;
  token: string;
  tipo: string;
}

@Injectable({
  providedIn: 'root',
})
export class AuthService implements OnDestroy {
  private apiUrl = API_BASE_URL;
  private tokenKey = 'auth_token';
  private userKey = 'user_data';
  private userSubject = new BehaviorSubject<User | null>(null);
  private isAuthenticatedSubject = new BehaviorSubject<boolean>(false);

  public currentUser$ = this.userSubject.asObservable();
  public isAuthenticated$ = this.isAuthenticatedSubject.asObservable();
  public idleWarning$: Observable<number>;

  constructor(private http: HttpClient, private router: Router, private idle: IdleService) {
    this.idleWarning$ = this.idle.warning$;
    const user = this.getStoredUser();
    if (user) {
      if (this.idle.isExpired()) {
        this.clearAuthData();
      } else {
        this.userSubject.next(user);
        this.isAuthenticatedSubject.next(true);
        this.idle.start(() => this.logout());
      }
    }
  }

  ngOnDestroy(): void {
    this.idle.stop();
  }

  // Llamado desde el modal de aviso para extender la sesión sin esperar otra actividad real.
  extendSession(): void {
    this.idle.extend();
  }

  login(identificador: string, password: string, tipoUsuario: 'alumno' | 'doctor' | 'admin'): Observable<LoginResponse> {
    const body: any = { identificador, password, tipo_usuario: tipoUsuario };
    if (tipoUsuario === 'doctor' || tipoUsuario === 'admin') {
      const deviceToken = localStorage.getItem(`${tipoUsuario}_device_token`);
      if (deviceToken) body.device_token = deviceToken;
    }
    return this.http.post<LoginResponse>(`${this.apiUrl}/login`, body)
      .pipe(
        tap((response: any) => {
          if (response && response.token) {
            this.setToken(response.token);
            this.setUser(response.user);
            this.isAuthenticatedSubject.next(true);
            this.userSubject.next(response.user);
            this.idle.start(() => this.logout());
            this.redirectUser(response.user.tipo);
          } else if (response && response.requires_2fa) {
            sessionStorage.setItem('pending_2fa', JSON.stringify({
              user_id: response.user_id,
              email_masked: response.email_masked,
            }));
            this.router.navigate(['/verify-2fa']);
          }
        }),
        catchError(error => this.handleError(error))
      );
  }

  private handleError(error: HttpErrorResponse) {
    let errorMessage = 'Ocurrió un error al procesar la solicitud.';

    if (error.status === 0) {
      errorMessage = 'No se pudo conectar con el servidor. Verifica tu conexión e intenta nuevamente.';
    } else if (error.status === 401) {
      errorMessage = 'Tu sesión ha expirado. Inicia sesión de nuevo.';
    } else if (error.status === 422) {
      const backendMessage = this.extractValidationMessage(error);
      errorMessage = backendMessage ?? 'Hay datos inválidos. Revisa la información ingresada.';
    } else if (error.status >= 500) {
      errorMessage = 'El servidor presentó un problema. Intenta más tarde.';
    } else if (typeof error.error === 'string') {
      errorMessage = error.error;
    } else if (typeof error.message === 'string' && error.message.trim() !== '') {
      errorMessage = error.message;
    }

    return throwError(() => new Error(errorMessage));
  }

  private extractValidationMessage(error: HttpErrorResponse): string | null {
    const errores = error?.error?.errors;
    if (errores && typeof errores === 'object') {
      const firstKey = Object.keys(errores)[0];
      const mensajes = errores[firstKey];
      if (Array.isArray(mensajes) && mensajes.length > 0) {
        return mensajes[0];
      }
    }

    if (typeof error?.error?.message === 'string') {
      return error.error.message;
    }

    return null;
  }

  // redirectTo permite que admin vaya a /acceso-gestion en lugar de /login
  logout(redirectTo: string = '/login'): void {
    this.http.post(`${this.apiUrl}/logout`, {}).subscribe({
      next: () => {
        this.clearAuthData();
        this.router.navigate([redirectTo]);
      },
      error: () => {
        this.clearAuthData();
        this.router.navigate([redirectTo]);
      },
    });
  }

  private clearAuthData(): void {
    this.idle.stop();
    localStorage.removeItem(this.tokenKey);
    localStorage.removeItem(this.userKey);
    this.isAuthenticatedSubject.next(false);
    this.userSubject.next(null);
  }

  isAuthenticated(): boolean {
    return this.isAuthenticatedSubject.value;
  }

  getToken(): string | null {
    return localStorage.getItem(this.tokenKey);
  }

  getCurrentUser(): any {
    const userJson = localStorage.getItem(this.userKey);
    return userJson ? JSON.parse(userJson) : null;
  }

  // Llamado desde flujos especiales (admin-login, verify-2fa) que ya hicieron auth fuera
  // del flujo normal login() y solo necesitan persistir + activar idle tracking.
  setAuthData(token: string, user: User): void {
    this.setToken(token);
    this.setUser(user);
    this.isAuthenticatedSubject.next(true);
    this.userSubject.next(user);
    this.idle.start(() => this.logout());
  }

  hasRole(role: string): boolean {
    const user = this.getCurrentUser();
    return !!user && user.tipo === role;
  }

  getUserType(): string | null {
    const user = this.getCurrentUser();
    return user ? user.tipo : null;
  }

  private setToken(token: string): void {
    localStorage.setItem(this.tokenKey, token);
  }

  private setUser(user: User): void {
    localStorage.setItem(this.userKey, JSON.stringify(user));
  }

  // Actualizar campos del user en localStorage y emitir cambio (sin re-login)
  updateCurrentUser(partial: Partial<User>): void {
    const current = this.getCurrentUser();
    if (!current) return;
    const updated = { ...current, ...partial };
    this.setUser(updated);
    this.userSubject.next(updated);
  }

  private getStoredUser(): User | null {
    const userJson = localStorage.getItem(this.userKey);
    if (!userJson) return null;
    try {
      return JSON.parse(userJson);
    } catch {
      localStorage.removeItem(this.userKey);
      return null;
    }
  }

  private redirectUser(userType: string): void {
    switch (userType) {
      case 'alumno':
        this.router.navigate(['/student-dashboard']);
        break;
      case 'doctor':
        this.router.navigate(['/doctor-dashboard']);
        break;
      case 'admin':
        this.router.navigate(['/admin-dashboard']);
        break;
      default:
        this.router.navigate(['/login']);
    }
  }
}
