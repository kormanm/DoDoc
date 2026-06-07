using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using ShareDocApp.Backend.Ai;
using ShareDocApp.Backend.Auth;
using ShareDocApp.Backend.Common;
using ShareDocApp.Backend.Documents;
using ShareDocApp.Backend.Models.Dtos;
using ShareDocApp.Backend.Storage;

namespace ShareDocApp.Backend.Functions;

public class DocumentsFunction
{
    private readonly EntraTokenValidator _auth;
    private readonly TextExtractor _extractor;
    private readonly IAiProvider _ai;
    private readonly IBlobStore _blobs;
    private readonly IUserStore _users;

    public DocumentsFunction(
        EntraTokenValidator auth,
        TextExtractor extractor,
        IAiProvider ai,
        IBlobStore blobs,
        IUserStore users)
    {
        _auth = auth;
        _extractor = extractor;
        _ai = ai;
        _blobs = blobs;
        _users = users;
    }

    [Function("DocumentsParse")]
    public async Task<IActionResult> Parse(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "documents")] HttpRequest req,
        CancellationToken ct)
    {
        var authResult = await _auth.ValidateAndGetUserIdAsync(HttpHelpers.GetAuthHeader(req), ct);
        if (!authResult.IsSuccess)
            return HttpHelpers.ToErrorResponse(authResult.Error!);

        var userId = authResult.Value!;

        var file = req.Form.Files.GetFile("file");
        if (file == null || file.Length == 0)
            return HttpHelpers.ToErrorResponse(Errors.Validation("File is required"));

        var persist = false;
        if (req.Form.TryGetValue("persist", out var persistValue))
            bool.TryParse(persistValue.FirstOrDefault(), out persist);

        using var stream = file.OpenReadStream();
        var extraction = _extractor.Extract(stream, file.Length, file.ContentType, file.FileName);
        if (!extraction.IsSuccess)
            return HttpHelpers.ToErrorResponse(extraction.Error!);

        var parseInput = new ParseInput
        {
            Text = extraction.Value!.Text,
            ImageBytes = extraction.Value.ImageBytes,
            Mime = extraction.Value.Mime
        };

        var aiResult = await _ai.ParseAsync(parseInput, ct);
        AiResult ai;
        if (!aiResult.IsSuccess)
        {
            ai = new AiResult { ParseFailed = true, Confidence = 0 };
        }
        else
        {
            ai = aiResult.Value!;
        }

        string? blobRef = null;
        if (persist)
        {
            var user = await _users.GetAsync(userId, ct);
            if (user is { PersistDocs: true })
            {
                stream.Position = 0;
                blobRef = await _blobs.UploadAsync(
                    userId,
                    file.FileName ?? "document",
                    stream,
                    file.ContentType ?? extraction.Value.Mime,
                    ct);
            }
        }

        return HttpHelpers.JsonOk(DocumentResultDto.From(ai, blobRef));
    }
}
