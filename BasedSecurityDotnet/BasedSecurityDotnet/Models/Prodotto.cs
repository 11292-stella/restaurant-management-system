namespace BasedSecurityDotnet.Models;

public class Prodotto
{
    public int Id { get; set; }
    public required string Nome { get; set; }
    public required string Descrizione { get; set; }

    // Decimal garantisce precisione esatta per i valori monetari
    public required decimal Prezzo { get; set; }

    // Costo di produzione/acquisto — usato per calcolare il margine
    // nelle statistiche del gestionale. Default 0 per i prodotti esistenti.
    public decimal CostoProduzione { get; set; } = 0;

    public bool Attivo { get; set; } = true;
    public bool Esaurito { get; set; } = false;

    // Foreign Key
    public int CategoriaId { get; set; }
    public string? ImmagineUrl { get; set; }

    // Navigation property
    public required Categoria Categoria { get; set; }
}
