using BasedSecurityDotnet.Enumeration;

namespace BasedSecurityDotnet.Models;

public class Ordine
{
    public int Id { get; set; }
    public required string Cliente { get; set; }
    public DateTime DataOra { get; set; }
    public decimal Totale { get; set; }
    public StatoOrdine StatoOrdine { get; set; }

    // Navigazione inversa: un Ordine ha molte OrdineRiga (stesso concetto di
    // Categoria.Prodotti) — serve al controller per caricare le righe con Include(...)
    public ICollection<OrdineRiga> Righe { get; set; } = new List<OrdineRiga>();
}
