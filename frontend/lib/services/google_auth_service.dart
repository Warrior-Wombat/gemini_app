import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart' as auth;

class GoogleAuthService {
  Future<auth.AccessCredentials> _obtainAccessCredentials() async {
    final credentialsJson = await rootBundle.loadString('assets/credentials/vertex-ai-credentials.json');
    final credentials = json.decode(credentialsJson);

    final accountCredentials = auth.ServiceAccountCredentials.fromJson(credentials);
    final scopes = ['https://www.googleapis.com/auth/cloud-platform'];

    final client = await auth.clientViaServiceAccount(accountCredentials, scopes);
    return client.credentials;
  }

  Future<String> getAccessToken() async {
    final credentials = await _obtainAccessCredentials();
    return credentials.accessToken.data;
  }
}
