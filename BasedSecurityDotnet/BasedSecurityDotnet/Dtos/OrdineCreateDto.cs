using System.ComponentModel.DataAnnotations;

namespace BasedSecurityDotnet.Dtos;

public class OrdineRigaInputDto
{
    [Required(ErrorMessage = "Il ProdottoId è obbligatorio")]
    public int ProdottoId { get; set; }

    [Required(ErrorMessage = "La quantità è obbligatoria")]
    [Range(1, int.MaxValue, ErrorMessage = "La quantità deve essere almeno 1")]
    public int Quantita { get; set; }
}

public class OrdineCreateDto
{
    [Required(ErrorMessage = "Il cliente è obbligatorio")]
    public string Cliente { get; set; } = string.Empty;

    [Required(ErrorMessage = "L'ordine deve avere almeno una riga")]
    [MinLength(1, ErrorMessage = "L'ordine deve avere almeno una riga")]
    public List<OrdineRigaInputDto> Righe { get; set; } = new();
}
