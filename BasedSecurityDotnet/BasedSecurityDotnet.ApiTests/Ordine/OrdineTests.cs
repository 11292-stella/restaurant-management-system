using System.Net;
using System.Text.Json;
using Xunit;

namespace BasedSecurityDotnet.ApiTests.Ordine;

public class OrdineTests : ApiTestBase
{
    // Helper locale: crea un prodotto con Attivo/Esaurito parametrizzabili,
    // per i test su disponibilità che servono solo a Ordine
    private async Task<(int prodottoId, decimal prezzo)> CreaProdottoAsync(
    Dictionary<string, string> headers, bool attivo = true, bool esaurito = false, decimal prezzo = 10.00m)
{
    var categoriaResponse = await Request.PostAsync("/api/Categoria", new()
    {
        Headers = headers,
        DataObject = new { Nome = $"Categoria Test {Guid.NewGuid()}", Descrizione = "Per test Ordine" }
    });
    var categoriaBody = await categoriaResponse.JsonAsync();
    Assert.NotNull(categoriaBody);
    var categoriaId = categoriaBody.Value.GetProperty("id").GetInt32();

    var response = await Request.PostAsync("/api/Prodotto", new()
    {
        Headers = headers,
        DataObject = new
        {
            Nome = $"Prodotto Ordine Test {Guid.NewGuid()}",
            Descrizione = "Per test Ordine",
            Prezzo = prezzo,
            CostoProduzione = prezzo * 0.3m,
            CategoriaId = categoriaId,
            Attivo = attivo,
            Esaurito = esaurito
        }
    });
    var body = await response.JsonAsync();
    Assert.NotNull(body);
    return (body.Value.GetProperty("id").GetInt32(), prezzo);
}

    [Fact]
    public async Task GetOrdini_ConTokenValido_Ritorna200EListaOrdini()
    {
        var token = await GetAuthTokenAsync();
        var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

        var response = await Request.GetAsync("/api/Ordine", new() { Headers = headers });

        Assert.True(response.Ok, $"Status: {response.Status}, Body: {await response.TextAsync()}");
        var body = await response.JsonAsync();
        Assert.NotNull(body);
        Assert.Equal(JsonValueKind.Array, body.Value.ValueKind);
    }

    [Fact]
    public async Task GetOrdini_SenzaToken_Ritorna401()
    {
        var response = await Request.GetAsync("/api/Ordine");
        Assert.Equal((int)HttpStatusCode.Unauthorized, response.Status);
    }

    [Fact]
    public async Task GetOrdineById_ConIdInesistente_Ritorna404()
    {
        var token = await GetAuthTokenAsync();
        var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

        var response = await Request.GetAsync("/api/Ordine/999999", new() { Headers = headers });
        Assert.Equal((int)HttpStatusCode.NotFound, response.Status);
    }

    [Fact]
    public async Task CreateOrdine_ConDatiValidi_Ritorna201ETotaleCalcolatoCorrettamente()
    {
        var token = await GetAuthTokenAsync();
        var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

        var (prodottoId, prezzo) = await CreaProdottoAsync(headers, prezzo: 8.50m);
        const int quantita = 3;

        var nuovoOrdine = new
        {
            Cliente = "Cliente Test",
            Righe = new[]
            {
                new { ProdottoId = prodottoId, Quantita = quantita }
            }
        };

        var response = await Request.PostAsync("/api/Ordine", new()
        {
            Headers = headers,
            DataObject = nuovoOrdine
        });

        Assert.Equal((int)HttpStatusCode.Created, response.Status);

        var body = await response.JsonAsync();
        Assert.NotNull(body);
        // Totale atteso: prezzo * quantità, calcolato server-side — non ci fidiamo,
        // lo ricalcoliamo noi nel test e confrontiamo
        var totaleAtteso = prezzo * quantita;
        Assert.Equal((double)totaleAtteso, body.Value.GetProperty("totale").GetDouble(), precision: 2);
    }

    [Fact]
    public async Task CreateOrdine_ConProdottoIdInesistente_Ritorna404()
    {
        var token = await GetAuthTokenAsync();
        var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

        var ordineConProdottoInvalido = new
        {
            Cliente = "Cliente Test",
            Righe = new[] { new { ProdottoId = 999999, Quantita = 1 } }
        };

        var response = await Request.PostAsync("/api/Ordine", new()
        {
            Headers = headers,
            DataObject = ordineConProdottoInvalido
        });

        Assert.Equal((int)HttpStatusCode.NotFound, response.Status);
    }

    [Fact]
    public async Task CreateOrdine_ConProdottoNonAttivo_Ritorna400()
    {
        var token = await GetAuthTokenAsync();
        var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

        var (prodottoId, _) = await CreaProdottoAsync(headers, attivo: false);

        var response = await Request.PostAsync("/api/Ordine", new()
        {
            Headers = headers,
            DataObject = new { Cliente = "Cliente Test", Righe = new[] { new { ProdottoId = prodottoId, Quantita = 1 } } }
        });

        Assert.Equal((int)HttpStatusCode.BadRequest, response.Status);
    }

    [Fact]
    public async Task CreateOrdine_ConProdottoEsaurito_Ritorna400()
    {
        var token = await GetAuthTokenAsync();
        var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

        var (prodottoId, _) = await CreaProdottoAsync(headers, esaurito: true);

        var response = await Request.PostAsync("/api/Ordine", new()
        {
            Headers = headers,
            DataObject = new { Cliente = "Cliente Test", Righe = new[] { new { ProdottoId = prodottoId, Quantita = 1 } } }
        });

        Assert.Equal((int)HttpStatusCode.BadRequest, response.Status);
    }

    [Fact]
    public async Task CreateOrdine_PrezzoUnitarioFotografato_NonCambiaSeIlPrezzoDelProdottoCambiaDopo()
    {
        var token = await GetAuthTokenAsync();
        var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

        var (prodottoId, prezzoOriginale) = await CreaProdottoAsync(headers, prezzo: 20.00m);

        var creaOrdineResponse = await Request.PostAsync("/api/Ordine", new()
        {
            Headers = headers,
            DataObject = new { Cliente = "Cliente Test", Righe = new[] { new { ProdottoId = prodottoId, Quantita = 1 } } }
        });
        var ordineCreato = await creaOrdineResponse.JsonAsync();
        Assert.NotNull(ordineCreato);
        var ordineId = ordineCreato.Value.GetProperty("id").GetInt32();

        // Recupero la categoria del prodotto per il PUT (serve nel ProdottoDto)
        var prodottoResponse = await Request.GetAsync($"/api/Prodotto/{prodottoId}", new() { Headers = headers });
        var prodottoBody = await prodottoResponse.JsonAsync();
        Assert.NotNull(prodottoBody);
        var categoriaId = prodottoBody.Value.GetProperty("categoriaId").GetInt32();

        // Cambio il prezzo del prodotto DOPO che l'ordine è già stato creato
        await Request.PutAsync($"/api/Prodotto/{prodottoId}", new()
        {
            Headers = headers,
            DataObject = new
            {
                Nome = "Prodotto con prezzo cambiato",
                Descrizione = "Test snapshot prezzo",
                Prezzo = 99.99,
                CostoProduzione = 5.00,
                CategoriaId = categoriaId,
                Attivo = true,
                Esaurito = false
            }
        });

        // Il PrezzoUnitario della riga d'ordine deve restare quello originale (20.00), non 99.99
        var getOrdineResponse = await Request.GetAsync($"/api/Ordine/{ordineId}", new() { Headers = headers });
        var ordineBody = await getOrdineResponse.JsonAsync();
        Assert.NotNull(ordineBody);
        var prezzoUnitarioRiga = ordineBody.Value.GetProperty("righe")[0].GetProperty("prezzoUnitario").GetDouble();

        Assert.Equal((double)prezzoOriginale, prezzoUnitarioRiga, precision: 2);
    }

    [Fact]
    public async Task AggiornaStatoOrdine_ConIdInesistente_Ritorna404()
    {
        var token = await GetAuthTokenAsync();
        var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

        // TODO: verificare il valore numerico corretto per lo stato una volta noti i valori dell'enum
        var response = await Request.PutAsync("/api/Ordine/999999/stato", new()
        {
            Headers = headers,
            DataObject = 1
        });

        Assert.Equal((int)HttpStatusCode.NotFound, response.Status);
    }

    [Fact]
    public async Task DeleteOrdine_ConIdEsistente_Ritorna200EPoiNonPiuTrovabile()
    {
        var token = await GetAuthTokenAsync();
        var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

        var (prodottoId, _) = await CreaProdottoAsync(headers);
        var creaResponse = await Request.PostAsync("/api/Ordine", new()
        {
            Headers = headers,
            DataObject = new { Cliente = "Cliente da eliminare", Righe = new[] { new { ProdottoId = prodottoId, Quantita = 1 } } }
        });
        var creato = await creaResponse.JsonAsync();
        Assert.NotNull(creato);
        var ordineId = creato.Value.GetProperty("id").GetInt32();

        var deleteResponse = await Request.DeleteAsync($"/api/Ordine/{ordineId}", new() { Headers = headers });
        Assert.True(deleteResponse.Ok, $"Status: {deleteResponse.Status}, Body: {await deleteResponse.TextAsync()}");

        var getResponse = await Request.GetAsync($"/api/Ordine/{ordineId}", new() { Headers = headers });
        Assert.Equal((int)HttpStatusCode.NotFound, getResponse.Status);
    }

    [Fact]
public async Task GetOrdineById_ConIdEsistente_Ritorna200EOrdineConRigheCorrette()
{
    var token = await GetAuthTokenAsync();
    var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

    var (prodottoId, prezzo) = await CreaProdottoAsync(headers, prezzo: 15.00m);
    const int quantita = 2;

    var creaResponse = await Request.PostAsync("/api/Ordine", new()
    {
        Headers = headers,
        DataObject = new { Cliente = "Cliente GetById", Righe = new[] { new { ProdottoId = prodottoId, Quantita = quantita } } }
    });
    var creato = await creaResponse.JsonAsync();
    Assert.NotNull(creato);
    var ordineId = creato.Value.GetProperty("id").GetInt32();

    var response = await Request.GetAsync($"/api/Ordine/{ordineId}", new() { Headers = headers });

    Assert.True(response.Ok, $"Status: {response.Status}, Body: {await response.TextAsync()}");

    var body = await response.JsonAsync();
    Assert.NotNull(body);
    Assert.Equal("Cliente GetById", body.Value.GetProperty("cliente").GetString());
    Assert.Equal(1, body.Value.GetProperty("righe").GetArrayLength());
    Assert.Equal(quantita, body.Value.GetProperty("righe")[0].GetProperty("quantita").GetInt32());
    Assert.Equal((double)(prezzo * quantita), body.Value.GetProperty("totale").GetDouble(), precision: 2);
}

[Fact]
public async Task AggiornaStatoOrdine_ConIdEsistente_Ritorna200ENuovoStatoConfermato()
{
    var token = await GetAuthTokenAsync();
    var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

    var (prodottoId, _) = await CreaProdottoAsync(headers);
    var creaResponse = await Request.PostAsync("/api/Ordine", new()
    {
        Headers = headers,
        DataObject = new { Cliente = "Cliente Stato", Righe = new[] { new { ProdottoId = prodottoId, Quantita = 1 } } }
    });
    var creato = await creaResponse.JsonAsync();
    Assert.NotNull(creato);
    var ordineId = creato.Value.GetProperty("id").GetInt32();

   
    var response = await Request.PutAsync($"/api/Ordine/{ordineId}/stato", new()
    {
        Headers = headers,
        DataObject = 2 // PRONTO
    });

    Assert.True(response.Ok, $"Status: {response.Status}, Body: {await response.TextAsync()}");

    // PUT ritorna NoContent: verifico con una GET, come già imparato su Prodotto/Categoria
    var getResponse = await Request.GetAsync($"/api/Ordine/{ordineId}", new() { Headers = headers });
    var body = await getResponse.JsonAsync();
    Assert.NotNull(body);
    Assert.Equal(2, body.Value.GetProperty("statoOrdine").GetInt32());
}
}

// per avviare: dotnet test --filter "FullyQualifiedName~OrdineTests"