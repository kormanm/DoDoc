using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using ShareDocApp.Backend.Common;

namespace ShareDocApp.Backend.Ai;

public class OpenAiProvider : IAiProvider
{
    private readonly HttpClient _http;
    private readonly string _model;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        Converters = { new JsonStringEnumConverter(JsonNamingPolicy.CamelCase) }
    };

    private static readonly JsonElement ResponseFormatSchema = BuildJsonSchema();

    public OpenAiProvider(string apiKey, string model)
        : this(CreateHttpClient(apiKey), model)
    {
    }

    public OpenAiProvider(HttpClient httpClient, string model)
    {
        _http = httpClient;
        _model = model;
    }

    public async Task<Result<AiResult>> ParseAsync(ParseInput input, CancellationToken ct)
    {
        try
        {
            var messages = BuildMessages(input);
            var requestBody = new
            {
                model = _model,
                messages,
                response_format = new
                {
                    type = "json_schema",
                    json_schema = new
                    {
                        name = "document_analysis",
                        strict = true,
                        schema = ResponseFormatSchema
                    }
                }
            };

            var json = JsonSerializer.Serialize(requestBody, JsonOptions);
            var content = new StringContent(json, Encoding.UTF8, "application/json");
            var response = await _http.PostAsync("chat/completions", content, ct);

            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync(ct);
                return ParseFailedResult($"OpenAI API error {(int)response.StatusCode}: {errorBody}");
            }

            var responseJson = await response.Content.ReadAsStringAsync(ct);
            return ParseResponse(responseJson);
        }
        catch (TaskCanceledException)
        {
            return ParseFailedResult("OpenAI request timed out");
        }
        catch (HttpRequestException ex)
        {
            return ParseFailedResult($"OpenAI request failed: {ex.Message}");
        }
    }

    private static List<object> BuildMessages(ParseInput input)
    {
        var messages = new List<object>
        {
            new { role = "system", content = PromptBuilder.SystemPrompt }
        };

        if (input.ImageBytes != null)
        {
            var base64 = Convert.ToBase64String(input.ImageBytes);
            var dataUri = $"data:{input.Mime};base64,{base64}";
            messages.Add(new
            {
                role = "user",
                content = new object[]
                {
                    new { type = "text", text = PromptBuilder.BuildUserPrompt("The document is provided as the attached image.") },
                    new { type = "image_url", image_url = new { url = dataUri } }
                }
            });
        }
        else
        {
            messages.Add(new
            {
                role = "user",
                content = PromptBuilder.BuildUserPrompt(input.Text ?? "")
            });
        }

        return messages;
    }

    private static Result<AiResult> ParseResponse(string responseJson)
    {
        try
        {
            using var doc = JsonDocument.Parse(responseJson);
            var root = doc.RootElement;

            var messageContent = root
                .GetProperty("choices")[0]
                .GetProperty("message")
                .GetProperty("content")
                .GetString();

            if (string.IsNullOrEmpty(messageContent))
                return ParseFailedResult("Empty response from OpenAI");

            var result = JsonSerializer.Deserialize<AiResult>(messageContent, JsonOptions);
            return result ?? ParseFailedResult("Failed to deserialize AI response");
        }
        catch (Exception ex)
        {
            return ParseFailedResult($"Failed to parse OpenAI response: {ex.Message}");
        }
    }

    private static AiResult ParseFailedResult(string reason) => new()
    {
        ParseFailed = true,
        Summary = null,
        Confidence = 0,
    };

    private static HttpClient CreateHttpClient(string apiKey)
    {
        var client = new HttpClient { BaseAddress = new Uri("https://api.openai.com/v1/") };
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
        return client;
    }

    private static JsonElement BuildJsonSchema()
    {
        var schema = """
        {
          "type": "object",
          "properties": {
            "summary": { "type": ["string", "null"] },
            "actions": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "title": {
                    "type": "string",
                    "description": "Very short action title, 2 to 4 words, starting with a verb"
                  },
                  "summary": { "type": ["string", "null"] },
                  "dueDate": { "type": ["string", "null"], "description": "ISO date YYYY-MM-DD or null" },
                  "severity": { "type": "string", "enum": ["low", "medium", "high", "critical"] },
                  "steps": {
                    "type": "array",
                    "items": {
                      "type": "object",
                      "properties": {
                        "text": { "type": "string" },
                        "phone": { "type": ["string", "null"] }
                      },
                      "required": ["text", "phone"],
                      "additionalProperties": false
                    }
                  },
                  "isRecurring": { "type": "boolean" },
                  "recurrence": { "type": ["string", "null"] },
                  "alert": { "type": ["string", "null"] }
                },
                "required": ["title", "summary", "dueDate", "severity", "steps", "isRecurring", "recurrence", "alert"],
                "additionalProperties": false
              }
            },
            "phones": { "type": "array", "items": { "type": "string" } },
            "geo": {
              "type": ["object", "null"],
              "properties": {
                "lat": { "type": "number" },
                "lon": { "type": "number" }
              },
              "required": ["lat", "lon"],
              "additionalProperties": false
            },
            "address": { "type": ["string", "null"] },
            "confidence": { "type": "number" },
            "parseFailed": { "type": "boolean" }
          },
          "required": ["summary", "actions", "phones", "geo", "address", "confidence", "parseFailed"],
          "additionalProperties": false
        }
        """;
        return JsonDocument.Parse(schema).RootElement.Clone();
    }
}
