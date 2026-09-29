import { Component, OnInit } from '@angular/core';
import { AbstractControl, FormBuilder, FormGroup, ReactiveFormsModule, ValidationErrors, Validators } from '@angular/forms';
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
import { HttpErrorResponse } from '@angular/common/http';
import { Observable } from 'rxjs';
import { BackToMenu } from '../../../shared/back-to-menu/back-to-menu';

// Validators.required considera valido "   " (non e' una stringa vuota):
// questo validator rifiuta anche i valori fatti di soli spazi.
function nonSoloSpazi(control: AbstractControl): ValidationErrors | null {
  const valore = (control.value ?? '') as string;
  return valore.trim().length === 0 ? { soloSpazi: true } : null;
}

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
  salvataggio = false;

  constructor(
    private fb: FormBuilder,
    private prodottoService: ProdottoService,
    private categoriaService: CategoriaService,
    private route: ActivatedRoute,
    private router: Router
  ) {
    this.form = this.fb.group({
      nome: ['', [Validators.required, nonSoloSpazi]],
      descrizione: [''],
      // min 0.01 come il backend ([Range(0.01, ...)]): prima il form accettava 0 e il backend rispondeva 400
      prezzo: [0, [Validators.required, Validators.min(0.01)]],
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
    // Guardia nel codice, non solo nel template: il [disabled] del bottone si aggiorna
    // al giro successivo di change detection, e un doppio click veloce arriva prima
    // (il test E2E "doppio click" creava ancora 2 prodotti con il solo [disabled])
    if (this.form.invalid || this.salvataggio) return;

    // Spazi iniziali/finali tolti dai campi di testo prima di inviare
    const valori = this.form.value;
    const dto = {
      ...valori,
      nome: (valori.nome ?? '').trim(),
      descrizione: (valori.descrizione ?? '').trim(),
      immagineUrl: (valori.immagineUrl ?? '').trim(),
    };

    // Salva disabilitato finche' la richiesta e' in corso: senza, un doppio click
    // creava DUE prodotti identici (trovato dal test E2E "doppio click su Salva")
    this.salvataggio = true;
    this.errore = null;

    const richiesta: Observable<unknown> = this.modificaId
      ? this.prodottoService.update(this.modificaId, dto)
      : this.prodottoService.create(dto);

    richiesta.subscribe({
      next: () => this.router.navigate(['/prodotti']),
      error: (err: HttpErrorResponse) => {
        // Messaggio del backend se c'e' (es. validazione), altrimenti generico
        this.errore = err.error?.message ?? 'Errore durante il salvataggio.';
        this.salvataggio = false;
      },
    });
  }
}