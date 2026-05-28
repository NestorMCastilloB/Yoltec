import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { Subject } from 'rxjs';
import { takeUntil, finalize } from 'rxjs/operators';
import { API_BASE_URL } from '../../../services/api-config';
import { AuthService } from '../../../services/auth.service';

@Component({
  selector: 'app-verify-2fa',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './verify-2fa.component.html',
  styleUrls: ['./verify-2fa.component.css']
})
export class Verify2faComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  // Bloqueo local tras varios fallos: complementa el rate limit del backend
  // para que el usuario no siga golpeando endpoints inútilmente.
  private static readonly MAX_ATTEMPTS = 5;
  private static readonly LOCKOUT_MINUTES = 15;
  private static readonly ATTEMPTS_KEY_PREFIX = '2fa_attempts_';
  private static readonly LOCKOUT_KEY_PREFIX = '2fa_lockout_';

  code = '';
  isLoading = false;
  isResending = false;
  errorMessage: string | null = null;
  successMessage: string | null = null;
  isLocked = false;
  minutesRemaining = 0;
  attemptsRemaining: number | null = null;

  userId: number | null = null;
  emailMasked = '';

  constructor(private http: HttpClient, private router: Router, private authService: AuthService) {}

  ngOnInit() {
    const pending = sessionStorage.getItem('pending_2fa');
    if (!pending) {
      this.router.navigate(['/login']);
      return;
    }
    const data = JSON.parse(pending);
    this.userId = data.user_id;
    this.emailMasked = data.email_masked;
    this.checkLockout();
  }

  onSubmit() {
    if (this.checkLockout()) return;
    if (!this.code || !/^\d{6}$/.test(this.code)) {
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
        this.clearAttempts();
        // Guardar device_token para los próximos 30 días
        if (response.device_token) {
          localStorage.setItem(`${response.tipo}_device_token`, response.device_token);
        }
        this.authService.setAuthData(response.token, response.user);
        sessionStorage.removeItem('pending_2fa');

        // Redirigir según rol
        if (response.tipo === 'admin') {
          this.router.navigate(['/admin-dashboard']);
        } else if (response.tipo === 'doctor') {
          this.router.navigate(['/doctor-dashboard']);
        } else {
          this.router.navigate(['/student-dashboard']);
        }
      },
      error: (err) => {
        this.registerFailedAttempt(err.error?.message || 'Código inválido o expirado.');
        this.code = '';
      }
    });
  }

  // Marca un intento fallido; al llegar al límite bloquea el formulario por LOCKOUT_MINUTES.
  private registerFailedAttempt(serverMessage: string): void {
    if (!this.userId) {
      this.errorMessage = serverMessage;
      return;
    }
    const key = Verify2faComponent.ATTEMPTS_KEY_PREFIX + this.userId;
    const attempts = parseInt(localStorage.getItem(key) || '0', 10) + 1;
    localStorage.setItem(key, attempts.toString());

    const remaining = Verify2faComponent.MAX_ATTEMPTS - attempts;
    if (remaining <= 0) {
      const lockoutUntil = Date.now() + Verify2faComponent.LOCKOUT_MINUTES * 60_000;
      localStorage.setItem(Verify2faComponent.LOCKOUT_KEY_PREFIX + this.userId, lockoutUntil.toString());
      localStorage.removeItem(key);
      this.checkLockout();
      return;
    }
    this.attemptsRemaining = remaining;
    this.errorMessage = `${serverMessage} (te quedan ${remaining} intento${remaining === 1 ? '' : 's'})`;
  }

  // Devuelve true si hay bloqueo vigente; actualiza el mensaje y deshabilita el form.
  private checkLockout(): boolean {
    if (!this.userId) return false;
    const lockoutKey = Verify2faComponent.LOCKOUT_KEY_PREFIX + this.userId;
    const lockoutUntil = parseInt(localStorage.getItem(lockoutKey) || '0', 10);
    if (lockoutUntil <= Date.now()) {
      if (lockoutUntil > 0) localStorage.removeItem(lockoutKey);
      this.isLocked = false;
      return false;
    }
    this.isLocked = true;
    this.minutesRemaining = Math.max(1, Math.ceil((lockoutUntil - Date.now()) / 60_000));
    this.errorMessage = `Demasiados intentos fallidos. Vuelve a intentar en ${this.minutesRemaining} minuto(s).`;
    return true;
  }

  private clearAttempts(): void {
    if (!this.userId) return;
    localStorage.removeItem(Verify2faComponent.ATTEMPTS_KEY_PREFIX + this.userId);
    localStorage.removeItem(Verify2faComponent.LOCKOUT_KEY_PREFIX + this.userId);
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
