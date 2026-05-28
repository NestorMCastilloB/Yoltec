import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { CitasFiltro } from '../doctor-citas-types';

@Component({
  selector: 'app-doctor-citas-filtros',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './doctor-citas-filtros.component.html',
})
export class DoctorCitasFiltrosComponent {
  @Input() filtro: CitasFiltro = { search: '', estatus: '', fechaDesde: '', fechaHasta: '' };
  @Output() filtroChange = new EventEmitter<CitasFiltro>();
  @Output() limpiar = new EventEmitter<void>();

  get hayFiltro(): boolean {
    const f = this.filtro;
    return !!(f.search || f.estatus || f.fechaDesde || f.fechaHasta);
  }

  update<K extends keyof CitasFiltro>(key: K, value: CitasFiltro[K]): void {
    this.filtro = { ...this.filtro, [key]: value };
    this.filtroChange.emit(this.filtro);
  }
}
