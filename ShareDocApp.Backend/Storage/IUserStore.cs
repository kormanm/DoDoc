using ShareDocApp.Backend.Models;

namespace ShareDocApp.Backend.Storage;

public interface IUserStore
{
    Task<UserEntity?> GetAsync(string userId, CancellationToken ct);
    Task<UserEntity> UpsertAsync(UserEntity entity, CancellationToken ct);
}
