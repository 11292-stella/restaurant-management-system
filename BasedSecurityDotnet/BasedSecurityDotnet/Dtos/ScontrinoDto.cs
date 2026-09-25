using System.ComponentModel.DataAnnotations;
using BasedSecurityDotnet.Enumerations;

namespace BasedSecurityDotnet.Dtos;

public class ScontrinoDto
{
    [Required(ErrorMessage = "L'ordine è obbligatorio")]
    [Range(1, int.MaxValue, ErrorMessage = "Devi associare un ID Ordine valido")]
    public int OrdineId { get; set; }

    [Required(ErrorMessage = "Il metodo di pagamento è obbligatorio")]
    public MetodoPagamento MetodoPagamento { get; set; }

    // Niente campo Importo qui: lo calcola il server dal totale reale
    // dell'ordine, così dal client (Angular) non si può "pagare" un
    // importo diverso da quello effettivo
}