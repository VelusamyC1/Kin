import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

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
            return Center(child: Text('No rating history yet', style: TextStyle(color: Colors.white.withOpacity(0.4))));
          }

          final reversed = items.reversed.toList();
          final spots = reversed.asMap().entries.map((e) {
            final elo = (e.value['eloAfter'] as num).toDouble();
            return FlSpot(e.key.toDouble(), elo);
          }).toList();

          final minElo = spots.map((s) => s.y).reduce(math.min);
          final maxElo = spots.map((s) => s.y).reduce(math.max);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Chart
              Container(
                padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
                decoration: BoxDecoration(color: kDarkCard, borderRadius: BorderRadius.circular(16)),
                child: SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      minY: (minElo - 50).floorToDouble(),
                      maxY: (maxElo + 50).ceilToDouble(),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)))),
                        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: kLime,
                          barWidth: 2.5,
                          dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 3, color: kLime, strokeColor: kNavy, strokeWidth: 2)),
                          belowBarData: BarAreaData(show: true, color: kLime.withOpacity(0.08)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // List
              ...items.map((item) {
                final change = item['change'] as int? ?? 0;
                final isGain = change > 0;
                final date = item['createdAt']?.toString().split('T').first ?? '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: kDarkCard, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isGain ? Colors.green : Colors.red).withOpacity(0.15),
                        ),
                        child: Icon(isGain ? Icons.arrow_upward : Icons.arrow_downward, color: isGain ? Colors.green : Colors.red, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${item['eloBefore']} → ${item['eloAfter']}', style: const TextStyle(color: kWhite, fontWeight: FontWeight.w600)),
                            Text(date, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(
                        '${isGain ? '+' : ''}$change',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isGain ? kLime : Colors.red),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: kLime)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}
