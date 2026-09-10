import { Component, OnDestroy } from '@angular/core';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { CommonModule } from '@angular/common';
import { Subject } from 'rxjs';
import { takeUntil, finalize } from 'rxjs/operators';
import { API_BASE_URL } from '../../../services/api-config';
import { AuthService } from '../../../services/auth.service';

@Component({
  selector: 'app-admin-login',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './admin-login.component.html',
  styleUrls: ['./admin-login.component.css']
})
export class AdminLoginComponent implements OnDestroy {
  private destroy$ = new Subject<void>();

  form: FormGroup;
  showPassword = false;
  isLoading = false;
  toast: string | null = null;
  private toastTimer: ReturnType<typeof setTimeout> | null = null;

  constructor(private fb: FormBuilder, private router: Router, private http: HttpClient, private authService: AuthService) {
    this.form = this.fb.group({
      usuario: ['', Validators.required],
      password: ['', Validators.required]
    });
  }

  togglePassword(): void {
    this.showPassword = !this.showPassword;
  }

  onSubmit(): void {
    if (this.form.invalid || this.isLoading) return;

    this.isLoading = true;
    this.toast = null;

    const body = {
      identificador: this.form.value.usuario,
      password: this.form.value.password,
      tipo_usuario: 'admin'
    };

    this.http.post<{ token?: string; user?: { id: number; nombre: string; apellido: string; email: string; tipo: string }; requires_2fa?: boolean; user_id?: number; email_masked?: string; modo_demostracion?: boolean; codigo_demo?: string }>(`${API_BASE_URL}/login`, body)
      .pipe(
        takeUntil(this.destroy$),
        finalize(() => { this.isLoading = false; })
      )
      .subscribe({
        next: (res) => {
          if (res.requires_2fa && res.user_id) {
            sessionStorage.setItem('pending_2fa', JSON.stringify({
              user_id: res.user_id,
              email_masked: res.email_masked ?? '',
              // En una cuenta de demostración no hay buzón que consultar: el
              // backend devuelve el código para mostrarlo en pantalla.
              modo_demostracion: res.modo_demostracion === true,
              codigo_demo: res.codigo_demo ?? null,
            }));
            this.router.navigate(['/verify-2fa']);
            return;
          }
          if (res.token && res.user) {
            this.authService.setAuthData(res.token, res.user);
            this.router.navigate(['/admin-dashboard']);
          } else {
            this.mostrarToast('Respuesta inesperada del servidor');
          }
        },
        error: (err: HttpErrorResponse) => {
          const backendMsg = (err.error?.message as string | undefined)?.trim();
          if (err.status === 401 || err.status === 422) {
            this.mostrarToast(backendMsg || 'Credenciales incorrectas');
          } else if (err.status === 403) {
            this.mostrarToast(backendMsg || 'Sin permisos de administrador');
          } else if (err.status === 429) {
            this.mostrarToast(backendMsg || 'Demasiados intentos. Espera unos minutos.');
          } else {
            this.mostrarToast('Error al conectar con el servidor');
          }
        }
      });
  }

  private mostrarToast(mensaje: string): void {
    if (this.toastTimer) clearTimeout(this.toastTimer);
    this.toast = mensaje;
    this.toastTimer = setTimeout(() => { this.toast = null; }, 4000);
  }

  ngOnDestroy(): void {
    if (this.toastTimer) clearTimeout(this.toastTimer);
    this.destroy$.next();
    this.destroy$.complete();
  }
}
