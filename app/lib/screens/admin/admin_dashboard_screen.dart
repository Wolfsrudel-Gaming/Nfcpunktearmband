import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../models/participant.dart';
import '../../models/point_transaction.dart';
import '../../models/reward.dart';
import '../../services/demo_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  final String eventId;

  const AdminDashboardScreen({super.key, required this.eventId});

  static const _groupColors = [
    AppTheme.brand,
    AppTheme.violet,
    AppTheme.success,
    AppTheme.warning,
    AppTheme.danger,
  ];

  @override
  Widget build(BuildContext context) {
    final demo = DemoService();
    final event = demo.getEvent(eventId);
    final participants = demo.getParticipants(eventId);
    final txs = demo.getEventTransactions(eventId);
    final rewards = demo.getRewards(eventId);
    final leaderboard = demo.getLeaderboard(eventId);

    final totalBalance =
        participants.fold<int>(0, (s, p) => s + p.balance);
    final totalEarned =
        txs.where((t) => t.amount > 0).fold<int>(0, (s, t) => s + t.amount);
    final totalSpent = txs
        .where((t) => t.amount < 0)
        .fold<int>(0, (s, t) => s + t.amount.abs());
    final redemptions = txs.where((t) => t.reason == 'redemption').length;
    final withNfc = participants.where((p) => p.nfcTagUid != null).length;

    final groupMap = <String, _GroupStats>{};
    for (final p in participants) {
      final g = p.group ?? 'Ohne Gruppe';
      final pTxs = txs.where((t) => t.participantId == p.id);
      final pEarned =
          pTxs.where((t) => t.amount > 0).fold<int>(0, (s, t) => s + t.amount);
      final existing = groupMap[g];
      groupMap[g] = _GroupStats(
        count: (existing?.count ?? 0) + 1,
        totalPoints: (existing?.totalPoints ?? 0) + p.balance,
        totalEarned: (existing?.totalEarned ?? 0) + pEarned,
      );
    }
    final maxGroupPts =
        groupMap.values.fold<int>(0, (m, g) => max(m, g.totalPoints));

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (event != null)
            _eventHeader(context, event.name, event.location, event.startDate,
                event.endDate, participants.length, withNfc)
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.15, end: 0, duration: 600.ms,
                    curve: Curves.easeOutCubic),
          const SizedBox(height: 20),
          _kpiGrid(context, participants.length, totalBalance, totalEarned,
              totalSpent, txs.length, redemptions)
              .animate()
              .fadeIn(duration: 500.ms, delay: 100.ms),
          const SizedBox(height: 20),
          _pointsFlow(context, totalEarned, totalSpent, totalBalance)
              .animate()
              .fadeIn(duration: 500.ms, delay: 200.ms)
              .slideX(begin: -0.04, end: 0, duration: 500.ms, delay: 200.ms),
          const SizedBox(height: 24),
          _topPerformers(context, leaderboard)
              .animate()
              .fadeIn(duration: 500.ms, delay: 280.ms),
          const SizedBox(height: 24),
          _groupComparison(context, groupMap, maxGroupPts)
              .animate()
              .fadeIn(duration: 500.ms, delay: 340.ms),
          const SizedBox(height: 24),
          _rewardsOverview(context, rewards)
              .animate()
              .fadeIn(duration: 500.ms, delay: 400.ms),
          const SizedBox(height: 24),
          _recentActivity(context, txs.take(12).toList(), participants)
              .animate()
              .fadeIn(duration: 500.ms, delay: 460.ms),
        ],
      ),
    );
  }

  Widget _eventHeader(BuildContext context, String name, String? location,
      String? startDate, String? endDate, int count, int nfc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.violet, AppTheme.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.violet.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.event, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (location != null)
                      Text(
                        location,
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.success.withAlpha(50),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.success.withAlpha(100)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Aktiv',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: Colors.white.withAlpha(180)),
                const SizedBox(width: 8),
                Text(
                  '${startDate ?? "?"} – ${endDate ?? "?"}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(Icons.people,
                    size: 14, color: Colors.white.withAlpha(180)),
                const SizedBox(width: 6),
                Text(
                  '$count TN',
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 14),
                Icon(Icons.nfc,
                    size: 14, color: Colors.white.withAlpha(180)),
                const SizedBox(width: 6),
                Text(
                  '$nfc NFC',
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiGrid(BuildContext context, int participants, int balance,
      int earned, int spent, int txCount, int redemptions) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _kpiCard(context, participants, 'Teilnehmer',
                    Icons.people, AppTheme.violet)),
            const SizedBox(width: 10),
            Expanded(
                child: _kpiCard(context, balance, 'Im Umlauf',
                    Icons.account_balance_wallet, AppTheme.brand)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _kpiCard(context, earned, 'Vergeben',
                    Icons.trending_up, AppTheme.success,
                    prefix: '+')),
            const SizedBox(width: 10),
            Expanded(
                child: _kpiCard(context, spent, 'Eingelöst',
                    Icons.redeem, AppTheme.danger,
                    prefix: '-')),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard(BuildContext context, int value, String label,
      IconData icon, Color color,
      {String prefix = ''}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(
              '$prefix${v.toInt()}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title,
      {IconData? icon, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: iconColor ?? AppTheme.violet),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
          ),
        ],
      ),
    );
  }

  Widget _pointsFlow(
      BuildContext context, int earned, int spent, int balance) {
    final total = earned > 0 ? earned : 1;
    final spentFrac = spent / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, 'Punkte-Kreislauf',
            icon: Icons.swap_vert_circle_outlined),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withAlpha(60),
            ),
          ),
          child: Column(
            children: [
              _flowBar(context, 'Vergeben', earned, 1.0, AppTheme.success),
              const SizedBox(height: 12),
              _flowBar(context, 'Eingelöst', spent, spentFrac, AppTheme.danger),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.violet.withAlpha(12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.violet.withAlpha(30)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_balance_wallet,
                        size: 16, color: AppTheme.violet),
                    const SizedBox(width: 8),
                    Text(
                      'Aktuell im Umlauf: ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: balance.toDouble()),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => Text(
                        '${v.toInt()} Punkte',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.violet,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _flowBar(BuildContext context, String label, int value,
      double fraction, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.toDouble()),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Text(
                '${v.toInt()}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 10,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withAlpha(180)],
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

  Widget _topPerformers(BuildContext context, List<Participant> leaderboard) {
    final top = leaderboard.take(5).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    const medalColors = [
      Color(0xFFFFD700),
      Color(0xFFC0C0C0),
      Color(0xFFCD7F32),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, 'Top-Performer',
            icon: Icons.emoji_events, iconColor: const Color(0xFFFFD700)),
        ...top.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          final isMedal = i < 3;
          final medalColor = isMedal ? medalColors[i] : null;

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMedal
                  ? medalColor!.withAlpha(12)
                  : Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: isMedal
                  ? Border.all(color: medalColor!.withAlpha(40))
                  : Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withAlpha(50)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: isMedal
                      ? Icon(Icons.emoji_events, size: 20, color: medalColor)
                      : Text(
                          '${i + 1}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 17,
                  backgroundColor: (isMedal ? medalColor! : AppTheme.violet)
                      .withAlpha(25),
                  child: Text(
                    p.displayName[0].toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isMedal ? medalColor : AppTheme.violet,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (p.group != null)
                        Text(
                          p.group!,
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
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: p.balance.toDouble()),
                  duration: Duration(milliseconds: 1000 + i * 200),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Text(
                    '${v.toInt()} P',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isMedal ? medalColor : AppTheme.violet,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _groupComparison(
      BuildContext context, Map<String, _GroupStats> groups, int maxPts) {
    if (groups.isEmpty) return const SizedBox.shrink();

    final entries = groups.entries.toList()
      ..sort((a, b) => b.value.totalPoints.compareTo(a.value.totalPoints));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, 'Gruppenvergleich',
            icon: Icons.groups, iconColor: AppTheme.violet),
        ...entries.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final color = _groupColors[i % _groupColors.length];
          final fraction = maxPts > 0 ? e.value.totalPoints / maxPts : 0.0;
          final avgPts = e.value.count > 0
              ? (e.value.totalPoints / e.value.count).round()
              : 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withAlpha(8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withAlpha(25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          e.key[0],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      '${e.value.count} TN',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: SizedBox(
                    height: 12,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: color.withAlpha(15),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: fraction),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => FractionallySizedBox(
                            widthFactor: v,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [color, color.withAlpha(160)],
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
                Row(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                          begin: 0,
                          end: e.value.totalPoints.toDouble()),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => Text(
                        '${v.toInt()} Punkte',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: color,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '~ $avgPts P/TN',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _rewardsOverview(BuildContext context, List<Reward> rewards) {
    if (rewards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, 'Prämien-Status',
            icon: Icons.card_giftcard, iconColor: AppTheme.brand),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: rewards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final r = rewards[i];
              final hasStock = r.stock != null;
              final fraction =
                  hasStock && r.stock! > 0 ? r.redeemed / r.stock! : 0.0;

              return Container(
                width: 140,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withAlpha(60),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.brand.withAlpha(15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${r.cost} P',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.brand,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (hasStock)
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: fraction),
                              duration: const Duration(milliseconds: 1000),
                              builder: (_, v, child) => Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: v,
                                    strokeWidth: 3,
                                    backgroundColor:
                                        AppTheme.success.withAlpha(25),
                                    valueColor:
                                        const AlwaysStoppedAnimation(
                                            AppTheme.success),
                                  ),
                                  Text(
                                    '${r.redeemed}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Text(
                            '${r.redeemed}x',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    if (hasStock)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${r.remaining} übrig',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _recentActivity(BuildContext context, List<PointTransaction> txs,
      List<Participant> participants) {
    if (txs.isEmpty) return const SizedBox.shrink();

    final pMap = {for (final p in participants) p.id: p};

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
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
        const SizedBox(height: 12),
        ...txs.asMap().entries.map((entry) {
          final tx = entry.value;
          final p = pMap[tx.participantId];
          final pos = tx.amount >= 0;
          final color = pos ? AppTheme.success : AppTheme.danger;
          final dt = DateTime.tryParse(tx.createdAt);
          final timeStr = dt != null
              ? _relativeTime(dt)
              : '';

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withAlpha(20),
                  child: Icon(
                    pos ? Icons.add : Icons.remove,
                    size: 16,
                    color: color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p?.displayName ?? '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        tx.note ?? _reasonLabel(tx.reason),
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${pos ? "+" : ""}${tx.amount}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: color,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
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
    if (diff.inMinutes < 1) return 'Jetzt';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std';
    return 'vor ${diff.inDays} T';
  }

  String _reasonLabel(String reason) {
    return switch (reason) {
      'manual' => 'Manuelle Buchung',
      'redemption' => 'Prämien-Einlösung',
      'bonus' => 'Bonus',
      'penalty' => 'Strafe',
      'correction' => 'Korrektur',
      _ => reason,
    };
  }
}

class _GroupStats {
  final int count;
  final int totalPoints;
  final int totalEarned;

  const _GroupStats({
    required this.count,
    required this.totalPoints,
    required this.totalEarned,
  });
}
