using Azure;
using Azure.Data.Tables;
using ShareDocApp.Backend.Models;

namespace ShareDocApp.Backend.Storage;

public class TableUserStore : IUserStore
{
    private const string TableName = "Users";
    private readonly TableClient _table;

    public TableUserStore(TableServiceClient serviceClient)
    {
        _table = serviceClient.GetTableClient(TableName);
        _table.CreateIfNotExists();
    }

    public async Task<UserEntity?> GetAsync(string userId, CancellationToken ct)
    {
        try
        {
            var response = await _table.GetEntityAsync<UserEntity>("USER", userId, cancellationToken: ct);
            return response.Value;
        }
        catch (RequestFailedException ex) when (ex.Status == 404)
        {
            return null;
        }
    }

    public async Task<UserEntity> UpsertAsync(UserEntity entity, CancellationToken ct)
    {
        entity.PartitionKey = "USER";
        await _table.UpsertEntityAsync(entity, TableUpdateMode.Replace, ct);
        return entity;
    }

    public async Task DeleteAsync(string userId, CancellationToken ct)
    {
        await _table.DeleteEntityAsync("USER", userId, ETag.All, ct);
    }
}
