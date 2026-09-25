import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { CategoriaService } from '../../../core/services/categoria.service';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { BackToMenu } from '../../../shared/back-to-menu/back-to-menu';

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

  constructor(
    private fb: FormBuilder,
    private categoriaService: CategoriaService,
    private route: ActivatedRoute,
    private router: Router
  ) {
    this.form = this.fb.group({
      nome: ['', Validators.required],
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
    if (this.form.invalid) return;

    const dto = this.form.value;

    if (this.modificaId) {
      this.categoriaService.update(this.modificaId, dto).subscribe({
        next: () => this.router.navigate(['/categorie']),
        error: () => (this.errore = 'Errore durante il salvataggio.'),
      });
    } else {
      this.categoriaService.create(dto).subscribe({
        next: () => this.router.navigate(['/categorie']),
        error: () => (this.errore = 'Errore durante il salvataggio.'),
      });
    }
  }
}