import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class ThemeService {
  private readonly key = 'dark_mode';

  constructor() {
    if (localStorage.getItem(this.key) === 'true') {
      document.body.classList.add('dark-mode');
    }
  }

  get isDark(): boolean {
    return document.body.classList.contains('dark-mode');
  }

  toggle(): void {
    if (this.isDark) {
      document.body.classList.remove('dark-mode');
      localStorage.setItem(this.key, 'false');
    } else {
      document.body.classList.add('dark-mode');
      localStorage.setItem(this.key, 'true');
    }
  }
}
