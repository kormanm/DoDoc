class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:7071/api',
  );

  static const String entraClientId = String.fromEnvironment(
    'ENTRA_CLIENT_ID',
    defaultValue: '',
  );

  static const String entraIssuer = String.fromEnvironment(
    'ENTRA_ISSUER',
    defaultValue: '',
  );

  static const String entraRedirectUri = 'com.sharedoc.app://oauth';
  static const String taskDeepLinkScheme = 'sharedoc';
  static const String taskDeepLinkHost = 'task';
  static const String todoListName = 'ShareDoc';
  static const String graphBaseUrl = 'https://graph.microsoft.com/v1.0';
  static const List<String> graphScopes = [
    'openid',
    'profile',
    'email',
    'offline_access',
    'Tasks.ReadWrite',
  ];

  static const String entraDiscoveryUrl = String.fromEnvironment(
    'ENTRA_DISCOVERY_URL',
    defaultValue: '',
  );

  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  static const List<String> allowedExtensions = [
    '.pdf',
    '.docx',
    '.jpg',
    '.jpeg',
    '.png',
    '.txt',
  ];
}
