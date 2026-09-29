*** Settings ***
Documentation     Test E2E della sezione Ordini: lista, filtri, cambio stato, dettaglio,
...               emissione scontrino (contanti e carta simulata).
...               Gli ordini arrivano dal kiosk, quindi nei test si creano via API (Arrange)
...               e si verificano sia in UI sia nel backend.
Resource          ../resources/ordini_page.resource
Resource          ../resources/prodotti_page.resource
Suite Setup       Apri Browser
Suite Teardown    Close Browser
Test Setup        Inizia Test Da Loggato
Test Teardown     Pulisci Ordini E Chiudi Contesto


*** Test Cases ***
# ---------------------------------------------------------------------
# Lista ordini
# ---------------------------------------------------------------------
Dalla Dashboard Si Apre La Lista Ordini Con I Dati Dell'Ordine
    [Tags]    smoke    ordini
    &{ordine}=    Crea Ordine Semplice Via API    quantita=2    prezzo=10

    Vai Alla Sezione    Ordini    /ordini
    Verifica Titolo Pagina    Ordini
    Cerca Cliente    ${ordine}[cliente]
    Verifica Ordine In Lista    ${ordine}[cliente]
    Verifica Cella Ordine    ${ordine}[cliente]    totale    €20.00
    Verifica Cella Ordine    ${ordine}[cliente]    stato     In attesa
    Get Text    tr:has-text("${ordine}[cliente]") >> td.mat-column-dataOra    matches    ^\\d{2}/\\d{2}/\\d{4} \\d{2}:\\d{2}$

La Ricerca Per Cliente Non Distingue Maiuscole E Minuscole
    [Tags]    ordini    filtri
    &{ordine}=    Crea Ordine Semplice Via API
    ${minuscolo}=    Convert To Lower Case    ${ordine}[cliente]

    Vai Alla Sezione    Ordini    /ordini
    Cerca Cliente    ${minuscolo}
    Verifica Ordine In Lista    ${ordine}[cliente]

    Cerca Cliente    cliente-che-non-esiste-xyz
    Wait For Elements State    ${MSG_NESSUN_ORDINE_FILTRI}    visible

Il Filtro Per Stato Mostra Solo Gli Ordini In Quello Stato
    [Tags]    ordini    filtri
    ${prefisso}=     Genera Nome Univoco    Filtro Robot
    &{pronto}=       Crea Ordine Semplice Via API    cliente=${prefisso} Uno
    &{in_attesa}=    Crea Ordine Semplice Via API    cliente=${prefisso} Due
    Imposta Stato Ordine Via API    ${pronto}[id]    ${STATO_PRONTO}

    Vai Alla Sezione    Ordini    /ordini
    Cerca Cliente    ${prefisso}
    Verifica Ordine In Lista    ${pronto}[cliente]
    Verifica Ordine In Lista    ${in_attesa}[cliente]

    Filtra Ordini Per Stato    Pronto
    Verifica Ordine In Lista        ${pronto}[cliente]
    Verifica Ordine Non In Lista    ${in_attesa}[cliente]

    Filtra Ordini Per Stato    In attesa
    Verifica Ordine In Lista        ${in_attesa}[cliente]
    Verifica Ordine Non In Lista    ${pronto}[cliente]

Azzera Filtri Mostra Di Nuovo Tutti Gli Ordini
    [Tags]    ordini    filtri
    ${prefisso}=     Genera Nome Univoco    Azzera Robot
    &{pronto}=       Crea Ordine Semplice Via API    cliente=${prefisso} Uno
    &{in_attesa}=    Crea Ordine Semplice Via API    cliente=${prefisso} Due
    Imposta Stato Ordine Via API    ${pronto}[id]    ${STATO_PRONTO}

    Vai Alla Sezione    Ordini    /ordini
    Filtra Ordini Per Stato    Pronto
    Cerca Cliente    ${prefisso}
    Verifica Ordine Non In Lista    ${in_attesa}[cliente]

    Azzera Filtri Ordini
    Get Property    ${INPUT_CERCA_CLIENTE}    value    ==    ${EMPTY}
    Verifica Ordine In Lista    ${pronto}[cliente]
    Verifica Ordine In Lista    ${in_attesa}[cliente]

Cambiare Stato Dalla Lista Lo Salva Nel Backend
    [Tags]    smoke    ordini    crud
    &{ordine}=    Crea Ordine Semplice Via API

    Vai Alla Sezione    Ordini    /ordini
    Cerca Cliente    ${ordine}[cliente]
    ${status}=    Cambia Stato Ordine Dalla Lista    ${ordine}[cliente]    ${ordine}[id]    Consegnato

    Should Be Equal As Integers    ${status}    204
    Verifica Stato Ordine Via API    ${ordine}[id]    ${STATO_CONSEGNATO}
    # dopo il ricaricamento lo stato arriva dal backend, non dalla memoria della pagina
    Reload
    Cerca Cliente    ${ordine}[cliente]
    Verifica Cella Ordine    ${ordine}[cliente]    stato    Consegnato

Dalla Lista Si Apre Il Dettaglio Dell'Ordine
    [Tags]    ordini    navigazione
    &{ordine}=    Crea Ordine Semplice Via API

    Vai Alla Sezione    Ordini    /ordini
    Cerca Cliente    ${ordine}[cliente]
    Apri Dettaglio Ordine Dalla Lista    ${ordine}[cliente]    ${ordine}[id]
    Verifica Intestazione Ordine    ${ordine}[id]    ${ordine}[cliente]    In attesa

# ---------------------------------------------------------------------
# Dettaglio ordine
# ---------------------------------------------------------------------
Il Dettaglio Mostra Righe Subtotali E Totale Corretti
    [Tags]    ordini
    &{pizza}=     Crea Prodotto Per Ordini Via API    prezzo=10    costo=3
    &{acqua}=     Crea Prodotto Per Ordini Via API    prezzo=4.5    costo=1
    ${cliente}=   Genera Nome Univoco    Tavolo Robot
    ${riga1}=     Riga Ordine    ${pizza}[id]    2
    ${riga2}=     Riga Ordine    ${acqua}[id]    1
    ${id}=        Crea Ordine Via API    ${cliente}    ${riga1}    ${riga2}

    Apri Dettaglio Ordine    ${id}
    Verifica Intestazione Ordine    ${id}    ${cliente}    In attesa
    Verifica Riga Dettaglio    ${pizza}[nome]    quantita          2
    Verifica Riga Dettaglio    ${pizza}[nome]    prezzoUnitario    €10.00
    Verifica Riga Dettaglio    ${pizza}[nome]    subtotale         €20.00
    Verifica Riga Dettaglio    ${acqua}[nome]    quantita          1
    Verifica Riga Dettaglio    ${acqua}[nome]    subtotale         €4.50
    Verifica Totale Dettaglio    €24.50
    Verifica Nessuno Scontrino In UI

Il Prezzo Dell'Ordine Non Cambia Se Cambia Il Prezzo Del Prodotto
    [Documentation]    Il prezzo e' "fotografato" al momento dell'ordine: lo storico non deve cambiare.
    [Tags]    ordini
    &{ordine}=    Crea Ordine Semplice Via API    quantita=1    prezzo=10
    Aggiorna Prezzo Prodotto Via API    ${ordine}[prodotto_id]    99

    Apri Dettaglio Ordine    ${ordine}[id]
    Verifica Riga Dettaglio    ${ordine}[prodotto]    prezzoUnitario    €10.00
    Verifica Totale Dettaglio    €10.00

Un Ordine Inesistente Mostra Ordine Non Trovato
    [Tags]    ordini
    Vai Alla Pagina    /ordini/999999
    Verifica Errore Nel Form    Ordine non trovato.

Torna Alla Lista Dal Dettaglio
    [Tags]    ordini    navigazione
    &{ordine}=    Crea Ordine Semplice Via API
    Apri Dettaglio Ordine    ${ordine}[id]
    Click    ${LINK_TORNA_ALLA_LISTA}
    Get Url    matches    .*/ordini$

# ---------------------------------------------------------------------
# Scontrino in contanti
# ---------------------------------------------------------------------
Emetti Scontrino In Contanti
    [Tags]    smoke    ordini    scontrini    crud
    &{ordine}=    Crea Ordine Semplice Via API    quantita=3    prezzo=7.5

    Apri Dettaglio Ordine    ${ordine}[id]
    Verifica Nessuno Scontrino In UI
    Emetti Scontrino Contanti

    Verifica Scontrino Emesso In UI    Contanti
    Verifica Scontrino Via API    ${ordine}[id]    ${METODO_CONTANTI}    ${ordine}[totale]

Doppio Click Su Emetti Scontrino Non Mostra Errori
    [Documentation]    Prima: il secondo click partiva prima della risposta, il backend rispondeva 400
    ...                ("ha gia' uno scontrino") e la pagina mostrava SOLO l'errore, anche se lo scontrino era stato emesso.
    [Tags]    ordini    scontrini    validazione
    &{ordine}=    Crea Ordine Semplice Via API

    Apri Dettaglio Ordine    ${ordine}[id]
    Click With Options    ${BOTTONE_SCONTRINO_CONTANTI}    clickCount=2
    Wait For Load State    networkidle

    Verifica Scontrino Emesso In UI    Contanti
    Verifica Nessun Errore In Pagina
    Verifica Scontrino Via API    ${ordine}[id]    ${METODO_CONTANTI}    ${ordine}[totale]

Ordine Annullato Non Permette Lo Scontrino
    [Documentation]    Un ordine annullato non e' una vendita. Prima: bottoni visibili e scontrino emesso lo stesso.
    [Tags]    ordini    scontrini    validazione
    &{ordine}=    Crea Ordine Semplice Via API
    Imposta Stato Ordine Via API    ${ordine}[id]    ${STATO_ANNULLATO}

    Apri Dettaglio Ordine    ${ordine}[id]
    Get Text    ${CHIP_STATO_ORDINE}    *=    Annullato
    Get Text    ${SCONTRINO_ASSENTE}    *=    Ordine annullato
    Get Element Count    ${BOTTONE_SCONTRINO_CONTANTI}    ==    0
    Get Element Count    ${BOTTONE_SCONTRINO_CARTA}       ==    0
    Verifica Nessuno Scontrino Via API    ${ordine}[id]

# ---------------------------------------------------------------------
# Pagamento con carta (simulato)
# ---------------------------------------------------------------------
Pagamento Con Carta Emette Lo Scontrino Carta
    [Tags]    smoke    ordini    scontrini    pagamento    crud
    &{ordine}=    Crea Ordine Semplice Via API    quantita=2    prezzo=12.25

    Apri Dettaglio Ordine    ${ordine}[id]
    Apri Pagamento Con Carta
    Get Text    ${BOTTONE_PAGA}    *=    €24.50
    Compila Dati Carta
    Conferma Pagamento

    Verifica Dialog Pagamento Chiuso
    Verifica Scontrino Emesso In UI    Carta
    Verifica Scontrino Via API    ${ordine}[id]    ${METODO_CARTA}    ${ordine}[totale]

Pagamento Rifiutato Non Emette Lo Scontrino
    [Documentation]    CVV 000 simula il rifiuto della banca: messaggio nel dialog, nessuno scontrino.
    [Tags]    ordini    pagamento
    &{ordine}=    Crea Ordine Semplice Via API

    Apri Dettaglio Ordine    ${ordine}[id]
    Apri Pagamento Con Carta
    Compila Dati Carta    cvv=${CVV_RIFIUTATO}
    Conferma Pagamento

    Wait For Elements State    ${ESITO_PAGAMENTO_ERRORE}    visible
    Get Text    ${ESITO_PAGAMENTO_ERRORE}    *=    Pagamento rifiutato
    Wait For Elements State    ${DIALOG_PAGAMENTO}    visible
    Click    ${BOTTONE_ANNULLA_PAGAMENTO}
    Verifica Dialog Pagamento Chiuso
    Verifica Nessuno Scontrino In UI
    Verifica Nessuno Scontrino Via API    ${ordine}[id]

Annulla Nel Pagamento Non Emette Lo Scontrino
    [Tags]    ordini    pagamento
    &{ordine}=    Crea Ordine Semplice Via API

    Apri Dettaglio Ordine    ${ordine}[id]
    Apri Pagamento Con Carta
    Compila Dati Carta
    Click    ${BOTTONE_ANNULLA_PAGAMENTO}

    Verifica Dialog Pagamento Chiuso
    Verifica Nessuno Scontrino In UI
    Verifica Nessuno Scontrino Via API    ${ordine}[id]

Con Dati Carta Non Validi Paga E' Disabilitato
    [Tags]    ordini    pagamento    validazione
    &{ordine}=    Crea Ordine Semplice Via API
    Apri Dettaglio Ordine    ${ordine}[id]
    Apri Pagamento Con Carta
    Verifica Paga Disabilitato

    Compila Dati Carta
    Verifica Paga Abilitato

    # numero carta incompleto (12 cifre)
    Fill Text    ${INPUT_NUMERO_CARTA}    424242424242
    Verifica Paga Disabilitato
    Fill Text    ${INPUT_NUMERO_CARTA}    ${CARTA_VISA}
    Verifica Paga Abilitato

    # mese 13 inesistente
    Fill Text    ${INPUT_SCADENZA}    1330
    Verifica Paga Disabilitato
    Fill Text    ${INPUT_SCADENZA}    ${SCADENZA_VALIDA}
    Verifica Paga Abilitato

    # CVV di 2 cifre
    Fill Text    ${INPUT_CVV}    12
    Verifica Paga Disabilitato
    Fill Text    ${INPUT_CVV}    ${CVV_VALIDO}
    Verifica Paga Abilitato

    # titolare vuoto
    Fill Text    ${INPUT_TITOLARE}    ${EMPTY}
    Verifica Paga Disabilitato

Una Carta Scaduta Non Si Puo' Usare
    [Documentation]    Prima: il pattern controllava solo il formato MM/AA, "01/20" veniva accettata.
    [Tags]    ordini    pagamento    validazione
    &{ordine}=    Crea Ordine Semplice Via API
    Apri Dettaglio Ordine    ${ordine}[id]
    Apri Pagamento Con Carta
    Compila Dati Carta    scadenza=0120

    Wait For Elements State    ${DIALOG_PAGAMENTO} >> mat-error >> text=Carta scaduta    visible
    Verifica Paga Disabilitato

Il Numero Carta Si Formatta E Riconosce Il Circuito
    [Tags]    ordini    pagamento
    &{ordine}=    Crea Ordine Semplice Via API
    Apri Dettaglio Ordine    ${ordine}[id]
    Apri Pagamento Con Carta

    Fill Text    ${INPUT_NUMERO_CARTA}    ${CARTA_VISA}
    Get Property    ${INPUT_NUMERO_CARTA}    value    ==    4242 4242 4242 4242
    Get Text    ${CARTA_CIRCUITO}    ==    VISA
    Get Text    ${CARTA_NUMERO}      ==    4242 4242 4242 4242

    Fill Text    ${INPUT_NUMERO_CARTA}    ${CARTA_MASTERCARD}
    Get Text    ${CARTA_CIRCUITO}    ==    Mastercard

    Fill Text    ${INPUT_SCADENZA}    1235
    Get Property    ${INPUT_SCADENZA}    value    ==    12/35

    # sulla carta il nome appare in MAIUSCOLO (text-transform CSS): Get Text legge il testo come lo vede l'utente
    Fill Text    ${INPUT_TITOLARE}    Giulia Bianchi
    Get Text    ${CARTA_TITOLARE}    ==    GIULIA BIANCHI

# ---------------------------------------------------------------------
# Integrita' dei dati
# ---------------------------------------------------------------------
Un Prodotto Gia' Ordinato Non Si Puo' Eliminare
    [Documentation]    Eliminandolo sparirebbero le righe degli ordini passati: il backend risponde 409
    ...                e la lista prodotti mostra il motivo (toast) senza togliere il prodotto.
    [Tags]    ordini    prodotti    crud
    &{ordine}=    Crea Ordine Semplice Via API

    Vai Alla Sezione    Prodotti    /prodotti
    Cerca Prodotto    ${ordine}[prodotto]
    ${attesa}=    Promise To    Wait For Response    matcher=**/api/Prodotto/${ordine}[prodotto_id]
    Elimina Prodotto Dalla Lista    ${ordine}[prodotto]    accept
    ${risposta}=    Wait For    ${attesa}

    Should Be Equal As Integers    ${risposta}[status]    409
    Verifica Notifica    Impossibile eliminare
    Verifica Prodotto In Lista    ${ordine}[prodotto]
    Verifica Prodotto Ancora Presente Via API    ${ordine}[prodotto_id]


# =====================================================================
# COME LANCIARE (dalla cartella robot-tests)
#   robot --outputdir results --suite Ordini tests
#   robot --outputdir results --include pagamento tests
# =====================================================================
