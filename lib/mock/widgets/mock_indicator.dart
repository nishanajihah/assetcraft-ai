import 'package:flutter/material.dart';
import '../mock_config.dart';

/// Widget that shows a banner when the app is running in mock mode
/// Helps developers remember they're using mock data
class MockIndicator extends StatelessWidget {
  final Widget child;
  
  const MockIndicator({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!MockConfig.showMockIndicator) {
      return child;
    }

    return Stack(
      children: [
        child,
        if (MockConfig.isMockModeEnabled)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildMockBanner(context),
          ),
      ],
    );
  }

  Widget _buildMockBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.9),
            Colors.deepOrange.withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.science,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              _getMockStatusText(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showMockDetails(context),
              child: const Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMockStatusText() {
    final activeMocks = <String>[];
    
    if (MockConfig.isMockAiEnabled) activeMocks.add('AI');
    if (MockConfig.isMockStorageEnabled) activeMocks.add('Storage');
    if (MockConfig.isMockStoreEnabled) activeMocks.add('Store');
    if (MockConfig.isMockNotificationsEnabled) activeMocks.add('Notifications');
    if (MockConfig.isMockAuthEnabled) activeMocks.add('Auth');
    if (MockConfig.isMockGemstonesEnabled) activeMocks.add('Gemstones');

    if (activeMocks.length == 1) {
      return 'MOCK MODE - ${activeMocks.first}';
    } else if (activeMocks.length <= 3) {
      return 'MOCK MODE - ${activeMocks.join(', ')}';
    } else {
      return 'MOCK MODE - ${activeMocks.length} Services';
    }
  }

  void _showMockDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.science, color: Colors.orange),
            SizedBox(width: 8),
            Text('Mock Mode Active'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The app is currently running with mock data:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildMockStatusList(),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Text(
                '⚠️ Remember to disable mock mode for production builds!',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.deepOrange,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildMockStatusList() {
    final mockServices = [
      ('AI Generation', MockConfig.isMockAiEnabled),
      ('Storage Service', MockConfig.isMockStorageEnabled),
      ('Store/Purchases', MockConfig.isMockStoreEnabled),
      ('Notifications', MockConfig.isMockNotificationsEnabled),
      ('Authentication', MockConfig.isMockAuthEnabled),
      ('Gemstones', MockConfig.isMockGemstonesEnabled),
    ];

    return Column(
      children: mockServices.map((service) {
        final name = service.$1;
        final isEnabled = service.$2;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(
                isEnabled ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: isEnabled ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  color: isEnabled ? Colors.black87 : Colors.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Helper widget for development screens to show mock status
class MockStatusChip extends StatelessWidget {
  const MockStatusChip({super.key});

  @override
  Widget build(BuildContext context) {
    if (!MockConfig.isMockModeEnabled) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.science, size: 14, color: Colors.orange),
          SizedBox(width: 4),
          Text(
            'Mock',
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
