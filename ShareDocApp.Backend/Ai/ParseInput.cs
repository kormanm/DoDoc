namespace ShareDocApp.Backend.Ai;

public record ParseInput
{
    public string? Text { get; init; }
    public byte[]? ImageBytes { get; init; }
    public string Mime { get; init; } = string.Empty;
}
