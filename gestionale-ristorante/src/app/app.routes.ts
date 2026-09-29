import { Routes } from '@angular/router';
import { Login } from './features/login/login';
import { Dashboard } from './features/dashboard/dashboard';
import { ProdottiList } from './features/prodotti/prodotti-list/prodotti-list';
import { ProdottoForm } from './features/prodotti/prodotto-form/prodotto-form';
import { authGuard } from './core/guards/auth-guard';
import { CategorieList } from './features/categorie/categorie-list/categorie-list';
import { CategoriaForm } from './features/categorie/categoria-form/categoria-form';
import { OrdiniList } from './features/ordini/ordini-list/ordini-list';
import { OrdineDetail } from './features/ordini/ordine-detail/ordine-detail';
import { ScontriniList } from './features/scontrini/scontrini-list/scontrini-list';
import { Statistiche } from './features/statistiche/statistiche';

export const routes: Routes = [
  { path: 'login', component: Login },
  { path: '', component: Dashboard, canActivate: [authGuard] },
  { path: 'prodotti', component: ProdottiList, canActivate: [authGuard] },
  { path: 'prodotti/nuovo', component: ProdottoForm, canActivate: [authGuard] },
  { path: 'prodotti/:id', component: ProdottoForm, canActivate: [authGuard] },
  { path: 'categorie', component: CategorieList, canActivate: [authGuard] },
  { path: 'categorie/nuovo', component: CategoriaForm, canActivate: [authGuard] },
  { path: 'categorie/:id', component: CategoriaForm, canActivate: [authGuard] },
  { path: 'ordini', component: OrdiniList, canActivate: [authGuard] },
  { path: 'ordini/:id', component: OrdineDetail, canActivate: [authGuard] },
  { path: 'scontrini', component: ScontriniList, canActivate: [authGuard] },
  { path: 'statistiche', component: Statistiche, canActivate: [authGuard] },
  // URL inesistente -> dashboard (che a sua volta rimanda al login se non autenticati).
  // Prima: pagina bianca. Deve restare l'ULTIMA route.
  { path: '**', redirectTo: '' },
];
