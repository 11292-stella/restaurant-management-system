using BasedSecurityDotnet.Enumeration;

namespace BasedSecurityDotnet.Dtos;

public class UserResponseDto
{
    public int Id { get; set; }
    public required string Nome { get; set; } 
    public required string Cognome { get; set; } 
    public required string Username { get; set; } 
    public required string Email { get; set; }
    public Role Role { get; set; }
}