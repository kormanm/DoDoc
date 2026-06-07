using System.Text;
using DocumentFormat.OpenXml;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Wordprocessing;
using ShareDocApp.Backend.Common;
using ShareDocApp.Backend.Documents;
using UglyToad.PdfPig.Writer;
using Xunit;
using DocumentType = ShareDocApp.Backend.Documents.DocumentType;

namespace ShareDocApp.Backend.Tests.Documents;

public class TextExtractorTests
{
    private readonly TextExtractor _extractor = new();

    [Fact]
    public void Extract_PlainText_Utf8()
    {
        var bytes = Encoding.UTF8.GetBytes("Hello, world!");
        using var stream = new MemoryStream(bytes);

        var result = _extractor.Extract(stream, bytes.Length, "text/plain", "test.txt");

        Assert.True(result.IsSuccess);
        Assert.Equal(DocumentType.PlainText, result.Value!.Type);
        Assert.Equal("Hello, world!", result.Value.Text);
        Assert.Null(result.Value.ImageBytes);
    }

    [Fact]
    public void Extract_PlainText_Latin1Fallback()
    {
        var bytes = Encoding.Latin1.GetBytes("Straße");
        using var stream = new MemoryStream(bytes);

        var result = _extractor.Extract(stream, bytes.Length, "text/plain", "test.txt");

        Assert.True(result.IsSuccess);
        Assert.NotNull(result.Value!.Text);
    }

    [Fact]
    public void Extract_PlainText_ViaOctetStream()
    {
        var bytes = Encoding.UTF8.GetBytes("octet-stream text content");
        using var stream = new MemoryStream(bytes);

        var result = _extractor.Extract(stream, bytes.Length, "application/octet-stream", "notes.txt");

        Assert.True(result.IsSuccess);
        Assert.Equal(DocumentType.PlainText, result.Value!.Type);
        Assert.Equal("octet-stream text content", result.Value.Text);
    }

    [Fact]
    public void Extract_Image_ReturnsBytes()
    {
        var fakeImage = new byte[] { 0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10 };
        using var stream = new MemoryStream(fakeImage);

        var result = _extractor.Extract(stream, fakeImage.Length, "image/jpeg", "photo.jpg");

        Assert.True(result.IsSuccess);
        Assert.Equal(DocumentType.Image, result.Value!.Type);
        Assert.Null(result.Value.Text);
        Assert.NotNull(result.Value.ImageBytes);
        Assert.Equal(fakeImage.Length, result.Value.ImageBytes!.Length);
    }

    [Fact]
    public void Extract_Image_ViaOctetStream()
    {
        var fakeImage = new byte[] { 0x89, 0x50, 0x4E, 0x47 };
        using var stream = new MemoryStream(fakeImage);

        var result = _extractor.Extract(stream, fakeImage.Length, "application/octet-stream", "scan.png");

        Assert.True(result.IsSuccess);
        Assert.Equal(DocumentType.Image, result.Value!.Type);
        Assert.NotNull(result.Value.ImageBytes);
    }

    [Fact]
    public void Extract_SizeExceeded_ReturnsError()
    {
        using var stream = new MemoryStream(new byte[1]);
        var oversized = Validation.MaxFileSizeBytes + 1;

        var result = _extractor.Extract(stream, oversized, "text/plain", "big.txt");

        Assert.False(result.IsSuccess);
        Assert.Equal("validation", result.Error!.Type);
        Assert.Contains("10 MB", result.Error.Message);
    }

    [Fact]
    public void Extract_UnknownType_ReturnsError()
    {
        using var stream = new MemoryStream(new byte[1]);

        var result = _extractor.Extract(stream, 1, "application/zip", "archive.zip");

        Assert.False(result.IsSuccess);
        Assert.Equal("validation", result.Error!.Type);
        Assert.Contains("Unsupported", result.Error.Message);
    }

    [Fact]
    public void Extract_OctetStream_UnknownExtension_ReturnsError()
    {
        using var stream = new MemoryStream(new byte[1]);

        var result = _extractor.Extract(stream, 1, "application/octet-stream", "file.xyz");

        Assert.False(result.IsSuccess);
        Assert.Equal("validation", result.Error!.Type);
    }

    [Fact]
    public void Extract_Pdf_ExtractsText()
    {
        var pdfBytes = CreateTestPdf("This is test PDF content.");
        using var stream = new MemoryStream(pdfBytes);

        var result = _extractor.Extract(stream, pdfBytes.Length, "application/pdf", "test.pdf");

        Assert.True(result.IsSuccess);
        Assert.Equal(DocumentType.Pdf, result.Value!.Type);
        Assert.Contains("test PDF content", result.Value.Text);
    }

    [Fact]
    public void Extract_Word_ExtractsText()
    {
        var docxBytes = CreateTestDocx("This is test Word content.");
        using var stream = new MemoryStream(docxBytes);

        var result = _extractor.Extract(stream, docxBytes.Length,
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "test.docx");

        Assert.True(result.IsSuccess);
        Assert.Equal(DocumentType.Word, result.Value!.Type);
        Assert.Contains("test Word content", result.Value.Text);
    }

    [Fact]
    public void Extract_Word_ViaOctetStream()
    {
        var docxBytes = CreateTestDocx("Shared from Outlook");
        using var stream = new MemoryStream(docxBytes);

        var result = _extractor.Extract(stream, docxBytes.Length, "application/octet-stream", "letter.docx");

        Assert.True(result.IsSuccess);
        Assert.Equal(DocumentType.Word, result.Value!.Type);
        Assert.Contains("Shared from Outlook", result.Value.Text);
    }

    private static byte[] CreateTestPdf(string text)
    {
        var builder = new PdfDocumentBuilder();
        var page = builder.AddPage(595, 842);
        var font = builder.AddStandard14Font(UglyToad.PdfPig.Fonts.Standard14Fonts.Standard14Font.Helvetica);
        page.AddText(text, 12, new UglyToad.PdfPig.Core.PdfPoint(50, 700), font);
        return builder.Build();
    }

    private static byte[] CreateTestDocx(string text)
    {
        using var ms = new MemoryStream();
        using (var doc = WordprocessingDocument.Create(ms, WordprocessingDocumentType.Document))
        {
            var mainPart = doc.AddMainDocumentPart();
            mainPart.Document = new Document(
                new Body(
                    new Paragraph(
                        new Run(
                            new Text(text)))));
        }
        return ms.ToArray();
    }
}
