import { Injectable } from '@angular/core';
import { ActivatedRouteSnapshot, CanActivate, Router, RouterStateSnapshot, UrlTree } from '@angular/router';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class AuthGuard implements CanActivate {
  constructor(private router: Router) {}

  canActivate(
    route: ActivatedRouteSnapshot,
    state: RouterStateSnapshot
  ): boolean | UrlTree | Observable<boolean | UrlTree> | Promise<boolean | UrlTree> {
    // Obtener el token del almacenamiento local
    const token = localStorage.getItem('auth_token');
    
    // Si no hay token, redirigir al login
    if (!token) {
      return this.router.createUrlTree(['/login'], {
        queryParams: { returnUrl: state.url }
      });
    }
    
    // Obtener los roles permitidos de la ruta
    const allowedRoles = route.data['roles'] as Array<string>;
    
    // Si no hay roles específicos requeridos, permitir el acceso
    if (!allowedRoles || allowedRoles.length === 0) {
      return true;
    }
    
    // Obtener el usuario del almacenamiento local
    const userJson = localStorage.getItem('user_data');
    
    if (!userJson) {
      // Si no hay información del usuario, redirigir al login
      return this.router.createUrlTree(['/login'], {
        queryParams: { returnUrl: state.url }
      });
    }
    
    try {
      const user = JSON.parse(userJson);
      
      // Verificar si el usuario tiene alguno de los roles permitidos
      if (user && user.tipo && allowedRoles.includes(user.tipo)) {
        return true;
      }
      
      // Si el usuario no tiene los permisos necesarios, redirigir a una página de acceso denegado
      // o de vuelta al dashboard correspondiente
      if (user.tipo === 'alumno') {
        return this.router.createUrlTree(['/student-dashboard']);
      } else if (user.tipo === 'doctor') {
        return this.router.createUrlTree(['/doctor-dashboard']);
      }
      
      // Por defecto, redirigir al login
      return this.router.createUrlTree(['/login']);
      
    } catch (error) {
      console.error('Error al analizar la información del usuario:', error);
      return this.router.createUrlTree(['/login']);
    }
  }
}
