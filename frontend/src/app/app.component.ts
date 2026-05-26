import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { IdleWarningComponent } from './components/shared/idle-warning/idle-warning.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, IdleWarningComponent],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css'
})
export class AppComponent {
  title = 'Sistema Académico';
}