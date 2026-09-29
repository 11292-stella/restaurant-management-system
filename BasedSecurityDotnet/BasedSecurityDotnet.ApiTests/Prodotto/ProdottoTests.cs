using System.Net;
using System.Text.Json;
using Microsoft.Playwright;
using Xunit;

namespace BasedSecurityDotnet.ApiTests.Prodotto;

public class ProdottoTests : ApiTestBase
{
    [Fact]
    public async Task GetProdotti_ConTokenValido_Ritorna200EListaProdotti()
    {
        var token = await GetAuthTokenAsync();

        var response = await Request.GetAsync("/api/Prodotto", new()
        {
            Headers = new Dictionary<string, string>
            {
                ["Authorization"] = $"Bearer {token}"
            }
        });

        Assert.True(response.Ok, $"Status: {response.Status}, Body: {await response.TextAsync()}");

        var body = await response.JsonAsync();
        Assert.NotNull(body);
        Assert.Equal(JsonValueKind.Array, body.Value.ValueKind);
        Assert.True(body.Value.GetArrayLength() > 0, "La lista prodotti è vuota: ci si aspettava almeno i 27 prodotti già popolati");
    }

    [Fact]
    public async Task GetProdotti_SenzaToken_Ritorna401()
    {
        // Nessun header Authorization: verifica che [Authorize] blocchi davvero l'accesso anonimo
        var response = await Request.GetAsync("/api/Prodotto");

        Assert.Equal((int)HttpStatusCode.Unauthorized, response.Status);
    }

    [Fact]
public async Task GetProdottoById_ConIdEsistente_Ritorna200EProdottoCorretto()
{
    var token = await GetAuthTokenAsync();
    var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

    // Prendiamo la lista e usiamo il primo id reale, invece di scrivere un id fisso
    // (se un giorno cancelli/reinserisci i dati, l'id "1" potrebbe non esistere più)
    var listResponse = await Request.GetAsync("/api/Prodotto", new() { Headers = headers });
    var listBody = await listResponse.JsonAsync();
    Assert.NotNull(listBody);
    var primoId = listBody.Value[0].GetProperty("id").GetInt32();

    var response = await Request.GetAsync($"/api/Prodotto/{primoId}", new() { Headers = headers });

    Assert.True(response.Ok, $"Status: {response.Status}, Body: {await response.TextAsync()}");

    var body = await response.JsonAsync();
    Assert.NotNull(body);
    Assert.Equal(primoId, body.Value.GetProperty("id").GetInt32());
}

[Fact]
public async Task GetProdottoById_ConIdInesistente_Ritorna404()
{
    var token = await GetAuthTokenAsync();
    var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

    var response = await Request.GetAsync("/api/Prodotto/999999", new() { Headers = headers });

    Assert.Equal((int)HttpStatusCode.NotFound, response.Status);
}

[Fact]
public async Task CreateProdotto_ConDatiValidi_Ritorna200EProdottoCreato()
{
    var token = await GetAuthTokenAsync();
    var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

    // Recupero una categoria esistente per la FK obbligatoria
    var categorieResponse = await Request.GetAsync("/api/Categoria", new() { Headers = headers });
    var categorieBody = await categorieResponse.JsonAsync();
    Assert.NotNull(categorieBody);
    var categoriaId = categorieBody.Value[0].GetProperty("id").GetInt32();

    var nuovoProdotto = new
    {
        Nome = $"Prodotto Test {Guid.NewGuid()}",
        Descrizione = "Prodotto creato da test automatico",
        Prezzo = 9.99,
        CostoProduzione = 3.50,
        CategoriaId = categoriaId,
        Attivo = true,
        Esaurito = false,
        ImmagineUrl = (string?)null
    };

    var response = await Request.PostAsync("/api/Prodotto", new()
    {
        Headers = headers,
        DataObject = nuovoProdotto
    });

    Assert.True(response.Ok, $"Status: {response.Status}, Body: {await response.TextAsync()}");

    var body = await response.JsonAsync();
    Assert.NotNull(body);
    Assert.Equal(nuovoProdotto.Nome, body.Value.GetProperty("nome").GetString());
    Assert.True(body.Value.GetProperty("id").GetInt32() > 0);
}

[Fact]
public async Task CreateProdotto_SenzaDescrizione_Ritorna201EDescrizioneVuota()
{
    // La descrizione e' facoltativa (come nel form Angular): prima il DTO la rendeva obbligatoria
    var token = await GetAuthTokenAsync();
    var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

    var categorieResponse = await Request.GetAsync("/api/Categoria", new() { Headers = headers });
    var categorieBody = await categorieResponse.JsonAsync();
    Assert.NotNull(categorieBody);
    var categoriaId = categorieBody.Value[0].GetProperty("id").GetInt32();

    var response = await Request.PostAsync("/api/Prodotto", new()
    {
        Headers = headers,
        DataObject = new
        {
            Nome = $"Prodotto senza descrizione {Guid.NewGuid()}",
            Descrizione = "",
            Prezzo = 4.00,
            CostoProduzione = 1.00,
            CategoriaId = categoriaId,
            Attivo = true,
            Esaurito = false
        }
    });

    Assert.Equal((int)HttpStatusCode.Created, response.Status);
    var body = await response.JsonAsync();
    Assert.NotNull(body);
    Assert.Equal("", body.Value.GetProperty("descrizione").GetString());

    await Request.DeleteAsync($"/api/Prodotto/{body.Value.GetProperty("id").GetInt32()}", new() { Headers = headers });
}

[Fact]
public async Task CreateProdotto_ConPrezzoZero_Ritorna400()
{
    // Il DTO ha [Range(0.01, ...)] sul prezzo: un prodotto a 0 euro non e' valido
    var token = await GetAuthTokenAsync();
    var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

    var categorieResponse = await Request.GetAsync("/api/Categoria", new() { Headers = headers });
    var categorieBody = await categorieResponse.JsonAsync();
    Assert.NotNull(categorieBody);
    var categoriaId = categorieBody.Value[0].GetProperty("id").GetInt32();

    var response = await Request.PostAsync("/api/Prodotto", new()
    {
        Headers = headers,
        DataObject = new
        {
            Nome = $"Prodotto a zero {Guid.NewGuid()}",
            Descrizione = "Non deve essere creato",
            Prezzo = 0.00,
            CostoProduzione = 0.00,
            CategoriaId = categoriaId,
            Attivo = true,
            Esaurito = false
        }
    });

    Assert.Equal((int)HttpStatusCode.BadRequest, response.Status);
}

[Fact]
public async Task CreateProdotto_ConCategoriaIdInesistente_Ritorna404()
{
    var token = await GetAuthTokenAsync();
    var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

    var prodottoConCategoriaInvalida = new
    {
        Nome = $"Prodotto Test {Guid.NewGuid()}",
        Descrizione = "Test categoria inesistente", // dimenticato prima: senza questo il 400 arrivava dalla validazione, non dal controller
        Prezzo = 9.99,
        CostoProduzione = 3.50,
        CategoriaId = 999999,
        Attivo = true,
        Esaurito = false
    };

    var response = await Request.PostAsync("/api/Prodotto", new()
    {
        Headers = headers,
        DataObject = prodottoConCategoriaInvalida
    });

    Assert.Equal((int)HttpStatusCode.NotFound, response.Status);
}

[Fact]
public async Task UpdateProdotto_ConDatiValidi_Ritorna200EDatiAggiornati()
{
    var token = await GetAuthTokenAsync();
    var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

    var categorieResponse = await Request.GetAsync("/api/Categoria", new() { Headers = headers });
    var categorieBody = await categorieResponse.JsonAsync();
    Assert.NotNull(categorieBody);
    var categoriaId = categorieBody.Value[0].GetProperty("id").GetInt32();

    var creaResponse = await Request.PostAsync("/api/Prodotto", new()
    {
        Headers = headers,
        DataObject = new
        {
            Nome = $"Prodotto da aggiornare {Guid.NewGuid()}",
            Descrizione = "Descrizione originale",
            Prezzo = 5.00,
            CostoProduzione = 1.00,
            CategoriaId = categoriaId,
            Attivo = true,
            Esaurito = false
        }
    });
    var creato = await creaResponse.JsonAsync();
    Assert.NotNull(creato);
    var prodottoId = creato.Value.GetProperty("id").GetInt32();

    var datiAggiornati = new
    {
        Nome = "Nome Aggiornato",
        Descrizione = "Descrizione aggiornata",
        Prezzo = 12.50,
        CostoProduzione = 4.00,
        CategoriaId = categoriaId,
        Attivo = false,
        Esaurito = true
    };

    var response = await Request.PutAsync($"/api/Prodotto/{prodottoId}", new()
    {
        Headers = headers,
        DataObject = datiAggiornati
    });

    Assert.True(response.Ok, $"Status: {response.Status}, Body: {await response.TextAsync()}");

    // Il PUT risponde senza body: verifico l'aggiornamento con una GET, non deserializzando la risposta del PUT
    var getResponse = await Request.GetAsync($"/api/Prodotto/{prodottoId}", new() { Headers = headers });
    var body = await getResponse.JsonAsync();
    Assert.NotNull(body);
    Assert.Equal("Nome Aggiornato", body.Value.GetProperty("nome").GetString());
    Assert.Equal(12.50, body.Value.GetProperty("prezzo").GetDouble());
    Assert.False(body.Value.GetProperty("attivo").GetBoolean());
}

[Fact]
public async Task DeleteProdotto_ConIdEsistente_Ritorna200EPoiNonPiuTrovabile()
{
    var token = await GetAuthTokenAsync();
    var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

    var categorieResponse = await Request.GetAsync("/api/Categoria", new() { Headers = headers });
    var categorieBody = await categorieResponse.JsonAsync();
    Assert.NotNull(categorieBody);
    var categoriaId = categorieBody.Value[0].GetProperty("id").GetInt32();

    var creaResponse = await Request.PostAsync("/api/Prodotto", new()
    {
        Headers = headers,
        DataObject = new
        {
            Nome = $"Prodotto da eliminare {Guid.NewGuid()}",
            Descrizione = "Da eliminare",
            Prezzo = 1.00,
            CostoProduzione = 0.50,
            CategoriaId = categoriaId,
            Attivo = true,
            Esaurito = false
        }
    });
    var creato = await creaResponse.JsonAsync();
    Assert.NotNull(creato);
    var prodottoId = creato.Value.GetProperty("id").GetInt32();

    var deleteResponse = await Request.DeleteAsync($"/api/Prodotto/{prodottoId}", new() { Headers = headers });
    Assert.True(deleteResponse.Ok, $"Status: {deleteResponse.Status}, Body: {await deleteResponse.TextAsync()}");

    // Verifica che sia davvero sparito, non solo che la DELETE abbia risposto 200
    var getResponse = await Request.GetAsync($"/api/Prodotto/{prodottoId}", new() { Headers = headers });
    Assert.Equal((int)HttpStatusCode.NotFound, getResponse.Status);
}
}

// per avviare: dotnet test --filter "FullyQualifiedName~ProdottoTests"