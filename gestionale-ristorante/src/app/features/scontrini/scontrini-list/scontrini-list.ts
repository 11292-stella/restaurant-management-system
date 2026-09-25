import { Component, OnInit } from '@angular/core';
import { RouterLink } from '@angular/router';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { ScontrinoService } from '../../../core/services/scontrino.service';
import { Scontrino } from '../../../core/models/scontrino.model';
import { MatCardModule } from '@angular/material/card';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatChipsModule } from '@angular/material/chips';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatTableModule } from '@angular/material/table';
import { MatTooltipModule } from '@angular/material/tooltip';
import { BackToMenu } from '../../../shared/back-to-menu/back-to-menu';

@Component({
  selector: 'app-scontrini-list',
  standalone: true,
  imports: [
    RouterLink,
    CurrencyPipe,
    DatePipe,
    MatCardModule,
    MatIconModule,
    MatButtonModule,
    MatChipsModule,
    MatProgressSpinnerModule,
    MatTableModule,
    MatTooltipModule,
    BackToMenu,
  ],
  templateUrl: './scontrini-list.html',
  styleUrl: './scontrini-list.scss',
})
export class ScontriniList implements OnInit {
  scontrini: Scontrino[] = [];
  caricamento = true;
  errore: string | null = null;

  readonly metodiLabel = ['Contanti', 'Carta'];
  readonly colonne = ['dataEmissione', 'ordineId', 'importo', 'metodo', 'azioni'];

  constructor(private scontrinoService: ScontrinoService) {}

  ngOnInit(): void {
    this.scontrinoService.getAll().subscribe({
      next: (scontrini) => {
        this.scontrini = scontrini;
        this.caricamento = false;
      },
      error: () => {
        this.errore = 'Errore nel caricamento degli scontrini.';
        this.caricamento = false;
      },
    });
  }

  eliminaScontrino(id: number): void {
    if (!confirm('Eliminare questo scontrino?')) return;

    this.scontrinoService.delete(id).subscribe({
      next: () => {
        this.scontrini = this.scontrini.filter((s) => s.id !== id);
      },
      error: () => {
        this.errore = "Errore durante l'eliminazione.";
      },
    });
  }
}
