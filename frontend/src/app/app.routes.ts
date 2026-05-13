import { Routes } from '@angular/router';
import { SplashScreenComponent } from './components/login/splash-screen/splash-screen.component';
import { LoginComponent } from './components/login/login/login.component';
import { Verify2faComponent } from './components/login/verify-2fa/verify-2fa.component';
import { StudentDashboardComponent } from './components/student/student-dashboard/student-dashboard.component';
import { DoctorDashboardComponent } from './components/doctor/doctor-dashboard/doctor-dashboard.component';
import { AdminDashboardComponent } from './components/admin/admin-dashboard/admin-dashboard.component';
import { AdminLoginComponent } from './components/admin/admin-login/admin-login.component';
import { UsuariosComponent } from './components/admin/usuarios/usuarios.component';
import { DiasEspecialesComponent } from './components/admin/dias-especiales/dias-especiales.component';
import { ForgotPasswordComponent } from './components/login/forgot-password/forgot-password.component';
import { ResetPasswordComponent } from './components/login/reset-password/reset-password.component';
import { AuthGuard } from './guards/auth.guard';
import { NuevaCitaDoctorComponent } from './components/doctor/nueva-cita/nueva-cita-doctor.component';

export const routes: Routes = [
  { 
    path: '', 
    component: SplashScreenComponent,
    pathMatch: 'full'
  },
  {
    path: 'login',
    component: LoginComponent
  },
  {
    path: 'verify-2fa',
    component: Verify2faComponent
  },
  { 
    path: 'student-dashboard', 
    component: StudentDashboardComponent,
    canActivate: [AuthGuard],
    data: { roles: ['alumno'] }
  },
  {
    path: 'doctor-dashboard',
    component: DoctorDashboardComponent,
    canActivate: [AuthGuard],
    data: { roles: ['doctor'] }
  },
  {
    path: 'doctor/nueva-cita',
    component: NuevaCitaDoctorComponent,
    canActivate: [AuthGuard],
    data: { roles: ['doctor'] }
  },
  { path: 'forgot-password', component: ForgotPasswordComponent },
  { path: 'reset-password', component: ResetPasswordComponent },
  {
    path: 'acceso-gestion',
    component: AdminLoginComponent
  },
  {
    path: 'admin-dashboard',
    component: AdminDashboardComponent,
    canActivate: [AuthGuard],
    data: { roles: ['admin'] }
  },
  {
    path: 'admin-usuarios',
    component: UsuariosComponent,
    canActivate: [AuthGuard],
    data: { roles: ['admin'] }
  },
  {
    path: 'admin-dias-especiales',
    component: DiasEspecialesComponent,
    canActivate: [AuthGuard],
    data: { roles: ['admin'] }
  },
  {
    path: '**',
    redirectTo: '/'
  }
];