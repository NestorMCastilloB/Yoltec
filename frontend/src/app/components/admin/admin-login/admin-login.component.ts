import { Component, OnDestroy } from '@angular/core';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { CommonModule } from '@angular/common';
import { Subject } from 'rxjs';
import { takeUntil, finalize } from 'rxjs/operators';
import { API_BASE_URL } from '../../../services/api-config';

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

  constructor(private fb: FormBuilder, private router: Router, private http: HttpClient) {
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

    this.http.post<{ token: string; user: { tipo: string } }>(`${API_BASE_URL}/login`, body)
      .pipe(
        takeUntil(this.destroy$),
        finalize(() => { this.isLoading = false; })
      )
      .subscribe({
        next: (res) => {
          localStorage.setItem('auth_token', res.token);
          localStorage.setItem('user_data', JSON.stringify(res.user));
          this.router.navigate(['/admin-dashboard']);
        },
        error: (err: HttpErrorResponse) => {
          if (err.status === 401) {
            this.mostrarToast('Credenciales incorrectas');
          } else if (err.status === 403) {
            this.mostrarToast('Sin permisos de administrador');
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
