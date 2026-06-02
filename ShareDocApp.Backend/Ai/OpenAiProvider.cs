namespace ShareDocApp.Backend.Ai;

public class OpenAiProvider : IAiProvider
{
    private readonly string _apiKey;
    private readonly string _model;

    public OpenAiProvider(string apiKey, string model)
    {
        _apiKey = apiKey;
        _model = model;
    }

    public Task<Common.Result<AiResult>> ParseAsync(ParseInput input, CancellationToken ct)
    {
        // TODO: Implement in Step 5 — OpenAI structured JSON output
        throw new NotImplementedException();
    }
}
