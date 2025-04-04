import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import 'package:flutter/foundation.dart';

final userProvider =
    StateNotifierProvider<UserViewModel, AsyncValue<List<User>>>(
      (ref) => UserViewModel(ref),
    );

class UserViewModel extends StateNotifier<AsyncValue<List<User>>> {
  UserViewModel(this.ref) : super(const AsyncValue.data([]));

  final Ref ref;
  final ApiService _apiService = ApiService();

  Future<void> fetchVendors() async {
    state = const AsyncValue.loading();
    try {
      debugPrint('Fetching vendors...');
      final response = await _apiService.get('/userProduct/vendors');

      if (response.statusCode == 200) {
        final List<dynamic> vendorsJson = response.data['data'] ?? [];
        final vendors =
            vendorsJson.map((json) {
              try {
                return User.fromJson(json);
              } catch (e) {
                debugPrint('Error parsing vendor: $e');
                debugPrint('Problematic JSON: $json');
                rethrow;
              }
            }).toList();
        state = AsyncValue.data(vendors);
      } else {
        final errorMessage = response.data['message'];
        final error = errorMessage?.toString() ?? 'Failed to fetch vendors';
        throw Exception(error);
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching vendors: $e');
      debugPrint('Stack trace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<List<Product>> fetchVendorProducts(String vendorId) async {
    try {
      debugPrint('Fetching products for vendor: $vendorId');
      final response = await _apiService.get(
        '/userProduct/vendors/$vendorId/products',
      );

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = response.data['data'] ?? [];
        return productsJson.map((json) {
          try {
            return Product.fromJson(json);
          } catch (e) {
            debugPrint('Error parsing product: $e');
            debugPrint('Problematic JSON: $json');
            rethrow;
          }
        }).toList();
      } else {
        final error =
            response.data['message']?.toString() ??
            'Failed to fetch vendor products';
        debugPrint('Error fetching vendor products: $error');
        throw Exception(error);
      }
    } catch (e, stackTrace) {
      debugPrint('Exception in fetchVendorProducts: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
