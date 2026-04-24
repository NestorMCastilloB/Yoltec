import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { Subject } from 'rxjs';
import { takeUntil, finalize } from 'rxjs/operators';
import { API_BASE_URL } from '../../../services/api-config';

@Component({
  selector: 'app-reset-password',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './reset-password.component.html',
  styleUrls: ['./reset-password.component.css']
})
export class ResetPasswordComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  token = '';
  password = '';
  passwordConfirmation = '';
  isLoading = false;
  message: string | null = null;
  isError = false;
  done = false;

  constructor(
    private http: HttpClient,
    private route: ActivatedRoute,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.token = this.route.snapshot.queryParamMap.get('token') || '';
    if (!this.token) {
      this.message = 'Enlace inválido. Solicita uno nuevo.';
      this.isError = true;
    }
  }

  onSubmit(): void {
    if (!this.password || this.password !== this.passwordConfirmation) {
      this.message = 'Las contraseñas no coinciden.';
      this.isError = true;
      return;
    }
    this.isLoading = true;
    this.message = null;

    this.http.post<any>(`${API_BASE_URL}/reset-password`, {
      token: this.token,
      password: this.password,
      password_confirmation: this.passwordConfirmation
    }).pipe(takeUntil(this.destroy$), finalize(() => this.isLoading = false))
      .subscribe({
        next: (res) => {
          this.message = res.message;
          this.isError = false;
          this.done = true;
          setTimeout(() => this.router.navigate(['/login']), 3000);
        },
        error: (err) => {
          this.message = err.error?.message || 'No se pudo restablecer la contraseña.';
          this.isError = true;
        }
      });
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
