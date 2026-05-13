import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subject, of } from 'rxjs';
import { catchError, debounceTime, distinctUntilChanged, finalize, takeUntil } from 'rxjs/operators';
import { DoctorRecetasService, RecetaItem, RecetaPayload } from './doctor-recetas.service';
import { Cita, CitaService } from '../../../../services/cita.service';

@Component({
  selector: 'app-doctor-recetas',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './doctor-recetas.component.html',
  styleUrls: ['./doctor-recetas.component.css']
})
export class DoctorRecetasComponent implements OnInit, OnDestroy {
  recetas: RecetaItem[] = [];
  total = 0;
  paginaActual = 1;
  ultimaPagina = 1;
  cargando = false;
  error: string | null = null;

  busqueda = '';
  private busqueda$ = new Subject<string>();

  drawerAbierto = false;
  drawerModo: 'vista' | 'creacion' = 'vista';
  recetaSel: RecetaItem | null = null;

  // Formulario
  citasDisponibles: Cita[] = [];
  formData: Partial<RecetaPayload> = this.emptyForm();
  editandoId: number | null = null;
  enviando = false;
  mensajeForm: string | null = null;

  private destroy$ = new Subject<void>();

  constructor(
    private recetasService: DoctorRecetasService,
    private citaService: CitaService
  ) {}

  ngOnInit(): void {
    this.cargarRecetas();
    this.busqueda$.pipe(
      debounceTime(300),
      distinctUntilChanged(),
      takeUntil(this.destroy$)
    ).subscribe(() => { this.paginaActual = 1; this.cargarRecetas(); });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  onBusqueda(): void { this.busqueda$.next(this.busqueda); }

  cambiarPagina(pagina: number): void {
    if (pagina < 1 || pagina > this.ultimaPagina) return;
    this.paginaActual = pagina;
    this.cargarRecetas();
  }

  paginas(): number[] {
    return Array.from({ length: this.ultimaPagina }, (_, i) => i + 1);
  }

  abrirVista(r: RecetaItem): void {
    this.drawerModo = 'vista';
    this.recetaSel = r;
    this.drawerAbierto = true;
  }

  abrirEdicion(r: RecetaItem): void {
    this.drawerModo = 'creacion';
    this.editandoId = r.id;
    this.mensajeForm = null;
    this.formData = {
      cita_id: r.cita_id,
      medicamentos: r.medicamentos,
      indicaciones: r.indicaciones ?? '',
      fecha_emision: r.fecha_emision
    };
    this.cargarCitas();
    this.drawerAbierto = true;
  }

  abrirNuevaReceta(): void {
    this.drawerModo = 'creacion';
    this.editandoId = null;
    this.formData = this.emptyForm();
    this.mensajeForm = null;
    this.cargarCitas();
    this.drawerAbierto = true;
  }

  cerrarDrawer(): void {
    this.drawerAbierto = false;
    this.recetaSel = null;
    this.editandoId = null;
    this.mensajeForm = null;
  }

  guardarReceta(): void {
    if (!this.formData.cita_id) { this.mensajeForm = 'Selecciona la cita atendida.'; return; }
    if (!this.formData.medicamentos?.trim()) { this.mensajeForm = 'Captura los medicamentos.'; return; }
    if (!this.formData.fecha_emision) { this.mensajeForm = 'Selecciona la fecha de emisión.'; return; }

    const payload: RecetaPayload = {
      cita_id: Number(this.formData.cita_id),
      medicamentos: this.formData.medicamentos.trim(),
      indicaciones: this.formData.indicaciones?.trim() || undefined,
      fecha_emision: this.formData.fecha_emision
    };

    this.enviando = true;
    this.mensajeForm = null;
    const req$ = this.editandoId
      ? this.recetasService.actualizarReceta(this.editandoId, payload)
      : this.recetasService.crearReceta(payload);

    req$.pipe(
      takeUntil(this.destroy$),
      catchError(err => {
        const errores = err?.error?.errors;
        if (errores) {
          const primera = Object.keys(errores)[0];
          const msgs = errores[primera];
          if (Array.isArray(msgs) && msgs.length) { this.mensajeForm = msgs[0]; return of(null); }
        }
        this.mensajeForm = err?.error?.message || 'No se pudo guardar la receta.';
        return of(null);
      }),
      finalize(() => { this.enviando = false; })
    ).subscribe(res => {
      if (res?.receta) {
        this.cerrarDrawer();
        this.cargarRecetas();
      }
    });
  }

  iniciales(nombre?: string, apellido?: string): string {
    return ((nombre?.[0] ?? '') + (apellido?.[0] ?? '')).toUpperCase() || '?';
  }

  // Primeros 2 medicamentos (separados por salto de línea)
  medsMostrados(meds: string): string[] {
    return meds.split('\n').map(m => m.trim()).filter(Boolean).slice(0, 2);
  }

  medsExtra(meds: string): number {
    return Math.max(0, meds.split('\n').filter(m => m.trim()).length - 2);
  }

  formatFecha(fecha: string): string {
    const [y, m, d] = fecha.split('-').map(Number);
    return new Intl.DateTimeFormat('es-MX', { day: 'numeric', month: 'short', year: 'numeric' })
      .format(new Date(y, (m ?? 1) - 1, d ?? 1)).toUpperCase();
  }

  private cargarRecetas(): void {
    this.cargando = true;
    this.error = null;
    this.recetasService.getRecetas(this.paginaActual, this.busqueda)
      .pipe(
        takeUntil(this.destroy$),
        catchError(err => {
          this.error = err?.error?.message || 'No se pudieron cargar las recetas.';
          return of({ data: [], total: 0, current_page: 1, last_page: 1 });
        }),
        finalize(() => { this.cargando = false; })
      )
      .subscribe(res => {
        this.recetas = res.data;
        this.total = res.total;
        this.paginaActual = res.current_page;
        this.ultimaPagina = res.last_page;
      });
  }

  private cargarCitas(): void {
    this.citaService.getCitas()
      .pipe(takeUntil(this.destroy$), catchError(() => of([] as Cita[])))
      .subscribe(citas => { this.citasDisponibles = citas.filter(c => c.estatus === 'atendida'); });
  }

  private emptyForm(): Partial<RecetaPayload> {
    return { cita_id: undefined, medicamentos: '', indicaciones: '', fecha_emision: this.hoy() };
  }

  private hoy(): string {
    const d = new Date();
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  }
}
