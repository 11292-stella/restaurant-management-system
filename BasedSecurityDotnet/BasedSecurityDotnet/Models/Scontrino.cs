using BasedSecurityDotnet.Enumerations;

namespace BasedSecurityDotnet.Models;

public class Scontrino
{
    public int Id { get; set; }
    public DateTime DataEmissione { get; set; } = DateTime.UtcNow;
    public required decimal Importo { get; set; }
    public required MetodoPagamento MetodoPagamento { get; set; }

    // Foreign Key — uno scontrino per ordine (relazione 1:1)
    public int OrdineId { get; set; }
    public required Ordine Ordine { get; set; }
}