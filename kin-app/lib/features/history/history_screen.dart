import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';

final _historyProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/me/history', queryParameters: {'weeks': 12});
  return (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(_historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Elo History')),
      body: history.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No rating history yet. Confirm a match to start!'));
          }

          // Chart points — items come newest-first, reverse for chronological
          final reversed = items.reversed.toList();
          final spots = reversed.asMap().entries.map((e) {
            final elo = (e.value['eloAfter'] as num).toDouble();
            return FlSpot(e.key.toDouble(), elo);
          }).toList();

          final minElo = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
          final maxElo = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Chart
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                  child: SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        minY: (minElo - 50).floorToDouble(),
                        maxY: (maxElo + 50).ceilToDouble(),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                          ),
                          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: Theme.of(context).colorScheme.primary,
                            barWidth: 2.5,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 3),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // List
              ...items.map((item) {
                final change = item['change'] as int? ?? 0;
                final isGain = change > 0;
                final date = item['createdAt']?.toString().split('T').first ?? '';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isGain ? Colors.green.shade50 : Colors.red.shade50,
                    child: Icon(
                      isGain ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isGain ? Colors.green : Colors.red,
                      size: 18,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text('${item['eloBefore']} → ${item['eloAfter']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(
                        '${isGain ? '+' : ''}$change',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: isGain ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(date),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
