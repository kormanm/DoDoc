using ShareDocApp.Backend.Ai;

namespace ShareDocApp.Backend.Models.Dtos;

public record DocumentResultDto
{
    public string? Summary { get; init; }
    public string? ExpiryDate { get; init; }
    public string Severity { get; init; } = "low";
    public List<ActionStepDto> Steps { get; init; } = [];
    public List<string> Phones { get; init; } = [];
    public GeoPointDto? Geo { get; init; }
    public string? Address { get; init; }
    public double Confidence { get; init; }
    public bool ParseFailed { get; init; }
    public string? BlobRef { get; init; }

    public static DocumentResultDto From(AiResult ai, string? blobRef) => new()
    {
        Summary = ai.Summary,
        ExpiryDate = ai.ExpiryDate?.ToString("yyyy-MM-dd"),
        Severity = ai.Severity.ToString().ToLowerInvariant(),
        Steps = ai.Steps.Select(s => new ActionStepDto(s.Text, s.Phone)).ToList(),
        Phones = ai.Phones,
        Geo = ai.Geo != null ? new GeoPointDto(ai.Geo.Lat, ai.Geo.Lon) : null,
        Address = ai.Address,
        Confidence = ai.Confidence,
        ParseFailed = ai.ParseFailed,
        BlobRef = blobRef
    };
}

public record ActionStepDto(string Text, string? Phone);
public record GeoPointDto(double Lat, double Lon);
