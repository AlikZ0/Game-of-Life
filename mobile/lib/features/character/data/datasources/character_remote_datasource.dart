import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../models/character_model.dart';

class CharacterRemoteDataSource {
  const CharacterRemoteDataSource(this._dio);
  final Dio _dio;

  Future<CharacterModel> me() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.characterMe);
    return CharacterModel.fromJson(res.data!);
  }

  Future<CharacterModel> create({
    required String name,
    required String characterClass,
    required String avatarKey,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.createCharacter,
      data: {'name': name, 'class': characterClass, 'avatarKey': avatarKey},
    );
    return CharacterModel.fromJson(res.data!);
  }
}
