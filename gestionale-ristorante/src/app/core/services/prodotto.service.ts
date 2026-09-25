import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_URL } from '../api-config';
import { Prodotto } from '../models/prodotto.model';

export interface ProdottoDto {
  nome: string;
  descrizione: string;
  prezzo: number;
  costoProduzione: number;
  immagineUrl: string | null;
  attivo: boolean;
  esaurito: boolean;
  categoriaId: number;
}

@Injectable({ providedIn: 'root' })
export class ProdottoService {
  constructor(private http: HttpClient) {}

  getAll(): Observable<Prodotto[]> {
    return this.http.get<Prodotto[]>(`${API_URL}/Prodotto`);
  }

  getById(id: number): Observable<Prodotto> {
    return this.http.get<Prodotto>(`${API_URL}/Prodotto/${id}`);
  }

  create(dto: ProdottoDto): Observable<Prodotto> {
    return this.http.post<Prodotto>(`${API_URL}/Prodotto`, dto);
  }

  update(id: number, dto: ProdottoDto): Observable<void> {
    return this.http.put<void>(`${API_URL}/Prodotto/${id}`, dto);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${API_URL}/Prodotto/${id}`);
  }
}