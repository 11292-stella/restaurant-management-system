using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BasedSecurityDotnet.data;
using BasedSecurityDotnet.Dtos;
using BasedSecurityDotnet.Exceptions;
using BasedSecurityDotnet.Models;

namespace BasedSecurityDotnet.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class CategoriaController : ControllerBase
{
    private readonly AppDbContext _context;

    public CategoriaController(AppDbContext context)
    {
        _context = context;
    }

    // GET api/Categoria
    [HttpGet]
    public async Task<ActionResult<IEnumerable<Categoria>>> GetAll()
    {
        var categorie = await _context.Categorie.ToListAsync();
        return Ok(categorie);
    }

    // GET api/Categoria/5
    [HttpGet("{id}")]
    public async Task<ActionResult<Categoria>> GetById(int id)
    {
        var categoria = await _context.Categorie.FindAsync(id);

        if (categoria == null)
        {
            throw new NotFoundException($"Categoria con id {id} non trovata.");
        }

        return Ok(categoria);
    }

    // POST api/Categoria
    [HttpPost]
    public async Task<ActionResult<Categoria>> Create(CategoriaDto dto)
    {
        // Nome univoco (senza distinguere maiuscole/minuscole): due "Colazione"
        // renderebbero ambigui i filtri e il form prodotto
        if (await EsisteCategoriaConNome(dto.Nome))
        {
            return NomeGiaUsato(dto.Nome);
        }

        var categoria = new Categoria
        {
            // Trim: "Pizza " e "Pizza" non diventano due categorie diverse.
            // Descrizione facoltativa: se manca si salva stringa vuota (colonna non nullable, niente migration)
            Nome = dto.Nome.Trim(),
            Descrizione = dto.Descrizione?.Trim() ?? string.Empty
        };

        _context.Categorie.Add(categoria);
        await _context.SaveChangesAsync();

        // CreatedAtAction: risponde 201 Created e mette nell'header "Location"
        // l'URL per recuperare la risorsa appena creata (GetById) — buona pratica REST
        return CreatedAtAction(nameof(GetById), new { id = categoria.Id }, categoria);
    }

    // PUT api/Categoria/5
    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, CategoriaDto dto)
    {
        var categoria = await _context.Categorie.FindAsync(id);

        if (categoria == null)
        {
            throw new NotFoundException($"Categoria con id {id} non trovata.");
        }

        // Stesso controllo della Create, escludendo la categoria che sto modificando
        // (rinominarla con il suo stesso nome, o cambiare solo maiuscole, e' permesso)
        if (await EsisteCategoriaConNome(dto.Nome, escludiId: id))
        {
            return NomeGiaUsato(dto.Nome);
        }

        categoria.Nome = dto.Nome.Trim();
        categoria.Descrizione = dto.Descrizione?.Trim() ?? string.Empty;

        await _context.SaveChangesAsync();

        // NoContent: 204, operazione riuscita ma non c'è nulla di nuovo da restituire
        // (il client ha già i dati aggiornati, glieli ha mandati lui nel body della richiesta)
        return NoContent();
    }

    // DELETE api/Categoria/5
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var categoria = await _context.Categorie.FindAsync(id);

        if (categoria == null)
        {
            throw new NotFoundException($"Categoria con id {id} non trovata.");
        }

        // Non si elimina una categoria che contiene prodotti:
        // 409 Conflict con un messaggio utile invece di cancellare tutto a cascata.
        // (Il DB ha anche OnDelete Restrict: senza questo controllo risponderebbe 500 con errore di FK)
        int numeroProdotti = await _context.Prodotti.CountAsync(p => p.CategoriaId == id);
        if (numeroProdotti > 0)
        {
            return Conflict(new
            {
                message = $"Impossibile eliminare la categoria '{categoria.Nome}': contiene {numeroProdotti} prodotti. Spostali o eliminali prima.",
                dataErrore = DateTime.UtcNow
            });
        }

        _context.Categorie.Remove(categoria);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    // true se esiste gia' una categoria con lo stesso nome (spazi esterni e maiuscole ignorati)
    private async Task<bool> EsisteCategoriaConNome(string nome, int? escludiId = null)
    {
        var nomeNormalizzato = nome.Trim().ToLower();
        return await _context.Categorie.AnyAsync(c =>
            c.Nome.ToLower() == nomeNormalizzato && (escludiId == null || c.Id != escludiId));
    }

    // 409 Conflict con lo stesso formato { message, dataErrore } degli altri errori
    private ConflictObjectResult NomeGiaUsato(string nome)
    {
        return Conflict(new
        {
            message = $"Esiste gia' una categoria chiamata '{nome.Trim()}'.",
            dataErrore = DateTime.UtcNow
        });
    }
}
