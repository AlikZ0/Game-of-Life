import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

/// Talks to the auth endpoints. Auth calls set `skipAuth` so they don't attach
/// a (possibly stale) bearer token.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);
  final Dio _dio;

  static final _noAuth = Options(extra: const {'skipAuth': true});

  Future<AuthResponseModel> login(String email, String password) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
      options: _noAuth,
    );
    return AuthResponseModel.fromJson(res.data!);
  }

  Future<AuthResponseModel> register(String email, String password) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      data: {'email': email, 'password': password},
      options: _noAuth,
    );
    return AuthResponseModel.fromJson(res.data!);
  }

  Future<AuthResponseModel> google(String idToken) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.oauthGoogle,
      data: {'idToken': idToken},
      options: _noAuth,
    );
    return AuthResponseModel.fromJson(res.data!);
  }

  Future<AuthResponseModel> apple(String identityToken, String? fullName) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.oauthApple,
      data: {'identityToken': identityToken, if (fullName != null) 'fullName': fullName},
      options: _noAuth,
    );
    return AuthResponseModel.fromJson(res.data!);
  }

  Future<UserModel> me() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.me);
    return UserModel.fromJson(res.data!);
  }

  Future<void> logout() => _dio.post<void>(ApiEndpoints.logout);
}
