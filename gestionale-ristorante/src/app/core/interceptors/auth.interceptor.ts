import { HttpInterceptorFn } from '@angular/common/http';

// Interceptor "funzionale" (stile Angular moderno, niente classi):
// si aggancia a OGNI richiesta HTTP in uscita e, se c'è un token salvato,
// aggiunge l'header Authorization — stesso concetto dell'interceptor
// che avevi scritto in Dio per Flutter
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const token = localStorage.getItem('jwt_token');

  if (token) {
    const clonedReq = req.clone({
      headers: req.headers.set('Authorization', `Bearer ${token}`),
    });
    return next(clonedReq);
  }

  return next(req);
};