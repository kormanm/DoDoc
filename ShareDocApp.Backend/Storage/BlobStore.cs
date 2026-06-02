namespace ShareDocApp.Backend.Storage;

public class BlobStore : IBlobStore
{
    public Task<string> UploadAsync(string userId, string fileName, Stream content, string contentType, CancellationToken ct) => throw new NotImplementedException();
    public Task<Stream?> DownloadAsync(string blobRef, CancellationToken ct) => throw new NotImplementedException();
    public Task DeleteAsync(string blobRef, CancellationToken ct) => throw new NotImplementedException();
}
