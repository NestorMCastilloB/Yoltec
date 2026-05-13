import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { Subject, of } from 'rxjs';
import { catchError, debounceTime, distinctUntilChanged, finalize, takeUntil } from 'rxjs/operators';
import { AuthService } from '../../../services/auth.service';
import { AdminSidebarComponent } from '../shared/admin-sidebar.component';
import { UsuariosService, Usuario } from './usuarios.service';

type Tab = 'todos' | 'alumnos' | 'doctores' | 'suspendidos';

@Component({
  selector: 'app-usuarios',
  standalone: true,
  imports: [CommonModule, FormsModule, AdminSidebarComponent],
  templateUrl: './usuarios.component.html',
  styleUrls: ['./usuarios.component.css']
})
export class UsuariosComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  private search$ = new Subject<string>();

  adminName = 'Administrador';
  activeTab: Tab = 'todos';

  // Tabla
  usuarios: Usuario[] = [];
  isLoading = false;
  total = 0;
  from = 0;
  to = 0;
  currentPage = 1;
  lastPage = 1;

  // Contadores por tab (se actualiza al cambiar de tab)
  counts: Record<Tab, number> = { todos: 0, alumnos: 0, doctores: 0, suspendidos: 0 };

  // Búsqueda
  searchTerm = '';

  // Checkboxes
  selectedIds = new Set<number>();
  allChecked = false;

  // Modal confirmar suspensión
  confirmSuspendId: number | null = null;
  confirmSuspendNombre = '';

  // Modal nuevo / editar usuario
  showUserModal = false;
  editingUserId: number | null = null;
  userForm = { nombre: '', apellido: '', email: '', rol: 'alumno', numero_control: '' };
  userMsg: string | null = null;
  isSubmitting = false;

  constructor(
    private router: Router,
    private authService: AuthService,
    private usuariosService: UsuariosService
  ) {}

  ngOnInit(): void {
    const user = this.authService.getCurrentUser();
    this.adminName = user ? `${user.nombre} ${user.apellido}` : 'Administrador';
    this.search$.pipe(
      debounceTime(300),
      distinctUntilChanged(),
      takeUntil(this.destroy$)
    ).subscribe(() => { this.currentPage = 1; this.loadUsuarios(); });
    this.loadTodos();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  // Carga inicial: todos los tabs para tener contadores
  private loadTodos(): void {
    this.loadUsuarios();
    // Precarga contadores de otros tabs
    (['alumnos', 'doctores', 'suspendidos'] as Tab[]).forEach(tab => {
      const params: any = {};
      if (tab === 'alumnos') params.rol = 'alumno';
      if (tab === 'doctores') params.rol = 'doctor';
      if (tab === 'suspendidos') params.suspendido = true;
      this.usuariosService.getUsuarios({ ...params, page: 1 })
        .pipe(takeUntil(this.destroy$), catchError(() => of(null)))
        .subscribe(res => { if (res) this.counts[tab] = res.total; });
    });
  }

  onSearch(term: string): void {
    this.searchTerm = term;
    this.search$.next(term);
  }

  setTab(tab: Tab): void {
    this.activeTab = tab;
    this.currentPage = 1;
    this.selectedIds.clear();
    this.allChecked = false;
    this.loadUsuarios();
  }

  loadUsuarios(): void {
    this.isLoading = true;
    const params: any = { page: this.currentPage };
    if (this.searchTerm.trim()) params.search = this.searchTerm.trim();
    if (this.activeTab === 'alumnos') params.rol = 'alumno';
    if (this.activeTab === 'doctores') params.rol = 'doctor';
    if (this.activeTab === 'suspendidos') params.suspendido = true;

    this.usuariosService.getUsuarios(params).pipe(
      takeUntil(this.destroy$),
      catchError(() => of(null)),
      finalize(() => { this.isLoading = false; })
    ).subscribe(res => {
      if (res) {
        this.usuarios = res.data;
        this.total = res.total;
        this.from = res.from ?? 0;
        this.to = res.to ?? 0;
        this.currentPage = res.current_page;
        this.lastPage = res.last_page;
        this.counts[this.activeTab] = res.total;
      }
    });
  }

  goToPage(page: number): void {
    if (page < 1 || page > this.lastPage) return;
    this.currentPage = page;
    this.loadUsuarios();
  }

  get visiblePages(): number[] {
    const pages: number[] = [];
    for (let i = 1; i <= Math.min(this.lastPage, 8); i++) pages.push(i);
    return pages;
  }

  // Checkboxes
  toggleAll(checked: boolean): void {
    this.allChecked = checked;
    if (checked) this.usuarios.forEach(u => this.selectedIds.add(u.id));
    else this.selectedIds.clear();
  }

  toggleOne(id: number, checked: boolean): void {
    checked ? this.selectedIds.add(id) : this.selectedIds.delete(id);
    this.allChecked = this.usuarios.length > 0 && this.usuarios.every(u => this.selectedIds.has(u.id));
  }

  isSelected(id: number): boolean { return this.selectedIds.has(id); }

  // Helpers visuales
  initials(u: Usuario): string {
    return `${u.nombre?.[0] ?? ''}${u.apellido?.[0] ?? ''}`.toUpperCase();
  }

  identificador(u: Usuario): string {
    return u.rol === 'doctor' ? (u.username ?? '') : (u.numero_control ?? '');
  }

  formatFecha(fecha?: string): string {
    if (!fecha) return '—';
    const d = new Date(fecha);
    const hoy = new Date();
    const ayer = new Date(hoy); ayer.setDate(hoy.getDate() - 1);
    const hhmm = `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
    if (d.toDateString() === hoy.toDateString()) return `Hoy, ${hhmm}`;
    if (d.toDateString() === ayer.toDateString()) return `Ayer, ${hhmm}`;
    return new Intl.DateTimeFormat('es-MX', { day: '2-digit', month: 'short' }).format(d) + `, ${hhmm}`;
  }

  // Suspender
  askSuspender(u: Usuario): void {
    this.confirmSuspendId = u.id;
    this.confirmSuspendNombre = `${u.nombre} ${u.apellido}`;
  }

  cancelSuspender(): void {
    this.confirmSuspendId = null;
    this.confirmSuspendNombre = '';
  }

  confirmarSuspender(): void {
    if (!this.confirmSuspendId) return;
    const id = this.confirmSuspendId;
    this.cancelSuspender();
    this.usuariosService.suspender(id).pipe(
      takeUntil(this.destroy$),
      catchError(() => of(null))
    ).subscribe(() => this.loadUsuarios());
  }

  reactivar(id: number): void {
    this.usuariosService.reactivar(id).pipe(
      takeUntil(this.destroy$),
      catchError(() => of(null))
    ).subscribe(() => this.loadUsuarios());
  }

  // Modal usuario
  openUserModal(u?: Usuario): void {
    this.userMsg = null;
    if (u) {
      this.editingUserId = u.id;
      this.userForm = { nombre: u.nombre, apellido: u.apellido, email: u.email, rol: u.rol, numero_control: u.numero_control ?? '' };
    } else {
      this.editingUserId = null;
      this.userForm = { nombre: '', apellido: '', email: '', rol: 'alumno', numero_control: '' };
    }
    this.showUserModal = true;
  }

  closeUserModal(): void {
    this.showUserModal = false;
    this.editingUserId = null;
    this.userMsg = null;
  }

  submitUser(): void {
    this.isSubmitting = true;
    this.userMsg = null;
    const req$ = this.editingUserId
      ? this.usuariosService.actualizarUsuario(this.editingUserId, this.userForm)
      : this.usuariosService.crearUsuario(this.userForm);

    req$.pipe(
      takeUntil(this.destroy$),
      catchError(err => {
        const errors = err?.error?.errors;
        this.userMsg = errors
          ? (Object.values(errors)[0] as string[])[0]
          : (err?.error?.message ?? 'Error al guardar.');
        return of(null);
      }),
      finalize(() => { this.isSubmitting = false; })
    ).subscribe(res => {
      if (res) {
        this.userMsg = this.editingUserId ? 'Usuario actualizado.' : 'Usuario creado.';
        this.loadUsuarios();
        setTimeout(() => this.closeUserModal(), 1000);
      }
    });
  }

  // Navegación sidebar
  onSectionChange(section: string): void {
    if (section === 'panel') this.router.navigate(['/admin-dashboard']);
    if (section === 'calendario') this.router.navigate(['/admin-dias-especiales']);
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/acceso-gestion']);
  }
}
