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
    const hoyStr = this.toDateStr(hoy.getFullYear(), hoy.getMonth() + 1, hoy.getDate());

    const fechaStr = (c: Cita) => (c.fecha_cita || '').split('T')[0];
    const sortKey = (c: Cita) => `${fechaStr(c)} ${c.hora_cita || ''}`;

    const proximas = citas
      .filter(c => c.estatus === 'programada' && fechaStr(c) >= hoyStr)
      .sort((a, b) => sortKey(a).localeCompare(sortKey(b)));

    this.citasProximas = proximas.slice(0, 5).map(c => this.mapearCita(c));

    const pasadas = citas
      .filter(c => c.estatus === 'atendida')
      .sort((a, b) => sortKey(b).localeCompare(sortKey(a)));

    if (pasadas.length) {
      const p = pasadas[0];
      const [y, m, d] = fechaStr(p).split('-').map(Number);
      this.ultimaVisita = {
        fecha: `${d} ${this.MESES[m - 1]} ${y}`,
        motivo: p.motivo ?? 'Consulta general',
      };
    }
  }

  // Parse local-safe: evita el corrimiento de zona horaria del ISO con sufijo Z
  private mapearCita(c: Cita): CitaResumen {
    const [y, m, d] = (c.fecha_cita || '').split('T')[0].split('-').map(Number);
    const local = new Date(y, (m || 1) - 1, d || 1);
    return {
      id:     c.id,
      dia:    d,
      mes:    this.MESES[(m || 1) - 1].toUpperCase(),
      dow:    this.DIAS[local.getDay()],
      hora:   c.hora_cita,
      motivo: c.motivo ?? 'Consulta general',
      estatus: c.estatus,
    };
  }

  private toDateStr(y: number, m: number, d: number): string {
    return `${y}-${String(m).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
  }
}
