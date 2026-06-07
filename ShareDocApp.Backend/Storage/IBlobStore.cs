namespace ShareDocApp.Backend.Storage;

public interface IBlobStore
{
    Task<string> UploadAsync(string userId, string fileName, Stream content, string contentType, CancellationToken ct);
    Task<Stream?> DownloadAsync(string blobRef, CancellationToken ct);
    Task DeleteAsync(string blobRef, CancellationToken ct);
}
