using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BasedSecurityDotnet.data;
using BasedSecurityDotnet.Dtos;
using BasedSecurityDotnet.Exceptions;
using BasedSecurityDotnet.Models;
using BasedSecurityDotnet.Enumeration;

namespace BasedSecurityDotnet.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ScontrinoController : ControllerBase
{
    private readonly AppDbContext _context;

    public ScontrinoController(AppDbContext context)
    {
        _context = context;
    }

    // GET api/Scontrino
    [HttpGet]
    public async Task<ActionResult<IEnumerable<Scontrino>>> GetAll()
    {
        var scontrini = await _context.Scontrini
            .Include(s => s.Ordine)
            .ToListAsync();

        return Ok(scontrini);
    }

    // GET api/Scontrino/5
    [HttpGet("{id}")]
    public async Task<ActionResult<Scontrino>> GetById(int id)
    {
        var scontrino = await _context.Scontrini
            .Include(s => s.Ordine)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (scontrino == null)
        {
            throw new NotFoundException($"Scontrino con id {id} non trovato.");
        }

        return Ok(scontrino);
    }

    // GET api/Scontrino/ordine/5
    // Comodo per il frontend: "questo ordine ha già uno scontrino?"
    [HttpGet("ordine/{ordineId}")]
    public async Task<ActionResult<Scontrino>> GetByOrdineId(int ordineId)
    {
        var scontrino = await _context.Scontrini
            .Include(s => s.Ordine)
            .FirstOrDefaultAsync(s => s.OrdineId == ordineId);

        if (scontrino == null)
        {
            throw new NotFoundException($"Nessuno scontrino trovato per l'ordine {ordineId}.");
        }

        return Ok(scontrino);
    }

    // POST api/Scontrino
    // Emette lo scontrino per un ordine esistente. L'Importo NON arriva dal
    // client (il DTO non lo prevede): lo calcoliamo qui dal Totale reale
    // dell'ordine, così non è manipolabile dal frontend.
    [HttpPost]
    public async Task<ActionResult<Scontrino>> Create(ScontrinoDto dto)
    {
        var ordine = await _context.Ordini.FindAsync(dto.OrdineId);

        if (ordine == null)
        {
            throw new NotFoundException($"Ordine con id {dto.OrdineId} non trovato.");
        }

        // Il vincolo "uno scontrino per ordine" esiste già a livello DB
        // (indice unico su OrdineId), ma controllarlo qui prima permette
        // di rispondere con un 400 chiaro invece di un errore SQL generico
        // che il GlobalExceptionMiddleware tradurrebbe in un 500 anonimo.
        // Un ordine annullato non e' una vendita: niente scontrino.
        // (Prima veniva emesso lo stesso. Bug trovato dal test E2E "Ordine Annullato Non Permette Lo Scontrino")
        if (ordine.StatoOrdine == StatoOrdine.ANNULLATO)
        {
            throw new BadRequestException($"L'ordine {dto.OrdineId} e' annullato: non si puo' emettere lo scontrino.");
        }

        bool esisteGia = await _context.Scontrini.AnyAsync(s => s.OrdineId == dto.OrdineId);
        if (esisteGia)
        {
            throw new BadRequestException($"L'ordine {dto.OrdineId} ha già uno scontrino emesso.");
        }

        var scontrino = new Scontrino
        {
            OrdineId = ordine.Id,
            Ordine = ordine,
            DataEmissione = DateTime.UtcNow,
            Importo = ordine.Totale,
            MetodoPagamento = dto.MetodoPagamento
        };

        _context.Scontrini.Add(scontrino);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = scontrino.Id }, scontrino);
    }

    // DELETE api/Scontrino/5
    // Da usare con cautela: uno scontrino emesso normalmente non si elimina
    // (implicazioni fiscali nella realtà), ma utile in un progetto didattico
    // per poter "annullare" un test.
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var scontrino = await _context.Scontrini.FindAsync(id);

        if (scontrino == null)
        {
            throw new NotFoundException($"Scontrino con id {id} non trovato.");
        }

        _context.Scontrini.Remove(scontrino);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}
