export interface Prodotto {
  id: number;
  nome: string;
  descrizione: string;
  prezzo: number;
  costoProduzione: number;
  immagineUrl: string | null;
  attivo: boolean;
  esaurito: boolean;
  categoriaId: number;
}