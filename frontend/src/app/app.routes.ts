import { Routes } from '@angular/router';
import { LoginComponent } from './login/login.component';
import { StudentDashboardComponent } from './student-dashboard/student-dashboard.component';
import { DoctorDashboardComponent } from './doctor-dashboard/doctor-dashboard.component';
import { AuthGuard } from './guards/auth.guard';

export const routes: Routes = [
  { 
    path: '', 
    redirectTo: '/login', 
    pathMatch: 'full' 
  },
  { 
    path: 'login', 
    component: LoginComponent 
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
    path: '**', 
    redirectTo: '/login' 
  }
];