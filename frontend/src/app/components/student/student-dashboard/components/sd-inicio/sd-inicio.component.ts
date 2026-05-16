import { Component, EventEmitter, OnDestroy, OnInit, Output } from '@angular/core';
import { Subject, forkJoin, of } from 'rxjs';
import { catchError, takeUntil } from 'rxjs/operators';
import { Cita, CitaService } from '../../../../../services/cita.service';
import { Receta, RecetaService } from '../../../../../services/receta.service';

interface CitaResumen {
  id: number;
  dia: number;
  mes: string;
  dow: string;
  hora: string;
  motivo: string;
  estatus: string;
}

@Component({
  selector: 'app-sd-inicio',
  standalone: true,
  imports: [],
  templateUrl: './sd-inicio.component.html',
  styleUrls: ['./sd-inicio.component.css'],
})
export class SdInicioComponent implements OnInit, OnDestroy {
  @Output() navegarACitas = new EventEmitter<void>();
  @Output() navegarAAgendar = new EventEmitter<void>();
  @Output() navegarARecetas = new EventEmitter<void>();

  citasProximas: CitaResumen[] = [];
  ultimaVisita: { fecha: string; motivo: string } | null = null;
  recetasActivas = 0;
  isLoading = true;

  private destroy$ = new Subject<void>();

  private readonly MESES = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
  private readonly DIAS  = ['domingo','lunes','martes','miércoles','jueves','viernes','sábado'];

  constructor(
    private citaService: CitaService,
    private recetaService: RecetaService,
  ) {}

  ngOnInit(): void {
    forkJoin({
      citas:   this.citaService.getCitas().pipe(catchError(() => of([] as Cita[]))),
      recetas: this.recetaService.getRecetas().pipe(catchError(() => of([] as Receta[]))),
    })
    .pipe(takeUntil(this.destroy$))
    .subscribe(({ citas, recetas }) => {
      this.procesarCitas(citas);
      this.recetasActivas = recetas.length;
      this.isLoading = false;
    });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private procesarCitas(citas: Cita[]): void {
    const hoy = new Date();
    hoy.setHours(0, 0, 0, 0);

    const proximas = citas
      .filter(c => c.estatus === 'programada' && new Date(c.fecha_cita) >= hoy)
      .sort((a, b) => new Date(a.fecha_cita).getTime() - new Date(b.fecha_cita).getTime());

    this.citasProximas = proximas.slice(0, 5).map(c => this.mapearCita(c));

    const pasadas = citas
      .filter(c => c.estatus === 'atendida')
      .sort((a, b) => new Date(b.fecha_cita).getTime() - new Date(a.fecha_cita).getTime());

    if (pasadas.length) {
      const p = pasadas[0];
      const d = new Date(p.fecha_cita);
      this.ultimaVisita = {
        fecha: `${d.getDate()} ${this.MESES[d.getMonth()]} ${d.getFullYear()}`,
        motivo: p.motivo ?? 'Consulta general',
      };
    }
  }

  private mapearCita(c: Cita): CitaResumen {
    const d = new Date(c.fecha_cita);
    return {
      id:     c.id,
      dia:    d.getDate(),
      mes:    this.MESES[d.getMonth()].toUpperCase(),
      dow:    this.DIAS[d.getDay()],
      hora:   c.hora_cita,
      motivo: c.motivo ?? 'Consulta general',
      estatus: c.estatus,
    };
  }
}
