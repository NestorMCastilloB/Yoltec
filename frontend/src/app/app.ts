import { Component, signal } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { IdleWarningComponent } from './components/shared/idle-warning/idle-warning.component';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, IdleWarningComponent],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css'
})
export class App {
  protected readonly title = signal('login');
}
