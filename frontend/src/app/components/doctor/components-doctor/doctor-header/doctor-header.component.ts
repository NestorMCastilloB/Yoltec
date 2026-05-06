import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-doctor-header',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './doctor-header.component.html',
  styleUrl: './doctor-header.component.css'
})
export class DoctorHeaderComponent {
  @Input() doctorName = 'Doctor';
  @Input() activeSection = 'inicio';
  @Input() totalPendientes = 0;
  @Output() sectionChange = new EventEmitter<string>();
  @Output() logoutEvent = new EventEmitter<void>();

  private sectionMap: Record<string, { crumb: string; title: string }> = {
    'inicio':            { crumb: 'Inicio · Panel',           title: 'Panel del consultorio' },
    'citas':             { crumb: 'Citas · Calendario',       title: 'Citas' },
    'bitacoras':         { crumb: 'Bitácoras · Historial',    title: 'Bitácoras' },
    'recetas':           { crumb: 'Recetas · Listado',        title: 'Recetas' },
    'pre-evaluaciones':  { crumb: 'IA · Pre-evaluaciones',    title: 'Pre-evaluaciones' },
    'ia-prioridad':      { crumb: 'IA · Prioridad',           title: 'Prioridad IA' },
    'estadisticas':      { crumb: 'Reportes · Estadísticas',  title: 'Estadísticas' },
  };

  get initials(): string {
    return this.doctorName
      .split(' ')
      .filter(w => w.length > 0)
      .slice(0, 2)
      .map(w => w[0].toUpperCase())
      .join('');
  }

  get sectionCrumb(): string {
    return this.sectionMap[this.activeSection]?.crumb ?? '';
  }

  get sectionTitle(): string {
    return this.sectionMap[this.activeSection]?.title ?? '';
  }
}
