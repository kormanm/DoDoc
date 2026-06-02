using Azure.Data.Tables;
using ShareDocApp.Backend.Models;
using ShareDocApp.Backend.Storage;
using Xunit;

namespace ShareDocApp.Backend.Tests.Storage;

public class TableTaskStoreTests : IAsyncLifetime
{
    private readonly TableServiceClient _serviceClient;
    private readonly TableTaskStore _store;
    private const string UserId = "test-user-1";
    private const string OtherUserId = "test-user-2";

    public TableTaskStoreTests()
    {
        _serviceClient = new TableServiceClient("UseDevelopmentStorage=true");
        _store = new TableTaskStore(_serviceClient);
    }

    public Task InitializeAsync() => Task.CompletedTask;

    public async Task DisposeAsync()
    {
        await _serviceClient.DeleteTableAsync("Tasks");
    }

    private static TaskEntity MakeTask(string userId, string title = "Test task") => new()
    {
        PartitionKey = userId,
        Title = title,
        Summary = "Test summary",
        DocumentName = "doc.pdf",
        SourceMime = "application/pdf",
        Severity = 1,
        Status = 0,
        Steps = "[]",
        Phones = "[]",
        AiConfidence = 0.9
    };

    [Fact]
    public async Task Create_AssignsRowKeyAndTimestamps()
    {
        var entity = MakeTask(UserId);
        var created = await _store.CreateAsync(entity, CancellationToken.None);

        Assert.False(string.IsNullOrEmpty(created.RowKey));
        Assert.True(Guid.TryParse(created.RowKey, out _));
        Assert.True(created.CreatedAt > DateTime.MinValue);
        Assert.Equal(created.CreatedAt, created.UpdatedAt);
    }

    [Fact]
    public async Task GetAll_ReturnsOnlyUserTasks()
    {
        await _store.CreateAsync(MakeTask(UserId, "A"), CancellationToken.None);
        await _store.CreateAsync(MakeTask(UserId, "B"), CancellationToken.None);
        await _store.CreateAsync(MakeTask(OtherUserId, "C"), CancellationToken.None);

        var userTasks = await _store.GetAllAsync(UserId, CancellationToken.None);
        var otherTasks = await _store.GetAllAsync(OtherUserId, CancellationToken.None);

        Assert.Equal(2, userTasks.Count);
        Assert.Single(otherTasks);
        Assert.All(userTasks, t => Assert.Equal(UserId, t.PartitionKey));
    }

    [Fact]
    public async Task Get_ReturnsNullForNonexistent()
    {
        var result = await _store.GetAsync(UserId, Guid.NewGuid().ToString(), CancellationToken.None);
        Assert.Null(result);
    }

    [Fact]
    public async Task Get_ReturnsNullForWrongUser()
    {
        var created = await _store.CreateAsync(MakeTask(UserId), CancellationToken.None);

        var result = await _store.GetAsync(OtherUserId, created.RowKey, CancellationToken.None);
        Assert.Null(result);
    }

    [Fact]
    public async Task CrudRoundTrip()
    {
        var entity = MakeTask(UserId, "Original");
        var created = await _store.CreateAsync(entity, CancellationToken.None);
        Assert.Equal("Original", created.Title);

        var fetched = await _store.GetAsync(UserId, created.RowKey, CancellationToken.None);
        Assert.NotNull(fetched);
        Assert.Equal("Original", fetched.Title);

        fetched.Title = "Updated";
        var updated = await _store.UpdateAsync(fetched, CancellationToken.None);
        Assert.Equal("Updated", updated.Title);
        Assert.True(updated.UpdatedAt >= created.UpdatedAt);

        await _store.DeleteAsync(UserId, created.RowKey, CancellationToken.None);
        var deleted = await _store.GetAsync(UserId, created.RowKey, CancellationToken.None);
        Assert.Null(deleted);
    }

    [Fact]
    public async Task OwnerIsolation_CannotUpdateOtherUsersTask()
    {
        var created = await _store.CreateAsync(MakeTask(UserId), CancellationToken.None);

        var tamperedEntity = MakeTask(OtherUserId, "Hacked");
        tamperedEntity.RowKey = created.RowKey;

        await Assert.ThrowsAsync<Azure.RequestFailedException>(() =>
            _store.UpdateAsync(tamperedEntity, CancellationToken.None));
    }

    [Fact]
    public async Task OwnerIsolation_CannotDeleteOtherUsersTask()
    {
        var created = await _store.CreateAsync(MakeTask(UserId), CancellationToken.None);

        await Assert.ThrowsAsync<Azure.RequestFailedException>(() =>
            _store.DeleteAsync(OtherUserId, created.RowKey, CancellationToken.None));
    }
}
