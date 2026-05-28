import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Cita } from '../../../../../services/cita.service';
import {
  formatDateDisplay,
  formatFechaCorta,
  formatTime,
  getCitaInitials,
  getCitaName,
} from '../doctor-citas-utils';

@Component({
  selector: 'app-doctor-citas-detail-drawer',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './doctor-citas-detail-drawer.component.html',
})
export class DoctorCitasDetailDrawerComponent {
  @Input() cita: Cita | null = null;
  @Input() abierto = false;

  @Output() close = new EventEmitter<void>();
  @Output() atender = new EventEmitter<Cita>();
  @Output() cancelar = new EventEmitter<Cita>();
  @Output() noAsistio = new EventEmitter<Cita>();
  @Output() reprogramar = new EventEmitter<Cita>();
  @Output() verExpediente = new EventEmitter<number>();

  readonly getCitaInitials = getCitaInitials;
  readonly getCitaName = getCitaName;
  readonly formatFechaCorta = formatFechaCorta;
  readonly formatTime = formatTime;
  readonly formatDateDisplay = formatDateDisplay;

  estatusLabel(c: Cita): string {
    switch (c.estatus) {
      case 'programada': return 'Programada';
      case 'atendida': return 'Atendida';
      case 'cancelada': return 'Cancelada';
      case 'no_asistio': return 'No asistió';
      default: return c.estatus;
    }
  }
}
