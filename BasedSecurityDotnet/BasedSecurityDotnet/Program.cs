using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer; // 1. nuovo namespace
using Microsoft.IdentityModel.Tokens;                // 2. nuovo namespace
using System.Text;                                    // 3. nuovo namespace
using BasedSecurityDotnet.data;
using BasedSecurityDotnet.Exceptions;
using BasedSecurityDotnet.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.ReferenceHandler =
            System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
    });
builder.Services.AddOpenApi();

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddScoped<JwtService>();

// CORS: consente le richieste dal frontend Angular in sviluppo
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAngular", policy =>
    {
        policy.WithOrigins("http://localhost:4200")
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// 4. Configurazione dell'autenticazione JWT
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!))
    };
});

var app = builder.Build();

// Applica automaticamente le migration EF Core pendenti all'avvio.
// Utile per il container Docker/CI, dove il database nasce vuoto ad ogni run
// e non c'è nessuno che lancia "dotnet ef database update" a mano.
// Sicuro anche in locale contro Neon: se il DB è già aggiornato, non fa nulla.
using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    dbContext.Database.Migrate();

    // Popola il menu base (3 categorie + 27 prodotti) solo se il DB è vuoto:
    // su Docker/CI lo inserisce ad ogni avvio "pulito", su Neon (già popolato) non fa nulla.
    DbSeeder.SeedMenu(dbContext);
}

app.UseMiddleware<GlobalExceptionMiddleware>();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

app.UseCors("AllowAngular"); // 5. DEVE stare prima di UseAuthentication

app.UseAuthentication(); // 6. DEVE stare prima di UseAuthorization
app.UseAuthorization();

app.MapControllers();

app.Run();

//per far partire: cd BasedSecurityDotnet
// per far partire: dotnet run --launch-profile http