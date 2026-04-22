import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, NgForm } from '@angular/forms';
import { Subject, of } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { Cita, CitaService } from '../../../services/cita.service';
import { Bitacora, BitacoraService, CreateBitacoraPayload } from '../../../services/bitacora.service';

@Component({
  selector: 'app-doctor-bitacoras',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './doctor-bitacoras.component.html',
  styleUrls: ['./doctor-bitacoras.component.css']   // ← Asegúrate de que esté
})

export class DoctorBitacorasComponent implements OnInit, OnDestroy {
  citas: Cita[] = [];
  bitacoras: Bitacora[] = [];
  isLoadingBitacoras = false;
  bitacorasError: string | null = null;
  filtrosBitacora = { fecha_desde: '', fecha_hasta: '', alumno: '' };
  showBitacoraForm = false;
  isSubmittingBitacora = false;
  bitacoraMessage: string | null = null;
  editingBitacoraId: number | null = null;
  bitacoraFormData: Partial<CreateBitacoraPayload> = this.emptyForm();

  readonly PAGE_SIZE = 6;
  currentPageBitacoras = 1;

  get pagedBitacoras(): Bitacora[] {
    const start = (this.currentPageBitacoras - 1) * this.PAGE_SIZE;
    return this.bitacoras.slice(start, start + this.PAGE_SIZE);
  }
  get totalPagesBitacoras(): number { return Math.ceil(this.bitacoras.length / this.PAGE_SIZE) || 1; }

  get availableCitasForBitacora(): Cita[] {
    const ids = new Set(this.bitacoras.map(b => b.cita_id));
    return this.citas.filter(c => c.estatus === 'atendida' && !ids.has(c.id));
  }

  private destroy$ = new Subject<void>();

  constructor(private citaService: CitaService, private bitacoraService: BitacoraService) { }

  ngOnInit(): void {
    this.loadCitas();
    this.loadBitacoras();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  toggleBitacoraForm(): void {
    this.showBitacoraForm = !this.showBitacoraForm;
    this.bitacoraMessage = null;
    if (!this.showBitacoraForm) {
      this.editingBitacoraId = null;
      this.bitacoraFormData = this.emptyForm();
    }
  }

  aplicarFiltrosBitacora(): void {
    this.currentPageBitacoras = 1;
    this.loadBitacoras();
  }

  limpiarFiltrosBitacora(): void {
    this.filtrosBitacora = { fecha_desde: '', fecha_hasta: '', alumno: '' };
    this.currentPageBitacoras = 1;
    this.loadBitacoras();
  }

  prevPageBitacoras(): void { if (this.currentPageBitacoras > 1) this.currentPageBitacoras--; }
  nextPageBitacoras(): void { if (this.currentPageBitacoras < this.totalPagesBitacoras) this.currentPageBitacoras++; }

  startEditBitacora(bitacora: Bitacora): void {
    this.showBitacoraForm = true;
    this.editingBitacoraId = bitacora.id;
    this.bitacoraMessage = null;
    this.bitacoraFormData = {
      cita_id: bitacora.cita_id,
      diagnostico: bitacora.diagnostico || '',
      tratamiento: bitacora.tratamiento || '',
      observaciones: bitacora.observaciones || '',
      peso: bitacora.peso || '',
      altura: bitacora.altura || '',
      temperatura: bitacora.temperatura || '',
      presion_arterial: bitacora.presion_arterial || ''
    };
  }

  onCreateBitacora(form: NgForm): void {
    if (form.invalid) {
      this.bitacoraMessage = !this.bitacoraFormData.cita_id
        ? 'Selecciona la cita atendida correspondiente.'
        : 'Por favor completa todos los campos obligatorios.';
      return;
    }

    const payload: CreateBitacoraPayload = {
      cita_id: Number(this.bitacoraFormData.cita_id),
      diagnostico: this.bitacoraFormData.diagnostico || undefined,
      tratamiento: this.bitacoraFormData.tratamiento || undefined,
      observaciones: this.bitacoraFormData.observaciones || undefined,
      peso: this.bitacoraFormData.peso || undefined,
      altura: this.bitacoraFormData.altura || undefined,
      temperatura: this.bitacoraFormData.temperatura || undefined,
      presion_arterial: this.bitacoraFormData.presion_arterial || undefined
    };

    this.isSubmittingBitacora = true;
    this.bitacoraMessage = null;

    const request$ = this.editingBitacoraId
      ? this.bitacoraService.updateBitacora(this.editingBitacoraId, payload)
      : this.bitacoraService.createBitacora(payload);

    request$.pipe(
      takeUntil(this.destroy$),
      catchError(error => {
        const errores = error?.error?.errors;
        if (errores) {
          const first = Object.keys(errores)[0];
          const msgs = (errores as any)[first];
          if (Array.isArray(msgs) && msgs.length > 0) { this.bitacoraMessage = msgs[0]; return of(null); }
        }
        this.bitacoraMessage = error?.error?.message || 'No se pudo registrar la bitácora.';
        return of(null);
      }),
      finalize(() => { this.isSubmittingBitacora = false; })
    ).subscribe(response => {
      if (response?.bitacora) {
        this.bitacoraMessage = this.editingBitacoraId ? 'Bitácora actualizada.' : 'Bitácora registrada.';
        this.loadBitacoras();
        this.editingBitacoraId = null;
        this.bitacoraFormData = this.emptyForm();
        this.showBitacoraForm = false;
      }
    });
  }

  exportBitacorasCSV(): void {
    const headers = ['Fecha Cita', 'Alumno', 'Diagnóstico', 'Tratamiento', 'Observaciones', 'Peso', 'Altura', 'Temperatura', 'Presión Arterial', 'Registrada'];
    const rows = this.bitacoras.map(b => [
      b.cita?.fecha_cita ?? '',
      `${b.alumno?.nombre ?? ''} ${b.alumno?.apellido ?? ''}`.trim(),
      b.diagnostico ?? '', b.tratamiento ?? '', b.observaciones ?? '',
      b.peso ?? '', b.altura ?? '', b.temperatura ?? '', b.presion_arterial ?? '',
      b.created_at ? new Date(b.created_at).toLocaleDateString('es-MX') : ''
    ].map(v => `"${String(v).replace(/"/g, '""')}"`));

    const csv = [headers.join(','), ...rows.map(r => r.join(','))].join('\n');
    const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `bitacoras_${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
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

  formatBitacoraDate(fecha: string): string {
    return new Intl.DateTimeFormat('es-MX', { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(fecha));
  }

  private loadCitas(): void {
    this.citaService.getCitas()
      .pipe(takeUntil(this.destroy$), catchError(() => of([] as Cita[])))
      .subscribe(citas => { this.citas = citas; });
  }

  private loadBitacoras(): void {
    if (this.isLoadingBitacoras) return;
    this.isLoadingBitacoras = true;
    this.bitacorasError = null;
    const filtros = {
      fecha_desde: this.filtrosBitacora.fecha_desde || undefined,
      fecha_hasta: this.filtrosBitacora.fecha_hasta || undefined,
      alumno: this.filtrosBitacora.alumno || undefined
    };
    this.bitacoraService.getBitacoras(filtros)
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => { this.bitacorasError = error?.error?.message || 'No se pudieron obtener las bitácoras.'; return of([] as Bitacora[]); }),
        finalize(() => { this.isLoadingBitacoras = false; })
      )
      .subscribe(bitacoras => {
        this.bitacoras = [...bitacoras].sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
      });
  }

  private emptyForm(): Partial<CreateBitacoraPayload> {
    return { cita_id: undefined, diagnostico: '', tratamiento: '', observaciones: '', peso: '', altura: '', temperatura: '', presion_arterial: '' };
  }
}
