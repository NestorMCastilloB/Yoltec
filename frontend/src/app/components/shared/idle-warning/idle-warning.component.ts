import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Subscription } from 'rxjs';
import { AuthService } from '../../../services/auth.service';

// Modal global que avisa al usuario 5 min antes de cerrar la sesión por inactividad.
// AuthService emite el número de minutos restantes vía idleWarning$ (0 = sin aviso).
@Component({
  selector: 'app-idle-warning',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div *ngIf="minutes > 0" class="idle-warning-overlay" role="alertdialog" aria-live="assertive">
      <div class="idle-warning-modal">
        <div class="idle-warning-icon">⏱️</div>
        <h3>Tu sesión está por cerrarse</h3>
        <p>Por inactividad, cerraremos tu sesión en <strong>{{ minutes }} minuto{{ minutes === 1 ? '' : 's' }}</strong>.</p>
        <div class="idle-warning-actions">
          <button class="btn-primary" (click)="continuar()">Continuar sesión</button>
          <button class="btn-secondary" (click)="cerrar()">Cerrar sesión ahora</button>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .idle-warning-overlay {
      position: fixed;
      inset: 0;
      background: rgba(15, 23, 42, 0.55);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 9999;
      animation: fadeIn 120ms ease-out;
    }
    .idle-warning-modal {
      background: var(--surface, #fff);
      color: var(--text-primary, #0f172a);
      border-radius: 12px;
      padding: 28px 32px;
      max-width: 420px;
      width: calc(100% - 32px);
      text-align: center;
      box-shadow: 0 20px 50px rgba(0, 0, 0, 0.25);
    }
    .idle-warning-icon {
      font-size: 40px;
      margin-bottom: 8px;
    }
    .idle-warning-modal h3 {
      margin: 0 0 8px;
      font-size: 18px;
    }
    .idle-warning-modal p {
      margin: 0 0 20px;
      color: var(--text-secondary, #475569);
      font-size: 14px;
    }
    .idle-warning-actions {
      display: flex;
      gap: 8px;
      justify-content: center;
      flex-wrap: wrap;
    }
    .idle-warning-actions button {
      padding: 10px 18px;
      border-radius: 8px;
      border: 0;
      cursor: pointer;
      font-weight: 600;
      font-size: 14px;
    }
    .btn-primary { background: #2563EB; color: #fff; }
    .btn-secondary { background: transparent; color: var(--text-secondary, #475569); border: 1px solid var(--border, #e2e8f0); }
    @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
  `],
})
export class IdleWarningComponent implements OnInit, OnDestroy {
  minutes = 0;
  private sub?: Subscription;

  constructor(private auth: AuthService) {}

  ngOnInit(): void {
    this.sub = this.auth.idleWarning$.subscribe(m => this.minutes = m);
  }

  ngOnDestroy(): void {
    this.sub?.unsubscribe();
  }

  continuar(): void {
    this.auth.extendSession();
  }

  cerrar(): void {
    this.auth.logout();
  }
}
