import { Component, ElementRef, ViewChild, AfterViewChecked, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { Subject, of } from 'rxjs';
import { takeUntil, finalize, catchError } from 'rxjs/operators';
import {
  PreEvaluacionChatService,
  MensajeChat,
  DiagnosticoIA,
  RespuestaChat
} from './pre-evaluacion-ia.service';
import { CitaService } from '../../../services/cita.service';

interface MensajeUI {
  tipo: 'ai' | 'user';
  contenido: string;
  hora: string;
}

@Component({
  selector: 'app-pre-evaluacion-ia',
  standalone: true,
  imports: [CommonModule, FormsModule],
  providers: [PreEvaluacionChatService],
  templateUrl: './pre-evaluacion-ia.component.html',
  styleUrls: ['./pre-evaluacion-ia.component.css']
})
export class PreEvaluacionIaComponent implements OnInit, OnDestroy, AfterViewChecked {
  @ViewChild('scrollContainer') private scrollContainer!: ElementRef<HTMLElement>;
  @ViewChild('inputRef') private inputRef!: ElementRef<HTMLTextAreaElement>;

  mensajes: MensajeUI[] = [];
  historial: MensajeChat[] = [];
  textoInput = '';
  enviando = false;
  error = '';
  shouldScroll = false;

  // Cita requerida para asociar la pre-evaluación
  citaId: number | null = null;
  cargandoCita = true;
  sinCita = false;

  // Resultado diagnóstico
  diagnosticos: DiagnosticoIA[] = [];
  sintomasDetectados: string[] = [];
  recomendaciones: string[] = [];
  mostrarResultado = false;

  private destroy$ = new Subject<void>();

  constructor(
    private chatService: PreEvaluacionChatService,
    private citaService: CitaService,
    private router: Router
  ) {
    this.agregarMensajeIA('Hola, soy tu asistente médico. Cuéntame, ¿qué síntomas estás presentando hoy?');
  }

  ngOnInit(): void {
    // Cargar próxima cita programada para asociar la pre-evaluación
    this.citaService.getCitas()
      .pipe(takeUntil(this.destroy$), catchError(() => of([])), finalize(() => this.cargandoCita = false))
      .subscribe(citas => {
        const proxima = (citas || [])
          .filter(c => c.estatus === 'programada')
          .sort((a, b) => `${a.fecha_cita} ${a.hora_cita}`.localeCompare(`${b.fecha_cita} ${b.hora_cita}`))[0];
        if (proxima) {
          this.citaId = proxima.id;
        } else {
          this.sinCita = true;
        }
      });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  ngAfterViewChecked(): void {
    if (this.shouldScroll) {
      this.scrollAlFinal();
      this.shouldScroll = false;
    }
  }

  // Maneja Enter (enviar) y Shift+Enter (salto de línea)
  onKeydown(event: KeyboardEvent): void {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      this.enviar();
    }
  }

  enviar(): void {
    const texto = this.textoInput.trim();
    if (!texto || this.enviando) return;

    this.error = '';
    this.textoInput = '';
    this.autoResize();

    // Mensaje del usuario
    this.mensajes.push({ tipo: 'user', contenido: texto, hora: this.horaActual() });
    this.historial.push({ rol: 'user', contenido: texto });
    this.enviando = true;
    this.shouldScroll = true;

    if (!this.citaId) {
      this.error = 'Necesitas tener una cita programada para usar la pre-evaluación. Agenda una primero.';
      this.enviando = false;
      this.historial.pop();
      this.mensajes.pop();
      return;
    }
    this.chatService.enviarMensaje(this.citaId, texto, this.historial.slice(0, -1))
      .pipe(
        takeUntil(this.destroy$),
        finalize(() => { this.enviando = false; })
      )
      .subscribe({
        next: (res: RespuestaChat) => {
          this.agregarMensajeIA(res.mensaje);
          this.historial.push({ rol: 'assistant', contenido: res.mensaje });

          if (res.diagnosticos?.length) {
            this.diagnosticos = res.diagnosticos;
            this.sintomasDetectados = res.sintomas_detectados || [];
            this.recomendaciones = res.recomendaciones || [];
            this.mostrarResultado = true;
          }
        },
        error: () => {
          this.error = 'No se pudo conectar con el servicio de IA. Intenta de nuevo.';
          this.shouldScroll = true;
        }
      });
  }

  reintentar(): void {
    this.error = '';
    if (this.historial.length > 0) {
      const ultimo = this.historial[this.historial.length - 1];
      if (ultimo.rol === 'user') {
        this.textoInput = ultimo.contenido;
        this.historial.pop();
        this.mensajes.pop();
        this.enviar();
      }
    }
  }

  agendarCita(): void {
    this.router.navigate(['/student/agendar-cita']);
  }

  // Auto-resize del textarea
  autoResize(): void {
    const ta = this.inputRef?.nativeElement;
    if (ta) {
      ta.style.height = 'auto';
      ta.style.height = Math.min(ta.scrollHeight, 96) + 'px';
    }
  }

  private agregarMensajeIA(contenido: string): void {
    this.mensajes.push({ tipo: 'ai', contenido, hora: this.horaActual() });
    this.shouldScroll = true;
  }

  private scrollAlFinal(): void {
    const el = this.scrollContainer?.nativeElement;
    if (el) el.scrollTop = el.scrollHeight;
  }

  private horaActual(): string {
    return new Date().toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit' });
  }
}
