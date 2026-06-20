namespace ShareDocApp.Backend.Models.Dtos;

public record UserDto
{
    public string Id { get; init; } = string.Empty;
    public string DisplayName { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public bool PersistDocs { get; init; }
    public bool ConsentConfigured { get; init; }
    public DateTime CreatedAt { get; init; }
}

public record ConsentRequest
{
    public bool PersistDocs { get; init; }
}

public record UpdateProfileRequest
{
    public string DisplayName { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
}
