using Microsoft.AspNetCore.Mvc;
using Moq;
using ShareDocApp.Backend.Auth;
using ShareDocApp.Backend.Common;
using ShareDocApp.Backend.Functions;
using ShareDocApp.Backend.Models;
using ShareDocApp.Backend.Models.Dtos;
using ShareDocApp.Backend.Storage;
using Xunit;

namespace ShareDocApp.Backend.Tests.Functions;

public class TasksFunctionTests
{
    private readonly Mock<ITaskStore> _taskStore = new();
    private readonly TasksFunction _func;
    private const string UserId = "user-abc";
    private const string OtherUserId = "user-xyz";

    public TasksFunctionTests()
    {
        var auth = TestAuth.CreateValidator(UserId);
        _func = new TasksFunction(auth, _taskStore.Object);
    }

    [Fact]
    public async Task List_ReturnsUserTasks()
    {
        var entities = new List<TaskEntity>
        {
            new() { PartitionKey = UserId, RowKey = "t1", Title = "Task 1", Steps = "[]", Phones = "[]" },
            new() { PartitionKey = UserId, RowKey = "t2", Title = "Task 2", Steps = "[]", Phones = "[]" }
        };
        _taskStore.Setup(s => s.GetAllAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(entities);

        var req = TestAuth.CreateRequest("GET");
        var result = await _func.List(req, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var dtos = Assert.IsType<List<TaskDto>>(ok.Value);
        Assert.Equal(2, dtos.Count);
    }

    [Fact]
    public async Task Create_ValidTask_Returns201()
    {
        _taskStore.Setup(s => s.CreateAsync(It.IsAny<TaskEntity>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((TaskEntity e, CancellationToken _) =>
            {
                e.RowKey = "new-id";
                e.CreatedAt = DateTime.UtcNow;
                e.UpdatedAt = DateTime.UtcNow;
                return e;
            });

        var dto = new TaskDto { Title = "New task", Summary = "Summary", Steps = "[]", Phones = "[]" };
        var req = TestAuth.CreateJsonRequest("POST", dto);
        var result = await _func.Create(req, CancellationToken.None);

        var obj = Assert.IsType<ObjectResult>(result);
        Assert.Equal(201, obj.StatusCode);
        var created = Assert.IsType<TaskDto>(obj.Value);
        Assert.Equal("new-id", created.Id);
    }

    [Fact]
    public async Task Create_EmptyTitle_Returns400()
    {
        var dto = new TaskDto { Title = "", Steps = "[]", Phones = "[]" };
        var req = TestAuth.CreateJsonRequest("POST", dto);
        var result = await _func.Create(req, CancellationToken.None);

        var obj = Assert.IsType<ObjectResult>(result);
        Assert.Equal(400, obj.StatusCode);
    }

    [Fact]
    public async Task Update_NonexistentTask_Returns404()
    {
        _taskStore.Setup(s => s.GetAsync(UserId, "no-such-id", It.IsAny<CancellationToken>()))
            .ReturnsAsync((TaskEntity?)null);

        var dto = new TaskDto { Title = "Updated", Steps = "[]", Phones = "[]" };
        var req = TestAuth.CreateJsonRequest("PUT", dto);
        var result = await _func.Update(req, "no-such-id", CancellationToken.None);

        var obj = Assert.IsType<ObjectResult>(result);
        Assert.Equal(404, obj.StatusCode);
    }

    [Fact]
    public async Task Update_ExistingTask_ReturnsUpdated()
    {
        var existing = new TaskEntity
        {
            PartitionKey = UserId, RowKey = "t1", Title = "Old",
            CreatedAt = DateTime.UtcNow.AddDays(-1), Steps = "[]", Phones = "[]"
        };
        _taskStore.Setup(s => s.GetAsync(UserId, "t1", It.IsAny<CancellationToken>()))
            .ReturnsAsync(existing);
        _taskStore.Setup(s => s.UpdateAsync(It.IsAny<TaskEntity>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((TaskEntity e, CancellationToken _) =>
            {
                e.UpdatedAt = DateTime.UtcNow;
                return e;
            });

        var dto = new TaskDto { Title = "Updated", Steps = "[]", Phones = "[]" };
        var req = TestAuth.CreateJsonRequest("PUT", dto);
        var result = await _func.Update(req, "t1", CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var updated = Assert.IsType<TaskDto>(ok.Value);
        Assert.Equal("Updated", updated.Title);
        Assert.Equal(existing.CreatedAt, updated.CreatedAt);
    }

    [Fact]
    public async Task Delete_NonexistentTask_Returns404()
    {
        _taskStore.Setup(s => s.GetAsync(UserId, "nope", It.IsAny<CancellationToken>()))
            .ReturnsAsync((TaskEntity?)null);

        var req = TestAuth.CreateRequest("DELETE");
        var result = await _func.Delete(req, "nope", CancellationToken.None);

        var obj = Assert.IsType<ObjectResult>(result);
        Assert.Equal(404, obj.StatusCode);
    }

    [Fact]
    public async Task Delete_ExistingTask_Returns204()
    {
        _taskStore.Setup(s => s.GetAsync(UserId, "t1", It.IsAny<CancellationToken>()))
            .ReturnsAsync(new TaskEntity { PartitionKey = UserId, RowKey = "t1", Steps = "[]", Phones = "[]" });
        _taskStore.Setup(s => s.DeleteAsync(UserId, "t1", It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        var req = TestAuth.CreateRequest("DELETE");
        var result = await _func.Delete(req, "t1", CancellationToken.None);

        var status = Assert.IsType<StatusCodeResult>(result);
        Assert.Equal(204, status.StatusCode);
    }

    [Fact]
    public async Task List_NoAuth_Returns401()
    {
        var auth = TestAuth.CreateFailingValidator();
        var func = new TasksFunction(auth, _taskStore.Object);
        var req = TestAuth.CreateRequestWithoutAuth("GET");

        var result = await func.List(req, CancellationToken.None);

        var obj = Assert.IsType<ObjectResult>(result);
        Assert.Equal(401, obj.StatusCode);
    }
}
