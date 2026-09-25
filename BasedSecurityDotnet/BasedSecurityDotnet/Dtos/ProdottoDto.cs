using System.ComponentModel.DataAnnotations;

namespace BasedSecurityDotnet.Dtos;

public class ProdottoDto
{
    [Required(ErrorMessage = "Il nome è obbligatorio")]
    public string Nome { get; set; } = string.Empty;

    [Required(ErrorMessage = "La descrizione è obbligatoria")]
    public string Descrizione { get; set; } = string.Empty;

    [Required(ErrorMessage = "Il prezzo è obbligatorio")]
    [Range(typeof(decimal), "0.01", "79228162514264337593543950335", ParseLimitsInInvariantCulture = true, ErrorMessage = "Il prezzo deve essere maggiore di zero")]
    public decimal Prezzo { get; set; }

    [Range(typeof(decimal), "0", "79228162514264337593543950335", ParseLimitsInInvariantCulture = true, ErrorMessage = "Il costo non può essere negativo")]
    public decimal CostoProduzione { get; set; } = 0;

    public string? ImmagineUrl { get; set; }

    public bool Attivo { get; set; } = true;
    public bool Esaurito { get; set; } = false;

    [Range(1, int.MaxValue, ErrorMessage = "Devi associare un ID Categoria valido")]
    public int CategoriaId { get; set; }
}
