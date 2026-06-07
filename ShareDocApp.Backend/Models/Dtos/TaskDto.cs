namespace ShareDocApp.Backend.Models.Dtos;

public record TaskDto
{
    public string? Id { get; init; }
    public string Title { get; init; } = string.Empty;
    public string Summary { get; init; } = string.Empty;
    public string DocumentName { get; init; } = string.Empty;
    public string? BlobRef { get; init; }
    public string SourceMime { get; init; } = string.Empty;
    public int Severity { get; init; }
    public int Status { get; init; }
    public DateTime? DueDate { get; init; }
    public DateTime CreatedAt { get; init; }
    public DateTime UpdatedAt { get; init; }
    public string Steps { get; init; } = "[]";
    public string Phones { get; init; } = "[]";
    public string? Address { get; init; }
    public double? GeoLat { get; init; }
    public double? GeoLon { get; init; }
    public double AiConfidence { get; init; }
    public bool ParseFailed { get; init; }
}
