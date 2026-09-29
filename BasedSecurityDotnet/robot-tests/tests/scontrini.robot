*** Settings ***
Documentation     Test E2E della sezione Scontrini: lista, metodo di pagamento, collegamento all'ordine,
...               eliminazione con conferma, flusso completo ordine -> scontrino -> lista.
Resource          ../resources/ordini_page.resource
Suite Setup       Apri Browser
Suite Teardown    Close Browser
Test Setup        Inizia Test Da Loggato
Test Teardown     Pulisci Ordini E Chiudi Contesto


*** Test Cases ***
Dalla Dashboard Si Apre La Lista Scontrini Con Importo E Metodo
    [Tags]    smoke    scontrini
    &{ordine}=    Crea Ordine Semplice Via API    quantita=2    prezzo=8.4
    Crea Scontrino Via API    ${ordine}[id]    ${METODO_CONTANTI}

    Vai Alla Sezione    Scontrini    /scontrini
    Verifica Titolo Pagina    Scontrini
    Verifica Scontrino In Lista    ${ordine}[id]
    Verifica Cella Scontrino    ${ordine}[id]    importo    €16.80
    Verifica Cella Scontrino    ${ordine}[id]    metodo     Contanti
    Get Text    tr:has(a.ordine-link:text-is("#${ordine}[id]")) >> td.mat-column-dataEmissione    matches    ^\\d{2}/\\d{2}/\\d{4} \\d{2}:\\d{2}$

Lo Scontrino Pagato Con Carta Mostra Il Metodo Carta
    [Tags]    scontrini
    &{ordine}=    Crea Ordine Semplice Via API
    Crea Scontrino Via API    ${ordine}[id]    ${METODO_CARTA}

    Vai Alla Sezione    Scontrini    /scontrini
    Verifica Cella Scontrino    ${ordine}[id]    metodo    Carta

Il Numero Ordine Apre Il Dettaglio Dell'Ordine
    [Tags]    scontrini    navigazione
    &{ordine}=    Crea Ordine Semplice Via API
    Crea Scontrino Via API    ${ordine}[id]

    Vai Alla Sezione    Scontrini    /scontrini
    Click    a.ordine-link:text-is("#${ordine}[id]")
    Get Url    matches    .*/ordini/${ordine}[id]$
    Verifica Intestazione Ordine    ${ordine}[id]    ${ordine}[cliente]    In attesa
    Verifica Scontrino Emesso In UI    Contanti

Lo Scontrino Emesso Dal Dettaglio Compare Nella Lista
    [Documentation]    Flusso completo da utente: ordine -> emetti scontrino -> menu -> lista scontrini.
    [Tags]    smoke    scontrini    crud
    &{ordine}=    Crea Ordine Semplice Via API    quantita=1    prezzo=13

    Apri Dettaglio Ordine    ${ordine}[id]
    Emetti Scontrino Contanti
    Verifica Scontrino Emesso In UI    Contanti
    Click    button[mattooltip="Torna al menu principale"]
    Vai Alla Sezione    Scontrini    /scontrini
    Verifica Scontrino In Lista    ${ordine}[id]
    Verifica Cella Scontrino    ${ordine}[id]    importo    €13.00

Elimina Scontrino Lo Rimuove E L'Ordine Torna Da Pagare
    [Tags]    scontrini    crud
    &{ordine}=    Crea Ordine Semplice Via API
    Crea Scontrino Via API    ${ordine}[id]

    Vai Alla Sezione    Scontrini    /scontrini
    ${messaggio}=    Elimina Scontrino Dalla Lista    ${ordine}[id]    accept
    Should Be Equal    ${messaggio}    Eliminare questo scontrino?

    Verifica Scontrino Non In Lista    ${ordine}[id]
    Verifica Nessuno Scontrino Via API    ${ordine}[id]
    # l'ordine resta e si puo' di nuovo emettere lo scontrino
    Apri Dettaglio Ordine    ${ordine}[id]
    Verifica Nessuno Scontrino In UI

Annullando La Conferma Lo Scontrino Non Viene Eliminato
    [Tags]    scontrini    crud
    &{ordine}=    Crea Ordine Semplice Via API
    Crea Scontrino Via API    ${ordine}[id]

    Vai Alla Sezione    Scontrini    /scontrini
    Elimina Scontrino Dalla Lista    ${ordine}[id]    dismiss

    Verifica Scontrino In Lista    ${ordine}[id]
    Verifica Scontrino Via API    ${ordine}[id]    ${METODO_CONTANTI}    ${ordine}[totale]

L'Importo Dello Scontrino Resta Quello Dell'Ordine Anche Se Il Prezzo Cambia
    [Documentation]    L'importo lo calcola il server dal totale dell'ordine (prezzo fotografato), non dal prezzo attuale.
    [Tags]    scontrini
    &{ordine}=    Crea Ordine Semplice Via API    quantita=2    prezzo=5
    Aggiorna Prezzo Prodotto Via API    ${ordine}[prodotto_id]    50

    Apri Dettaglio Ordine    ${ordine}[id]
    Emetti Scontrino Contanti
    Verifica Scontrino Emesso In UI    Contanti
    Verifica Scontrino Via API    ${ordine}[id]    ${METODO_CONTANTI}    10


# =====================================================================
# COME LANCIARE (dalla cartella robot-tests)
#   robot --outputdir results --suite Scontrini tests
# =====================================================================
