using ShareDocApp.Backend.Models;

namespace ShareDocApp.Backend.Storage;

public interface ITaskStore
{
    Task<List<TaskEntity>> GetAllAsync(string userId, CancellationToken ct);
    Task<TaskEntity?> GetAsync(string userId, string taskId, CancellationToken ct);
    Task<TaskEntity> CreateAsync(TaskEntity entity, CancellationToken ct);
    Task<TaskEntity> UpdateAsync(TaskEntity entity, CancellationToken ct);
    Task DeleteAsync(string userId, string taskId, CancellationToken ct);
}
