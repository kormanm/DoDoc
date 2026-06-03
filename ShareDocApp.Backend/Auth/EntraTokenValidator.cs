using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.IdentityModel.Protocols;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;
using ShareDocApp.Backend.Common;

namespace ShareDocApp.Backend.Auth;

public class EntraTokenValidator
{
    private readonly string _issuer;
    private readonly string _audience;
    private readonly ConfigurationManager<OpenIdConnectConfiguration> _configManager;
    private readonly JwtSecurityTokenHandler _handler = new();

    public EntraTokenValidator(string issuer, string audience, string jwksUri)
    {
        _issuer = issuer;
        _audience = audience;
        _configManager = new ConfigurationManager<OpenIdConnectConfiguration>(
            jwksUri,
            new OpenIdConnectConfigurationRetriever(),
            new HttpDocumentRetriever());
    }

    internal EntraTokenValidator(string issuer, string audience, TokenValidationParameters overrideParams)
    {
        _issuer = issuer;
        _audience = audience;
        _configManager = null!;
        _overrideParams = overrideParams;
    }

    private readonly TokenValidationParameters? _overrideParams;

    public async Task<Result<string>> ValidateAndGetUserIdAsync(string? authHeader, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(authHeader))
            return Errors.Auth("Missing Authorization header");

        if (!authHeader.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
            return Errors.Auth("Authorization header must use Bearer scheme");

        var token = authHeader["Bearer ".Length..].Trim();
        if (string.IsNullOrEmpty(token))
            return Errors.Auth("Empty bearer token");

        try
        {
            var validationParams = _overrideParams ?? await BuildValidationParametersAsync(ct);
            var principal = _handler.ValidateToken(token, validationParams, out _);
            var oid = principal.FindFirstValue("oid")
                      ?? principal.FindFirstValue("http://schemas.microsoft.com/identity/claims/objectidentifier");

            if (string.IsNullOrEmpty(oid))
                return Errors.Auth("Token missing oid claim");

            return oid;
        }
        catch (SecurityTokenExpiredException)
        {
            return Errors.Auth("Token expired");
        }
        catch (SecurityTokenException ex)
        {
            return Errors.Auth($"Invalid token: {ex.Message}");
        }
    }

    private async Task<TokenValidationParameters> BuildValidationParametersAsync(CancellationToken ct)
    {
        var config = await _configManager.GetConfigurationAsync(ct);
        return new TokenValidationParameters
        {
            ValidIssuer = _issuer,
            ValidAudience = _audience,
            IssuerSigningKeys = config.SigningKeys,
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ClockSkew = TimeSpan.FromMinutes(2)
        };
    }
}
