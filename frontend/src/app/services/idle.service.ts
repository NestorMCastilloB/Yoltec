import { Injectable, NgZone, OnDestroy } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';

// Cierra sesion por inactividad. AuthService delega el tracking aqui para no mezclar
// responsabilidades. El callback de timeout permite que el consumidor decida que hacer
// (tipicamente: logout + navegar a /login).
@Injectable({ providedIn: 'root' })
export class IdleService implements OnDestroy {
  private readonly TIMEOUT_MS = 30 * 60 * 1000;
  private readonly WARNING_MS = 5 * 60 * 1000;
  private readonly LAST_ACTIVITY_KEY = 'last_activity';
  private readonly ACTIVITY_EVENTS = ['mousemove', 'keydown', 'click', 'scroll', 'touchstart'];

  private interval: ReturnType<typeof setInterval> | null = null;
  private warningSubject = new BehaviorSubject<number>(0);
  private onTimeoutCallback: (() => void) | null = null;

  warning$: Observable<number> = this.warningSubject.asObservable();

  constructor(private ngZone: NgZone) {}

  ngOnDestroy(): void {
    this.stop();
  }

  start(onTimeout: () => void): void {
    if (this.interval) return;
    this.onTimeoutCallback = onTimeout;
    this.recordActivity();
    this.ACTIVITY_EVENTS.forEach(evt =>
      document.addEventListener(evt, this.handleActivity, { passive: true })
    );
    this.ngZone.runOutsideAngular(() => {
      this.interval = setInterval(() => this.tick(), 30_000);
    });
  }

  stop(): void {
    this.ACTIVITY_EVENTS.forEach(evt =>
      document.removeEventListener(evt, this.handleActivity)
    );
    if (this.interval) {
      clearInterval(this.interval);
      this.interval = null;
    }
    this.warningSubject.next(0);
    this.onTimeoutCallback = null;
  }

  extend(): void {
    this.recordActivity();
    this.warningSubject.next(0);
  }

  isExpired(): boolean {
    const last = localStorage.getItem(this.LAST_ACTIVITY_KEY);
    if (!last) return false;
    return (Date.now() - parseInt(last, 10)) > this.TIMEOUT_MS;
  }

  private handleActivity = (): void => {
    this.recordActivity();
  };

  private recordActivity(): void {
    localStorage.setItem(this.LAST_ACTIVITY_KEY, Date.now().toString());
  }

  private remainingMs(): number {
    const last = localStorage.getItem(this.LAST_ACTIVITY_KEY);
    if (!last) return this.TIMEOUT_MS;
    return this.TIMEOUT_MS - (Date.now() - parseInt(last, 10));
  }

  private tick(): void {
    if (this.isExpired()) {
      this.ngZone.run(() => {
        this.warningSubject.next(0);
        this.onTimeoutCallback?.();
      });
      return;
    }
    const remaining = this.remainingMs();
    const shouldWarn = remaining > 0 && remaining <= this.WARNING_MS;
    const minutes = shouldWarn ? Math.max(1, Math.ceil(remaining / 60_000)) : 0;
    if (minutes !== this.warningSubject.value) {
      this.ngZone.run(() => this.warningSubject.next(minutes));
    }
  }
}
