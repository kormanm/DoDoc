using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.IdentityModel.Tokens;
using ShareDocApp.Backend.Auth;
using ShareDocApp.Backend.Common;

namespace ShareDocApp.Backend.Tests.Functions;

internal static class TestAuth
{
    public static EntraTokenValidator CreateValidator(string userId)
    {
        return new StubTokenValidator(userId);
    }

    public static EntraTokenValidator CreateFailingValidator()
    {
        return new StubTokenValidator(null);
    }

    public static HttpRequest CreateRequest(string method)
    {
        var context = new DefaultHttpContext();
        context.Request.Method = method;
        context.Request.Headers.Authorization = "Bearer valid-token";
        return context.Request;
    }

    public static HttpRequest CreateRequestWithoutAuth(string method)
    {
        var context = new DefaultHttpContext();
        context.Request.Method = method;
        return context.Request;
    }

    public static HttpRequest CreateJsonRequest<T>(string method, T body)
    {
        var json = JsonSerializer.Serialize(body, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });
        var context = new DefaultHttpContext();
        context.Request.Method = method;
        context.Request.Headers.Authorization = "Bearer valid-token";
        context.Request.ContentType = "application/json";
        context.Request.Body = new MemoryStream(Encoding.UTF8.GetBytes(json));
        return context.Request;
    }
}

internal class StubTokenValidator : EntraTokenValidator
{
    private readonly string? _userId;

    public StubTokenValidator(string? userId)
        : base("stub-issuer", "stub-audience", new TokenValidationParameters())
    {
        _userId = userId;
    }

    public override Task<Result<string>> ValidateAndGetUserIdAsync(string? authHeader, CancellationToken ct)
    {
        if (_userId == null || string.IsNullOrEmpty(authHeader))
            return Task.FromResult<Result<string>>(Errors.Auth("Unauthorized"));

        return Task.FromResult<Result<string>>(_userId);
    }
}
