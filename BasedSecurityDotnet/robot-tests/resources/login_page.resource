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
    New Browser    chromium    headless=${HEADLESS}
    New Page       ${BASE_URL}/login

Esegui Login
    [Arguments]    ${username}    ${password}
    Fill Text    ${INPUT_USERNAME}    ${username}
    Fill Text    ${INPUT_PASSWORD}    ${password}
    Click        ${BOTTONE_ACCEDI}

Verifica Di Essere Nella Dashboard
    Wait For Elements State    text=Esci    visible
    Get Url    not contains    /login

Verifica Messaggio Di Errore Visibile
    Wait For Elements State    ${MESSAGGIO_ERRORE}    visible