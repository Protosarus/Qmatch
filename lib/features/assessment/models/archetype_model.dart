class ArchetypeModel {
  final String name;
  final String emoji;
  final String description;
  final String category; // H (High), M (Mid), L (Low)
  final int iqNormalized; // 0-100
  final int eqNormalized; // 0-100

  const ArchetypeModel({
    required this.name,
    required this.emoji,
    required this.description,
    required this.category,
    required this.iqNormalized,
    required this.eqNormalized,
  });
}

class ArchetypeCalculator {
  // 9 Arketip tanımları (legacy HH…LL — not canonical 18 personas)
  static const Map<String, Map<String, String>> archetypes = {
    'HH': {
      'name': 'The Mastermind',
      'emoji': '🧠',
      'description':
          'Strategic genius with high emotional intelligence. Natural leader and visionary.',
    },
    'HM': {
      'name': 'The Strategist',
      'emoji': '♟️',
      'description':
          'High analytical ability with balanced social skills. Strategic thinker.',
    },
    'HL': {
      'name': 'The Architect',
      'emoji': '🏗️',
      'description':
          'Pure rationalism with low social tolerance. Analytical perfectionist.',
    },
    'MH': {
      'name': 'The Diplomat',
      'emoji': '🤝',
      'description':
          'Above-average intelligence with high emotional depth. Social manipulator and persuader.',
    },
    'MM': {
      'name': 'The Realist',
      'emoji': '⚖️',
      'description':
          'Society\'s backbone. Pragmatic and adaptable with balanced abilities.',
    },
    'ML': {
      'name': 'The Technician',
      'emoji': '🔧',
      'description':
          'Practical and detail-oriented. Focused on technical execution.',
    },
    'LH': {
      'name': 'The Healer',
      'emoji': '💚',
      'description':
          'High emotional depth with lower analytical focus. Empathetic caregiver.',
    },
    'LM': {
      'name': 'The Observer',
      'emoji': '👁️',
      'description':
          'Perceptive and aware. Understands emotions without high analytical drive.',
    },
    'LL': {
      'name': 'The Executor',
      'emoji': '⚙️',
      'description':
          'Practical implementer. Gets things done through persistence.',
    },
  };

  /// Normalize a module score with that module's own denominator.
  static int normalizeScore(int rawScore, int maxScore) {
    if (maxScore <= 0) return 0;
    return ((rawScore / maxScore) * 100).round().clamp(0, 100);
  }

  // Kategori belirle: H (>66), M (34-66), L (<34)
  static String getCategory(int normalizedScore) {
    if (normalizedScore > 66) return 'H';
    if (normalizedScore >= 34) return 'M';
    return 'L';
  }

  /// Legacy HH…LL resolver with **module-specific** denominators.
  ///
  /// P1B-1: IQ must not use EQ question count (and vice versa).
  static ArchetypeModel calculateArchetype({
    required int iqCorrect,
    required int iqQuestionCount,
    required int eqCorrect,
    required int eqQuestionCount,
  }) {
    final iqNormalized = normalizeScore(iqCorrect, iqQuestionCount);
    final eqNormalized = normalizeScore(eqCorrect, eqQuestionCount);

    final iqCategory = getCategory(iqNormalized);
    final eqCategory = getCategory(eqNormalized);
    final categoryKey = '$iqCategory$eqCategory';

    final archetypeData = archetypes[categoryKey]!;

    return ArchetypeModel(
      name: archetypeData['name']!,
      emoji: archetypeData['emoji']!,
      description: archetypeData['description']!,
      category: categoryKey,
      iqNormalized: iqNormalized,
      eqNormalized: eqNormalized,
    );
  }
}
