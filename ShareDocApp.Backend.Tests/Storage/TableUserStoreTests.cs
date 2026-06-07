using Azure.Data.Tables;
using ShareDocApp.Backend.Models;
using ShareDocApp.Backend.Storage;
using Xunit;

namespace ShareDocApp.Backend.Tests.Storage;

public class TableUserStoreTests : IAsyncLifetime
{
    private readonly TableServiceClient _serviceClient;
    private readonly TableUserStore _store;

    public TableUserStoreTests()
    {
        _serviceClient = new TableServiceClient("UseDevelopmentStorage=true");
        _store = new TableUserStore(_serviceClient);
    }

    public Task InitializeAsync() => Task.CompletedTask;

    public async Task DisposeAsync()
    {
        await _serviceClient.DeleteTableAsync("Users");
    }

    [Fact]
    public async Task GetAsync_ReturnsNullForNonexistent()
    {
        var result = await _store.GetAsync("nonexistent", CancellationToken.None);
        Assert.Null(result);
    }

    [Fact]
    public async Task UpsertAsync_CreatesNewUser()
    {
        var entity = new UserEntity
        {
            RowKey = "user-1",
            DisplayName = "Test User",
            Email = "test@example.com",
            PersistDocs = false,
            CreatedAt = DateTime.UtcNow
        };

        var created = await _store.UpsertAsync(entity, CancellationToken.None);
        Assert.Equal("USER", created.PartitionKey);
        Assert.Equal("user-1", created.RowKey);

        var fetched = await _store.GetAsync("user-1", CancellationToken.None);
        Assert.NotNull(fetched);
        Assert.Equal("Test User", fetched.DisplayName);
        Assert.Equal("test@example.com", fetched.Email);
    }

    [Fact]
    public async Task UpsertAsync_IdempotentRegister()
    {
        var entity = new UserEntity
        {
            RowKey = "user-idem",
            DisplayName = "First",
            Email = "first@example.com",
            PersistDocs = false,
            CreatedAt = DateTime.UtcNow
        };

        await _store.UpsertAsync(entity, CancellationToken.None);

        entity.DisplayName = "Second";
        await _store.UpsertAsync(entity, CancellationToken.None);

        var fetched = await _store.GetAsync("user-idem", CancellationToken.None);
        Assert.NotNull(fetched);
        Assert.Equal("Second", fetched.DisplayName);
    }

    [Fact]
    public async Task UpsertAsync_UpdatesConsentFlag()
    {
        var entity = new UserEntity
        {
            RowKey = "user-consent",
            DisplayName = "Consent User",
            Email = "consent@example.com",
            PersistDocs = false,
            CreatedAt = DateTime.UtcNow
        };

        await _store.UpsertAsync(entity, CancellationToken.None);

        entity.PersistDocs = true;
        await _store.UpsertAsync(entity, CancellationToken.None);

        var fetched = await _store.GetAsync("user-consent", CancellationToken.None);
        Assert.NotNull(fetched);
        Assert.True(fetched.PersistDocs);
    }
}
