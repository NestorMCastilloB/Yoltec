import { Component, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { Subject } from 'rxjs';
import { takeUntil, finalize } from 'rxjs/operators';
import { API_BASE_URL } from '../../../services/api-config';

@Component({
  selector: 'app-forgot-password',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './forgot-password.component.html',
  styleUrls: ['./forgot-password.component.css']
})
export class ForgotPasswordComponent implements OnDestroy {
  private destroy$ = new Subject<void>();
  email = '';
  isLoading = false;
  message: string | null = null;
  isError = false;
  sent = false;

  constructor(private http: HttpClient, private router: Router) {}

  onSubmit(): void {
    if (!this.email.trim()) return;
    this.isLoading = true;
    this.message = null;

    this.http.post<any>(`${API_BASE_URL}/forgot-password`, { email: this.email })
      .pipe(takeUntil(this.destroy$), finalize(() => this.isLoading = false))
      .subscribe({
        next: (res) => {
          this.message = res.message;
          this.isError = false;
          this.sent = true;
        },
        error: (err) => {
          this.message = err.error?.message || 'No se pudo procesar la solicitud.';
          this.isError = true;
        }
      });
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
