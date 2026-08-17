import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../models/participant.dart';
import '../../models/point_transaction.dart';
import '../../models/reward.dart';
import '../../services/demo_service.dart';

class TnDashboardScreen extends StatelessWidget {
  final Participant participant;

  const TnDashboardScreen({super.key, required this.participant});

  @override
  Widget build(BuildContext context) {
    final p = DemoService().getParticipant(participant.id) ?? participant;
    final transactions = DemoService().getTransactions(p.id);
    final leaderboard = DemoService().getLeaderboard(p.eventId);
    final rewards = DemoService().getRewards(p.eventId);
    final rank = leaderboard.indexWhere((x) => x.id == p.id) + 1;
    final totalParticipants = leaderboard.length;

    final earned =
        transactions.where((t) => t.amount > 0).fold<int>(0, (s, t) => s + t.amount);
    final spent = transactions
        .where((t) => t.amount < 0)
        .fold<int>(0, (s, t) => s + t.amount.abs());
    final redemptions = transactions.where((t) => t.reason == 'redemption').length;

    final affordableRewards = rewards
        .where((r) => r.cost > p.balance && r.inStock && r.available)
        .toList()
      ..sort((a, b) => a.cost.compareTo(b.cost));
    final nextReward = affordableRewards.isNotEmpty ? affordableRewards.first : null;

    final recent = transactions.take(10).toList();

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _heroCard(context, p, rank, totalParticipants)
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.15, end: 0, duration: 600.ms,
                  curve: Curves.easeOutCubic),
          const SizedBox(height: 16),
          if (nextReward != null)
            _nextRewardCard(context, nextReward, p.balance)
                .animate()
                .fadeIn(duration: 500.ms, delay: 100.ms)
                .slideX(begin: 0.05, end: 0, duration: 500.ms, delay: 100.ms),
          if (nextReward != null) const SizedBox(height: 16),
          _statsGrid(context, earned, spent, transactions.length, redemptions)
              .animate()
              .fadeIn(duration: 500.ms, delay: 180.ms),
          const SizedBox(height: 20),
          _streakBadges(context, transactions)
              .animate()
              .fadeIn(duration: 500.ms, delay: 250.ms),
          const SizedBox(height: 20),
          _activityFeed(context, recent)
              .animate()
              .fadeIn(duration: 500.ms, delay: 320.ms),
        ],
      ),
    );
  }

  Widget _heroCard(
      BuildContext context, Participant p, int rank, int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.violet, AppTheme.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.violet.withAlpha(50),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.white.withAlpha(40),
                      child: Text(
                        p.displayName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      p.displayName,
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
            'Deine Punkte',
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 13,
              letterSpacing: 1,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: p.balance.toDouble()),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(
              '${v.toInt()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 60,
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
              if (p.group != null)
                _heroBadge(p.group!, Icons.groups),
              if (p.group != null && rank > 0)
                const SizedBox(width: 8),
              if (rank > 0)
                _heroBadge('Platz $rank von $total', Icons.emoji_events),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroBadge(String text, IconData icon) {
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

  Widget _nextRewardCard(BuildContext context, Reward reward, int balance) {
    final needed = reward.cost - balance;
    final progress = balance / reward.cost;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.brand.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.brand.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.brand.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.star, size: 18, color: AppTheme.brand),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nächste Prämie',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      reward.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.brand.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${reward.cost} P',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.brand,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.brand.withAlpha(15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => FractionallySizedBox(
                      widthFactor: v,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.brand, AppTheme.violet],
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Noch $needed Punkte bis zur Einlösung',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.brand.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid(
      BuildContext context, int earned, int spent, int bookings, int redemptions) {
    return Row(
      children: [
        Expanded(
          child: _statCard(context, earned, 'Verdient', Icons.trending_up,
              AppTheme.success, prefix: '+'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(context, spent, 'Ausgegeben', Icons.shopping_bag,
              AppTheme.danger, prefix: '-'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
              context, bookings, 'Buchungen', Icons.receipt_long, AppTheme.violet),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(context, redemptions, 'Prämien',
              Icons.card_giftcard, AppTheme.brand),
        ),
      ],
    );
  }

  Widget _statCard(BuildContext context, int value, String label,
      IconData icon, Color color,
      {String prefix = ''}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
              '$prefix${v.toInt()}',
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _streakBadges(
      BuildContext context, List<PointTransaction> transactions) {
    final earned =
        transactions.where((t) => t.amount > 0).fold<int>(0, (s, t) => s + t.amount);
    final txCount = transactions.length;

    final badges = <_Badge>[];

    if (earned >= 50) {
      badges.add(_Badge('Punkte-Sammler', Icons.local_fire_department,
          const Color(0xFFFF6B35)));
    }
    if (earned >= 100) {
      badges.add(
          _Badge('Punkte-Meister', Icons.whatshot, const Color(0xFFEF4444)));
    }
    if (txCount >= 5) {
      badges.add(
          _Badge('Aktiver Teilnehmer', Icons.bolt, const Color(0xFF7C3AED)));
    }
    if (txCount >= 10) {
      badges.add(
          _Badge('Super-Aktiv', Icons.electric_bolt, const Color(0xFF10B981)));
    }
    final redemptions = transactions.where((t) => t.reason == 'redemption').length;
    if (redemptions >= 1) {
      badges.add(_Badge(
          'Erste Prämie', Icons.card_giftcard, const Color(0xFFF59E0B)));
    }

    if (badges.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withAlpha(60),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 24, color: AppTheme.violet.withAlpha(80)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sammle Abzeichen!',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Text(
                    'Verdiene Punkte und löse Prämien ein',
                    style: TextStyle(
                      fontSize: 12,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.military_tech, size: 20, color: AppTheme.brand),
            const SizedBox(width: 8),
            Text(
              'Deine Abzeichen',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: badges
              .map((b) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: b.color.withAlpha(12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: b.color.withAlpha(40)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(b.icon, size: 16, color: b.color),
                        const SizedBox(width: 6),
                        Text(
                          b.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: b.color,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _activityFeed(BuildContext context, List<PointTransaction> txs) {
    if (txs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.history,
                size: 40, color: AppTheme.violet.withAlpha(60)),
            const SizedBox(height: 12),
            const Text(
              'Noch keine Aktivitäten',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Deine Buchungen erscheinen hier',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, size: 20, color: AppTheme.violet),
            const SizedBox(width: 8),
            Text(
              'Letzte Aktivitäten',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.violet.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${txs.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.violet,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...txs.map((tx) {
          final pos = tx.amount >= 0;
          final color = pos ? AppTheme.success : AppTheme.danger;
          final dt = DateTime.tryParse(tx.createdAt);
          final timeStr = dt != null ? _relativeTime(dt) : '';

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withAlpha(40),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    pos ? Icons.add_circle_outline : Icons.remove_circle_outline,
                    size: 20,
                    color: color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.note ?? _reasonLabel(tx.reason),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${pos ? "+" : ""}${tx.amount}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std';
    return 'vor ${diff.inDays} Tagen';
  }

  String _reasonLabel(String reason) {
    return switch (reason) {
      'manual' => 'Punkte-Buchung',
      'redemption' => 'Prämie eingelöst',
      'bonus' => 'Bonus erhalten',
      'penalty' => 'Strafe',
      'correction' => 'Korrektur',
      _ => reason,
    };
  }
}

class _Badge {
  final String label;
  final IconData icon;
  final Color color;

  const _Badge(this.label, this.icon, this.color);
}
