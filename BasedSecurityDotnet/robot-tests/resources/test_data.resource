*** Settings ***
Documentation    Generatori di dati di test (data factory), come il file Faker del progetto Playwright.
Library          FakerLibrary    locale=it_IT


*** Variables ***
# Catalogo di piatti realistici: nome, categoria, descrizione e foto coerenti tra loro.
# NB: evitare nomi che contengono testi cercati da altri test (es. "Cappuccino", "Cornetto vuoto").
&{PANCAKES}      nome=Pancakes ai frutti di bosco    categoria=Colazione    descrizione=Pancakes soffici con frutti di bosco e sciroppo d'acero       immagine=https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=500
&{BRIOCHE}       nome=Brioche integrale al miele     categoria=Colazione    descrizione=Brioche sfogliata integrale con miele di acacia               immagine=https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=500
&{TOAST}         nome=Avocado toast                  categoria=Colazione    descrizione=Pane tostato, avocado, uovo in camicia e semi di sesamo       immagine=https://images.unsplash.com/photo-1484723091739-30a097e8f929?w=500
&{TAGLIATELLE}   nome=Tagliatelle al ragu            categoria=Pranzo       descrizione=Tagliatelle all'uovo con ragu di manzo cotto 4 ore            immagine=https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=500
&{CHICKEN}       nome=Chicken burger                 categoria=Pranzo       descrizione=Pollo croccante, insalata, pomodoro e salsa yogurt            immagine=https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500
&{GRECA}         nome=Insalata greca                 categoria=Pranzo       descrizione=Pomodori, cetrioli, feta, olive nere e cipolla rossa          immagine=https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500
&{BUFALA}        nome=Pizza bufala e pomodorini      categoria=Cena         descrizione=Mozzarella di bufala, pomodorini freschi e basilico           immagine=https://images.unsplash.com/photo-1604382354936-07c5d9983bd3?w=500
&{TONNO}         nome=Pizza tonno e cipolla          categoria=Cena         descrizione=Pomodoro, mozzarella, tonno e cipolla di Tropea               immagine=https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=500
&{CALZONE}       nome=Calzone farcito                categoria=Cena         descrizione=Calzone con prosciutto cotto, ricotta e mozzarella            immagine=https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500

@{CATALOGO}      ${PANCAKES}    ${BRIOCHE}    ${TOAST}    ${TAGLIATELLE}    ${CHICKEN}    ${GRECA}    ${BUFALA}    ${TONNO}    ${CALZONE}


*** Keywords ***
Genera Nome Univoco
    [Documentation]    Prefisso + 8 caratteri casuali (come Guid.NewGuid() nei test API).
    [Arguments]    ${prefisso}
    ${suffisso}=    Evaluate    uuid.uuid4().hex[:8]    modules=uuid
    RETURN    ${prefisso} ${suffisso}

Genera Dati Prodotto
    [Documentation]    Prodotto realistico e casuale: piatto dal catalogo (con la sua categoria e foto),
    ...                prezzo/costo casuali coerenti, stato casuale (80% attivo, 20% esaurito).
    ${piatto}=      FakerLibrary.Random Element    elements=${CATALOGO}
    ${nome}=        Genera Nome Univoco    ${piatto}[nome]
    ${prezzo}=      Evaluate    round(random.uniform(4, 18), 2)    modules=random
    ${costo}=       Evaluate    round(${prezzo} * random.uniform(0.15, 0.40), 2)    modules=random
    ${attivo}=      FakerLibrary.Boolean    chance_of_getting_true=80
    ${esaurito}=    FakerLibrary.Boolean    chance_of_getting_true=20
    &{prodotto}=    Create Dictionary
    ...    nome=${nome}    descrizione=${piatto}[descrizione]    categoria=${piatto}[categoria]
    ...    immagine=${piatto}[immagine]    prezzo=${prezzo}    costo=${costo}
    ...    attivo=${attivo}    esaurito=${esaurito}
    RETURN    ${prodotto}