namespace ShareDocApp.Backend.Auth;

public class EntraTokenValidator
{
    private readonly string _issuer;
    private readonly string _audience;
    private readonly string _jwksUri;

    public EntraTokenValidator(string issuer, string audience, string jwksUri)
    {
        _issuer = issuer;
        _audience = audience;
        _jwksUri = jwksUri;
    }

    // TODO: Implement in Step 3 — JWT validation + oid extraction
    public Task<Common.Result<string>> ValidateAndGetUserIdAsync(string? authHeader, CancellationToken ct)
    {
        throw new NotImplementedException();
    }
}
