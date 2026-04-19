import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { Subject, of } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { AuthService } from '../services/auth.service';
import { AdminService, Alumno, Doctor } from '../services/admin.service';
import { CalendarioAdminService, DiaEspecial, TIPO_LABELS } from '../services/calendario-admin.service';

@Component({
  selector: 'app-admin-dashboard',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './admin-dashboard.component.html',
  styleUrls: ['./admin-dashboard.component.css']
})
export class AdminDashboardComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  activeSection = 'alumnos';
  adminName = 'Administrador';

  // Alumnos
  alumnos: Alumno[] = [];
  alumnosBusqueda = '';
  isLoadingAlumnos = false;
  alumnosError: string | null = null;
  showAlumnoForm = false;
  editingAlumnoId: number | null = null;
  alumnoMsg: string | null = null;
  isSubmittingAlumno = false;
  alumnoForm = { numero_control: '', nombre: '', apellido: '', email: '', nip: '', telefono: '', fecha_nacimiento: '' };

  get alumnosFiltrados(): Alumno[] {
    const q = this.alumnosBusqueda.trim().toLowerCase();
    if (!q) return this.alumnos;
    return this.alumnos.filter(a =>
      a.numero_control.toLowerCase().includes(q) ||
      a.nombre.toLowerCase().includes(q) ||
      a.apellido.toLowerCase().includes(q) ||
      (a.email ?? '').toLowerCase().includes(q)
    );
  }

  // Doctores
  doctores: Doctor[] = [];
  isLoadingDoctores = false;
  doctoresError: string | null = null;
  showDoctorForm = false;
  editingDoctorId: number | null = null;
  doctorMsg: string | null = null;
  isSubmittingDoctor = false;
  doctorForm = { username: '', nombre: '', apellido: '', email: '', password: '', telefono: '' };

  // Confirmación de borrado
  confirmDeleteId: number | null = null;
  confirmDeleteType: 'alumno' | 'doctor' | null = null;

  // Calendario
  readonly tipoLabels = TIPO_LABELS;
  readonly weekDays = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
  calCurrentMonth = new Date(new Date().getFullYear(), new Date().getMonth(), 1);
  calWeeks: { date: string; label: number; isCurrentMonth: boolean; diaEspecial: DiaEspecial | null }[][] = [];
  diasEspeciales: DiaEspecial[] = [];
  isLoadingCal = false;
  // Formulario de día especial
  showDiaForm = false;
  diaForm = { fecha: '', tipo: 'holiday', etiqueta: '' };
  diaMsg: string | null = null;
  isSubmittingDia = false;

  constructor(
    private router: Router,
    private authService: AuthService,
    private adminService: AdminService,
    private calendarioService: CalendarioAdminService
  ) {}

  ngOnInit(): void {
    const user = this.authService.getCurrentUser();
    this.adminName = user ? `${user.nombre} ${user.apellido}` : 'Administrador';
    this.loadAlumnos();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  setSection(section: string): void {
    this.activeSection = section;
    if (section === 'alumnos') this.loadAlumnos();
    if (section === 'doctores') this.loadDoctores();
    if (section === 'calendario') this.loadCalendario();
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/login']);
  }

  // ===== ALUMNOS =====

  loadAlumnos(): void {
    this.isLoadingAlumnos = true;
    this.alumnosError = null;
    this.adminService.getAlumnos()
      .pipe(
        takeUntil(this.destroy$),
        catchError(err => { this.alumnosError = err?.error?.message || 'Error al cargar alumnos.'; return of([]); }),
        finalize(() => { this.isLoadingAlumnos = false; })
      )
      .subscribe(data => { this.alumnos = data; });
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
        fecha_nacimiento: alumno.fecha_nacimiento || ''
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
    const payload = { ...this.alumnoForm };
    if (!payload.nip) delete (payload as any).nip;
    if (!payload.telefono) delete (payload as any).telefono;
    if (!payload.fecha_nacimiento) delete (payload as any).fecha_nacimiento;

    const req$ = this.editingAlumnoId
      ? this.adminService.updateAlumno(this.editingAlumnoId, payload)
      : this.adminService.createAlumno(payload);

    req$.pipe(
      takeUntil(this.destroy$),
      catchError(err => {
        const errors = err?.error?.errors;
        if (errors) {
          const first = Object.values(errors)[0] as string[];
          this.alumnoMsg = first[0];
        } else {
          this.alumnoMsg = err?.error?.message || 'Error al guardar alumno.';
        }
        return of(null);
      }),
      finalize(() => { this.isSubmittingAlumno = false; })
    ).subscribe(res => {
      if (res) {
        this.alumnoMsg = this.editingAlumnoId ? 'Alumno actualizado.' : 'Alumno creado.';
        this.loadAlumnos();
        setTimeout(() => this.closeAlumnoForm(), 1200);
      }
    });
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

    const req$ = tipo === 'alumno'
      ? this.adminService.deleteAlumno(id)
      : this.adminService.deleteDoctor(id);

    req$.pipe(takeUntil(this.destroy$), catchError(() => of(null)))
      .subscribe(() => {
        if (tipo === 'alumno') this.loadAlumnos();
        else this.loadDoctores();
      });
  }

  // ===== DOCTORES =====

  loadDoctores(): void {
    this.isLoadingDoctores = true;
    this.doctoresError = null;
    this.adminService.getDoctores()
      .pipe(
        takeUntil(this.destroy$),
        catchError(err => { this.doctoresError = err?.error?.message || 'Error al cargar doctores.'; return of([]); }),
        finalize(() => { this.isLoadingDoctores = false; })
      )
      .subscribe(data => { this.doctores = data; });
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
        telefono: doctor.telefono || ''
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

  // ===== CALENDARIO =====

  get calLabel(): string {
    return new Intl.DateTimeFormat('es-MX', { month: 'long', year: 'numeric' }).format(this.calCurrentMonth);
  }

  changeCalMonth(dir: number): void {
    this.calCurrentMonth = new Date(this.calCurrentMonth.getFullYear(), this.calCurrentMonth.getMonth() + dir, 1);
    this.loadCalendario();
  }

  loadCalendario(): void {
    this.isLoadingCal = true;
    const m = this.calCurrentMonth.getMonth() + 1;
    const y = this.calCurrentMonth.getFullYear();
    this.calendarioService.getDias(m, y)
      .pipe(takeUntil(this.destroy$), catchError(() => of([])), finalize(() => this.isLoadingCal = false))
      .subscribe(dias => {
        this.diasEspeciales = dias;
        this.buildCalGrid();
      });
  }

  private buildCalGrid(): void {
    const ref = this.calCurrentMonth;
    const firstDay = ref.getDay();
    const start = new Date(ref);
    start.setDate(start.getDate() - firstDay);
    const diasMap = new Map(this.diasEspeciales.map(d => [d.fecha, d]));
    const weeks: any[][] = [];
    const cursor = new Date(start);
    for (let w = 0; w < 6; w++) {
      const week: any[] = [];
      for (let d = 0; d < 7; d++) {
        const dateStr = `${cursor.getFullYear()}-${String(cursor.getMonth()+1).padStart(2,'0')}-${String(cursor.getDate()).padStart(2,'0')}`;
        week.push({
          date: dateStr,
          label: cursor.getDate(),
          isCurrentMonth: cursor.getMonth() === ref.getMonth(),
          diaEspecial: diasMap.get(dateStr) ?? null
        });
        cursor.setDate(cursor.getDate() + 1);
      }
      weeks.push(week);
    }
    this.calWeeks = weeks;
  }

  openDiaForm(fecha?: string): void {
    this.diaMsg = null;
    this.diaForm = { fecha: fecha ?? '', tipo: 'holiday', etiqueta: '' };
    // Si ya existe un día especial en esa fecha, pre-carga los datos
    if (fecha) {
      const existing = this.diasEspeciales.find(d => d.fecha === fecha);
      if (existing) {
        this.diaForm.tipo = existing.tipo;
        this.diaForm.etiqueta = existing.etiqueta ?? '';
      }
    }
    this.showDiaForm = true;
  }

  closeDiaForm(): void {
    this.showDiaForm = false;
    this.diaMsg = null;
  }

  submitDia(): void {
    if (!this.diaForm.fecha) { this.diaMsg = 'Selecciona una fecha.'; return; }
    this.isSubmittingDia = true;
    this.calendarioService.saveDia(this.diaForm.fecha, this.diaForm.tipo, this.diaForm.etiqueta)
      .pipe(takeUntil(this.destroy$), catchError(err => {
        this.diaMsg = err?.error?.message || 'Error al guardar.';
        return of(null);
      }), finalize(() => this.isSubmittingDia = false))
      .subscribe(res => {
        if (res) {
          this.diaMsg = 'Guardado.';
          this.loadCalendario();
          setTimeout(() => this.closeDiaForm(), 800);
        }
      });
  }

  deleteDia(id: number): void {
    this.calendarioService.deleteDia(id)
      .pipe(takeUntil(this.destroy$), catchError(() => of(null)))
      .subscribe(() => this.loadCalendario());
  }

  submitDoctor(): void {
    this.isSubmittingDoctor = true;
    this.doctorMsg = null;
    const payload = { ...this.doctorForm };
    if (!payload.password) delete (payload as any).password;
    if (!payload.telefono) delete (payload as any).telefono;

    const req$ = this.editingDoctorId
      ? this.adminService.updateDoctor(this.editingDoctorId, payload)
      : this.adminService.createDoctor(payload);

    req$.pipe(
      takeUntil(this.destroy$),
      catchError(err => {
        const errors = err?.error?.errors;
        if (errors) {
          const first = Object.values(errors)[0] as string[];
          this.doctorMsg = first[0];
        } else {
          this.doctorMsg = err?.error?.message || 'Error al guardar doctor.';
        }
        return of(null);
      }),
      finalize(() => { this.isSubmittingDoctor = false; })
    ).subscribe(res => {
      if (res) {
        this.doctorMsg = this.editingDoctorId ? 'Doctor actualizado.' : 'Doctor creado.';
        this.loadDoctores();
        setTimeout(() => this.closeDoctorForm(), 1200);
      }
    });
  }
}
