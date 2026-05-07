import { Component, Input, Output, EventEmitter, OnChanges, OnDestroy, SimpleChanges } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Subject, of, forkJoin } from 'rxjs';
import { catchError, takeUntil, finalize } from 'rxjs/operators';
import { PerfilMedicoService, PerfilMedico, ConsultaHistorial } from '../../../../services/perfil-medico.service';
import { RecetaService } from '../../../../services/receta.service';
import { CitaService, Cita } from '../../../../services/cita.service';

@Component({
  selector: 'app-doctor-ficha-paciente',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './doctor-ficha-paciente.component.html',
  styleUrls: ['./doctor-ficha-paciente.component.css']
})
export class DoctorFichaPacienteComponent implements OnChanges, OnDestroy {
  @Input() alumnoId: number | null = null;
  @Output() back = new EventEmitter<void>();

  perfil: PerfilMedico | null = null;
  historial: ConsultaHistorial[] = [];
  recetas: any[] = [];
  bitacoras: Cita[] = [];
  isLoading = false;
  activeTab: 'info' | 'historial' | 'recetas' | 'bitacoras' = 'info';
  historialExpandido: number | null = null;

  private destroy$ = new Subject<void>();

  constructor(
    private perfilService: PerfilMedicoService,
    private recetaService: RecetaService,
    private citaService: CitaService
  ) {}

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['alumnoId'] && this.alumnoId) {
      this.loadData();
    }
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  get initials(): string {
    if (!this.perfil) return '';
    return (this.perfil.nombre.charAt(0) + this.perfil.apellido.charAt(0)).toUpperCase();
  }

  get edad(): string {
    if (!this.perfil?.fecha_nacimiento) return '';
    const birth = new Date(this.perfil.fecha_nacimiento);
    const now = new Date();
    let age = now.getFullYear() - birth.getFullYear();
    const m = now.getMonth() - birth.getMonth();
    if (m < 0 || (m === 0 && now.getDate() < birth.getDate())) age--;
    return `${age} años`;
  }

  setTab(tab: 'info' | 'historial' | 'recetas' | 'bitacoras'): void {
    this.activeTab = tab;
  }

  toggleHistorial(id: number): void {
    this.historialExpandido = this.historialExpandido === id ? null : id;
  }

  private loadData(): void {
    if (!this.alumnoId) return;
    this.isLoading = true;
    this.activeTab = 'info';

    forkJoin({
      perfil: this.perfilService.getPerfilAlumno(this.alumnoId).pipe(catchError(() => of(null))),
      historial: this.perfilService.getHistorialAlumno(this.alumnoId).pipe(catchError(() => of(null))),
      recetas: this.recetaService.getRecetas().pipe(catchError(() => of([]))),
      citas: this.citaService.getCitas().pipe(catchError(() => of([])))
    })
    .pipe(
      takeUntil(this.destroy$),
      finalize(() => this.isLoading = false)
    )
    .subscribe(({ perfil, historial, recetas, citas }) => {
      this.perfil = perfil?.perfil ?? null;
      this.historial = historial?.historial ?? [];

      // Filtrar recetas y citas por alumno
      if (this.perfil) {
        this.recetas = (recetas as any[]).filter((r: any) =>
          r.alumno?.id === this.alumnoId || r.alumno_id === this.alumnoId
        );
        this.bitacoras = (citas as Cita[]).filter(c =>
          c.alumno?.id === this.alumnoId && c.estatus !== 'programada'
        ).sort((a, b) => new Date(b.fecha_cita).getTime() - new Date(a.fecha_cita).getTime());
      }
    });
  }
}
