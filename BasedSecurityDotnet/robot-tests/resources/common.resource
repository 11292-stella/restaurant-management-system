# =====================================================================
# COME LANCIARE I TEST (3 finestre PowerShell)
#
# 1. Backend + DB: reset e riavvio (dalla root, dove c'e' docker-compose.yml)
#      cd C:\Users\stell\Desktop\BasedSecurityDotnet
#      docker compose down -v
#      docker compose up -d
#
# 2. Angular (lasciare la finestra aperta)
#      cd <cartella Angular>
#      ng serve
#
# 3. Test Robot (quando Angular risponde su http://localhost:4200)
#      cd C:\Users\stell\Desktop\BasedSecurityDotnet\robot-tests
#      robot --outputdir results tests
#
#    Varianti:
#      robot --outputdir results tests/login.robot                -> un solo file (SENZA setup utente di __init__)
#      robot --outputdir results --suite Prodotti tests           -> una sola suite CON setup utente (usare dopo down -v)
#      robot --outputdir results --include smoke tests            -> solo i test smoke
#      robot --outputdir results --variable HEADLESS:True tests   -> senza finestra
#      robot --outputdir results --variable DEBUG:True tests      -> si ferma a ogni "Pausa Debug"
#
#    Esploratore (salva HTML + screenshot di una pagina, per trovare i selettori):
#      robot --outputdir results --variable PAGINA:/prodotti tools/salva_pagina.robot
#      robot --outputdir results --variable PAGINA:/prodotti --variable DEBUG:True tools/salva_pagina.robot
#      -> file in results/html/ ; i test falliti salvano da soli results/html/FALLITO_<nome test>_...
# =====================================================================

*** Settings ***
Documentation    Variabili e keyword condivise da tutti i test.
Library          Browser    timeout=20s
Library          RequestsLibrary
Library          Dialogs          # Pause Execution per il debug
Library          String           # Convert To Lower Case, Replace String Using Regexp
Library          OperatingSystem  # Create File per salvare l'HTML
Library          DateTime         # timestamp nei nomi dei file
Resource         test_data.resource


*** Variables ***
# Configurazione ambiente (sovrascrivibile con --variable NOME:valore)
${BASE_URL}      http://localhost:4200
${API_URL}       http://localhost:5231
${HEADLESS}      False
${DEBUG}         False
${MANTIENI_DATI}    False
# True = registra tutte le chiamate di rete (file .har per test) -> poi: python tools/estrai_endpoint.py
${REGISTRA_ENDPOINT}    False

# Utente di test: letto da variabili d'ambiente (in CI: variabili "masked" di GitLab).
# Il valore dopo "=" e' solo il fallback per l'utente di test locale.
# Per usare altre credenziali:  $env:ROBOT_USERNAME="..." ; $env:ROBOT_PASSWORD="..."
${USERNAME}      %{ROBOT_USERNAME=mrossi}
${PASSWORD}      %{ROBOT_PASSWORD=password123}


*** Keywords ***
# ---------------------------------------------------------------------
# Utente e autenticazione
# ---------------------------------------------------------------------
Prepara Utente Di Test
    [Documentation]    Registra l'utente di test via API. 200 = creato, 400 = esiste gia': vanno bene entrambi.
    ...                Log disattivato durante la chiamata: la password non finisce in log.html.
    Create Session    api    ${API_URL}
    ${livello}=    Set Log Level    NONE
    TRY
        &{body}=    Create Dictionary
        ...    username=${USERNAME}    password=${PASSWORD}
        ...    nome=Mario    cognome=Rossi    email=mrossi@test.it    role=${1}
        POST On Session    api    /api/Auth/register    json=${body}    expected_status=any
    FINALLY
        Set Log Level    ${livello}
    END

Ottieni Token
    [Documentation]    Fa login via API e ritorna il JWT.
    ...                Log disattivato durante la chiamata: password e risposta non finiscono in log.html.
    Create Session    api    ${API_URL}
    ${livello}=    Set Log Level    NONE
    TRY
        &{body}=    Create Dictionary    username=${USERNAME}    password=${PASSWORD}
        ${resp}=    POST On Session    api    /api/Auth/login    json=${body}    expected_status=200
        ${token}=    Set Variable    ${resp.json()}[token]
    FINALLY
        Set Log Level    ${livello}
    END
    RETURN    ${token}

Headers Autenticati
    [Documentation]    Ritorna gli headers con il Bearer token (come nei test .NET).
    ${token}=    Ottieni Token
    &{headers}=    Create Dictionary    Authorization=Bearer ${token}
    RETURN    ${headers}

# ---------------------------------------------------------------------
# Browser e navigazione
# ---------------------------------------------------------------------
# Schema: UN browser per suite (Suite Setup: Apri Browser / Suite Teardown: Close Browser)
#         + UN contesto nuovo per ogni test (Test Setup: New Context... / Test Teardown: Chiudi Contesto).
# Il contesto e' come una finestra in incognito: localStorage/cookie puliti a ogni test,
# ma senza chiudere e riaprire il processo del browser (lento e, su Windows, fonte di errori
# "Target page, context or browser has been closed").
Apri Browser
    [Documentation]    Avvia il browser una volta per suite.
    New Browser    chromium    headless=${HEADLESS}

Apri Gestionale Da Loggato
    [Documentation]    Nuovo contesto pulito + login via API + token nel localStorage: si entra gia' autenticati, senza passare dal form.
    ...                wait_until=domcontentloaded: non aspettiamo le immagini esterne (Unsplash), solo che la pagina sia pronta.
    ${token}=    Ottieni Token
    Nuovo Contesto
    New Page       ${BASE_URL}/login    wait_until=domcontentloaded
    LocalStorage Set Item    jwt_token    ${token}
    Go To          ${BASE_URL}/    wait_until=domcontentloaded
    Wait For Elements State    text=Esci    visible

Nuovo Contesto
    [Documentation]    New Context "in incognito". Con --variable REGISTRA_ENDPOINT:True registra anche il traffico
    ...                di rete del test in results/har/<nome test>.har (come il recorder degli endpoint del progetto Playwright).
    ...                Il file .har viene scritto quando il contesto si chiude (teardown).
    ...                ATTENZIONE: il .har contiene header e body (anche il token JWT): resta in results/, che e' in .gitignore.
    IF    ${REGISTRA_ENDPOINT}
        ${nome}=    Replace String Using Regexp    ${TEST NAME}    [^\\w-]+    _
        &{har}=     Create Dictionary    path=${OUTPUT DIR}${/}har${/}${nome}.har    omitContent=${False}
        New Context    recordHar=${har}
    ELSE
        New Context
    END

Chiudi Contesto
    [Documentation]    Test Teardown standard: se il test e' fallito salva HTML + screenshot, poi chiude il contesto.
    Salva HTML Se Fallito
    Close Context

Vai Alla Sezione
    [Documentation]    Dalla dashboard clicca la card della sezione e verifica l'URL.
    [Arguments]    ${nome_card}    ${url}
    Click    text=${nome_card}
    Get Url    contains    ${url}

Seleziona Da Dropdown
    [Documentation]    Dropdown Material: si clicca il mat-form-field (non il mat-select, coperto dalla mat-label) e poi l'opzione.
    [Arguments]    ${etichetta}    ${opzione}
    Click    mat-form-field:has-text("${etichetta}")
    Click    role=option[name="${opzione}"]

Imposta Switch
    [Documentation]    Porta uno switch Material a on/off, cliccando solo se serve (un click lo inverte).
    [Arguments]    ${selettore}    ${acceso}
    ${stato}=     Get Attribute    ${selettore}    aria-checked
    ${atteso}=    Convert To Lower Case    ${acceso}
    IF    '${stato}' != '${atteso}'
        Click    ${selettore}
    END

Pausa Debug
    [Documentation]    Si ferma solo se lanciato con --variable DEBUG:True. In pipeline non fa nulla.
    [Arguments]    ${messaggio}=Ispeziona con F12, poi premi OK
    IF    ${DEBUG}
        Pause Execution    ${messaggio}
    END

Vai Alla Pagina
    [Documentation]    Apre direttamente un URL del gestionale (es. /prodotti/999999), senza passare dalla dashboard.
    [Arguments]    ${percorso}
    Go To    ${BASE_URL}${percorso}    wait_until=domcontentloaded

Apri Browser Non Loggato
    [Documentation]    Nuovo contesto SENZA token nel localStorage, direttamente sull'URL indicato.
    [Arguments]    ${percorso}=/login
    Nuovo Contesto
    New Page    ${BASE_URL}${percorso}    wait_until=domcontentloaded

Verifica Titolo Pagina
    [Documentation]    Titolo (h2) della card: es. "Nuovo prodotto" / "Modifica prodotto".
    [Arguments]    ${titolo}
    Get Text    mat-card h2    ==    ${titolo}

Verifica Errore Nel Form
    [Documentation]    Messaggio d'errore mostrato dentro un form (div .stato-errore), es. "Prodotto non trovato."
    [Arguments]    ${testo}
    Wait For Elements State    .stato-errore >> text=${testo}    visible

Verifica Notifica
    [Documentation]    Controlla che compaia la notifica temporanea di Angular Material (MatSnackBar) con quel testo.
    [Arguments]    ${testo}
    Wait For Elements State    mat-snack-bar-container >> text=${testo}    visible

# ---------------------------------------------------------------------
# Diagnostica: salva HTML + screenshot della pagina
# ---------------------------------------------------------------------
# Salva il DOM gia' renderizzato da Angular (quello che vedi con F12, con mat-option,
# mat-dialog-container, aria-checked...), NON il template .html del componente.
# File in results/html/ (gia' in .gitignore).
# Uso nei test:
#   Salva HTML Pagina                                          -> tutta la pagina
#   Salva HTML Pagina    dialog_elimina                        -> nome file personalizzato
#   Salva HTML Pagina    dialog    mat-dialog-container        -> solo un pezzo di pagina (piu' leggibile)
Salva HTML Pagina
    [Documentation]    Salva il DOM attuale e uno screenshot. Utile senza codice sorgente
    ...                o quando non si trova il selettore giusto.
    ...                pulito=True toglie <style> e commenti Angular: resta solo la struttura utile per i selettori.
    [Arguments]    ${nome}=pagina    ${selettore}=${None}    ${pulito}=${True}
    ${timestamp}=    Get Current Date    result_format=%Y%m%d_%H%M%S
    ${nome}=         Replace String Using Regexp    ${nome}    [^\\w-]+    _
    ${percorso}=     Set Variable    ${OUTPUT DIR}${/}html${/}${nome}_${timestamp}
    IF    $selettore is None
        ${html}=    Get Page Source
    ELSE
        ${html}=    Get Property    ${selettore}    outerHTML
    END
    IF    ${pulito}
        ${html}=    Replace String Using Regexp    ${html}    (?s)<style.*?</style>|<!--.*?-->    ${EMPTY}
    END
    Create File        ${percorso}.html    ${html}    encoding=UTF-8
    Take Screenshot    filename=${percorso}    fullPage=True
    Log    HTML salvato in: ${percorso}.html    console=True

Salva HTML Se Fallito
    [Documentation]    Nel Test Teardown: se il test e' fallito salva la pagina com'era in quel momento.
    ...                Ignore Error: se la pagina e' rotta, il salvataggio non deve far fallire anche il teardown.
    IF    '${TEST STATUS}' == 'FAIL'
        Run Keyword And Ignore Error    Salva HTML Pagina    FALLITO_${TEST NAME}
    END

# ---------------------------------------------------------------------
# Dati di test via API (Arrange / Cleanup)
# ---------------------------------------------------------------------
Crea Categoria Via API
    [Documentation]    POST /api/Categoria -> 201 (CreatedAtAction). Ritorna l'id.
    [Arguments]    ${nome}
    &{headers}=    Headers Autenticati
    &{body}=    Create Dictionary    nome=${nome}    descrizione=Creata dai test Robot
    ${resp}=    POST On Session    api    /api/Categoria    json=${body}    headers=${headers}    expected_status=201
    RETURN    ${resp.json()}[id]

Crea Prodotto Via API
    [Documentation]    POST /api/Prodotto -> 201 (CreatedAtAction). Ritorna l'id.
    ...                immagine_url=${None} -> prodotto senza immagine (la lista mostra il placeholder).
    [Arguments]    ${nome}    ${categoria_id}    ${attivo}=${True}    ${esaurito}=${False}
    ...            ${prezzo}=${5.5}    ${costo}=${2.0}
    ...            ${immagine_url}=https://images.unsplash.com/photo-1534778101976-62847782c213?w=500
    &{headers}=    Headers Autenticati
    &{body}=    Create Dictionary
    ...    nome=${nome}    descrizione=Creato dai test Robot    prezzo=${prezzo}    costoProduzione=${costo}
    ...    attivo=${attivo}    esaurito=${esaurito}    categoriaId=${categoria_id}
    ...    immagineUrl=${immagine_url}
    ${resp}=    POST On Session    api    /api/Prodotto    json=${body}    headers=${headers}    expected_status=201
    RETURN    ${resp.json()}[id]

Conta Prodotti Con Nome Via API
    [Documentation]    Quanti prodotti esistono nel backend con esattamente quel nome.
    [Arguments]    ${nome}
    &{headers}=    Headers Autenticati
    ${resp}=    GET On Session    api    /api/Prodotto    headers=${headers}
    ${n}=    Evaluate    len([p for p in $resp.json() if p['nome'] == $nome])
    RETURN    ${n}

Conta Categorie Con Nome Via API
    [Documentation]    Quante categorie hanno quel nome (senza distinguere maiuscole/minuscole).
    [Arguments]    ${nome}
    &{headers}=    Headers Autenticati
    ${resp}=    GET On Session    api    /api/Categoria    headers=${headers}
    ${n}=    Evaluate    len([c for c in $resp.json() if c['nome'].strip().lower() == $nome.strip().lower()])
    RETURN    ${n}

Elimina Via API
    [Documentation]    DELETE generico (204 se ok, 404 se gia' cancellato: va bene uguale). Es: Elimina Via API    /api/Prodotto/5
    [Arguments]    ${percorso}
    &{headers}=    Headers Autenticati
    DELETE On Session    api    ${percorso}    headers=${headers}    expected_status=any

Elimina Prodotto Per Nome Via API
    [Documentation]    Per i prodotti creati dalla UI (non conosciamo l'id): cerca per nome ed elimina.
    ...                Se non lo trova (test fallito prima di salvare) non fa nulla.
    [Arguments]    ${nome}
    &{headers}=    Headers Autenticati
    ${resp}=    GET On Session    api    /api/Prodotto    headers=${headers}
    FOR    ${p}    IN    @{resp.json()}
        IF    $p['nome'] == $nome
            Elimina Via API    /api/Prodotto/${p}[id]
        END
    END