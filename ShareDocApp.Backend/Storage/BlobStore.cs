using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;

namespace ShareDocApp.Backend.Storage;

public class BlobStore : IBlobStore
{
    private const string ContainerName = "documents";
    private readonly BlobContainerClient _container;

    public BlobStore(BlobServiceClient serviceClient)
    {
        _container = serviceClient.GetBlobContainerClient(ContainerName);
        _container.CreateIfNotExists();
    }

    public async Task<string> UploadAsync(string userId, string fileName, Stream content, string contentType, CancellationToken ct)
    {
        var blobName = $"{userId}/{Guid.NewGuid()}/{fileName}";
        var blob = _container.GetBlobClient(blobName);
        await blob.UploadAsync(content, new BlobHttpHeaders { ContentType = contentType }, cancellationToken: ct);
        return blobName;
    }

    public async Task<Stream?> DownloadAsync(string blobRef, CancellationToken ct)
    {
        var blob = _container.GetBlobClient(blobRef);
        if (!await blob.ExistsAsync(ct))
            return null;
        var response = await blob.DownloadStreamingAsync(cancellationToken: ct);
        return response.Value.Content;
    }

    public async Task DeleteAsync(string blobRef, CancellationToken ct)
    {
        var blob = _container.GetBlobClient(blobRef);
        await blob.DeleteIfExistsAsync(cancellationToken: ct);
    }
}
