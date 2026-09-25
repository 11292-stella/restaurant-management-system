# Restaurant Management System — sviluppo e test automation full-stack

Sistema completo per la gestione di un ristorante, **costruito da zero per esercitarmi sulla test automation a tutti i livelli**: API, E2E web e (in arrivo) E2E mobile, con pipeline CI su Docker.

| Componente | Cartella | Tecnologie |
|---|---|---|
| Backend REST API | `BasedSecurityDotnet/BasedSecurityDotnet` | ASP.NET Core (.NET 10), Entity Framework Core, PostgreSQL, JWT |
| Test API | `BasedSecurityDotnet/BasedSecurityDotnet.ApiTests` | xUnit + Playwright .NET (`IAPIRequestContext`) |
| Test E2E web | `BasedSecurityDotnet/robot-tests` | Robot Framework + Browser Library + RequestsLibrary |
| Gestionale staff | `gestionale-ristorante` | Angular (standalone components) + TypeScript + Angular Material |
| Kiosk self-order | `self_order_kiosk` | Flutter + Riverpod, build Windows standalone |
| Infrastruttura | `BasedSecurityDotnet` | Docker (multi-stage), Docker Compose, GitLab CI |

---

## Architettura

```
┌──────────────────────┐     ┌──────────────────────┐
│  Gestionale Angular  │     │  Kiosk Flutter       │
│  (staff)             │     │  (clienti, ordini)   │
└──────────┬───────────┘     └──────────┬───────────┘
           │        HTTP + JWT          │
           └──────────────┬─────────────┘
                          ▼
              ┌───────────────────────┐
              │  ASP.NET Core Web API │
              │  Auth · Prodotti ·    │
              │  Categorie · Ordini · │
              │  Scontrini            │
              └───────────┬───────────┘
                          ▼
                    PostgreSQL
```

**Dominio:** categorie e prodotti del menu, ordini con righe d'ordine e cambio di stato, scontrini con pagamento in contanti o carta (pagamento simulato), statistiche di vendita e margini.

---

## Livelli di test

| Livello | Strumento | Stato |
|---|---|---|
| API | xUnit + Playwright .NET | ✅ **42 test verdi**, anche in pipeline |
| E2E web (Angular) | Robot Framework + Browser Library | 🔄 in corso: login e prodotti |
| E2E mobile/kiosk (Flutter) | Appium | 🔜 previsto |

### Test API — 42 test su 5 aree

| Classe | Test | Cosa verifica |
|---|---|---|
| `AuthTests` | 5 | login valido e non valido, registrazione, dati mancanti, sicurezza sul ruolo |
| `ProdottoTests` | 8 | CRUD completo, 401 senza token, 404 su id inesistente |
| `CategoriaTests` | 8 | CRUD completo, validazioni, cancellazione |
| `OrdineTests` | 11 | creazione con righe, cambio stato, casi di errore |
| `ScontrinoTests` | 9 | emissione, pagamento, totali |

Scelte principali:

- `ApiTestBase` condivisa, con `IAsyncLifetime` per creare e chiudere il contesto HTTP a ogni test.
- `GetAuthTokenAsync()` "auto-riparante": se l'utente di test non esiste (DB vuoto in CI), lo registra e riprova il login.
- **Ogni test crea i propri dati** tramite API: nessuna dipendenza dai dati già presenti nel database o dall'ordine di esecuzione.
- `API_BASE_URL` da variabile d'ambiente: gli stessi test girano contro il backend in locale o nel container di CI.

### Test E2E web — Robot Framework

- Keyword organizzate come page object in `resources/` (`login_page`, `prodotti_page`, `common`).
- **Preparazione dati via API** con RequestsLibrary: l'utente di test viene creato con una chiamata al backend.
- **Login via API**: il token JWT viene inserito nel localStorage, così i test entrano già autenticati senza ripassare dal form.

---

## Bug reali trovati con i test

1. **Privilege escalation** — `/api/Auth/register` accetta il campo `Role` dal client: chiunque può registrarsi come ADMIN. Il test lo dimostra ricevendo 200.
2. **Cancellazione a cascata silenziosa** — eliminando una categoria vengono eliminati senza avviso tutti i prodotti collegati.

---

## CI/CD

La pipeline GitLab (`BasedSecurityDotnet/.gitlab-ci.yml`) esegue i test API in un ambiente pulito a ogni push:

1. build dell'immagine del backend (Dockerfile multi-stage: SDK per la build, runtime ASP.NET per l'immagine finale);
2. avvio di backend + **Postgres usa e getta** con Docker Compose;
3. migration EF Core e seed del menu applicati automaticamente all'avvio;
4. esecuzione dei 42 test in un container dedicato e pubblicazione del report JUnit come artifact.

Problemi risolti lungo la strada:

- **Race condition** tra classi di test eseguite in parallelo → esecuzione sequenziale con `DisableTestParallelization`.
- **Test dipendenti dai dati** che fallivano solo su DB vuoto → ogni test crea i propri dati.
- **Conflitto di porte** tra ambiente locale e CI → override con `docker-compose.ci.yml` e tag `!override`.
- **Bind-mount vuoto** usando il socket Docker dell'host → codice copiato nell'immagine di test con `COPY` invece che montato.

---

## Come avviarlo in locale

### 1. Backend + database

```bash
cd BasedSecurityDotnet
cp .env.example .env        # poi imposta le tue password e la chiave JWT
docker compose up --build
# API su http://localhost:5231
```

### 2. Test API

```bash
cd BasedSecurityDotnet
API_BASE_URL=http://localhost:5231 dotnet test BasedSecurityDotnet.ApiTests
```

Su PowerShell:

```powershell
$env:API_BASE_URL="http://localhost:5231"; dotnet test BasedSecurityDotnet.ApiTests
```

### 3. Gestionale Angular

```bash
cd gestionale-ristorante
npm install
npx ng serve
# http://localhost:4200
```

### 4. Test E2E Robot Framework

```bash
cd BasedSecurityDotnet/robot-tests
pip install -r requirements.txt
rfbrowser init
robot --outputdir results tests
```

### 5. Kiosk Flutter

```bash
cd self_order_kiosk
flutter pub get
flutter run -d windows
```

---

## Roadmap

- [x] Backend REST con autenticazione JWT
- [x] Gestionale Angular e kiosk Flutter
- [x] 42 test API verdi in pipeline GitLab CI con Docker
- [ ] E2E del gestionale con Robot Framework (in corso)
- [ ] Job E2E in pipeline
- [ ] E2E del kiosk con Appium
- [ ] Demo pubblica del gestionale
