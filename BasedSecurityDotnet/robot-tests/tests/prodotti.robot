*** Settings ***
Documentation     Test E2E della sezione Prodotti del gestionale.
Resource          ../resources/prodotti_page.resource
Suite Setup       Apri Browser
Suite Teardown    Close Browser
Test Setup        Apri Gestionale Da Loggato
Test Teardown     Chiudi Contesto


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

Filtro Per Stato Esaurito Mostra Solo I Prodotti Esauriti
    [Tags]    prodotti    filtri
    # Arrange: nel menu seedato nessun prodotto e' esaurito -> ne creo uno via API.
    # Ogni Set Test Variable subito dopo la sua creazione: se il test fallisce a meta', il teardown pulisce quello che esiste.
    ${nome_cat}=    Genera Nome Univoco    Cat Robot
    ${cat_id}=      Crea Categoria Via API    ${nome_cat}
    Set Test Variable    ${CAT_ID}     ${cat_id}
    ${nome}=        Genera Nome Univoco    Esaurito Robot
    ${prod_id}=     Crea Prodotto Via API    ${nome}    ${cat_id}    esaurito=${True}
    Set Test Variable    ${PROD_ID}    ${prod_id}

    # Act
    Vai Alla Sezione    Prodotti    /prodotti
    Filtra Per Stato    Esaurito

    # Assert: il prodotto esaurito c'e', uno del menu (non esaurito) no
    Verifica Prodotto In Lista        ${nome}
    Verifica Prodotto Non In Lista    Cornetto vuoto
    [Teardown]    Pulisci Dati E Chiudi Contesto

Si Apre Il Form Nuovo Prodotto
    [Tags]    prodotti
    Vai Alla Sezione    Prodotti    /prodotti
    Apri Form Nuovo Prodotto

Crea Prodotto Dal Form Lo Mostra In Lista
    [Documentation]    Crea un prodotto realistico e casuale dal form.
    ...                Di default viene cancellato a fine test; con --variable MANTIENI_DATI:True resta nel DB.
    [Tags]    smoke    prodotti    crud
    # Arrange: dati casuali dal catalogo. Se NON va mantenuto, salvo il nome per il teardown.
    &{prodotto}=    Genera Dati Prodotto
    IF    not ${MANTIENI_DATI}
        Set Test Variable    ${NOME_CREATO}    ${prodotto}[nome]
    END

    # Act
    Vai Alla Sezione    Prodotti    /prodotti
    Apri Form Nuovo Prodotto
    Compila Form Prodotto    ${prodotto}
    Salva Prodotto

    # Assert: cerco per nome (la lista ha 27+ prodotti, il nuovo potrebbe essere in fondo)
    Cerca Prodotto    ${prodotto}[nome]
    Verifica Prodotto In Lista    ${prodotto}[nome]
    [Teardown]    Pulisci Dati E Chiudi Contesto

Modifica Prodotto Aggiorna I Dati In Lista E Nel Backend
    [Tags]    prodotti    crud
    # Arrange: prodotto da modificare creato via API (mai toccare il menu seedato)
    ${nome_cat}=         Genera Nome Univoco    Cat Robot
    ${cat_id}=           Crea Categoria Via API    ${nome_cat}
    Set Test Variable    ${CAT_ID}     ${cat_id}
    ${nome_iniziale}=    Genera Nome Univoco    Da Modificare Robot
    ${prod_id}=          Crea Prodotto Via API    ${nome_iniziale}    ${cat_id}
    Set Test Variable    ${PROD_ID}    ${prod_id}
    &{nuovi_dati}=       Genera Dati Prodotto

    # Act
    Vai Alla Sezione    Prodotti    /prodotti
    Cerca Prodotto    ${nome_iniziale}
    Apri Form Modifica Prodotto    ${nome_iniziale}
    Compila Form Prodotto    ${nuovi_dati}
    Salva Prodotto

    # Assert: il nome nuovo c'e', il vecchio no, e il backend ha salvato i dati giusti
    Cerca Prodotto    ${nuovi_dati}[nome]
    Verifica Prodotto In Lista        ${nuovi_dati}[nome]
    Cerca Prodotto    ${nome_iniziale}
    Verifica Prodotto Non In Lista    ${nome_iniziale}
    Verifica Prodotto Via API    ${prod_id}    ${nuovi_dati}[nome]    ${nuovi_dati}[prezzo]
    [Teardown]    Pulisci Dati E Chiudi Contesto

Elimina Prodotto Lo Rimuove Dalla Lista E Dal Backend
    [Tags]    prodotti    crud
    # Arrange: prodotto usa-e-getta creato via API (mai eliminare il menu seedato)
    ${nome_cat}=    Genera Nome Univoco    Cat Robot
    ${cat_id}=      Crea Categoria Via API    ${nome_cat}
    Set Test Variable    ${CAT_ID}     ${cat_id}
    ${nome}=        Genera Nome Univoco    Da Eliminare Robot
    ${prod_id}=     Crea Prodotto Via API    ${nome}    ${cat_id}
    Set Test Variable    ${PROD_ID}    ${prod_id}

    # Act: cestino + OK sul confirm
    Vai Alla Sezione    Prodotti    /prodotti
    Cerca Prodotto    ${nome}
    ${messaggio}=    Elimina Prodotto Dalla Lista    ${nome}    accept

    # Assert: il confirm e' stato chiesto, il prodotto sparisce dalla lista e dal backend
    Should Not Be Empty    ${messaggio}
    Verifica Prodotto Non In Lista    ${nome}
    Verifica Prodotto Eliminato Via API    ${prod_id}
    [Teardown]    Pulisci Dati E Chiudi Contesto

Annullando La Conferma Il Prodotto Non Viene Eliminato
    [Tags]    prodotti    crud
    # Arrange
    ${nome_cat}=    Genera Nome Univoco    Cat Robot
    ${cat_id}=      Crea Categoria Via API    ${nome_cat}
    Set Test Variable    ${CAT_ID}     ${cat_id}
    ${nome}=        Genera Nome Univoco    Non Eliminare Robot
    ${prod_id}=     Crea Prodotto Via API    ${nome}    ${cat_id}
    Set Test Variable    ${PROD_ID}    ${prod_id}

    # Act: cestino + Annulla sul confirm
    Vai Alla Sezione    Prodotti    /prodotti
    Cerca Prodotto    ${nome}
    Elimina Prodotto Dalla Lista    ${nome}    dismiss

    # Assert: il prodotto e' ancora in lista e nel backend
    Verifica Prodotto In Lista    ${nome}
    Verifica Prodotto Via API    ${prod_id}    ${nome}    5.5
    [Teardown]    Pulisci Dati E Chiudi Contesto

Con Il Form Vuoto Salva E' Disabilitato
    [Tags]    prodotti    validazione
    Vai Alla Sezione    Prodotti    /prodotti
    Apri Form Nuovo Prodotto
    Verifica Salva Disabilitato

Senza Nome Il Prodotto Non Si Puo' Salvare
    [Tags]    prodotti    validazione
    &{prodotto}=    Genera Dati Prodotto
    Vai Alla Sezione    Prodotti    /prodotti
    Apri Form Nuovo Prodotto
    Compila Form Prodotto    ${prodotto}
    # controllo di partenza: con tutti i dati validi Salva e' attivo
    # (cosi' se poi si disabilita, e' proprio per il nome vuoto)
    Verifica Salva Abilitato
    Clear Text    ${INPUT_NOME}
    Verifica Salva Disabilitato

Con Prezzo Negativo Il Prodotto Non Si Puo' Salvare
    [Tags]    prodotti    validazione
    &{prodotto}=    Genera Dati Prodotto
    Vai Alla Sezione    Prodotti    /prodotti
    Apri Form Nuovo Prodotto
    Compila Form Prodotto    ${prodotto}
    Verifica Salva Abilitato
    Fill Text    ${INPUT_PREZZO}    -5
    Verifica Salva Disabilitato

Annulla Dal Form Non Crea Il Prodotto
    [Tags]    prodotti    validazione
    &{prodotto}=    Genera Dati Prodotto
    # per sicurezza: se per un bug venisse creato comunque, il teardown lo cancella
    Set Test Variable    ${NOME_CREATO}    ${prodotto}[nome]
    Vai Alla Sezione    Prodotti    /prodotti
    Apri Form Nuovo Prodotto
    Compila Form Prodotto    ${prodotto}
    Annulla Form Prodotto
    Cerca Prodotto    ${prodotto}[nome]
    Verifica Prodotto Non In Lista    ${prodotto}[nome]
    [Teardown]    Pulisci Dati E Chiudi Contesto

Con Nome Di Soli Spazi Il Prodotto Non Si Puo' Salvare
    [Documentation]    Validators.required considera valido "   " (non e' una stringa vuota):
    ...                senza un controllo in piu' si creerebbe un prodotto con il nome invisibile.
    [Tags]    prodotti    validazione
    &{prodotto}=    Genera Dati Prodotto
    Vai Alla Sezione    Prodotti    /prodotti
    Apri Form Nuovo Prodotto
    Compila Form Prodotto    ${prodotto}
    # controllo di partenza: con dati validi Salva e' attivo
    Verifica Salva Abilitato
    Fill Text    ${INPUT_NOME}    ${SPACE}${SPACE}${SPACE}
    Verifica Salva Disabilitato

# ---------------------------------------------------------------------
# Lista: filtri, stati, formati
# ---------------------------------------------------------------------
Filtro Stato Disattivo Mostra Solo I Prodotti Disattivati
    [Tags]    prodotti    filtri
    ${nome_cat}=    Genera Nome Univoco    Cat Robot
    ${cat_id}=      Crea Categoria Via API    ${nome_cat}
    Set Test Variable    ${CAT_ID}     ${cat_id}
    ${nome}=        Genera Nome Univoco    Disattivo Robot
    ${prod_id}=     Crea Prodotto Via API    ${nome}    ${cat_id}    attivo=${False}
    Set Test Variable    ${PROD_ID}    ${prod_id}

    Vai Alla Sezione    Prodotti    /prodotti
    Filtra Per Stato    Disattivo

    Verifica Prodotto In Lista        ${nome}
    Verifica Prodotto Non In Lista    Cornetto vuoto
    [Teardown]    Pulisci Dati E Chiudi Contesto

Filtro Stato Attivo Esclude I Prodotti Esauriti
    [Documentation]    Da codice "attivo" = attivo E non esaurito: un esaurito non deve comparire tra gli attivi.
    [Tags]    prodotti    filtri
    ${nome_cat}=    Genera Nome Univoco    Cat Robot
    ${cat_id}=      Crea Categoria Via API    ${nome_cat}
    Set Test Variable    ${CAT_ID}     ${cat_id}
    ${nome}=        Genera Nome Univoco    Esaurito Robot
    ${prod_id}=     Crea Prodotto Via API    ${nome}    ${cat_id}    esaurito=${True}
    Set Test Variable    ${PROD_ID}    ${prod_id}

    Vai Alla Sezione    Prodotti    /prodotti
    Filtra Per Stato    Attivo

    Verifica Prodotto In Lista        Cornetto vuoto
    Verifica Prodotto Non In Lista    ${nome}
    [Teardown]    Pulisci Dati E Chiudi Contesto

Filtri Combinati Categoria Stato E Ricerca
    [Documentation]    Categoria + stato insieme; poi una ricerca che non trova nulla mostra il messaggio "nessun prodotto".
    [Tags]    prodotti    filtri
    ${nome_cat}=     Genera Nome Univoco    Cat Filtri
    ${cat_id}=       Crea Categoria Via API    ${nome_cat}
    Set Test Variable    ${CAT_ID}       ${cat_id}
    ${attivo}=       Genera Nome Univoco    Filtro Attivo
    ${prod_1}=       Crea Prodotto Via API    ${attivo}    ${cat_id}
    Set Test Variable    ${PROD_ID}      ${prod_1}
    ${esaurito}=     Genera Nome Univoco    Filtro Esaurito
    ${prod_2}=       Crea Prodotto Via API    ${esaurito}    ${cat_id}    esaurito=${True}
    Set Test Variable    ${PROD_ID_2}    ${prod_2}

    Vai Alla Sezione    Prodotti    /prodotti
    Filtra Per Categoria    ${nome_cat}
    Filtra Per Stato    Esaurito
    Verifica Prodotto In Lista        ${esaurito}
    Verifica Prodotto Non In Lista    ${attivo}
    Verifica Prodotto Non In Lista    Cornetto vuoto

    # l'esaurito non contiene la parola "Attivo": con la ricerca non resta nessun prodotto
    Cerca Prodotto    ${attivo}
    Wait For Elements State    ${MSG_NESSUN_PRODOTTO}    visible
    [Teardown]    Pulisci Dati E Chiudi Contesto

Azzera Filtri Mostra Di Nuovo Tutti I Prodotti
    [Tags]    prodotti    filtri
    Vai Alla Sezione    Prodotti    /prodotti
    # senza filtri il bottone non c'e'
    Wait For Elements State    ${BOTTONE_AZZERA_FILTRI}    detached
    Filtra Per Categoria    Cena
    Verifica Prodotto Non In Lista    Cornetto vuoto
    Azzera Filtri Prodotti
    Verifica Prodotto In Lista    Cornetto vuoto
    Verifica Prodotto In Lista    Pizza Margherita
    Wait For Elements State    ${BOTTONE_AZZERA_FILTRI}    detached

Prodotto Disattivo Ed Esaurito Mostra Il Badge Disattivo
    [Documentation]    Priorita' dei badge: se non e' attivo conta "Disattivo", anche se e' anche esaurito.
    [Tags]    prodotti
    ${nome_cat}=    Genera Nome Univoco    Cat Robot
    ${cat_id}=      Crea Categoria Via API    ${nome_cat}
    Set Test Variable    ${CAT_ID}     ${cat_id}
    ${nome}=        Genera Nome Univoco    Badge Robot
    ${prod_id}=     Crea Prodotto Via API    ${nome}    ${cat_id}    attivo=${False}    esaurito=${True}
    Set Test Variable    ${PROD_ID}    ${prod_id}

    Vai Alla Sezione    Prodotti    /prodotti
    Cerca Prodotto    ${nome}
    Verifica Stato Prodotto    ${nome}    Disattivo
    [Teardown]    Pulisci Dati E Chiudi Contesto

Prezzi Formattati In Euro Con Due Decimali
    [Tags]    prodotti
    ${nome_cat}=    Genera Nome Univoco    Cat Robot
    ${cat_id}=      Crea Categoria Via API    ${nome_cat}
    Set Test Variable    ${CAT_ID}     ${cat_id}
    ${nome}=        Genera Nome Univoco    Prezzo Robot
    ${prod_id}=     Crea Prodotto Via API    ${nome}    ${cat_id}    prezzo=${5.5}    costo=${2}
    Set Test Variable    ${PROD_ID}    ${prod_id}

    Vai Alla Sezione    Prodotti    /prodotti
    Cerca Prodotto    ${nome}
    Verifica Cella Prodotto    ${nome}    prezzo             €5.50
    Verifica Cella Prodotto    ${nome}    costoProduzione    €2.00
    Verifica Cella Prodotto    ${nome}    categoria          ${nome_cat}
    [Teardown]    Pulisci Dati E Chiudi Contesto

Prodotto Senza Immagine Mostra Il Placeholder
    [Tags]    prodotti
    ${nome_cat}=    Genera Nome Univoco    Cat Robot
    ${cat_id}=      Crea Categoria Via API    ${nome_cat}
    Set Test Variable    ${CAT_ID}     ${cat_id}
    ${nome}=        Genera Nome Univoco    Senza Foto Robot
    ${prod_id}=     Crea Prodotto Via API    ${nome}    ${cat_id}    immagine_url=${None}
    Set Test Variable    ${PROD_ID}    ${prod_id}

    Vai Alla Sezione    Prodotti    /prodotti
    Cerca Prodotto    ${nome}
    Verifica Placeholder Immagine    ${nome}
    [Teardown]    Pulisci Dati E Chiudi Contesto

# ---------------------------------------------------------------------
# Form: modifica, casi limite, errori
# ---------------------------------------------------------------------
Il Form Di Modifica Contiene Tutti I Dati Del Prodotto
    [Tags]    prodotti    crud
    ${nome_cat}=    Genera Nome Univoco    Cat Robot
    ${cat_id}=      Crea Categoria Via API    ${nome_cat}
    Set Test Variable    ${CAT_ID}     ${cat_id}
    ${nome}=        Genera Nome Univoco    Precompilato Robot
    ${prod_id}=     Crea Prodotto Via API    ${nome}    ${cat_id}    esaurito=${True}    prezzo=${7.25}    costo=${3.1}
    Set Test Variable    ${PROD_ID}    ${prod_id}

    Vai Alla Sezione    Prodotti    /prodotti
    Cerca Prodotto    ${nome}
    Apri Form Modifica Prodotto    ${nome}

    Verifica Titolo Pagina    Modifica prodotto
    Verifica Form Prodotto Popolato    7.25    3.1    ${nome_cat}    True    True
    [Teardown]    Pulisci Dati E Chiudi Contesto

Cambiare Categoria In Modifica Aggiorna La Lista
    [Tags]    prodotti    crud
    ${cat_1}=       Genera Nome Univoco    Cat Partenza
    ${cat_id}=      Crea Categoria Via API    ${cat_1}
    Set Test Variable    ${CAT_ID}      ${cat_id}
    ${cat_2}=       Genera Nome Univoco    Cat Arrivo
    ${cat_id_2}=    Crea Categoria Via API    ${cat_2}
    Set Test Variable    ${CAT_ID_2}    ${cat_id_2}
    ${nome}=        Genera Nome Univoco    Sposta Robot
    ${prod_id}=     Crea Prodotto Via API    ${nome}    ${cat_id}
    Set Test Variable    ${PROD_ID}     ${prod_id}

    Vai Alla Sezione    Prodotti    /prodotti
    Cerca Prodotto    ${nome}
    Apri Form Modifica Prodotto    ${nome}
    Seleziona Da Dropdown    Categoria    ${cat_2}
    Salva Prodotto

    Cerca Prodotto    ${nome}
    Verifica Cella Prodotto    ${nome}    categoria    ${cat_2}
    [Teardown]    Pulisci Dati E Chiudi Contesto

Annulla In Modifica Non Salva Le Modifiche
    [Tags]    prodotti    crud
    ${nome_cat}=    Genera Nome Univoco    Cat Robot
    ${cat_id}=      Crea Categoria Via API    ${nome_cat}
    Set Test Variable    ${CAT_ID}     ${cat_id}
    ${nome}=        Genera Nome Univoco    Non Modificare Robot
    ${prod_id}=     Crea Prodotto Via API    ${nome}    ${cat_id}
    Set Test Variable    ${PROD_ID}    ${prod_id}

    Vai Alla Sezione    Prodotti    /prodotti
    Cerca Prodotto    ${nome}
    Apri Form Modifica Prodotto    ${nome}
    Fill Text    ${INPUT_NOME}    Nome che non deve essere salvato
    Annulla Form Prodotto

    Verifica Nome Prodotto Via API    ${prod_id}    ${nome}
    [Teardown]    Pulisci Dati E Chiudi Contesto

Prodotto Senza Descrizione Si Salva
    [Documentation]    La descrizione e' facoltativa nel form: prima il backend ([Required] nel DTO) rispondeva 400.
    [Tags]    prodotti    validazione    crud
    &{prodotto}=    Genera Dati Prodotto
    Set Test Variable    ${NOME_CREATO}    ${prodotto}[nome]

    Vai Alla Sezione    Prodotti    /prodotti
    Apri Form Nuovo Prodotto
    Compila Form Prodotto    ${prodotto}
    Clear Text    ${INPUT_DESCRIZIONE}
    Salva Prodotto

    Cerca Prodotto    ${prodotto}[nome]
    Verifica Prodotto In Lista    ${prodotto}[nome]
    [Teardown]    Pulisci Dati E Chiudi Contesto

Con Prezzo Zero Il Prodotto Non Si Puo' Salvare
    [Documentation]    Il backend richiede prezzo >= 0.01: prima il form accettava 0 e il salvataggio falliva con 400.
    [Tags]    prodotti    validazione
    &{prodotto}=    Genera Dati Prodotto
    Vai Alla Sezione    Prodotti    /prodotti
    Apri Form Nuovo Prodotto
    Compila Form Prodotto    ${prodotto}
    Verifica Salva Abilitato
    Fill Text    ${INPUT_PREZZO}    0
    Verifica Salva Disabilitato

Doppio Click Su Salva Crea Un Solo Prodotto
    [Documentation]    Classico bug dei form: se Salva resta attivo durante la richiesta, un doppio click invia due POST.
    [Tags]    prodotti    validazione    crud
    &{prodotto}=    Genera Dati Prodotto
    Set Test Variable    ${NOME_CREATO}    ${prodotto}[nome]

    Vai Alla Sezione    Prodotti    /prodotti
    Apri Form Nuovo Prodotto
    Compila Form Prodotto    ${prodotto}
    Click With Options    ${BOTTONE_SALVA}    clickCount=2
    Get Url    matches    .*/prodotti$
    # aspetto che anche un'eventuale seconda richiesta sia terminata prima di contare
    Wait For Load State    networkidle

    ${quanti}=    Conta Prodotti Con Nome Via API    ${prodotto}[nome]
    Should Be Equal As Integers    ${quanti}    1
    [Teardown]    Pulisci Dati E Chiudi Contesto

Un Prodotto Inesistente Mostra Prodotto Non Trovato
    [Tags]    prodotti
    Vai Alla Pagina    /prodotti/999999
    Verifica Errore Nel Form    Prodotto non trovato.

# ---------------------------------------------------------------------
# Dati particolari
# ---------------------------------------------------------------------
Nome Con Accenti E Simboli Viene Salvato Identico
    [Tags]    prodotti    crud
    &{prodotto}=    Genera Dati Prodotto
    ${nome}=        Genera Nome Univoco    Caffè & Cornetto àèìòù €
    Set Test Variable    ${NOME_CREATO}    ${nome}

    Vai Alla Sezione    Prodotti    /prodotti
    Apri Form Nuovo Prodotto
    Compila Form Prodotto    ${prodotto}
    Fill Text    ${INPUT_NOME}    ${nome}
    Salva Prodotto

    Cerca Prodotto    ${nome}
    Verifica Cella Prodotto    ${nome}    nome    ${nome}
    ${quanti}=    Conta Prodotti Con Nome Via API    ${nome}
    Should Be Equal As Integers    ${quanti}    1
    [Teardown]    Pulisci Dati E Chiudi Contesto

Un Nome Con HTML Viene Mostrato Come Testo
    [Documentation]    Sicurezza (XSS): tag HTML nel nome devono apparire come testo, non essere interpretati.
    [Tags]    prodotti    sicurezza
    ${nome_cat}=    Genera Nome Univoco    Cat Robot
    ${cat_id}=      Crea Categoria Via API    ${nome_cat}
    Set Test Variable    ${CAT_ID}     ${cat_id}
    ${nome}=        Genera Nome Univoco    <b>Grassetto</b><img src=x onerror=alert(1)>
    ${prod_id}=     Crea Prodotto Via API    ${nome}    ${cat_id}
    Set Test Variable    ${PROD_ID}    ${prod_id}

    Vai Alla Sezione    Prodotti    /prodotti
    Cerca Prodotto    ${nome}
    # il testo visibile e' la stringa grezza, tag compresi
    Verifica Cella Prodotto    ${nome}    nome    ${nome}
    # e nella cella non e' stato creato nessun elemento <b> o <img>
    Get Element Count    tr:has-text("${nome}") >> td.mat-column-nome b      ==    0
    Get Element Count    tr:has-text("${nome}") >> td.mat-column-nome img    ==    0
    [Teardown]    Pulisci Dati E Chiudi Contesto


# =====================================================================
# COME LANCIARE I TEST PRODOTTI (dalla cartella robot-tests)
#
#   robot --outputdir results --suite Prodotti tests
#       -> tutti i test prodotti, DB lasciato pulito (i prodotti creati vengono cancellati)
#
#   robot --outputdir results --suite Prodotti --variable MANTIENI_DATI:True tests
#       -> tutti i test prodotti, il prodotto creato dal form RESTA nel DB
#
#   robot --outputdir results --test "Crea Prodotto*" --variable MANTIENI_DATI:True tests
#       -> solo il test di creazione, il prodotto resta nel DB
#          (lanciarlo piu' volte per popolare il DB con prodotti realistici)
#
#   I prodotti mantenuti restano finche' non si fa "docker compose down -v".
# =====================================================================