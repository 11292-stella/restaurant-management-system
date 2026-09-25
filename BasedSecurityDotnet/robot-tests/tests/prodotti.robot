*** Settings ***
Documentation     Test E2E della sezione Prodotti del gestionale.
Resource          ../resources/prodotti_page.resource
Test Setup        Apri Gestionale Da Loggato
Test Teardown     Close Browser


*** Test Cases ***
Dalla Dashboard Si Apre La Lista Prodotti Con Il Menu Base
    [Tags]    smoke    prodotti
    Vai Alla Sezione    Prodotti    /prodotti
    Verifica Prodotto In Lista    Cornetto vuoto
    Verifica Prodotto In Lista    Pizza Margherita

Ricerca Per Nome Mostra Solo I Prodotti Corrispondenti
    [Tags]    prodotti    filtri
    Vai Alla Sezione    Prodotti    /prodotti
    Cerca Prodotto    capp
    Verifica Prodotto In Lista        Cappuccino
    Verifica Prodotto Non In Lista    Cornetto vuoto

Filtro Per Categoria Mostra Solo I Prodotti Di Quella Categoria
    [Tags]    prodotti    filtri
    Vai Alla Sezione    Prodotti    /prodotti
    Filtra Per Categoria    Colazione
    Verifica Prodotto In Lista        Cornetto vuoto
    Verifica Prodotto Non In Lista    Pizza Margherita

#    Varianti:
#      robot --outputdir results tests/login.robot                -> un solo file (SENZA setup utente di __init__)
#      robot --outputdir results --suite Prodotti tests           -> una sola suite CON setup utente (usare dopo down -v)
#      robot --outputdir results --include smoke tests            -> solo i test smoke
#      robot --outputdir results --variable HEADLESS:True tests   -> senza finestra