
using System.ComponentModel.DataAnnotations;

namespace BasedSecurityDotnet.Dtos;

public class CategoriaDto
{
    [Required(ErrorMessage = "Il nome è obbligatorio")]
    public string Nome { get; set; } = string.Empty;

    // Facoltativa: il gestionale permette categorie senza descrizione (la lista mostra "—").
    // Prima era [Required] e rifiutava anche "" con 400 → frontend e backend non erano allineati
    // (trovato dal test E2E "Categoria Senza Descrizione Si Salva E Mostra Il Trattino").
    public string? Descrizione { get; set; }
}