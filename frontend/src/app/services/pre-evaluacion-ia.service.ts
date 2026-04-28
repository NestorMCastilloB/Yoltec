import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_BASE_URL } from './api-config';

export interface Pregunta {
  id: string;
  texto: string;
  opciones: string[];
  peso: number;
}

export interface PosibleEnfermedad {
  enfermedad: string;
  confianza: number;
}

export interface PreEvaluacion {
  id: number;
  cita_id: number;
  alumno_id: number;
  respuestas: Record<string, string>;
  diagnostico_sugerido: string;
  confianza: number;
  sintomas_detectados: string[];
  estatus_validacion: 'pendiente' | 'validado' | 'descartado';
  validado_por?: number;
  comentario_doctor?: string;
  fecha_validacion?: string;
  created_at: string;
  cita?: {
    id: number;
    fecha_cita: string;
    hora_cita: string;
    alumno?: {
      nombre: string;
      apellido: string;
      numero_control: string;
    };
  };
}

export interface CreatePreEvaluacionPayload {
  cita_id: number;
  respuestas: Record<string, string>;
}

export interface PreEvaluacionResult {
  success?: boolean;
  diagnostico_principal: string;
  confianza: number;
  sintomas_detectados: string[];
  posibles_enfermedades: PosibleEnfermedad[];
  recomendacion: string;
}

export interface ChatMessage {
  role: 'user' | 'assistant';
  content: string;
}

export interface ChatResponse {
  message: string;
  finished: boolean;
  diagnostico: PreEvaluacionResult | null;
  pre_evaluacion?: PreEvaluacion;
}

@Injectable({
  providedIn: 'root'
})
export class PreEvaluacionIAService {
  private apiUrl = `${API_BASE_URL}`;

  constructor(private http: HttpClient) {}

  /**
   * Obtener preguntas para la pre-evaluación
   */
  getPreguntas(): Observable<{ preguntas: Pregunta[] }> {
    return this.http.get<{ preguntas: Pregunta[] }>(`${this.apiUrl}/pre-evaluacion/preguntas`);
  }

  /**
   * Obtener todas las pre-evaluaciones del usuario
   */
  getPreEvaluaciones(): Observable<{ pre_evaluaciones: PreEvaluacion[] }> {
    return this.http.get<{ pre_evaluaciones: PreEvaluacion[] }>(`${this.apiUrl}/pre-evaluacion`);
  }

  /**
   * Crear una nueva pre-evaluación
   */
  createPreEvaluacion(payload: CreatePreEvaluacionPayload): Observable<{
    message: string;
    pre_evaluacion: PreEvaluacion;
    resultado_ia: PreEvaluacionResult;
  }> {
    return this.http.post<{
      message: string;
      pre_evaluacion: PreEvaluacion;
      resultado_ia: PreEvaluacionResult;
    }>(`${this.apiUrl}/pre-evaluacion`, payload);
  }

  /**
   * Ver una pre-evaluación específica
   */
  getPreEvaluacion(id: number): Observable<{ pre_evaluacion: PreEvaluacion }> {
    return this.http.get<{ pre_evaluacion: PreEvaluacion }>(`${this.apiUrl}/pre-evaluacion/${id}`);
  }

  /**
   * Obtener pre-evaluaciones pendientes (solo doctores)
   */
  getPendientes(): Observable<{ pendientes: PreEvaluacion[]; total: number }> {
    return this.http.get<{ pendientes: PreEvaluacion[]; total: number }>(`${this.apiUrl}/pre-evaluacion/pendientes`);
  }

  /**
   * Chat conversacional con IA para pre-evaluación
   */
  chat(citaId: number, messages: ChatMessage[]): Observable<ChatResponse> {
    return this.http.post<ChatResponse>(`${this.apiUrl}/pre-evaluacion/chat`, {
      cita_id: citaId,
      messages
    });
  }

  /**
   * Validar o descartar una pre-evaluación (solo doctores)
   */
  validarPreEvaluacion(
    id: number,
    accion: 'validar' | 'descartar',
    comentario?: string
  ): Observable<{ message: string; pre_evaluacion: PreEvaluacion }> {
    return this.http.post<{ message: string; pre_evaluacion: PreEvaluacion }>(
      `${this.apiUrl}/pre-evaluacion/${id}/validar`,
      { accion, comentario }
    );
  }
}
