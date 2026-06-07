using System.Text;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Moq;
using ShareDocApp.Backend.Ai;
using ShareDocApp.Backend.Common;
using ShareDocApp.Backend.Documents;
using ShareDocApp.Backend.Functions;
using ShareDocApp.Backend.Models;
using ShareDocApp.Backend.Models.Dtos;
using ShareDocApp.Backend.Storage;
using Xunit;

namespace ShareDocApp.Backend.Tests.Functions;

public class DocumentsFunctionTests
{
    private readonly Mock<IAiProvider> _ai = new();
    private readonly Mock<IBlobStore> _blobs = new();
    private readonly Mock<IUserStore> _users = new();
    private readonly DocumentsFunction _func;
    private const string UserId = "doc-user";

    public DocumentsFunctionTests()
    {
        var auth = TestAuth.CreateValidator(UserId);
        var extractor = new TextExtractor();
        _func = new DocumentsFunction(auth, extractor, _ai.Object, _blobs.Object, _users.Object);
    }

    [Fact]
    public async Task Parse_TextFile_ReturnsAiResult()
    {
        _ai.Setup(a => a.ParseAsync(It.IsAny<ParseInput>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<AiResult>.Ok(new AiResult
            {
                Summary = "Test summary",
                Severity = Severity.Medium,
                Confidence = 0.85,
                Steps = [new ActionStep("Do something", null)],
                Phones = [],
            }));

        var req = CreateMultipartRequest("hello world", "test.txt", "text/plain", persist: false);
        var result = await _func.Parse(req, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var dto = Assert.IsType<DocumentResultDto>(ok.Value);
        Assert.Equal("Test summary", dto.Summary);
        Assert.Equal("medium", dto.Severity);
        Assert.False(dto.ParseFailed);
        Assert.Null(dto.BlobRef);
    }

    [Fact]
    public async Task Parse_AiFails_ReturnsParseFailed200()
    {
        _ai.Setup(a => a.ParseAsync(It.IsAny<ParseInput>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<AiResult>.Ok(new AiResult
            {
                ParseFailed = true,
                Confidence = 0
            }));

        var req = CreateMultipartRequest("content", "doc.txt", "text/plain", persist: false);
        var result = await _func.Parse(req, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var dto = Assert.IsType<DocumentResultDto>(ok.Value);
        Assert.True(dto.ParseFailed);
    }

    [Fact]
    public async Task Parse_PersistWithConsent_UploadsToBlobAndReturnsBlobRef()
    {
        _ai.Setup(a => a.ParseAsync(It.IsAny<ParseInput>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<AiResult>.Ok(new AiResult
            {
                Summary = "OK",
                Confidence = 0.9
            }));
        _users.Setup(u => u.GetAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new UserEntity { RowKey = UserId, PersistDocs = true });
        _blobs.Setup(b => b.UploadAsync(UserId, "test.txt", It.IsAny<Stream>(), "text/plain", It.IsAny<CancellationToken>()))
            .ReturnsAsync("doc-user/abc/test.txt");

        var req = CreateMultipartRequest("content", "test.txt", "text/plain", persist: true);
        var result = await _func.Parse(req, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var dto = Assert.IsType<DocumentResultDto>(ok.Value);
        Assert.Equal("doc-user/abc/test.txt", dto.BlobRef);
    }

    [Fact]
    public async Task Parse_PersistWithoutConsent_NoBlobRef()
    {
        _ai.Setup(a => a.ParseAsync(It.IsAny<ParseInput>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<AiResult>.Ok(new AiResult { Summary = "OK", Confidence = 0.9 }));
        _users.Setup(u => u.GetAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new UserEntity { RowKey = UserId, PersistDocs = false });

        var req = CreateMultipartRequest("content", "test.txt", "text/plain", persist: true);
        var result = await _func.Parse(req, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var dto = Assert.IsType<DocumentResultDto>(ok.Value);
        Assert.Null(dto.BlobRef);
        _blobs.Verify(b => b.UploadAsync(It.IsAny<string>(), It.IsAny<string>(),
            It.IsAny<Stream>(), It.IsAny<string>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task Parse_UnsupportedType_Returns400()
    {
        var req = CreateMultipartRequest("data", "archive.zip", "application/zip", persist: false);
        var result = await _func.Parse(req, CancellationToken.None);

        var obj = Assert.IsType<ObjectResult>(result);
        Assert.Equal(400, obj.StatusCode);
    }

    [Fact]
    public async Task Parse_NoAuth_Returns401()
    {
        var auth = TestAuth.CreateFailingValidator();
        var func = new DocumentsFunction(auth, new TextExtractor(), _ai.Object, _blobs.Object, _users.Object);
        var req = CreateMultipartRequestWithoutAuth("content", "test.txt", "text/plain");

        var result = await func.Parse(req, CancellationToken.None);

        var obj = Assert.IsType<ObjectResult>(result);
        Assert.Equal(401, obj.StatusCode);
    }

    private static HttpRequest CreateMultipartRequest(string content, string fileName, string contentType, bool persist)
    {
        var context = new DefaultHttpContext();
        context.Request.Method = "POST";
        context.Request.Headers.Authorization = "Bearer valid-token";
        context.Request.ContentType = "multipart/form-data; boundary=----test";

        var fileBytes = Encoding.UTF8.GetBytes(content);
        var file = new FormFile(new MemoryStream(fileBytes), 0, fileBytes.Length, "file", fileName)
        {
            Headers = new HeaderDictionary(),
            ContentType = contentType
        };

        var formCollection = new FormCollection(
            new Dictionary<string, Microsoft.Extensions.Primitives.StringValues>
            {
                ["persist"] = persist.ToString()
            },
            new FormFileCollection { file });

        context.Request.Form = formCollection;
        return context.Request;
    }

    private static HttpRequest CreateMultipartRequestWithoutAuth(string content, string fileName, string contentType)
    {
        var context = new DefaultHttpContext();
        context.Request.Method = "POST";
        context.Request.ContentType = "multipart/form-data; boundary=----test";

        var fileBytes = Encoding.UTF8.GetBytes(content);
        var file = new FormFile(new MemoryStream(fileBytes), 0, fileBytes.Length, "file", fileName)
        {
            Headers = new HeaderDictionary(),
            ContentType = contentType
        };

        context.Request.Form = new FormCollection(
            new Dictionary<string, Microsoft.Extensions.Primitives.StringValues>(),
            new FormFileCollection { file });

        return context.Request;
    }
}
