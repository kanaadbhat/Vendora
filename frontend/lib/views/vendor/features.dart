import 'package:flutter/material.dart';
import '../../widgets/gradient_info_card.dart';
import 'product_list_screen.dart';

class VendorFeaturesScreen extends StatefulWidget {
  final ValueNotifier<String?>? featureKeyNotifier;
  const VendorFeaturesScreen({super.key, this.featureKeyNotifier});

  @override
  State<VendorFeaturesScreen> createState() => _VendorFeaturesScreenState();
}

class _VendorFeaturesScreenState extends State<VendorFeaturesScreen> {
  @override
  void initState() {
    super.initState();
    widget.featureKeyNotifier?.addListener(_handleFeatureKey);
  }

  @override
  void dispose() {
    widget.featureKeyNotifier?.removeListener(_handleFeatureKey);
    super.dispose();
  }

  void _handleFeatureKey() {
    final key = widget.featureKeyNotifier?.value;
    if (key == null) return;
    if (!mounted) return;
    switch (key) {
      case 'products':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProductListScreen()),
        );
        break;
    }
    widget.featureKeyNotifier?.value = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Features')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GradientInfoCard(
            icon: Icons.inventory,
            title: 'My Products',
            description: 'View and manage all your products.',
            gradientColors: [Colors.orange, Colors.deepOrangeAccent],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductListScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
