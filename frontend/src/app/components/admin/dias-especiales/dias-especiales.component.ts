import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { Subject, of } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { AuthService } from '../../../services/auth.service';
import { AdminSidebarComponent } from '../shared/admin-sidebar.component';
import { DiasEspecialesService, DiaEspecialItem, TipoDiaEspecial } from './dias-especiales.service';

interface CalDay {
  date: string;
  label: number;
  isCurrentMonth: boolean;
  isPast: boolean;
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
  form: { fecha: string; tipo: TipoDiaEspecial; etiqueta: string } = { fecha: '', tipo: 'holiday', etiqueta: '' };
  formError: string | null = null;
  isSubmitting = false;

  // Catálogo de tipos para el select
  readonly tiposDia: { value: TipoDiaEspecial; label: string }[] = [
    { value: 'holiday',  label: 'Festivo (sin atención)' },
    { value: 'vacation', label: 'Vacaciones (sin atención)' },
    { value: 'reduced',  label: 'Horario reducido' },
  ];

  // Modal eliminar
  confirmDeleteId: number | null = null;
  confirmDeleteEtiqueta = '';

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
    const month = this.calCurrentMonth.getMonth() + 1;
    const year = this.calCurrentMonth.getFullYear();
    this.service.getDias(month, year).pipe(
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
    this.loadDias();
  }

  private buildCalGrid(): void {
    const year = this.calCurrentMonth.getFullYear();
    const month = this.calCurrentMonth.getMonth();
    const dow = new Date(year, month, 1).getDay();
    const daysBack = dow === 0 ? 6 : dow - 1;
    const cursor = new Date(year, month, 1 - daysBack);

    const today = new Date();
    const todayStr = `${today.getFullYear()}-${String(today.getMonth()+1).padStart(2,'0')}-${String(today.getDate()).padStart(2,'0')}`;

    const diasMap = new Map(this.dias.map(d => [d.fecha, d]));
    const rows: CalDay[][] = [];

    for (let week = 0; week < 6; week++) {
      const row: CalDay[] = [];
      for (let d = 0; d < 7; d++) {
        if (cursor.getDay() !== 0) {
          const ds = `${cursor.getFullYear()}-${String(cursor.getMonth()+1).padStart(2,'0')}-${String(cursor.getDate()).padStart(2,'0')}`;
          row.push({
            date: ds,
            label: cursor.getDate(),
            isCurrentMonth: cursor.getMonth() === month,
            isPast: ds < todayStr,
            dia: diasMap.get(ds) ?? null
          });
        }
        cursor.setDate(cursor.getDate() + 1);
      }
      rows.push(row);
    }
    this.calRows = rows;
  }

  selectDay(day: CalDay): void {
    if (day.isPast && !day.dia) return;
    this.selectedDate = day.date;
    this.openModalAgregar(day.date);
  }

  // ===== MODAL AGREGAR =====

  openModalAgregar(fecha = ''): void {
    this.formError = null;
    this.form = { fecha, tipo: 'holiday', etiqueta: '' };
    this.showModalAgregar = true;
  }

  closeModalAgregar(): void {
    this.showModalAgregar = false;
    this.selectedDate = '';
    this.formError = null;
  }

  submitAgregar(): void {
    if (!this.form.fecha) { this.formError = 'Selecciona una fecha.'; return; }
    if (!this.form.tipo) { this.formError = 'Selecciona el tipo de día.'; return; }
    this.isSubmitting = true;
    this.formError = null;
    this.service.agregar({
      fecha: this.form.fecha,
      tipo: this.form.tipo,
      etiqueta: this.form.etiqueta.trim() || null,
    }).pipe(
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
    this.confirmDeleteEtiqueta = dia.etiqueta || this.tipoLabel(dia.tipo);
  }

  cancelEliminar(): void {
    this.confirmDeleteId = null;
    this.confirmDeleteEtiqueta = '';
  }

  tipoLabel(tipo: TipoDiaEspecial): string {
    return this.tiposDia.find(t => t.value === tipo)?.label ?? tipo;
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
