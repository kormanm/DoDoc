namespace ShareDocApp.Backend.Documents;

public enum DocumentType
{
    Pdf,
    Word,
    Image,
    PlainText,
    Unknown
}

public static class DocumentTypeDetector
{
    private static readonly Dictionary<string, DocumentType> MimeMap = new(StringComparer.OrdinalIgnoreCase)
    {
        ["application/pdf"] = DocumentType.Pdf,
        ["application/vnd.openxmlformats-officedocument.wordprocessingml.document"] = DocumentType.Word,
        ["image/jpeg"] = DocumentType.Image,
        ["image/png"] = DocumentType.Image,
        ["image/jpg"] = DocumentType.Image,
        ["text/plain"] = DocumentType.PlainText,
    };

    private static readonly Dictionary<string, DocumentType> ExtMap = new(StringComparer.OrdinalIgnoreCase)
    {
        [".pdf"] = DocumentType.Pdf,
        [".docx"] = DocumentType.Word,
        [".jpg"] = DocumentType.Image,
        [".jpeg"] = DocumentType.Image,
        [".png"] = DocumentType.Image,
        [".txt"] = DocumentType.PlainText,
    };

    public static DocumentType Detect(string? mime, string? fileName)
    {
        if (!string.IsNullOrWhiteSpace(mime)
            && mime != "application/octet-stream"
            && MimeMap.TryGetValue(mime, out var fromMime))
        {
            return fromMime;
        }

        if (!string.IsNullOrWhiteSpace(fileName))
        {
            var ext = Path.GetExtension(fileName);
            if (!string.IsNullOrEmpty(ext) && ExtMap.TryGetValue(ext, out var fromExt))
                return fromExt;
        }

        return DocumentType.Unknown;
    }
}
