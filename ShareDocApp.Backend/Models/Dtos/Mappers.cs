namespace ShareDocApp.Backend.Models.Dtos;

public static class Mappers
{
    public static TaskDto ToDto(TaskEntity entity) => new()
    {
        Id = entity.RowKey,
        Title = entity.Title,
        Summary = entity.Summary,
        DocumentName = entity.DocumentName,
        BlobRef = entity.BlobRef,
        SourceMime = entity.SourceMime,
        Severity = entity.Severity,
        Status = entity.Status,
        DueDate = entity.DueDate,
        CreatedAt = entity.CreatedAt,
        UpdatedAt = entity.UpdatedAt,
        Steps = entity.Steps,
        Phones = entity.Phones,
        Address = entity.Address,
        GeoLat = entity.GeoLat,
        GeoLon = entity.GeoLon,
        AiConfidence = entity.AiConfidence,
        ParseFailed = entity.ParseFailed
    };

    public static TaskEntity ToEntity(TaskDto dto, string userId) => new()
    {
        PartitionKey = userId,
        RowKey = dto.Id ?? "",
        Title = dto.Title,
        Summary = dto.Summary,
        DocumentName = dto.DocumentName,
        BlobRef = dto.BlobRef,
        SourceMime = dto.SourceMime,
        Severity = dto.Severity,
        Status = dto.Status,
        DueDate = dto.DueDate,
        Steps = dto.Steps,
        Phones = dto.Phones,
        Address = dto.Address,
        GeoLat = dto.GeoLat,
        GeoLon = dto.GeoLon,
        AiConfidence = dto.AiConfidence,
        ParseFailed = dto.ParseFailed
    };

    public static UserDto ToDto(UserEntity entity) => new()
    {
        Id = entity.RowKey,
        DisplayName = entity.DisplayName,
        Email = entity.Email,
        PersistDocs = entity.PersistDocs,
        CreatedAt = entity.CreatedAt
    };
}
