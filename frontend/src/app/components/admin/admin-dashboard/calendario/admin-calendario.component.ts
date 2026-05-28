import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, OnDestroy, OnInit, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subject, of } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { CalendarioAdminService, DiaEspecial, TIPO_LABELS } from '../../../../services/calendario-admin.service';
import { CalendarCellAdmin, buildCalGridAdmin, formatFechaDia } from '../admin-utils';

@Component({
  selector: 'app-admin-calendario',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './admin-calendario.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AdminCalendarioComponent implements OnInit, OnDestroy {
  @Output() changed = new EventEmitter<DiaEspecial[]>();

  readonly tipoLabels = TIPO_LABELS;
  readonly weekDays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
  readonly formatFechaDia = formatFechaDia;

  calCurrentMonth = new Date(new Date().getFullYear(), new Date().getMonth(), 1);
  calLabel = '';
  calWeeks: CalendarCellAdmin[][] = [];
  diasEspeciales: DiaEspecial[] = [];
  isLoadingCal = false;
  diaForm = { fecha: '', tipo: 'holiday', etiqueta: '', hora_cierre: '' };
  diaMsg: string | null = null;
  isSubmittingDia = false;

  private destroy$ = new Subject<void>();

  constructor(private calendarioService: CalendarioAdminService, private cdr: ChangeDetectorRef) {
    this.updateCalLabel();
  }

  ngOnInit(): void {
    this.loadCalendario();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
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
      .subscribe(dias => {
        this.diasEspeciales = dias;
        this.calWeeks = buildCalGridAdmin(this.calCurrentMonth, dias);
        this.changed.emit(dias);
        this.cdr.markForCheck();
      });
  }

  selectCalDay(fecha: string, isPast = false, hasDia = false): void {
    if (isPast && !hasDia) return;
    this.diaForm.fecha = fecha;
    const existing = this.diasEspeciales.find(d => d.fecha === fecha);
    if (existing) {
      this.diaForm.tipo = existing.tipo;
      this.diaForm.etiqueta = existing.etiqueta ?? '';
      this.diaForm.hora_cierre = existing.hora_cierre ?? '';
    } else {
      this.diaForm.tipo = 'holiday';
      this.diaForm.etiqueta = '';
      this.diaForm.hora_cierre = '';
    }
  }

  resetDiaForm(): void {
    this.diaForm = { fecha: '', tipo: 'holiday', etiqueta: '', hora_cierre: '' };
    this.diaMsg = null;
  }

  submitDia(): void {
    if (!this.diaForm.fecha) { this.diaMsg = 'Selecciona una fecha.'; return; }
    if (this.diaForm.tipo === 'reduced' && !this.diaForm.hora_cierre) {
      this.diaMsg = 'Especifica la hora de cierre para un día de horario reducido.';
      return;
    }
    this.isSubmittingDia = true;
    this.diaMsg = null;
    this.calendarioService.saveDia(this.diaForm.fecha, this.diaForm.tipo, this.diaForm.etiqueta, this.diaForm.hora_cierre || null)
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

  private updateCalLabel(): void {
    this.calLabel = new Intl.DateTimeFormat('es-MX', { month: 'long', year: 'numeric' }).format(this.calCurrentMonth);
  }
}
