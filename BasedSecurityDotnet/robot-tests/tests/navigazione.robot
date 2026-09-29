*** Settings ***
Documentation     Test trasversali di sicurezza e navigazione: pagine protette, token non valido,
...               URL inesistenti, torna al menu, logout.
Resource          ../resources/common.resource
Suite Setup       Apri Browser
Suite Teardown    Close Browser
Test Teardown     Chiudi Contesto


*** Variables ***
@{PAGINE_PROTETTE}      /    /prodotti    /prodotti/nuovo    /categorie    /categorie/nuovo
...                     /ordini    /scontrini    /statistiche
${BOTTONE_TORNA_MENU}   button[mattooltip="Torna al menu principale"]


*** Test Cases ***
Senza Login Le Pagine Protette Rimandano Al Login
    [Tags]    sicurezza    navigazione
    Apri Browser Non Loggato
    FOR    ${pagina}    IN    @{PAGINE_PROTETTE}
        Vai Alla Pagina    ${pagina}
        Get Url    contains    /login    message=La pagina ${pagina} e' accessibile senza login
    END

Con Un Token Non Valido Si Torna Al Login
    [Documentation]    Il guard controlla solo che il token ESISTA: con un token scaduto o falso
    ...                il backend risponde 401 e l'app deve riportare al login (e cancellare il token).
    [Tags]    sicurezza    navigazione
    Apri Browser Non Loggato
    LocalStorage Set Item    jwt_token    token-non-valido
    Vai Alla Pagina    /prodotti
    Get Url    contains    /login
    # il token falso e' stato cancellato: il guard ora blocca subito
    Vai Alla Pagina    /categorie
    Get Url    contains    /login

Un URL Inesistente Porta Alla Dashboard
    [Documentation]    Prima: pagina bianca (nessuna route "**").
    [Tags]    navigazione
    Apri Gestionale Da Loggato
    Vai Alla Pagina    /pagina-che-non-esiste
    Get Url    ==    ${BASE_URL}/
    Wait For Elements State    text=Esci    visible

Un URL Inesistente Senza Login Porta Al Login
    [Tags]    sicurezza    navigazione
    Apri Browser Non Loggato
    Vai Alla Pagina    /pagina-che-non-esiste
    Get Url    contains    /login

Il Bottone Torna Al Menu Riporta Alla Dashboard
    [Tags]    navigazione
    Apri Gestionale Da Loggato
    Vai Alla Sezione    Prodotti    /prodotti
    Click    ${BOTTONE_TORNA_MENU}
    Get Url    ==    ${BASE_URL}/
    Wait For Elements State    text=Esci    visible

Ogni Card Della Dashboard Apre La Sua Sezione E Si Torna Al Menu
    [Tags]    smoke    navigazione
    Apri Gestionale Da Loggato
    FOR    ${card}    ${url}    IN
    ...    Prodotti       /prodotti
    ...    Categorie      /categorie
    ...    Ordini         /ordini
    ...    Scontrini      /scontrini
    ...    Statistiche    /statistiche
        Vai Alla Sezione    ${card}    ${url}
        Click    ${BOTTONE_TORNA_MENU}
        Get Url    ==    ${BASE_URL}/
    END

Il Dettaglio Di Un Ordine Senza Login Rimanda Al Login
    [Tags]    sicurezza    navigazione
    Apri Browser Non Loggato
    Vai Alla Pagina    /ordini/1
    Get Url    contains    /login

Esci Fa Logout E Non Si Rientra Con Il Tasto Indietro
    [Tags]    sicurezza    navigazione
    Apri Gestionale Da Loggato
    Click    text=Esci
    Get Url    contains    /login
    Go Back
    Get Url    contains    /login
    Vai Alla Pagina    /prodotti
    Get Url    contains    /login


# =====================================================================
# COME LANCIARE (dalla cartella robot-tests)
#   robot --outputdir results --suite Navigazione tests
#   robot --outputdir results --include sicurezza tests
# =====================================================================
