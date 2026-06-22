import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

final meProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/me');
  return Map<String, dynamic>.from(res.data as Map);
});

final myMatchesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/me/matches');
  return (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
});
