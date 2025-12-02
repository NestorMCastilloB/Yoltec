import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { FormsModule, NgForm } from '@angular/forms';
import { Subject, of } from 'rxjs';
import { catchError, finalize, takeUntil } from 'rxjs/operators';
import { AuthService } from '../services/auth.service';
import { Cita, CitaService, CreateCitaPayload } from '../services/cita.service';
import { Bitacora, BitacoraService } from '../services/bitacora.service';
import { Receta, RecetaService } from '../services/receta.service';

@Component({
  selector: 'app-student-dashboard',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule],
  templateUrl: './student-dashboard.component.html',
  styleUrls: ['./student-dashboard.component.css']
})
export class StudentDashboardComponent implements OnInit, OnDestroy {
  activeSection: string = 'inicio';
  studentName: string = '';
  today: string = this.formatDate(new Date());

  citas: Cita[] = [];
  isLoadingCitas = false;
  citasError: string | null = null;

  bitacoras: Bitacora[] = [];
  isLoadingBitacoras = false;
  bitacorasError: string | null = null;

  recetas: Receta[] = [];
  isLoadingRecetas = false;
  recetasError: string | null = null;

  nextCitaInfo: { fecha: string; hora: string; motivo?: string } | null = null;
  totalCitasProgramadas = 0;

  showCreateForm = false;
  createFormData: Partial<CreateCitaPayload> = {
    fecha_cita: '',
    hora_cita: '',
    motivo: ''
  };
  isSubmitting = false;
  submitMessage: string | null = null;

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
    this.studentName = user ? `${user.nombre} ${user.apellido}` : 'Alumno';
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
    if (section === 'bitacora') {
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

  onCreateCita(form: NgForm): void {
    if (form.invalid) {
      return;
    }

    const payload: CreateCitaPayload = {
      fecha_cita: this.createFormData.fecha_cita!,
      hora_cita: this.createFormData.hora_cita!,
      motivo: this.createFormData.motivo || undefined
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
      });
  }

  private resetForm(): void {
    this.createFormData = {
      fecha_cita: '',
      hora_cita: '',
      motivo: ''
    };
  }

  private updateStats(): void {
    const upcoming = this.citas
      .filter(cita => cita.estatus === 'programada')
      .map(cita => ({
        cita,
        date: this.toDate(cita.fecha_cita, cita.hora_cita)
      }))
      .filter(item => item.date >= new Date())
      .sort((a, b) => a.date.getTime() - b.date.getTime());

    if (upcoming.length > 0) {
      const next = upcoming[0];
      this.nextCitaInfo = {
        fecha: this.formatFullDate(next.cita.fecha_cita),
        hora: next.cita.hora_cita,
        motivo: next.cita.motivo || undefined
      };
    } else {
      this.nextCitaInfo = null;
    }

    this.totalCitasProgramadas = this.citas.filter(cita => cita.estatus === 'programada').length;
  }

  private formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  private formatFullDate(fecha: string): string {
    const date = this.toDate(fecha);
    return new Intl.DateTimeFormat('es-MX', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    }).format(date);
  }

  private toDate(fecha: string, hora?: string): Date {
    const [year, month, day] = fecha.split('-').map(Number);
    if (hora) {
      const [hours, minutes] = hora.split(':').map(Number);
      return new Date(year, month - 1, day, hours, minutes || 0, 0);
    }
    return new Date(year, month - 1, day);
  }

  formatDateDisplay(fecha: string): string {
    return this.formatFullDate(fecha);
  }

  formatBitacoraDate(fecha: string): string {
    return new Intl.DateTimeFormat('es-MX', {
      dateStyle: 'medium',
      timeStyle: 'short'
    }).format(new Date(fecha));
  }

  formatRecetaDate(fecha: string): string {
    return new Intl.DateTimeFormat('es-MX', {
      dateStyle: 'medium'
    }).format(new Date(fecha));
  }
}