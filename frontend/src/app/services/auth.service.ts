import { Injectable } from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { BehaviorSubject, Observable, throwError } from 'rxjs';
import { tap, catchError } from 'rxjs/operators';
import { Router } from '@angular/router';
import { API_BASE_URL } from './api-config';

interface User {
  id: number;
  nombre: string;
  apellido: string;
  email: string;
  tipo: string;
  numero_control?: string;
  username?: string;
}

interface LoginResponse {
  message: string;
  user: User;
  token: string;
  tipo: string;
}

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private apiUrl = API_BASE_URL;
  private tokenKey = 'auth_token';
  private userKey = 'user_data';
  private userSubject = new BehaviorSubject<User | null>(null);
  private isAuthenticatedSubject = new BehaviorSubject<boolean>(false);

  // Exponer observables
  public currentUser$ = this.userSubject.asObservable();
  public isAuthenticated$ = this.isAuthenticatedSubject.asObservable();

  constructor(private http: HttpClient, private router: Router) {
    // Cargar datos del usuario al iniciar
    const user = this.getStoredUser();
    if (user) {
      this.userSubject.next(user);
      this.isAuthenticatedSubject.next(true);
    }
  }

  login(identificador: string, password: string, expectedRole?: string): Observable<LoginResponse> {
    return this.http.post<LoginResponse>(`${this.apiUrl}/login`, { identificador, password })
      .pipe(
        tap(response => {
          if (response && response.token) {
            // Si se indicó un rol esperado (alumno/doctor) y no coincide, lanzar error
            if (expectedRole && response.user?.tipo !== expectedRole) {
              throw new Error('Las credenciales corresponden a un usuario de tipo ' + response.user.tipo + '. Verifica que estés usando la pestaña correcta.');
            }

            // Guardar token y datos del usuario
            this.setToken(response.token);
            this.setUser(response.user);
            
            // Actualizar estado de autenticación
            this.isAuthenticatedSubject.next(true);
            this.userSubject.next(response.user);
            
            // Redirigir según el tipo de usuario
            this.redirectUser(response.user.tipo);
          }
        }),
        catchError(error => this.handleError(error))
      );
  }
  
  // Método privado para manejar errores
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

    console.error('Error HTTP:', error);
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

  logout(): void {
    // Realizar la petición de cierre de sesión
    this.http.post(`${this.apiUrl}/logout`, {}).subscribe({
      next: () => {
        this.clearAuthData();
        this.router.navigate(['/login']);
      },
      error: (error) => {
        console.error('Error al cerrar sesión:', error);
        // Asegurarse de limpiar los datos de autenticación incluso si hay un error
        this.clearAuthData();
        this.router.navigate(['/login']);
      }
    });
  }
  
  // Limpiar todos los datos de autenticación
  private clearAuthData(): void {
    localStorage.removeItem(this.tokenKey);
    localStorage.removeItem(this.userKey);
    this.isAuthenticatedSubject.next(false);
    this.userSubject.next(null);
  }

  // Obtener el estado de autenticación actual
  isAuthenticated(): boolean {
    return this.isAuthenticatedSubject.value;
  }

  // Obtener el token del almacenamiento local
  getToken(): string | null {
    return localStorage.getItem(this.tokenKey);
  }
  
  // Obtener la información del usuario actual
  getCurrentUser(): any {
    const userJson = localStorage.getItem(this.userKey);
    return userJson ? JSON.parse(userJson) : null;
  }
  
  // Verificar si el usuario actual tiene un rol específico
  hasRole(role: string): boolean {
    const user = this.getCurrentUser();
    return !!user && user.tipo === role;
  }

  // Guardar el token en el almacenamiento local
  private setToken(token: string): void {
    localStorage.setItem(this.tokenKey, token);
  }
  
  // Guardar la información del usuario en el almacenamiento local
  private setUser(user: User): void {
    localStorage.setItem(this.userKey, JSON.stringify(user));
  }
  
  // Obtener el usuario almacenado en el almacenamiento local
  private getStoredUser(): User | null {
    const userJson = localStorage.getItem(this.userKey);
    return userJson ? JSON.parse(userJson) : null;
  }
  
  // Redirigir al usuario según su tipo
  private redirectUser(userType: string): void {
    switch (userType) {
      case 'alumno':
        this.router.navigate(['/student-dashboard']);
        break;
      case 'doctor':
        this.router.navigate(['/doctor-dashboard']);
        break;
      default:
        this.router.navigate(['/login']);
    }
  }
}
