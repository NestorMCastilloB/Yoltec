import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ThemeService } from '../../../services/theme.service';

@Component({
  selector: 'app-doctor-header',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './doctor-header.component.html'
})
export class DoctorHeaderComponent {
  @Input() doctorName = 'Doctor';
  @Input() activeSection = 'inicio';
  @Input() totalPendientes = 0;
  @Output() sectionChange = new EventEmitter<string>();
  @Output() logoutEvent = new EventEmitter<void>();

  constructor(public themeService: ThemeService) {}
}
