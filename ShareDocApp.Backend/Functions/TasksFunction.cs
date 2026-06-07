using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using ShareDocApp.Backend.Auth;
using ShareDocApp.Backend.Common;
using ShareDocApp.Backend.Models.Dtos;
using ShareDocApp.Backend.Storage;

namespace ShareDocApp.Backend.Functions;

public class TasksFunction
{
    private readonly EntraTokenValidator _auth;
    private readonly ITaskStore _tasks;

    public TasksFunction(EntraTokenValidator auth, ITaskStore tasks)
    {
        _auth = auth;
        _tasks = tasks;
    }

    [Function("TasksList")]
    public async Task<IActionResult> List(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "tasks")] HttpRequest req,
        CancellationToken ct)
    {
        var authResult = await _auth.ValidateAndGetUserIdAsync(HttpHelpers.GetAuthHeader(req), ct);
        if (!authResult.IsSuccess)
            return HttpHelpers.ToErrorResponse(authResult.Error!);

        var entities = await _tasks.GetAllAsync(authResult.Value!, ct);
        var dtos = entities.Select(Mappers.ToDto).ToList();
        return HttpHelpers.JsonOk(dtos);
    }

    [Function("TasksCreate")]
    public async Task<IActionResult> Create(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "tasks")] HttpRequest req,
        CancellationToken ct)
    {
        var authResult = await _auth.ValidateAndGetUserIdAsync(HttpHelpers.GetAuthHeader(req), ct);
        if (!authResult.IsSuccess)
            return HttpHelpers.ToErrorResponse(authResult.Error!);

        var userId = authResult.Value!;
        var dto = await req.ReadFromJsonAsync<TaskDto>(ct);
        if (dto == null)
            return HttpHelpers.ToErrorResponse(Errors.Validation("Invalid request body"));
        if (string.IsNullOrWhiteSpace(dto.Title))
            return HttpHelpers.ToErrorResponse(Errors.Validation("Title is required"));

        var entity = Mappers.ToEntity(dto, userId);
        var created = await _tasks.CreateAsync(entity, ct);
        return new ObjectResult(Mappers.ToDto(created)) { StatusCode = 201 };
    }

    [Function("TasksUpdate")]
    public async Task<IActionResult> Update(
        [HttpTrigger(AuthorizationLevel.Anonymous, "put", Route = "tasks/{id}")] HttpRequest req,
        string id,
        CancellationToken ct)
    {
        var authResult = await _auth.ValidateAndGetUserIdAsync(HttpHelpers.GetAuthHeader(req), ct);
        if (!authResult.IsSuccess)
            return HttpHelpers.ToErrorResponse(authResult.Error!);

        var userId = authResult.Value!;
        var existing = await _tasks.GetAsync(userId, id, ct);
        if (existing == null)
            return HttpHelpers.ToErrorResponse(Errors.NotFound("Task not found"));

        var dto = await req.ReadFromJsonAsync<TaskDto>(ct);
        if (dto == null)
            return HttpHelpers.ToErrorResponse(Errors.Validation("Invalid request body"));
        if (string.IsNullOrWhiteSpace(dto.Title))
            return HttpHelpers.ToErrorResponse(Errors.Validation("Title is required"));

        var entity = Mappers.ToEntity(dto, userId);
        entity.RowKey = id;
        entity.CreatedAt = existing.CreatedAt;
        var updated = await _tasks.UpdateAsync(entity, ct);
        return HttpHelpers.JsonOk(Mappers.ToDto(updated));
    }

    [Function("TasksDelete")]
    public async Task<IActionResult> Delete(
        [HttpTrigger(AuthorizationLevel.Anonymous, "delete", Route = "tasks/{id}")] HttpRequest req,
        string id,
        CancellationToken ct)
    {
        var authResult = await _auth.ValidateAndGetUserIdAsync(HttpHelpers.GetAuthHeader(req), ct);
        if (!authResult.IsSuccess)
            return HttpHelpers.ToErrorResponse(authResult.Error!);

        var userId = authResult.Value!;
        var existing = await _tasks.GetAsync(userId, id, ct);
        if (existing == null)
            return HttpHelpers.ToErrorResponse(Errors.NotFound("Task not found"));

        await _tasks.DeleteAsync(userId, id, ct);
        return HttpHelpers.NoContent();
    }
}
