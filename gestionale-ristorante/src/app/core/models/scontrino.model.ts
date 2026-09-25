export interface Scontrino {
  id: number;
  dataEmissione: string;
  importo: number;
  metodoPagamento: number; // 0 = CONTANTI, 1 = CARTA (stesso discorso di statoOrdine)
  ordineId: number;
}