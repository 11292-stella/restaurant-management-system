# =====================================================================
# ESPLORATORE: apre una pagina del gestionale da loggato e ne salva HTML + screenshot.
# Da usare PRIMA di scrivere un test, quando non si ha il codice sorgente.
#
#   cd C:\Users\stell\Desktop\BasedSecurityDotnet\robot-tests
#   robot --outputdir results --variable PAGINA:/prodotti tools/salva_pagina.robot
#   robot --outputdir results --variable PAGINA:/prodotti/nuovo tools/salva_pagina.robot
#
# Con DEBUG:True si ferma prima di salvare: puoi cliccare a mano (es. aprire un dialog
# o un dropdown), premere OK, e viene salvato lo stato della pagina in quel momento.
#   robot --outputdir results --variable PAGINA:/prodotti --variable DEBUG:True tools/salva_pagina.robot
#
# Risultato: results/html/<pagina>_<timestamp>.html e .png
# =====================================================================

*** Settings ***
Documentation     Salva HTML e screenshot di una pagina del gestionale.
Resource          ../resources/common.resource
Suite Setup       Run Keywords    Prepara Utente Di Test    AND    Apri Browser
Suite Teardown    Close Browser


*** Variables ***
${PAGINA}    /


*** Test Cases ***
Salva Pagina
    Apri Gestionale Da Loggato
    Go To    ${BASE_URL}${PAGINA}    wait_until=domcontentloaded
    Wait For Load State    networkidle
    Pausa Debug    Porta la pagina nello stato che ti interessa (apri dialog, dropdown...), poi premi OK
    Salva HTML Pagina    ${PAGINA}
    Close Context