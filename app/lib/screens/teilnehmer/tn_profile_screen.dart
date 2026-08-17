import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../models/participant.dart';
import '../../models/point_transaction.dart';
import '../../services/demo_service.dart';

class TnProfileScreen extends StatelessWidget {
  final Participant participant;

  const TnProfileScreen({super.key, required this.participant});

  @override
  Widget build(BuildContext context) {
    final p = DemoService().getParticipant(participant.id) ?? participant;
    final txs = DemoService().getTransactions(p.id);
    final leaderboard = DemoService().getLeaderboard(p.eventId);
    final rank = leaderboard.indexWhere((x) => x.id == p.id) + 1;

    final earned =
        txs.where((t) => t.amount > 0).fold<int>(0, (s, t) => s + t.amount);
    final spent =
        txs.where((t) => t.amount < 0).fold<int>(0, (s, t) => s + t.amount.abs());
    final redeemed = txs.where((t) => t.reason == 'redemption').toList();

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _profileHeader(context, p)
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.12, end: 0, duration: 600.ms,
                  curve: Curves.easeOutCubic),
          const SizedBox(height: 20),
          _statsGrid(context, p.balance, earned, spent, txs.length, rank)
              .animate()
              .fadeIn(duration: 500.ms, delay: 100.ms),
          const SizedBox(height: 20),
          _pointsBreakdown(context, earned, spent)
              .animate()
              .fadeIn(duration: 500.ms, delay: 180.ms)
              .slideX(begin: -0.04, end: 0, duration: 500.ms, delay: 180.ms),
          const SizedBox(height: 20),
          _nfcStatus(context, p)
              .animate()
              .fadeIn(duration: 500.ms, delay: 240.ms),
          if (redeemed.isNotEmpty) ...[
            const SizedBox(height: 20),
            _redeemedRewards(context, redeemed)
                .animate()
                .fadeIn(duration: 500.ms, delay: 300.ms),
          ],
          const SizedBox(height: 20),
          _personalInfo(context, p)
              .animate()
              .fadeIn(duration: 500.ms, delay: 360.ms),
        ],
      ),
    );
  }

  Widget _profileHeader(BuildContext context, Participant p) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppTheme.violet, AppTheme.brand],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.violet.withAlpha(40),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Center(
                child: Text(
                  p.displayName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.violet,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          p.displayName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (p.group != null)
              _infoBadge(p.group!, Icons.groups, AppTheme.violet),
            if (p.group != null && p.age != null) const SizedBox(width: 8),
            if (p.age != null)
              _infoBadge('${p.age} Jahre', Icons.cake_outlined, AppTheme.brand),
          ],
        ),
      ],
    );
  }

  Widget _infoBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid(BuildContext context, int balance, int earned, int spent,
      int bookings, int rank) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(context, balance, 'Guthaben',
                  Icons.account_balance_wallet, AppTheme.violet),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(context, rank, 'Rang', Icons.emoji_events,
                  const Color(0xFFFFD700)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _statCard(context, earned, 'Verdient',
                  Icons.trending_up, AppTheme.success,
                  prefix: '+'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(context, spent, 'Ausgegeben',
                  Icons.shopping_bag, AppTheme.danger,
                  prefix: '-'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(BuildContext context, int value, String label,
      IconData icon, Color color,
      {String prefix = ''}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: value.toDouble()),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Text(
                    '$prefix${v.toInt()}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color.withAlpha(180),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pointsBreakdown(BuildContext context, int earned, int spent) {
    final total = earned > 0 ? earned : 1;
    final spentFrac = spent / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(60),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_outline,
                  size: 18, color: AppTheme.violet),
              const SizedBox(width: 8),
              const Text(
                'Punkte-Verteilung',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _breakdownBar(context, 'Verdient', earned, 1.0, AppTheme.success),
          const SizedBox(height: 10),
          _breakdownBar(
              context, 'Ausgegeben', spent, spentFrac, AppTheme.danger),
        ],
      ),
    );
  }

  Widget _breakdownBar(BuildContext context, String label, int value,
      double fraction, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              '$value P',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                Container(color: color.withAlpha(15)),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withAlpha(160)],
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
      ],
    );
  }

  Widget _nfcStatus(BuildContext context, Participant p) {
    final connected = p.nfcTagUid != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: connected
            ? AppTheme.success.withAlpha(8)
            : Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: connected
              ? AppTheme.success.withAlpha(30)
              : Theme.of(context).colorScheme.outlineVariant.withAlpha(60),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: connected
                  ? AppTheme.success.withAlpha(20)
                  : AppTheme.violet.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              connected ? Icons.nfc : Icons.nfc_outlined,
              size: 22,
              color: connected ? AppTheme.success : AppTheme.violet,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NFC-Armband',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  connected ? 'Verbunden und aktiv' : 'Noch nicht zugewiesen',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: connected
                  ? AppTheme.success.withAlpha(15)
                  : AppTheme.warning.withAlpha(15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: connected ? AppTheme.success : AppTheme.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  connected ? 'Aktiv' : 'Offen',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: connected ? AppTheme.success : AppTheme.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _redeemedRewards(
      BuildContext context, List<PointTransaction> redeemed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.card_giftcard, size: 20, color: AppTheme.brand),
            const SizedBox(width: 8),
            Text(
              'Eingelöste Prämien',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.brand.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${redeemed.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.brand,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...redeemed.map((tx) {
          final dt = DateTime.tryParse(tx.createdAt);
          final timeStr = dt != null ? _relativeTime(dt) : '';

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.success.withAlpha(6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.success.withAlpha(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check_circle_outline,
                      size: 18, color: AppTheme.success),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.note ?? 'Prämie',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
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
                  '${tx.amount} P',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.danger,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _personalInfo(BuildContext context, Participant p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(60),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 18, color: AppTheme.violet),
              const SizedBox(width: 8),
              const Text(
                'Persönliche Daten',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(context, 'Name', p.displayName),
          if (p.group != null) _infoRow(context, 'Gruppe', p.group!),
          if (p.age != null) _infoRow(context, 'Alter', '${p.age} Jahre'),
          _infoRow(context, 'Status', p.active ? 'Aktiv' : 'Inaktiv'),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std';
    return 'vor ${diff.inDays} Tagen';
  }
}
