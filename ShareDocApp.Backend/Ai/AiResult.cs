namespace ShareDocApp.Backend.Ai;

public enum Severity { Low, Medium, High, Critical }

public record ActionStep(string Text, string? Phone);

public record GeoPoint(double Lat, double Lon);

public record AiAction
{
    public string Title { get; init; } = string.Empty;
    public string? Summary { get; init; }
    public DateOnly? DueDate { get; init; }
    public Severity Severity { get; init; }
    public List<ActionStep> Steps { get; init; } = [];
    public bool IsRecurring { get; init; }
    public string? Recurrence { get; init; }
    public string? Alert { get; init; }
}

public record AiResult
{
    public string? Summary { get; init; }
    public List<AiAction> Actions { get; init; } = [];
    public List<string> Phones { get; init; } = [];
    public GeoPoint? Geo { get; init; }
    public string? Address { get; init; }
    public double Confidence { get; init; }
    public bool ParseFailed { get; init; }
}
