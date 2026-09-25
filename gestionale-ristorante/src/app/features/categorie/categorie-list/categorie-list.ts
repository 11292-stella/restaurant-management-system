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

  constructor(private categoriaService: CategoriaService) {}

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
    if (!confirm('Eliminare questa categoria? I prodotti collegati potrebbero causare un errore se non vengono prima spostati o eliminati.')) return;

    this.categoriaService.delete(id).subscribe({
      next: () => {
        this.categorie = this.categorie.filter((c) => c.id !== id);
      },
      error: () => {
        this.errore = "Errore durante l'eliminazione. Probabilmente ci sono ancora prodotti collegati a questa categoria.";
      },
    });
  }
}