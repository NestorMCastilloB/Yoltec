import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Subject } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { of } from 'rxjs';
import { Bitacora, BitacoraService } from '../../../../../services/bitacora.service';
import { formatFechaHora } from '../../../../shared/utils/format.utils';

@Component({
  selector: 'app-sd-bitacora',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './sd-bitacora.component.html',
})
export class SdBitacoraComponent implements OnInit, OnDestroy {
  bitacoras: Bitacora[] = [];
  isLoading = false;
  error: string | null = null;

  private destroy$ = new Subject<void>();

  constructor(private bitacoraService: BitacoraService) {}

  ngOnInit(): void { this.cargar(); }

  ngOnDestroy(): void { this.destroy$.next(); this.destroy$.complete(); }

  private cargar(): void {
    this.isLoading = true;
    this.bitacoraService.getBitacoras()
      .pipe(takeUntil(this.destroy$), catchError(() => { this.error = 'Error al cargar bitácora.'; return of([]); }), finalize(() => this.isLoading = false))
      .subscribe((data: Bitacora[]) => this.bitacoras = data);
  }

  formatFecha = formatFechaHora;

  formatFechaCita(fecha: string): string {
    return new Intl.DateTimeFormat('es-MX', { day: '2-digit', month: '2-digit', year: '2-digit' }).format(new Date(fecha));
  }
}
