namespace ShareDocApp.Backend.Ai;

// OpenAI Chat Completions with response_format = json_schema matching AiResult
public class OpenAiProvider : IAiProvider
{
    public Task<Common.Result<AiResult>> ParseAsync(ParseInput input, CancellationToken ct)
    {
        throw new NotImplementedException();
    }
}
