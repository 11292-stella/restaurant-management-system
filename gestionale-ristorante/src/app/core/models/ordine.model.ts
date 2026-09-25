import { OrdineRiga } from './ordine-riga.model';

export interface Ordine {
  id: number;
  cliente: string;
  dataOra: string;
  totale: number;
  statoOrdine: number;
  righe: OrdineRiga[];
}