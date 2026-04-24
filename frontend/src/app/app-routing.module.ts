import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { LoginComponent } from './components/login/login/login.component';
import { StudentDashboardComponent } from './components/student/student-dashboard/student-dashboard.component';
import { DoctorDashboardComponent } from './components/doctor/doctor-dashboard/doctor-dashboard.component';
import { SubirDocumentoComponent } from './components/shared/subir-documento/subir-documento.component';
import { PanelValidacionComponent } from './components/shared/panel-validacion/panel-validacion.component';

const routes: Routes = [
  { path: '', redirectTo: '/login', pathMatch: 'full' },
  { path: 'login', component: LoginComponent },
  { path: 'student-dashboard', component: StudentDashboardComponent },
  { path: 'doctor-dashboard', component: DoctorDashboardComponent },
  { path: 'documentos/subir', component: SubirDocumentoComponent },
  { path: 'documentos/validar', component: PanelValidacionComponent },
  { path: '**', redirectTo: '/login' }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }