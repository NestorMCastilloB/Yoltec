import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { Subject } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { of } from 'rxjs';
import { ConsultaHistorial, PerfilMedicoService } from '../../../../../services/perfil-medico.service';

@Component({
  selector: 'app-sd-historial',
  standalone: true,
  imports: [CommonModule, DatePipe],
  templateUrl: './sd-historial.component.html',
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
