# Checklist black box: test E2E senza codice sorgente

Come testare un gestionale **che non hai scritto e di cui non vedi il codice**: cosa verificare in ogni sezione, come scoprire le regole nascoste e come ricavare le API dalla UI.

È complementare a `CHECKLIST_TEST.md`, che è la checklist "da mentore" per scrivere i test avendo il codice. Questa ne è la versione **black box**: ogni voce si verifica solo da browser, DevTools e chiamate API.

> Le voci con 🐞 su questo progetto hanno trovato un difetto reale.

---

## 0. Kit di partenza (prima di scrivere un test)

### 0.1 Salvare l'HTML delle pagine (per trovare i selettori)
```powershell
robot --outputdir results --variable PAGINA:/ordini tools/salva_pagina.robot
robot --outputdir results --variable PAGINA:/ordini/1 --variable DEBUG:True tools/salva_pagina.robot   # dialog, menu aperti
```
Il file `results\html\_ordini_<data>.html` va aperto in VS Code. Poi `Ctrl+F` sul testo visibile e si sceglie il selettore:

| Preferenza | Esempio |
|---|---|
| ruolo + nome accessibile | `role=textbox[name="Cerca cliente"]`, `role=option[name="Pronto"]` |
| attributi stabili | `button[mattooltip="Dettaglio"]`, `input[formcontrolname="cvv"]` |
| riga di tabella per testo | `tr:has-text("Tavolo 4") >> td.mat-column-totale` |
| testo esatto (evita `#12` che trova `#123`) | `a.ordine-link:text-is("#12")` |
| ❌ da evitare | `#mat-input-3`, `.mat-mdc-select-3`, catene di classi generate |

### 0.2 Registrare gli endpoint chiamati dalla UI (recorder)
Con il recorder la UI ti dice quali API usa, anche senza Swagger e senza codice.
```powershell
robot --outputdir results --variable REGISTRA_ENDPOINT:True tests
python tools/estrai_endpoint.py
start results\endpoint\endpoint.md
```
Come funziona:
- ogni test registra il traffico del browser in `results/har/<nome test>.har` (keyword `Nuovo Contesto` in `common.resource`, `recordHar` di Playwright);
- lo script unisce tutti i file e produce una tabella con **metodo, endpoint normalizzato, status visti, campi del body, n. di test**.

Esempio di output reale (sezioni Ordini/Scontrini):

| Metodo | Endpoint | Status visti | Campi body |
|---|---|---|---|
| PUT | `/api/Ordine/{id}/stato` | 204 | `<int>` (numero nudo nel body) |
| POST | `/api/Scontrino` | 201 | metodoPagamento, ordineId |
| GET | `/api/Scontrino/ordine/{id}` | 200, 404 | - |
| DELETE | `/api/Prodotto/{id}` | 409 | - |

Da qui escono i test API da scrivere:
- ogni riga va testata senza token (401) e con un id inesistente (404);
- ogni status visto è un caso da coprire;
- ogni campo del body va provato vuoto, di soli spazi, al limite e con il tipo sbagliato.

> ⚠️ I file `.har` contengono header e token JWT: restano in `results/`, che è in `.gitignore`. **Non vanno mai condivisi.** L'output `endpoint.md` contiene solo i nomi dei campi, quindi si può condividere.

### 0.3 Scoprire le regole del backend senza codice
```robot
# body vuoto -> ASP.NET risponde 400 con l'elenco dei campi obbligatori e i loro messaggi
${resp}=    POST On Session    api    /api/Ordine    json=${{ {} }}    headers=${headers}    expected_status=400
Log    ${resp.json()}[errors]
# valore fuori dall'enum -> accettato? (su questo progetto: si' -> bug)
PUT On Session    api    /api/Ordine/${id}/stato    json=${99}    headers=${headers}    expected_status=any
```
Altre fonti utili:
- **Swagger** (`/swagger`), se esposto;
- **DevTools → Network** mentre si usa il form.

### 0.4 Scoprire le regole del frontend senza codice
- Nell'HTML salvato: `required`, `maxlength`, `min`, `type="password"`, `formcontrolname`.
- Provare i campi uno alla volta (vuoto, spazi, 0, negativo, formato sbagliato) e guardare se **Salva/Paga si disabilita**.
- Regola d'oro: si parte da **dati validi → bottone abilitato**, poi si rompe **un solo campo**.

---

## 1. Login
- [ ] Credenziali valide → dashboard (`smoke`)
- [ ] Password errata → messaggio, resta su /login
- [ ] Campi vuoti → Accedi disabilitato
- [ ] La password non compare in log/report (`Fill Secret`, `Set Log Level NONE` nelle chiamate API)

## 2. Navigazione e sicurezza (trasversale)
- [ ] **Ogni** pagina protetta, senza login, rimanda a /login (lista in `@{PAGINE_PROTETTE}`), anche i dettagli (`/ordini/1`)
- [ ] 🐞 Token falso nel localStorage → torna al login e il token viene cancellato
- [ ] 🐞 URL inesistente: da loggato va alla dashboard, senza login al login (prima dava una pagina bianca)
- [ ] Ogni card della dashboard apre la sua sezione e "Torna al menu" riporta indietro
- [ ] Logout + tasto Indietro → non si rientra

## 3. Liste (Prodotti, Categorie, Ordini, Scontrini)
- [ ] Si apre dalla dashboard con i dati base (`smoke`)
- [ ] Ricerca: per tutti i campi dichiarati e senza distinguere maiuscole/minuscole
- [ ] Ogni filtro da solo, **incluso lo stato raro** (creato via API: esaurito, disattivo, annullato)
- [ ] Filtri combinati + messaggio "nessun risultato"
- [ ] "Azzera filtri" svuota ricerca e filtri, e compare solo quando serve
- [ ] Formati: valuta (`€24.50`), date (`dd/MM/yyyy HH:mm`), placeholder per i dati mancanti
- [ ] Testo visto dall'utente ≠ testo nel DOM: con `text-transform: uppercase` Get Text restituisce `GIULIA BIANCHI`

```robot
Get Text    tr:has-text("${cliente}") >> td.mat-column-dataOra    matches    ^\\d{2}/\\d{2}/\\d{4} \\d{2}:\\d{2}$
```

## 4. CRUD (Prodotti, Categorie)
- [ ] Crea / modifica / elimina → verifica in lista **e** via API
- [ ] Modifica: il form arriva popolato con **tutti** i campi
- [ ] Annulla (form e confirm) → backend invariato
- [ ] 🐞 Eliminare un elemento **con dati collegati** (categoria con prodotti, prodotto già ordinato) → 409 e messaggio, niente cascade
- [ ] 🐞 Campo di soli spazi, campo facoltativo vuoto, doppio click su Salva
- [ ] Accenti/simboli identici; HTML mostrato come testo (XSS)

## 5. Ordini (dati creati via API: gli ordini arrivano dal kiosk)
- [ ] Lista: totale, stato, data; ricerca cliente; filtro stato; azzera
- [ ] Cambio stato dalla lista → PUT 204, stato giusto via API e dopo `Reload`
- [ ] 🐞 Stato fuori dall'enum via API (`99`) → 400 (prima veniva salvato)
- [ ] Dettaglio: righe, quantità, prezzo unitario, subtotali, totale
- [ ] Prezzo "fotografato": cambiare il prezzo del prodotto **dopo** l'ordine non cambia l'ordine
- [ ] Ordine inesistente → "Ordine non trovato."
- [ ] 🐞 Eliminare un ordine con scontrino → 409 (prima spariva anche lo scontrino)

## 6. Scontrino e pagamento simulato
- [ ] Contanti → "Scontrino emesso (Contanti)", importo = totale (via API)
- [ ] 🐞 **Doppio click** su "Emetti scontrino" → nessun errore a schermo (prima: la 2ª POST tornava 400 e la pagina mostrava solo l'errore)
- [ ] 🐞 Ordine **annullato** → niente bottoni, niente scontrino (prima veniva emesso)
- [ ] Carta: importo nel bottone Paga, dialog chiuso, metodo Carta via API
- [ ] Pagamento rifiutato (CVV `000`) → messaggio, dialog aperto, nessuno scontrino
- [ ] Annulla nel dialog → nessuno scontrino
- [ ] Campi carta: numero incompleto, mese 13, CVV di 2 cifre, titolare vuoto → Paga disabilitato
- [ ] 🐞 **Carta scaduta** (`01/20`) → "Carta scaduta" e Paga disabilitato (prima veniva accettata)
- [ ] Formattazione automatica (`4242 4242 4242 4242`, `12/35`) e circuito riconosciuto (VISA/Mastercard)
- [ ] 🐞 (test flaky) Dopo l'apertura del dialog aspettare il focus sul primo campo, altrimenti il testo finisce nel campo sbagliato

```robot
Click    ${BOTTONE_SCONTRINO_CARTA}
Wait For Elements State    ${INPUT_TITOLARE}    focused    # fine animazione MatDialog
```

## 7. Lista scontrini
- [ ] Importo, metodo, data; il link `#id` apre l'ordine
- [ ] Elimina con conferma → sparisce, API 404, l'ordine torna "da pagare"
- [ ] Annulla sul confirm → resta
- [ ] Lo scontrino emesso dal dettaglio compare in lista (flusso completo)

## 8. Statistiche (numeri calcolati a mano)
Si creano prodotti con prezzo e costo scelti apposta: i totali generali dipendono da tutto il DB, la riga del **proprio** prodotto invece no.
- [ ] Prezzo 10, costo 2,50, venduti 2 → ricavo €20.00, margine €15.00, food cost 25% (ottimo)
- [ ] Più ordini dello stesso prodotto si sommano
- [ ] Gli ordini **annullati** non contano
- [ ] Soglie di colore: <30% ottimo, 30–40% normale, ≥40% alto
- [ ] Il ricavo usa il prezzo dell'ordine, non quello attuale

---

## 9. Chiusura di ogni sezione
- [ ] Ogni test crea i **propri** dati (nomi univoci) e il teardown li cancella nell'ordine giusto: scontrino → ordine → prodotto → categoria
- [ ] Ogni bug trovato: test rosso prima del fix, verde dopo, e un test API che lo blocca
- [ ] Suite lanciata **3 volte di fila** verde (niente flaky)
- [ ] Recorder rilanciato: nuovi endpoint → nuovi test API
