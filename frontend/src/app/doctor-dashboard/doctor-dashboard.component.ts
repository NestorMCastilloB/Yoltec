import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { FormsModule, NgForm } from '@angular/forms';
import { Subject, of } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { AuthService } from '../services/auth.service';
import { Cita, CitaService, CreateCitaPayload } from '../services/cita.service';
import { Bitacora, BitacoraService, CreateBitacoraPayload } from '../services/bitacora.service';
import { Receta, RecetaService, CreateRecetaPayload } from '../services/receta.service';

@Component({
  selector: 'app-doctor-dashboard',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule],
  templateUrl: './doctor-dashboard.component.html',
  styleUrls: ['./doctor-dashboard.component.css']
})
export class DoctorDashboardComponent implements OnInit, OnDestroy {
  activeSection: string = 'inicio';
  doctorName: string = 'Doctor';
  today: string = this.formatDate(new Date());

  citas: Cita[] = [];
  isLoadingCitas = false;
  citasError: string | null = null;

  showCreateForm = false;
  isSubmitting = false;
  submitMessage: string | null = null;

  createFormData: Partial<CreateCitaPayload & { numero_control: string }> = {
    fecha_cita: '',
    hora_cita: '',
    motivo: '',
    numero_control: ''
  };

  todayAppointments = 0;
  patientsAttended = 0;
  pendingBitacoras = 0;

  bitacoras: Bitacora[] = [];
  isLoadingBitacoras = false;
  bitacorasError: string | null = null;
  showBitacoraForm = false;
  isSubmittingBitacora = false;
  bitacoraMessage: string | null = null;
  bitacoraFormData: Partial<CreateBitacoraPayload> = {
    cita_id: undefined,
    diagnostico: '',
    tratamiento: '',
    observaciones: '',
    peso: '',
    altura: '',
    temperatura: '',
    presion_arterial: ''
  };

  recetas: Receta[] = [];
  isLoadingRecetas = false;
  recetasError: string | null = null;
  showRecetaForm = false;
  isSubmittingReceta = false;
  recetaMessage: string | null = null;
  recetaFormData: Partial<CreateRecetaPayload> = {
    cita_id: undefined,
    medicamentos: '',
    indicaciones: '',
    fecha_emision: this.formatDate(new Date())
  };

  private destroy$ = new Subject<void>();

  constructor(
    private router: Router,
    private authService: AuthService,
    private citaService: CitaService,
    private bitacoraService: BitacoraService,
    private recetaService: RecetaService
  ) {}

  ngOnInit(): void {
    const user = this.authService.getCurrentUser();
    this.doctorName = user ? `${user.nombre} ${user.apellido}` : 'Doctor';
    this.loadCitas();
    this.loadBitacoras();
    this.loadRecetas();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  setActiveSection(section: string) {
    this.activeSection = section;
    if (section === 'citas') {
      this.loadCitas();
    }
    if (section === 'bitacoras') {
      this.loadBitacoras();
    }
    if (section === 'recetas') {
      this.loadRecetas();
    }
  }

  toggleCreateForm(): void {
    this.showCreateForm = !this.showCreateForm;
    this.submitMessage = null;
    if (!this.showCreateForm) {
      this.resetForm();
    }
  }

  toggleBitacoraForm(): void {
    this.showBitacoraForm = !this.showBitacoraForm;
    this.bitacoraMessage = null;
    if (!this.showBitacoraForm) {
      this.resetBitacoraForm();
    }
  }

  toggleRecetaForm(): void {
    this.showRecetaForm = !this.showRecetaForm;
    this.recetaMessage = null;
    if (!this.showRecetaForm) {
      this.resetRecetaForm();
    }
  }

  onCreateCita(form: NgForm): void {
    if (form.invalid || !this.createFormData.numero_control?.trim()) {
      this.submitMessage = 'Ingresa el número de control del alumno.';
      return;
    }

    const payload: CreateCitaPayload = {
      fecha_cita: this.createFormData.fecha_cita!,
      hora_cita: this.createFormData.hora_cita!,
      motivo: this.createFormData.motivo || undefined,
      numero_control: this.createFormData.numero_control.trim()
    };

    this.isSubmitting = true;
    this.submitMessage = null;

    this.citaService.createCita(payload)
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => {
          this.submitMessage = error?.error?.message || 'No se pudo agendar la cita.';
          return of(null);
        }),
        finalize(() => {
          this.isSubmitting = false;
        })
      )
      .subscribe(response => {
        if (response?.cita) {
          this.submitMessage = 'Cita agendada correctamente.';
          this.loadCitas();
          this.resetForm();
          this.showCreateForm = false;
        }
      });
  }

  onCreateReceta(form: NgForm): void {
    if (form.invalid || !this.recetaFormData.cita_id || !this.recetaFormData.medicamentos?.trim()) {
      this.recetaMessage = 'Selecciona la cita y captura los medicamentos.';
      return;
    }

    const payload: CreateRecetaPayload = {
      cita_id: Number(this.recetaFormData.cita_id),
      medicamentos: this.recetaFormData.medicamentos.trim(),
      indicaciones: this.recetaFormData.indicaciones?.trim() || undefined,
      fecha_emision: this.recetaFormData.fecha_emision || this.formatDate(new Date())
    };

    this.isSubmittingReceta = true;
    this.recetaMessage = null;

    this.recetaService.createReceta(payload)
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => {
          this.recetaMessage = error?.error?.message || 'No se pudo registrar la receta.';
          return of(null);
        }),
        finalize(() => {
          this.isSubmittingReceta = false;
        })
      )
      .subscribe(response => {
        if (response?.receta) {
          this.recetaMessage = 'Receta registrada correctamente.';
          this.loadRecetas();
          this.resetRecetaForm();
          this.showRecetaForm = false;
        }
      });
  }

  onCancelCita(cita: Cita): void {
    if (this.isSubmitting) {
      return;
    }

    this.isSubmitting = true;
    this.citaService.cancelCita(cita.id)
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => {
          this.submitMessage = error?.error?.message || 'No se pudo cancelar la cita.';
          return of(null);
        }),
        finalize(() => {
          this.isSubmitting = false;
        })
      )
      .subscribe(response => {
        if (response?.cita) {
          this.submitMessage = 'Cita cancelada correctamente.';
          this.loadCitas();
        }
      });
  }

  onMarkAsAttended(cita: Cita): void {
    if (this.isSubmitting) {
      return;
    }

    this.isSubmitting = true;
    this.citaService.markAsAttended(cita.id)
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => {
          this.submitMessage = error?.error?.message || 'No se pudo marcar como atendida.';
          return of(null);
        }),
        finalize(() => {
          this.isSubmitting = false;
        })
      )
      .subscribe(response => {
        if (response?.cita) {
          this.submitMessage = 'Cita marcada como atendida.';
          this.loadCitas();
          this.loadBitacoras();
          this.loadRecetas();
        }
      });
  }

  onCreateBitacora(form: NgForm): void {
    if (form.invalid || !this.bitacoraFormData.cita_id) {
      this.bitacoraMessage = 'Selecciona la cita atendida correspondiente.';
      return;
    }

    const payload: CreateBitacoraPayload = {
      cita_id: Number(this.bitacoraFormData.cita_id),
      diagnostico: this.bitacoraFormData.diagnostico || undefined,
      tratamiento: this.bitacoraFormData.tratamiento || undefined,
      observaciones: this.bitacoraFormData.observaciones || undefined,
      peso: this.bitacoraFormData.peso || undefined,
      altura: this.bitacoraFormData.altura || undefined,
      temperatura: this.bitacoraFormData.temperatura || undefined,
      presion_arterial: this.bitacoraFormData.presion_arterial || undefined
    };

    this.isSubmittingBitacora = true;
    this.bitacoraMessage = null;

    this.bitacoraService.createBitacora(payload)
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => {
          this.bitacoraMessage = error?.error?.message || 'No se pudo registrar la bitácora.';
          return of(null);
        }),
        finalize(() => {
          this.isSubmittingBitacora = false;
        })
      )
      .subscribe(response => {
        if (response?.bitacora) {
          this.bitacoraMessage = 'Bitácora registrada correctamente.';
          this.loadBitacoras();
          this.resetBitacoraForm();
          this.showBitacoraForm = false;
        }
      });
  }

  logout() {
    this.authService.logout();
    this.router.navigate(['/login']);
  }

  private loadCitas(): void {
    this.isLoadingCitas = true;
    this.citasError = null;

    this.citaService.getCitas()
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => {
          this.citasError = error?.error?.message || 'No se pudieron obtener las citas.';
          return of([] as Cita[]);
        }),
        finalize(() => {
          this.isLoadingCitas = false;
        })
      )
      .subscribe(citas => {
        this.citas = citas;
        this.updateStats();
      });
  }

  private loadBitacoras(): void {
    this.isLoadingBitacoras = true;
    this.bitacorasError = null;

    this.bitacoraService.getBitacoras()
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => {
          this.bitacorasError = error?.error?.message || 'No se pudieron obtener las bitácoras.';
          return of([] as Bitacora[]);
        }),
        finalize(() => {
          this.isLoadingBitacoras = false;
        })
      )
      .subscribe(bitacoras => {
        this.bitacoras = bitacoras;
        this.updateStats();
      });
  }

  private loadRecetas(): void {
    this.isLoadingRecetas = true;
    this.recetasError = null;

    this.recetaService.getRecetas()
      .pipe(
        takeUntil(this.destroy$),
        catchError(error => {
          this.recetasError = error?.error?.message || 'No se pudieron obtener las recetas.';
          return of([] as Receta[]);
        }),
        finalize(() => {
          this.isLoadingRecetas = false;
        })
      )
      .subscribe(recetas => {
        this.recetas = recetas;
        this.updateStats();
      });
  }

  private resetForm(): void {
    this.createFormData = {
      fecha_cita: '',
      hora_cita: '',
      motivo: '',
      numero_control: ''
    };
  }

  private resetBitacoraForm(): void {
    this.bitacoraFormData = {
      cita_id: undefined,
      diagnostico: '',
      tratamiento: '',
      observaciones: '',
      peso: '',
      altura: '',
      temperatura: '',
      presion_arterial: ''
    };
  }

  private resetRecetaForm(): void {
    this.recetaFormData = {
      cita_id: undefined,
      medicamentos: '',
      indicaciones: '',
      fecha_emision: this.formatDate(new Date())
    };
  }

  private updateStats(): void {
    this.todayAppointments = this.citas.filter(cita => cita.estatus === 'programada' && cita.fecha_cita === this.today).length;
    this.patientsAttended = this.citas.filter(cita => cita.estatus === 'atendida').length;
    const bitacoraCitaIds = new Set(this.bitacoras.map(bitacora => bitacora.cita_id));
    this.pendingBitacoras = this.citas.filter(cita => cita.estatus === 'atendida' && !bitacoraCitaIds.has(cita.id)).length;
  }

  formatDateDisplay(fecha: string): string {
    return this.formatFullDate(fecha);
  }

  get availableCitasForBitacora(): Cita[] {
    return this.citas.filter(cita => cita.estatus === 'atendida');
  }

  formatBitacoraDate(fecha: string): string {
    return new Intl.DateTimeFormat('es-MX', {
      dateStyle: 'medium',
      timeStyle: 'short'
    }).format(new Date(fecha));
  }

  get availableCitasForReceta(): Cita[] {
    return this.citas.filter(cita => cita.estatus === 'atendida');
  }

  formatRecetaDate(fecha: string): string {
    return new Intl.DateTimeFormat('es-MX', {
      dateStyle: 'medium'
    }).format(new Date(fecha));
  }

  private formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  private formatFullDate(fecha: string): string {
    const [year, month, day] = fecha.split('-').map(Number);
    const date = new Date(year, (month ?? 1) - 1, day ?? 1);
    return new Intl.DateTimeFormat('es-MX', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    }).format(date);
  }
}