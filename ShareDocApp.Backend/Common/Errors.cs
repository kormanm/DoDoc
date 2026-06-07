namespace ShareDocApp.Backend.Common;

public record Error(string Type, string Message, int StatusCode);

public static class Errors
{
    public static Error Validation(string message) => new("validation", message, 400);
    public static Error Auth(string message) => new("auth", message, 401);
    public static Error NotFound(string message) => new("notFound", message, 404);
    public static Error Server(string message) => new("server", message, 500);
}
