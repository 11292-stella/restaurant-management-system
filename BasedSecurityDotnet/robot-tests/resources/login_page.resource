*** Settings ***
Documentation    Keyword e selettori della pagina di login del gestionale.
Resource         common.resource


*** Variables ***
# Selettori: formControlName nel DOM diventa l'attributo "formcontrolname"
${INPUT_USERNAME}      input[formcontrolname="username"]
${INPUT_PASSWORD}      input[formcontrolname="password"]
${BOTTONE_ACCEDI}      button[type="submit"]
${MESSAGGIO_ERRORE}    p.errore


*** Keywords ***
Apri Browser Sul Login
    [Documentation]    Nuovo contesto pulito (il browser e' gia' aperto dal Suite Setup) sulla pagina di login.
    New Context
    New Page       ${BASE_URL}/login    wait_until=domcontentloaded

Esegui Login
    [Arguments]    ${username}    ${password}
    Fill Text      ${INPUT_USERNAME}    ${username}
    # Fill Secret + "$password" (senza graffe): il valore non viene scritto nel log
    Fill Secret    ${INPUT_PASSWORD}    $password
    Click          ${BOTTONE_ACCEDI}

Verifica Di Essere Nella Dashboard
    Wait For Elements State    text=Esci    visible
    Get Url    not contains    /login

Verifica Messaggio Di Errore Visibile
    Wait For Elements State    ${MESSAGGIO_ERRORE}    visible
