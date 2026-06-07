using Azure;
using Azure.Data.Tables;
using ShareDocApp.Backend.Models;

namespace ShareDocApp.Backend.Storage;

public class TableTaskStore : ITaskStore
{
    private const string TableName = "Tasks";
    private readonly TableClient _table;

    public TableTaskStore(TableServiceClient serviceClient)
    {
        _table = serviceClient.GetTableClient(TableName);
        _table.CreateIfNotExists();
    }

    public async Task<List<TaskEntity>> GetAllAsync(string userId, CancellationToken ct)
    {
        var results = new List<TaskEntity>();
        await foreach (var entity in _table.QueryAsync<TaskEntity>(
            e => e.PartitionKey == userId, cancellationToken: ct))
        {
            results.Add(entity);
        }
        return results;
    }

    public async Task<TaskEntity?> GetAsync(string userId, string taskId, CancellationToken ct)
    {
        try
        {
            var response = await _table.GetEntityAsync<TaskEntity>(userId, taskId, cancellationToken: ct);
            return response.Value;
        }
        catch (RequestFailedException ex) when (ex.Status == 404)
        {
            return null;
        }
    }

    public async Task<TaskEntity> CreateAsync(TaskEntity entity, CancellationToken ct)
    {
        entity.RowKey = Guid.NewGuid().ToString();
        entity.CreatedAt = DateTime.UtcNow;
        entity.UpdatedAt = DateTime.UtcNow;
        await _table.AddEntityAsync(entity, ct);
        return entity;
    }

    public async Task<TaskEntity> UpdateAsync(TaskEntity entity, CancellationToken ct)
    {
        entity.UpdatedAt = DateTime.UtcNow;
        await _table.UpdateEntityAsync(entity, ETag.All, TableUpdateMode.Replace, ct);
        return entity;
    }

    public async Task DeleteAsync(string userId, string taskId, CancellationToken ct)
    {
        await _table.DeleteEntityAsync(userId, taskId, ETag.All, ct);
    }
}
