import { Component, Input, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Subject, of } from 'rxjs';
import { catchError, takeUntil } from 'rxjs/operators';
import { Cita, CitaService } from '../../../../services/cita.service';

@Component({
  selector: 'app-doctor-inicio',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './doctor-inicio.component.html',
  styleUrls: ['./doctor-inicio.component.css']   // <-- Agrega esta línea
})

export class DoctorInicioComponent implements OnInit, OnDestroy {
  @Input() doctorName = 'Doctor';

  todayAppointments = 0;
  patientsAttended = 0;
  pendingBitacoras = 0;
  proximaCita: Cita | null = null;

  private readonly today = this.formatDate(new Date());
  private destroy$ = new Subject<void>();

  constructor(private citaService: CitaService) { }

  ngOnInit(): void {
    this.citaService.getCitas()
      .pipe(takeUntil(this.destroy$), catchError(() => of([] as Cita[])))
      .subscribe(citas => {
        const ahora = new Date();
        this.todayAppointments = citas.filter(c => c.estatus === 'programada' && c.fecha_cita === this.today).length;
        this.patientsAttended = citas.filter(c => c.estatus === 'atendida').length;
        this.pendingBitacoras = citas.filter(c => c.estatus === 'programada').length;

        const pending = citas
          .filter(c => c.estatus === 'programada')
          .sort((a, b) => this.toDate(a.fecha_cita, a.hora_cita).getTime() - this.toDate(b.fecha_cita, b.hora_cita).getTime());
        this.proximaCita = pending.find(c => this.toDate(c.fecha_cita, c.hora_cita) >= ahora) ?? pending[0] ?? null;
      });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private formatDate(date: Date): string {
    const y = date.getFullYear();
    const m = String(date.getMonth() + 1).padStart(2, '0');
    const d = String(date.getDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
  }

  private toDate(fecha: string, hora?: string): Date {
    const [year, month, day] = fecha.split('-').map(Number);
    if (hora) {
      const [h, min] = hora.split(':').map(Number);
      return new Date(year, (month ?? 1) - 1, day ?? 1, h ?? 0, min ?? 0);
    }
    return new Date(year, (month ?? 1) - 1, day ?? 1);
  }
}
