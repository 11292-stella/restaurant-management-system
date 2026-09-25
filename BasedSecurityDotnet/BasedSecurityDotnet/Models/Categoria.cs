namespace BasedSecurityDotnet.Models;

public class Categoria
{
    public int Id { get; set; }
    public required string Nome { get; set; }
    public required string Descrizione { get; set; }

    // Navigazione: una Categoria ha molti Prodotti (relazione inversa, popolata da EF Core)
    public ICollection<Prodotto> Prodotti { get; set; } = new List<Prodotto>();
}
