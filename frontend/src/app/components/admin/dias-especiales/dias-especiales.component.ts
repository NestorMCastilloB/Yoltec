import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { Subject, of } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { AuthService } from '../../../services/auth.service';
import { AdminSidebarComponent } from '../shared/admin-sidebar.component';
import { DiasEspecialesService, DiaEspecialItem } from './dias-especiales.service';

interface CalDay {
  date: string;
  label: number;
  isCurrentMonth: boolean;
  dia: DiaEspecialItem | null;
}

@Component({
  selector: 'app-dias-especiales',
  standalone: true,
  imports: [CommonModule, FormsModule, AdminSidebarComponent],
  templateUrl: './dias-especiales.component.html',
  styleUrls: ['./dias-especiales.component.css']
})
export class DiasEspecialesComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();
  adminName = 'Administrador';

  dias: DiaEspecialItem[] = [];
  isLoading = false;

  // Calendario — solo Lun-Sáb
  readonly weekDays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
  calCurrentMonth = new Date(new Date().getFullYear(), new Date().getMonth(), 1);
  calRows: CalDay[][] = [];
  selectedDate = '';

  // Modal agregar
  showModalAgregar = false;
  form = { fecha: '', motivo: '' };
  formError: string | null = null;
  isSubmitting = false;

  // Modal eliminar
  confirmDeleteId: number | null = null;
  confirmDeleteMotivo = '';

  constructor(
    private router: Router,
    private authService: AuthService,
    private service: DiasEspecialesService
  ) {}

  ngOnInit(): void {
    const user = this.authService.getCurrentUser();
    this.adminName = user ? `${user.nombre} ${user.apellido}` : 'Administrador';
    this.loadDias();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  loadDias(): void {
    this.isLoading = true;
    this.service.getDias().pipe(
      takeUntil(this.destroy$),
      catchError(() => of([])),
      finalize(() => { this.isLoading = false; })
    ).subscribe(data => {
      this.dias = data;
      this.buildCalGrid();
    });
  }

  // ===== CALENDARIO =====

  get calLabel(): string {
    return new Intl.DateTimeFormat('es-MX', { month: 'long', year: 'numeric' }).format(this.calCurrentMonth);
  }

  changeMonth(dir: number): void {
    this.calCurrentMonth = new Date(
      this.calCurrentMonth.getFullYear(),
      this.calCurrentMonth.getMonth() + dir, 1
    );
    this.buildCalGrid();
  }

  private buildCalGrid(): void {
    const year = this.calCurrentMonth.getFullYear();
    const month = this.calCurrentMonth.getMonth();
    const dow = new Date(year, month, 1).getDay();
    const daysBack = dow === 0 ? 6 : dow - 1;
    const cursor = new Date(year, month, 1 - daysBack);

    const diasMap = new Map(this.dias.map(d => [d.fecha, d]));
    const rows: CalDay[][] = [];

    for (let week = 0; week < 6; week++) {
      const row: CalDay[] = [];
      for (let d = 0; d < 7; d++) {
        if (cursor.getDay() !== 0) {
          const ds = `${cursor.getFullYear()}-${String(cursor.getMonth()+1).padStart(2,'0')}-${String(cursor.getDate()).padStart(2,'0')}`;
          row.push({ date: ds, label: cursor.getDate(), isCurrentMonth: cursor.getMonth() === month, dia: diasMap.get(ds) ?? null });
        }
        cursor.setDate(cursor.getDate() + 1);
      }
      rows.push(row);
    }
    this.calRows = rows;
  }

  selectDay(day: CalDay): void {
    this.selectedDate = day.date;
    this.openModalAgregar(day.date);
  }

  // ===== MODAL AGREGAR =====

  openModalAgregar(fecha = ''): void {
    this.formError = null;
    this.form = { fecha, motivo: '' };
    this.showModalAgregar = true;
  }

  closeModalAgregar(): void {
    this.showModalAgregar = false;
    this.selectedDate = '';
    this.formError = null;
  }

  submitAgregar(): void {
    if (!this.form.fecha) { this.formError = 'Selecciona una fecha.'; return; }
    if (this.form.motivo.trim().length < 3) { this.formError = 'El motivo debe tener al menos 3 caracteres.'; return; }
    this.isSubmitting = true;
    this.formError = null;
    this.service.agregar(this.form.fecha, this.form.motivo.trim()).pipe(
      takeUntil(this.destroy$),
      catchError(err => { this.formError = err?.error?.message ?? 'Error al guardar.'; return of(null); }),
      finalize(() => { this.isSubmitting = false; })
    ).subscribe(res => {
      if (res) { this.closeModalAgregar(); this.loadDias(); }
    });
  }

  // ===== MODAL ELIMINAR =====

  askEliminar(dia: DiaEspecialItem): void {
    this.confirmDeleteId = dia.id;
    this.confirmDeleteMotivo = dia.motivo;
  }

  cancelEliminar(): void {
    this.confirmDeleteId = null;
    this.confirmDeleteMotivo = '';
  }

  confirmarEliminar(): void {
    if (!this.confirmDeleteId) return;
    const id = this.confirmDeleteId;
    this.cancelEliminar();
    this.service.eliminar(id).pipe(
      takeUntil(this.destroy$),
      catchError(() => of(null))
    ).subscribe(() => this.loadDias());
  }

  // ===== HELPERS =====

  // Convierte YYYY-MM-DD a formato legible en español
  formatFecha(fecha: string): string {
    const [y, m, d] = fecha.split('-').map(Number);
    return new Intl.DateTimeFormat('es-MX', { day: '2-digit', month: 'short', year: 'numeric' }).format(new Date(y, m - 1, d));
  }

  onSectionChange(section: string): void {
    if (section === 'panel') this.router.navigate(['/admin-dashboard']);
    if (section === 'usuarios') this.router.navigate(['/admin-usuarios']);
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/acceso-gestion']);
  }
}
