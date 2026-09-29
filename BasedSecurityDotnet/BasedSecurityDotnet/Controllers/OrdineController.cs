using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BasedSecurityDotnet.data;
using BasedSecurityDotnet.Dtos;
using BasedSecurityDotnet.Exceptions;
using BasedSecurityDotnet.Enumeration;
using BasedSecurityDotnet.Models;

namespace BasedSecurityDotnet.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class OrdineController : ControllerBase
{
    private readonly AppDbContext _context;

    public OrdineController(AppDbContext context)
    {
        _context = context;
    }

    // GET api/Ordine
    // Include(...) carica anche le OrdineRiga collegate (e il loro Prodotto) in una
    // sola query, altrimenti EF Core per default NON le carica automaticamente
    // (lazy loading disattivato di default: evita query nascoste e sorprese di performance)
    [HttpGet]
    public async Task<ActionResult<IEnumerable<Ordine>>> GetAll()
    {
        var ordini = await _context.Ordini
            .Include(o => o.Righe)
                .ThenInclude(r => r.Prodotto)
            .ToListAsync();

        return Ok(ordini);
    }

    // GET api/Ordine/5
    [HttpGet("{id}")]
    public async Task<ActionResult<Ordine>> GetById(int id)
    {
        var ordine = await _context.Ordini
            .Include(o => o.Righe)
                .ThenInclude(r => r.Prodotto)
            .FirstOrDefaultAsync(o => o.Id == id);

        if (ordine == null)
        {
            throw new NotFoundException($"Ordine con id {id} non trovato.");
        }

        return Ok(ordine);
    }

    // POST api/Ordine
    // Qui la parte nuova: creiamo l'Ordine E le sue OrdineRiga in un solo colpo,
    // partendo da una lista di {ProdottoId, Quantita} mandata dal client.
    [HttpPost]
    public async Task<ActionResult<Ordine>> Create(OrdineCreateDto dto)
    {
        var ordine = new Ordine
        {
            Cliente = dto.Cliente,
            DataOra = DateTime.UtcNow,
            StatoOrdine = StatoOrdine.IN_ATTESA,
            Totale = 0 // lo calcoliamo sotto, sommando le righe
        };

        decimal totale = 0;
        var righe = new List<OrdineRiga>();

        foreach (var rigaDto in dto.Righe)
        {
            var prodotto = await _context.Prodotti.FindAsync(rigaDto.ProdottoId);

            if (prodotto == null)
            {
                throw new NotFoundException($"Prodotto con id {rigaDto.ProdottoId} non trovato.");
            }

            if (!prodotto.Attivo || prodotto.Esaurito)
            {
                throw new BadRequestException($"Il prodotto '{prodotto.Nome}' non è disponibile.");
            }

            // Il prezzo lo "fotografiamo" ORA dal prodotto (PrezzoUnitario),
            // così se in futuro il prezzo del prodotto cambia, questo ordine
            // storico resta corretto con il prezzo pagato in quel momento.
            var riga = new OrdineRiga
            {
                Ordine = ordine,
                Prodotto = prodotto,
                ProdottoId = prodotto.Id,
                Quantita = rigaDto.Quantita,
                PrezzoUnitario = prodotto.Prezzo
            };

            righe.Add(riga);
            totale += prodotto.Prezzo * rigaDto.Quantita;
        }

        ordine.Totale = totale;

        _context.Ordini.Add(ordine);
        _context.OrdineRighe.AddRange(righe);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = ordine.Id }, ordine);
    }

    // PUT api/Ordine/5/stato
    // Endpoint separato solo per cambiare stato (es. "InPreparazione" -> "Pronto"),
    // più realistico di un PUT generico: di solito chi aggiorna un ordine in cucina
    // cambia solo lo stato, non riscrive cliente/righe.
    [HttpPut("{id}/stato")]
    public async Task<IActionResult> AggiornaStato(int id, [FromBody] StatoOrdine nuovoStato)
    {
        // Un enum in C# accetta QUALSIASI intero: senza questo controllo PUT con body 99
        // salvava uno stato inesistente e la UI mostrava una riga senza etichetta.
        // (Bug trovato scrivendo i test sugli stati dell'ordine)
        if (!Enum.IsDefined(nuovoStato))
        {
            throw new BadRequestException($"Stato ordine non valido: {(int)nuovoStato}.");
        }

        var ordine = await _context.Ordini.FindAsync(id);

        if (ordine == null)
        {
            throw new NotFoundException($"Ordine con id {id} non trovato.");
        }

        ordine.StatoOrdine = nuovoStato;
        await _context.SaveChangesAsync();

        return NoContent();
    }

    // DELETE api/Ordine/5
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var ordine = await _context.Ordini.FindAsync(id);

        if (ordine == null)
        {
            throw new NotFoundException($"Ordine con id {id} non trovato.");
        }

        // Un ordine con scontrino emesso non si elimina: il cascade (convenzione EF su FK
        // obbligatoria) cancellerebbe in silenzio anche lo scontrino, cioe' un documento fiscale.
        // Stesso schema di categoria/prodotto: 409 con messaggio, prima va annullato lo scontrino.
        bool haScontrino = await _context.Scontrini.AnyAsync(s => s.OrdineId == id);
        if (haScontrino)
        {
            return Conflict(new
            {
                message = $"Impossibile eliminare l'ordine {id}: ha gia' uno scontrino emesso. Elimina prima lo scontrino.",
                dataErrore = DateTime.UtcNow
            });
        }

        // OnDelete(Cascade) sulle FK di OrdineRiga fa sì che eliminando l'Ordine
        // vengano eliminate in automatico anche le sue righe collegate.
        _context.Ordini.Remove(ordine);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}
