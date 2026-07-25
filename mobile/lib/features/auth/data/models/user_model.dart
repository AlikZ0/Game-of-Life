import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/auth_user.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// DTO for the API `User` resource returned by `/auth/me` and auth responses.
@freezed
class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    required String id,
    required String email,
    @Default('EMAIL') String provider,
    @JsonKey(name: 'emailVerified') @Default(false) bool emailVerified,
    @JsonKey(name: 'hasCharacter') @Default(false) bool hasCharacter,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  AuthUser toEntity() => AuthUser(
        id: id,
        email: email,
        provider: provider,
        emailVerified: emailVerified,
        hasCharacter: hasCharacter,
      );
}
