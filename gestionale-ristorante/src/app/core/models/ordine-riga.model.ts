import { Prodotto } from './prodotto.model';

export interface OrdineRiga {
  id: number;
  ordineId: number;
  prodottoId: number;
  prodotto: Prodotto;
  quantita: number;
  prezzoUnitario: number;
}