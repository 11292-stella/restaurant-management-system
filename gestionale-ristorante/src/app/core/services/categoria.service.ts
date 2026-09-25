import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_URL } from '../api-config';
import { Categoria } from '../models/categoria.model';

export interface CategoriaDto {
  nome: string;
  descrizione: string;
}

@Injectable({ providedIn: 'root' })
export class CategoriaService {
  constructor(private http: HttpClient) {}

  getAll(): Observable<Categoria[]> {
    return this.http.get<Categoria[]>(`${API_URL}/Categoria`);
  }

  getById(id: number): Observable<Categoria> {
    return this.http.get<Categoria>(`${API_URL}/Categoria/${id}`);
  }

  create(dto: CategoriaDto): Observable<Categoria> {
    return this.http.post<Categoria>(`${API_URL}/Categoria`, dto);
  }

  update(id: number, dto: CategoriaDto): Observable<void> {
    return this.http.put<void>(`${API_URL}/Categoria/${id}`, dto);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${API_URL}/Categoria/${id}`);
  }
}