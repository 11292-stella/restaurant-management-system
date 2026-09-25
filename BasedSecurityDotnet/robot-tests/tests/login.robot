*** Settings ***
Documentation     Test E2E della pagina di login del gestionale Angular.
Resource          ../resources/login_page.resource
Test Setup        Apri Browser Sul Login
Test Teardown     Close Browser


*** Test Cases ***
Login Con Credenziali Valide Porta Alla Dashboard
    [Tags]    smoke    login
    Esegui Login    ${USERNAME}    ${PASSWORD}
    Verifica Di Essere Nella Dashboard

Login Con Password Errata Mostra Messaggio Di Errore
    [Tags]    login
    Esegui Login    ${USERNAME}    password-sbagliata
    Verifica Messaggio Di Errore Visibile
    Get Url    contains    /login

Bottone Accedi Disabilitato Con Campi Vuoti
    [Tags]    login
    Get Element States    ${BOTTONE_ACCEDI}    contains    disabled