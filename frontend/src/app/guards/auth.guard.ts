import { Injectable, inject } from '@angular/core';
import { ActivatedRouteSnapshot, CanActivate, Router, RouterStateSnapshot, UrlTree } from '@angular/router';
import { Observable } from 'rxjs';
import { AuthService } from '../services/auth.service';

@Injectable({
  providedIn: 'root',
})
export class AuthGuard implements CanActivate {
  private router = inject(Router);
  private auth = inject(AuthService);

  canActivate(
    route: ActivatedRouteSnapshot,
    state: RouterStateSnapshot,
  ): boolean | UrlTree | Observable<boolean | UrlTree> | Promise<boolean | UrlTree> {
    const token = this.auth.getToken();
    if (!token) {
      return this.router.createUrlTree(['/login'], { queryParams: { returnUrl: state.url } });
    }

    const allowedRoles = route.data['roles'] as Array<string>;
    if (!allowedRoles || allowedRoles.length === 0) {
      return true;
    }

    const user = this.auth.getCurrentUser();
    if (!user) {
      return this.router.createUrlTree(['/login'], { queryParams: { returnUrl: state.url } });
    }

    if (user.tipo && allowedRoles.includes(user.tipo)) {
      return true;
    }

    if (user.tipo === 'alumno') return this.router.createUrlTree(['/student-dashboard']);
    if (user.tipo === 'doctor') return this.router.createUrlTree(['/doctor-dashboard']);
    if (user.tipo === 'admin') return this.router.createUrlTree(['/admin-dashboard']);

    return this.router.createUrlTree(['/login']);
  }
}
