import { Component, OnDestroy, OnInit, HostListener, ChangeDetectionStrategy, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { Subject, of, forkJoin } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { AuthService } from '../../../services/auth.service';
import { ThemeService } from '../../../services/theme.service';
import { AdminService, Alumno, Doctor } from '../../../services/admin.service';
import { CalendarioAdminService, DiaEspecial, TIPO_LABELS } from '../../../services/calendario-admin.service';
import { AdminDashboardService, AdminStats } from '../dashboard/admin-dashboard.service';
import { AdminSidebarComponent } from '../shared/admin-sidebar.component';

interface UsuarioRow {
  key: string;
  id: number;
  initials: string;
  nombre: string;
  sub: string;
  email: string;
  rol: 'alumno' | 'doctor';
}

@Component({
  selector: 'app-admin-dashboard',
  standalone: true,
  imports: [CommonModule, FormsModule, AdminSidebarComponent],
  templateUrl: './admin-dashboard.component.html',
  styleUrls: ['./admin-dashboard.component.css'],
  changeDetection: ChangeDetectionStrategy.OnPush  // cambio 4: evita CD innecesario
})
export class AdminDashboardComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  activeSection = 'panel';
  adminName = 'Administrador';
  userMenuOpen = false;

  // Panel
  stats: AdminStats | null = null;
  isLoadingStats = false;
  panelUsuarios: UsuarioRow[] = [];
  diasProximos: DiaEspecial[] = [];
  isLoadingPanel = false;

  // cambio 5: calculado una sola vez, no en cada ciclo de CD
  readonly fechaHoy = new Intl.DateTimeFormat('es-MX', {
    weekday: 'long', day: 'numeric', month: 'long', year: 'numeric'
  }).format(new Date());

  // Alumnos
  alumnos: Alumno[] = [];
  isLoadingAlumnos = false;
  alumnosError: string | null = null;
  showAlumnoForm = false;
  editingAlumnoId: number | null = null;
  alumnoMsg: string | null = null;
  isSubmittingAlumno = false;
  alumnoForm = { numero_control: '', nombre: '', apellido: '', email: '', nip: '', telefono: '', fecha_nacimiento: '' };

  // Doctores
  doctores: Doctor[] = [];
  isLoadingDoctores = false;
  doctoresError: string | null = null;
  showDoctorForm = false;
  editingDoctorId: number | null = null;
  doctorMsg: string | null = null;
  isSubmittingDoctor = false;
  doctorForm = { username: '', nombre: '', apellido: '', email: '', password: '', telefono: '' };

  // cambio 3: propiedades cacheadas en lugar de getters recalculados en cada CD
  alumnosRows: UsuarioRow[] = [];
  doctoresRows: UsuarioRow[] = [];
  todosRows: UsuarioRow[] = [];
  filteredRows: UsuarioRow[] = [];

  // cambio 3: setter activa el filtro automáticamente al escribir sin CD extra
  usersTab: 'todos' | 'alumnos' | 'doctores' = 'todos';
  private _usuariosBusqueda = '';
  get usuariosBusqueda(): string { return this._usuariosBusqueda; }
  set usuariosBusqueda(v: string) { this._usuariosBusqueda = v; this.applyFilter(); }

  // Confirmación de borrado
  confirmDeleteId: number | null = null;
  confirmDeleteType: 'alumno' | 'doctor' | null = null;

  // Calendario
  readonly tipoLabels = TIPO_LABELS;
  readonly weekDays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
  calCurrentMonth = new Date(new Date().getFullYear(), new Date().getMonth(), 1);
  calLabel = '';  // cambio 6: propiedad, no getter
  calWeeks: { date: string; label: number; isCurrentMonth: boolean; diaEspecial: DiaEspecial | null }[][] = [];
  diasEspeciales: DiaEspecial[] = [];
  isLoadingCal = false;
  diaForm = { fecha: '', tipo: 'holiday', etiqueta: '' };
  diaMsg: string | null = null;
  isSubmittingDia = false;

  constructor(
    private router: Router,
    private authService: AuthService,
    public themeService: ThemeService,
    private adminService: AdminService,
    private calendarioService: CalendarioAdminService,
    private dashboardService: AdminDashboardService,
    private cdr: ChangeDetectorRef
  ) {
    this.updateCalLabel();
  }

  ngOnInit(): void {
    const user = this.authService.getCurrentUser();
    this.adminName = user ? `${user.nombre} ${user.apellido}` : 'Administrador';
    this.loadStats();
    this.loadPanelPreview();
  }

  get adminInitial(): string { return this.adminName.charAt(0).toUpperCase(); }

  get sectionTitle(): string {
    const titles: Record<string, string> = {
      panel: 'Panel de administración',
      usuarios: 'Gestión de usuarios',
      calendario: 'Días especiales'
    };
    return titles[this.activeSection] ?? '';
  }

  get sectionCrumb(): string { return 'ADMIN · ' + this.activeSection.toUpperCase(); }

  toggleUserMenu(): void { this.userMenuOpen = !this.userMenuOpen; }

  @HostListener('document:click', ['$event'])
  onDocumentClick(e: MouseEvent): void {
    if (!(e.target as Element).closest('.admin-user-wrap')) {
      this.userMenuOpen = false;
    }
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  setSection(section: string): void {
    this.activeSection = section;
    // cambio 1 y 2: no re-fetch si ya hay datos en memoria
    if (section === 'panel') {
      if (!this.stats) this.loadStats();
      if (this.alumnos.length || this.doctores.length || this.diasEspeciales.length) {
        this.panelUsuarios = this.buildPanelUsuarios();
        this.diasProximos = this.buildDiasProximos();
      } else {
        this.loadPanelPreview();
      }
    }
    if (section === 'usuarios') {
      this.usersTab = 'todos';
      this._usuariosBusqueda = '';
      if (!this.alumnos.length) this.loadAlumnos();
      if (!this.doctores.length) this.loadDoctores();
      if (this.alumnos.length && this.doctores.length) this.updateRows();
    }
    if (section === 'calendario') { this.loadCalendario(); }
  }

  setUsersTab(tab: 'todos' | 'alumnos' | 'doctores'): void {
    this.usersTab = tab;
    this._usuariosBusqueda = '';
    this.applyFilter();
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/login']);
  }

  // ===== PANEL =====

  loadStats(): void {
    this.isLoadingStats = true;
    this.dashboardService.getStats()
      .pipe(
        takeUntil(this.destroy$),
        catchError(() => of(null)),
        finalize(() => { this.isLoadingStats = false; this.cdr.markForCheck(); })
      )
      .subscribe(data => { this.stats = data; this.cdr.markForCheck(); });
  }

  // cambio 2: solo pide al backend lo que no tiene en memoria
  loadPanelPreview(): void {
    this.isLoadingPanel = true;
    const m = new Date().getMonth() + 1;
    const y = new Date().getFullYear();

    const alumnos$ = this.alumnos.length
      ? of(this.alumnos)
      : this.adminService.getAlumnos().pipe(catchError(() => of([])));
    const doctores$ = this.doctores.length
      ? of(this.doctores)
      : this.adminService.getDoctores().pipe(catchError(() => of([])));
    const dias$ = this.diasEspeciales.length
      ? of(this.diasEspeciales)
      : this.calendarioService.getDias(m, y).pipe(catchError(() => of([])));

    forkJoin({ alumnos: alumnos$, doctores: doctores$, dias: dias$ })
      .pipe(
        takeUntil(this.destroy$),
        finalize(() => { this.isLoadingPanel = false; this.cdr.markForCheck(); })
      )
      .subscribe(({ alumnos, doctores, dias }) => {
        if (!this.alumnos.length) this.alumnos = alumnos as Alumno[];
        if (!this.doctores.length) this.doctores = doctores as Doctor[];
        if (!this.diasEspeciales.length) this.diasEspeciales = dias as DiaEspecial[];
        this.panelUsuarios = this.buildPanelUsuarios();
        this.diasProximos = this.buildDiasProximos();
        this.cdr.markForCheck();
      });
  }

  private buildPanelUsuarios(): UsuarioRow[] {
    return [
      ...this.alumnos.slice(0, 4).map(a => this.toAlumnoRow(a)),
      ...this.doctores.slice(0, 2).map(d => this.toDoctorRow(d))
    ];
  }

  private buildDiasProximos(): DiaEspecial[] {
    const today = new Date();
    const todayStr = `${today.getFullYear()}-${String(today.getMonth()+1).padStart(2,'0')}-${String(today.getDate()).padStart(2,'0')}`;
    return this.diasEspeciales.filter(d => d.fecha >= todayStr).slice(0, 3);
  }

  formatFechaDia(iso: string): string {
    const [y, m, d] = iso.split('-').map(Number);
    return new Intl.DateTimeFormat('es-MX', { day: 'numeric', month: 'short' }).format(new Date(y, m - 1, d));
  }

  // ===== USUARIOS =====

  private toAlumnoRow(a: Alumno): UsuarioRow {
    return {
      key: `a-${a.id}`, id: a.id,
      initials: `${a.nombre[0] ?? ''}${a.apellido[0] ?? ''}`.toUpperCase(),
      nombre: `${a.nombre} ${a.apellido}`, sub: a.numero_control,
      email: a.email, rol: 'alumno'
    };
  }

  private toDoctorRow(d: Doctor): UsuarioRow {
    return {
      key: `d-${d.id}`, id: d.id,
      initials: `${d.nombre[0] ?? ''}${d.apellido[0] ?? ''}`.toUpperCase(),
      nombre: `${d.nombre} ${d.apellido}`, sub: d.username,
      email: d.email, rol: 'doctor'
    };
  }

  // cambio 3: recalcula y cachea al cambiar datos, no en cada CD
  private updateRows(): void {
    this.alumnosRows = this.alumnos.map(a => this.toAlumnoRow(a));
    this.doctoresRows = this.doctores.map(d => this.toDoctorRow(d));
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

  editUsuario(row: UsuarioRow): void {
    if (row.rol === 'alumno') {
      const a = this.alumnos.find(x => x.id === row.id);
      if (a) this.openAlumnoForm(a);
    } else {
      const d = this.doctores.find(x => x.id === row.id);
      if (d) this.openDoctorForm(d);
    }
  }

  // ===== ALUMNOS =====

  loadAlumnos(): void {
    this.isLoadingAlumnos = true;
    this.alumnosError = null;
    this.adminService.getAlumnos()
      .pipe(
        takeUntil(this.destroy$),
        catchError(err => { this.alumnosError = err?.error?.message || 'Error al cargar alumnos.'; return of([]); }),
        finalize(() => { this.isLoadingAlumnos = false; this.cdr.markForCheck(); })
      )
      .subscribe(data => { this.alumnos = data; this.updateRows(); this.cdr.markForCheck(); });
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
      .subscribe(() => { if (tipo === 'alumno') this.loadAlumnos(); else this.loadDoctores(); });
  }

  // ===== DOCTORES =====

  loadDoctores(): void {
    this.isLoadingDoctores = true;
    this.doctoresError = null;
    this.adminService.getDoctores()
      .pipe(
        takeUntil(this.destroy$),
        catchError(err => { this.doctoresError = err?.error?.message || 'Error al cargar doctores.'; return of([]); }),
        finalize(() => { this.isLoadingDoctores = false; this.cdr.markForCheck(); })
      )
      .subscribe(data => { this.doctores = data; this.updateRows(); this.cdr.markForCheck(); });
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

  // ===== CALENDARIO =====

  // cambio 6: actualiza la propiedad solo cuando cambia el mes
  private updateCalLabel(): void {
    this.calLabel = new Intl.DateTimeFormat('es-MX', { month: 'long', year: 'numeric' }).format(this.calCurrentMonth);
  }

  changeCalMonth(dir: number): void {
    this.calCurrentMonth = new Date(this.calCurrentMonth.getFullYear(), this.calCurrentMonth.getMonth() + dir, 1);
    this.updateCalLabel();
    this.loadCalendario();
  }

  loadCalendario(): void {
    this.isLoadingCal = true;
    const m = this.calCurrentMonth.getMonth() + 1;
    const y = this.calCurrentMonth.getFullYear();
    this.calendarioService.getDias(m, y)
      .pipe(
        takeUntil(this.destroy$),
        catchError(() => of([])),
        finalize(() => { this.isLoadingCal = false; this.cdr.markForCheck(); })
      )
      .subscribe(dias => { this.diasEspeciales = dias; this.buildCalGrid(); this.cdr.markForCheck(); });
  }

  private buildCalGrid(): void {
    const ref = this.calCurrentMonth;
    const year = ref.getFullYear();
    const month = ref.getMonth();
    const dow = new Date(year, month, 1).getDay();
    const daysBack = dow === 0 ? 6 : dow - 1;
    const cursor = new Date(year, month, 1 - daysBack);
    const diasMap = new Map(this.diasEspeciales.map(d => [d.fecha, d]));
    const weeks: any[][] = [];
    for (let w = 0; w < 6; w++) {
      const week: any[] = [];
      while (week.length < 6) {
        if (cursor.getDay() !== 0) {
          const ds = `${cursor.getFullYear()}-${String(cursor.getMonth()+1).padStart(2,'0')}-${String(cursor.getDate()).padStart(2,'0')}`;
          week.push({ date: ds, label: cursor.getDate(), isCurrentMonth: cursor.getMonth() === month, diaEspecial: diasMap.get(ds) ?? null });
        }
        cursor.setDate(cursor.getDate() + 1);
      }
      weeks.push(week);
    }
    this.calWeeks = weeks;
  }

  selectCalDay(fecha: string): void {
    this.diaForm.fecha = fecha;
    const existing = this.diasEspeciales.find(d => d.fecha === fecha);
    if (existing) { this.diaForm.tipo = existing.tipo; this.diaForm.etiqueta = existing.etiqueta ?? ''; }
    else { this.diaForm.tipo = 'holiday'; this.diaForm.etiqueta = ''; }
  }

  resetDiaForm(): void { this.diaForm = { fecha: '', tipo: 'holiday', etiqueta: '' }; this.diaMsg = null; }

  submitDia(): void {
    if (!this.diaForm.fecha) { this.diaMsg = 'Selecciona una fecha.'; return; }
    this.isSubmittingDia = true;
    this.diaMsg = null;
    this.calendarioService.saveDia(this.diaForm.fecha, this.diaForm.tipo, this.diaForm.etiqueta)
      .pipe(
        takeUntil(this.destroy$),
        catchError(err => {
          this.diaMsg = err?.error?.message || 'Error al guardar.';
          this.cdr.markForCheck();
          return of(null);
        }),
        finalize(() => { this.isSubmittingDia = false; this.cdr.markForCheck(); })
      )
      .subscribe(res => {
        if (res) { this.diaMsg = 'Guardado correctamente.'; this.loadCalendario(); setTimeout(() => this.resetDiaForm(), 1200); }
      });
  }

  deleteDia(id: number): void {
    this.calendarioService.deleteDia(id)
      .pipe(takeUntil(this.destroy$), catchError(() => of(null)))
      .subscribe(() => this.loadCalendario());
  }
}
