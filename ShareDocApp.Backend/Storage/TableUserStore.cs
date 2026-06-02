namespace ShareDocApp.Backend.Storage;

public class TableUserStore : IUserStore
{
    public Task<Models.UserEntity?> GetAsync(string userId, CancellationToken ct) => throw new NotImplementedException();
    public Task<Models.UserEntity> UpsertAsync(Models.UserEntity entity, CancellationToken ct) => throw new NotImplementedException();
}
