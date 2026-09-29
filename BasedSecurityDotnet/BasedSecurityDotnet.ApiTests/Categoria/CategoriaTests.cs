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

        // Nome univoco anche qui: con il vincolo "nome categoria unico" un nome fisso
        // ("Nome Aggiornato") farebbe fallire il test dalla seconda esecuzione sullo stesso DB
        var nomeAggiornato = $"Nome Aggiornato {Guid.NewGuid()}";
        var response = await Request.PutAsync($"/api/Categoria/{categoriaId}", new()
        {
            Headers = headers,
            DataObject = new { Nome = nomeAggiornato, Descrizione = "Descrizione aggiornata" }
        });

        Assert.True(response.Ok, $"Status: {response.Status}, Body: {await response.TextAsync()}");

        // PUT ritorna NoContent: verifico con una GET, come già imparato su ProdottoTests
        var getResponse = await Request.GetAsync($"/api/Categoria/{categoriaId}", new() { Headers = headers });
        var body = await getResponse.JsonAsync();
        Assert.NotNull(body);
        Assert.Equal(nomeAggiornato, body.Value.GetProperty("nome").GetString());

        await Request.DeleteAsync($"/api/Categoria/{categoriaId}", new() { Headers = headers });
    }

    [Fact]
    public async Task CreateCategoria_ConNomeGiaEsistente_Ritorna409()
    {
        var token = await GetAuthTokenAsync();
        var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };
        var nome = $"Categoria duplicata {Guid.NewGuid()}";

        var primaResponse = await Request.PostAsync("/api/Categoria", new()
        {
            Headers = headers,
            DataObject = new { Nome = nome, Descrizione = "Prima" }
        });
        var prima = await primaResponse.JsonAsync();
        Assert.NotNull(prima);
        var primaId = prima.Value.GetProperty("id").GetInt32();

        try
        {
            // Stesso nome con maiuscole diverse e spazi esterni: deve essere considerato un duplicato
            var duplicataResponse = await Request.PostAsync("/api/Categoria", new()
            {
                Headers = headers,
                DataObject = new { Nome = $"  {nome.ToUpper()}  ", Descrizione = "Seconda" }
            });

            Assert.Equal((int)HttpStatusCode.Conflict, duplicataResponse.Status);
            Assert.Contains("Esiste gia' una categoria", await duplicataResponse.TextAsync());
        }
        finally
        {
            await Request.DeleteAsync($"/api/Categoria/{primaId}", new() { Headers = headers });
        }
    }

    [Fact]
    public async Task UpdateCategoria_ConNomeDiUnAltraCategoria_Ritorna409()
    {
        var token = await GetAuthTokenAsync();
        var headers = new Dictionary<string, string> { ["Authorization"] = $"Bearer {token}" };

        var aResponse = await Request.PostAsync("/api/Categoria", new()
        {
            Headers = headers,
            DataObject = new { Nome = $"Categoria A {Guid.NewGuid()}", Descrizione = "A" }
        });
        var a = await aResponse.JsonAsync();
        Assert.NotNull(a);
        var aId = a.Value.GetProperty("id").GetInt32();
        var aNome = a.Value.GetProperty("nome").GetString();

        var bResponse = await Request.PostAsync("/api/Categoria", new()
        {
            Headers = headers,
            DataObject = new { Nome = $"Categoria B {Guid.NewGuid()}", Descrizione = "B" }
        });
        var b = await bResponse.JsonAsync();
        Assert.NotNull(b);
        var bId = b.Value.GetProperty("id").GetInt32();

        try
        {
            // Rinomino B con il nome di A: rifiutato
            var response = await Request.PutAsync($"/api/Categoria/{bId}", new()
            {
                Headers = headers,
                DataObject = new { Nome = aNome, Descrizione = "B" }
            });
            Assert.Equal((int)HttpStatusCode.Conflict, response.Status);

            // Rinominare A con il SUO stesso nome invece e' permesso
            var stessoNome = await Request.PutAsync($"/api/Categoria/{aId}", new()
            {
                Headers = headers,
                DataObject = new { Nome = aNome, Descrizione = "A modificata" }
            });
            Assert.True(stessoNome.Ok, $"Status: {stessoNome.Status}, Body: {await stessoNome.TextAsync()}");
        }
        finally
        {
            await Request.DeleteAsync($"/api/Categoria/{aId}", new() { Headers = headers });
            await Request.DeleteAsync($"/api/Categoria/{bId}", new() { Headers = headers });
        }
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
public async Task DeleteCategoria_ConProdottiCollegati_Ritorna409EProdottiRestano()
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

    try
    {
        // Act: provo a eliminare una categoria che contiene un prodotto
        var deleteResponse = await Request.DeleteAsync($"/api/Categoria/{categoriaId}", new() { Headers = headers });

        // Requisito: una categoria con prodotti NON si elimina (prima: 204 + cascade delete dei prodotti,
        // bug trovato dal test E2E Robot). Il backend risponde 409 Conflict con un messaggio chiaro.
        var body = await deleteResponse.TextAsync();
        Assert.Equal((int)HttpStatusCode.Conflict, deleteResponse.Status);
        Assert.Contains("Impossibile eliminare la categoria", body);

        // Niente e' stato cancellato: categoria e prodotto esistono ancora
        var getCategoriaResponse = await Request.GetAsync($"/api/Categoria/{categoriaId}", new() { Headers = headers });
        Assert.Equal((int)HttpStatusCode.OK, getCategoriaResponse.Status);

        var getProdottoResponse = await Request.GetAsync($"/api/Prodotto/{prodottoId}", new() { Headers = headers });
        Assert.Equal((int)HttpStatusCode.OK, getProdottoResponse.Status);
    }
    finally
    {
        // Pulizia anche se un Assert fallisce: prima il prodotto, poi la categoria (ora vuota)
        await Request.DeleteAsync($"/api/Prodotto/{prodottoId}", new() { Headers = headers });
        await Request.DeleteAsync($"/api/Categoria/{categoriaId}", new() { Headers = headers });
    }
}
}

// per avviare: dotnet test --filter "FullyQualifiedName~CategoriaTests"