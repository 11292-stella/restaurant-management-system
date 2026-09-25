using System.Net;
using System.Net.Http.Json;
using Microsoft.Playwright;
using Xunit;

namespace BasedSecurityDotnet.ApiTests;

public class AuthTests : ApiTestBase
{
    [Fact]
    public async Task Login_ConCredenzialiValide_Ritorna200EToken()
    {
        var response = await Request.PostAsync("/api/Auth/login", new APIRequestContextOptions
        {
            DataObject = new
            {
                username = "mrossi",
                password = "password123"
            }
        });

        Assert.Equal(200, response.Status);

        var body = await response.JsonAsync();
        Assert.NotNull(body);
        Assert.True(body.Value.TryGetProperty("token", out _));
    }

    [Fact]
    public async Task Login_ConPasswordErrata_Ritorna401()
    {
        var response = await Request.PostAsync("/api/Auth/login", new APIRequestContextOptions
        {
            DataObject = new
            {
                username = "mrossi",
                password = "password-sbagliata"
            }
        });

        Assert.Equal(401, response.Status);
    }

[Fact]
public async Task Register_ConDatiValidi_CreaUtente()
{
    var response = await Request.PostAsync("/api/Auth/register", new APIRequestContextOptions
    {
        DataObject = new
        {
            username = $"test_{Guid.NewGuid():N}".Substring(0, 15),
            password = "Password123!",
            nome = "Test",
            cognome = "Automatico",
            email = $"test_{Guid.NewGuid():N}@test.com",
            role = 1
        }
    });

    var bodyText = await response.TextAsync();
    Assert.True(response.Status == 200, $"Status: {response.Status}, Body: {bodyText}");
}

[Fact]
public async Task Register_ConDatiMancanti_Ritorna400()
{
    var response = await Request.PostAsync("/api/Auth/register", new APIRequestContextOptions
    {
        DataObject = new
        {
            username = "" // vuoto, dovrebbe fallire la validazione
        }
    });

    Assert.Equal(400, response.Status);
}

[Fact]
public async Task Register_ConRoleAdmin_VerificaComportamentoAttuale()
{
    var response = await Request.PostAsync("/api/Auth/register", new APIRequestContextOptions
    {
        DataObject = new
        {
            username = $"test_{Guid.NewGuid():N}".Substring(0, 15),
            password = "Password123!",
            nome = "Test",
            cognome = "Sicurezza",
            email = $"test_{Guid.NewGuid():N}@test.com",
            role = 0 // ADMIN
        }
    });

    var bodyText = await response.TextAsync();
    // Questo test DOCUMENTA il comportamento attuale, non impone "come dovrebbe essere":
    // se passa con 200, conferma che chiunque può registrarsi come ADMIN (bug di sicurezza noto)
    Assert.True(response.Status == 200, $"Status: {response.Status}, Body: {bodyText}");
}
}