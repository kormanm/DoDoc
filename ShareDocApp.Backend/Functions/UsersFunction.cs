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
    private readonly ITaskStore _tasks;
    private readonly IBlobStore _blobs;

    public UsersFunction(
        EntraTokenValidator auth,
        IUserStore users,
        ITaskStore tasks,
        IBlobStore blobs)
    {
        _auth = auth;
        _users = users;
        _tasks = tasks;
        _blobs = blobs;
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
            ConsentConfigured = false,
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
        user.ConsentConfigured = true;
        var updated = await _users.UpsertAsync(user, ct);
        return HttpHelpers.JsonOk(Mappers.ToDto(updated));
    }

    [Function("UsersUpdateProfile")]
    public async Task<IActionResult> UpdateProfile(
        [HttpTrigger(AuthorizationLevel.Anonymous, "put", Route = "users/me")] HttpRequest req,
        CancellationToken ct)
    {
        var authResult = await _auth.ValidateAndGetUserIdAsync(HttpHelpers.GetAuthHeader(req), ct);
        if (!authResult.IsSuccess)
            return HttpHelpers.ToErrorResponse(authResult.Error!);

        var user = await _users.GetAsync(authResult.Value!, ct);
        if (user == null)
            return HttpHelpers.ToErrorResponse(Errors.NotFound("User not found"));

        var body = await req.ReadFromJsonAsync<UpdateProfileRequest>(ct);
        if (body == null)
            return HttpHelpers.ToErrorResponse(Errors.Validation("Invalid request body"));

        user.DisplayName = body.DisplayName.Trim();
        user.Email = body.Email.Trim();
        var updated = await _users.UpsertAsync(user, ct);
        return HttpHelpers.JsonOk(Mappers.ToDto(updated));
    }

    [Function("UsersDeleteMe")]
    public async Task<IActionResult> DeleteMe(
        [HttpTrigger(AuthorizationLevel.Anonymous, "delete", Route = "users/me")] HttpRequest req,
        CancellationToken ct)
    {
        var authResult = await _auth.ValidateAndGetUserIdAsync(HttpHelpers.GetAuthHeader(req), ct);
        if (!authResult.IsSuccess)
            return HttpHelpers.ToErrorResponse(authResult.Error!);

        var userId = authResult.Value!;
        var tasks = await _tasks.GetAllAsync(userId, ct);
        foreach (var task in tasks)
        {
            if (!string.IsNullOrWhiteSpace(task.BlobRef))
                await _blobs.DeleteAsync(task.BlobRef, ct);

            await _tasks.DeleteAsync(userId, task.RowKey, ct);
        }

        var user = await _users.GetAsync(userId, ct);
        if (user != null)
            await _users.DeleteAsync(userId, ct);

        return HttpHelpers.NoContent();
    }
}
