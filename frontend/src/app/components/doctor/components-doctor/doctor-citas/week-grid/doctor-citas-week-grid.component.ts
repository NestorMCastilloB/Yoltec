import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Cita } from '../../../../../services/cita.service';
import {
  buildWeekDays,
  formatDate,
  getCitaName,
  getGridCitaClass,
  getMonday,
  trackByCita,
  weekLabelFromStart,
} from '../doctor-citas-utils';

@Component({
  selector: 'app-doctor-citas-week-grid',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './doctor-citas-week-grid.component.html',
})
export class DoctorCitasWeekGridComponent {
  @Input() citas: Cita[] = [];
  @Input() weekStart: Date = getMonday(new Date());
  @Input() hayFiltroActivo = false;
  @Input() citaMatchaFiltro: (c: Cita) => boolean = () => true;

  @Output() openCita = new EventEmitter<Cita>();
  @Output() weekStartChange = new EventEmitter<Date>();

  readonly hourGridSlots: number[] = [8, 9, 10, 11, 12, 13, 14, 15, 16];
  readonly trackByCita = trackByCita;
  readonly getCitaName = getCitaName;
  readonly getGridCitaClass = getGridCitaClass;

  get today(): string {
    return formatDate(new Date());
  }

  get weekGridDays(): { date: string; label: string; isToday: boolean }[] {
    return buildWeekDays(this.weekStart, this.today);
  }

  get weekLabel(): string {
    return weekLabelFromStart(this.weekStart);
  }

  changeWeek(direction: number): void {
    const next = new Date(this.weekStart);
    next.setDate(next.getDate() + direction * 7);
    this.weekStart = next;
    this.weekStartChange.emit(next);
  }

  goToThisWeek(): void {
    const monday = getMonday(new Date());
    this.weekStart = monday;
    this.weekStartChange.emit(monday);
  }

  getCitasForSlot(date: string, hour: number): Cita[] {
    return this.citas.filter(c => {
      if (c.fecha_cita !== date) return false;
      const h = parseInt(c.hora_cita.split(':')[0], 10);
      return h === hour;
    });
  }
}
