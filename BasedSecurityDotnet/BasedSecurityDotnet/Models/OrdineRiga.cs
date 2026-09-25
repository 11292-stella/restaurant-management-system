namespace BasedSecurityDotnet.Models;

public class OrdineRiga
{
    public int Id { get; set;}
    public int OrdineId {get; set;}
    public required Ordine Ordine {get; set;}
    public int ProdottoId {get; set;}
    public required Prodotto Prodotto {get; set;}
    public  int Quantita {get; set;}
    public required decimal PrezzoUnitario {get; set;}
}