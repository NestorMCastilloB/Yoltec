import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Subject } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { of } from 'rxjs';
import { ConsultaHistorial, PerfilMedicoService } from '../../../../../services/perfil-medico.service';

@Component({
  selector: 'app-sd-historial',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './sd-historial.component.html',
  styles: [`
    .historial-info { display: flex; align-items: center; gap: 0.75rem; flex: 1; min-width: 0; }
    .historial-fecha { font-weight: 700; color: var(--yol-primary, #2563eb); white-space: nowrap; }
    .historial-motivo { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .historial-doctor { color: var(--yol-text-subtle, #6b7280); white-space: nowrap; font-size: 0.875rem; }
  `],
})
export class SdHistorialComponent implements OnInit, OnDestroy {
  historial: ConsultaHistorial[] = [];
  isLoading = false;
  expandido: number | null = null;

  private destroy$ = new Subject<void>();

  constructor(private perfilMedicoService: PerfilMedicoService) {}

  ngOnInit(): void { this.cargar(); }
  ngOnDestroy(): void { this.destroy$.next(); this.destroy$.complete(); }

  private cargar(): void {
    this.isLoading = true;
    this.perfilMedicoService.getHistorial()
      .pipe(takeUntil(this.destroy$), catchError(() => of([])), finalize(() => this.isLoading = false))
      .subscribe((res: any) => this.historial = res?.historial ?? []);
  }

  toggle(id: number): void {
    this.expandido = this.expandido === id ? null : id;
  }
}
