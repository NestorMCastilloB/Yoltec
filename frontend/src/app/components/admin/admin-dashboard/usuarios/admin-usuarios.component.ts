import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, OnDestroy, OnInit, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subject, of } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { AdminService, Alumno, Doctor } from '../../../../services/admin.service';
import { UsuarioRow, toAlumnoRow, toDoctorRow } from '../admin-utils';

@Component({
  selector: 'app-admin-usuarios',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './admin-usuarios.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AdminUsuariosComponent implements OnInit, OnDestroy {
  @Output() changed = new EventEmitter<{ alumnos: Alumno[]; doctores: Doctor[] }>();

  alumnos: Alumno[] = [];
  doctores: Doctor[] = [];
  isLoadingAlumnos = false;
  isLoadingDoctores = false;
  alumnosError: string | null = null;
  doctoresError: string | null = null;

  showAlumnoForm = false;
  editingAlumnoId: number | null = null;
  alumnoMsg: string | null = null;
  isSubmittingAlumno = false;
  alumnoForm = { numero_control: '', nombre: '', apellido: '', email: '', nip: '', telefono: '', fecha_nacimiento: '' };

  showDoctorForm = false;
  editingDoctorId: number | null = null;
  doctorMsg: string | null = null;
  isSubmittingDoctor = false;
  doctorForm = { username: '', nombre: '', apellido: '', email: '', password: '', telefono: '' };

  confirmDeleteId: number | null = null;
  confirmDeleteType: 'alumno' | 'doctor' | null = null;

  alumnosRows: UsuarioRow[] = [];
  doctoresRows: UsuarioRow[] = [];
  todosRows: UsuarioRow[] = [];
  filteredRows: UsuarioRow[] = [];

  usersTab: 'todos' | 'alumnos' | 'doctores' = 'todos';
  private _usuariosBusqueda = '';
  get usuariosBusqueda(): string { return this._usuariosBusqueda; }
  set usuariosBusqueda(v: string) { this._usuariosBusqueda = v; this.applyFilter(); }

  private destroy$ = new Subject<void>();

  constructor(private adminService: AdminService, private cdr: ChangeDetectorRef) {}

  ngOnInit(): void {
    this.loadAlumnos();
    this.loadDoctores();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  setUsersTab(tab: 'todos' | 'alumnos' | 'doctores'): void {
    this.usersTab = tab;
    this._usuariosBusqueda = '';
    this.applyFilter();
  }

  loadAlumnos(): void {
    this.isLoadingAlumnos = true;
    this.alumnosError = null;
    this.adminService.getAlumnos()
      .pipe(
        takeUntil(this.destroy$),
        catchError(err => { this.alumnosError = err?.error?.message || 'Error al cargar alumnos.'; return of([]); }),
        finalize(() => { this.isLoadingAlumnos = false; this.cdr.markForCheck(); })
      )
      .subscribe(data => { this.alumnos = data; this.updateRows(); this.emitChanged(); this.cdr.markForCheck(); });
  }

  loadDoctores(): void {
    this.isLoadingDoctores = true;
    this.doctoresError = null;
    this.adminService.getDoctores()
      .pipe(
        takeUntil(this.destroy$),
        catchError(err => { this.doctoresError = err?.error?.message || 'Error al cargar doctores.'; return of([]); }),
        finalize(() => { this.isLoadingDoctores = false; this.cdr.markForCheck(); })
      )
      .subscribe(data => { this.doctores = data; this.updateRows(); this.emitChanged(); this.cdr.markForCheck(); });
  }

  openAlumnoForm(alumno?: Alumno): void {
    this.alumnoMsg = null;
    if (alumno) {
      this.editingAlumnoId = alumno.id;
      this.alumnoForm = {
        numero_control: alumno.numero_control,
        nombre: alumno.nombre,
        apellido: alumno.apellido,
        email: alumno.email,
        nip: '',
        telefono: alumno.telefono || '',
        fecha_nacimiento: alumno.fecha_nacimiento || '',
      };
    } else {
      this.editingAlumnoId = null;
      this.alumnoForm = { numero_control: '', nombre: '', apellido: '', email: '', nip: '', telefono: '', fecha_nacimiento: '' };
    }
    this.showAlumnoForm = true;
  }

  closeAlumnoForm(): void {
    this.showAlumnoForm = false;
    this.editingAlumnoId = null;
    this.alumnoMsg = null;
  }

  submitAlumno(): void {
    this.isSubmittingAlumno = true;
    this.alumnoMsg = null;
    const payload: Partial<typeof this.alumnoForm> = { ...this.alumnoForm };
    if (!payload.nip) delete payload.nip;
    if (!payload.telefono) delete payload.telefono;
    if (!payload.fecha_nacimiento) delete payload.fecha_nacimiento;

    const req$ = this.editingAlumnoId
      ? this.adminService.updateAlumno(this.editingAlumnoId, payload)
      : this.adminService.createAlumno(payload);

    req$.pipe(
      takeUntil(this.destroy$),
      catchError(err => {
        const errors = err?.error?.errors;
        this.alumnoMsg = errors ? (Object.values(errors)[0] as string[])[0] : (err?.error?.message || 'Error al guardar alumno.');
        this.cdr.markForCheck();
        return of(null);
      }),
      finalize(() => { this.isSubmittingAlumno = false; this.cdr.markForCheck(); })
    ).subscribe(res => {
      if (res) {
        this.alumnoMsg = this.editingAlumnoId ? 'Alumno actualizado.' : 'Alumno creado.';
        this.loadAlumnos();
        setTimeout(() => this.closeAlumnoForm(), 1200);
      }
    });
  }

  openDoctorForm(doctor?: Doctor): void {
    this.doctorMsg = null;
    if (doctor) {
      this.editingDoctorId = doctor.id;
      this.doctorForm = {
        username: doctor.username,
        nombre: doctor.nombre,
        apellido: doctor.apellido,
        email: doctor.email,
        password: '',
        telefono: doctor.telefono || '',
      };
    } else {
      this.editingDoctorId = null;
      this.doctorForm = { username: '', nombre: '', apellido: '', email: '', password: '', telefono: '' };
    }
    this.showDoctorForm = true;
  }

  closeDoctorForm(): void {
    this.showDoctorForm = false;
    this.editingDoctorId = null;
    this.doctorMsg = null;
  }

  submitDoctor(): void {
    this.isSubmittingDoctor = true;
    this.doctorMsg = null;
    const payload: Partial<typeof this.doctorForm> = { ...this.doctorForm };
    if (!payload.password) delete payload.password;
    if (!payload.telefono) delete payload.telefono;

    const req$ = this.editingDoctorId
      ? this.adminService.updateDoctor(this.editingDoctorId, payload)
      : this.adminService.createDoctor(payload);

    req$.pipe(
      takeUntil(this.destroy$),
      catchError(err => {
        const errors = err?.error?.errors;
        this.doctorMsg = errors ? (Object.values(errors)[0] as string[])[0] : (err?.error?.message || 'Error al guardar doctor.');
        this.cdr.markForCheck();
        return of(null);
      }),
      finalize(() => { this.isSubmittingDoctor = false; this.cdr.markForCheck(); })
    ).subscribe(res => {
      if (res) {
        this.doctorMsg = this.editingDoctorId ? 'Doctor actualizado.' : 'Doctor creado.';
        this.loadDoctores();
        setTimeout(() => this.closeDoctorForm(), 1200);
      }
    });
  }

  editUsuario(row: UsuarioRow): void {
    if (row.rol === 'alumno') {
      const a = this.alumnos.find(x => x.id === row.id);
      if (a) this.openAlumnoForm(a);
    } else {
      const d = this.doctores.find(x => x.id === row.id);
      if (d) this.openDoctorForm(d);
    }
  }

  confirmDelete(id: number, tipo: 'alumno' | 'doctor'): void {
    this.confirmDeleteId = id;
    this.confirmDeleteType = tipo;
  }

  cancelDelete(): void {
    this.confirmDeleteId = null;
    this.confirmDeleteType = null;
  }

  executeDelete(): void {
    if (!this.confirmDeleteId || !this.confirmDeleteType) return;
    const id = this.confirmDeleteId;
    const tipo = this.confirmDeleteType;
    this.cancelDelete();
    const req$ = tipo === 'alumno' ? this.adminService.deleteAlumno(id) : this.adminService.deleteDoctor(id);
    req$.pipe(takeUntil(this.destroy$), catchError(() => of(null)))
      .subscribe(() => { if (tipo === 'alumno') this.loadAlumnos(); else this.loadDoctores(); });
  }

  private updateRows(): void {
    this.alumnosRows = this.alumnos.map(a => toAlumnoRow(a));
    this.doctoresRows = this.doctores.map(d => toDoctorRow(d));
    this.todosRows = [...this.alumnosRows, ...this.doctoresRows];
    this.applyFilter();
  }

  private applyFilter(): void {
    const base = this.usersTab === 'todos' ? this.todosRows
               : this.usersTab === 'alumnos' ? this.alumnosRows
               : this.doctoresRows;
    const q = this._usuariosBusqueda.trim().toLowerCase();
    this.filteredRows = !q ? base : base.filter(r =>
      r.nombre.toLowerCase().includes(q) ||
      r.sub.toLowerCase().includes(q) ||
      r.email.toLowerCase().includes(q)
    );
    this.cdr.markForCheck();
  }

  private emitChanged(): void {
    this.changed.emit({ alumnos: this.alumnos, doctores: this.doctores });
  }
}
