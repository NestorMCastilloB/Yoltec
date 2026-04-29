import { Injectable, inject } from '@angular/core';
import {
  HttpRequest,
  HttpHandler,
  HttpEvent,
  HttpInterceptor,
  HttpErrorResponse
} from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { Router } from '@angular/router';
import { AuthService } from '../services/auth.service';

@Injectable()
export class AuthInterceptor implements HttpInterceptor {
  private authService = inject(AuthService);
  private router = inject(Router);

  intercept(request: HttpRequest<unknown>, next: HttpHandler): Observable<HttpEvent<unknown>> {
    // Obtener el token del AuthService
    const token = this.authService.getToken();
    
    // Clonar la solicitud y agregar el encabezado de autorización si existe el token
    if (token) {
      request = this.addTokenToRequest(request, token);
    }

    // Manejar la respuesta
    return next.handle(request).pipe(
      catchError((error: HttpErrorResponse) => {
        // Manejar errores de autenticación (401 Unauthorized)
        if (error.status === 401) {
          // Si el token expiró o no es válido, redirigir al login
          if (this.router.url !== '/login') {
            this.authService.logout();
            this.router.navigate(['/login']);
          }
          return throwError(() => error);
        }
        
        // Manejar errores de acceso prohibido (403 Forbidden)
        if (error.status === 403) {
          // Redirigir a una página de acceso denegado o mostrar un mensaje
        }
        
        // Pasar el error al manejador de errores
        return throwError(() => error);
      })
    );
  }

  // Agregar el token a la solicitud
  private addTokenToRequest(request: HttpRequest<unknown>, token: string): HttpRequest<unknown> {
    const headers: Record<string, string> = {
      Authorization: `Bearer ${token}`,
      'Accept': 'application/json'
    };
    // No fijar Content-Type en uploads de archivos (FormData) — el navegador lo pone automáticamente con el boundary
    if (!(request.body instanceof FormData)) {
      headers['Content-Type'] = 'application/json';
    }
    return request.clone({ setHeaders: headers });
  }
}
