import '../core/result.dart';
import 'api_client.dart';

class UserProfile {
  final String id;
  final String displayName;
  final String email;
  final bool persistDocs;
  final bool consentConfigured;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    required this.persistDocs,
    required this.consentConfigured,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        displayName: json['displayName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        persistDocs: json['persistDocs'] as bool? ?? false,
        consentConfigured: json['consentConfigured'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class UsersApi {
  final ApiClient _client;

  UsersApi(this._client);

  Future<Result<UserProfile>> register() =>
      _client.post('/users', null, (json) => UserProfile.fromJson(json));

  Future<Result<UserProfile>> getMe() =>
      _client.get('/users/me', (json) => UserProfile.fromJson(json));

  Future<Result<UserProfile>> updateConsent(bool persistDocs) =>
      _client.put('/users/me/consent', {'persistDocs': persistDocs},
          (json) => UserProfile.fromJson(json));

  Future<Result<UserProfile>> updateProfile(
    String displayName,
    String email,
  ) =>
      _client.put(
        '/users/me',
        {'displayName': displayName, 'email': email},
        (json) => UserProfile.fromJson(json),
      );

  Future<Result<void>> deleteMe() => _client.delete('/users/me');
}
