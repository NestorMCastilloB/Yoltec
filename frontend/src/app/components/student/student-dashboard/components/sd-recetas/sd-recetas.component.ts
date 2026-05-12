import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Subject } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { of } from 'rxjs';
import { Receta, RecetaService } from '../../../../../services/receta.service';

@Component({
  selector: 'app-sd-recetas',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './sd-recetas.component.html',
})
export class SdRecetasComponent implements OnInit, OnDestroy {
  recetas: Receta[] = [];
  isLoading = false;
  error: string | null = null;

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
    return new Intl.DateTimeFormat('es-MX', { day: '2-digit', month: '2-digit', year: '2-digit' }).format(new Date(fecha));
  }
}
