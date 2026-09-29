import { Component, OnInit } from '@angular/core';
import { RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { CategoriaService } from '../../../core/services/categoria.service';
import { Categoria } from '../../../core/models/categoria.model';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatTableModule } from '@angular/material/table';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSnackBar } from '@angular/material/snack-bar';
import { HttpErrorResponse } from '@angular/common/http';
import { BackToMenu } from '../../../shared/back-to-menu/back-to-menu';

@Component({
  selector: 'app-categorie-list',
  standalone: true,
  imports: [
    RouterLink,
    FormsModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule,
    MatTableModule,
    MatTooltipModule,
    MatFormFieldModule,
    MatInputModule,
    BackToMenu,
  ],
  templateUrl: './categorie-list.html',
  styleUrl: './categorie-list.scss',
})
export class CategorieList implements OnInit {
  categorie: Categoria[] = [];
  caricamento = true;
  errore: string | null = null;

  // Ricerca lato client su nome e descrizione (categorie già tutte caricate)
  filtroRicerca = '';

  readonly colonne = ['nome', 'descrizione', 'azioni'];

  constructor(
    private categoriaService: CategoriaService,
    // Notifica temporanea (toast) per gli errori delle azioni: NON sostituisce la tabella
    private snackBar: MatSnackBar,
  ) {}

  ngOnInit(): void {
    this.categoriaService.getAll().subscribe({
      next: (categorie) => {
        this.categorie = categorie;
        this.caricamento = false;
      },
      error: () => {
        this.errore = 'Errore nel caricamento delle categorie.';
        this.caricamento = false;
      },
    });
  }

  get categorieFiltrate(): Categoria[] {
    const ricerca = this.filtroRicerca.trim().toLowerCase();
    if (!ricerca) return this.categorie;

    return this.categorie.filter(
      (c) => c.nome.toLowerCase().includes(ricerca) || (c.descrizione ?? '').toLowerCase().includes(ricerca)
    );
  }

  resetFiltri(): void {
    this.filtroRicerca = '';
  }

  eliminaCategoria(id: number): void {
    if (!confirm('Eliminare questa categoria?')) return;

    this.categoriaService.delete(id).subscribe({
      next: () => {
        this.categorie = this.categorie.filter((c) => c.id !== id);
      },
      error: (err: HttpErrorResponse) => {
        // Il backend risponde 409 con { message } se la categoria contiene prodotti:
        // mostriamo il SUO messaggio (dice quanti prodotti e cosa fare) in un toast,
        // senza usare "errore" (che nasconderebbe tutta la tabella: e' per gli errori di caricamento)
        const messaggio = err.error?.message ?? "Errore durante l'eliminazione della categoria.";
        this.snackBar.open(messaggio, 'Chiudi', { duration: 6000 });
      },
    });
  }
}