using System.Net;
using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace ShareDocApp.Backend.Common;

public static class HttpHelpers
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    };

    public static string? GetAuthHeader(HttpRequest request)
    {
        return request.Headers.Authorization.FirstOrDefault();
    }

    public static IActionResult ToErrorResponse(Error error)
    {
        var envelope = new
        {
            error = new
            {
                type = error.Type,
                message = error.Message,
                traceId = Guid.NewGuid().ToString()
            }
        };

        return new ObjectResult(envelope) { StatusCode = error.StatusCode };
    }

    public static IActionResult JsonOk(object value)
    {
        return new OkObjectResult(value);
    }

    public static IActionResult NoContent()
    {
        return new StatusCodeResult((int)HttpStatusCode.NoContent);
    }
}
