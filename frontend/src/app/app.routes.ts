import { Routes } from '@angular/router';
import { SplashScreenComponent } from './splash-screen/splash-screen.component';
import { LoginComponent } from './login/login.component';
import { Verify2faComponent } from './verify-2fa/verify-2fa.component';
import { StudentDashboardComponent } from './student-dashboard/student-dashboard.component';
import { DoctorDashboardComponent } from './doctor-dashboard/doctor-dashboard.component';
import { AdminDashboardComponent } from './admin-dashboard/admin-dashboard.component';
import { ForgotPasswordComponent } from './forgot-password/forgot-password.component';
import { ResetPasswordComponent } from './reset-password/reset-password.component';
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