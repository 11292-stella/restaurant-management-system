import { Component, OnInit } from '@angular/core';
import { RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { OrdineService } from '../../../core/services/ordine.service';
import { Ordine } from '../../../core/models/ordine.model';
import { MatCardModule } from '@angular/material/card';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatTableModule } from '@angular/material/table';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatSelectModule } from '@angular/material/select';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { BackToMenu } from '../../../shared/back-to-menu/back-to-menu';

@Component({
  selector: 'app-ordini-list',
  standalone: true,
  imports: [
    RouterLink,
    FormsModule,
    CurrencyPipe,
    DatePipe,
    MatCardModule,
    MatIconModule,
    MatButtonModule,
    MatProgressSpinnerModule,
    MatTableModule,
    MatTooltipModule,
    MatSelectModule,
    MatFormFieldModule,
    MatInputModule,
    BackToMenu,
  ],
  templateUrl: './ordini-list.html',
  styleUrl: './ordini-list.scss',
})
export class OrdiniList implements OnInit {
  ordini: Ordine[] = [];
  caricamento = true;
  errore: string | null = null;

  // Filtri: ricerca sul nome cliente e stato ordine. Applicati lato client
  // (ordini già tutti caricati), niente chiamate extra al backend.
  filtroRicerca = '';
  filtroStato: number | null = null;

  readonly statiLabel = ['In attesa', 'In preparazione', 'Pronto', 'Consegnato', 'Annullato'];
  readonly colonne = ['cliente', 'dataOra', 'totale', 'stato', 'azioni'];

  constructor(private ordineService: OrdineService) {}

  ngOnInit(): void {
    this.ordineService.getAll().subscribe({
      next: (ordini) => {
        this.ordini = ordini;
        this.caricamento = false;
      },
      error: () => {
        this.errore = 'Errore nel caricamento degli ordini.';
        this.caricamento = false;
      },
    });
  }

  get ordiniFiltrati(): Ordine[] {
    const ricerca = this.filtroRicerca.trim().toLowerCase();

    return this.ordini.filter((o) => {
      const matchRicerca = !ricerca || o.cliente.toLowerCase().includes(ricerca);
      const matchStato = this.filtroStato === null || o.statoOrdine === this.filtroStato;
      return matchRicerca && matchStato;
    });
  }

  get filtriAttivi(): boolean {
    return this.filtroRicerca.trim() !== '' || this.filtroStato !== null;
  }

  resetFiltri(): void {
    this.filtroRicerca = '';
    this.filtroStato = null;
  }

  onCambiaStato(ordine: Ordine, nuovoStato: number): void {
    this.ordineService.aggiornaStato(ordine.id, nuovoStato).subscribe({
      next: () => {
        ordine.statoOrdine = nuovoStato;
      },
      error: () => {
        this.errore = "Errore durante l'aggiornamento dello stato.";
      },
    });
  }
}