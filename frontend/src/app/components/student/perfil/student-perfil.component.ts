import { Component, ElementRef, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subject } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { of } from 'rxjs';
import { PerfilAlumno, StudentPerfilService } from './student-perfil.service';

interface PerfilForm {
  tipo_sangre: string;
  peso: string;
  estatura: string;
  alergias: string;
  enfermedades_cronicas: string;
  contacto_emergencia_nombre: string;
  contacto_emergencia_telefono: string;
}

@Component({
  selector: 'app-student-perfil',
  standalone: true,
  imports: [CommonModule, FormsModule, DatePipe],
  templateUrl: './student-perfil.component.html',
  styleUrls: ['./student-perfil.component.css'],
})
export class StudentPerfilComponent implements OnInit, OnDestroy {
  @ViewChild('fotoInput') fotoInput!: ElementRef<HTMLInputElement>;

  perfil: PerfilAlumno | null = null;
  cargando = false;
  editando = false;
  guardando = false;
  subiendo = false;
  fotoPreview: string | null = null;

  form: PerfilForm = {
    tipo_sangre: '',
    peso: '',
    estatura: '',
    alergias: '',
    enfermedades_cronicas: '',
    contacto_emergencia_nombre: '',
    contacto_emergencia_telefono: '',
  };

  toast: { visible: boolean; msg: string; error: boolean } = {
    visible: false,
    msg: '',
    error: false,
  };

  private destroy$ = new Subject<void>();
  private toastTimer: ReturnType<typeof setTimeout> | null = null;

  readonly TIPOS_SANGRE = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'No lo sé'];

  constructor(private service: StudentPerfilService) {}

  ngOnInit(): void {
    this.cargarPerfil();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
    if (this.toastTimer) clearTimeout(this.toastTimer);
  }

  get iniciales(): string {
    if (!this.perfil) return '?';
    return `${this.perfil.nombre?.[0] ?? ''}${this.perfil.apellido?.[0] ?? ''}`.toUpperCase();
  }

  get fotoUrl(): string | null {
    return this.fotoPreview ?? this.perfil?.foto_perfil ?? null;
  }

  cargarPerfil(): void {
    this.cargando = true;
    this.service.getPerfil()
      .pipe(
        takeUntil(this.destroy$),
        catchError(() => { this.mostrarToast('Error al cargar el perfil.', true); return of(null); }),
        finalize(() => this.cargando = false),
      )
      .subscribe(res => {
        if (res) this.perfil = res.perfil;
      });
  }

  iniciarEdicion(): void {
    if (!this.perfil) return;
    this.form = {
      tipo_sangre: this.perfil.tipo_sangre ?? '',
      peso: this.perfil.peso != null ? String(this.perfil.peso) : '',
      estatura: this.perfil.estatura != null ? String(this.perfil.estatura) : '',
      alergias: this.perfil.alergias ?? '',
      enfermedades_cronicas: this.perfil.enfermedades_cronicas ?? '',
      contacto_emergencia_nombre: this.perfil.contacto_emergencia_nombre ?? '',
      contacto_emergencia_telefono: this.perfil.contacto_emergencia_telefono ?? '',
    };
    this.editando = true;
  }

  cancelarEdicion(): void {
    this.editando = false;
  }

  guardar(): void {
    this.guardando = true;
    const data = {
      tipo_sangre: this.form.tipo_sangre || null,
      peso: this.form.peso ? parseFloat(this.form.peso) : null,
      estatura: this.form.estatura ? parseFloat(this.form.estatura) : null,
      alergias: this.form.alergias || null,
      enfermedades_cronicas: this.form.enfermedades_cronicas || null,
      contacto_emergencia_nombre: this.form.contacto_emergencia_nombre || null,
      contacto_emergencia_telefono: this.form.contacto_emergencia_telefono || null,
    };

    this.service.actualizarPerfil(data)
      .pipe(
        takeUntil(this.destroy$),
        catchError(err => {
          this.mostrarToast(err?.error?.message ?? 'Error al guardar los cambios.', true);
          return of(null);
        }),
        finalize(() => this.guardando = false),
      )
      .subscribe(res => {
        if (res) {
          this.mostrarToast('Perfil actualizado correctamente.');
          this.editando = false;
          this.cargarPerfil();
        }
      });
  }

  triggerFoto(): void {
    this.fotoInput.nativeElement.click();
  }

  onFotoChange(event: Event): void {
    const file = (event.target as HTMLInputElement).files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = e => this.fotoPreview = e.target?.result as string;
    reader.readAsDataURL(file);

    this.subiendo = true;
    this.service.subirFoto(file)
      .pipe(
        takeUntil(this.destroy$),
        catchError(() => { this.mostrarToast('Error al subir la foto.', true); return of(null); }),
        finalize(() => this.subiendo = false),
      )
      .subscribe(res => {
        if (res) {
          this.mostrarToast('Foto actualizada.');
          this.cargarPerfil();
        }
      });
  }

  private mostrarToast(msg: string, error = false): void {
    if (this.toastTimer) clearTimeout(this.toastTimer);
    this.toast = { visible: true, msg, error };
    this.toastTimer = setTimeout(() => this.toast = { ...this.toast, visible: false }, 3500);
  }
}
