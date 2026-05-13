import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { PerfilMedicoService } from '../../../services/perfil-medico.service';

export interface PerfilAlumno {
  id: number;
  nombre: string;
  apellido: string;
  numero_control: string;
  email: string;
  carrera: string | null;
  semestre: number | null;
  tipo_sangre: string | null;
  peso: number | null;
  estatura: number | null;
  alergias: string | null;
  enfermedades_cronicas: string | null;
  contacto_emergencia_nombre: string | null;
  contacto_emergencia_telefono: string | null;
  foto_perfil: string | null;
  updated_at: string | null;
}

@Injectable({ providedIn: 'root' })
export class StudentPerfilService {
  constructor(private perfilService: PerfilMedicoService) {}

  // GET /api/perfil-medico
  getPerfil(): Observable<{ perfil: PerfilAlumno }> {
    return this.perfilService.getPerfil() as Observable<{ perfil: PerfilAlumno }>;
  }

  // PUT /api/perfil-medico
  actualizarPerfil(data: Partial<PerfilAlumno>): Observable<any> {
    return this.perfilService.updatePerfil(data);
  }

  // POST /api/perfil/foto
  subirFoto(file: File): Observable<{ message: string; foto_url: string }> {
    return this.perfilService.subirFoto(file);
  }
}
