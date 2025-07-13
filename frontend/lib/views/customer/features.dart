import 'package:flutter/material.dart';
import '../../widgets/gradient_info_card.dart';
import 'explore_vendors_screen.dart';
import 'subscription_screen.dart';
import 'payment.dart';

class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Features')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GradientInfoCard(
            icon: Icons.store,
            title: 'Explore Vendors',
            description: 'Browse and discover new vendors to subscribe to.',
            gradientColors: [Colors.blue, Colors.blueAccent],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExploreVendorsScreen(),
                ),
              );
            },
          ),
          GradientInfoCard(
            icon: Icons.subscriptions,
            title: 'My Subscriptions',
            description: 'View and manage all your active subscriptions.',
            gradientColors: [Colors.purple, Colors.deepPurpleAccent],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionScreen(),
                ),
              );
            },
          ),
          GradientInfoCard(
            icon: Icons.payment,
            title: 'Payments',
            description: 'Pay your vendors directly from here.',
            gradientColors: [Colors.green, Colors.teal],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaymentScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
