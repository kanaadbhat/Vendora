import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'package:flutter/foundation.dart';
import '../models/productwithsubscribers.model.dart';

final productWithSubscribersProvider = StateNotifierProvider<ProductWithSubscribersViewModel, AsyncValue<List<ProductWithSubscribers>>>(
  (ref) => ProductWithSubscribersViewModel(ref),
);


class ProductWithSubscribersViewModel extends StateNotifier<AsyncValue<List<ProductWithSubscribers>>> {
  ProductWithSubscribersViewModel(this.ref) : super(const AsyncValue.data([]));

  final Ref ref;
  final ApiService _apiService = ApiService();

    Future<void> fetchDetails() async {
    state = const AsyncValue.loading();
    try {
      debugPrint('Fetching product details with subscribers...');
      final response = await _apiService.get('/vendorProduct/details');

      if (response.statusCode == 200) {
        final List<dynamic> detailsJson =
            response.data['productsWithSubscribers'] ?? [];

        final details =
            detailsJson.map((json) {
              try {
                return ProductWithSubscribers.fromJson(json);
              } catch (e) {
                debugPrint('Error parsing productWithSubscribers: $e');
                debugPrint('Problematic JSON: $json');
                rethrow;
              }
            }).toList();

        state = AsyncValue.data(details);
      } else {
        final errorMessage = response.data['message'];
        final error =
            errorMessage?.toString() ?? 'Failed to fetch product details';
        throw Exception(error);
      }
    } catch (e, stackTrace) {
      if (e is TypeError) {
        debugPrint('Type Error: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      state = AsyncValue.error(e, stackTrace);
    }
  }
}