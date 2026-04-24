import { Routes } from '@angular/router';
import { SplashScreenComponent } from './components/login/splash-screen/splash-screen.component';
import { LoginComponent } from './components/login/login/login.component';
import { Verify2faComponent } from './components/login/verify-2fa/verify-2fa.component';
import { StudentDashboardComponent } from './components/student/student-dashboard/student-dashboard.component';
import { DoctorDashboardComponent } from './components/doctor/doctor-dashboard/doctor-dashboard.component';
import { AdminDashboardComponent } from './components/admin/admin-dashboard/admin-dashboard.component';
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
  { path: 'forgot-password', component: ForgotPasswordComponent },
  { path: 'reset-password', component: ResetPasswordComponent },
  {
    path: 'admin-dashboard',
    component: AdminDashboardComponent,
    canActivate: [AuthGuard],
    data: { roles: ['admin'] }
  },
  {
    path: '**',
    redirectTo: '/'
  }
];