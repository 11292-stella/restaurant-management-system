using System.Net;
using System.Text.Json;
using Xunit;

namespace BasedSecurityDotnet.ApiTests.Scontrino;

public class ScontrinoTests : ApiTestBase
{
    // Helper locale: crea un ordine completo (categoria -> prodotto -> ordine),
    // per avere sempre un OrdineId valido e "pulito" su cui appendere lo scontrino
    private async Task<int> CreaOrdineAsync(Dictionary<string, string> headers)
{
    var categoriaResponse = await Request.PostAsync("/api/Categoria", new()
    {
        Headers = headers,
        DataObject = new { Nome = $"Categoria Test {Guid.NewGuid()}", Descrizione = "Per test Scontrino" }
    });
    var categoriaBody = await categoriaResponse.JsonAsync();
    Assert.NotNull(categoriaBody);
    var categoriaId = categoriaBody.Value.GetProperty("id").GetInt32();

    var prodottoResponse = await Request.PostAsync("/api/Prodotto", new()
    {
        Headers = headers,
        DataObject = new
        {
            Nome = $"Prodotto Scontrino Test {Guid.NewGuid()}",
            Descrizione = "Per test Scontrino",
            Prezzo = 10.00,
            CostoProduzione = 3.00,
            CategoriaId = categoriaId,
            Attivo = true,
            Esaurito = false
        }
    });
    var prodotto = await prodottoResponse.JsonAsync();
    Assert.NotNull(prodotto);
    var prodottoId = prodotto.Value.GetProperty("id").GetInt32();

    var ordineResponse = await Request.PostAsync("/api/Ordine", new()
    {
        Headers = headers,
        DataObject = new { Cliente = "Cliente Scontrino Test", Righe = new[] { new { ProdottoId = prodottoId, Quantita = 1 } } }
    });
    var ordine = await ordineResponse.JsonAsync();
    Assert.NotNull(ordine);
    return ordine.Value.GetProperty("id").GetInt32();
}

    [Fact]
    public async Task GetScontrini_ConTokenValido_Ritorna200EListaScontrini()
    {
        var token = await GetAuthTokenAsync();
        var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

        var response = await Request.GetAsync("/api/Scontrino", new() { Headers = headers });

        Assert.True(response.Ok, $"Status: {response.Status}, Body: {await response.TextAsync()}");
        var body = await response.JsonAsync();
        Assert.NotNull(body);
        Assert.Equal(JsonValueKind.Array, body.Value.ValueKind);
    }

    [Fact]
    public async Task GetScontrini_SenzaToken_Ritorna401()
    {
        var response = await Request.GetAsync("/api/Scontrino");
        Assert.Equal((int)HttpStatusCode.Unauthorized, response.Status);
    }

    [Fact]
    public async Task GetScontrinoById_ConIdInesistente_Ritorna404()
    {
        var token = await GetAuthTokenAsync();
        var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

        var response = await Request.GetAsync("/api/Scontrino/999999", new() { Headers = headers });
        Assert.Equal((int)HttpStatusCode.NotFound, response.Status);
    }

    [Fact]
    public async Task GetScontrinoByOrdineId_ConOrdineSenzaScontrino_Ritorna404()
    {
        var token = await GetAuthTokenAsync();
        var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

        var ordineId = await CreaOrdineAsync(headers);

        // Ordine appena creato, nessuno scontrino emesso ancora
        var response = await Request.GetAsync($"/api/Scontrino/ordine/{ordineId}", new() { Headers = headers });
        Assert.Equal((int)HttpStatusCode.NotFound, response.Status);
    }

    [Fact]
    public async Task CreateScontrino_ConDatiValidi_Ritorna201EImportoUgualeAlTotaleOrdine()
    {
        var token = await GetAuthTokenAsync();
        var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

        var ordineId = await CreaOrdineAsync(headers);

        var ordineResponse = await Request.GetAsync($"/api/Ordine/{ordineId}", new() { Headers = headers });
        var ordineBody = await ordineResponse.JsonAsync();
        Assert.NotNull(ordineBody);
        var totaleOrdine = ordineBody.Value.GetProperty("totale").GetDouble();

        var response = await Request.PostAsync("/api/Scontrino", new()
        {
            Headers = headers,
            DataObject = new { OrdineId = ordineId, MetodoPagamento = 0 } // CONTANTI
        });

        Assert.Equal((int)HttpStatusCode.Created, response.Status);

        var body = await response.JsonAsync();
        Assert.NotNull(body);
        // L'Importo deve venire dal Totale reale dell'ordine, non da un valore mandato dal client
        // (il DTO non lo prevede nemmeno, ma verifichiamo che il calcolo server-side sia corretto)
        Assert.Equal(totaleOrdine, body.Value.GetProperty("importo").GetDouble(), precision: 2);
    }

    [Fact]
    public async Task CreateScontrino_ConOrdineIdInesistente_Ritorna404()
    {
        var token = await GetAuthTokenAsync();
        var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

        var response = await Request.PostAsync("/api/Scontrino", new()
        {
            Headers = headers,
            DataObject = new { OrdineId = 999999, MetodoPagamento = 0 }
        });

        Assert.Equal((int)HttpStatusCode.NotFound, response.Status);
    }

    [Fact]
    public async Task CreateScontrino_ConOrdineCheHaGiaUnoScontrino_Ritorna400()
    {
        var token = await GetAuthTokenAsync();
        var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

        var ordineId = await CreaOrdineAsync(headers);

        // Primo scontrino: deve andare a buon fine
        var primaResponse = await Request.PostAsync("/api/Scontrino", new()
        {
            Headers = headers,
            DataObject = new { OrdineId = ordineId, MetodoPagamento = 1 } // CARTA
        });
        Assert.Equal((int)HttpStatusCode.Created, primaResponse.Status);

        // Secondo scontrino sullo stesso ordine: deve essere bloccato dal controllo esplicito,
        // non dal vincolo DB (quello darebbe un 500 generico, non un 400 pulito)
        var secondaResponse = await Request.PostAsync("/api/Scontrino", new()
        {
            Headers = headers,
            DataObject = new { OrdineId = ordineId, MetodoPagamento = 0 }
        });

        Assert.Equal((int)HttpStatusCode.BadRequest, secondaResponse.Status);
    }

    [Fact]
    public async Task GetScontrinoByOrdineId_DopoEmissione_Ritorna200EScontrinoCorretto()
    {
        var token = await GetAuthTokenAsync();
        var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

        var ordineId = await CreaOrdineAsync(headers);
        await Request.PostAsync("/api/Scontrino", new()
        {
            Headers = headers,
            DataObject = new { OrdineId = ordineId, MetodoPagamento = 0 }
        });

        var response = await Request.GetAsync($"/api/Scontrino/ordine/{ordineId}", new() { Headers = headers });

        Assert.True(response.Ok, $"Status: {response.Status}, Body: {await response.TextAsync()}");
        var body = await response.JsonAsync();
        Assert.NotNull(body);
        Assert.Equal(ordineId, body.Value.GetProperty("ordineId").GetInt32());
    }

    [Fact]
    public async Task DeleteScontrino_ConIdEsistente_Ritorna200EPoiNonPiuTrovabile()
    {
        var token = await GetAuthTokenAsync();
        var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

        var ordineId = await CreaOrdineAsync(headers);
        var creaResponse = await Request.PostAsync("/api/Scontrino", new()
        {
            Headers = headers,
            DataObject = new { OrdineId = ordineId, MetodoPagamento = 0 }
        });
        var creato = await creaResponse.JsonAsync();
        Assert.NotNull(creato);
        var scontrinoId = creato.Value.GetProperty("id").GetInt32();

        var deleteResponse = await Request.DeleteAsync($"/api/Scontrino/{scontrinoId}", new() { Headers = headers });
        Assert.True(deleteResponse.Ok, $"Status: {deleteResponse.Status}, Body: {await deleteResponse.TextAsync()}");

        var getResponse = await Request.GetAsync($"/api/Scontrino/{scontrinoId}", new() { Headers = headers });
        Assert.Equal((int)HttpStatusCode.NotFound, getResponse.Status);
    }

    [Fact]
    public async Task CreateScontrino_SuOrdineAnnullato_Ritorna400()
    {
        var token = await GetAuthTokenAsync();
        var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

        var ordineId = await CreaOrdineAsync(headers);
        var statoResponse = await Request.PutAsync($"/api/Ordine/{ordineId}/stato", new()
        {
            Headers = headers,
            DataObject = 4 // ANNULLATO
        });
        Assert.True(statoResponse.Ok);

        // Un ordine annullato non e' una vendita: prima lo scontrino veniva emesso lo stesso
        var response = await Request.PostAsync("/api/Scontrino", new()
        {
            Headers = headers,
            DataObject = new { OrdineId = ordineId, MetodoPagamento = 0 }
        });
        Assert.Equal((int)HttpStatusCode.BadRequest, response.Status);

        var getResponse = await Request.GetAsync($"/api/Scontrino/ordine/{ordineId}", new() { Headers = headers });
        Assert.Equal((int)HttpStatusCode.NotFound, getResponse.Status);
    }
}

//per avviare: dotnet test --filter "FullyQualifiedName~ScontrinoTests"