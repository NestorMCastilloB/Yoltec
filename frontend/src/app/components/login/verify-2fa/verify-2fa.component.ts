import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { Subject } from 'rxjs';
import { takeUntil, finalize } from 'rxjs/operators';
import { API_BASE_URL } from '../../../services/api-config';

@Component({
  selector: 'app-verify-2fa',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './verify-2fa.component.html',
  styleUrls: ['./verify-2fa.component.css']
})
export class Verify2faComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  code = '';
  isLoading = false;
  isResending = false;
  errorMessage: string | null = null;
  successMessage: string | null = null;

  userId: number | null = null;
  emailMasked = '';

  constructor(private http: HttpClient, private router: Router) {}

  ngOnInit() {
    const pending = sessionStorage.getItem('pending_2fa');
    if (!pending) {
      this.router.navigate(['/login']);
      return;
    }
    const data = JSON.parse(pending);
    this.userId = data.user_id;
    this.emailMasked = data.email_masked;
  }

  onSubmit() {
    if (!this.code || this.code.length !== 6) {
      this.errorMessage = 'Ingresa el código de 6 dígitos.';
      return;
    }

    this.isLoading = true;
    this.errorMessage = null;

    this.http.post<any>(`${API_BASE_URL}/verify-2fa`, {
      user_id: this.userId,
      code: this.code
    }).pipe(
      takeUntil(this.destroy$),
      finalize(() => this.isLoading = false)
    ).subscribe({
      next: (response) => {
        // Guardar device_token para los próximos 30 días
        if (response.device_token) {
          localStorage.setItem('doctor_device_token', response.device_token);
        }
        // Guardar token y usuario
        localStorage.setItem('auth_token', response.token);
        localStorage.setItem('user_data', JSON.stringify(response.user));
        sessionStorage.removeItem('pending_2fa');

        // Redirigir
        if (response.tipo === 'doctor') {
          this.router.navigate(['/doctor-dashboard']);
        } else {
          this.router.navigate(['/student-dashboard']);
        }
      },
      error: (err) => {
        this.errorMessage = err.error?.message || 'Código inválido o expirado.';
        this.code = '';
      }
    });
  }

  onResend() {
    this.isResending = true;
    this.errorMessage = null;
    this.successMessage = null;

    this.http.post<any>(`${API_BASE_URL}/resend-2fa`, { user_id: this.userId })
      .pipe(takeUntil(this.destroy$), finalize(() => this.isResending = false))
      .subscribe({
        next: () => this.successMessage = 'Nuevo código enviado a tu correo.',
        error: (err) => this.errorMessage = err.error?.message || 'No se pudo reenviar el código.'
      });
  }

  goBack() {
    sessionStorage.removeItem('pending_2fa');
    this.router.navigate(['/login']);
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
