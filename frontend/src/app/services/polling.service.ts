import { Injectable } from '@angular/core';
import { NEVER, Observable, fromEvent, merge, timer } from 'rxjs';
import { map, startWith, switchMap } from 'rxjs/operators';

@Injectable({ providedIn: 'root' })
export class PollingService {
  // Emite cada intervalSec mientras la pestana este visible. Pausa al ocultarse para no quemar el plan free de Render.
  poll(intervalSec: number): Observable<number> {
    const ms = Math.max(5, intervalSec) * 1000;
    if (typeof document === 'undefined') return timer(ms, ms);

    return fromEvent(document, 'visibilitychange').pipe(
      map(() => document.visibilityState === 'visible'),
      startWith(document.visibilityState === 'visible'),
      switchMap(visible => visible ? timer(ms, ms) : NEVER),
    );
  }
}
