using Azure.Data.Tables;
using Azure.Storage.Blobs;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using ShareDocApp.Backend.Ai;
using ShareDocApp.Backend.Auth;
using ShareDocApp.Backend.Documents;
using ShareDocApp.Backend.Storage;

var host = new HostBuilder()
    .ConfigureFunctionsWebApplication()
    .ConfigureServices((context, services) =>
    {
        services.AddApplicationInsightsTelemetryWorkerService();
        services.ConfigureFunctionsApplicationInsights();

        var config = context.Configuration;

        services.AddSingleton<EntraTokenValidator>(sp =>
            new EntraTokenValidator(
                config["Entra:Issuer"] ?? throw new InvalidOperationException("Entra:Issuer not configured"),
                config["Entra:Audience"] ?? throw new InvalidOperationException("Entra:Audience not configured"),
                config["Entra:MetadataAddress"] ?? throw new InvalidOperationException("Entra:MetadataAddress not configured")));

        var storageConn = config["StorageConnection"]
            ?? throw new InvalidOperationException("StorageConnection not configured");

        services.AddSingleton(new TableServiceClient(storageConn));
        services.AddSingleton(new BlobServiceClient(storageConn));

        services.AddSingleton<ITaskStore>(sp =>
            new TableTaskStore(sp.GetRequiredService<TableServiceClient>()));
        services.AddSingleton<IUserStore>(sp =>
            new TableUserStore(sp.GetRequiredService<TableServiceClient>()));
        services.AddSingleton<IBlobStore>(sp =>
            new BlobStore(sp.GetRequiredService<BlobServiceClient>()));

        var aiProvider = config["Ai:Provider"] ?? "openai";
        if (aiProvider == "openai")
        {
            var apiKey = config["OpenAiApiKey"]
                ?? throw new InvalidOperationException("OpenAiApiKey not configured");
            var model = config["Ai:Model"] ?? "gpt-4o-mini";
            services.AddSingleton<IAiProvider>(new OpenAiProvider(apiKey, model));
        }
        else
        {
            throw new InvalidOperationException($"Unsupported AI provider: '{aiProvider}'. Only 'openai' is supported in v1.");
        }

        services.AddSingleton<TextExtractor>();
    })
    .Build();

host.Run();
