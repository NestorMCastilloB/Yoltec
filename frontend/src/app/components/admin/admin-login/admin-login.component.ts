import { Component, OnDestroy } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import { AuthService } from '../../../services/auth.service';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { Subject, of } from 'rxjs';

@Component({
  selector: 'app-admin-login',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './admin-login.component.html',
  styleUrls: ['./admin-login.component.css']
})
export class AdminLoginComponent implements OnDestroy {
  private destroy$ = new Subject<void>();

  isLoading = false;
  errorMessage: string | null = null;
  showPassword = false;

  credentials = { identificador: '', password: '' };

  constructor(private router: Router, private authService: AuthService) {}

  togglePassword() {
    this.showPassword = !this.showPassword;
  }

  onSubmit() {
    this.isLoading = true;
    this.errorMessage = null;

    this.authService.login(this.credentials.identificador, this.credentials.password, 'admin')
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => {
          this.errorMessage = 'Credenciales inválidas';
          return of(null);
        }),
        finalize(() => { this.isLoading = false; })
      )
      .subscribe({ next: () => {} });
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
