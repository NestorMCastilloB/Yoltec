import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { Cita, CitaService } from '../../../services/cita.service';

export interface CitaMisCitas extends Cita {
  diagnostico?: string | null;
}

export interface CitasFiltradas {
  proximas: CitaMisCitas[];
  pasadas: CitaMisCitas[];
  canceladas: CitaMisCitas[];
}

@Injectable({ providedIn: 'root' })
export class MisCitasService {
  constructor(private citaService: CitaService) {}

  // Obtiene citas y las separa por estatus para las 3 tabs
  getCitasFiltradas(): Observable<CitasFiltradas> {
    return this.citaService.getCitas().pipe(
      map(citas => ({
        proximas: citas.filter(c => c.estatus === 'programada' || c.estatus === 'confirmada'),
        pasadas: citas.filter(c => c.estatus === 'atendida'),
        canceladas: citas.filter(c => c.estatus === 'cancelada' || c.estatus === 'no_asistio'),
      }))
    );
  }

  cancelarCita(id: number): Observable<{ message: string; cita: Cita }> {
    return this.citaService.cancelCita(id);
  }
}
