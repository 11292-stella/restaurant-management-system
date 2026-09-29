*** Settings ***
Documentation    Keyword e selettori di Ordini (lista + dettaglio + pagamento simulato), Scontrini e Statistiche.
...              Nel gestionale gli ordini NON si creano dalla UI (arrivano dal kiosk): nei test si creano via API.
Resource         common.resource
Library          Collections


*** Variables ***
# Stati ordine (enum StatoOrdine del backend: 0..4) e relative etichette mostrate in UI
${STATO_IN_ATTESA}          ${0}
${STATO_IN_PREPARAZIONE}    ${1}
${STATO_PRONTO}             ${2}
${STATO_CONSEGNATO}         ${3}
${STATO_ANNULLATO}          ${4}
${METODO_CONTANTI}          ${0}
${METODO_CARTA}             ${1}

# Lista ordini
${INPUT_CERCA_CLIENTE}              role=textbox[name="Cerca cliente"]
${BOTTONE_AZZERA_FILTRI_ORDINI}     button[mattooltip="Azzera filtri"]
${BOTTONE_DETTAGLIO_ORDINE}         button[mattooltip="Dettaglio"]
${MSG_NESSUN_ORDINE_FILTRI}         text=Nessun ordine corrisponde ai filtri selezionati.

# Dettaglio ordine
${TITOLO_ORDINE}                    mat-card h2
${CHIP_STATO_ORDINE}                mat-chip.badge
${TOTALE_ORDINE}                    td.totale-cell
${SCONTRINO_EMESSO}                 .scontrino-emesso
${SCONTRINO_ASSENTE}                .scontrino-assente
${ERRORE_SCONTRINO}                 .errore-scontrino
${BOTTONE_SCONTRINO_CONTANTI}       button:has-text("Emetti scontrino (Contanti)")
${BOTTONE_SCONTRINO_CARTA}          button:has-text("Emetti scontrino (Carta)")
${LINK_TORNA_ALLA_LISTA}            a:has-text("Torna alla lista")

# Dialog pagamento simulato
${DIALOG_PAGAMENTO}                 mat-dialog-container
${INPUT_TITOLARE}                   ${DIALOG_PAGAMENTO} >> input[formcontrolname="titolare"]
${INPUT_NUMERO_CARTA}               ${DIALOG_PAGAMENTO} >> input[formcontrolname="numeroCarta"]
${INPUT_SCADENZA}                   ${DIALOG_PAGAMENTO} >> input[formcontrolname="scadenza"]
${INPUT_CVV}                        ${DIALOG_PAGAMENTO} >> input[formcontrolname="cvv"]
${BOTTONE_PAGA}                     ${DIALOG_PAGAMENTO} >> button:has-text("Paga")
${BOTTONE_ANNULLA_PAGAMENTO}        ${DIALOG_PAGAMENTO} >> button:has-text("Annulla")
${ESITO_PAGAMENTO_ERRORE}           ${DIALOG_PAGAMENTO} >> .esito-errore
${CARTA_CIRCUITO}                   ${DIALOG_PAGAMENTO} >> .carta-preview .circuito
${CARTA_NUMERO}                     ${DIALOG_PAGAMENTO} >> .carta-preview .carta-numero
${CARTA_TITOLARE}                   ${DIALOG_PAGAMENTO} >> .carta-preview .carta-titolare

# Carta di test valida (nessun gateway reale: il pagamento e' simulato)
${CARTA_VISA}          4242424242424242
${CARTA_MASTERCARD}    5555555555554444
${SCADENZA_VALIDA}     1235
${CVV_VALIDO}          123
${CVV_RIFIUTATO}       000

# Scontrini
${BOTTONE_ELIMINA_SCONTRINO}        button[mattooltip="Elimina"]


*** Keywords ***
# ---------------------------------------------------------------------
# Setup / teardown: ogni test registra cio' che crea e il teardown lo cancella
# nell'ordine giusto: scontrino -> ordine -> prodotto -> categoria
# (il backend rifiuta con 409 un prodotto gia' ordinato e un ordine con scontrino)
# ---------------------------------------------------------------------
Prepara Registro Dati Di Test
    [Documentation]    Liste (vuote) degli id creati dal test: le riempiono le keyword "Crea ... Via API".
    Set Test Variable    @{ORDINI_CREATI}       @{EMPTY}
    Set Test Variable    @{PRODOTTI_CREATI}     @{EMPTY}
    Set Test Variable    @{CATEGORIE_CREATE}    @{EMPTY}

Inizia Test Da Loggato
    [Documentation]    Test Setup delle suite Ordini/Scontrini/Statistiche.
    Prepara Registro Dati Di Test
    Apri Gestionale Da Loggato

Pulisci Ordini E Chiudi Contesto
    [Documentation]    Test Teardown: cancella SOLO i dati creati dal test, anche se e' fallito a meta'.
    ${ordini}=       Get Variable Value    ${ORDINI_CREATI}       ${{[]}}
    ${prodotti}=     Get Variable Value    ${PRODOTTI_CREATI}     ${{[]}}
    ${categorie}=    Get Variable Value    ${CATEGORIE_CREATE}    ${{[]}}
    FOR    ${ordine_id}    IN    @{ordini}
        Elimina Scontrino Di Ordine Via API    ${ordine_id}
        Elimina Via API    /api/Ordine/${ordine_id}
    END
    FOR    ${prod_id}    IN    @{prodotti}
        Elimina Via API    /api/Prodotto/${prod_id}
    END
    FOR    ${cat_id}    IN    @{categorie}
        Elimina Via API    /api/Categoria/${cat_id}
    END
    Chiudi Contesto

# ---------------------------------------------------------------------
# Dati di test via API
# ---------------------------------------------------------------------
Crea Prodotto Per Ordini Via API
    [Documentation]    Categoria + prodotto univoci, con prezzo e costo scelti dal test (per calcoli verificabili).
    ...                Ritorna un dizionario con id e nome.
    [Arguments]    ${prezzo}=10    ${costo}=2.5    ${prefisso}=Piatto Robot
    ${prezzo}=      Convert To Number    ${prezzo}
    ${costo}=       Convert To Number    ${costo}
    ${nome_cat}=    Genera Nome Univoco    Cat Ordini Robot
    ${cat_id}=      Crea Categoria Via API    ${nome_cat}
    Append To List    ${CATEGORIE_CREATE}    ${cat_id}
    ${nome}=        Genera Nome Univoco    ${prefisso}
    ${prod_id}=     Crea Prodotto Via API    ${nome}    ${cat_id}    prezzo=${prezzo}    costo=${costo}
    Append To List    ${PRODOTTI_CREATI}    ${prod_id}
    &{prodotto}=    Create Dictionary    id=${prod_id}    nome=${nome}
    RETURN    ${prodotto}

Riga Ordine
    [Documentation]    Una riga per Crea Ordine Via API. Quantita' convertita in intero: il backend (System.Text.Json) rifiuta "2" come stringa.
    [Arguments]    ${prodotto_id}    ${quantita}=1
    ${quantita}=    Convert To Integer    ${quantita}
    &{riga}=    Create Dictionary    prodottoId=${prodotto_id}    quantita=${quantita}
    RETURN    ${riga}

Crea Ordine Via API
    [Documentation]    POST /api/Ordine -> 201. Esempio:
    ...                ${r}=    Riga Ordine    ${prodotto}[id]    2
    ...                ${id}=   Crea Ordine Via API    Tavolo 4    ${r}
    [Arguments]    ${cliente}    @{righe}
    &{headers}=    Headers Autenticati
    @{lista}=      Create List    @{righe}
    &{body}=       Create Dictionary    cliente=${cliente}    righe=${lista}
    ${resp}=       POST On Session    api    /api/Ordine    json=${body}    headers=${headers}    expected_status=201
    ${id}=         Set Variable    ${resp.json()}[id]
    Append To List    ${ORDINI_CREATI}    ${id}
    RETURN    ${id}

Crea Ordine Semplice Via API
    [Documentation]    Scorciatoia: prodotto nuovo (prezzo/costo dati) + ordine con una riga. Ritorna un dizionario
    ...                con id, cliente, prodotto (nome), totale atteso.
    [Arguments]    ${quantita}=2    ${prezzo}=10    ${costo}=2.5    ${cliente}=${None}
    IF    $cliente is None
        ${cliente}=    Genera Nome Univoco    Tavolo Robot
    END
    &{prodotto}=    Crea Prodotto Per Ordini Via API    ${prezzo}    ${costo}
    ${riga}=        Riga Ordine    ${prodotto}[id]    ${quantita}
    ${id}=          Crea Ordine Via API    ${cliente}    ${riga}
    ${totale}=      Evaluate    float(${prezzo}) * int(${quantita})
    &{ordine}=      Create Dictionary    id=${id}    cliente=${cliente}    prodotto=${prodotto}[nome]
    ...             prodotto_id=${prodotto}[id]    totale=${totale}
    RETURN    ${ordine}

Imposta Stato Ordine Via API
    [Documentation]    PUT /api/Ordine/{id}/stato con il numero nudo nel body (es. 4 = ANNULLATO) -> 204.
    [Arguments]    ${ordine_id}    ${stato}
    ${stato}=      Convert To Integer    ${stato}
    &{headers}=    Headers Autenticati
    PUT On Session    api    /api/Ordine/${ordine_id}/stato    json=${stato}    headers=${headers}    expected_status=204

Aggiorna Prezzo Prodotto Via API
    [Documentation]    Legge il prodotto, cambia solo il prezzo e lo salva (PUT completo).
    [Arguments]    ${prodotto_id}    ${nuovo_prezzo}
    &{headers}=    Headers Autenticati
    ${resp}=       GET On Session    api    /api/Prodotto/${prodotto_id}    headers=${headers}
    ${body}=       Set Variable    ${resp.json()}
    ${prezzo}=     Convert To Number    ${nuovo_prezzo}
    Set To Dictionary    ${body}    prezzo=${prezzo}
    PUT On Session    api    /api/Prodotto/${prodotto_id}    json=${body}    headers=${headers}    expected_status=204

Crea Scontrino Via API
    [Documentation]    POST /api/Scontrino -> 201. metodo: 0 = Contanti, 1 = Carta. Ritorna l'id.
    [Arguments]    ${ordine_id}    ${metodo}=0
    ${metodo}=     Convert To Integer    ${metodo}
    &{headers}=    Headers Autenticati
    &{body}=       Create Dictionary    ordineId=${ordine_id}    metodoPagamento=${metodo}
    ${resp}=       POST On Session    api    /api/Scontrino    json=${body}    headers=${headers}    expected_status=201
    RETURN    ${resp.json()}[id]

Leggi Scontrino Di Ordine Via API
    [Documentation]    GET /api/Scontrino/ordine/{id}: ritorna la risposta (200 = emesso, 404 = non emesso).
    [Arguments]    ${ordine_id}
    &{headers}=    Headers Autenticati
    ${resp}=    GET On Session    api    /api/Scontrino/ordine/${ordine_id}    headers=${headers}    expected_status=any
    RETURN    ${resp}

Elimina Scontrino Di Ordine Via API
    [Documentation]    Se l'ordine ha uno scontrino lo cancella (serve prima di poter cancellare l'ordine).
    [Arguments]    ${ordine_id}
    ${resp}=    Leggi Scontrino Di Ordine Via API    ${ordine_id}
    IF    ${resp.status_code} == 200
        Elimina Via API    /api/Scontrino/${resp.json()}[id]
    END

# ---------------------------------------------------------------------
# Verifiche via API
# ---------------------------------------------------------------------
Verifica Stato Ordine Via API
    [Arguments]    ${ordine_id}    ${stato_atteso}
    &{headers}=    Headers Autenticati
    ${resp}=    GET On Session    api    /api/Ordine/${ordine_id}    headers=${headers}
    Should Be Equal As Integers    ${resp.json()}[statoOrdine]    ${stato_atteso}

Verifica Scontrino Via API
    [Documentation]    Lo scontrino esiste, con il metodo atteso e importo = totale dell'ordine (calcolato dal server).
    [Arguments]    ${ordine_id}    ${metodo_atteso}    ${importo_atteso}
    ${resp}=    Leggi Scontrino Di Ordine Via API    ${ordine_id}
    Should Be Equal As Integers    ${resp.status_code}    200    msg=Nessuno scontrino nel backend per l'ordine ${ordine_id}
    Should Be Equal As Integers    ${resp.json()}[metodoPagamento]    ${metodo_atteso}
    Should Be Equal As Numbers     ${resp.json()}[importo]            ${importo_atteso}

Verifica Nessuno Scontrino Via API
    [Arguments]    ${ordine_id}
    ${resp}=    Leggi Scontrino Di Ordine Via API    ${ordine_id}
    Should Be Equal As Integers    ${resp.status_code}    404    msg=L'ordine ${ordine_id} ha uno scontrino, non doveva averlo

Verifica Prodotto Ancora Presente Via API
    [Arguments]    ${prodotto_id}
    &{headers}=    Headers Autenticati
    GET On Session    api    /api/Prodotto/${prodotto_id}    headers=${headers}    expected_status=200

# ---------------------------------------------------------------------
# Lista ordini
# ---------------------------------------------------------------------
Cerca Cliente
    [Arguments]    ${testo}
    Fill Text    ${INPUT_CERCA_CLIENTE}    ${testo}

Filtra Ordini Per Stato
    [Documentation]    Dropdown "Stato" sopra la tabella (Tutti / In attesa / ... / Annullato).
    [Arguments]    ${etichetta}
    Seleziona Da Dropdown    Stato    ${etichetta}

Azzera Filtri Ordini
    Click    ${BOTTONE_AZZERA_FILTRI_ORDINI}

Verifica Ordine In Lista
    [Arguments]    ${cliente}
    Wait For Elements State    tr:has-text("${cliente}")    visible

Verifica Ordine Non In Lista
    [Arguments]    ${cliente}
    Wait For Elements State    tr:has-text("${cliente}")    hidden

Verifica Cella Ordine
    [Documentation]    Colonne: cliente, dataOra, totale, stato.
    [Arguments]    ${cliente}    ${colonna}    ${atteso}
    Get Text    tr:has-text("${cliente}") >> td.mat-column-${colonna}    *=    ${atteso}

Cambia Stato Ordine Dalla Lista
    [Documentation]    Cambia lo stato dal menu a tendina nella riga e aspetta la risposta del backend (ritorna lo status HTTP).
    [Arguments]    ${cliente}    ${ordine_id}    ${etichetta}
    ${attesa}=    Promise To    Wait For Response    matcher=**/api/Ordine/${ordine_id}/stato
    Click    tr:has-text("${cliente}") >> mat-select
    Click    role=option[name="${etichetta}"]
    ${risposta}=    Wait For    ${attesa}
    RETURN    ${risposta}[status]

Apri Dettaglio Ordine Dalla Lista
    [Arguments]    ${cliente}    ${ordine_id}
    Click      tr:has-text("${cliente}") >> ${BOTTONE_DETTAGLIO_ORDINE}
    Get Url    matches    .*/ordini/${ordine_id}$
    Wait For Elements State    ${TITOLO_ORDINE}    visible

# ---------------------------------------------------------------------
# Dettaglio ordine
# ---------------------------------------------------------------------
Apri Dettaglio Ordine
    [Documentation]    Apre direttamente /ordini/{id} e aspetta che l'ordine sia caricato.
    [Arguments]    ${ordine_id}
    Vai Alla Pagina    /ordini/${ordine_id}
    Wait For Elements State    ${TITOLO_ORDINE}    visible

Verifica Intestazione Ordine
    [Arguments]    ${ordine_id}    ${cliente}    ${stato}
    Get Text    ${TITOLO_ORDINE}        *=    Ordine #${ordine_id}
    Get Text    ${TITOLO_ORDINE}        *=    ${cliente}
    Get Text    ${CHIP_STATO_ORDINE}    *=    ${stato}

Verifica Riga Dettaglio
    [Documentation]    Colonne: quantita, prezzoUnitario, subtotale.
    [Arguments]    ${prodotto}    ${colonna}    ${atteso}
    Get Text    table.righe-table tr:has-text("${prodotto}") >> td.mat-column-${colonna}    ==    ${atteso}

Verifica Totale Dettaglio
    [Arguments]    ${atteso}
    Get Text    ${TOTALE_ORDINE}    ==    ${atteso}

Emetti Scontrino Contanti
    Click    ${BOTTONE_SCONTRINO_CONTANTI}

Verifica Scontrino Emesso In UI
    [Arguments]    ${metodo}
    Wait For Elements State    ${SCONTRINO_EMESSO}    visible
    Get Text    ${SCONTRINO_EMESSO}    *=    (${metodo})
    Get Element Count    ${BOTTONE_SCONTRINO_CONTANTI}    ==    0

Verifica Nessuno Scontrino In UI
    Get Text    ${SCONTRINO_ASSENTE}    *=    Nessuno scontrino emesso per questo ordine
    Wait For Elements State    ${BOTTONE_SCONTRINO_CONTANTI}    visible

Verifica Nessun Errore In Pagina
    Get Element Count    .stato-errore        ==    0
    Get Element Count    ${ERRORE_SCONTRINO}    ==    0

# ---------------------------------------------------------------------
# Pagamento con carta (simulato)
# ---------------------------------------------------------------------
Apri Pagamento Con Carta
    [Documentation]    Apre il dialog e aspetta che il focus sia sul primo campo.
    ...                Perche': a fine animazione MatDialog sposta il focus sul primo campo (autoFocus).
    ...                Se si scrive prima, il testo del CVV puo' finire nel Titolare ("Mario Rossi000"):
    ...                test flaky trovato con l'HTML salvato automaticamente dal teardown.
    Click    ${BOTTONE_SCONTRINO_CARTA}
    Wait For Elements State    ${DIALOG_PAGAMENTO}    visible
    Wait For Elements State    ${INPUT_TITOLARE}      focused

Compila Dati Carta
    [Documentation]    Scrive i campi della carta. Numero e scadenza si formattano da soli (spazi e "/").
    [Arguments]    ${titolare}=Mario Rossi    ${numero}=${CARTA_VISA}    ${scadenza}=${SCADENZA_VALIDA}    ${cvv}=${CVV_VALIDO}
    Fill Text    ${INPUT_TITOLARE}        ${titolare}
    Fill Text    ${INPUT_NUMERO_CARTA}    ${numero}
    Fill Text    ${INPUT_SCADENZA}        ${scadenza}
    Fill Text    ${INPUT_CVV}             ${cvv}

Conferma Pagamento
    [Documentation]    Clicca Paga: c'e' un'elaborazione finta di ~1,2 secondi, poi il dialog si chiude (se il pagamento riesce).
    Click    ${BOTTONE_PAGA}

Verifica Dialog Pagamento Chiuso
    Wait For Elements State    ${DIALOG_PAGAMENTO}    detached

Verifica Paga Disabilitato
    Wait For Elements State    ${BOTTONE_PAGA}    disabled

Verifica Paga Abilitato
    Wait For Elements State    ${BOTTONE_PAGA}    enabled

# ---------------------------------------------------------------------
# Scontrini
# ---------------------------------------------------------------------
Riga Scontrino
    [Documentation]    Selettore della riga della lista scontrini per numero d'ordine (":text-is" = testo esatto, #12 non trova #123).
    [Arguments]    ${ordine_id}
    RETURN    tr:has(a.ordine-link:text-is("#${ordine_id}"))

Verifica Scontrino In Lista
    [Arguments]    ${ordine_id}
    ${riga}=    Riga Scontrino    ${ordine_id}
    Wait For Elements State    ${riga}    visible

Verifica Scontrino Non In Lista
    [Arguments]    ${ordine_id}
    ${riga}=    Riga Scontrino    ${ordine_id}
    Wait For Elements State    ${riga}    hidden

Verifica Cella Scontrino
    [Documentation]    Colonne: dataEmissione, importo, metodo.
    [Arguments]    ${ordine_id}    ${colonna}    ${atteso}
    ${riga}=    Riga Scontrino    ${ordine_id}
    Get Text    ${riga} >> td.mat-column-${colonna}    *=    ${atteso}

Elimina Scontrino Dalla Lista
    [Documentation]    Cestino + risposta al confirm() nativo (accept = OK, dismiss = Annulla).
    [Arguments]    ${ordine_id}    ${azione}=accept
    ${riga}=         Riga Scontrino    ${ordine_id}
    ${promessa}=     Promise To    Wait For Alert    action=${azione}
    Click            ${riga} >> ${BOTTONE_ELIMINA_SCONTRINO}
    ${messaggio}=    Wait For    ${promessa}
    RETURN    ${messaggio}

# ---------------------------------------------------------------------
# Statistiche
# ---------------------------------------------------------------------
Riga Statistica
    [Arguments]    ${nome_prodotto}
    RETURN    .riga-grafico:has(.riga-nome:text-is("${nome_prodotto}"))

Verifica Statistica Prodotto
    [Documentation]    Riga del grafico food cost: "<n> venduti · ricavo €x · margine €y" + percentuale.
    [Arguments]    ${nome_prodotto}    ${venduti}    ${ricavo}    ${margine}    ${food_cost}
    ${riga}=    Riga Statistica    ${nome_prodotto}
    Wait For Elements State    ${riga}    visible
    Get Text    ${riga} >> .riga-dettaglio    *=    ${venduti} venduti
    Get Text    ${riga} >> .riga-dettaglio    *=    ricavo ${ricavo}
    Get Text    ${riga} >> .riga-dettaglio    *=    margine ${margine}
    Get Text    ${riga} >> .barra-valore      ==    ${food_cost}

Verifica Classe Food Cost
    [Documentation]    Colore della barra: fc-ottimo (<30%), fc-normale (30-40%), fc-alto (>=40%).
    [Arguments]    ${nome_prodotto}    ${classe}
    ${riga}=    Riga Statistica    ${nome_prodotto}
    Get Attribute    ${riga} >> .barra    class    *=    fc-${classe}
