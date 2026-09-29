"""Mappa degli endpoint chiamati durante i test E2E (recorder degli endpoint).

1. lancia i test registrando il traffico:
       robot --outputdir results --variable REGISTRA_ENDPOINT:True tests
   (ogni test salva results/har/<nome test>.har)
2. estrai la mappa:
       python tools/estrai_endpoint.py
   -> results/endpoint/endpoint.md  (tabella leggibile, da cui scrivere i test API)
   -> results/endpoint/endpoint.csv (stessi dati, per Excel)

Per ogni endpoint: metodo, percorso normalizzato (/api/Ordine/57 -> /api/Ordine/{id}),
status HTTP visti, campi del body JSON inviati, quante chiamate e da quali test.
Utile soprattutto SENZA codice sorgente: la UI "racconta" quali API usa.
Nell'output niente dati sensibili: solo metodo, percorso, status e NOMI dei campi (il body di /Auth non viene letto).
I file .har in results/har invece contengono header e token: restano in results/ (gitignored), non condividerli.
"""
import csv
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

CARTELLA = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("results")
FILTRO_API = "/api/"                      # solo le chiamate al backend (niente JS, CSS, immagini)
PERCORSI_SENSIBILI = ("/Auth/login", "/Auth/register")


def normalizza(percorso: str) -> str:
    """/api/Ordine/57/stato -> /api/Ordine/{id}/stato ; toglie la query string."""
    percorso = percorso.split("?")[0]
    return re.sub(r"/\d+(?=/|$)", "/{id}", percorso)


def campi_body(richiesta: dict, percorso: str) -> set[str]:
    if any(s in percorso for s in PERCORSI_SENSIBILI):
        return set()
    testo = (richiesta.get("postData") or {}).get("text") or ""
    try:
        dato = json.loads(testo)
    except ValueError:
        return set()
    if isinstance(dato, dict):
        return set(dato.keys())
    return {f"<{type(dato).__name__}>"}      # es. PUT /stato manda un numero nudo


def main() -> None:
    file_har = sorted((CARTELLA / "har").glob("*.har"))
    if not file_har:
        sys.exit(f"Nessun .har in {CARTELLA / 'har'}: lancia prima i test con --variable REGISTRA_ENDPOINT:True")

    endpoint = defaultdict(lambda: {"status": set(), "campi": set(), "chiamate": 0, "test": set()})
    for har in file_har:
        voci = json.loads(har.read_text(encoding="utf-8"))["log"]["entries"]
        for voce in voci:
            req = voce["request"]
            url = req["url"]
            if FILTRO_API not in url or req["method"] == "OPTIONS":   # OPTIONS = preflight CORS
                continue
            percorso = normalizza("/" + url.split("://", 1)[1].split("/", 1)[1])
            e = endpoint[(req["method"], percorso)]
            e["status"].add(voce["response"]["status"])
            e["campi"] |= campi_body(req, percorso)
            e["chiamate"] += 1
            e["test"].add(har.stem.replace("_", " "))

    uscita = CARTELLA / "endpoint"
    uscita.mkdir(parents=True, exist_ok=True)
    righe = sorted(endpoint.items(), key=lambda kv: (kv[0][1], kv[0][0]))

    with open(uscita / "endpoint.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter=";")
        w.writerow(["metodo", "endpoint", "status visti", "campi body", "chiamate", "n. test"])
        for (metodo, percorso), e in righe:
            w.writerow([metodo, percorso, " ".join(map(str, sorted(e["status"]))),
                        ", ".join(sorted(e["campi"])), e["chiamate"], len(e["test"])])

    md = [
        "# Endpoint chiamati dai test E2E",
        "",
        f"Generato da `tools/estrai_endpoint.py` su {len(file_har)} test registrati. "
        f"{len(righe)} endpoint distinti.",
        "",
        "| Metodo | Endpoint | Status visti | Campi body | Chiamate | Test |",
        "|---|---|---|---|---|---|",
    ]
    for (metodo, percorso), e in righe:
        md.append(f"| {metodo} | `{percorso}` | {', '.join(map(str, sorted(e['status'])))} | "
                  f"{', '.join(sorted(e['campi'])) or '-'} | {e['chiamate']} | {len(e['test'])} |")
    md += ["", "## Idee per i test API", "",
           "- ogni endpoint: senza token -> 401, id inesistente -> 404",
           "- ogni status visto qui (200/201/204/400/409) e' un caso da coprire con un test API dedicato",
           "- i campi body sono i DTO da validare (vuoti, spazi, limiti, tipi sbagliati)"]
    (uscita / "endpoint.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    print(f"{len(righe)} endpoint da {len(file_har)} test -> {uscita / 'endpoint.md'}")


if __name__ == "__main__":
    main()
