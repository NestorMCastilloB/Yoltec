import { Component, OnDestroy } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import { AuthService } from '../../../services/auth.service';
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

  showPasswordStudent = false;
  showPasswordDoctor = false;

  studentData = { identificador: '', password: '' };
  doctorData = { identificador: '', password: '' };

  constructor(private router: Router, private authService: AuthService) { }

  togglePassword(role: 'student' | 'doctor') {
    if (role === 'student') this.showPasswordStudent = !this.showPasswordStudent;
    if (role === 'doctor') this.showPasswordDoctor = !this.showPasswordDoctor;
  }

  onStudentLogin() { this.login(this.studentData.identificador, this.studentData.password, 'alumno'); }
  onDoctorLogin() { this.login(this.doctorData.identificador, this.doctorData.password, 'doctor'); }

  private login(identificador: string, password: string, tipoUsuario: 'alumno' | 'doctor' | 'admin') {
    this.isLoading = true;
    this.errorMessage = null;

    this.authService.login(identificador, password, tipoUsuario)
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => {
          this.errorMessage = error.message || 'Error en el inicio de sesión. Verifica tus credenciales.';
          return of(null);
        }),
        finalize(() => { this.isLoading = false; })
      )
      .subscribe({ next: (response) => { if (response) { } } });
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }

  setActiveTab(tab: string) {
    this.activeTab = tab;
    this.errorMessage = null;
  }
}