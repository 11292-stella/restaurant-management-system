# Comandi — Test E2E Robot Framework (gestionale Angular)

Guida rapida con tutti i comandi da terminale (PowerShell) per avviare l'ambiente e lanciare i test,
pensata per chi riceve il progetto senza averlo scritto.
Servono **3 terminali**, da aprire in quest'ordine: Docker → Angular → Robot.

> Tutti i percorsi sono relativi alla **root del repo** (la cartella che contiene `docker-compose.yml`).
> `<cartella Angular>` = percorso in cui hai clonato il progetto Angular del gestionale.

---

## 0. Percorsi

| Cosa | Cartella |
|---|---|
| Root del repo (qui c'è `docker-compose.yml`) | `.` |
| Test Robot | `robot-tests` |
| Angular | `<cartella Angular>` |

---

## 1. Finestra 1 — Backend + Database (Docker)

```powershell
cd <root del repo>
```

### Avvio normale (i dati restano)
```powershell
docker compose up -d
```

### Reset completo (DB pulito + menu base ricreato dal seeder)
Da fare quando i dati sono "sporchi" (prodotti di test rimasti, utente cambiato, ecc.).
```powershell
docker compose down -v
docker compose up -d
```
- `down -v` spegne i container **e cancella i volumi** (= cancella il database)
- `up -d` riaccende tutto in background; all'avvio il backend fa `Migrate()` + `DbSeeder` (Colazione/Pranzo/Cena + 27 prodotti)

### Dopo aver modificato il codice del backend (es. il DbSeeder)
```powershell
docker compose down -v
docker compose up -d --build
```
`--build` ricostruisce l'immagine del backend con il codice nuovo (senza, gira la versione vecchia).

### Controlli utili
```powershell
docker compose ps                  # container accesi? (devono essere "running"/"Up")
docker compose logs -f             # log in tempo reale (Ctrl+C per uscire)
docker compose logs -f <servizio>  # log di un solo servizio (nome da "docker compose ps")
docker compose down                # spegne tutto SENZA cancellare il DB
```

Backend raggiungibile su: `http://localhost:5231`

---

## 2. Finestra 2 — Angular (lasciarla aperta)

```powershell
cd <cartella Angular>
ng serve
```
Aspettare il messaggio di compilazione completata, poi l'app risponde su `http://localhost:4200`.
Per fermarlo: `Ctrl+C`.

---

## 3. Finestra 3 — Test Robot

```powershell
cd robot-tests
```

### Tutti i test
```powershell
robot --outputdir results tests
```

### Una sola suite (con setup utente di `__init__.robot`)
```powershell
robot --outputdir results --suite Prodotti tests
robot --outputdir results --suite Login tests
robot --outputdir results --suite Categorie tests
robot --outputdir results --suite Navigazione tests   # login, token, URL inesistenti, logout
robot --outputdir results --suite Ordini tests        # lista, stati, dettaglio, scontrino, pagamento carta
robot --outputdir results --suite Scontrini tests
robot --outputdir results --suite Statistiche tests
```
> Usare `--suite Nome tests` e NON `tests/prodotti.robot`: lanciando il file singolo `__init__.robot` non gira e l'utente di test non viene creato (problema dopo un `down -v`).

### Un solo test (per nome, `*` = qualsiasi testo)
```powershell
robot --outputdir results --test "Modifica Prodotto*" tests
robot --outputdir results --test "*Esaurito*" tests
```

### Per tag
```powershell
robot --outputdir results --include smoke tests    # solo smoke
robot --outputdir results --include crud tests     # solo CRUD
robot --outputdir results --exclude crud tests     # tutto tranne CRUD
robot --outputdir results --include validazione tests   # test dei form (campi vuoti, spazi, prezzo 0...)
robot --outputdir results --include sicurezza tests     # login, token, XSS
robot --outputdir results --include pagamento tests     # pagamento con carta simulato
```
Tag usati: `smoke`, `crud`, `filtri`, `validazione`, `sicurezza`, `navigazione`, `prodotti`, `categorie`, `ordini`, `scontrini`, `pagamento`, `statistiche`.

### Senza finestra del browser (headless, come in pipeline)
```powershell
robot --outputdir results --variable HEADLESS:True tests
```

### Modalità debug (si ferma a ogni `Pausa Debug`)
```powershell
robot --outputdir results --variable DEBUG:True --test "Modifica Prodotto*" tests
```
Si apre una finestrella "Pausa": ispezioni il browser (F12), poi premi **OK** per continuare.

### Tenere nel DB il prodotto creato dal form (popolare il DB)
```powershell
robot --outputdir results --test "Crea Prodotto*" --variable MANTIENI_DATI:True tests
```
Lanciandolo più volte crea più prodotti realistici (dati Faker). Senza `MANTIENI_DATI` il test cancella quello che crea.

### Rilanciare solo i test falliti dell'ultima esecuzione
```powershell
robot --outputdir results --rerunfailed results\output.xml tests
```

### Controllo sintassi senza aprire il browser
```powershell
robot --dryrun --outputdir results tests
robot --dryrun --outputdir results tools/salva_pagina.robot
```
Trova keyword mancanti, errori di battitura, file resource non trovati.

### Combinazioni (si possono sommare le opzioni)
```powershell
robot --outputdir results --suite Prodotti --variable HEADLESS:True --include smoke tests
```

---

## 4. Vedere i risultati

```powershell
start results\report.html    # riepilogo verde/rosso
start results\log.html       # dettaglio passo per passo, con i tempi di ogni keyword
ii results\html              # apre in Esplora risorse la cartella degli HTML salvati
```
- `log.html` → è lì che si vede **dove si perde tempo** (es. il `New Page` da 19,7s) e **dove fallisce**
- Screenshot automatici dei fallimenti: in `results\browser\screenshot\`

---

## 5. Salvare l'HTML di una pagina (trovare i selettori)

Tutti i file vanno in `results\html\` (in `.gitignore`, non finiscono su git).

### 5a. Esploratore — salva una pagina da loggato
```powershell
robot --outputdir results --variable PAGINA:/prodotti tools/salva_pagina.robot
robot --outputdir results --variable PAGINA:/prodotti/nuovo tools/salva_pagina.robot
robot --outputdir results --variable PAGINA:/categorie tools/salva_pagina.robot
robot --outputdir results --variable PAGINA:/ tools/salva_pagina.robot          # dashboard
```
Risultato: `results\html\_prodotti_<data_ora>.html` + `.png`

### 5b. Esploratore + debug — salva la pagina DOPO un'azione fatta a mano
Per dialog, dropdown aperti, messaggi di errore: cose che compaiono solo dopo un click.
```powershell
robot --outputdir results --variable PAGINA:/prodotti --variable DEBUG:True tools/salva_pagina.robot
```
1. si apre il browser e compare la finestrella **"Pausa"**
2. **non premere OK subito**: nel browser fai a mano l'azione (apri il dropdown, clicca il cestino…)
3. premi **OK** → salva l'HTML in quello stato

> ⚠️ Per il cestino usare un prodotto usa-e-getta (creato con `MANTIENI_DATI:True`), non il menu base.
> Se dopo il click non si vede nessun dialog nell'HTML, è probabilmente un `confirm()` nativo del browser (Playwright lo chiude da solo) → nel test serve `Handle Future Dialogs    action=accept`.

### 5c. Dentro un test (riga temporanea mentre lo scrivi)
```robot
Salva HTML Pagina                                          # tutta la pagina
Salva HTML Pagina    dopo_click_elimina                    # nome del file a scelta
Salva HTML Pagina    dialog    mat-dialog-container        # solo un pezzo di pagina
Salva HTML Pagina    completo    pulito=False              # con anche i <style> (di default li toglie)
```
Poi si lancia il test normalmente e si guarda il file in `results\html\`. Trovato il selettore, **togliere la riga**.

### 5d. Automatico sui test falliti
Non serve fare niente: se un test fallisce, il teardown `Chiudi Contesto` salva
`results\html\FALLITO_<nome test>_<data_ora>.html` + `.png` = com'era la pagina al momento dell'errore.

### 5e. Registrare gli endpoint chiamati dalla UI (recorder)
Per ricavare le API usate dal gestionale senza guardare il codice (base per scrivere i test API):
```powershell
robot --outputdir results --variable REGISTRA_ENDPOINT:True tests          # oppure una sola suite: --suite Ordini
python tools/estrai_endpoint.py
start results\endpoint\endpoint.md
```
- ogni test salva il suo traffico in `results\har\<nome test>.har`
- lo script produce `endpoint.md` e `endpoint.csv` (apribile con Excel): metodo, endpoint (`/api/Ordine/{id}/stato`), status visti, campi del body, quante chiamate e da quanti test
- ⚠️ i file `.har` contengono il token: restano in `results\` (non va su git), **non condividerli**

### Come leggere l'HTML salvato
1. aprirlo in **VS Code** (non nel browser)
2. `Ctrl+F` sul testo che si vede a schermo (es. "Nuova categoria")
3. guardare il tag intorno e scegliere il selettore, in ordine di preferenza:
   - `role=button[name="Testo"]` / `role=textbox[name="Etichetta"]`
   - attributi stabili: `button[mattooltip="Elimina"]`, `input[formcontrolname="nome"]`
   - `tr:has-text("Nome prodotto") >> button[...]` per le righe di tabella
   - ❌ evitare: id generati (`#mat-select-0`, `#mat-input-3`), catene di classi `.mat-mdc-...`

---

## 6. Codegen Playwright (registrare i click e vedere i selettori)

```powershell
cd robot-tests
npx playwright codegen --save-storage=auth.json http://localhost:4200/login    # prima volta: fai login a mano
npx playwright codegen --load-storage=auth.json http://localhost:4200/prodotti # poi entri già loggata
```
Traduzione: `getByRole('button', { name: 'X' })` → `role=button[name="X"]`.
> `auth.json` contiene il token: è in `.gitignore`, **non committarlo**.

---

## 7. Setup (solo su un PC nuovo o dopo aver reinstallato Python)

```powershell
cd robot-tests
pip install -r requirements.txt
rfbrowser init
robot --version
```
`rfbrowser init` scarica Playwright/Chromium per la Browser Library (ci mette qualche minuto).

### Usare credenziali diverse da quelle di default (solo per la finestra corrente)
```powershell
$env:ROBOT_USERNAME="altroutente"
$env:ROBOT_PASSWORD="..."
```

---

## 8. Sequenza completa "da zero" (copia-incolla)

**Finestra 1**
```powershell
cd <root del repo>
docker compose down -v
docker compose up -d
```
**Finestra 2**
```powershell
cd <cartella Angular>
ng serve
```
**Finestra 3** (quando Angular ha finito di compilare)
```powershell
cd robot-tests
robot --outputdir results tests
start results\report.html
```

---

## 9. Test API .NET (xUnit + Playwright)

Con il backend in Docker (porta 5231), dalla root del repo:
```powershell
$env:API_BASE_URL="http://localhost:5231"
dotnet test
dotnet test --filter "FullyQualifiedName~CategoriaTests"    # una sola classe
```
Senza la variabile i test cercano `https://localhost:7198` (backend avviato con `dotnet run`)
e falliscono tutti con `connect ECONNREFUSED ::1:7198`. La variabile vale solo per la finestra PowerShell corrente.

---

## 10. Errori tipici

| Errore | Causa / soluzione |
|---|---|
| `ECONNREFUSED ::1:7198` in `dotnet test` | i test API cercano il backend fuori Docker → `$env:API_BASE_URL="http://localhost:5231"` |
| `ERR_CONNECTION_REFUSED` su `localhost:4200` | Angular non è acceso → finestra 2, `ng serve` |
| `ConnectionError` su `localhost:5231` | Docker spento → `docker compose up -d` |
| Login via API fallisce (401) dopo un `down -v` | utente non ricreato: lanciare con `--suite ... tests`, non il file singolo |
| `No keyword with name '...' found` | file non salvato (pallino sulla linguetta in VS Code) o copia-incolla troncato → `Select-String -Path resources\common.resource -Pattern "NomeKeyword"` |
| `Multiple keywords with name '...'` | la keyword esiste in due `.resource`: deve stare in uno solo |
| Test che passa da solo ma fallisce nella suite | dati condivisi o attesa mancante: aprire `log.html` e il file `FALLITO_...` in `results\html\` |
| `mkdir a b` non funziona | in PowerShell: `mkdir a, b` |
| Testo digitato finito nel campo sbagliato di un dialog | il dialog Material sposta il focus a fine animazione: prima di scrivere `Wait For Elements State  <primo campo>  focused` |
| `Get Text` restituisce il testo in MAIUSCOLO | `text-transform: uppercase` nel CSS: Get Text legge il testo come lo vede l'utente |
