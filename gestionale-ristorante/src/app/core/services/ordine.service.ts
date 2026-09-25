import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_URL } from '../api-config';
import { Ordine } from '../models/ordine.model';

export interface OrdineRigaInputDto {
  prodottoId: number;
  quantita: number;
}

export interface OrdineCreateDto {
  cliente: string;
  righe: OrdineRigaInputDto[];
}

@Injectable({ providedIn: 'root' })
export class OrdineService {
  constructor(private http: HttpClient) {}

  getAll(): Observable<Ordine[]> {
    return this.http.get<Ordine[]>(`${API_URL}/Ordine`);
  }

  getById(id: number): Observable<Ordine> {
    return this.http.get<Ordine>(`${API_URL}/Ordine/${id}`);
  }

  create(dto: OrdineCreateDto): Observable<Ordine> {
    return this.http.post<Ordine>(`${API_URL}/Ordine`, dto);
  }

  // Il backend si aspetta il numero nudo nel body (vedi PUT /Ordine/{id}/stato),
  // non un oggetto { statoOrdine: ... }
  aggiornaStato(id: number, nuovoStato: number): Observable<void> {
    return this.http.put<void>(`${API_URL}/Ordine/${id}/stato`, nuovoStato);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${API_URL}/Ordine/${id}`);
  }
}