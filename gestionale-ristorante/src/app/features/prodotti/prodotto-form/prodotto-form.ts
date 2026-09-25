import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { ProdottoService } from '../../../core/services/prodotto.service';
import { CategoriaService } from '../../../core/services/categoria.service';
import { Categoria } from '../../../core/models/categoria.model';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { BackToMenu } from '../../../shared/back-to-menu/back-to-menu';

@Component({
  selector: 'app-prodotto-form',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    RouterLink,
    MatCardModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatSlideToggleModule,
    MatButtonModule,
    MatIconModule,
    BackToMenu,
  ],
  templateUrl: './prodotto-form.html',
  styleUrl: './prodotto-form.scss',
})
export class ProdottoForm implements OnInit {
  form: FormGroup;
  categorie: Categoria[] = [];
  modificaId: number | null = null;
  errore: string | null = null;

  constructor(
    private fb: FormBuilder,
    private prodottoService: ProdottoService,
    private categoriaService: CategoriaService,
    private route: ActivatedRoute,
    private router: Router
  ) {
    this.form = this.fb.group({
      nome: ['', Validators.required],
      descrizione: [''],
      prezzo: [0, [Validators.required, Validators.min(0)]],
      costoProduzione: [0, [Validators.required, Validators.min(0)]],
      immagineUrl: [''],
      attivo: [true],
      esaurito: [false],
      categoriaId: [null, Validators.required],
    });
  }

  ngOnInit(): void {
    this.categoriaService.getAll().subscribe({
      next: (categorie) => (this.categorie = categorie),
      error: () => (this.errore = 'Errore nel caricamento delle categorie.'),
    });

    const idParam = this.route.snapshot.paramMap.get('id');
    if (idParam) {
      this.modificaId = Number(idParam);
      this.prodottoService.getById(this.modificaId).subscribe({
        next: (prodotto) => this.form.patchValue(prodotto),
        error: () => (this.errore = 'Prodotto non trovato.'),
      });
    }
  }

  onSubmit(): void {
    if (this.form.invalid) return;

    const dto = this.form.value;

    if (this.modificaId) {
      this.prodottoService.update(this.modificaId, dto).subscribe({
        next: () => this.router.navigate(['/prodotti']),
        error: () => (this.errore = 'Errore durante il salvataggio.'),
      });
    } else {
      this.prodottoService.create(dto).subscribe({
        next: () => this.router.navigate(['/prodotti']),
        error: () => (this.errore = 'Errore durante il salvataggio.'),
      });
    }
  }
}