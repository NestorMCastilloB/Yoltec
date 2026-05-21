import { Component, EventEmitter, Input, Output } from '@angular/core';

@Component({
  selector: 'app-admin-sidebar',
  standalone: true,
  imports: [],
  templateUrl: './admin-sidebar.component.html',
  styleUrls: ['./admin-sidebar.component.css']
})
export class AdminSidebarComponent {
  @Input() activeSection = 'panel';
  @Input() adminName = 'Administrador';
  @Output() sectionChange = new EventEmitter<string>();

  isOpen = false;

  toggle(): void { this.isOpen = !this.isOpen; }
  close(): void { this.isOpen = false; }

  onNavigate(section: string): void {
    this.sectionChange.emit(section);
    this.isOpen = false;
  }

  get initials(): string {
    return this.adminName.split(' ').slice(0, 2).map(p => p[0]).join('').toUpperCase();
  }
}
