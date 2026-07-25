import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/di.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/coach_suggestion.dart';

final coachSuggestionsProvider = FutureProvider<List<CoachSuggestion>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get<Map<String, dynamic>>(ApiEndpoints.coachSuggestions);
  final items = (res.data?['data'] ?? const []) as List<dynamic>;
  return [
    for (final s in items)
      CoachSuggestion(
        id: s['id'] as String,
        title: s['title'] as String,
        body: s['body'] as String? ?? '',
        type: s['type'] as String? ?? 'tip',
        actionLabel: s['actionLabel'] as String?,
        actionRoute: s['actionRoute'] as String?,
      ),
  ];
});
