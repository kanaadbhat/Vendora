import 'package:flutter/material.dart';
import '../../widgets/gradient_info_card.dart';
import 'product_list_screen.dart';

class VendorFeaturesScreen extends StatelessWidget {
  const VendorFeaturesScreen({super.key});

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
