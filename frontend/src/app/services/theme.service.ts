import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class ThemeService {
  private readonly key = 'dark_mode';

  constructor() {
    if (localStorage.getItem(this.key) === 'true') {
      document.documentElement.classList.add('dark');
    }
  }

  get isDark(): boolean {
    return document.documentElement.classList.contains('dark');
  }

  toggle(): void {
    if (this.isDark) {
      document.documentElement.classList.remove('dark');
      localStorage.setItem(this.key, 'false');
    } else {
      document.documentElement.classList.add('dark');
      localStorage.setItem(this.key, 'true');
    }
  }
}
