import { Component, OnDestroy } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import { AuthService } from '../services/auth.service';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { Subject, of } from 'rxjs';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css']
})
export class LoginComponent implements OnDestroy {
  private destroy$ = new Subject<void>();
  
  activeTab: string = 'student';
  isLoading = false;
  errorMessage: string | null = null;
  recordarPor: number = 1440;

  readonly duracionOpciones = [
    { valor: 1440,  etiqueta: '1 día' },
    { valor: 2880,  etiqueta: '2 días' },
    { valor: 7200,  etiqueta: '5 días' },
    { valor: 10080, etiqueta: '1 semana' },
    { valor: 20160, etiqueta: '2 semanas' },
    { valor: 43200, etiqueta: '1 mes' },
  ];

  studentData = {
    identificador: '',
    password: ''
  };

  doctorData = {
    identificador: '',
    password: ''
  };

  adminData = {
    identificador: '',
    password: ''
  };

  constructor(
    private router: Router,
    private authService: AuthService
  ) {}

  onStudentLogin() {
    this.login(this.studentData.identificador, this.studentData.password, 'alumno');
  }

  onDoctorLogin() {
    this.login(this.doctorData.identificador, this.doctorData.password, 'doctor');
  }

  onAdminLogin() {
    this.login(this.adminData.identificador, this.adminData.password, 'admin');
  }

  private login(identificador: string, password: string, tipoUsuario: 'alumno' | 'doctor' | 'admin') {
    this.isLoading = true;
    this.errorMessage = null;

    this.authService.login(identificador, password, tipoUsuario, this.recordarPor)
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => {
          this.errorMessage = error.message || 'Error en el inicio de sesión. Verifica tus credenciales.';
          return of(null);
        }),
        finalize(() => {
          this.isLoading = false;
        })
      )
      .subscribe({
        next: (response) => {
          if (response) {
            // La redirección se maneja en el servicio de autenticación
          }
        }
      });
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }

  setActiveTab(tab: string) {
    this.activeTab = tab;
  }
}