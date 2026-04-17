import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, NgForm } from '@angular/forms';
import { Subject, of } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { Cita, CitaService } from '../../../services/cita.service';
import { Receta, RecetaService, CreateRecetaPayload } from '../../../services/receta.service';

@Component({
  selector: 'app-doctor-recetas',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './doctor-recetas.component.html'
})
export class DoctorRecetasComponent implements OnInit, OnDestroy {
  citas: Cita[] = [];
  recetas: Receta[] = [];
  isLoadingRecetas = false;
  recetasError: string | null = null;
  showRecetaForm = false;
  isSubmittingReceta = false;
  recetaMessage: string | null = null;
  editingRecetaId: number | null = null;
  recetaFormData: Partial<CreateRecetaPayload> = this.emptyForm();

  readonly PAGE_SIZE = 10;
  currentPageRecetas = 1;

  get pagedRecetas(): Receta[] {
    const start = (this.currentPageRecetas - 1) * this.PAGE_SIZE;
    return this.recetas.slice(start, start + this.PAGE_SIZE);
  }
  get totalPagesRecetas(): number { return Math.ceil(this.recetas.length / this.PAGE_SIZE) || 1; }

  get availableCitasForReceta(): Cita[] {
    if (this.editingRecetaId !== null) return this.citas.filter(c => c.estatus === 'atendida');
    const ids = new Set(this.recetas.map(r => r.cita_id));
    return this.citas.filter(c => c.estatus === 'atendida' && !ids.has(c.id));
  }

  private destroy$ = new Subject<void>();

  constructor(private citaService: CitaService, private recetaService: RecetaService) {}

  ngOnInit(): void {
    this.loadCitas();
    this.loadRecetas();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  toggleRecetaForm(): void {
    this.showRecetaForm = !this.showRecetaForm;
    this.recetaMessage = null;
    if (!this.showRecetaForm) {
      this.editingRecetaId = null;
      this.recetaFormData = this.emptyForm();
    }
  }

  prevPageRecetas(): void { if (this.currentPageRecetas > 1) this.currentPageRecetas--; }
  nextPageRecetas(): void { if (this.currentPageRecetas < this.totalPagesRecetas) this.currentPageRecetas++; }

  onRecetaCitaChange(citaId: number | string): void {
    const cita = this.citas.find(c => c.id === Number(citaId));
    if (cita) this.recetaFormData.fecha_emision = cita.fecha_cita;
  }

  startEditReceta(receta: Receta): void {
    this.showRecetaForm = true;
    this.editingRecetaId = receta.id;
    this.recetaMessage = null;
    this.recetaFormData = {
      cita_id: receta.cita_id,
      medicamentos: receta.medicamentos,
      indicaciones: receta.indicaciones || '',
      fecha_emision: receta.fecha_emision
    };
  }

  onCreateReceta(form: NgForm): void {
    if (form.invalid) {
      if (!this.recetaFormData.cita_id) this.recetaMessage = 'Selecciona la cita atendida correspondiente.';
      else if (!this.recetaFormData.medicamentos?.trim()) this.recetaMessage = 'Captura los medicamentos recetados.';
      else if (!this.recetaFormData.indicaciones?.trim()) this.recetaMessage = 'Captura las indicaciones para el paciente.';
      else if (!this.recetaFormData.fecha_emision) this.recetaMessage = 'Selecciona la fecha de emisión.';
      else this.recetaMessage = 'Por favor completa todos los campos.';
      return;
    }

    const payload: CreateRecetaPayload = {
      cita_id: Number(this.recetaFormData.cita_id),
      medicamentos: this.recetaFormData.medicamentos!.trim(),
      indicaciones: this.recetaFormData.indicaciones?.trim() || undefined,
      fecha_emision: this.recetaFormData.fecha_emision || this.formatDate(new Date())
    };

    this.isSubmittingReceta = true;
    this.recetaMessage = null;

    const request$ = this.editingRecetaId
      ? this.recetaService.updateReceta(this.editingRecetaId, payload)
      : this.recetaService.createReceta(payload);

    request$.pipe(
      takeUntil(this.destroy$),
      catchError(error => {
        const errores = error?.error?.errors;
        if (errores) {
          const first = Object.keys(errores)[0];
          const msgs = (errores as any)[first];
          if (Array.isArray(msgs) && msgs.length > 0) { this.recetaMessage = msgs[0]; return of(null); }
        }
        this.recetaMessage = error?.error?.message || 'No se pudo registrar la receta.';
        return of(null);
      }),
      finalize(() => { this.isSubmittingReceta = false; })
    ).subscribe(response => {
      if (response?.receta) {
        this.recetaMessage = this.editingRecetaId ? 'Receta actualizada.' : 'Receta registrada.';
        this.loadRecetas();
        this.editingRecetaId = null;
        this.recetaFormData = this.emptyForm();
        this.showRecetaForm = false;
      }
    });
  }

  formatDateDisplay(fecha: string): string {
    const [year, month, day] = fecha.split('-').map(Number);
    return new Intl.DateTimeFormat('es-MX', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })
      .format(new Date(year, (month ?? 1) - 1, day ?? 1));
  }

  formatTime(hora: string): string {
    const [h, m] = hora.split(':').map(Number);
    const d = new Date();
    d.setHours(h, m || 0, 0, 0);
    return new Intl.DateTimeFormat('es-MX', { hour: '2-digit', minute: '2-digit', hour12: false }).format(d);
  }

  formatRecetaDate(fecha: string): string {
    return new Intl.DateTimeFormat('es-MX', { dateStyle: 'medium' }).format(new Date(fecha));
  }

  private loadCitas(): void {
    this.citaService.getCitas()
      .pipe(takeUntil(this.destroy$), catchError(() => of([] as Cita[])))
      .subscribe(citas => { this.citas = citas; });
  }

  private loadRecetas(): void {
    if (this.isLoadingRecetas) return;
    this.isLoadingRecetas = true;
    this.recetasError = null;
    this.recetaService.getRecetas()
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => { this.recetasError = error?.error?.message || 'No se pudieron obtener las recetas.'; return of([] as Receta[]); }),
        finalize(() => { this.isLoadingRecetas = false; })
      )
      .subscribe(recetas => {
        this.recetas = [...recetas].sort((a, b) => new Date(b.fecha_emision).getTime() - new Date(a.fecha_emision).getTime());
        this.currentPageRecetas = 1;
      });
  }

  private formatDate(date: Date): string {
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
  }

  private emptyForm(): Partial<CreateRecetaPayload> {
    return { cita_id: undefined, medicamentos: '', indicaciones: '', fecha_emision: this.formatDate(new Date()) };
  }
}
