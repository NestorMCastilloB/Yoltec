import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { Subject } from 'rxjs';
import { AuthService } from '../../../services/auth.service';
import { CitaService } from '../../../services/cita.service';
import { BitacoraService } from '../../../services/bitacora.service';
import { RecetaService } from '../../../services/receta.service';
import { PreEvaluacionIAService } from '../../../services/pre-evaluacion-ia.service';
import { PerfilMedicoService } from '../../../services/perfil-medico.service';
import { ThemeService } from '../../../services/theme.service';

import { StudentDashboardInicioComponent } from '../dashboard/student-dashboard.component';
import { MisCitasComponent } from '../mis-citas/mis-citas.component';
import { SdBitacoraComponent } from './components/sd-bitacora/sd-bitacora.component';
import { SdRecetasComponent } from './components/sd-recetas/sd-recetas.component';
import { SdPerfilComponent } from './components/sd-perfil/sd-perfil.component';
import { SdHistorialComponent } from './components/sd-historial/sd-historial.component';
import { PreEvaluacionIaComponent } from '../pre-evaluacion-ia/pre-evaluacion-ia.component';

@Component({
  selector: 'app-student-dashboard',
  standalone: true,
  imports: [
    CommonModule,
    StudentDashboardInicioComponent,
    MisCitasComponent,
    SdBitacoraComponent,
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
    // Servicios inyectados para pasarlos a hijos vía DI automática
    private citaService: CitaService,
    private bitacoraService: BitacoraService,
    private recetaService: RecetaService,
    private preEvaluacionIAService: PreEvaluacionIAService,
    private perfilMedicoService: PerfilMedicoService,
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
