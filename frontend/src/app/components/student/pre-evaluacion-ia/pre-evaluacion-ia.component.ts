import { Component, ElementRef, ViewChild, AfterViewChecked } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { Subject } from 'rxjs';
import { takeUntil, finalize } from 'rxjs/operators';
import {
  PreEvaluacionChatService,
  MensajeChat,
  DiagnosticoIA,
  RespuestaChat
} from './pre-evaluacion-ia.service';

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
export class PreEvaluacionIaComponent implements AfterViewChecked {
  @ViewChild('scrollContainer') private scrollContainer!: ElementRef<HTMLElement>;
  @ViewChild('inputRef') private inputRef!: ElementRef<HTMLTextAreaElement>;

  mensajes: MensajeUI[] = [];
  historial: MensajeChat[] = [];
  textoInput = '';
  enviando = false;
  error = '';
  shouldScroll = false;

  // Resultado diagnóstico
  diagnosticos: DiagnosticoIA[] = [];
  sintomasDetectados: string[] = [];
  recomendaciones: string[] = [];
  mostrarResultado = false;

  private destroy$ = new Subject<void>();

  constructor(
    private chatService: PreEvaluacionChatService,
    private router: Router
  ) {
    this.agregarMensajeIA('Hola, soy tu asistente médico. Cuéntame, ¿qué síntomas estás presentando hoy?');
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

    this.chatService.enviarMensaje(texto, this.historial)
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

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
