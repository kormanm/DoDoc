using ShareDocApp.Backend.Ai;

namespace ShareDocApp.Backend.Models.Dtos;

public record DocumentResultDto
{
    public string? Summary { get; init; }
    public List<DocumentActionDto> Actions { get; init; } = [];
    public List<string> Phones { get; init; } = [];
    public GeoPointDto? Geo { get; init; }
    public string? Address { get; init; }
    public double Confidence { get; init; }
    public bool ParseFailed { get; init; }
    public string? BlobRef { get; init; }

    public static DocumentResultDto From(AiResult ai, string? blobRef) => new()
    {
        Summary = ai.Summary,
        Actions = ai.Actions.Select(a => new DocumentActionDto(
            a.Title,
            a.Summary,
            a.DueDate?.ToString("yyyy-MM-dd"),
            a.Severity.ToString().ToLowerInvariant(),
            a.Steps.Select(s => new ActionStepDto(s.Text, s.Phone)).ToList(),
            a.IsRecurring,
            a.Recurrence,
            a.Alert)).ToList(),
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
public record DocumentActionDto(
    string Title,
    string? Summary,
    string? DueDate,
    string Severity,
    List<ActionStepDto> Steps,
    bool IsRecurring,
    string? Recurrence,
    string? Alert);
