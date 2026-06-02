namespace ShareDocApp.Backend.Storage;

public class TableTaskStore : ITaskStore
{
    public Task<List<Models.TaskEntity>> GetAllAsync(string userId, CancellationToken ct) => throw new NotImplementedException();
    public Task<Models.TaskEntity?> GetAsync(string userId, string taskId, CancellationToken ct) => throw new NotImplementedException();
    public Task<Models.TaskEntity> CreateAsync(Models.TaskEntity entity, CancellationToken ct) => throw new NotImplementedException();
    public Task<Models.TaskEntity> UpdateAsync(Models.TaskEntity entity, CancellationToken ct) => throw new NotImplementedException();
    public Task DeleteAsync(string userId, string taskId, CancellationToken ct) => throw new NotImplementedException();
}
