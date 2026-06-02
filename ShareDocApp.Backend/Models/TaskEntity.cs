using Azure;
using Azure.Data.Tables;

namespace ShareDocApp.Backend.Models;

public class TaskEntity : ITableEntity
{
    public string PartitionKey { get; set; } = string.Empty; // userId
    public string RowKey { get; set; } = string.Empty;       // taskId (GUID)
    public DateTimeOffset? Timestamp { get; set; }
    public ETag ETag { get; set; }

    public string Title { get; set; } = string.Empty;
    public string Summary { get; set; } = string.Empty;
    public string DocumentName { get; set; } = string.Empty;
    public string? BlobRef { get; set; }
    public string SourceMime { get; set; } = string.Empty;
    public int Severity { get; set; }       // 0 Low, 1 Medium, 2 High, 3 Critical
    public int Status { get; set; }         // 0 Open, 1 Done
    public DateTime? DueDate { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public string Steps { get; set; } = "[]";   // JSON array of {text, phone?}
    public string Phones { get; set; } = "[]";  // JSON array of string
    public string? Address { get; set; }
    public double? GeoLat { get; set; }
    public double? GeoLon { get; set; }
    public double AiConfidence { get; set; }
    public bool ParseFailed { get; set; }
}
