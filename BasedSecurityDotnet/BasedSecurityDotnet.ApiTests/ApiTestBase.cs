using Microsoft.Playwright;
using Xunit;

[assembly: CollectionBehavior(DisableTestParallelization = true)]

namespace BasedSecurityDotnet.ApiTests;

public class ApiTestBase : IAsyncLifetime
{
    private IPlaywright _playwright = null!;
    protected IAPIRequestContext Request { get; private set; } = null!;

    // URL del tuo backend in locale: controlla in Properties/launchSettings.json
    // del progetto principale quale porta HTTPS usa, e mettila qui
    protected static readonly string BaseUrl =
    Environment.GetEnvironmentVariable("API_BASE_URL") ?? "https://localhost:7198";

    public async Task InitializeAsync()
    {
        _playwright = await Playwright.CreateAsync();

        Request = await _playwright.APIRequest.NewContextAsync(new()
        {
            BaseURL = BaseUrl,
            ExtraHTTPHeaders = new Dictionary<string, string>
            {
                ["Content-Type"] = "application/json"
            },
            IgnoreHTTPSErrors = true // utile in locale, il certificato dev di .NET spesso non è "trusted"
        });
    }

    public async Task DisposeAsync()
    {
        await Request.DisposeAsync();
        _playwright.Dispose();
    }

    protected async Task<string> GetAuthTokenAsync(string username = "mrossi", string password = "password123")
{
    var response = await Request.PostAsync("/api/Auth/login", new()
    {
        DataObject = new { Username = username, Password = password }
    });

    if (response.Status == 401)
    {
        // Non blocchiamo sul risultato della register: con test in parallelo su DB vuoto,
        // un altro test potrebbe aver già creato l'utente nel frattempo (race condition).
        await Request.PostAsync("/api/Auth/register", new()
        {
            DataObject = new
            {
                Username = username,
                Password = password,
                Role = 1,
                Nome = "Mario",
                Cognome = "Rossi",
                Email = "mrossi@test.local"
            }
        });

        response = await Request.PostAsync("/api/Auth/login", new()
        {
            DataObject = new { Username = username, Password = password }
        });
    }

    Assert.True(response.Ok, $"Login fallito. Status: {response.Status}, Body: {await response.TextAsync()}");

    var body = await response.JsonAsync();
    Assert.NotNull(body);

    var token = body.Value.GetProperty("token").GetString();
    Assert.False(string.IsNullOrEmpty(token), "Token vuoto o assente nella risposta di login");

    return token!;
}
}

// per avviare: docker compose down -v
// poi: docker compose up -d
// poi: dotnet test BasedSecurityDotnet.ApiTests