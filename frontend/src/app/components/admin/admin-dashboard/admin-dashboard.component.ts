import { ChangeDetectionStrategy, ChangeDetectorRef, Component, HostListener, OnDestroy, OnInit, ViewEncapsulation } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { Subject, forkJoin, of } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { AuthService } from '../../../services/auth.service';
import { ThemeService } from '../../../services/theme.service';
import { AdminService, Alumno, Doctor } from '../../../services/admin.service';
import { CalendarioAdminService, DiaEspecial } from '../../../services/calendario-admin.service';
import { AdminDashboardService, AdminStats } from '../dashboard/admin-dashboard.service';
import { AdminSidebarComponent } from '../shared/admin-sidebar.component';
import { PollingService } from '../../../services/polling.service';
import { UsuarioRow, filterDiasProximos, toAlumnoRow, toDoctorRow } from './admin-utils';
import { AdminPanelComponent } from './panel/admin-panel.component';
import { AdminUsuariosComponent } from './usuarios/admin-usuarios.component';
import { AdminCalendarioComponent } from './calendario/admin-calendario.component';

@Component({
  selector: 'app-admin-dashboard',
  standalone: true,
  imports: [
    CommonModule,
    AdminSidebarComponent,
    AdminPanelComponent,
    AdminUsuariosComponent,
    AdminCalendarioComponent,
  ],
  templateUrl: './admin-dashboard.component.html',
  styleUrls: ['./admin-dashboard.component.css'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
})
export class AdminDashboardComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  activeSection: 'panel' | 'usuarios' | 'calendario' = 'panel';
  adminName = 'Administrador';
  userMenuOpen = false;

  stats: AdminStats | null = null;
  isLoadingStats = false;
  panelUsuarios: UsuarioRow[] = [];
  diasProximos: DiaEspecial[] = [];
  isLoadingPanel = false;

  private alumnosCache: Alumno[] = [];
  private doctoresCache: Doctor[] = [];
  private diasCache: DiaEspecial[] = [];

  readonly fechaHoy = new Intl.DateTimeFormat('es-MX', {
    weekday: 'long', day: 'numeric', month: 'long', year: 'numeric',
  }).format(new Date());

  constructor(
    private router: Router,
    private authService: AuthService,
    public themeService: ThemeService,
    private adminService: AdminService,
    private calendarioService: CalendarioAdminService,
    private dashboardService: AdminDashboardService,
    private cdr: ChangeDetectorRef,
    private polling: PollingService,
  ) {}

  ngOnInit(): void {
    const user = this.authService.getCurrentUser();
    this.adminName = user ? `${user.nombre} ${user.apellido}` : 'Administrador';
    this.loadStats();
    this.loadPanelPreview();
    this.polling.poll(60).pipe(takeUntil(this.destroy$)).subscribe(() => this.loadStats());
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  get adminInitial(): string { return this.adminName.charAt(0).toUpperCase(); }

  get sectionTitle(): string {
    const titles: Record<string, string> = {
      panel: 'Panel de administración',
      usuarios: 'Gestión de usuarios',
      calendario: 'Días especiales',
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

  setSection(section: string): void {
    this.activeSection = section as 'panel' | 'usuarios' | 'calendario';
    if (section === 'panel') {
      if (!this.stats) this.loadStats();
      if (this.alumnosCache.length || this.doctoresCache.length || this.diasCache.length) {
        this.rebuildPanelData();
      } else {
        this.loadPanelPreview();
      }
    }
  }

  onUsuariosChanged(data: { alumnos: Alumno[]; doctores: Doctor[] }): void {
    this.alumnosCache = data.alumnos;
    this.doctoresCache = data.doctores;
    this.rebuildPanelData();
  }

  onCalendarioChanged(dias: DiaEspecial[]): void {
    this.diasCache = dias;
    this.rebuildPanelData();
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/login']);
  }

  private loadStats(): void {
    this.isLoadingStats = true;
    this.dashboardService.getStats()
      .pipe(
        takeUntil(this.destroy$),
        catchError(() => of(null)),
        finalize(() => { this.isLoadingStats = false; this.cdr.markForCheck(); })
      )
      .subscribe(data => { this.stats = data; this.cdr.markForCheck(); });
  }

  private loadPanelPreview(): void {
    this.isLoadingPanel = true;
    const m = new Date().getMonth() + 1;
    const y = new Date().getFullYear();

    const alumnos$ = this.alumnosCache.length
      ? of(this.alumnosCache)
      : this.adminService.getAlumnos().pipe(catchError(() => of([])));
    const doctores$ = this.doctoresCache.length
      ? of(this.doctoresCache)
      : this.adminService.getDoctores().pipe(catchError(() => of([])));
    const dias$ = this.diasCache.length
      ? of(this.diasCache)
      : this.calendarioService.getDias(m, y).pipe(catchError(() => of([])));

    forkJoin({ alumnos: alumnos$, doctores: doctores$, dias: dias$ })
      .pipe(
        takeUntil(this.destroy$),
        finalize(() => { this.isLoadingPanel = false; this.cdr.markForCheck(); })
      )
      .subscribe(({ alumnos, doctores, dias }) => {
        if (!this.alumnosCache.length) this.alumnosCache = alumnos as Alumno[];
        if (!this.doctoresCache.length) this.doctoresCache = doctores as Doctor[];
        if (!this.diasCache.length) this.diasCache = dias as DiaEspecial[];
        this.rebuildPanelData();
      });
  }

  private rebuildPanelData(): void {
    this.panelUsuarios = [
      ...this.alumnosCache.slice(0, 4).map(a => toAlumnoRow(a)),
      ...this.doctoresCache.slice(0, 2).map(d => toDoctorRow(d)),
    ];
    this.diasProximos = filterDiasProximos(this.diasCache, 3);
    this.cdr.markForCheck();
  }
}
