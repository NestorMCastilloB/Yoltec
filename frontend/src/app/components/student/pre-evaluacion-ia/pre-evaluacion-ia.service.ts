import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { timeout } from 'rxjs/operators';
import { API_BASE_URL } from '../../../services/api-config';

export interface MensajeChat {
  rol: 'user' | 'assistant';
  contenido: string;
}

export interface DiagnosticoIA {
  nombre: string;
  porcentaje: number;
  descripcion?: string;
  codigo?: string;
}

export interface RespuestaChat {
  mensaje: string;
  diagnosticos?: DiagnosticoIA[];
  sintomas_detectados?: string[];
  recomendaciones?: string[];
  finalizado?: boolean;
}

@Injectable()
export class PreEvaluacionChatService {
  private apiUrl = `${API_BASE_URL}/ia`;

  constructor(private http: HttpClient) {}

  // Envía mensaje al chat IA con historial de sesión
  enviarMensaje(mensaje: string, historial: MensajeChat[]): Observable<RespuestaChat> {
    return this.http
      .post<RespuestaChat>(`${this.apiUrl}/chat`, { mensaje, historial })
      .pipe(timeout(20000));
  }
}
