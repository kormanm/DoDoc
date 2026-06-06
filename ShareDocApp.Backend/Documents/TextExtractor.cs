using System.Text;
using DocumentFormat.OpenXml.Packaging;
using ShareDocApp.Backend.Common;
using UglyToad.PdfPig;

namespace ShareDocApp.Backend.Documents;

public record ExtractionResult(DocumentType Type, string? Text, byte[]? ImageBytes, string Mime);

public class TextExtractor
{
    public Result<ExtractionResult> Extract(Stream content, long length, string? mime, string? fileName)
    {
        if (length > Validation.MaxFileSizeBytes)
            return Errors.Validation($"File exceeds {Validation.MaxFileSizeBytes / (1024 * 1024)} MB limit");

        var docType = DocumentTypeDetector.Detect(mime, fileName);
        if (docType == DocumentType.Unknown)
            return Errors.Validation($"Unsupported file type: mime={mime}, file={fileName}");

        return docType switch
        {
            DocumentType.Pdf => ExtractPdf(content, mime ?? "application/pdf"),
            DocumentType.Word => ExtractWord(content, mime ?? "application/vnd.openxmlformats-officedocument.wordprocessingml.document"),
            DocumentType.PlainText => ExtractPlainText(content, mime ?? "text/plain"),
            DocumentType.Image => ExtractImage(content, length, mime ?? "image/jpeg"),
            _ => Errors.Validation("Unsupported file type")
        };
    }

    private static Result<ExtractionResult> ExtractPdf(Stream content, string mime)
    {
        try
        {
            using var document = PdfDocument.Open(content);
            var sb = new StringBuilder();
            foreach (var page in document.GetPages())
            {
                sb.AppendLine(page.Text);
            }
            var text = sb.ToString().Trim();
            return new ExtractionResult(DocumentType.Pdf, text, null, mime);
        }
        catch (Exception ex)
        {
            return Errors.Validation($"Failed to parse PDF: {ex.Message}");
        }
    }

    private static Result<ExtractionResult> ExtractWord(Stream content, string mime)
    {
        try
        {
            using var doc = WordprocessingDocument.Open(content, false);
            var body = doc.MainDocumentPart?.Document?.Body;
            if (body == null)
                return new ExtractionResult(DocumentType.Word, "", null, mime);

            var sb = new StringBuilder();
            foreach (var para in body.Elements<DocumentFormat.OpenXml.Wordprocessing.Paragraph>())
            {
                sb.AppendLine(para.InnerText);
            }
            var text = sb.ToString().Trim();
            return new ExtractionResult(DocumentType.Word, text, null, mime);
        }
        catch (Exception ex)
        {
            return Errors.Validation($"Failed to parse Word document: {ex.Message}");
        }
    }

    private static Result<ExtractionResult> ExtractPlainText(Stream content, string mime)
    {
        try
        {
            using var reader = new StreamReader(content, Encoding.UTF8, detectEncodingFromByteOrderMarks: true);
            var text = reader.ReadToEnd().Trim();
            return new ExtractionResult(DocumentType.PlainText, text, null, mime);
        }
        catch
        {
            content.Position = 0;
            using var reader = new StreamReader(content, Encoding.Latin1);
            var text = reader.ReadToEnd().Trim();
            return new ExtractionResult(DocumentType.PlainText, text, null, mime);
        }
    }

    private static Result<ExtractionResult> ExtractImage(Stream content, long length, string mime)
    {
        using var ms = new MemoryStream();
        content.CopyTo(ms);
        return new ExtractionResult(DocumentType.Image, null, ms.ToArray(), mime);
    }
}
