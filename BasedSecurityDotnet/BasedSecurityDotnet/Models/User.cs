using BasedSecurityDotnet.Enumeration;

namespace BasedSecurityDotnet.Models;

public class User
{
    public int Id {get; set;}
    public required string Nome {get; set;}
    public required string Cognome {get; set;}
    public required string Username {get; set;}
    public required string Password {get; set;}
    public required string Email {get; set;}

    public Role Role {get; set;}
}