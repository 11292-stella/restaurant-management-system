*** Settings ***
Documentation     Test E2E della pagina Statistiche: vendite, ricavo, margine e food cost per prodotto.
...               Ogni test crea prodotti con prezzo e costo scelti apposta, cosi' i numeri attesi
...               si calcolano a mano (i totali generali invece dipendono da tutti gli ordini nel DB).
Resource          ../resources/ordini_page.resource
Suite Setup       Apri Browser
Suite Teardown    Close Browser
Test Setup        Inizia Test Da Loggato
Test Teardown     Pulisci Ordini E Chiudi Contesto


*** Test Cases ***
Dalla Dashboard Si Aprono Le Statistiche Con Il Riepilogo
    [Tags]    smoke    statistiche
    Crea Ordine Semplice Via API

    Vai Alla Sezione    Statistiche    /statistiche
    Verifica Titolo Pagina    Statistiche vendite e costi
    FOR    ${etichetta}    IN    Ricavo totale    Costo di produzione    Margine    Food cost medio
        Wait For Elements State    .riepilogo-card >> text=${etichetta}    visible
    END

Vendite Ricavo Margine E Food Cost Di Un Prodotto
    [Documentation]    Prezzo 10, costo 2,50, venduti 2 -> ricavo 20, costo 5, margine 15, food cost 25% (ottimo).
    [Tags]    statistiche
    &{ordine}=    Crea Ordine Semplice Via API    quantita=2    prezzo=10    costo=2.5

    Vai Alla Sezione    Statistiche    /statistiche
    Verifica Statistica Prodotto    ${ordine}[prodotto]    2    €20.00    €15.00    25%
    Verifica Classe Food Cost       ${ordine}[prodotto]    ottimo

Piu' Ordini Dello Stesso Prodotto Vengono Sommati
    [Documentation]    2 + 3 pezzi a 10 euro (costo 2,50) -> 5 venduti, ricavo 50, margine 37,50.
    [Tags]    statistiche
    &{prodotto}=    Crea Prodotto Per Ordini Via API    prezzo=10    costo=2.5
    ${riga_a}=      Riga Ordine    ${prodotto}[id]    2
    ${riga_b}=      Riga Ordine    ${prodotto}[id]    3
    Crea Ordine Via API    Tavolo Robot A    ${riga_a}
    Crea Ordine Via API    Tavolo Robot B    ${riga_b}

    Vai Alla Sezione    Statistiche    /statistiche
    Verifica Statistica Prodotto    ${prodotto}[nome]    5    €50.00    €37.50    25%

Gli Ordini Annullati Non Contano Nelle Vendite
    [Tags]    statistiche
    &{prodotto}=    Crea Prodotto Per Ordini Via API    prezzo=10    costo=2.5
    ${riga_valida}=       Riga Ordine    ${prodotto}[id]    2
    ${riga_annullata}=    Riga Ordine    ${prodotto}[id]    5
    Crea Ordine Via API    Tavolo Robot Valido    ${riga_valida}
    ${annullato}=    Crea Ordine Via API    Tavolo Robot Annullato    ${riga_annullata}
    Imposta Stato Ordine Via API    ${annullato}    ${STATO_ANNULLATO}

    Vai Alla Sezione    Statistiche    /statistiche
    Verifica Statistica Prodotto    ${prodotto}[nome]    2    €20.00    €15.00    25%

Food Cost Alto E Normale Vengono Evidenziati
    [Documentation]    Soglie: sotto 30% ottimo, 30-40% normale, da 40% alto.
    ...                Prezzo 4 costo 2 -> 50% alto; prezzo 10 costo 3,50 -> 35% normale.
    [Tags]    statistiche
    &{caro}=       Crea Ordine Semplice Via API    quantita=1    prezzo=4     costo=2
    &{normale}=    Crea Ordine Semplice Via API    quantita=1    prezzo=10    costo=3.5

    Vai Alla Sezione    Statistiche    /statistiche
    Verifica Statistica Prodotto    ${caro}[prodotto]       1    €4.00     €2.00    50%
    Verifica Classe Food Cost       ${caro}[prodotto]       alto
    Verifica Statistica Prodotto    ${normale}[prodotto]    1    €10.00    €6.50    35%
    Verifica Classe Food Cost       ${normale}[prodotto]    normale

Le Vendite Usano Il Prezzo Dell'Ordine Non Quello Attuale
    [Documentation]    Il ricavo si calcola sul prezzo pagato (fotografato nell'ordine).
    [Tags]    statistiche
    &{ordine}=    Crea Ordine Semplice Via API    quantita=2    prezzo=10    costo=2.5
    Aggiorna Prezzo Prodotto Via API    ${ordine}[prodotto_id]    30

    Vai Alla Sezione    Statistiche    /statistiche
    Verifica Statistica Prodotto    ${ordine}[prodotto]    2    €20.00    €15.00    25%


# =====================================================================
# COME LANCIARE (dalla cartella robot-tests)
#   robot --outputdir results --suite Statistiche tests
# =====================================================================
