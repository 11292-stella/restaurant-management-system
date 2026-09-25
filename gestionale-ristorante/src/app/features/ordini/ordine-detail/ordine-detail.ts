import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { catchError, of } from 'rxjs';
import { OrdineService } from '../../../core/services/ordine.service';
import { Ordine } from '../../../core/models/ordine.model';
import { ScontrinoService } from '../../../core/services/scontrino.service';
import { Scontrino } from '../../../core/models/scontrino.model';
import { MatCardModule } from '@angular/material/card';
import { MatIconModule } from '@angular/material/icon';
import { MatChipsModule } from '@angular/material/chips';
import { MatButtonModule } from '@angular/material/button';
import { MatTableModule } from '@angular/material/table';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import { BackToMenu } from '../../../shared/back-to-menu/back-to-menu';
import { PagamentoSimulato, PagamentoSimulatoData } from '../../../shared/pagamento-simulato/pagamento-simulato';

@Component({
  selector: 'app-ordine-detail',
  standalone: true,
  imports: [
    RouterLink,
    CurrencyPipe,
    DatePipe,
    MatCardModule,
    MatIconModule,
    MatChipsModule,
    MatButtonModule,
    MatTableModule,
    MatDialogModule,
    BackToMenu,
  ],
  templateUrl: './ordine-detail.html',
  styleUrl: './ordine-detail.scss',
})
export class OrdineDetail implements OnInit {
  ordine: Ordine | null = null;
  scontrino: Scontrino | null = null;
  errore: string | null = null;

  readonly statiLabel = ['In attesa', 'In preparazione', 'Pronto', 'Consegnato', 'Annullato'];
  readonly metodiLabel = ['Contanti', 'Carta'];
  readonly colonne = ['prodotto', 'quantita', 'prezzoUnitario', 'subtotale'];

  constructor(
    private ordineService: OrdineService,
    private scontrinoService: ScontrinoService,
    private route: ActivatedRoute,
    private dialog: MatDialog
  ) {}

  ngOnInit(): void {
    const id = Number(this.route.snapshot.paramMap.get('id'));

    this.ordineService.getById(id).subscribe({
      next: (ordine) => (this.ordine = ordine),
      error: () => (this.errore = 'Ordine non trovato.'),
    });

    // Se l'ordine non ha ancora uno scontrino, il backend risponde con un errore
    // (probabilmente 404) — non è un vero errore per noi, significa solo che
    // possiamo ancora emetterlo. catchError lo intercetta e restituisce null
    // invece di far fallire tutto l'observable.
    this.scontrinoService
      .getByOrdineId(id)
      .pipe(catchError(() => of(null)))
      .subscribe((scontrino) => (this.scontrino = scontrino));
  }

  // Apre il dialogo di pagamento simulato (carta di test, nessun gateway reale).
  // Lo scontrino viene emesso solo se il "pagamento" va a buon fine, così il
  // flusso è identico a quello reale ed è pronto per gli script di test E2E.
  pagaConCarta(): void {
    if (!this.ordine) return;

    const dialogRef = this.dialog.open<PagamentoSimulato, PagamentoSimulatoData, boolean>(PagamentoSimulato, {
      data: { importo: this.ordine.totale },
    });

    dialogRef.afterClosed().subscribe((pagamentoRiuscito) => {
      if (pagamentoRiuscito) {
        this.emettiScontrino(1);
      }
    });
  }

  emettiScontrino(metodoPagamento: number): void {
    if (!this.ordine) return;

    this.scontrinoService.create({ ordineId: this.ordine.id, metodoPagamento }).subscribe({
      next: (scontrino) => (this.scontrino = scontrino),
      error: () => (this.errore = "Errore durante l'emissione dello scontrino."),
    });
  }
}