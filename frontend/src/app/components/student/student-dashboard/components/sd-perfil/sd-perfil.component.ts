import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subject } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { of } from 'rxjs';
import { PerfilMedico, PerfilMedicoService, SesionActiva } from '../../../../../services/perfil-medico.service';

@Component({
  selector: 'app-sd-perfil',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './sd-perfil.component.html',
  styleUrls: ['./sd-perfil.component.css'],
})
export class SdPerfilComponent implements OnInit, OnDestroy {
  activeTab: 'personal' | 'medico' | 'seguridad' = 'personal';

  perfilMedico: PerfilMedico | null = null;
  isLoadingPerfil = false;
  perfilMsg: string | null = null;
  perfilForm = { tipo_sangre: '', alergias: '', enfermedades_cronicas: '' };
  isSubmittingPerfil = false;

  fotoPreview: string | null = null;
  isUploadingFoto = false;
  fotoMsg: string | null = null;

  personalForm = { nombre: '', apellido: '', email: '', telefono: '', fecha_nacimiento: '' };
  isSubmittingPersonal = false;
  personalMsg: string | null = null;
  editandoPersonal = false;

  passwordForm = { password_actual: '', password_nuevo: '', password_nuevo_confirmation: '' };
  isSubmittingPassword = false;
  passwordMsg: string | null = null;

  sesiones: SesionActiva[] = [];
  isLoadingSesiones = false;
  sesionMsg: string | null = null;
  mostrarTodasSesiones = false;

  private destroy$ = new Subject<void>();

  constructor(private perfilMedicoService: PerfilMedicoService) {}

  ngOnInit(): void {
    this.loadPerfil();
    this.loadSesiones();
  }

  ngOnDestroy(): void { this.destroy$.next(); this.destroy$.complete(); }

  loadPerfil(): void {
    this.isLoadingPerfil = true;
    this.perfilMedicoService.getPerfil()
      .pipe(takeUntil(this.destroy$), catchError(() => of(null)), finalize(() => this.isLoadingPerfil = false))
      .subscribe((res: any) => {
        if (res) {
          this.perfilMedico = res.perfil;
          this.perfilForm = {
            tipo_sangre: res.perfil.tipo_sangre ?? '',
            alergias: res.perfil.alergias ?? '',
            enfermedades_cronicas: res.perfil.enfermedades_cronicas ?? ''
          };
        }
      });
  }

  submitPerfil(): void {
    this.isSubmittingPerfil = true;
    this.perfilMsg = null;
    this.perfilMedicoService.updatePerfil(this.perfilForm)
      .pipe(takeUntil(this.destroy$), catchError(err => { this.perfilMsg = err?.error?.message || 'Error al guardar.'; return of(null); }), finalize(() => this.isSubmittingPerfil = false))
      .subscribe((res: any) => { if (res) { this.perfilMsg = 'Perfil médico actualizado.'; this.loadPerfil(); } });
  }

  startEditPersonal(): void {
    if (!this.perfilMedico) return;
    this.personalForm = {
      nombre: this.perfilMedico.nombre,
      apellido: this.perfilMedico.apellido,
      email: this.perfilMedico.email,
      telefono: this.perfilMedico.telefono ?? '',
      fecha_nacimiento: this.perfilMedico.fecha_nacimiento ?? ''
    };
    this.editandoPersonal = true;
    this.personalMsg = null;
  }

  cancelEditPersonal(): void { this.editandoPersonal = false; this.personalMsg = null; }

  submitDatosPersonales(): void {
    this.isSubmittingPersonal = true;
    this.personalMsg = null;
    this.perfilMedicoService.updateDatosPersonales(this.personalForm)
      .pipe(takeUntil(this.destroy$), catchError(err => { this.personalMsg = err?.error?.message || 'Error al guardar.'; return of(null); }), finalize(() => this.isSubmittingPersonal = false))
      .subscribe((res: any) => { if (res) { this.personalMsg = 'Datos actualizados correctamente.'; this.editandoPersonal = false; this.loadPerfil(); } });
  }

  submitCambiarPassword(): void {
    this.isSubmittingPassword = true;
    this.passwordMsg = null;
    this.perfilMedicoService.cambiarPassword(this.passwordForm)
      .pipe(takeUntil(this.destroy$), catchError(err => { this.passwordMsg = err?.error?.message || 'Error al cambiar contraseña.'; return of(null); }), finalize(() => this.isSubmittingPassword = false))
      .subscribe((res: any) => {
        if (res) {
          this.passwordMsg = 'Contraseña actualizada correctamente.';
          this.passwordForm = { password_actual: '', password_nuevo: '', password_nuevo_confirmation: '' };
        }
      });
  }

  onFotoChange(event: Event): void {
    const file = (event.target as HTMLInputElement).files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = e => this.fotoPreview = e.target?.result as string;
    reader.readAsDataURL(file);
    this.isUploadingFoto = true;
    this.fotoMsg = null;
    this.perfilMedicoService.subirFoto(file)
      .pipe(takeUntil(this.destroy$), catchError(err => { this.fotoMsg = 'Error al subir foto.'; return of(null); }), finalize(() => this.isUploadingFoto = false))
      .subscribe((res: any) => { if (res) { this.fotoMsg = 'Foto actualizada.'; this.loadPerfil(); } });
  }

  loadSesiones(): void {
    this.isLoadingSesiones = true;
    this.perfilMedicoService.getSesiones()
      .pipe(takeUntil(this.destroy$), catchError(() => of([])), finalize(() => this.isLoadingSesiones = false))
      .subscribe((res: any) => this.sesiones = res?.sesiones ?? []);
  }

  revocarSesion(id: number): void {
    this.perfilMedicoService.revocarSesion(id)
      .pipe(takeUntil(this.destroy$), catchError(() => of(null)))
      .subscribe((res: any) => { if (res) { this.sesionMsg = 'Sesión cerrada.'; this.loadSesiones(); } });
  }

  revocarTodasSesiones(): void {
    this.sesionMsg = 'Función no disponible aún.';
  }

  get sesionesVisibles(): SesionActiva[] {
    return this.mostrarTodasSesiones ? this.sesiones : this.sesiones.slice(0, 5);
  }

  get iniciales(): string {
    if (!this.perfilMedico) return '?';
    return `${this.perfilMedico.nombre[0]}${this.perfilMedico.apellido[0]}`;
  }
}
