import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap } from 'rxjs';
import { API_URL } from '../api-config';

interface LoginRequest {
  username: string;
  password: string;
}

interface AuthResponse {
  token: string;
  user: {
    id: number;
    username: string;
    role: number;
  };
}

@Injectable({
  providedIn: 'root', // registrato automaticamente come singleton globale
})
export class AuthService {
  constructor(private http: HttpClient) {}

  login(credenziali: LoginRequest): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${API_URL}/Auth/login`, credenziali).pipe(
      tap((response) => {
        localStorage.setItem('jwt_token', response.token);
      })
    );
  }

  logout(): void {
    localStorage.removeItem('jwt_token');
  }

  isLoggedIn(): boolean {
    return localStorage.getItem('jwt_token') !== null;
  }
}