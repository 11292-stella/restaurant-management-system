using System.Net;
using System.Text.Json;
using Xunit;

namespace BasedSecurityDotnet.ApiTests.Categoria;

public class CategoriaTests : ApiTestBase
{
    [Fact]
    public async Task GetCategorie_ConTokenValido_Ritorna200EListaCategorie()
    {
        var token = await GetAuthTokenAsync();
        var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

        var response = await Request.GetAsync("/api/Categoria", new() { Headers = headers });

        Assert.True(response.Ok, $"Status: {response.Status}, Body: {await response.TextAsync()}");

        var body = await response.JsonAsync();
        Assert.NotNull(body);
        Assert.Equal(JsonValueKind.Array, body.Value.ValueKind);
        Assert.True(body.Value.GetArrayLength() > 0);
    }

    [Fact]
    public async Task GetCategorie_SenzaToken_Ritorna401()
    {
        var response = await Request.GetAsync("/api/Categoria");
        Assert.Equal((int)HttpStatusCode.Unauthorized, response.Status);
    }

   [Fact]
public async Task GetCategoriaById_ConIdEsistente_Ritorna200ECategoriaCorretta()
{
    var token = await GetAuthTokenAsync();
    var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

    // Arrange: creo una categoria mia, senza dipendere da dati preesistenti
    var nomeUnivoco = $"Categoria test {Guid.NewGuid():N}";
    var createResponse = await Request.PostAsync("/api/Categoria", new()
    {
        Headers = headers,
        DataObject = new { nome = nomeUnivoco, descrizione = "Creata dal test GetById" }
    });
    Assert.Equal(201, createResponse.Status);

    var creata = (await createResponse.JsonAsync())!.Value;
    var id = creata.GetProperty("id").GetInt32();

    // Act
    var response = await Request.GetAsync($"/api/Categoria/{id}", new() { Headers = headers });

    // Assert
    Assert.Equal(200, response.Status);
    var body = (await response.JsonAsync())!.Value;
    Assert.Equal(id, body.GetProperty("id").GetInt32());
    Assert.Equal(nomeUnivoco, body.GetProperty("nome").GetString());
}

    [Fact]
    public async Task GetCategoriaById_ConIdInesistente_Ritorna404()
    {
        var token = await GetAuthTokenAsync();
        var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

        var response = await Request.GetAsync("/api/Categoria/999999", new() { Headers = headers });

        Assert.Equal((int)HttpStatusCode.NotFound, response.Status);
    }

    [Fact]
    public async Task CreateCategoria_ConDatiValidi_Ritorna201ECategoriaCreata()
    {
        var token = await GetAuthTokenAsync();
        var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

        var nuovaCategoria = new
        {
            Nome = $"Categoria Test {Guid.NewGuid()}",
            Descrizione = "Categoria creata da test automatico"
        };

        var response = await Request.PostAsync("/api/Categoria", new()
        {
            Headers = headers,
            DataObject = nuovaCategoria
        });

        // Qui aspettiamo 201, non 200: a differenza di ProdottoController, questo Create
        // usa CreatedAtAction, che risponde correttamente col vero status REST per una creazione
        Assert.Equal((int)HttpStatusCode.Created, response.Status);

        var body = await response.JsonAsync();
        Assert.NotNull(body);
        Assert.Equal(nuovaCategoria.Nome, body.Value.GetProperty("nome").GetString());
    }

    [Fact]
    public async Task UpdateCategoria_ConDatiValidi_Ritorna200EDatiAggiornati()
    {
        var token = await GetAuthTokenAsync();
        var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

        var creaResponse = await Request.PostAsync("/api/Categoria", new()
        {
            Headers = headers,
            DataObject = new { Nome = $"Categoria da aggiornare {Guid.NewGuid()}", Descrizione = "Originale" }
        });
        var creato = await creaResponse.JsonAsync();
        Assert.NotNull(creato);
        var categoriaId = creato.Value.GetProperty("id").GetInt32();

        var response = await Request.PutAsync($"/api/Categoria/{categoriaId}", new()
        {
            Headers = headers,
            DataObject = new { Nome = "Nome Aggiornato", Descrizione = "Descrizione aggiornata" }
        });

        Assert.True(response.Ok, $"Status: {response.Status}, Body: {await response.TextAsync()}");

        // PUT ritorna NoContent: verifico con una GET, come già imparato su ProdottoTests
        var getResponse = await Request.GetAsync($"/api/Categoria/{categoriaId}", new() { Headers = headers });
        var body = await getResponse.JsonAsync();
        Assert.NotNull(body);
        Assert.Equal("Nome Aggiornato", body.Value.GetProperty("nome").GetString());
    }

    [Fact]
    public async Task DeleteCategoria_ConIdEsistenteESenzaProdottiCollegati_Ritorna200EPoiNonPiuTrovabile()
    {
        var token = await GetAuthTokenAsync();
        var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

        var creaResponse = await Request.PostAsync("/api/Categoria", new()
        {
            Headers = headers,
            DataObject = new { Nome = $"Categoria da eliminare {Guid.NewGuid()}", Descrizione = "Da eliminare" }
        });
        var creato = await creaResponse.JsonAsync();
        Assert.NotNull(creato);
        var categoriaId = creato.Value.GetProperty("id").GetInt32();

        var deleteResponse = await Request.DeleteAsync($"/api/Categoria/{categoriaId}", new() { Headers = headers });
        Assert.True(deleteResponse.Ok, $"Status: {deleteResponse.Status}, Body: {await deleteResponse.TextAsync()}");

        var getResponse = await Request.GetAsync($"/api/Categoria/{categoriaId}", new() { Headers = headers });
        Assert.Equal((int)HttpStatusCode.NotFound, getResponse.Status);
    }

    [Fact]
public async Task DeleteCategoria_ConProdottiCollegati_CancellaACascataAncheIProdotti()
{
    var token = await GetAuthTokenAsync();
    var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

    var categoriaResponse = await Request.PostAsync("/api/Categoria", new()
    {
        Headers = headers,
        DataObject = new { Nome = $"Categoria con prodotti {Guid.NewGuid()}", Descrizione = "Test FK" }
    });
    var categoria = await categoriaResponse.JsonAsync();
    Assert.NotNull(categoria);
    var categoriaId = categoria.Value.GetProperty("id").GetInt32();

    var prodottoResponse = await Request.PostAsync("/api/Prodotto", new()
    {
        Headers = headers,
        DataObject = new
        {
            Nome = $"Prodotto collegato {Guid.NewGuid()}",
            Descrizione = "Serve solo per il vincolo FK",
            Prezzo = 1.00,
            CostoProduzione = 0.50,
            CategoriaId = categoriaId,
            Attivo = true,
            Esaurito = false
        }
    });
    var prodotto = await prodottoResponse.JsonAsync();
    Assert.NotNull(prodotto);
    var prodottoId = prodotto.Value.GetProperty("id").GetInt32();

    var deleteResponse = await Request.DeleteAsync($"/api/Categoria/{categoriaId}", new() { Headers = headers });
    Assert.True(deleteResponse.Ok, $"Status: {deleteResponse.Status}, Body: {await deleteResponse.TextAsync()}");

    // Test-documentazione: conferma che la cancellazione della categoria elimina "a cascata"
    // anche i prodotti collegati, senza nessun avviso preventivo — comportamento di default
    // di EF Core sulle FK obbligatorie, probabilmente non voluto in un gestionale reale
    // (un ristoratore che elimina una categoria per errore perderebbe anche tutti i prodotti dentro).
    var getProdottoResponse = await Request.GetAsync($"/api/Prodotto/{prodottoId}", new() { Headers = headers });
    Assert.Equal((int)HttpStatusCode.NotFound, getProdottoResponse.Status);
}
}

// per avviare: dotnet test --filter "FullyQualifiedName~CategoriaTests"