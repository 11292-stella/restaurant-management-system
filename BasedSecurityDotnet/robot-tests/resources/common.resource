*** Settings ***
Documentation   Variabili e Keyword condivise da tutti i test.
Library         Browser
Library         RequestsLibrary



*** Variables ***
# Configurazione ambiente (sovrascrivibile con --variable NOME:valore)
${BASE_URL}      http://localhost:4200
${API_URL}       http://localhost:5231
${HEADLESS}      False



# Utente di test
${USERNAME}      mrossi
${PASSWORD}      password123



*** Keywords ***
Prepara Utente Di Test
    [Documentation]    Registra mrossi via API. 200 = creato, 400 = esiste gia': vanno bene entrambi.
    Create Session    api    ${API_URL}
    &{body}=    Create Dictionary
    ...    username=${USERNAME}    password=${PASSWORD}
    ...    nome=Mario    cognome=Rossi    email=mrossi@test.it    role=${1}
    POST On Session    api    /api/Auth/register    json=${body}    expected_status=any

Ottieni Token
    [Documentation]    Fa login via API e ritorna il JWT.
    Create Session    api    ${API_URL}
    &{body}=    Create Dictionary    username=${USERNAME}    password=${PASSWORD}
    ${resp}=    POST On Session    api    /api/Auth/login    json=${body}    expected_status=200
    RETURN    ${resp.json()}[token]

Apri Gestionale Da Loggato
    [Documentation]    Login via API + token nel localStorage: si entra gia' autenticati, senza passare dal form.
    ${token}=    Ottieni Token
    New Browser    chromium    headless=${HEADLESS}
    New Page       ${BASE_URL}/login
    LocalStorage Set Item    jwt_token    ${token}
    Go To          ${BASE_URL}/
    Wait For Elements State    text=Esci    visible

Vai Alla Sezione
    [Documentation]    Dalla dashboard clicca la card della sezione e verifica l'URL.
    [Arguments]    ${nome_card}    ${url}
    Click    text=${nome_card}
    Get Url    contains    ${url}

Headers Autenticati
    [Documentation]    Ritorna gli headers con il Bearer token (come nei test .NET).
    ${token}=    Ottieni Token
    &{headers}=    Create Dictionary    Authorization=Bearer ${token}
    RETURN    ${headers}

Genera Nome Univoco
    [Documentation]    Prefisso + 8 caratteri casuali (come Guid.NewGuid() nei test API).
    [Arguments]    ${prefisso}
    ${suffisso}=    Evaluate    uuid.uuid4().hex[:8]    modules=uuid
    RETURN    ${prefisso} ${suffisso}

Crea Categoria Via API
    [Arguments]    ${nome}
    &{headers}=    Headers Autenticati
    &{body}=    Create Dictionary    nome=${nome}    descrizione=Creata dai test Robot
    ${resp}=    POST On Session    api    /api/Categoria    json=${body}    headers=${headers}    expected_status=201
    RETURN    ${resp.json()}[id]

Crea Prodotto Via API
    [Arguments]    ${nome}    ${categoria_id}    ${attivo}=${True}    ${esaurito}=${False}
    &{headers}=    Headers Autenticati
    &{body}=    Create Dictionary
    ...    nome=${nome}    descrizione=Creato dai test Robot    prezzo=${5.5}    costoProduzione=${2.0}
    ...    attivo=${attivo}    esaurito=${esaurito}    categoriaId=${categoria_id}
    ...    immagineUrl=https://images.unsplash.com/photo-1534778101976-62847782c213?w=500
    ${resp}=    POST On Session    api    /api/Prodotto    json=${body}    headers=${headers}    expected_status=200
    RETURN    ${resp.json()}[id]

Elimina Via API
    [Documentation]    DELETE generico, es: Elimina Via API    /api/Prodotto/5
    [Arguments]    ${percorso}
    &{headers}=    Headers Autenticati
    DELETE On Session    api    ${percorso}    headers=${headers}    expected_status=any

Seleziona Da Dropdown
    [Documentation]    Dropdown Material: si clicca il mat-form-field (non il mat-select) e poi l'opzione.
    [Arguments]    ${etichetta}    ${opzione}
    Click    mat-form-field:has-text("${etichetta}")
    Click    role=option[name="${opzione}"]


# =====================================================================
# COME LANCIARE I TEST (3 finestre PowerShell)
#
# 1. Backend + DB: reset e riavvio (dalla root, dove c'è docker-compose.yml)
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
#      robot --outputdir results tests/login.robot       -> un solo file
#      robot --outputdir results --include smoke tests   -> solo i test smoke
#      robot --outputdir results --variable HEADLESS:True tests  -> senza finestra
# =====================================================================

*** Settings ***
...