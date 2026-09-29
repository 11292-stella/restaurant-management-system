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
public class ProdottoController : ControllerBase
{
    private readonly AppDbContext _context;
    public ProdottoController(AppDbContext context)
    {
        _context = context;
    }

    // GET api/Prodotto
    [HttpGet]
    public async Task<ActionResult<IEnumerable<Prodotto>>> GetAll()
    {
        var prodotti = await _context.Prodotti.ToListAsync();
        return Ok(prodotti);
    }

    // GET api/Prodotto/5
    [HttpGet("{id}")]
    public async Task<ActionResult<Prodotto>> GetById(int id)
    {
        var prodotto = await _context.Prodotti.FindAsync(id);

        if (prodotto == null)
        {
            throw new NotFoundException($"Prodotto con id {id} non trovato.");
        }

        return Ok(prodotto);
    }

    // POST api/Prodotto
    [HttpPost]
    public async Task<ActionResult<Prodotto>> Create(ProdottoDto dto)
    {
        var categoria = await _context.Categorie.FindAsync(dto.CategoriaId);

        if (categoria == null)
        {
            throw new NotFoundException($"Categoria con id {dto.CategoriaId} non trovata.");
        }

        var prodotto = new Prodotto
        {
            // Trim sui testi; descrizione facoltativa (colonna non nullable -> stringa vuota);
            // URL immagine vuoto -> null (la lista mostra il placeholder)
            Nome = dto.Nome.Trim(),
            Descrizione = dto.Descrizione?.Trim() ?? string.Empty,
            Prezzo = dto.Prezzo,
            CostoProduzione = dto.CostoProduzione,
            ImmagineUrl = string.IsNullOrWhiteSpace(dto.ImmagineUrl) ? null : dto.ImmagineUrl.Trim(),
            Attivo = dto.Attivo,
            Esaurito = dto.Esaurito,
            CategoriaId = dto.CategoriaId,
            Categoria = categoria
        };

        _context.Prodotti.Add(prodotto);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = prodotto.Id }, prodotto);
    }

    // PUT api/Prodotto/5
    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, ProdottoDto dto)
    {
        var prodotto = await _context.Prodotti.FindAsync(id);

        if (prodotto == null)
        {
            throw new NotFoundException($"Prodotto con id {id} non trovato.");
        }

        var categoria = await _context.Categorie.FindAsync(dto.CategoriaId);
        if (categoria == null)
        {
            throw new NotFoundException($"Categoria con id {dto.CategoriaId} non trovata.");
        }

        prodotto.Nome = dto.Nome.Trim();
        prodotto.Descrizione = dto.Descrizione?.Trim() ?? string.Empty;
        prodotto.Prezzo = dto.Prezzo;
        prodotto.CostoProduzione = dto.CostoProduzione;
        prodotto.ImmagineUrl = string.IsNullOrWhiteSpace(dto.ImmagineUrl) ? null : dto.ImmagineUrl.Trim();
        prodotto.Attivo = dto.Attivo;
        prodotto.Esaurito = dto.Esaurito;
        prodotto.CategoriaId = dto.CategoriaId;

        await _context.SaveChangesAsync();

        return NoContent();
    }

    // DELETE api/Prodotto/5
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var prodotto = await _context.Prodotti.FindAsync(id);

        if (prodotto == null)
        {
            throw new NotFoundException($"Prodotto con id {id} non trovato.");
        }

        // Un prodotto presente in ordini passati non si elimina (rovinerebbe lo storico ordini/scontrini):
        // meglio disattivarlo (Attivo = false), cosi' sparisce dal menu ma gli ordini restano corretti.
        // (Il DB ha anche OnDelete Restrict su OrdineRiga -> Prodotto: senza questo controllo darebbe 500)
        bool giaOrdinato = await _context.OrdineRighe.AnyAsync(r => r.ProdottoId == id);
        if (giaOrdinato)
        {
            return Conflict(new
            {
                message = $"Impossibile eliminare '{prodotto.Nome}': e' presente in ordini gia' effettuati. Disattivalo invece di eliminarlo.",
                dataErrore = DateTime.UtcNow
            });
        }

        _context.Prodotti.Remove(prodotto);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}