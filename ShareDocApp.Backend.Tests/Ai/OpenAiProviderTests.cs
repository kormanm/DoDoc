using System.Net;
using System.Text.Json;
using ShareDocApp.Backend.Ai;
using Xunit;

namespace ShareDocApp.Backend.Tests.Ai;

public class OpenAiProviderTests
{
    private static OpenAiProvider CreateProvider(HttpResponseMessage response)
    {
        var handler = new FakeHttpHandler(response);
        var client = new HttpClient(handler) { BaseAddress = new Uri("https://api.openai.com/v1/") };
        return new OpenAiProvider(client, "gpt-4o-mini");
    }

    private static HttpResponseMessage OkResponse(object aiResultContent)
    {
        var content = JsonSerializer.Serialize(aiResultContent, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });

        var wrapper = new
        {
            choices = new[]
            {
                new
                {
                    message = new { content }
                }
            }
        };

        return new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent(
                JsonSerializer.Serialize(wrapper),
                System.Text.Encoding.UTF8,
                "application/json")
        };
    }

    [Fact]
    public async Task ParseAsync_Text_ReturnsStructuredResult()
    {
        var aiResult = new
        {
            summary = "Insurance renewal notice",
            expiryDate = "2025-03-15",
            severity = "high",
            steps = new[]
            {
                new { text = "Call insurance company", phone = "+31201234567" },
                new { text = "Submit renewal form", phone = (string?)null }
            },
            phones = new[] { "+31201234567" },
            geo = new { lat = 52.37, lon = 4.89 },
            address = "Herengracht 1, Amsterdam",
            confidence = 0.92,
            parseFailed = false
        };

        var provider = CreateProvider(OkResponse(aiResult));
        var input = new ParseInput { Text = "Your insurance expires March 15, 2025.", Mime = "text/plain" };

        var result = await provider.ParseAsync(input, CancellationToken.None);

        Assert.True(result.IsSuccess);
        var value = result.Value!;
        Assert.Equal("Insurance renewal notice", value.Summary);
        Assert.Equal(new DateOnly(2025, 3, 15), value.ExpiryDate);
        Assert.Equal(Severity.High, value.Severity);
        Assert.Equal(2, value.Steps.Count);
        Assert.Equal("Call insurance company", value.Steps[0].Text);
        Assert.Equal("+31201234567", value.Steps[0].Phone);
        Assert.Single(value.Phones);
        Assert.NotNull(value.Geo);
        Assert.Equal(52.37, value.Geo!.Lat);
        Assert.Equal("Herengracht 1, Amsterdam", value.Address);
        Assert.Equal(0.92, value.Confidence);
        Assert.False(value.ParseFailed);
    }

    [Fact]
    public async Task ParseAsync_Image_SendsBase64()
    {
        var aiResult = new
        {
            summary = "Scanned letter",
            expiryDate = (string?)null,
            severity = "low",
            steps = Array.Empty<object>(),
            phones = Array.Empty<string>(),
            geo = (object?)null,
            address = (string?)null,
            confidence = 0.5,
            parseFailed = false
        };

        string? capturedBody = null;
        var handler = new FakeHttpHandler(OkResponse(aiResult), body => capturedBody = body);
        var client = new HttpClient(handler) { BaseAddress = new Uri("https://api.openai.com/v1/") };
        var provider = new OpenAiProvider(client, "gpt-4o-mini");

        var input = new ParseInput
        {
            ImageBytes = new byte[] { 0xFF, 0xD8, 0xFF },
            Mime = "image/jpeg"
        };

        var result = await provider.ParseAsync(input, CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.NotNull(capturedBody);
        Assert.Contains("image_url", capturedBody);
        Assert.Contains("data:image/jpeg;base64,", capturedBody);
    }

    [Fact]
    public async Task ParseAsync_NullFields_HandlesGracefully()
    {
        var aiResult = new
        {
            summary = (string?)null,
            expiryDate = (string?)null,
            severity = "low",
            steps = Array.Empty<object>(),
            phones = Array.Empty<string>(),
            geo = (object?)null,
            address = (string?)null,
            confidence = 0.3,
            parseFailed = false
        };

        var provider = CreateProvider(OkResponse(aiResult));
        var input = new ParseInput { Text = "Some vague text", Mime = "text/plain" };

        var result = await provider.ParseAsync(input, CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Null(result.Value!.Summary);
        Assert.Null(result.Value.ExpiryDate);
        Assert.Null(result.Value.Geo);
        Assert.Null(result.Value.Address);
        Assert.Empty(result.Value.Steps);
        Assert.Empty(result.Value.Phones);
    }

    [Fact]
    public async Task ParseAsync_ApiError_ReturnsParseFailed()
    {
        var errorResponse = new HttpResponseMessage(HttpStatusCode.TooManyRequests)
        {
            Content = new StringContent("{\"error\":{\"message\":\"Rate limit exceeded\"}}")
        };

        var provider = CreateProvider(errorResponse);
        var input = new ParseInput { Text = "test", Mime = "text/plain" };

        var result = await provider.ParseAsync(input, CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.True(result.Value!.ParseFailed);
        Assert.Equal(0, result.Value.Confidence);
    }

    [Fact]
    public async Task ParseAsync_MalformedJson_ReturnsParseFailed()
    {
        var response = new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent("{\"choices\":[{\"message\":{\"content\":\"not valid json\"}}]}")
        };

        var provider = CreateProvider(response);
        var input = new ParseInput { Text = "test", Mime = "text/plain" };

        var result = await provider.ParseAsync(input, CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.True(result.Value!.ParseFailed);
    }

    [Fact]
    public async Task ParseAsync_EmptyContent_ReturnsParseFailed()
    {
        var response = new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent("{\"choices\":[{\"message\":{\"content\":\"\"}}]}")
        };

        var provider = CreateProvider(response);
        var input = new ParseInput { Text = "test", Mime = "text/plain" };

        var result = await provider.ParseAsync(input, CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.True(result.Value!.ParseFailed);
    }

    [Fact]
    public async Task ParseAsync_HttpException_ReturnsParseFailed()
    {
        var handler = new FakeHttpHandler(new HttpRequestException("connection refused"));
        var client = new HttpClient(handler) { BaseAddress = new Uri("https://api.openai.com/v1/") };
        var provider = new OpenAiProvider(client, "gpt-4o-mini");
        var input = new ParseInput { Text = "test", Mime = "text/plain" };

        var result = await provider.ParseAsync(input, CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.True(result.Value!.ParseFailed);
    }

    [Fact]
    public async Task ParseAsync_ParseFailedFromAi_PreservedInResult()
    {
        var aiResult = new
        {
            summary = (string?)null,
            expiryDate = (string?)null,
            severity = "low",
            steps = Array.Empty<object>(),
            phones = Array.Empty<string>(),
            geo = (object?)null,
            address = (string?)null,
            confidence = 0.0,
            parseFailed = true
        };

        var provider = CreateProvider(OkResponse(aiResult));
        var input = new ParseInput { Text = "garbled text", Mime = "text/plain" };

        var result = await provider.ParseAsync(input, CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.True(result.Value!.ParseFailed);
    }
}

internal class FakeHttpHandler : HttpMessageHandler
{
    private readonly HttpResponseMessage? _response;
    private readonly HttpRequestException? _exception;
    private readonly Action<string>? _captureBody;

    public FakeHttpHandler(HttpResponseMessage response, Action<string>? captureBody = null)
    {
        _response = response;
        _captureBody = captureBody;
    }

    public FakeHttpHandler(HttpRequestException exception)
    {
        _exception = exception;
    }

    protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct)
    {
        if (_captureBody != null && request.Content != null)
        {
            var body = await request.Content.ReadAsStringAsync(ct);
            _captureBody(body);
        }

        if (_exception != null)
            throw _exception;

        return _response!;
    }
}
