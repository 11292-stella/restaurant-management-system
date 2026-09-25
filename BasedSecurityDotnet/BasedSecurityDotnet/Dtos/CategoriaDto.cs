using System.ComponentModel.DataAnnotations;

namespace BasedSecurityDotnet.Dtos;

public class CategoriaDto
{
    [Required(ErrorMessage = "Il nome è obbligatorio")]
    public string Nome { get; set; } = string.Empty;

    [Required(ErrorMessage = "La descrizione è obbligatoria")]
    public string Descrizione { get; set; } = string.Empty;
}
