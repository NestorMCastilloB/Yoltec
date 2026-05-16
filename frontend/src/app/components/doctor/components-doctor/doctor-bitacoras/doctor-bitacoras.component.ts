import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, NgForm } from '@angular/forms';
import { Subject, of } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { Cita, CitaService } from '../../../../services/cita.service';
import { Bitacora, BitacoraService, CreateBitacoraPayload } from '../../../../services/bitacora.service';

@Component({
  selector: 'app-doctor-bitacoras',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './doctor-bitacoras.component.html',
  styleUrls: ['./doctor-bitacoras.component.css']
})
export class DoctorBitacorasComponent implements OnInit, OnDestroy {
  citas: Cita[] = [];
  bitacoras: Bitacora[] = [];
  isLoadingBitacoras = false;
  bitacorasError: string | null = null;
  busquedaAlumno = '';

  // Drawer
  drawerAbierto = false;
  drawerModo: 'vista' | 'form' = 'vista';
  drawerBitacora: Bitacora | null = null;
  editandoId: number | null = null;
  bitacoraFormData: Partial<CreateBitacoraPayload> = this.emptyForm();
  isSubmitting = false;
  mensajeForm: string | null = null;

  readonly PAGE_SIZE = 10;
  currentPage = 1;

  private destroy$ = new Subject<void>();

  constructor(private citaService: CitaService, private bitacoraService: BitacoraService) {}

  ngOnInit(): void {
    this.loadCitas();
    this.loadBitacoras();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  // --- KPIs (computados del array cargado) ---

  get bitacorasDelMes(): number {
    const ahora = new Date();
    return this.bitacoras.filter(b => {
      const f = new Date(b.created_at);
      return f.getMonth() === ahora.getMonth() && f.getFullYear() === ahora.getFullYear();
    }).length;
  }

  get pacientesUnicos(): number {
    return new Set(this.bitacoras.map(b => b.alumno_id)).size;
  }

  get dxFrecuente(): string {
    const conteo: Record<string, number> = {};
    for (const b of this.bitacoras) {
      if (b.diagnostico) conteo[b.diagnostico] = (conteo[b.diagnostico] ?? 0) + 1;
    }
    const top = Object.entries(conteo).sort((a, b) => b[1] - a[1])[0];
    return top ? top[0] : '—';
  }

  // --- Búsqueda local ---

  get bitacorasFiltradas(): Bitacora[] {
    const busq = this.busquedaAlumno.toLowerCase().trim();
    if (!busq) return this.bitacoras;
    return this.bitacoras.filter(b => {
      const nombre = `${b.alumno?.nombre ?? ''} ${b.alumno?.apellido ?? ''}`.toLowerCase();
      const ctrl = b.alumno?.numero_control?.toLowerCase() ?? '';
      const dx = b.diagnostico?.toLowerCase() ?? '';
      return nombre.includes(busq) || ctrl.includes(busq) || dx.includes(busq);
    });
  }

  get pagedBitacoras(): Bitacora[] {
    const start = (this.currentPage - 1) * this.PAGE_SIZE;
    return this.bitacorasFiltradas.slice(start, start + this.PAGE_SIZE);
  }

  get totalPages(): number { return Math.ceil(this.bitacorasFiltradas.length / this.PAGE_SIZE) || 1; }

  onBusqueda(): void { this.currentPage = 1; }

  prevPage(): void { if (this.currentPage > 1) this.currentPage--; }
  nextPage(): void { if (this.currentPage < this.totalPages) this.currentPage++; }

  get availableCitas(): Cita[] {
    const ids = new Set(this.bitacoras.map(b => b.cita_id));
    return this.citas.filter(c => c.estatus === 'atendida' && !ids.has(c.id));
  }

  // --- Drawer ---

  abrirVista(b: Bitacora): void {
    this.drawerBitacora = b;
    this.drawerModo = 'vista';
    this.drawerAbierto = true;
  }

  abrirNueva(): void {
    this.editandoId = null;
    this.bitacoraFormData = this.emptyForm();
    this.mensajeForm = null;
    this.drawerModo = 'form';
    this.drawerBitacora = null;
    this.drawerAbierto = true;
  }

  abrirEdicion(b: Bitacora): void {
    this.editandoId = b.id;
    this.bitacoraFormData = {
      cita_id: b.cita_id,
      diagnostico: b.diagnostico || '',
      tratamiento: b.tratamiento || '',
      observaciones: b.observaciones || '',
      peso: b.peso || '',
      altura: b.altura || '',
      temperatura: b.temperatura || '',
      presion_arterial: b.presion_arterial || ''
    };
    this.mensajeForm = null;
    this.drawerModo = 'form';
    this.drawerAbierto = true;
  }

  cerrarDrawer(): void {
    this.drawerAbierto = false;
    this.drawerBitacora = null;
    this.editandoId = null;
    this.mensajeForm = null;
  }

  guardarBitacora(form: NgForm): void {
    if (form.invalid) {
      this.mensajeForm = !this.bitacoraFormData.cita_id
        ? 'Selecciona la cita atendida.'
        : 'Completa todos los campos obligatorios.';
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

    this.isSubmitting = true;
    this.mensajeForm = null;

    const req$ = this.editandoId
      ? this.bitacoraService.updateBitacora(this.editandoId, payload)
      : this.bitacoraService.createBitacora(payload);

    req$.pipe(
      takeUntil(this.destroy$),
      catchError(error => {
        const errores = error?.error?.errors;
        if (errores) {
          const first = Object.keys(errores)[0];
          const msgs = (errores as Record<string, string[]>)[first];
          if (Array.isArray(msgs) && msgs.length) { this.mensajeForm = msgs[0]; return of(null); }
        }
        this.mensajeForm = error?.error?.message || 'No se pudo guardar la bitácora.';
        return of(null);
      }),
      finalize(() => { this.isSubmitting = false; })
    ).subscribe(res => {
      if (res?.bitacora) {
        this.cerrarDrawer();
        this.loadBitacoras();
      }
    });
  }

  // --- Helpers ---

  iniciales(b: Bitacora): string {
    const n = b.alumno?.nombre?.[0] ?? '';
    const a = b.alumno?.apellido?.[0] ?? '';
    return (n + a).toUpperCase() || '?';
  }

  formatFecha(fecha: string): string {
    if (!fecha) return '—';
    const [y, m, d] = fecha.split('-').map(Number);
    return new Intl.DateTimeFormat('es-MX', { day: 'numeric', month: 'short', year: 'numeric' })
      .format(new Date(y, (m ?? 1) - 1, d ?? 1)).toUpperCase();
  }

  formatDatetime(iso: string): string {
    if (!iso) return '—';
    return new Intl.DateTimeFormat('es-MX', { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(iso));
  }

  // Descarga las bitácoras visibles (respeta el filtro activo) como CSV con BOM UTF-8
  exportarCsv(): void {
    if (!this.bitacorasFiltradas.length) return;
    const headers = ['Fecha', 'Alumno', 'No. Control', 'Diagnóstico', 'Tratamiento', 'Observaciones', 'Peso', 'Altura', 'Temperatura', 'Presión arterial'];
    const rows = this.bitacorasFiltradas.map(b => [
      b.cita?.fecha_cita ?? b.created_at.split('T')[0],
      `${b.alumno?.nombre ?? ''} ${b.alumno?.apellido ?? ''}`.trim(),
      b.alumno?.numero_control ?? '',
      b.diagnostico ?? '',
      b.tratamiento ?? '',
      b.observaciones ?? '',
      b.peso ?? '',
      b.altura ?? '',
      b.temperatura ?? '',
      b.presion_arterial ?? '',
    ]);
    const csv = [headers, ...rows]
      .map(row => row.map(v => `"${String(v).replace(/"/g, '""')}"`).join(','))
      .join('\n');
    const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `bitacoras_${new Date().toISOString().split('T')[0]}.csv`;
    a.click();
    URL.revokeObjectURL(url);
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
    this.bitacoraService.getBitacoras()
      .pipe(
        takeUntil(this.destroy$),
        catchError(err => { this.bitacorasError = err?.error?.message || 'No se pudieron obtener las bitácoras.'; return of([] as Bitacora[]); }),
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
