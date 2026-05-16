import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map, timeout } from 'rxjs/operators';
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

// Shape crudo del backend (POST /api/pre-evaluacion/chat)
interface BackendChatResponse {
  message: string;
  finished: boolean;
  diagnostico: {
    diagnostico_principal: string;
    confianza: number;
    sintomas_detectados: string[];
    posibles_enfermedades: { enfermedad: string; confianza: number }[];
    recomendacion: string;
  } | null;
  pre_evaluacion?: unknown;
}

@Injectable()
export class PreEvaluacionChatService {
  private apiUrl = `${API_BASE_URL}/pre-evaluacion`;

  constructor(private http: HttpClient) {}

  // POST /api/pre-evaluacion/chat — requiere cita_id y messages[{role,content}]
  enviarMensaje(citaId: number, mensaje: string, historial: MensajeChat[]): Observable<RespuestaChat> {
    const messages = [
      ...historial.map(m => ({ role: m.rol, content: m.contenido })),
      { role: 'user' as const, content: mensaje },
    ];
    return this.http
      .post<BackendChatResponse>(`${this.apiUrl}/chat`, { cita_id: citaId, messages })
      .pipe(
        timeout(60000), // IA en cold start puede tardar hasta 50s
        map(res => this.adaptarResponse(res)),
      );
  }

  private adaptarResponse(res: BackendChatResponse): RespuestaChat {
    const out: RespuestaChat = {
      mensaje: res.message,
      finalizado: res.finished,
    };
    if (res.diagnostico) {
      out.diagnosticos = (res.diagnostico.posibles_enfermedades || []).map(p => ({
        nombre: p.enfermedad,
        porcentaje: Math.round((p.confianza || 0) * 100),
      }));
      out.sintomas_detectados = res.diagnostico.sintomas_detectados || [];
      out.recomendaciones = res.diagnostico.recomendacion ? [res.diagnostico.recomendacion] : [];
    }
    return out;
  }
}
