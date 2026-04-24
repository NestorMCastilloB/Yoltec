import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { AuthService } from '../../../services/auth.service';

@Component({
  selector: 'app-splash-screen',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './splash-screen.component.html',
  styleUrls: ['./splash-screen.component.css']
})
export class SplashScreenComponent implements OnInit {
  isLoading = true;

  constructor(
    private router: Router,
    private authService: AuthService
  ) {}

  ngOnInit() {
    // Simular carga inicial (2 segundos)
    setTimeout(() => {
      this.checkAuthAndNavigate();
    }, 2000);
  }

  private checkAuthAndNavigate() {
    // Verificar si hay sesión activa
    if (this.authService.isAuthenticated()) {
      const userType = this.authService.getUserType();
      if (userType === 'alumno') {
        this.router.navigate(['/student-dashboard']);
      } else if (userType === 'doctor') {
        this.router.navigate(['/doctor-dashboard']);
      } else {
        this.router.navigate(['/login']);
      }
    } else {
      // No hay sesión, ir a login
      this.router.navigate(['/login']);
    }
  }
}
