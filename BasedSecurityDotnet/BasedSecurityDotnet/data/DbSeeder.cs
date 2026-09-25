// data/DbSeeder.cs  (file NUOVO, accanto ad AppDbContext.cs)
// Popola il menu base (3 categorie + 27 prodotti) SOLO se il database e' vuoto.
// Viene chiamato in Program.cs subito dopo Database.Migrate().
//  - Postgres Docker nuovo (locale o CI) -> nessuna categoria -> inserisce il menu
//  - DB che ha gia' dati (es. Neon)      -> Any() e' true     -> non tocca niente
// Nessun Id esplicito: li assegna Postgres, quindi niente problemi di sequence (setval).

using BasedSecurityDotnet.Models;

namespace BasedSecurityDotnet.data; // stesso namespace di AppDbContext (d minuscola)

public static class DbSeeder
{
    public static void SeedMenu(AppDbContext db)
    {
        if (db.Categorie.Any())
            return;

        var colazione = new Categoria { Nome = "Colazione", Descrizione = "Dolci italiani e American breakfast" };
        var pranzo    = new Categoria { Nome = "Pranzo",    Descrizione = "Primi e secondi italiani, burger e insalate americane" };
        var cena      = new Categoria { Nome = "Cena",      Descrizione = "Pizze italiane classiche e pizze americane extra" };

        db.Categorie.AddRange(colazione, pranzo, cena);

        db.Prodotti.AddRange(new List<Prodotto>
        {
            new() { Nome = "Cornetto vuoto", Descrizione = "Cornetto sfogliato classico", Prezzo = 1.8m, Attivo = true, Esaurito = false, Categoria = colazione, ImmagineUrl = "https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=500" },
            new() { Nome = "Cornetto alla crema", Descrizione = "Farcito con crema pasticcera", Prezzo = 2.2m, Attivo = true, Esaurito = false, Categoria = colazione, ImmagineUrl = "https://images.unsplash.com/photo-1623334044303-241021148842?w=500" },
            new() { Nome = "Cornetto al cioccolato", Descrizione = "Farcito con crema al cacao", Prezzo = 2.2m, Attivo = true, Esaurito = false, Categoria = colazione, ImmagineUrl = "https://images.unsplash.com/photo-1530610476181-d83430b64dcd?w=500" },
            new() { Nome = "Maritozzo con panna", Descrizione = "Il maritozzo romano, panna fresca", Prezzo = 3.0m, Attivo = true, Esaurito = false, Categoria = colazione, ImmagineUrl = "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500" },
            new() { Nome = "Cappuccino", Descrizione = "Con schiuma di latte", Prezzo = 2.0m, Attivo = true, Esaurito = false, Categoria = colazione, ImmagineUrl = "https://images.unsplash.com/photo-1534778101976-62847782c213?w=500" },
            new() { Nome = "American Pancakes", Descrizione = "Pancakes classici con sciroppo d'acero e burro", Prezzo = 5.5m, Attivo = true, Esaurito = false, Categoria = colazione, ImmagineUrl = "https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=500" },
            new() { Nome = "Bacon & Eggs Pancakes", Descrizione = "Pancakes salati con bacon croccante e uova", Prezzo = 7.0m, Attivo = true, Esaurito = false, Categoria = colazione, ImmagineUrl = "https://images.unsplash.com/photo-1525351484163-7529414344d8?w=500" },
            new() { Nome = "French Toast", Descrizione = "Pane brioche caramellato, frutti di bosco", Prezzo = 6.0m, Attivo = true, Esaurito = false, Categoria = colazione, ImmagineUrl = "https://images.unsplash.com/photo-1484723091739-30a097e8f929?w=500" },
            new() { Nome = "American Breakfast", Descrizione = "Uova, bacon, salsiccia, toast, fagioli", Prezzo = 8.5m, Attivo = true, Esaurito = false, Categoria = colazione, ImmagineUrl = "https://images.unsplash.com/photo-1533089860892-a7c6f0a88666?w=500" },
            new() { Nome = "Pasta al pomodoro", Descrizione = "Pasta fresca, pomodoro San Marzano, basilico", Prezzo = 8.0m, Attivo = true, Esaurito = false, Categoria = pranzo, ImmagineUrl = "https://images.unsplash.com/photo-1621996346565-e3def616400c?w=500" },
            new() { Nome = "Lasagna alla bolognese", Descrizione = "Classica lasagna al forno", Prezzo = 9.5m, Attivo = true, Esaurito = false, Categoria = pranzo, ImmagineUrl = "https://images.unsplash.com/photo-1574894709920-11b28e7367e3?w=500" },
            new() { Nome = "Cotoletta alla milanese", Descrizione = "Con contorno di patate", Prezzo = 11.0m, Attivo = true, Esaurito = false, Categoria = pranzo, ImmagineUrl = "https://images.unsplash.com/photo-1599921841143-819065a55cc6?w=500" },
            new() { Nome = "Pollo alla griglia", Descrizione = "Petto di pollo, verdure grigliate", Prezzo = 10.0m, Attivo = true, Esaurito = false, Categoria = pranzo, ImmagineUrl = "https://images.unsplash.com/photo-1532550907401-a500c9a57435?w=500" },
            new() { Nome = "Classic Burger", Descrizione = "Manzo, cheddar, lattuga, pomodoro, salsa burger", Prezzo = 9.0m, Attivo = true, Esaurito = false, Categoria = pranzo, ImmagineUrl = "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500" },
            new() { Nome = "BBQ Bacon Burger", Descrizione = "Doppio manzo, bacon, cipolla croccante, salsa BBQ", Prezzo = 11.5m, Attivo = true, Esaurito = false, Categoria = pranzo, ImmagineUrl = "https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=500" },
            new() { Nome = "Club Sandwich", Descrizione = "Pollo, bacon, uovo, lattuga, maionese", Prezzo = 8.5m, Attivo = true, Esaurito = false, Categoria = pranzo, ImmagineUrl = "https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=500" },
            new() { Nome = "Caesar Salad", Descrizione = "Pollo grigliato, parmigiano, crostini", Prezzo = 8.0m, Attivo = true, Esaurito = false, Categoria = pranzo, ImmagineUrl = "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500" },
            new() { Nome = "Cobb Salad", Descrizione = "Uova, bacon, avocado, formaggio blu", Prezzo = 9.5m, Attivo = true, Esaurito = false, Categoria = pranzo, ImmagineUrl = "https://images.unsplash.com/photo-1540420773420-3366772f4999?w=500" },
            new() { Nome = "Pizza Margherita", Descrizione = "Pomodoro, mozzarella, basilico", Prezzo = 6.5m, Attivo = true, Esaurito = false, Categoria = cena, ImmagineUrl = "https://images.unsplash.com/photo-1604382354936-07c5d9983bd3?w=500" },
            new() { Nome = "Pizza Marinara", Descrizione = "Pomodoro, aglio, origano", Prezzo = 5.5m, Attivo = true, Esaurito = false, Categoria = cena, ImmagineUrl = "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=500" },
            new() { Nome = "Pizza Diavola", Descrizione = "Pomodoro, mozzarella, salame piccante", Prezzo = 8.0m, Attivo = true, Esaurito = false, Categoria = cena, ImmagineUrl = "https://images.unsplash.com/photo-1628840042765-356cda07504e?w=500" },
            new() { Nome = "Pizza Quattro Formaggi", Descrizione = "Mozzarella, gorgonzola, fontina, parmigiano", Prezzo = 9.0m, Attivo = true, Esaurito = false, Categoria = cena, ImmagineUrl = "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500" },
            new() { Nome = "Pizza Capricciosa", Descrizione = "Prosciutto, funghi, carciofi, olive, uovo", Prezzo = 9.5m, Attivo = true, Esaurito = false, Categoria = cena, ImmagineUrl = "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=500" },
            new() { Nome = "BBQ Chicken Pizza", Descrizione = "Pollo, salsa BBQ, cipolla rossa, mozzarella", Prezzo = 11.0m, Attivo = true, Esaurito = false, Categoria = cena, ImmagineUrl = "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=500" },
            new() { Nome = "Meat Lovers Pizza", Descrizione = "Pepperoni, salsiccia, bacon, manzo macinato", Prezzo = 13.0m, Attivo = true, Esaurito = false, Categoria = cena, ImmagineUrl = "https://images.unsplash.com/photo-1534308983496-4fabb1a015ee?w=500" },
            new() { Nome = "Mac & Cheese Pizza", Descrizione = "Base di formaggio, maccheroni al formaggio, briciole croccanti", Prezzo = 12.5m, Attivo = true, Esaurito = false, Categoria = cena, ImmagineUrl = "https://images.unsplash.com/photo-1541745537411-b8046dc6d66c?w=500" },
            new() { Nome = "Buffalo Chicken Pizza", Descrizione = "Pollo piccante buffalo, salsa ranch, sedano", Prezzo = 12.0m, Attivo = true, Esaurito = false, Categoria = cena, ImmagineUrl = "https://images.unsplash.com/photo-1593560708920-61dd98c46a4e?w=500" },
        });

        db.SaveChanges(); // EF inserisce prima le categorie, poi i prodotti con la FK giusta
    }
}