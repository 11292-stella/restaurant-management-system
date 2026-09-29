*** Settings ***
Documentation    Keyword e selettori della sezione Categorie (lista + form crea/modifica).
Resource         common.resource


*** Variables ***
# Lista
${INPUT_CERCA_CATEGORIA}         role=textbox[name="Cerca categoria"]
${BOTTONE_NUOVA_CATEGORIA}       role=button[name="Nuova categoria"]
${BOTTONE_MODIFICA_CATEGORIA}    button[mattooltip="Modifica"]
${BOTTONE_ELIMINA_CATEGORIA}     button[mattooltip="Elimina"]

# Form categoria 
${INPUT_NOME_CATEGORIA}          role=textbox[name="Nome"]
${INPUT_DESCRIZIONE_CATEGORIA}   role=textbox[name="Descrizione"]
${BOTTONE_SALVA_CATEGORIA}       role=button[name="Salva"]
${BOTTONE_ANNULLA_CATEGORIA}     role=button[name="Annulla"]
${BOTTONE_AZZERA_RICERCA}        button[mattooltip="Azzera ricerca"]


*** Keywords ***
# ---------------------------------------------------------------------
# Azioni - lista
# ---------------------------------------------------------------------
Cerca Categoria
    [Documentation]    Scrive nella barra di ricerca (cerca su nome E descrizione).
    [Arguments]    ${testo}
    Fill Text    ${INPUT_CERCA_CATEGORIA}    ${testo}

Azzera Ricerca Categorie
    [Documentation]    Clicca il bottone "Azzera ricerca" (compare solo se c'e' del testo nella ricerca).
    Click    ${BOTTONE_AZZERA_RICERCA}

Apri Form Nuova Categoria
    Click      ${BOTTONE_NUOVA_CATEGORIA}
    Get Url    contains    /categorie/nuovo

Apri Form Modifica Categoria
    [Documentation]    Matita nella riga della categoria + attesa che il form sia popolato (caricamento asincrono, come per i prodotti).
    [Arguments]    ${nome}
    Click      tr:has-text("${nome}") >> ${BOTTONE_MODIFICA_CATEGORIA}
    Get Url    matches    .*/categorie/\\d+$
    Get Property    ${INPUT_NOME_CATEGORIA}    value    ==    ${nome}

Elimina Categoria Dalla Lista
    [Documentation]    Cestino + risposta al confirm() nativo (accept = OK, dismiss = Annulla). Ritorna il testo del confirm.
    [Arguments]    ${nome}    ${azione}=accept
    ${promessa}=     Promise To    Wait For Alert    action=${azione}
    Click            tr:has-text("${nome}") >> ${BOTTONE_ELIMINA_CATEGORIA}
    ${messaggio}=    Wait For    ${promessa}
    Log    Testo del confirm: ${messaggio}
    RETURN    ${messaggio}

# ---------------------------------------------------------------------
# Azioni - form
# ---------------------------------------------------------------------
Compila Form Categoria
    [Arguments]    ${nome}    ${descrizione}
    Fill Text    ${INPUT_NOME_CATEGORIA}           ${nome}
    Fill Text    ${INPUT_DESCRIZIONE_CATEGORIA}    ${descrizione}

Salva Categoria
    [Documentation]    Salva e verifica il ritorno alla lista (vale per crea e modifica).
    Click      ${BOTTONE_SALVA_CATEGORIA}
    Get Url    matches    .*/categorie$

Annulla Form Categoria
    [Documentation]    Annulla e verifica il ritorno alla lista senza salvare.
    Click      ${BOTTONE_ANNULLA_CATEGORIA}
    Get Url    matches    .*/categorie$

# ---------------------------------------------------------------------
# Verifiche
# ---------------------------------------------------------------------
Verifica Categoria In Lista
    [Arguments]    ${nome}
    Wait For Elements State    tr:has-text("${nome}")    visible

Verifica Categoria Non In Lista
    [Arguments]    ${nome}
    Wait For Elements State    tr:has-text("${nome}")    hidden

Verifica Categoria Via API
    [Documentation]    Doppio controllo nel backend: nome e descrizione salvati davvero.
    [Arguments]    ${id}    ${nome}    ${descrizione}
    &{headers}=    Headers Autenticati
    ${resp}=    GET On Session    api    /api/Categoria/${id}    headers=${headers}
    Should Be Equal    ${resp.json()}[nome]           ${nome}
    Should Be Equal    ${resp.json()}[descrizione]    ${descrizione}

Verifica Categoria Eliminata Via API
    [Arguments]    ${id}
    &{headers}=    Headers Autenticati
    GET On Session    api    /api/Categoria/${id}    headers=${headers}    expected_status=404

Verifica Categoria Esiste Via API
    [Arguments]    ${id}
    &{headers}=    Headers Autenticati
    GET On Session    api    /api/Categoria/${id}    headers=${headers}    expected_status=200

Verifica Prodotto Esiste Via API
    [Arguments]    ${id}
    &{headers}=    Headers Autenticati
    GET On Session    api    /api/Prodotto/${id}    headers=${headers}    expected_status=200

Verifica Salva Categoria Disabilitato
    Wait For Elements State    ${BOTTONE_SALVA_CATEGORIA}    disabled

Verifica Salva Categoria Abilitato
    Wait For Elements State    ${BOTTONE_SALVA_CATEGORIA}    enabled

Verifica Descrizione Categoria
    [Documentation]    Controlla il testo della colonna Descrizione nella riga della categoria.
    [Arguments]    ${nome}    ${descrizione_attesa}
    Get Text    tr:has-text("${nome}") >> td.mat-column-descrizione    ==    ${descrizione_attesa}

# ---------------------------------------------------------------------
# Dati e teardown
# ---------------------------------------------------------------------
Elimina Categoria Per Nome Via API
    [Documentation]    Per le categorie create dalla UI (id sconosciuto). Se non la trova non fa nulla.
    [Arguments]    ${nome}
    &{headers}=    Headers Autenticati
    ${resp}=    GET On Session    api    /api/Categoria    headers=${headers}
    FOR    ${c}    IN    @{resp.json()}
        IF    $c['nome'] == $nome
            Elimina Via API    /api/Categoria/${c}[id]
        END
    END

Pulisci Categorie E Chiudi Contesto
    [Documentation]    Cancella SOLO quello che e' stato creato: PROD_ID, CAT_ID (via API) e/o NOME_CAT_CREATA (dalla UI).
    ...                Prima il prodotto, poi la categoria: non ci affidiamo al cascade.
    ${prod_id}=    Get Variable Value    ${PROD_ID}
    ${cat_id}=     Get Variable Value    ${CAT_ID}
    ${nome_ui}=    Get Variable Value    ${NOME_CAT_CREATA}
    IF    $prod_id is not None
        Elimina Via API    /api/Prodotto/${prod_id}
    END
    IF    $cat_id is not None
        Elimina Via API    /api/Categoria/${cat_id}
    END
    IF    $nome_ui is not None
        Elimina Categoria Per Nome Via API    ${nome_ui}
    END
    Chiudi Contesto