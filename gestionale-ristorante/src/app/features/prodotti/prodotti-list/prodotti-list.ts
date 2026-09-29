import { Component, OnInit } from '@angular/core';
import { RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { ProdottoService } from '../../../core/services/prodotto.service';
import { CategoriaService } from '../../../core/services/categoria.service';
import { Prodotto } from '../../../core/models/prodotto.model';
import { Categoria } from '../../../core/models/categoria.model';
import { CurrencyPipe } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatChipsModule } from '@angular/material/chips';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatTableModule } from '@angular/material/table';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatSnackBar } from '@angular/material/snack-bar';
import { HttpErrorResponse } from '@angular/common/http';
import { BackToMenu } from '../../../shared/back-to-menu/back-to-menu';

type FiltroStato = 'tutti' | 'attivo' | 'esaurito' | 'disattivo';

@Component({
  selector: 'app-prodotti-list',
  standalone: true,
  imports: [
    RouterLink,
    FormsModule,
    CurrencyPipe,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatChipsModule,
    MatProgressSpinnerModule,
    MatTableModule,
    MatTooltipModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    BackToMenu,
  ],
  templateUrl: './prodotti-list.html',
  styleUrl: './prodotti-list.scss',
})
export class ProdottiList implements OnInit {
  prodotti: Prodotto[] = [];
  categorie: Categoria[] = [];
  caricamento = true;
  errore: string | null = null;

  // Filtri: ricerca testuale sul nome, categoria e stato. Applicati lato client
  // (i prodotti sono già tutti caricati), niente chiamate extra al backend.
  filtroRicerca = '';
  filtroCategoriaId: number | null = null;
  filtroStato: FiltroStato = 'tutti';

  readonly colonne = ['immagine', 'nome', 'categoria', 'prezzo', 'costoProduzione', 'stato', 'azioni'];

  constructor(
    private prodottoService: ProdottoService,
    private categoriaService: CategoriaService,
    // Notifica temporanea (toast) per gli errori delle azioni: NON sostituisce la tabella
    private snackBar: MatSnackBar,
  ) {}

  ngOnInit(): void {
    this.categoriaService.getAll().subscribe({
      next: (categorie) => {
        this.categorie = categorie;
        this.caricaProdotti();
      },
      error: () => {
        this.errore = 'Errore nel caricamento delle categorie.';
        this.caricamento = false;
      },
    });
  }

  private caricaProdotti(): void {
    this.prodottoService.getAll().subscribe({
      next: (prodotti) => {
        this.prodotti = prodotti;
        this.caricamento = false;
      },
      error: () => {
        this.errore = 'Errore nel caricamento dei prodotti.';
        this.caricamento = false;
      },
    });
  }

  get prodottiFiltrati(): Prodotto[] {
    const ricerca = this.filtroRicerca.trim().toLowerCase();

    return this.prodotti.filter((p) => {
      const matchRicerca = !ricerca || p.nome.toLowerCase().includes(ricerca);
      const matchCategoria = this.filtroCategoriaId === null || p.categoriaId === this.filtroCategoriaId;
      const matchStato =
        this.filtroStato === 'tutti' ||
        (this.filtroStato === 'disattivo' && !p.attivo) ||
        (this.filtroStato === 'esaurito' && p.attivo && p.esaurito) ||
        (this.filtroStato === 'attivo' && p.attivo && !p.esaurito);
      return matchRicerca && matchCategoria && matchStato;
    });
  }

  get filtriAttivi(): boolean {
    return this.filtroRicerca.trim() !== '' || this.filtroCategoriaId !== null || this.filtroStato !== 'tutti';
  }

  resetFiltri(): void {
    this.filtroRicerca = '';
    this.filtroCategoriaId = null;
    this.filtroStato = 'tutti';
  }

  nomeCategoria(categoriaId: number): string {
    return this.categorie.find((c) => c.id === categoriaId)?.nome ?? '—';
  }

  eliminaProdotto(id: number): void {
    if (!confirm('Eliminare questo prodotto?')) return;

    this.prodottoService.delete(id).subscribe({
      next: () => {
        this.prodotti = this.prodotti.filter((p) => p.id !== id);
      },
      error: (err: HttpErrorResponse) => {
        // Il backend risponde 409 con { message } se il prodotto e' gia' presente in ordini:
        // mostriamo il suo messaggio ("disattivalo invece di eliminarlo") in un toast,
        // senza usare "errore" (che nasconderebbe tutta la tabella: e' per gli errori di caricamento)
        const messaggio = err.error?.message ?? "Errore durante l'eliminazione del prodotto.";
        this.snackBar.open(messaggio, 'Chiudi', { duration: 6000 });
      },
    });
  }
}