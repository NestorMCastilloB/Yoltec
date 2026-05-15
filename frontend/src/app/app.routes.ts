import { Routes } from '@angular/router';
import { SplashScreenComponent } from './components/login/splash-screen/splash-screen.component';
import { LoginComponent } from './components/login/login/login.component';
import { Verify2faComponent } from './components/login/verify-2fa/verify-2fa.component';
import { ForgotPasswordComponent } from './components/login/forgot-password/forgot-password.component';
import { ResetPasswordComponent } from './components/login/reset-password/reset-password.component';
import { AuthGuard } from './guards/auth.guard';

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
  { path: 'forgot-password', component: ForgotPasswordComponent },
  { path: 'reset-password', component: ResetPasswordComponent },
  {
    path: 'student-dashboard',
    loadComponent: () => import('./components/student/student-dashboard/student-dashboard.component').then(m => m.StudentDashboardComponent),
    canActivate: [AuthGuard],
    data: { roles: ['alumno'] }
  },
  {
    path: 'doctor-dashboard',
    loadComponent: () => import('./components/doctor/doctor-dashboard/doctor-dashboard.component').then(m => m.DoctorDashboardComponent),
    canActivate: [AuthGuard],
    data: { roles: ['doctor'] }
  },
  {
    path: 'doctor/nueva-cita',
    loadComponent: () => import('./components/doctor/nueva-cita/nueva-cita-doctor.component').then(m => m.NuevaCitaDoctorComponent),
    canActivate: [AuthGuard],
    data: { roles: ['doctor'] }
  },
  {
    path: 'acceso-gestion',
    loadComponent: () => import('./components/admin/admin-login/admin-login.component').then(m => m.AdminLoginComponent)
  },
  {
    path: 'admin-dashboard',
    loadComponent: () => import('./components/admin/admin-dashboard/admin-dashboard.component').then(m => m.AdminDashboardComponent),
    canActivate: [AuthGuard],
    data: { roles: ['admin'] }
  },
  {
    path: 'admin-usuarios',
    loadComponent: () => import('./components/admin/usuarios/usuarios.component').then(m => m.UsuariosComponent),
    canActivate: [AuthGuard],
    data: { roles: ['admin'] }
  },
  {
    path: 'admin-dias-especiales',
    loadComponent: () => import('./components/admin/dias-especiales/dias-especiales.component').then(m => m.DiasEspecialesComponent),
    canActivate: [AuthGuard],
    data: { roles: ['admin'] }
  },
  {
    path: '**',
    redirectTo: '/'
  }
];