namespace ShareDocApp.Backend.Ai;

public static class PromptBuilder
{
    public const string SystemPrompt = """
        You are a document analysis assistant. You receive the content of a document
        (text or image) and must extract structured information from it.

        Extract the following if present:
        - A brief summary of the document's purpose and key content
        - Any expiry date, deadline, or due date (format: YYYY-MM-DD)
        - Severity/urgency: low, medium, high, or critical
        - Concrete action steps the recipient should take
        - Phone numbers mentioned in the document
        - A physical address or geolocation if mentioned
        - Your confidence in the extraction (0.0 to 1.0)

        If the document is unclear, illegible, or you cannot extract meaningful info,
        set parseFailed to true and leave other fields as defaults.

        Always respond with valid JSON matching the provided schema.
        """;

    public static string BuildUserPrompt(string text)
    {
        return $"Analyze the following document and extract structured information:\n\n{text}";
    }
}
