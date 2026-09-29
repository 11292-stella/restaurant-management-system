*** Settings ***
Documentation     Test E2E della sezione Categorie del gestionale.
Resource          ../resources/categorie_page.resource
Resource          ../resources/prodotti_page.resource
Suite Setup       Apri Browser
Suite Teardown    Close Browser
Test Setup        Apri Gestionale Da Loggato
Test Teardown     Chiudi Contesto


*** Test Cases ***
Dalla Dashboard Si Apre La Lista Categorie Con Il Menu Base
    [Tags]    smoke    categorie
    Vai Alla Sezione    Categorie    /categorie
    Verifica Categoria In Lista    Colazione
    Verifica Categoria In Lista    Pranzo
    Verifica Categoria In Lista    Cena

La Ricerca Trova Le Categorie Anche Per Descrizione
    [Documentation]    "pizze" non e' nel nome di nessuna categoria, solo nella descrizione di Cena.
    [Tags]    categorie    filtri
    Vai Alla Sezione    Categorie    /categorie
    Cerca Categoria    pizze
    Verifica Categoria In Lista        Cena
    Verifica Categoria Non In Lista    Colazione

Si Apre Il Form Nuova Categoria
    [Tags]    categorie
    Vai Alla Sezione    Categorie    /categorie
    Apri Form Nuova Categoria

Crea Categoria Dal Form La Mostra In Lista E Nel Backend
    [Tags]    smoke    categorie    crud
    # Arrange: dati univoci; il nome serve al teardown (id sconosciuto perche' creata dalla UI)
    ${nome}=           Genera Nome Univoco    Categoria Robot
    ${descrizione}=    FakerLibrary.Sentence    nb_words=6
    Set Test Variable    ${NOME_CAT_CREATA}    ${nome}

    # Act
    Vai Alla Sezione    Categorie    /categorie
    Apri Form Nuova Categoria
    Compila Form Categoria    ${nome}    ${descrizione}
    Salva Categoria

    # Assert
    Cerca Categoria    ${nome}
    Verifica Categoria In Lista    ${nome}
    [Teardown]    Pulisci Categorie E Chiudi Contesto

Modifica Categoria Aggiorna Lista E Backend
    [Tags]    categorie    crud
    # Arrange: categoria creata via API (mai toccare Colazione/Pranzo/Cena)
    ${nome_iniziale}=    Genera Nome Univoco    Cat Da Modificare
    ${cat_id}=           Crea Categoria Via API    ${nome_iniziale}
    Set Test Variable    ${CAT_ID}    ${cat_id}
    ${nuovo_nome}=       Genera Nome Univoco    Cat Modificata
    ${nuova_desc}=       FakerLibrary.Sentence    nb_words=6

    # Act
    Vai Alla Sezione    Categorie    /categorie
    Cerca Categoria    ${nome_iniziale}
    Apri Form Modifica Categoria    ${nome_iniziale}
    Compila Form Categoria    ${nuovo_nome}    ${nuova_desc}
    Salva Categoria

    # Assert: lista + backend
    Cerca Categoria    ${nuovo_nome}
    Verifica Categoria In Lista    ${nuovo_nome}
    Verifica Categoria Via API    ${cat_id}    ${nuovo_nome}    ${nuova_desc}
    [Teardown]    Pulisci Categorie E Chiudi Contesto

Elimina Categoria Vuota La Rimuove Da Lista E Backend
    [Tags]    categorie    crud
    # Arrange: categoria SENZA prodotti (il caso "con prodotti" e' un test a parte)
    ${nome}=      Genera Nome Univoco    Cat Da Eliminare
    ${cat_id}=    Crea Categoria Via API    ${nome}
    Set Test Variable    ${CAT_ID}    ${cat_id}

    # Act
    Vai Alla Sezione    Categorie    /categorie
    Cerca Categoria    ${nome}
    ${messaggio}=    Elimina Categoria Dalla Lista    ${nome}    accept

    # Assert
    Should Not Be Empty    ${messaggio}
    Verifica Categoria Non In Lista    ${nome}
    Verifica Categoria Eliminata Via API    ${cat_id}
    [Teardown]    Pulisci Categorie E Chiudi Contesto

Categoria Con Prodotti Non Si Puo' Eliminare
    [Documentation]    Eliminare una categoria che contiene prodotti NON deve cancellarli a cascata
    ...                (perderemmo il menu e lo storico ordini). Atteso: backend 409 Conflict, categoria e prodotti restano.
    [Tags]    categorie    crud    regressione
    # Arrange: categoria + un prodotto dentro, via API
    ${nome}=       Genera Nome Univoco    Cat Con Prodotti
    ${cat_id}=     Crea Categoria Via API    ${nome}
    Set Test Variable    ${CAT_ID}     ${cat_id}
    ${prod_id}=    Crea Prodotto Via API    Prodotto Di ${nome}    ${cat_id}
    Set Test Variable    ${PROD_ID}    ${prod_id}

    # Act: preparo l'attesa della risposta HTTP della DELETE PRIMA del click,
    # cosi' le verifiche via API partono solo quando il backend ha davvero risposto
    Vai Alla Sezione    Categorie    /categorie
    Cerca Categoria    ${nome}
    ${attesa_delete}=    Promise To    Wait For Response    matcher=**/api/Categoria/${cat_id}
    Elimina Categoria Dalla Lista    ${nome}    accept
    ${risposta}=    Wait For    ${attesa_delete}

    # Assert API: rifiutato dal backend, niente e' stato cancellato
    Should Be Equal As Integers    ${risposta}[status]    409
    Verifica Categoria Esiste Via API    ${cat_id}
    Verifica Prodotto Esiste Via API     ${prod_id}

    # Assert UI: l'utente vede il motivo e la tabella resta al suo posto
    Verifica Notifica    Impossibile eliminare la categoria
    Verifica Categoria In Lista    ${nome}
    [Teardown]    Pulisci Categorie E Chiudi Contesto

Annullando La Conferma La Categoria Non Viene Eliminata
    [Tags]    categorie    crud
    ${nome}=      Genera Nome Univoco    Cat Non Eliminare
    ${cat_id}=    Crea Categoria Via API    ${nome}
    Set Test Variable    ${CAT_ID}    ${cat_id}

    Vai Alla Sezione    Categorie    /categorie
    Cerca Categoria    ${nome}
    Elimina Categoria Dalla Lista    ${nome}    dismiss

    Verifica Categoria In Lista    ${nome}
    Verifica Categoria Esiste Via API    ${cat_id}
    [Teardown]    Pulisci Categorie E Chiudi Contesto

Azzera Ricerca Mostra Di Nuovo Tutte Le Categorie
    [Tags]    categorie    filtri
    Vai Alla Sezione    Categorie    /categorie
    Cerca Categoria    pizze
    Verifica Categoria Non In Lista    Colazione
    Azzera Ricerca Categorie
    Verifica Categoria In Lista    Colazione
    Verifica Categoria In Lista    Pranzo
    Verifica Categoria In Lista    Cena

Con Il Form Categoria Vuoto Salva E' Disabilitato
    [Tags]    categorie    validazione
    Vai Alla Sezione    Categorie    /categorie
    Apri Form Nuova Categoria
    Verifica Salva Categoria Disabilitato

Senza Nome La Categoria Non Si Puo' Salvare
    [Tags]    categorie    validazione
    ${nome}=    Genera Nome Univoco    Cat Validazione
    Vai Alla Sezione    Categorie    /categorie
    Apri Form Nuova Categoria
    Compila Form Categoria    ${nome}    Descrizione di prova
    Verifica Salva Categoria Abilitato
    Clear Text    ${INPUT_NOME_CATEGORIA}
    Verifica Salva Categoria Disabilitato

Con Nome Di Soli Spazi La Categoria Non Si Puo' Salvare
    [Documentation]    Validators.required considera valido "   " (non e' una stringa vuota):
    ...                senza un controllo in piu' si creerebbe una categoria con il nome invisibile.
    [Tags]    categorie    validazione
    Vai Alla Sezione    Categorie    /categorie
    Apri Form Nuova Categoria
    Compila Form Categoria    ${SPACE}${SPACE}${SPACE}    Descrizione di prova
    Verifica Salva Categoria Disabilitato

Categoria Senza Descrizione Si Salva E Mostra Il Trattino
    [Documentation]    La descrizione e' facoltativa nel form: la categoria deve salvarsi e la lista mostra "—".
    [Tags]    categorie    validazione    crud
    ${nome}=    Genera Nome Univoco    Cat Senza Descrizione
    Set Test Variable    ${NOME_CAT_CREATA}    ${nome}

    Vai Alla Sezione    Categorie    /categorie
    Apri Form Nuova Categoria
    Compila Form Categoria    ${nome}    ${EMPTY}
    Salva Categoria

    Cerca Categoria    ${nome}
    Verifica Categoria In Lista    ${nome}
    Verifica Descrizione Categoria    ${nome}    —
    [Teardown]    Pulisci Categorie E Chiudi Contesto

Annulla Dal Form Non Crea La Categoria
    [Tags]    categorie    validazione
    ${nome}=    Genera Nome Univoco    Cat Annullata
    # per sicurezza: se per un bug venisse creata comunque, il teardown la cancella
    Set Test Variable    ${NOME_CAT_CREATA}    ${nome}

    Vai Alla Sezione    Categorie    /categorie
    Apri Form Nuova Categoria
    Compila Form Categoria    ${nome}    Descrizione di prova
    Annulla Form Categoria

    Cerca Categoria    ${nome}
    Verifica Categoria Non In Lista    ${nome}
    [Teardown]    Pulisci Categorie E Chiudi Contesto

# ---------------------------------------------------------------------
# Nome univoco, modifica, collegamento con i prodotti, dati particolari
# ---------------------------------------------------------------------
Non Si Puo' Creare Una Categoria Con Un Nome Gia' Esistente
    [Documentation]    "colazione" (minuscolo, con spazi) esiste gia' come "Colazione": il backend risponde 409
    ...                e il form mostra il suo messaggio, senza creare un doppione.
    [Tags]    categorie    validazione
    # per sicurezza: se per un bug venisse creata comunque, il teardown la cancella (nome esatto "colazione")
    Set Test Variable    ${NOME_CAT_CREATA}    colazione

    Vai Alla Sezione    Categorie    /categorie
    Apri Form Nuova Categoria
    Compila Form Categoria    ${SPACE}colazione${SPACE}    Doppione
    Click    ${BOTTONE_SALVA_CATEGORIA}

    Verifica Errore Nel Form    Esiste gia' una categoria
    Get Url    contains    /categorie/nuovo
    ${quante}=    Conta Categorie Con Nome Via API    Colazione
    Should Be Equal As Integers    ${quante}    1
    [Teardown]    Pulisci Categorie E Chiudi Contesto

Il Form Di Modifica Contiene I Dati Della Categoria
    [Tags]    categorie    crud
    ${nome}=      Genera Nome Univoco    Cat Precompilata
    ${cat_id}=    Crea Categoria Via API    ${nome}
    Set Test Variable    ${CAT_ID}    ${cat_id}

    Vai Alla Sezione    Categorie    /categorie
    Cerca Categoria    ${nome}
    Apri Form Modifica Categoria    ${nome}

    Verifica Titolo Pagina    Modifica categoria
    Get Property    ${INPUT_DESCRIZIONE_CATEGORIA}    value    ==    Creata dai test Robot
    [Teardown]    Pulisci Categorie E Chiudi Contesto

Rinominare Una Categoria Aggiorna Anche La Lista Prodotti
    [Documentation]    Test tra due sezioni: il nuovo nome compare nella colonna Categoria e nel filtro dei prodotti.
    [Tags]    categorie    prodotti    crud
    ${nome_cat}=     Genera Nome Univoco    Cat Da Rinominare
    ${cat_id}=       Crea Categoria Via API    ${nome_cat}
    Set Test Variable    ${CAT_ID}     ${cat_id}
    ${nome_prod}=    Genera Nome Univoco    Prodotto Collegato
    ${prod_id}=      Crea Prodotto Via API    ${nome_prod}    ${cat_id}
    Set Test Variable    ${PROD_ID}    ${prod_id}
    ${nuovo_nome}=   Genera Nome Univoco    Cat Rinominata

    Vai Alla Sezione    Categorie    /categorie
    Cerca Categoria    ${nome_cat}
    Apri Form Modifica Categoria    ${nome_cat}
    Compila Form Categoria    ${nuovo_nome}    Rinominata dai test Robot
    Salva Categoria

    Vai Alla Pagina    /prodotti
    Cerca Prodotto    ${nome_prod}
    Verifica Cella Prodotto    ${nome_prod}    categoria    ${nuovo_nome}
    Filtra Per Categoria    ${nuovo_nome}
    Verifica Prodotto In Lista    ${nome_prod}
    [Teardown]    Pulisci Categorie E Chiudi Contesto

Una Nuova Categoria E' Subito Disponibile Nel Form Prodotto
    [Tags]    categorie    prodotti
    ${nome}=      Genera Nome Univoco    Cat Per Form
    ${cat_id}=    Crea Categoria Via API    ${nome}
    Set Test Variable    ${CAT_ID}    ${cat_id}

    Vai Alla Pagina    /prodotti/nuovo
    Seleziona Da Dropdown    Categoria    ${nome}
    Get Text    mat-form-field:has-text("Categoria") .mat-mdc-select-value-text    ==    ${nome}
    [Teardown]    Pulisci Categorie E Chiudi Contesto

Una Categoria Inesistente Mostra Categoria Non Trovata
    [Tags]    categorie
    Vai Alla Pagina    /categorie/999999
    Verifica Errore Nel Form    Categoria non trovata.

Un Nome Categoria Con Accenti E HTML Viene Mostrato Come Testo
    [Documentation]    Caratteri speciali salvati identici e tag HTML mostrati come testo (niente XSS).
    [Tags]    categorie    sicurezza
    ${nome}=      Genera Nome Univoco    Caffè & <b>Dolci</b> àèìòù
    ${cat_id}=    Crea Categoria Via API    ${nome}
    Set Test Variable    ${CAT_ID}    ${cat_id}

    Vai Alla Sezione    Categorie    /categorie
    Cerca Categoria    ${nome}
    ${testo}=    Get Text    tr:has-text("${nome}") >> td.mat-column-nome
    Should Be Equal    ${testo.strip()}    ${nome}
    Get Element Count    tr:has-text("${nome}") >> td.mat-column-nome b    ==    0
    [Teardown]    Pulisci Categorie E Chiudi Contesto


# =====================================================================
# COME LANCIARE (dalla cartella robot-tests)
#   robot --outputdir results --suite Categorie tests
#   robot --outputdir results --include categorie tests
# =====================================================================