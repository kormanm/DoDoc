using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using Microsoft.IdentityModel.Tokens;
using ShareDocApp.Backend.Auth;
using Xunit;

namespace ShareDocApp.Backend.Tests.Auth;

public class EntraTokenValidatorTests
{
    private const string Issuer = "https://login.microsoftonline.com/test-tenant/v2.0";
    private const string Audience = "test-client-id";

    private static readonly RSA Rsa = RSA.Create(2048);
    private static readonly RsaSecurityKey SigningKey = new(Rsa);
    private static readonly SigningCredentials Creds = new(SigningKey, SecurityAlgorithms.RsaSha256);

    private static EntraTokenValidator CreateValidator(bool validateLifetime = true)
    {
        var parameters = new TokenValidationParameters
        {
            ValidIssuer = Issuer,
            ValidAudience = Audience,
            IssuerSigningKey = SigningKey,
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = validateLifetime,
            ValidateIssuerSigningKey = true,
            ClockSkew = TimeSpan.FromMinutes(2)
        };
        return new EntraTokenValidator(Issuer, Audience, parameters);
    }

    private static string MakeToken(
        string issuer = Issuer,
        string audience = Audience,
        string? oid = "user-123",
        DateTime? expires = null,
        DateTime? notBefore = null)
    {
        var claims = new List<Claim>();
        if (oid != null)
            claims.Add(new Claim("oid", oid));

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            notBefore: notBefore ?? DateTime.UtcNow.AddMinutes(-5),
            expires: expires ?? DateTime.UtcNow.AddHours(1),
            signingCredentials: Creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    [Fact]
    public async Task ValidToken_ReturnsOid()
    {
        var validator = CreateValidator();
        var token = MakeToken(oid: "my-user-oid");

        var result = await validator.ValidateAndGetUserIdAsync($"Bearer {token}", CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Equal("my-user-oid", result.Value);
    }

    [Fact]
    public async Task MissingAuthHeader_ReturnsAuthError()
    {
        var validator = CreateValidator();

        var result = await validator.ValidateAndGetUserIdAsync(null, CancellationToken.None);

        Assert.False(result.IsSuccess);
        Assert.Equal("auth", result.Error!.Type);
        Assert.Contains("Missing", result.Error.Message);
    }

    [Fact]
    public async Task EmptyAuthHeader_ReturnsAuthError()
    {
        var validator = CreateValidator();

        var result = await validator.ValidateAndGetUserIdAsync("", CancellationToken.None);

        Assert.False(result.IsSuccess);
        Assert.Equal("auth", result.Error!.Type);
    }

    [Fact]
    public async Task NonBearerScheme_ReturnsAuthError()
    {
        var validator = CreateValidator();

        var result = await validator.ValidateAndGetUserIdAsync("Basic abc123", CancellationToken.None);

        Assert.False(result.IsSuccess);
        Assert.Equal("auth", result.Error!.Type);
        Assert.Contains("Bearer", result.Error.Message);
    }

    [Fact]
    public async Task WrongIssuer_ReturnsAuthError()
    {
        var validator = CreateValidator();
        var token = MakeToken(issuer: "https://evil.example.com/v2.0");

        var result = await validator.ValidateAndGetUserIdAsync($"Bearer {token}", CancellationToken.None);

        Assert.False(result.IsSuccess);
        Assert.Equal("auth", result.Error!.Type);
        Assert.Contains("Invalid token", result.Error.Message);
    }

    [Fact]
    public async Task WrongAudience_ReturnsAuthError()
    {
        var validator = CreateValidator();
        var token = MakeToken(audience: "wrong-client-id");

        var result = await validator.ValidateAndGetUserIdAsync($"Bearer {token}", CancellationToken.None);

        Assert.False(result.IsSuccess);
        Assert.Equal("auth", result.Error!.Type);
        Assert.Contains("Invalid token", result.Error.Message);
    }

    [Fact]
    public async Task ExpiredToken_ReturnsAuthError()
    {
        var validator = CreateValidator(validateLifetime: true);
        var token = MakeToken(
            expires: DateTime.UtcNow.AddHours(-1),
            notBefore: DateTime.UtcNow.AddHours(-2));

        var result = await validator.ValidateAndGetUserIdAsync($"Bearer {token}", CancellationToken.None);

        Assert.False(result.IsSuccess);
        Assert.Equal("auth", result.Error!.Type);
        Assert.Contains("expired", result.Error.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task MissingOidClaim_ReturnsAuthError()
    {
        var validator = CreateValidator();
        var token = MakeToken(oid: null);

        var result = await validator.ValidateAndGetUserIdAsync($"Bearer {token}", CancellationToken.None);

        Assert.False(result.IsSuccess);
        Assert.Equal("auth", result.Error!.Type);
        Assert.Contains("oid", result.Error.Message);
    }

    [Fact]
    public async Task GarbageToken_ReturnsAuthError()
    {
        var validator = CreateValidator();

        var result = await validator.ValidateAndGetUserIdAsync("Bearer not.a.jwt", CancellationToken.None);

        Assert.False(result.IsSuccess);
        Assert.Equal("auth", result.Error!.Type);
    }

    [Fact]
    public async Task TokenSignedWithDifferentKey_ReturnsAuthError()
    {
        var validator = CreateValidator();

        var otherRsa = RSA.Create(2048);
        var otherKey = new RsaSecurityKey(otherRsa);
        var otherCreds = new SigningCredentials(otherKey, SecurityAlgorithms.RsaSha256);
        var token = new JwtSecurityToken(
            issuer: Issuer,
            audience: Audience,
            claims: [new Claim("oid", "user-1")],
            notBefore: DateTime.UtcNow.AddMinutes(-5),
            expires: DateTime.UtcNow.AddHours(1),
            signingCredentials: otherCreds);
        var tokenStr = new JwtSecurityTokenHandler().WriteToken(token);

        var result = await validator.ValidateAndGetUserIdAsync($"Bearer {tokenStr}", CancellationToken.None);

        Assert.False(result.IsSuccess);
        Assert.Equal("auth", result.Error!.Type);
    }
}
