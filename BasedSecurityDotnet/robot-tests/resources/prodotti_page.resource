*** Settings ***
Documentation    Keyword e selettori della sezione Prodotti.
Resource         common.resource


*** Variables ***
${INPUT_CERCA}    role=textbox[name="Cerca prodotto"]
${SELECT_CATEGORIA}      mat-form-field:has-text("Categoria")


*** Keywords ***
Verifica Prodotto In Lista
    [Documentation]    Controlla che un prodotto con quel nome sia visibile nella lista.
    [Arguments]    ${nome}
    Wait For Elements State    text=${nome}    visible

Cerca Prodotto
    [Documentation]    Scrive il testo nella barra di ricerca dei prodotti.
    [Arguments]    ${testo}
    Fill Text    ${INPUT_CERCA}    ${testo}

Verifica Prodotto Non In Lista
    [Documentation]    Controlla che un prodotto NON sia visibile (es. escluso dal filtro).
    [Arguments]    ${nome}
    Wait For Elements State    text=${nome}    hidden

Filtra Per Categoria
    [Documentation]    Apre la tendina Categoria e sceglie l'opzione indicata.
    [Arguments]    ${categoria}
    Click    ${SELECT_CATEGORIA}
    Click    role=option[name="${categoria}"]