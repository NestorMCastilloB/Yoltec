import { Component, OnInit, ViewEncapsulation } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { AuthService } from '../../../services/auth.service';
import { DoctorHeaderComponent } from '../components-doctor/doctor-header/doctor-header.component';
import { DoctorInicioComponent } from '../components-doctor/doctor-inicio/doctor-inicio.component';
import { DoctorCitasComponent } from '../components-doctor/doctor-citas/doctor-citas.component';
import { DoctorBitacorasComponent } from '../components-doctor/doctor-bitacoras/doctor-bitacoras.component';
import { DoctorRecetasComponent } from '../components-doctor/doctor-recetas/doctor-recetas.component';
import { DoctorPreEvaluacionesComponent } from '../components-doctor/doctor-pre-evaluaciones/doctor-pre-evaluaciones.component';
import { DoctorIaPrioridadComponent } from '../components-doctor/doctor-ia-prioridad/doctor-ia-prioridad.component';
import { DoctorEstadisticasComponent } from '../components-doctor/doctor-estadisticas/doctor-estadisticas.component';

@Component({
  selector: 'app-doctor-dashboard',
  standalone: true,
  encapsulation: ViewEncapsulation.None,
  imports: [
    CommonModule,
    DoctorHeaderComponent,
    DoctorInicioComponent,
    DoctorCitasComponent,
    DoctorBitacorasComponent,
    DoctorRecetasComponent,
    DoctorPreEvaluacionesComponent,
    DoctorIaPrioridadComponent,
    DoctorEstadisticasComponent
  ],
  templateUrl: './doctor-dashboard.component.html',
  styleUrls: ['./doctor-dashboard.component.css']
})
export class DoctorDashboardComponent implements OnInit {
  activeSection = 'inicio';
  doctorName = 'Doctor';
  totalPendientes = 0;

  constructor(private router: Router, private authService: AuthService) {}

  ngOnInit(): void {
    const user = this.authService.getCurrentUser();
    this.doctorName = user ? `${user.nombre} ${user.apellido}` : 'Doctor';
  }

  setActiveSection(section: string): void {
    this.activeSection = section;
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/login']);
  }
}
