using Azure;
using Azure.Data.Tables;

namespace ShareDocApp.Backend.Models;

public class UserEntity : ITableEntity
{
    public string PartitionKey { get; set; } = "USER";
    public string RowKey { get; set; } = string.Empty; // userId (oid)
    public DateTimeOffset? Timestamp { get; set; }
    public ETag ETag { get; set; }

    public string DisplayName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public bool PersistDocs { get; set; }
    public DateTime CreatedAt { get; set; }
}
