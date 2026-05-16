import { Component, ElementRef, ViewChild, AfterViewChecked, OnInit, OnDestroy, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subject, of, forkJoin } from 'rxjs';
import { takeUntil, finalize, catchError } from 'rxjs/operators';
import {
  PreEvaluacionChatService,
  MensajeChat,
  DiagnosticoIA,
  RespuestaChat,
  PreEvaluacionExistente,
} from './pre-evaluacion-ia.service';
import { CitaService } from '../../../services/cita.service';

interface MensajeUI {
  tipo: 'ai' | 'user';
  contenido: string;
  hora: string;
}

interface CitaOpcion {
  id: number;
  fecha: string;
  hora: string;
  etiqueta: string;
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

  // Citas futuras + selección
  citasFuturas: CitaOpcion[] = [];
  citaIdSeleccionada: number | null = null;
  cargandoCita = true;
  sinCita = false;

  // Pre-evaluaciones previas indexadas por cita_id
  preEvalPorCita = new Map<number, PreEvaluacionExistente>();
  preEvaluacionActual: PreEvaluacionExistente | null = null;

  @Output() solicitaAgendar = new EventEmitter<void>();

  // Resultado IA del chat actual
  diagnosticos: DiagnosticoIA[] = [];
  sintomasDetectados: string[] = [];
  recomendaciones: string[] = [];
  mostrarResultado = false;

  private destroy$ = new Subject<void>();

  constructor(
    private chatService: PreEvaluacionChatService,
    private citaService: CitaService,
  ) {}

  ngOnInit(): void {
    forkJoin({
      citas: this.citaService.getCitas().pipe(catchError(() => of([] as any[]))),
      preEvals: this.chatService.listarPreEvaluaciones().pipe(catchError(() => of([] as PreEvaluacionExistente[]))),
    })
      .pipe(takeUntil(this.destroy$), finalize(() => this.cargandoCita = false))
      .subscribe(({ citas, preEvals }) => {
        for (const pe of preEvals) {
          this.preEvalPorCita.set(pe.cita_id, pe);
        }

        this.citasFuturas = (citas || [])
          .filter((c: any) => c.estatus === 'programada')
          .map((c: any) => {
            const fecha = String(c.fecha_cita || c.fecha || '').split('T')[0];
            const hora = String(c.hora_cita || c.hora_inicio || '').slice(0, 5);
            return { id: c.id, fecha, hora, etiqueta: this.formatearEtiqueta(fecha, hora) };
          })
          .filter(c => !!c.fecha && !!c.hora)
          .sort((a, b) => `${a.fecha} ${a.hora}`.localeCompare(`${b.fecha} ${b.hora}`));

        if (this.citasFuturas.length === 0) {
          this.sinCita = true;
          return;
        }

        this.seleccionarCita(this.citasFuturas[0].id);
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

  onCambiarCita(id: number | string): void {
    const num = typeof id === 'string' ? Number(id) : id;
    if (!num || num === this.citaIdSeleccionada) return;
    this.seleccionarCita(num);
  }

  private seleccionarCita(id: number): void {
    this.citaIdSeleccionada = id;
    this.error = '';
    this.mensajes = [];
    this.historial = [];
    this.diagnosticos = [];
    this.sintomasDetectados = [];
    this.recomendaciones = [];
    this.mostrarResultado = false;
    this.textoInput = '';

    const previa = this.preEvalPorCita.get(id) || null;
    this.preEvaluacionActual = previa;

    if (previa) return;

    this.agregarMensajeIA('Hola, soy tu asistente médico. Cuéntame, ¿qué síntomas estás presentando hoy?');
  }

  onKeydown(event: KeyboardEvent): void {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      this.enviar();
    }
  }

  enviar(): void {
    const texto = this.textoInput.trim();
    if (!texto || this.enviando) return;
    if (!this.citaIdSeleccionada) {
      this.error = 'Selecciona una cita para continuar.';
      return;
    }

    this.error = '';
    this.textoInput = '';
    this.autoResize();

    this.mensajes.push({ tipo: 'user', contenido: texto, hora: this.horaActual() });
    this.historial.push({ rol: 'user', contenido: texto });
    this.enviando = true;
    this.shouldScroll = true;

    this.chatService.enviarMensaje(this.citaIdSeleccionada, texto, this.historial.slice(0, -1))
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
    this.solicitaAgendar.emit();
  }

  autoResize(): void {
    const ta = this.inputRef?.nativeElement;
    if (ta) {
      ta.style.height = 'auto';
      ta.style.height = Math.min(ta.scrollHeight, 96) + 'px';
    }
  }

  porcentaje(confianza: number): number {
    return Math.round((confianza || 0) * 100);
  }

  etiquetaEstatus(estatus: string): string {
    return estatus === 'validado' ? 'Validado por el doctor'
         : estatus === 'descartado' ? 'Descartado por el doctor'
         : 'Pendiente de validación';
  }

  private formatearEtiqueta(fecha: string, hora: string): string {
    if (!fecha) return hora;
    const [y, m, d] = fecha.split('-').map(Number);
    if (!y || !m || !d) return `${fecha} · ${hora}`;
    const meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return `${d} ${meses[m - 1]} · ${hora}`;
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
