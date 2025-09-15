import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/cost_monitoring_service.dart';

class CostMonitoringWidget extends StatefulWidget {
  /// Whether to show the widget regardless of build mode
  final bool forceShow;

  const CostMonitoringWidget({super.key, this.forceShow = false});

  @override
  State<CostMonitoringWidget> createState() => _CostMonitoringWidgetState();
}

class _CostMonitoringWidgetState extends State<CostMonitoringWidget> {
  double _totalCost = 0.0;
  Map<String, double> _costBreakdown = {};
  bool _isLoading = true;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    // Only show in debug mode or when forced
    _isVisible = kDebugMode || widget.forceShow;
    if (_isVisible) {
      _loadCostData();
    }
  }

  Future<void> _loadCostData() async {
    setState(() => _isLoading = true);

    try {
      final totalCost = await CostMonitoringService.getTotalDailyCost();
      final breakdown = await CostMonitoringService.getCostBreakdown();

      setState(() {
        _totalCost = totalCost;
        _costBreakdown = breakdown;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
      if (_isVisible && (_totalCost == 0.0 && _costBreakdown.isEmpty)) {
        _loadCostData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Hide completely in release mode unless forced
    if (!kDebugMode && !widget.forceShow) {
      return const SizedBox.shrink();
    }

    // Show toggle button when not visible
    if (!_isVisible) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.developer_mode, color: Colors.blue),
          title: const Text('Cost Monitoring'),
          subtitle: const Text('Dev Mode - Tap to view API costs'),
          trailing: const Icon(Icons.visibility),
          onTap: _toggleVisibility,
        ),
      );
    }
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final costPercentage = (_totalCost / 100.0).clamp(0.0, 1.0);
    final isWarning = costPercentage >= 0.5;
    final isDanger = costPercentage >= 0.8;

    Color progressColor = Colors.green;
    if (isDanger) {
      progressColor = Colors.red;
    } else if (isWarning) {
      progressColor = Colors.orange;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Daily API Costs (Dev Mode)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadCostData,
                  tooltip: 'Refresh cost data',
                ),
                IconButton(
                  icon: const Icon(Icons.visibility_off),
                  onPressed: _toggleVisibility,
                  tooltip: 'Hide cost monitor',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Cost indicator
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: costPercentage,
                    backgroundColor: Colors.grey.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'RM${_totalCost.toStringAsFixed(2)} / RM100.00',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Warning messages
            if (isDanger)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'DANGER: Approaching daily limit!',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (isWarning)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Warning: 50% of daily limit used',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (isDanger || isWarning) const SizedBox(height: 12),

            // Cost breakdown
            if (_costBreakdown.isNotEmpty) ...[
              Text(
                'Cost Breakdown:',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._costBreakdown.entries.map((entry) {
                final serviceName = _formatServiceName(entry.key);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        serviceName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'RM${entry.value.toStringAsFixed(3)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 12),

            // Safety features info
            ExpansionTile(
              title: Text(
                'Safety Features Active',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('✅ Input validation prevents empty requests'),
                      Text('✅ Rate limiting (50 requests/hour)'),
                      Text('✅ Daily cost limit (RM100)'),
                      Text('✅ Automatic retry prevention'),
                      Text('✅ Local caching saves repeated calls'),
                      Text('✅ User confirmation for expensive operations'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatServiceName(String serviceName) {
    switch (serviceName) {
      case 'gemini_enhance':
        return 'Prompt Enhancement';
      case 'gemini_suggestions':
        return 'AI Suggestions';
      case 'gemini_chat':
        return 'AI Chat';
      case 'vertex_ai_generation':
        return 'Image Generation';
      default:
        return serviceName
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (word) =>
                  word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
            )
            .join(' ');
    }
  }
}
