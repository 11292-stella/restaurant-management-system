import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_URL } from '../api-config';
import { Scontrino } from '../models/scontrino.model';

export interface ScontrinoDto {
  ordineId: number;
  metodoPagamento: number; // 0 = CONTANTI, 1 = CARTA
}

@Injectable({ providedIn: 'root' })
export class ScontrinoService {
  constructor(private http: HttpClient) {}

  getAll(): Observable<Scontrino[]> {
    return this.http.get<Scontrino[]>(`${API_URL}/Scontrino`);
  }

  getById(id: number): Observable<Scontrino> {
    return this.http.get<Scontrino>(`${API_URL}/Scontrino/${id}`);
  }

  getByOrdineId(ordineId: number): Observable<Scontrino> {
    return this.http.get<Scontrino>(`${API_URL}/Scontrino/ordine/${ordineId}`);
  }

  create(dto: ScontrinoDto): Observable<Scontrino> {
    return this.http.post<Scontrino>(`${API_URL}/Scontrino`, dto);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${API_URL}/Scontrino/${id}`);
  }
}