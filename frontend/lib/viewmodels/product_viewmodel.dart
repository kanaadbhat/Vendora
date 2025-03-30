import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import 'package:flutter/foundation.dart';

final productProvider =
    StateNotifierProvider<ProductViewModel, AsyncValue<List<Product>>>((ref) {
      return ProductViewModel(ref);
    });

class ProductViewModel extends StateNotifier<AsyncValue<List<Product>>> {
  ProductViewModel(this.ref) : super(const AsyncValue.data([]));

  final Ref ref;
  final ApiService _apiService = ApiService();

  Future<void> fetchProducts() async {
    state = const AsyncValue.loading();
    try {
      debugPrint('Fetching products...');
      final response = await _apiService.get('/vendorProduct/all');

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = response.data['products'] ?? [];
        final products =
            productsJson.map((json) {
              try {
                return Product.fromJson(json);
              } catch (e) {
                debugPrint('Error parsing product: $e');
                debugPrint('Problematic JSON: $json');
                rethrow;
              }
            }).toList();
        state = AsyncValue.data(products);
      } else {
        final errorMessage = response.data['message'];
        final error = errorMessage?.toString() ?? 'Failed to fetch products';
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

  Future<void> addProduct(
    String name,
    String description,
    String price,
    String image,
  ) async {
    state = const AsyncValue.loading();
    try {
      debugPrint(
        'Adding product with data: name=$name, price=$price, image=$image',
      );
      final response = await _apiService.post(
        '/vendorProduct/add',
        data: {
          'name': name,
          'description': description,
          'price': price,
          'image': image,
        },
      );
      debugPrint('Add product response: ${response.data}');

      if (response.statusCode == 201) {
        // Fetch all products after adding a new one
        await fetchProducts();
      } else {
        final errorMessage =
            response.data['message']?.toString() ?? 'Failed to add product';
        debugPrint('Error response: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      debugPrint('Exception in addProduct: $e');
      debugPrint('Stack trace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId, String password) async {
    try {
      debugPrint('Deleting product: $productId');
      final response = await _apiService.delete(
        '/vendorProduct/delete/$productId',
        data: {'password': password},
      );
      debugPrint('Delete product response: ${response.data}');

      if (response.statusCode == 200) {
        debugPrint('Product deleted successfully: $productId');
        state = AsyncValue.data(
          state.value?.where((product) => product.id != productId).toList() ??
              [],
        );
      } else {
        final error =
            response.data['message']?.toString() ?? 'Failed to delete product';
        debugPrint('Error deleting product: $error');
        throw Exception(error);
      }
    } catch (e, stackTrace) {
      debugPrint('Exception in deleteProduct: $e');
      debugPrint('Stack trace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}
