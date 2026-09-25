namespace BasedSecurityDotnet.Dtos;

public class ApiError
{
    public string Message {get; set;} = string.Empty;
    public DateTime DataErrore { get; set; } = DateTime.UtcNow;

    //Costruttore vuoto
    public ApiError() {}

    // Costruttore di comodo
    public ApiError(string message)
    {
        Message = message;
        DataErrore = DateTime.UtcNow;
    }

}
