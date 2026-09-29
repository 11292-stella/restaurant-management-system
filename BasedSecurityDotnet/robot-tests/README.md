# Test E2E del gestionale ristorante (Robot Framework)

Suite end-to-end per il **gestionale Angular** (area staff) di un sistema per ristoranti, scritta in **Robot Framework** con **Browser Library (Playwright)**. Copre login, prodotti, categorie, ordini, scontrini con pagamento simulato, statistiche, navigazione e sicurezza.

**94 test** in 7 suite. Ogni test crea i propri dati e li cancella a fine test. Il backend è verificato anche dai **49 test API** in xUnit + Playwright .NET, che girano in pipeline GitLab CI.

Applicazione sotto test:
- **Frontend**: Angular 20 + Angular Material.
- **Backend**: ASP.NET Core + Entity Framework + PostgreSQL, in Docker.
- **Ordini**: arrivano da un kiosk Flutter separato, quindi nei test si creano via API.

---

## Stack

| Strumento | Uso |
|---|---|
| **Robot Framework 7** | framework keyword-driven; Python fa solo da motore |
| **Browser Library** | automazione del browser basata su Playwright (Chromium) |
| **RequestsLibrary** | chiamate REST al backend: login, preparazione e pulizia dei dati, verifiche |
| **FakerLibrary** (`it_IT`) | dati di test realistici |
| Librerie standard | `String`, `Collections`, `OperatingSystem`, `DateTime`, `Dialogs` |

---

## Copertura

| Suite | Test | Cosa verifica |
|---|---|---|
| `login.robot` | 3 | login valido, password errata, bottone disabilitato |
| `prodotti.robot` | 30 | lista, ricerca, filtri singoli e combinati, CRUD, validazione del form, doppio click, formati, XSS, accenti |
| `categorie.robot` | 20 | CRUD, nome univoco (409), categoria con prodotti non eliminabile, collegamenti con la lista prodotti |
| `navigazione.robot` | 8 | pagine protette, token non valido, URL inesistenti, card della dashboard, logout + tasto Indietro |
| `ordini.robot` | 20 | lista/filtri, cambio stato, dettaglio e totali, prezzo "fotografato", scontrino in contanti, **pagamento con carta simulato** (rifiuto, annulla, validazione, carta scaduta), prodotto già ordinato non eliminabile |
| `scontrini.robot` | 7 | lista, metodo di pagamento, link all'ordine, eliminazione con conferma, flusso completo |
| `statistiche.robot` | 6 | quantità vendute, ricavo, margine e food cost calcolati a mano, ordini annullati esclusi, soglie di colore |

Tag per lanciare sottoinsiemi: `smoke`, `crud`, `filtri`, `validazione`, `sicurezza`, `navigazione`, `pagamento`, più un tag per ogni sezione.

---

## Scelte tecniche

- **Approccio ibrido UI + API.**
  - Login via API, con il JWT messo nel `localStorage`: la UI di login si testa solo in `login.robot`.
  - I dati si preparano via API e ogni verifica controlla **sia la UI sia il backend**.
- **Page object in file `.resource`.** Selettori nelle `Variables`, azioni e verifiche come keyword riusabili; i `.robot` contengono solo gli scenari (Arrange / Act / Assert).
- **Test indipendenti e ripetibili.**
  - Nomi univoci per ogni dato creato.
  - Il teardown cancella solo ciò che il test ha creato, anche se fallisce a metà.
  - La cancellazione segue l'ordine delle dipendenze: scontrino → ordine → prodotto → categoria. Il backend rifiuta i cascade silenziosi.
- **Numeri verificabili.** Le statistiche si testano su prodotti con prezzo e costo scelti apposta (es. 10 € con costo 2,50 € → food cost 25%), non sui totali del DB.
- **Angular Material.** Keyword dedicate per `mat-select`, `mat-slide-toggle`, `MatDialog` e `MatSnackBar`, e gestione dei `confirm()` nativi con `Promise To  Wait For Alert`.
- **Attese sullo stato, mai `Sleep`.**
  - `Wait For Response` sulle chiamate critiche.
  - `Get Property ... value ==` sui form caricati in modo asincrono.
  - Focus sul primo campo prima di scrivere in un dialog.
- **Credenziali fuori dal codice e dai log.** Variabili d'ambiente, `Set Log Level NONE` e `Fill Secret`.

### Diagnostica e lavoro senza codice sorgente
- **HTML + screenshot automatici** di ogni test fallito (`results/html/FALLITO_<test>.html`).
- **Esploratore** (`tools/salva_pagina.robot`): salva il DOM renderizzato di qualsiasi pagina per ricavare i selettori.
- **Recorder degli endpoint** (`--variable REGISTRA_ENDPOINT:True` + `tools/estrai_endpoint.py`):
  - registra il traffico di rete di ogni test;
  - produce la mappa delle API usate dalla UI: metodo, endpoint normalizzato, status, campi del body;
  - da quella mappa si scrivono i test API.
- **`CHECKLIST_BLACK_BOX.md`**: cosa testare in ogni sezione senza accesso al codice.
- **`CHECKLIST_TEST.md`**: la stessa lista, avendo il codice.

---

## Bug trovati dai test (e corretti)

| Test | Difetto | Correzione |
|---|---|---|
| Categoria con prodotti non eliminabile | `204`: cancellava a cascata prodotti e righe degli ordini storici | 409 nel controller + `OnDelete(Restrict)` con migration |
| Stesso test, lato UI | dopo l'errore la tabella spariva, con un messaggio generico | toast con il messaggio del backend |
| Nome di soli spazi | `Validators.required` accetta `"   "` | validator `nonSoloSpazi` + trim |
| Descrizione facoltativa vuota | form e DTO in disaccordo (400) | DTO allineato al form |
| Doppio click su Salva | due prodotti creati: `[disabled]` non bastava | guardia nel codice |
| Doppio click su "Emetti scontrino" | la 2ª POST tornava 400 e **la pagina mostrava solo l'errore** | flag di emissione + errore in linea |
| Ordine annullato | lo scontrino veniva emesso lo stesso | 400 nel backend, bottoni nascosti |
| Carta scaduta (`01/20`) | accettata: il pattern controllava solo il formato | validator `cartaNonScaduta` |
| Stato ordine `99` via API | salvato: un enum C# accetta qualsiasi intero | `Enum.IsDefined` → 400 |
| Ordine con scontrino eliminato | lo scontrino (documento fiscale) spariva a cascata | 409 |
| URL inesistente / token non valido | pagina bianca / nessun redirect | route `**` + interceptor 401 |

Per ogni correzione: test rosso prima del fix, verde dopo, e dove serve un test API che blocca la regressione.

### Stabilizzazione
- **Suite iniziale: da ~50s con test flaky a ~16s stabile.**
  - Un browser per suite con un contesto isolato per test.
  - `wait_until=domcontentloaded`, così non si aspettano le immagini esterne.
  - Attesa sul valore del form invece che su un tempo fisso.
- **Test flaky del pagamento.** Il testo del CVV finiva nel campo "Titolare" (`Mario Rossi000`) perché, a fine animazione, MatDialog sposta il focus sul primo campo. L'ho individuato grazie all'HTML salvato in automatico e corretto aspettando il focus.

---

## Struttura

```
robot-tests/
├── requirements.txt
├── resources/
│   ├── common.resource          # config, auth via API, navigazione, Material, dati via API, diagnostica, recorder
│   ├── test_data.resource       # data factory con Faker (catalogo piatti, nomi univoci, prezzi/costi)
│   ├── login_page.resource
│   ├── prodotti_page.resource
│   ├── categorie_page.resource
│   └── ordini_page.resource     # ordini, dettaglio, pagamento simulato, scontrini, statistiche
├── tests/
│   ├── __init__.robot           # Suite Setup unico: crea l'utente di test
│   ├── login.robot  prodotti.robot  categorie.robot  navigazione.robot
│   └── ordini.robot  scontrini.robot  statistiche.robot
├── tools/
│   ├── salva_pagina.robot       # esploratore: HTML + screenshot di una pagina
│   └── estrai_endpoint.py       # recorder: mappa degli endpoint dai .har dei test
├── COMANDI.md                   # tutti i comandi, per chi riceve il progetto
├── CHECKLIST_TEST.md            # checklist con codice sorgente
└── CHECKLIST_BLACK_BOX.md       # checklist senza codice sorgente
```

---

## Avvio rapido

Prerequisiti: Python 3.10+, Node.js, Docker Desktop, Angular CLI.

```powershell
# 1. backend + database (dalla root del repo)
docker compose up -d

# 2. frontend (cartella del progetto Angular, finestra da lasciare aperta)
ng serve

# 3. test
cd robot-tests
pip install -r requirements.txt
rfbrowser init
robot --outputdir results tests
start results\report.html
```

Altri comandi utili:
```powershell
robot --outputdir results --suite Ordini tests                    # una suite
robot --outputdir results --include smoke tests                   # per tag
robot --outputdir results --variable HEADLESS:True tests          # senza finestra, come in CI
robot --outputdir results --variable REGISTRA_ENDPOINT:True tests # + python tools/estrai_endpoint.py
```
Il resto (debug, esploratore, reset del DB, test API .NET, errori tipici) è in **[COMANDI.md](COMANDI.md)**.
