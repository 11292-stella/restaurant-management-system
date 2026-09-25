using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BasedSecurityDotnet.data;
using BasedSecurityDotnet.Dtos;
using BasedSecurityDotnet.Models;
using BasedSecurityDotnet.Services;
using BasedSecurityDotnet.Exceptions;

namespace BasedSecurityDotnet.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly JwtService _jwtService;

    public AuthController(AppDbContext context, JwtService jwtService)
    {
        _context = context;
        _jwtService = jwtService;
    }

    [HttpPost("register")]
    public async Task<ActionResult<AuthResponseDto>> Register(RegisterDto dto)
    {
        bool usernameEsiste = await _context.Users.AnyAsync(u => u.Username == dto.Username);
        if (usernameEsiste)
        {
            throw new BadRequestException("Username già in uso.");
        }

        var user = new User
        {
            Nome = dto.Nome,
            Cognome = dto.Cognome,
            Username = dto.Username,
            Email = dto.Email,
            Password = BCrypt.Net.BCrypt.HashPassword(dto.Password),
            Role = dto.Role
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        var token = _jwtService.GenerateToken(user);

        return Ok(new AuthResponseDto
        {
            Token = token,
            User = new UserResponseDto
            {
                Id = user.Id,
                Nome = user.Nome,
                Cognome = user.Cognome,
                Username = user.Username,
                Email = user.Email,
                Role = user.Role
            }
        });
    }

    [HttpPost("login")]
    public async Task<ActionResult<AuthResponseDto>> Login(LoginDto dto)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Username == dto.Username);

        if (user == null || !BCrypt.Net.BCrypt.Verify(dto.Password, user.Password))
        {
            throw new UnAuthorizedException("Username o password non corretti.");
        }

        var token = _jwtService.GenerateToken(user);

        return Ok(new AuthResponseDto
        {
            Token = token,
            User = new UserResponseDto
            {
                Id = user.Id,
                Nome = user.Nome,
                Cognome = user.Cognome,
                Username = user.Username,
                Email = user.Email,
                Role = user.Role
            }
        });
    }
}