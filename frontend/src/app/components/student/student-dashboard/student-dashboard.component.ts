import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { Subject } from 'rxjs';
import { AuthService } from '../../../services/auth.service';
import { ThemeService } from '../../../services/theme.service';

import { SdInicioComponent } from './components/sd-inicio/sd-inicio.component';
import { MisCitasComponent } from '../mis-citas/mis-citas.component';
import { SdRecetasComponent } from './components/sd-recetas/sd-recetas.component';
import { SdPerfilComponent } from './components/sd-perfil/sd-perfil.component';
import { SdHistorialComponent } from './components/sd-historial/sd-historial.component';
import { PreEvaluacionIaComponent } from '../pre-evaluacion-ia/pre-evaluacion-ia.component';

@Component({
  selector: 'app-student-dashboard',
  standalone: true,
  imports: [
    CommonModule,
    SdInicioComponent,
    MisCitasComponent,
    SdRecetasComponent,
    SdPerfilComponent,
    SdHistorialComponent,
    PreEvaluacionIaComponent,
  ],
  templateUrl: './student-dashboard.component.html',
  styleUrls: ['./student-dashboard.component.css']
})
export class StudentDashboardComponent implements OnInit, OnDestroy {
  activeSection = 'inicio';
  studentName = '';

  private destroy$ = new Subject<void>();

  constructor(
    private router: Router,
    private authService: AuthService,
    public themeService: ThemeService,
  ) {}

  ngOnInit(): void {
    const user = this.authService.getCurrentUser();
    this.studentName = user ? `${user.nombre} ${user.apellido}` : 'Alumno';
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  setActiveSection(section: string): void {
    this.activeSection = section;
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/login']);
  }
}
