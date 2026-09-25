import { Component, OnInit } from '@angular/core';
import { forkJoin } from 'rxjs';
import { CurrencyPipe, DecimalPipe } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { OrdineService } from '../../core/services/ordine.service';
import { ProdottoService } from '../../core/services/prodotto.service';
import { Ordine } from '../../core/models/ordine.model';
import { Prodotto } from '../../core/models/prodotto.model';
import { BackToMenu } from '../../shared/back-to-menu/back-to-menu';

interface RigaStatistica {
  prodottoId: number;
  nome: string;
  quantitaVenduta: number;
  ricavo: number;
  costoStimato: number;
  margine: number;
  foodCostPercent: number; // costoStimato / ricavo * 100
}

const STATO_ANNULLATO = 4;

@Component({
  selector: 'app-statistiche',
  standalone: true,
  imports: [CurrencyPipe, DecimalPipe, MatCardModule, MatIconModule, MatProgressSpinnerModule, BackToMenu],
  templateUrl: './statistiche.html',
  styleUrl: './statistiche.scss',
})
export class Statistiche implements OnInit {
  caricamento = true;
  errore: string | null = null;

  righe: RigaStatistica[] = [];

  ricavoTotale = 0;
  costoTotale = 0;
  margineTotale = 0;
  foodCostMedio = 0;

  constructor(
    private ordineService: OrdineService,
    private prodottoService: ProdottoService
  ) {}

  ngOnInit(): void {
    forkJoin({
      ordini: this.ordineService.getAll(),
      prodotti: this.prodottoService.getAll(),
    }).subscribe({
      next: ({ ordini, prodotti }) => this.calcolaStatistiche(ordini, prodotti),
      error: () => {
        this.errore = 'Errore nel caricamento dei dati per le statistiche.';
        this.caricamento = false;
      },
    });
  }

  // Incrocia le righe ordine (ricavo reale, prezzo fotografato al momento dell'ordine)
  // con il costoProduzione ATTUALE del prodotto: è una stima semplificata di food cost,
  // non tiene conto di eventuali variazioni del costo nel tempo (va bene per un indicatore
  // di massima, non per un report contabile preciso).
  private calcolaStatistiche(ordini: Ordine[], prodotti: Prodotto[]): void {
    const costoPerProdotto = new Map(prodotti.map((p) => [p.id, p.costoProduzione]));
    const aggregati = new Map<number, RigaStatistica>();

    for (const ordine of ordini) {
      if (ordine.statoOrdine === STATO_ANNULLATO) continue; // gli ordini annullati non contano come vendite

      for (const riga of ordine.righe) {
        const costoUnitario = costoPerProdotto.get(riga.prodottoId) ?? 0;
        const ricavoRiga = riga.prezzoUnitario * riga.quantita;
        const costoRiga = costoUnitario * riga.quantita;
        const esistente = aggregati.get(riga.prodottoId);

        if (esistente) {
          esistente.quantitaVenduta += riga.quantita;
          esistente.ricavo += ricavoRiga;
          esistente.costoStimato += costoRiga;
        } else {
          aggregati.set(riga.prodottoId, {
            prodottoId: riga.prodottoId,
            nome: riga.prodotto?.nome ?? `Prodotto #${riga.prodottoId}`,
            quantitaVenduta: riga.quantita,
            ricavo: ricavoRiga,
            costoStimato: costoRiga,
            margine: 0,
            foodCostPercent: 0,
          });
        }
      }
    }

    this.righe = Array.from(aggregati.values())
      .map((r) => ({
        ...r,
        margine: r.ricavo - r.costoStimato,
        foodCostPercent: r.ricavo > 0 ? (r.costoStimato / r.ricavo) * 100 : 0,
      }))
      .sort((a, b) => b.ricavo - a.ricavo);

    this.ricavoTotale = this.righe.reduce((sum, r) => sum + r.ricavo, 0);
    this.costoTotale = this.righe.reduce((sum, r) => sum + r.costoStimato, 0);
    this.margineTotale = this.ricavoTotale - this.costoTotale;
    this.foodCostMedio = this.ricavoTotale > 0 ? (this.costoTotale / this.ricavoTotale) * 100 : 0;

    this.caricamento = false;
  }

  // Soglie indicative da gestione ristorante: food cost sotto il 30% ottimo,
  // 30-40% nella norma, oltre 40% da tenere d'occhio. Semplificato ad uso didattico.
  classeFoodCost(percent: number): string {
    if (percent < 30) return 'ottimo';
    if (percent < 40) return 'normale';
    return 'alto';
  }
}
