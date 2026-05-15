import { Component, Input, Output, EventEmitter, HostListener } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ThemeService } from '../../../../services/theme.service';

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
  @Output() exportEvent = new EventEmitter<void>();

  userMenuOpen = false;

  constructor(public themeService: ThemeService) {}

  toggleUserMenu(): void { this.userMenuOpen = !this.userMenuOpen; }

  @HostListener('document:click', ['$event'])
  onDocumentClick(e: MouseEvent): void {
    if (!(e.target as Element).closest('.user-menu-wrap')) {
      this.userMenuOpen = false;
    }
  }

  private sectionMap: Record<string, { crumb: string; title: string; showExport: boolean; primaryAction?: string }> = {
    'inicio':            { crumb: 'Inicio · Panel',           title: 'Panel del consultorio', showExport: false, primaryAction: '+ Nueva cita' },
    'citas':             { crumb: 'Citas · Calendario',       title: 'Citas',                 showExport: false, primaryAction: '+ Nueva cita' },
    'bitacoras':         { crumb: 'Bitácoras · Historial',    title: 'Bitácoras',             showExport: true },
    'recetas':           { crumb: 'Recetas · Listado',        title: 'Recetas',               showExport: false },
    'pre-evaluaciones':  { crumb: 'IA · Pre-evaluaciones',    title: 'Pre-evaluaciones',      showExport: false },
    'ia-prioridad':      { crumb: 'IA · Prioridad',           title: 'Prioridad IA',          showExport: false },
    'estadisticas':      { crumb: 'Reportes · Estadísticas',  title: 'Estadísticas',          showExport: false },
    'ficha-paciente':    { crumb: 'Pacientes · Ficha',        title: 'Ficha del paciente',    showExport: false },
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

  get showExport(): boolean {
    return this.sectionMap[this.activeSection]?.showExport ?? false;
  }

  get primaryAction(): string | undefined {
    return this.sectionMap[this.activeSection]?.primaryAction;
  }
}
