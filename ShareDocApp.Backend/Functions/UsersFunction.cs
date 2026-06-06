using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using ShareDocApp.Backend.Auth;
using ShareDocApp.Backend.Common;
using ShareDocApp.Backend.Models;
using ShareDocApp.Backend.Models.Dtos;
using ShareDocApp.Backend.Storage;

namespace ShareDocApp.Backend.Functions;

public class UsersFunction
{
    private readonly EntraTokenValidator _auth;
    private readonly IUserStore _users;

    public UsersFunction(EntraTokenValidator auth, IUserStore users)
    {
        _auth = auth;
        _users = users;
    }

    [Function("UsersRegister")]
    public async Task<IActionResult> Register(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "users")] HttpRequest req,
        CancellationToken ct)
    {
        var authResult = await _auth.ValidateAndGetUserIdAsync(HttpHelpers.GetAuthHeader(req), ct);
        if (!authResult.IsSuccess)
            return HttpHelpers.ToErrorResponse(authResult.Error!);

        var userId = authResult.Value!;
        var existing = await _users.GetAsync(userId, ct);
        if (existing != null)
            return HttpHelpers.JsonOk(Mappers.ToDto(existing));

        var entity = new UserEntity
        {
            RowKey = userId,
            DisplayName = "",
            Email = "",
            PersistDocs = false,
            CreatedAt = DateTime.UtcNow
        };

        var created = await _users.UpsertAsync(entity, ct);
        return HttpHelpers.JsonOk(Mappers.ToDto(created));
    }

    [Function("UsersGetMe")]
    public async Task<IActionResult> GetMe(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "users/me")] HttpRequest req,
        CancellationToken ct)
    {
        var authResult = await _auth.ValidateAndGetUserIdAsync(HttpHelpers.GetAuthHeader(req), ct);
        if (!authResult.IsSuccess)
            return HttpHelpers.ToErrorResponse(authResult.Error!);

        var user = await _users.GetAsync(authResult.Value!, ct);
        if (user == null)
            return HttpHelpers.ToErrorResponse(Errors.NotFound("User not found"));

        return HttpHelpers.JsonOk(Mappers.ToDto(user));
    }

    [Function("UsersUpdateConsent")]
    public async Task<IActionResult> UpdateConsent(
        [HttpTrigger(AuthorizationLevel.Anonymous, "put", Route = "users/me/consent")] HttpRequest req,
        CancellationToken ct)
    {
        var authResult = await _auth.ValidateAndGetUserIdAsync(HttpHelpers.GetAuthHeader(req), ct);
        if (!authResult.IsSuccess)
            return HttpHelpers.ToErrorResponse(authResult.Error!);

        var userId = authResult.Value!;
        var user = await _users.GetAsync(userId, ct);
        if (user == null)
            return HttpHelpers.ToErrorResponse(Errors.NotFound("User not found"));

        var body = await req.ReadFromJsonAsync<ConsentRequest>(ct);
        if (body == null)
            return HttpHelpers.ToErrorResponse(Errors.Validation("Invalid request body"));

        user.PersistDocs = body.PersistDocs;
        var updated = await _users.UpsertAsync(user, ct);
        return HttpHelpers.JsonOk(Mappers.ToDto(updated));
    }
}
