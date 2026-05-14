import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subject } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { of } from 'rxjs';
import { Receta, RecetaService } from '../../../../../services/receta.service';

@Component({
  selector: 'app-sd-recetas',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './sd-recetas.component.html',
  styleUrls: ['./sd-recetas.component.css'],
})
export class SdRecetasComponent implements OnInit, OnDestroy {
  recetas: Receta[] = [];
  isLoading = false;
  error: string | null = null;
  busqueda = '';

  get recetasFiltradas(): Receta[] {
    const q = this.busqueda.toLowerCase().trim();
    if (!q) return this.recetas;
    return this.recetas.filter(r =>
      r.medicamentos.toLowerCase().includes(q) ||
      `${r.doctor?.nombre} ${r.doctor?.apellido}`.toLowerCase().includes(q)
    );
  }

  // Divide el string de medicamentos en líneas; separa nombre y dosis por " - "
  parseMedicamentos(texto: string): { nombre: string; dosis: string }[] {
    return texto.split('\n')
      .map(l => l.trim())
      .filter(l => l.length > 0)
      .map(l => {
        const idx = l.indexOf(' - ');
        return idx !== -1
          ? { nombre: l.substring(0, idx), dosis: l.substring(idx + 3) }
          : { nombre: l, dosis: '' };
      });
  }

  private destroy$ = new Subject<void>();

  constructor(private recetaService: RecetaService) {}

  ngOnInit(): void { this.cargar(); }
  ngOnDestroy(): void { this.destroy$.next(); this.destroy$.complete(); }

  private cargar(): void {
    this.isLoading = true;
    this.recetaService.getRecetas()
      .pipe(takeUntil(this.destroy$), catchError(() => { this.error = 'Error al cargar recetas.'; return of([]); }), finalize(() => this.isLoading = false))
      .subscribe((data: Receta[]) => this.recetas = data);
  }

  formatFecha(fecha: string): string {
    const d = new Date(fecha);
    const mes = ['ENE','FEB','MAR','ABR','MAY','JUN','JUL','AGO','SEP','OCT','NOV','DIC'][d.getMonth()];
    return `${d.getDate()} ${mes} ${d.getFullYear()}`;
  }
}
