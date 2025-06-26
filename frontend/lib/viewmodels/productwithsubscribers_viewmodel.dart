import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/productwithsubscribers.model.dart';
import '../services/api_service.dart';

final productWithSubscribersProvider = AsyncNotifierProvider.family<
  ProductWithSubscribersNotifier,
  List<ProductWithSubscribers>,
  String
>(
  ProductWithSubscribersNotifier.new,
);

class ProductWithSubscribersNotifier
    extends FamilyAsyncNotifier<List<ProductWithSubscribers>, String> {
  final ApiService _apiService = ApiService();

  @override
  Future<List<ProductWithSubscribers>> build(String userId) async {
    debugPrint('[DEBUG] Fetching ProductWithSubscribers for userId: $userId');

    try {
      final response = await _apiService.get('/vendorProduct/details');

      if (response.statusCode == 200) {
        final List<dynamic> detailsJson =
            response.data['productsWithSubscribers'] ?? [];

        final details = detailsJson.map((json) {
          try {
            return ProductWithSubscribers.fromJson(json);
          } catch (e) {
            debugPrint('[ERROR] Parsing ProductWithSubscribers: $e');
            debugPrint('[DATA] JSON: $json');
            rethrow;
          }
        }).toList();

        return details;
      } else {
        final errorMessage = response.data['message'];
        throw Exception(
            errorMessage?.toString() ?? 'Failed to fetch product details');
      }
    } catch (e, stackTrace) {
      debugPrint('[ERROR] ProductWithSubscribers fetch error: $e');
      throw AsyncError(e, stackTrace);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(arg));
  }
}
