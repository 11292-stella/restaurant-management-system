import { Component, OnInit } from '@angular/core';
import { AbstractControl, FormBuilder, FormGroup, ReactiveFormsModule, ValidationErrors, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { CategoriaService } from '../../../core/services/categoria.service';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
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
  selector: 'app-categoria-form',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    RouterLink,
    MatCardModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatIconModule,
    BackToMenu,
  ],
  templateUrl: './categoria-form.html',
  styleUrl: './categoria-form.scss',
})
export class CategoriaForm implements OnInit {
  form: FormGroup;
  modificaId: number | null = null;
  errore: string | null = null;
  salvataggio = false;

  constructor(
    private fb: FormBuilder,
    private categoriaService: CategoriaService,
    private route: ActivatedRoute,
    private router: Router
  ) {
    this.form = this.fb.group({
      nome: ['', [Validators.required, nonSoloSpazi]],
      descrizione: [''],
    });
  }

  ngOnInit(): void {
    const idParam = this.route.snapshot.paramMap.get('id');
    if (idParam) {
      this.modificaId = Number(idParam);
      this.categoriaService.getById(this.modificaId).subscribe({
        next: (categoria) => this.form.patchValue(categoria),
        error: () => (this.errore = 'Categoria non trovata.'),
      });
    }
  }

  onSubmit(): void {
    // Guardia nel codice, non solo nel template: il [disabled] del bottone si aggiorna
    // al giro successivo di change detection, e un doppio click veloce arriva prima
    // (il test E2E "doppio click" creava ancora 2 prodotti con il solo [disabled])
    if (this.form.invalid || this.salvataggio) return;

    // Spazi iniziali/finali tolti prima di inviare (evita "Pizza " e "Pizza" come nomi diversi)
    const dto = {
      nome: (this.form.value.nome ?? '').trim(),
      descrizione: (this.form.value.descrizione ?? '').trim(),
    };

    // Salva disabilitato finche' la richiesta e' in corso: senza, un doppio click
    // avrebbe inviato due richieste
    this.salvataggio = true;
    this.errore = null;

    const richiesta: Observable<unknown> = this.modificaId
      ? this.categoriaService.update(this.modificaId, dto)
      : this.categoriaService.create(dto);

    richiesta.subscribe({
      next: () => this.router.navigate(['/categorie']),
      error: (err: HttpErrorResponse) => {
        // Messaggio del backend se c'e' (es. "Esiste gia' una categoria chiamata ..."), altrimenti generico
        this.errore = err.error?.message ?? 'Errore durante il salvataggio.';
        this.salvataggio = false;
      },
    });
  }
}