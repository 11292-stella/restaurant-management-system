*** Settings ***
Documentation    Keyword e selettori della sezione Prodotti (lista + form crea/modifica).
Resource         common.resource


*** Variables ***
# Lista
${INPUT_CERCA}               role=textbox[name="Cerca prodotto"]
${BOTTONE_NUOVO_PRODOTTO}    role=button[name="Nuovo prodotto"]
${BOTTONE_MODIFICA}          button[mattooltip="Modifica"]
${BOTTONE_ELIMINA}           button[mattooltip="Elimina"]
${BOTTONE_AZZERA_FILTRI}     button[mattooltip="Azzera filtri"]
${MSG_NESSUN_PRODOTTO}       text=Nessun prodotto corrisponde ai filtri selezionati.

# Form prodotto
${INPUT_NOME}                role=textbox[name="Nome"]
${INPUT_DESCRIZIONE}         role=textbox[name="Descrizione"]
${INPUT_PREZZO}              role=spinbutton[name="Prezzo"]
${INPUT_COSTO}               role=spinbutton[name="Costo produzione"]
${INPUT_IMMAGINE}            role=textbox[name="Immagine (URL)"]
${SWITCH_ATTIVO}             role=switch[name="Attivo"]
${SWITCH_ESAURITO}           role=switch[name="Esaurito"]
${BOTTONE_SALVA}             role=button[name="Salva"]
${BOTTONE_ANNULLA}           role=button[name="Annulla"]


*** Keywords ***
# ---------------------------------------------------------------------
# Azioni - lista
# ---------------------------------------------------------------------
Cerca Prodotto
    [Documentation]    Scrive il testo nella barra di ricerca dei prodotti.
    [Arguments]    ${testo}
    Fill Text    ${INPUT_CERCA}    ${testo}

Filtra Per Categoria
    [Documentation]    Sceglie una categoria dal dropdown "Categoria" dei filtri.
    [Arguments]    ${categoria}
    Seleziona Da Dropdown    Categoria    ${categoria}

Filtra Per Stato
    [Documentation]    Sceglie uno stato (Tutti / Attivo / Esaurito / Disattivo) dal dropdown "Stato" dei filtri.
    [Arguments]    ${stato}
    Seleziona Da Dropdown    Stato    ${stato}

Azzera Filtri Prodotti
    [Documentation]    Clicca "Azzera filtri" (il bottone compare solo se c'e' almeno un filtro attivo).
    Click    ${BOTTONE_AZZERA_FILTRI}

Apri Form Nuovo Prodotto
    [Documentation]    Dalla lista prodotti clicca "Nuovo prodotto" e verifica che si apra il form di creazione.
    Click      ${BOTTONE_NUOVO_PRODOTTO}
    Get Url    contains    /prodotti/nuovo

Apri Form Modifica Prodotto
    [Documentation]    Clicca la matita SOLO nella riga del prodotto indicato (tr:has-text = la riga che contiene quel testo)
    ...                e verifica che si apra il form di modifica (/prodotti/<id>).
    ...                Poi ASPETTA che il form sia popolato col prodotto: Angular carica i dati in modo asincrono (getById + patchValue)
    ...                e, se compilassimo prima, i nostri valori verrebbero sovrascritti con quelli vecchi.
    [Arguments]    ${nome}
    Click      tr:has-text("${nome}") >> ${BOTTONE_MODIFICA}
    Get Url    matches    .*/prodotti/\\d+$
    Get Property    ${INPUT_NOME}    value    ==    ${nome}

Elimina Prodotto Dalla Lista
    [Documentation]    Clicca il cestino nella riga del prodotto e risponde al confirm() nativo del browser.
    ...                azione=accept -> OK (elimina) | azione=dismiss -> Annulla.
    ...                "Promise To" prepara l'attesa del popup PRIMA del click (il popup blocca la pagina finche' non si risponde);
    ...                se il popup non compare il test fallisce: verifichiamo anche che la conferma venga chiesta.
    [Arguments]    ${nome}    ${azione}=accept
    ${promessa}=     Promise To    Wait For Alert    action=${azione}
    Click            tr:has-text("${nome}") >> ${BOTTONE_ELIMINA}
    ${messaggio}=    Wait For    ${promessa}
    Log    Testo del confirm: ${messaggio}
    RETURN    ${messaggio}

# ---------------------------------------------------------------------
# Azioni - form (crea e modifica usano lo stesso form)
# ---------------------------------------------------------------------
Compila Form Prodotto
    [Documentation]    Compila tutti i campi del form prodotto (senza salvare) dal dizionario di "Genera Dati Prodotto".
    [Arguments]    ${prodotto}
    # prezzo e costo sono numeri: Fill Text vuole testo
    ${prezzo}=    Convert To String    ${prodotto}[prezzo]
    ${costo}=     Convert To String    ${prodotto}[costo]
    Fill Text    ${INPUT_NOME}           ${prodotto}[nome]
    Fill Text    ${INPUT_DESCRIZIONE}    ${prodotto}[descrizione]
    Fill Text    ${INPUT_PREZZO}         ${prezzo}
    Fill Text    ${INPUT_COSTO}          ${costo}
    Fill Text    ${INPUT_IMMAGINE}       ${prodotto}[immagine]
    Seleziona Da Dropdown    Categoria    ${prodotto}[categoria]
    Imposta Switch    ${SWITCH_ATTIVO}      ${prodotto}[attivo]
    Imposta Switch    ${SWITCH_ESAURITO}    ${prodotto}[esaurito]

Salva Prodotto
    [Documentation]    Clicca Salva e verifica di essere tornati alla lista prodotti (vale sia per crea che per modifica).
    Click      ${BOTTONE_SALVA}
    Get Url    matches    .*/prodotti$

Annulla Form Prodotto
    [Documentation]    Clicca Annulla e verifica di essere tornati alla lista senza salvare.
    Click      ${BOTTONE_ANNULLA}
    Get Url    matches    .*/prodotti$

# ---------------------------------------------------------------------
# Verifiche
# ---------------------------------------------------------------------
Verifica Prodotto In Lista
    [Documentation]    Controlla che un prodotto con quel nome sia visibile nella lista.
    [Arguments]    ${nome}
    Wait For Elements State    text=${nome}    visible

Verifica Prodotto Non In Lista
    [Documentation]    Controlla che un prodotto NON sia visibile (es. escluso dal filtro o rinominato).
    [Arguments]    ${nome}
    Wait For Elements State    text=${nome}    hidden

Verifica Prodotto Via API
    [Documentation]    Doppio controllo: oltre alla lista, verifica nel backend che nome e prezzo siano stati salvati davvero.
    [Arguments]    ${id}    ${nome}    ${prezzo}
    &{headers}=    Headers Autenticati
    ${resp}=    GET On Session    api    /api/Prodotto/${id}    headers=${headers}
    Should Be Equal               ${resp.json()}[nome]      ${nome}
    Should Be Equal As Numbers    ${resp.json()}[prezzo]    ${prezzo}

Verifica Stato Prodotto
    [Documentation]    Testo del badge nella colonna Stato (Attivo / Esaurito / Disattivo).
    [Arguments]    ${nome}    ${stato}
    Get Text    tr:has-text("${nome}") >> td.mat-column-stato    matches    ^\\s*${stato}\\s*$

Verifica Cella Prodotto
    [Documentation]    Testo esatto di una colonna nella riga del prodotto. colonna = nome | categoria | prezzo | costoProduzione
    [Arguments]    ${nome}    ${colonna}    ${atteso}
    ${testo}=    Get Text    tr:has-text("${nome}") >> td.mat-column-${colonna}
    Should Be Equal    ${testo.strip()}    ${atteso}

Verifica Placeholder Immagine
    [Documentation]    Prodotto senza immagine: icona placeholder al posto di un'immagine rotta.
    [Arguments]    ${nome}
    Wait For Elements State    tr:has-text("${nome}") >> .prodotto-thumb.placeholder    visible
    Get Element Count    tr:has-text("${nome}") >> td.mat-column-immagine img    ==    0

Verifica Form Prodotto Popolato
    [Documentation]    In modifica, i campi contengono i valori del prodotto (non solo il nome).
    [Arguments]    ${prezzo}    ${costo}    ${categoria}    ${attivo}    ${esaurito}
    ${valore_prezzo}=    Get Property    ${INPUT_PREZZO}    value
    ${valore_costo}=     Get Property    ${INPUT_COSTO}    value
    Should Be Equal As Numbers    ${valore_prezzo}    ${prezzo}
    Should Be Equal As Numbers    ${valore_costo}     ${costo}
    Get Text    mat-form-field:has-text("Categoria") .mat-mdc-select-value-text    ==    ${categoria}
    ${atteso_attivo}=      Convert To Lower Case    ${attivo}
    ${atteso_esaurito}=    Convert To Lower Case    ${esaurito}
    Get Attribute    ${SWITCH_ATTIVO}      aria-checked    ==    ${atteso_attivo}
    Get Attribute    ${SWITCH_ESAURITO}    aria-checked    ==    ${atteso_esaurito}

Verifica Nome Prodotto Via API
    [Arguments]    ${id}    ${nome}
    &{headers}=    Headers Autenticati
    ${resp}=    GET On Session    api    /api/Prodotto/${id}    headers=${headers}
    Should Be Equal    ${resp.json()}[nome]    ${nome}

Verifica Prodotto Eliminato Via API
    [Documentation]    Doppio controllo: il prodotto non esiste piu' nel backend (GET -> 404).
    [Arguments]    ${id}
    &{headers}=    Headers Autenticati
    GET On Session    api    /api/Prodotto/${id}    headers=${headers}    expected_status=404

Verifica Salva Disabilitato
    [Documentation]    Il form e' invalido: Angular disabilita Salva ([disabled]="form.invalid").
    Wait For Elements State    ${BOTTONE_SALVA}    disabled

Verifica Salva Abilitato
    [Documentation]    Il form e' valido: Salva cliccabile.
    Wait For Elements State    ${BOTTONE_SALVA}    enabled

# ---------------------------------------------------------------------
# Teardown
# ---------------------------------------------------------------------
Pulisci Dati E Chiudi Contesto
    [Documentation]    Cancella SOLO quello che e' stato davvero creato (il test puo' fallire a meta'), poi chiude il contesto del test.
    ...                PROD_ID / CAT_ID = creati via API; NOME_CREATO = prodotto creato dalla UI (id sconosciuto).
    ...                Prima i prodotti, poi la categoria: non ci affidiamo al cascade delete.
    ${prod_id}=    Get Variable Value    ${PROD_ID}
    ${prod_id_2}=  Get Variable Value    ${PROD_ID_2}
    ${cat_id}=     Get Variable Value    ${CAT_ID}
    ${cat_id_2}=   Get Variable Value    ${CAT_ID_2}
    ${nome_ui}=    Get Variable Value    ${NOME_CREATO}
    IF    $prod_id is not None
        Elimina Via API    /api/Prodotto/${prod_id}
    END
    IF    $prod_id_2 is not None
        Elimina Via API    /api/Prodotto/${prod_id_2}
    END
    IF    $nome_ui is not None
        Elimina Prodotto Per Nome Via API    ${nome_ui}
    END
    IF    $cat_id is not None
        Elimina Via API    /api/Categoria/${cat_id}
    END
    IF    $cat_id_2 is not None
        Elimina Via API    /api/Categoria/${cat_id_2}
    END
    Chiudi Contesto
