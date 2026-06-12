/// Progression stats derived from the `users/{uid}` document. All
/// fields are plain ints already stored (or defaulted) on that doc —
/// no extra Firestore collection or index is involved.
class PlayerStats {
  final int wins;
  final int competitionsPlayed;
  final int currentStreak;
  final int bestStreak;
  final int level;
  final int coins;
  final int itemsOwned;

  const PlayerStats({
    required this.wins,
    required this.competitionsPlayed,
    required this.currentStreak,
    required this.bestStreak,
    required this.level,
    required this.coins,
    required this.itemsOwned,
  });

  factory PlayerStats.fromUserData(Map<String, dynamic> data) {
    final bought = (data['boughtItems'] as List?)?.length ?? 0;
    return PlayerStats(
      wins: (data['wins'] as int?) ?? 0,
      competitionsPlayed: (data['competitionsPlayed'] as int?) ?? 0,
      currentStreak: (data['currentStreak'] as int?) ?? 0,
      bestStreak: (data['bestStreak'] as int?) ?? 0,
      level: (data['level'] as int?) ?? 1,
      coins: (data['coins'] as int?) ?? 0,
      itemsOwned: bought,
    );
  }
}

/// A single unlockable achievement. [unlocked] is a pure predicate
/// over [PlayerStats] so the same catalog drives both the "did I just
/// earn it" check after a contest and the menu badge wall.
class Achievement {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final bool Function(PlayerStats) unlocked;

  const Achievement({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.unlocked,
  });
}

class Achievements {
  Achievements._();

  static const List<Achievement> all = [
    Achievement(
      id: 'first_steps',
      emoji: '👠',
      title: 'On The Runway',
      description: 'Enter your first fashion contest.',
      unlocked: _firstSteps,
    ),
    Achievement(
      id: 'first_win',
      emoji: '👑',
      title: 'First Crown',
      description: 'Win a fashion contest.',
      unlocked: _firstWin,
    ),
    Achievement(
      id: 'hat_trick',
      emoji: '🔥',
      title: 'Hat Trick',
      description: 'Win 3 contests in a row.',
      unlocked: _hatTrick,
    ),
    Achievement(
      id: 'unstoppable',
      emoji: '💎',
      title: 'Unstoppable',
      description: 'Reach a 5-win streak.',
      unlocked: _unstoppable,
    ),
    Achievement(
      id: 'veteran',
      emoji: '🎀',
      title: 'Catwalk Veteran',
      description: 'Play 10 contests.',
      unlocked: _veteran,
    ),
    Achievement(
      id: 'trendsetter',
      emoji: '🛍️',
      title: 'Trendsetter',
      description: 'Own 10 fashion items.',
      unlocked: _trendsetter,
    ),
    Achievement(
      id: 'high_roller',
      emoji: '🪙',
      title: 'High Roller',
      description: 'Save up 1,000 coins.',
      unlocked: _highRoller,
    ),
    Achievement(
      id: 'rising_star',
      emoji: '🌟',
      title: 'Rising Star',
      description: 'Reach level 5.',
      unlocked: _risingStar,
    ),
    Achievement(
      id: 'fashion_icon',
      emoji: '✨',
      title: 'Fashion Icon',
      description: 'Reach the max level, 10.',
      unlocked: _fashionIcon,
    ),
  ];

  /// IDs that [stats] currently satisfy.
  static Set<String> earnedIds(PlayerStats stats) =>
      all.where((a) => a.unlocked(stats)).map((a) => a.id).toSet();

  static Achievement? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }

  // Predicates kept top-level so they can be `const`-referenced above.
  static bool _firstSteps(PlayerStats s) => s.competitionsPlayed >= 1;
  static bool _firstWin(PlayerStats s) => s.wins >= 1;
  static bool _hatTrick(PlayerStats s) => s.bestStreak >= 3;
  static bool _unstoppable(PlayerStats s) => s.bestStreak >= 5;
  static bool _veteran(PlayerStats s) => s.competitionsPlayed >= 10;
  static bool _trendsetter(PlayerStats s) => s.itemsOwned >= 10;
  static bool _highRoller(PlayerStats s) => s.coins >= 1000;
  static bool _risingStar(PlayerStats s) => s.level >= 5;
  static bool _fashionIcon(PlayerStats s) => s.level >= 10;
}
