namespace ShareDocApp.Backend.Ai;

public interface IAiProvider
{
    Task<Common.Result<AiResult>> ParseAsync(ParseInput input, CancellationToken ct);
}
