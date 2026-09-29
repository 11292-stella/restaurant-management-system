# Checklist test E2E — da seguire per ogni nuova sezione

Nata completando **Prodotti** e **Categorie**: ogni voce ha trovato (o escluso) un difetto reale.
Per una nuova sezione (Ordini, Scontrini, Statistiche...) si scorre la lista e per ogni voce si decide:
**test**, **non applicabile**, oppure **decisione di business** (da scrivere in `PROGRESS.md`).

Legenda: 🐞 = voce che su Prodotti/Categorie ha trovato un difetto.

---

## 0. Prima di scrivere i test

- [ ] **Leggere il codice** (componente `.ts` + `.html`, controller e DTO del backend) o, senza sorgente, salvare l'HTML con l'esploratore:
  ```powershell
  robot --outputdir results --variable PAGINA:/ordini tools/salva_pagina.robot
  robot --outputdir results --variable PAGINA:/ordini --variable DEBUG:True tools/salva_pagina.robot
  ```
- [ ] Confrontare **regole del form** e **regole del backend**: ogni differenza è un sospetto 🐞
  (descrizione facoltativa nel form ma `[Required]` nel DTO; prezzo `min(0)` nel form ma `[Range(0.01, ...)]` nel backend).
  - **Con il codice**: validators Angular ↔ DataAnnotations del DTO.
  - **Senza il codice del backend** (black box), le regole si scoprono lo stesso:
    1. **Swagger/OpenAPI** (es. `/swagger`), se esposto: campi obbligatori, tipi, min/max.
    2. **Chiamare l'API con un body vuoto o con valori limite** (Postman o RequestsLibrary): ASP.NET risponde 400
       con l'elenco dei campi non validi e i loro messaggi.
       ```robot
       ${resp}=    POST On Session    api    /api/Prodotto    json=${{ {} }}    headers=${headers}    expected_status=400
       Log    ${resp.json()}[errors]    # {"Nome": ["Il nome è obbligatorio"], "Descrizione": [...], ...}
       ```
    3. **DevTools → Network** mentre si salva dal form: richiesta inviata, status e risposta dell'errore.
  - **Senza il codice del frontend**: i validators si ricavano provando i campi (vuoto, spazi, 0, negativo) e guardando
    se Salva si disabilita; l'HTML dell'esploratore mostra `required`, `min`, `type="number"`.
  - In ogni caso i test "campo facoltativo vuoto si salva" e "valore limite" scoprono il disallineamento da soli:
    il form lascia salvare, il backend rifiuta → il test resta sul form e fallisce.
- [ ] Creare `resources/<sezione>_page.resource` (selettori in `*** Variables ***`, azioni e verifiche in `*** Keywords ***`)
  e `tests/<sezione>.robot` con `Test Setup  Apri Gestionale Da Loggato` e `Test Teardown  Chiudi Contesto`.

## 1. Lista

- [ ] Si apre dalla dashboard e mostra i dati base (`smoke`)
- [ ] Ricerca: trova per nome **e** per gli altri campi dichiarati (es. descrizione), esclude il resto
- [ ] Ogni filtro da solo (categoria, stato...) — **incluso lo stato "raro"** (Disattivo) creando il dato via API
- [ ] Regole nascoste dei filtri (su Prodotti "Attivo" = attivo **e** non esaurito)
- [ ] Filtri combinati + messaggio "nessun risultato"
- [ ] "Azzera filtri/ricerca": ripristina tutto e il bottone compare solo quando serve (`detached`)
- [ ] Badge/etichette di stato e **priorità** tra stati (Disattivo batte Esaurito)
- [ ] Formati: valuta (`€5.50`), date, trattino per campi vuoti (`—`), placeholder per immagini mancanti

```robot
Verifica Cella Prodotto    ${nome}    prezzo    €5.50
Wait For Elements State    ${BOTTONE_AZZERA_FILTRI}    detached
```

## 2. CRUD

- [ ] Crea dal form → presente in lista **e** nel backend (GET via API)
- [ ] Modifica: il form arriva **popolato con tutti i campi** (non solo il nome) e titolo "Modifica ..."
- [ ] Modifica di un campo relazionale (es. cambio categoria) → la lista mostra il nuovo valore
- [ ] Annulla in modifica → backend invariato (verifica via API)
- [ ] Elimina con conferma → sparisce da lista e backend (404)
- [ ] Annulla sul confirm → resta
- [ ] 🐞 Elimina un elemento **con dati collegati** → comportamento atteso deciso (su Categorie: 409 + messaggio, niente cascade)
- [ ] 🐞 L'errore dell'eliminazione è **visibile** e la tabella **resta** (toast `mat-snack-bar-container`)

```robot
${attesa}=    Promise To    Wait For Response    matcher=**/api/Categoria/${cat_id}
Elimina Categoria Dalla Lista    ${nome}    accept
${risposta}=    Wait For    ${attesa}
Should Be Equal As Integers    ${risposta}[status]    409
Verifica Notifica    Impossibile eliminare la categoria
```

## 3. Validazione del form

Regola: prima si verifica **Salva abilitato con dati validi**, poi si rompe **un solo campo**.

- [ ] Form vuoto → Salva disabilitato
- [ ] Ogni campo obbligatorio svuotato → disabilitato
- [ ] 🐞 Campo di **soli spazi** (`${SPACE}${SPACE}${SPACE}`) → disabilitato (`Validators.required` lo accetta!)
- [ ] Numeri: negativo, **zero**, limite minimo valido (0.01)
- [ ] 🐞 Campi facoltativi **lasciati vuoti** → si salva davvero (il backend potrebbe rifiutarli)
- [ ] 🐞 **Doppio click su Salva** → un solo elemento creato
- [ ] Annulla dal form → niente creato
- [ ] Errore del backend mostrato nel form con il **suo** messaggio (es. 409 nome duplicato)

```robot
Compila Form Prodotto    ${prodotto}
Verifica Salva Abilitato
Fill Text    ${INPUT_PREZZO}    0
Verifica Salva Disabilitato

Click With Options    ${BOTTONE_SALVA}    clickCount=2
Wait For Load State    networkidle
${quanti}=    Conta Prodotti Con Nome Via API    ${prodotto}[nome]
Should Be Equal As Integers    ${quanti}    1
```

## 4. Dati particolari

- [ ] Accenti e simboli (`Caffè & Cornetto àèìòù €`) salvati e mostrati identici
- [ ] 🐞 Duplicati: decidere se vanno bloccati (Categorie: sì, 409 case-insensitive; Prodotti: no)
- [ ] **XSS**: `<b>...</b><img src=x onerror=alert(1)>` mostrato come testo, nessun elemento creato
- [ ] URL di un elemento inesistente (`/prodotti/999999`) → messaggio "non trovato"

```robot
Get Element Count    tr:has-text("${nome}") >> td.mat-column-nome b    ==    0
```

## 5. Collegamenti tra sezioni

- [ ] Una modifica in una sezione si vede nelle altre (rinomina categoria → colonna e filtro dei prodotti)
- [ ] Un elemento nuovo è subito selezionabile nei dropdown delle altre sezioni

## 6. Sicurezza e navigazione (`navigazione.robot`)

- [ ] Ogni nuova pagina protetta va aggiunta a `@{PAGINE_PROTETTE}` (senza login → /login)
- [ ] Token non valido/scaduto → login (interceptor 401)
- [ ] URL inesistente, "Torna al menu", logout + tasto Indietro

## 7. Backend (test API xUnit) — per ogni fix

- [ ] Il fix ha un test API che lo blocca (409, 400, 201...) oltre al test E2E
- [ ] Nessun test API usa **nomi fissi** senza pulizia (con vincoli di unicità fallirebbe alla 2ª esecuzione)
- [ ] Se un test API esistente "fotografava" il vecchio comportamento sbagliato → riscriverlo come requisito

## 8. Chiusura

- [ ] Test rosso **prima** del fix, verde dopo (evidenze "prima" salvate fuori dal repo)
- [ ] Suite completa Robot + `dotnet test` verdi
- [ ] `PROGRESS.md` aggiornato (difetti, fix, decisioni), commit
