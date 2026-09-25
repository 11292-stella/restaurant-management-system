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
        var categoria = new Categoria
        {
            Nome = dto.Nome,
            Descrizione = dto.Descrizione
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

        categoria.Nome = dto.Nome;
        categoria.Descrizione = dto.Descrizione;

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

        _context.Categorie.Remove(categoria);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}
