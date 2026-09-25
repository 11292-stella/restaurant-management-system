import { Component, Inject } from '@angular/core';
import { CurrencyPipe } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';

export interface PagamentoSimulatoData {
  importo: number;
}

// Componente puramente di TEST: non contatta nessun gateway di pagamento reale,
// serve solo a simulare un checkout con carta per collaudare il flusso
// (e in futuro per gli script di test automatico Playwright/Appium).
@Component({
  selector: 'app-pagamento-simulato',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    CurrencyPipe,
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule,
  ],
  templateUrl: './pagamento-simulato.html',
  styleUrl: './pagamento-simulato.scss',
})
export class PagamentoSimulato {
  form: FormGroup;
  elaborazione = false;
  esitoErrore: string | null = null;

  constructor(
    private fb: FormBuilder,
    private dialogRef: MatDialogRef<PagamentoSimulato, boolean>,
    @Inject(MAT_DIALOG_DATA) public data: PagamentoSimulatoData
  ) {
    this.form = this.fb.group({
      titolare: ['', Validators.required],
      numeroCarta: ['', [Validators.required, Validators.pattern(/^\d{4} \d{4} \d{4} \d{4}$/)]],
      scadenza: ['', [Validators.required, Validators.pattern(/^(0[1-9]|1[0-2])\/\d{2}$/)]],
      cvv: ['', [Validators.required, Validators.pattern(/^\d{3}$/)]],
    });
  }

  // Aggiunge automaticamente uno spazio ogni 4 cifre mentre si digita il numero carta
  onNumeroCartaInput(event: Event): void {
    const input = event.target as HTMLInputElement;
    const cifre = input.value.replace(/\D/g, '').slice(0, 16);
    const formattato = cifre.match(/.{1,4}/g)?.join(' ') ?? cifre;
    this.form.get('numeroCarta')?.setValue(formattato, { emitEvent: false });
  }

  // Inserisce automaticamente lo slash tra mese e anno (MM/AA)
  onScadenzaInput(event: Event): void {
    const input = event.target as HTMLInputElement;
    const cifre = input.value.replace(/\D/g, '').slice(0, 4);
    const formattato = cifre.length > 2 ? `${cifre.slice(0, 2)}/${cifre.slice(2)}` : cifre;
    this.form.get('scadenza')?.setValue(formattato, { emitEvent: false });
  }

  // Solo per la grafica della finta carta: capisce se mostrare "VISA" o "Mastercard"
  // guardando la prima cifra (4xxx = Visa, 5xxx = Mastercard), come in un vero BIN check.
  get circuito(): string {
    const primaCifra = (this.form.get('numeroCarta')?.value as string)?.[0];
    if (primaCifra === '4') return 'VISA';
    if (primaCifra === '5') return 'Mastercard';
    return 'CARTA';
  }

  onAnnulla(): void {
    this.dialogRef.close(false);
  }

  onPaga(): void {
    if (this.form.invalid) return;

    this.elaborazione = true;
    this.esitoErrore = null;

    // Simulazione di una chiamata a un gateway di pagamento: nessuna richiesta reale,
    // solo un ritardo finto per riprodurre l'esperienza utente da testare.
    setTimeout(() => {
      this.elaborazione = false;

      // Trucco utile in fase di test: CVV "000" simula sempre un pagamento rifiutato,
      // così si può testare anche il ramo di errore senza logica random.
      if (this.form.value.cvv === '000') {
        this.esitoErrore = 'Pagamento rifiutato dalla banca (simulazione).';
        return;
      }

      this.dialogRef.close(true);
    }, 1200);
  }
}
