namespace ShareDocApp.Backend.Documents;

// MIME + extension sniffing (incl. octet-stream fallback)
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
}
