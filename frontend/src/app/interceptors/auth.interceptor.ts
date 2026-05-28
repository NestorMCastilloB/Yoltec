import { Injectable, inject } from '@angular/core';
import {
  HttpRequest,
  HttpHandler,
  HttpEvent,
  HttpInterceptor,
  HttpErrorResponse
} from '@angular/common/http';
import { Observable, throwError, timer } from 'rxjs';
import { catchError, switchMap, retry } from 'rxjs/operators';
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
      // Retry 1 vez en cold start Render (502/503) o error de red (status 0)
      retry({ count: 1, delay: (err: HttpErrorResponse) =>
        (err.status === 0 || err.status === 502 || err.status === 503)
          ? timer(2000)
          : throwError(() => err)
      }),
      catchError((error: HttpErrorResponse) => {
        if (error.status === 401 && this.router.url !== '/login') {
          // AuthService.logout ya navega — no se requiere router.navigate manual
          this.authService.logout();
        }
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
