import 'package:flutter/foundation.dart';
import '../api/users_api.dart';

class ConsentService extends ChangeNotifier {
  final UsersApi _usersApi;
  bool _persistDocs = false;
  bool _consentShown = false;

  bool get persistDocs => _persistDocs;
  bool get consentShown => _consentShown;

  ConsentService(this._usersApi);

  Future<void> loadFromProfile() async {
    await _usersApi.register();
    final result = await _usersApi.getMe();
    if (result.isSuccess) {
      _persistDocs = result.value!.persistDocs;
      _consentShown = true;
      notifyListeners();
    }
  }

  Future<void> updateConsent(bool persist) async {
    await _usersApi.register();
    final result = await _usersApi.updateConsent(persist);
    if (result.isSuccess) {
      _persistDocs = persist;
      _consentShown = true;
      notifyListeners();
    }
  }
}
