import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, throwError } from 'rxjs';

// Interceptor "funzionale" (stile Angular moderno, niente classi):
// si aggancia a OGNI richiesta HTTP in uscita e, se c'è un token salvato,
// aggiunge l'header Authorization — stesso concetto dell'interceptor
// che avevi scritto in Dio per Flutter
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const router = inject(Router);
  const token = localStorage.getItem('jwt_token');

  const richiesta = token
    ? req.clone({ headers: req.headers.set('Authorization', `Bearer ${token}`) })
    : req;

  return next(richiesta).pipe(
    catchError((err: HttpErrorResponse) => {
      // 401 = token scaduto o non valido: senza questa gestione l'utente restava
      // su pagine "Errore nel caricamento" (il guard controlla solo che il token ESISTA).
      // Escluso il login, dove 401 significa solo "credenziali errate".
      if (err.status === 401 && !req.url.includes('/Auth/login')) {
        localStorage.removeItem('jwt_token');
        router.navigate(['/login']);
      }
      return throwError(() => err);
    })
  );
};