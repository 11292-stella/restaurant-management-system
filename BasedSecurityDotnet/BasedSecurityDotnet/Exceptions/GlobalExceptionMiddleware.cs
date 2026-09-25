using System.Net;
using System.Text.Json;
using BasedSecurityDotnet.Dtos;

namespace BasedSecurityDotnet.Exceptions;

public class GlobalExceptionMiddleware
{
    private readonly RequestDelegate _next;

    public GlobalExceptionMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            await HandleExceptionAsync(context, ex);
        }
    }

    private static Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        Console.WriteLine("=== ERRORE NON GESTITO ===");
        Console.WriteLine(exception.ToString());
        Console.WriteLine("===========================");

        context.Response.ContentType = "application/json";

        var (statusCode, message) = exception switch
        {
            NotFoundException => (HttpStatusCode.NotFound, exception.Message),
            UnAuthorizedException => (HttpStatusCode.Unauthorized, exception.Message),
            BadRequestException => (HttpStatusCode.BadRequest, exception.Message),
            _ => (HttpStatusCode.InternalServerError, "Si è verificato un errore interno del server.")
        };

        context.Response.StatusCode = (int)statusCode;

        var apiError = new ApiError(message);

        var jsonResponse = JsonSerializer.Serialize(apiError, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });

        return context.Response.WriteAsync(jsonResponse);
    }
}