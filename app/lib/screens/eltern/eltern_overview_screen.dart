import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../models/participant.dart';
import '../../models/point_transaction.dart';
import '../../services/demo_service.dart';

class ElternOverviewScreen extends StatelessWidget {
  final List<Participant> children;

  const ElternOverviewScreen({super.key, required this.children});

  static const _childColors = [
    AppTheme.success,
    AppTheme.violet,
    AppTheme.brand,
    AppTheme.warning,
    AppTheme.danger,
  ];

  @override
  Widget build(BuildContext context) {
    final childData = children.map((child) {
      final p = DemoService().getParticipant(child.id) ?? child;
      final txs = DemoService().getTransactions(p.id);
      final leaderboard = DemoService().getLeaderboard(p.eventId);
      final rank = leaderboard.indexWhere((x) => x.id == p.id) + 1;
      final earned =
          txs.where((t) => t.amount > 0).fold<int>(0, (s, t) => s + t.amount);
      final spent =
          txs.where((t) => t.amount < 0).fold<int>(0, (s, t) => s + t.amount.abs());
      final redeemed = txs.where((t) => t.reason == 'redemption').length;
      final lastTx = txs.isNotEmpty ? txs.first : null;
      return _ChildData(
        participant: p,
        earned: earned,
        spent: spent,
        redeemed: redeemed,
        rank: rank,
        totalParticipants: leaderboard.length,
        lastTransaction: lastTx,
        transactionCount: txs.length,
      );
    }).toList();

    final totalPoints = childData.fold<int>(0, (s, c) => s + c.participant.balance);
    final totalEarned = childData.fold<int>(0, (s, c) => s + c.earned);
    final bestRank = childData.fold<int>(
        999, (m, c) => c.rank > 0 ? min(m, c.rank) : m);

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _summaryCard(context, totalPoints, totalEarned, bestRank,
              childData.length)
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.15, end: 0, duration: 600.ms,
                  curve: Curves.easeOutCubic),
          const SizedBox(height: 20),
          _quickStats(context, childData)
              .animate()
              .fadeIn(duration: 500.ms, delay: 100.ms),
          const SizedBox(height: 20),
          ...childData.asMap().entries.map((entry) {
            final i = entry.key;
            final data = entry.value;
            final color = _childColors[i % _childColors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _childCard(context, data, color)
                  .animate()
                  .fadeIn(duration: 500.ms, delay: (200 + i * 80).ms)
                  .slideY(begin: 0.06, end: 0,
                      duration: 500.ms, delay: (200 + i * 80).ms),
            );
          }),
        ],
      ),
    );
  }

  Widget _summaryCard(BuildContext context, int totalPoints, int totalEarned,
      int bestRank, int childCount) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.success, Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.success.withAlpha(50),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.family_restroom,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '$childCount ${childCount == 1 ? 'Kind' : 'Kinder'}',
                      style: TextStyle(
                        color: Colors.white.withAlpha(220),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Punkte gesamt',
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 13,
              letterSpacing: 1,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: totalPoints.toDouble()),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(
              '${v.toInt()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 52,
                fontWeight: FontWeight.bold,
                letterSpacing: -2,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _summaryBadge('+$totalEarned verdient', Icons.trending_up),
              if (bestRank < 999) ...[
                const SizedBox(width: 8),
                _summaryBadge('Beste: Platz $bestRank', Icons.emoji_events),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickStats(BuildContext context, List<_ChildData> childData) {
    final totalEarned = childData.fold<int>(0, (s, c) => s + c.earned);
    final totalSpent = childData.fold<int>(0, (s, c) => s + c.spent);
    final totalRedeemed = childData.fold<int>(0, (s, c) => s + c.redeemed);

    return Row(
      children: [
        Expanded(
          child: _quickStatCard(context, totalEarned, 'Verdient',
              Icons.trending_up, AppTheme.success),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _quickStatCard(context, totalSpent, 'Ausgegeben',
              Icons.shopping_bag, AppTheme.danger),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _quickStatCard(context, totalRedeemed, 'Prämien',
              Icons.card_giftcard, AppTheme.brand),
        ),
      ],
    );
  }

  Widget _quickStatCard(BuildContext context, int value, String label,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(
              '${v.toInt()}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withAlpha(180)),
          ),
        ],
      ),
    );
  }

  Widget _childCard(BuildContext context, _ChildData data, Color accentColor) {
    final p = data.participant;
    final maxBalance =
        data.totalParticipants > 0 ? _maxBalanceInLeaderboard(p.eventId) : 1;
    final balanceFraction =
        maxBalance > 0 ? p.balance / maxBalance : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withAlpha(5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withAlpha(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withAlpha(160)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    p.displayName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (p.group != null) ...[
                          Icon(Icons.groups,
                              size: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            p.group!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (p.group != null && p.age != null)
                          Text(
                            ' · ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        if (p.age != null)
                          Text(
                            '${p.age} Jahre',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: p.balance.toDouble()),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Text(
                      '${v.toInt()}',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  Text(
                    'Punkte',
                    style: TextStyle(
                      fontSize: 11,
                      color: accentColor.withAlpha(160),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Container(color: accentColor.withAlpha(15)),
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                        begin: 0, end: balanceFraction.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => FractionallySizedBox(
                      widthFactor: v,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accentColor, accentColor.withAlpha(140)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _childStat(context, Icons.trending_up, '+${data.earned}',
                  'Verdient', AppTheme.success),
              const SizedBox(width: 12),
              _childStat(context, Icons.card_giftcard, '${data.redeemed}',
                  'Eingelöst', AppTheme.brand),
              const SizedBox(width: 12),
              _childStat(
                  context,
                  Icons.emoji_events,
                  data.rank > 0 ? 'Platz ${data.rank}' : '—',
                  'Rang',
                  const Color(0xFFFFD700)),
            ],
          ),
          if (data.lastTransaction != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    data.lastTransaction!.amount >= 0
                        ? Icons.add_circle_outline
                        : Icons.remove_circle_outline,
                    size: 16,
                    color: data.lastTransaction!.amount >= 0
                        ? AppTheme.success
                        : AppTheme.danger,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${data.lastTransaction!.note ?? _reasonLabel(data.lastTransaction!.reason)} · ${data.lastTransaction!.amount >= 0 ? "+" : ""}${data.lastTransaction!.amount} P',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _relativeTime(
                        DateTime.tryParse(data.lastTransaction!.createdAt)),
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _childStat(BuildContext context, IconData icon, String value,
      String label, Color color) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _maxBalanceInLeaderboard(String eventId) {
    final leaderboard = DemoService().getLeaderboard(eventId);
    if (leaderboard.isEmpty) return 1;
    return leaderboard.first.balance;
  }

  String _relativeTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std';
    return 'vor ${diff.inDays} T';
  }

  String _reasonLabel(String reason) {
    return switch (reason) {
      'manual' => 'Buchung',
      'redemption' => 'Einlösung',
      'bonus' => 'Bonus',
      'penalty' => 'Strafe',
      'correction' => 'Korrektur',
      _ => reason,
    };
  }
}

class _ChildData {
  final Participant participant;
  final int earned;
  final int spent;
  final int redeemed;
  final int rank;
  final int totalParticipants;
  final PointTransaction? lastTransaction;
  final int transactionCount;

  const _ChildData({
    required this.participant,
    required this.earned,
    required this.spent,
    required this.redeemed,
    required this.rank,
    required this.totalParticipants,
    this.lastTransaction,
    required this.transactionCount,
  });
}
