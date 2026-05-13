import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AgendarCitaComponent } from '../../shared/agendar-cita/agendar-cita.component';
import { AgendarCitaService, AlumnoBusqueda, Cita } from '../../shared/agendar-cita/agendar-cita.service';

@Component({
  selector: 'app-nueva-cita-doctor',
  standalone: true,
  imports: [CommonModule, FormsModule, AgendarCitaComponent],
  templateUrl: './nueva-cita-doctor.component.html',
  styleUrl: './nueva-cita-doctor.component.css'
})
export class NuevaCitaDoctorComponent {
  private router = inject(Router);
  private svc = inject(AgendarCitaService);

  currentStep: 1 | 2 | 3 = 1;

  // Paso 1
  searchQuery = '';
  searching = false;
  searchResults: AlumnoBusqueda[] = [];
  searchError = '';
  alumnoSeleccionado: AlumnoBusqueda | null = null;

  // Paso 3
  citaConfirmada: Cita | null = null;

  buscar(): void {
    if (!this.searchQuery.trim()) return;
    this.searching = true;
    this.searchError = '';
    this.searchResults = [];
    this.alumnoSeleccionado = null;
    this.svc.buscarAlumno(this.searchQuery.trim()).subscribe({
      next: res => {
        this.searchResults = res;
        this.searching = false;
        if (!res.length) this.searchError = 'No se encontró ningún alumno con ese criterio.';
      },
      error: () => {
        this.searching = false;
        this.searchError = 'Error al buscar. Intenta de nuevo.';
      }
    });
  }

  seleccionar(alumno: AlumnoBusqueda): void {
    this.alumnoSeleccionado = alumno;
  }

  continuar(): void {
    if (this.alumnoSeleccionado) this.currentStep = 2;
  }

  cancelar(): void {
    this.router.navigate(['/doctor']);
  }

  onCitaAgendada(cita: Cita): void {
    this.citaConfirmada = cita;
    this.currentStep = 3;
  }

  agendarOtra(): void {
    this.searchQuery = '';
    this.searchResults = [];
    this.searchError = '';
    this.alumnoSeleccionado = null;
    this.citaConfirmada = null;
    this.currentStep = 1;
  }

  irACitas(): void {
    this.router.navigate(['/doctor/citas']);
  }

  iniciales(nombre: string): string {
    return nombre.split(' ').slice(0, 2).map(p => p[0]).join('').toUpperCase();
  }

  // Convierte ISO a "Miércoles, 13 de mayo 2026"
  formatFecha(iso: string): string {
    const [y, m, d] = iso.split('-').map(Number);
    const meses = ['enero','febrero','marzo','abril','mayo','junio',
                   'julio','agosto','septiembre','octubre','noviembre','diciembre'];
    const diasSemana = ['domingo','lunes','martes','miércoles','jueves','viernes','sábado'];
    const dow = diasSemana[new Date(y, m - 1, d).getDay()];
    return `${dow.charAt(0).toUpperCase() + dow.slice(1)}, ${d} de ${meses[m - 1]} ${y}`;
  }
}
