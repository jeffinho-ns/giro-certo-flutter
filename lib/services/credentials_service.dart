import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda e recupera e-mail/senha de forma segura (criptografado).
/// Usado em conjunto com biometria para login rápido.
class CredentialsService {
  static const _keyEmail = 'giro_certo_saved_email';
  static const _keyPassword = 'giro_certo_saved_password';
  static const _keySaved = 'giro_certo_credentials_saved';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  /// Guarda e-mail e senha (apenas se [save] for true).
  static Future<void> saveCredentials({
    required String email,
    required String password,
    required bool save,
  }) async {
    if (save) {
      await _storage.write(key: _keyEmail, value: email);
      await _storage.write(key: _keyPassword, value: password);
      await _storage.write(key: _keySaved, value: 'true');
    } else {
      await clearCredentials();
    }
  }

  /// Retorna o e-mail guardado ou null.
  static Future<String?> getSavedEmail() => _storage.read(key: _keyEmail);

  /// Retorna a senha guardada ou null.
  static Future<String?> getSavedPassword() => _storage.read(key: _keyPassword);

  /// Indica se existem credenciais guardadas.
  static Future<bool> hasSavedCredentials() async {
    final saved = await _storage.read(key: _keySaved);
    if (saved != 'true') return false;
    final email = await _storage.read(key: _keyEmail);
    final password = await _storage.read(key: _keyPassword);
    return email != null && email.isNotEmpty && password != null && password.isNotEmpty;
  }

  /// Remove as credenciais guardadas.
  static Future<void> clearCredentials() async {
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyPassword);
    await _storage.delete(key: _keySaved);
  }
}
