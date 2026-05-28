import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AdminStats } from '../../dashboard/admin-dashboard.service';
import { DiaEspecial, TIPO_LABELS } from '../../../../services/calendario-admin.service';
import { UsuarioRow, formatFechaDia } from '../admin-utils';

@Component({
  selector: 'app-admin-panel',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './admin-panel.component.html',
})
export class AdminPanelComponent {
  @Input() stats: AdminStats | null = null;
  @Input() panelUsuarios: UsuarioRow[] = [];
  @Input() diasProximos: DiaEspecial[] = [];
  @Input() isLoadingStats = false;
  @Input() isLoadingPanel = false;
  @Input() fechaHoy = '';

  @Output() navigateToUsuarios = new EventEmitter<void>();
  @Output() navigateToCalendario = new EventEmitter<void>();

  readonly tipoLabels = TIPO_LABELS;
  readonly formatFechaDia = formatFechaDia;
}
