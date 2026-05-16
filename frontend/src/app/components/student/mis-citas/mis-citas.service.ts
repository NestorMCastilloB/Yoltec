import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { Cita, CitaService } from '../../../services/cita.service';

export interface CitaMisCitas extends Cita {
  diagnostico?: string | null;
  motivo_cancelacion?: string | null;
}

export interface CitasFiltradas {
  proximas: CitaMisCitas[];
  pasadas: CitaMisCitas[];
  canceladas: CitaMisCitas[];
}

@Injectable({ providedIn: 'root' })
export class MisCitasService {
  constructor(private citaService: CitaService) {}

  // Obtiene citas y las separa por estatus. Próximas asc por fecha+hora; pasadas/canceladas desc
  getCitasFiltradas(): Observable<CitasFiltradas> {
    const key = (c: Cita) => `${(c.fecha_cita || '').split('T')[0]} ${c.hora_cita || ''}`;
    return this.citaService.getCitas().pipe(
      map(citas => ({
        proximas: citas
          .filter(c => c.estatus === 'programada' || c.estatus === 'confirmada')
          .sort((a, b) => key(a).localeCompare(key(b))),
        pasadas: citas
          .filter(c => c.estatus === 'atendida')
          .sort((a, b) => key(b).localeCompare(key(a))),
        canceladas: citas
          .filter(c => c.estatus === 'cancelada' || c.estatus === 'no_asistio')
          .sort((a, b) => key(b).localeCompare(key(a))),
      }))
    );
  }

  cancelarCita(id: number): Observable<{ message: string; cita: Cita }> {
    return this.citaService.cancelCita(id);
  }
}
