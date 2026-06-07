using ShareDocApp.Backend.Documents;
using Xunit;

namespace ShareDocApp.Backend.Tests.Documents;

public class DocumentTypeDetectorTests
{
    [Theory]
    [InlineData("application/pdf", null, DocumentType.Pdf)]
    [InlineData("application/vnd.openxmlformats-officedocument.wordprocessingml.document", null, DocumentType.Word)]
    [InlineData("image/jpeg", null, DocumentType.Image)]
    [InlineData("image/png", null, DocumentType.Image)]
    [InlineData("text/plain", null, DocumentType.PlainText)]
    public void Detect_ByMime(string mime, string? fileName, DocumentType expected)
    {
        Assert.Equal(expected, DocumentTypeDetector.Detect(mime, fileName));
    }

    [Theory]
    [InlineData("application/octet-stream", "report.pdf", DocumentType.Pdf)]
    [InlineData("application/octet-stream", "letter.docx", DocumentType.Word)]
    [InlineData("application/octet-stream", "photo.jpg", DocumentType.Image)]
    [InlineData("application/octet-stream", "photo.jpeg", DocumentType.Image)]
    [InlineData("application/octet-stream", "scan.png", DocumentType.Image)]
    [InlineData("application/octet-stream", "notes.txt", DocumentType.PlainText)]
    public void Detect_OctetStream_FallsBackToExtension(string mime, string fileName, DocumentType expected)
    {
        Assert.Equal(expected, DocumentTypeDetector.Detect(mime, fileName));
    }

    [Theory]
    [InlineData(null, "report.pdf", DocumentType.Pdf)]
    [InlineData("", "letter.docx", DocumentType.Word)]
    [InlineData("  ", "photo.PNG", DocumentType.Image)]
    public void Detect_EmptyMime_FallsBackToExtension(string? mime, string fileName, DocumentType expected)
    {
        Assert.Equal(expected, DocumentTypeDetector.Detect(mime, fileName));
    }

    [Theory]
    [InlineData("application/octet-stream", "file.xyz")]
    [InlineData("application/octet-stream", null)]
    [InlineData("application/octet-stream", "noext")]
    [InlineData(null, null)]
    [InlineData("application/zip", "archive.zip")]
    public void Detect_UnknownType(string? mime, string? fileName)
    {
        Assert.Equal(DocumentType.Unknown, DocumentTypeDetector.Detect(mime, fileName));
    }

    [Fact]
    public void Detect_MimeTakesPriorityOverExtension()
    {
        var result = DocumentTypeDetector.Detect("application/pdf", "file.docx");
        Assert.Equal(DocumentType.Pdf, result);
    }

    [Fact]
    public void Detect_CaseInsensitiveMime()
    {
        Assert.Equal(DocumentType.Pdf, DocumentTypeDetector.Detect("Application/PDF", null));
    }

    [Fact]
    public void Detect_CaseInsensitiveExtension()
    {
        Assert.Equal(DocumentType.Word, DocumentTypeDetector.Detect("application/octet-stream", "DOC.DOCX"));
    }
}
