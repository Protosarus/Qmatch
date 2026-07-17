import 'package:flutter/foundation.dart';

import 'assessment_language.dart';

/// Localized user-facing display for assessment results / archetypes.
///
/// Internal IDs and codes (e.g. `slow_bond`, `ML`) may be stored and scored,
/// but must not be shown as primary UI text — resolve through this layer.
class AssessmentResultDisplay {
  const AssessmentResultDisplay({
    required this.id,
    required this.title,
    required this.description,
    this.tags = const [],
    this.emoji,
  });

  /// Internal id/code (not for primary UI display).
  final String id;
  final String title;
  final String description;
  final List<String> tags;
  final String? emoji;
}

/// Resolves internal result IDs/codes to localized titles, descriptions, tags.
class AssessmentResultDisplayResolver {
  AssessmentResultDisplayResolver._();

  static const _fallbackEn = AssessmentResultDisplay(
    id: 'unknown',
    title: 'Connection Profile',
    description:
        'A connection-oriented profile shaped by how you think, feel, and bond.',
    tags: [],
  );

  static const _fallbackTr = AssessmentResultDisplay(
    id: 'unknown',
    title: 'Bağ Profili',
    description:
        'Düşünme, hissetme ve bağ kurma biçiminle şekillenen bir bağlantı profilisin.',
    tags: [],
  );

  // ---------------------------------------------------------------------------
  // Frequency type (stored English type string from FrequencyService)
  // ---------------------------------------------------------------------------

  static const Map<String, _LocalizedEntry> _frequencyTypes = {
    'Deep Connector': _LocalizedEntry(
      titleEn: 'Deep Connector',
      titleTr: 'Derin Bağ Kurucu',
      descEn:
          'You build connection through meaning, trust, and emotional depth.',
      descTr:
          'Anlam, güven ve duygusal derinlik üzerinden bağ kurarsın. Yüzeysel sohbetten çok gerçek yakınlığı tercih edersin.',
      tagsEn: ['Depth', 'Trust', 'Meaning'],
      tagsTr: ['Derinlik', 'Güven', 'Anlam'],
    ),
    'Social Spark': _LocalizedEntry(
      titleEn: 'Social Spark',
      titleTr: 'Sosyal Kıvılcım',
      descEn:
          'You connect through energy, playfulness, and shared momentum.',
      descTr:
          'Enerji, oyun ve ortak ritimle bağ kurarsın. Birlikte hareket etmek seni canlandırır.',
      tagsEn: ['Energy', 'Play', 'Momentum'],
      tagsTr: ['Enerji', 'Oyun', 'Ritim'],
    ),
    'Slow Burner': _LocalizedEntry(
      titleEn: 'Slow Burner',
      titleTr: 'Yavaş Yanan Bağ',
      descEn: 'You prefer trust to grow gradually and intentionally.',
      descTr:
          'Güvenin acele etmeden, bilinçli ve yavaş büyumesini tercih edersin. Bağ kurarken tempo senin için önemlidir.',
      tagsEn: ['Patience', 'Trust', 'Pace'],
      tagsTr: ['Sabır', 'Güven', 'Tempo'],
    ),
    'Emotional Explorer': _LocalizedEntry(
      titleEn: 'Emotional Explorer',
      titleTr: 'Duygusal Kaşif',
      descEn:
          'You connect through honesty, emotional openness, and reflection.',
      descTr:
          'Dürüstlük, duygusal açıklık ve içgörüyle bağ kurarsın. Hislerin konuşulabilir olmasını önemsesin.',
      tagsEn: ['Honesty', 'Openness', 'Reflection'],
      tagsTr: ['Dürüstlük', 'Açıklık', 'İçgörü'],
    ),
    'Open Current': _LocalizedEntry(
      titleEn: 'Open Current',
      titleTr: 'Açık Akış',
      descEn:
          'You connect through flow, spontaneity, and emotional availability.',
      descTr:
          'Akış, spontanlık ve duygusal erişilebilirlikle bağ kurarsın. Anın içinde kalmak sana iyi gelir.',
      tagsEn: ['Flow', 'Spontaneity', 'Availability'],
      tagsTr: ['Akış', 'Spontanlık', 'Erişilebilirlik'],
    ),
    'Balanced Frequency': _LocalizedEntry(
      titleEn: 'Balanced Frequency',
      titleTr: 'Dengeli Frekans',
      descEn:
          'You adapt your connection style depending on the person and context.',
      descTr:
          'Bağ kurma stilini kişiye ve ortama göre esnekçe ayarlarsın. Dengeli ve uyumlu bir ritmin var.',
      tagsEn: ['Balance', 'Adaptability', 'Harmony'],
      tagsTr: ['Denge', 'Uyum', 'Esneklik'],
    ),
  };

  // ---------------------------------------------------------------------------
  // Frequency tag IDs (internal snake_case)
  // ---------------------------------------------------------------------------

  static const Map<String, _LocalizedEntry> _frequencyTags = {
    'deep_talker': _LocalizedEntry(
      titleEn: 'Deep Talker',
      titleTr: 'Derin Konuşmacı',
      descEn: 'You lean into meaningful, layered conversation.',
      descTr: 'Anlamlı ve katmanlı konuşmalara yönelirsin.',
      tagsEn: ['Deep talk'],
      tagsTr: ['Derin sohbet'],
    ),
    'social_energy': _LocalizedEntry(
      titleEn: 'Social Energy',
      titleTr: 'Sosyal Enerji',
      descEn: 'Shared social energy fuels your connections.',
      descTr: 'Ortak sosyal enerji bağlarını besler.',
      tagsEn: ['Social energy'],
      tagsTr: ['Sosyal enerji'],
    ),
    'spontaneous': _LocalizedEntry(
      titleEn: 'Spontaneous',
      titleTr: 'Spontan',
      descEn: 'You like room for impulse and surprise.',
      descTr: 'Ani kararlara ve sürprizlere alan bırakırsın.',
      tagsEn: ['Spontaneous'],
      tagsTr: ['Spontan'],
    ),
    'stability_first': _LocalizedEntry(
      titleEn: 'Stability First',
      titleTr: 'Önce İstikrar',
      descEn: 'Consistency and stability come first for you.',
      descTr: 'Senin için önce tutarlılık ve istikrar gelir.',
      tagsEn: ['Stability'],
      tagsTr: ['İstikrar'],
    ),
    'emotionally_open': _LocalizedEntry(
      titleEn: 'Emotionally Open',
      titleTr: 'Duygusal Açıklık',
      descEn: 'You value emotional honesty and openness.',
      descTr: 'Duygusal dürüstlüğü ve açıklığı önemsesin.',
      tagsEn: ['Emotional openness'],
      tagsTr: ['Duygusal açıklık'],
    ),
    'slow_bond': _LocalizedEntry(
      titleEn: 'Steady Connection',
      titleTr: 'Yavaş ve Güvenli Bağ',
      descEn:
          'You build trust over time, without rushing closeness.',
      descTr:
          'Güveni zamanla kuran, acele etmeyen ve bağ kurarken duygusal güvenliği önemseyen bir profilsin.',
      tagsEn: ['Slow burn', 'Trust-first'],
      tagsTr: ['Yavaş bağ', 'Güven odaklı'],
    ),
    'fast_connection': _LocalizedEntry(
      titleEn: 'Fast Connection',
      titleTr: 'Hızlı Bağlantı',
      descEn: 'You form chemistry quickly when the vibe is right.',
      descTr: 'Ruh hali tuttuğunda kimyayı hızlı kurarsın.',
      tagsEn: ['Fast chemistry'],
      tagsTr: ['Hızlı kimya'],
    ),
  };

  // ---------------------------------------------------------------------------
  // IQ/EQ archetype codes (HH…LL) — meanings match ArchetypeCalculator bands
  // IQ/EQ: H >66, M 34–66, L <34
  // ---------------------------------------------------------------------------

  static const Map<String, _LocalizedEntry> _iqEqLevels = {
    'HH': _LocalizedEntry(
      titleEn: 'The Mastermind',
      titleTr: 'Usta Zihin',
      descEn:
          'Strategic mind with high emotional intelligence. Natural leadership and vision.',
      descTr:
          'Yüksek duygusal zekâyla birleşen stratejik bir zihin. Doğal liderlik ve vizyon senin alanın.',
      tagsEn: ['Strategic', 'Emotionally sharp'],
      tagsTr: ['Stratejik', 'Duygusal keskinlik'],
      emoji: '🧠',
    ),
    'HM': _LocalizedEntry(
      titleEn: 'The Strategist',
      titleTr: 'Stratejist',
      descEn:
          'High analytical ability with balanced social skills. You think several moves ahead.',
      descTr:
          'Yüksek analitik güç ve dengeli sosyal beceri. Birkaç hamle ötesini düşünürsün.',
      tagsEn: ['Analytical', 'Balanced social'],
      tagsTr: ['Analitik', 'Dengeli sosyal'],
      emoji: '♟️',
    ),
    'HL': _LocalizedEntry(
      titleEn: 'The Architect',
      titleTr: 'Mimar',
      descEn:
          'Strong rational focus with lower social preference. Precision matters to you.',
      descTr:
          'Güçlü rasyonel odak, daha seçici sosyal mesafe. Senin için netlik ve kesinlik önemli.',
      tagsEn: ['Rational', 'Precise'],
      tagsTr: ['Rasyonel', 'Netlik'],
      emoji: '🏗️',
    ),
    'MH': _LocalizedEntry(
      titleEn: 'The Diplomat',
      titleTr: 'Diplomat',
      descEn:
          'Solid intellect with high emotional depth. You read people and shape conversation.',
      descTr:
          'Sağlam zihin ve yüksek duygusal derinlik. İnsanları okur, konuşmayı yönlendirirsin.',
      tagsEn: ['Persuasive', 'Emotionally deep'],
      tagsTr: ['İkna gücü', 'Duygusal derinlik'],
      emoji: '🤝',
    ),
    'MM': _LocalizedEntry(
      titleEn: 'The Realist',
      titleTr: 'Gerçekçi',
      descEn:
          'Balanced IQ and EQ. Practical, adaptable, and steady in everyday connection.',
      descTr:
          'Dengeli IQ ve EQ. Pratik, uyumlu ve gündelik bağlarda istikrarlısın.',
      tagsEn: ['Balanced', 'Practical'],
      tagsTr: ['Dengeli', 'Pratik'],
      emoji: '⚖️',
    ),
    'ML': _LocalizedEntry(
      titleEn: 'The Technician',
      titleTr: 'Teknik Odaklı Profil',
      descEn:
          'Practical and detail-oriented. You focus on clear execution over social complexity.',
      descTr:
          'Pratik ve detay odaklısın. Sosyal karmaşadan çok net uygulamaya odaklanırsın.',
      tagsEn: ['Practical', 'Detail-focused'],
      tagsTr: ['Pratik', 'Detay odaklı'],
      emoji: '🔧',
    ),
    'LH': _LocalizedEntry(
      titleEn: 'The Healer',
      titleTr: 'Şifacı',
      descEn:
          'High emotional depth with softer analytical drive. Empathy leads your presence.',
      descTr:
          'Yüksek duygusal derinlik, daha yumuşak analitik tempo. Empati senin varoluşunu yönetir.',
      tagsEn: ['Empathic', 'Caring'],
      tagsTr: ['Empatik', 'Şefkatli'],
      emoji: '💚',
    ),
    'LM': _LocalizedEntry(
      titleEn: 'The Observer',
      titleTr: 'Gözlemci',
      descEn:
          'Perceptive and emotionally aware without chasing high analytical intensity.',
      descTr:
          'Algın açık ve duygusal olarak farkındasın; yüksek analitik yoğunluk peşinde koşmazsın.',
      tagsEn: ['Perceptive', 'Aware'],
      tagsTr: ['Algılı', 'Farkındalık'],
      emoji: '👁️',
    ),
    'LL': _LocalizedEntry(
      titleEn: 'The Executor',
      titleTr: 'Uygulayıcı',
      descEn:
          'Practical implementer. You get things done through persistence and presence.',
      descTr:
          'Pratik bir uygulayıcısın. Direnç ve varlıkla işleri ileri taşırsın.',
      tagsEn: ['Persistent', 'Hands-on'],
      tagsTr: ['Dirençli', 'Pratik'],
      emoji: '⚙️',
    ),
  };

  /// Name → category key for stored English archetype names.
  static final Map<String, String> _nameToCode = {
    for (final e in _iqEqLevels.entries) e.value.titleEn: e.key,
    // Legacy TR names used by older profile emoji maps
    'Usta Zihin': 'HH',
    'Stratejist': 'HM',
    'Mimar': 'HL',
    'Diplomat': 'MH',
    'Gerçekçi': 'MM',
    'Teknik Odaklı Profil': 'ML',
    'The Technician': 'ML',
    'Şifacı': 'LH',
    'Gözlemci': 'LM',
    'Uygulayıcı': 'LL',
  };

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  static String _lang({String? languageCode}) =>
      AssessmentLanguage.languageUsed(languageCode: languageCode);

  static AssessmentResultDisplay resolveFrequencyArchetype(
    String id, {
    String? languageCode,
  }) =>
      resolveFrequencyType(id, languageCode: languageCode);

  static AssessmentResultDisplay resolveFrequencyType(
    String type, {
    String? languageCode,
  }) {
    final key = type.trim();
    final entry = _frequencyTypes[key];
    if (entry == null) {
      return _unknown(key, languageCode: languageCode, kind: 'frequency_type');
    }
    return entry.toDisplay(key, _lang(languageCode: languageCode));
  }

  static AssessmentResultDisplay resolveFrequencyTag(
    String tagId, {
    String? languageCode,
  }) {
    final key = tagId.trim();
    final entry = _frequencyTags[key];
    if (entry == null) {
      return _unknown(key, languageCode: languageCode, kind: 'frequency_tag');
    }
    return entry.toDisplay(key, _lang(languageCode: languageCode));
  }

  /// IQ/EQ 2-letter category code (HH…LL).
  static AssessmentResultDisplay resolveIqEqLevel(
    String code, {
    String? languageCode,
  }) {
    final key = code.trim().toUpperCase();
    final entry = _iqEqLevels[key];
    if (entry == null) {
      return _unknown(key, languageCode: languageCode, kind: 'iq_eq_level');
    }
    return entry.toDisplay(key, _lang(languageCode: languageCode));
  }

  /// Alias used by architecture docs / callers.
  static AssessmentResultDisplay resolveIqLevel(
    String code, {
    String? languageCode,
  }) =>
      resolveIqEqLevel(code, languageCode: languageCode);

  static AssessmentResultDisplay resolveEqLevel(
    String code, {
    String? languageCode,
  }) =>
      resolveIqEqLevel(code, languageCode: languageCode);

  /// Resolve stored profile archetype name or category code.
  static AssessmentResultDisplay resolveArchetypeLabel(
    String? nameOrCode, {
    String? languageCode,
  }) {
    final raw = (nameOrCode ?? '').trim();
    if (raw.isEmpty) {
      return _unknown('unknown', languageCode: languageCode, kind: 'archetype');
    }
    if (_iqEqLevels.containsKey(raw.toUpperCase())) {
      return resolveIqEqLevel(raw, languageCode: languageCode);
    }
    final code = _nameToCode[raw];
    if (code != null) {
      return resolveIqEqLevel(code, languageCode: languageCode);
    }
    return _unknown(raw, languageCode: languageCode, kind: 'archetype');
  }

  static List<String> localizeFrequencyTags(
    Iterable<String> tagIds, {
    String? languageCode,
  }) {
    return tagIds
        .map(
          (id) => resolveFrequencyTag(id, languageCode: languageCode).title,
        )
        .toList(growable: false);
  }

  static AssessmentResultDisplay _unknown(
    String id, {
    required String? languageCode,
    required String kind,
  }) {
    if (kDebugMode) {
      debugPrint(
        'AssessmentResultDisplayResolver: unknown $kind id="$id" '
        '(showing safe fallback; never raw id in UI)',
      );
    }
    final lang = _lang(languageCode: languageCode);
    final base = lang == 'tr' ? _fallbackTr : _fallbackEn;
    // Do not echo snake_case / raw codes as the title.
    return AssessmentResultDisplay(
      id: id,
      title: base.title,
      description: base.description,
      tags: [],
    );
  }
}

class _LocalizedEntry {
  const _LocalizedEntry({
    required this.titleEn,
    required this.titleTr,
    required this.descEn,
    required this.descTr,
    this.tagsEn = const [],
    this.tagsTr = const [],
    this.emoji,
  });

  final String titleEn;
  final String titleTr;
  final String descEn;
  final String descTr;
  final List<String> tagsEn;
  final List<String> tagsTr;
  final String? emoji;

  AssessmentResultDisplay toDisplay(String id, String lang) {
    final tr = lang == 'tr';
    return AssessmentResultDisplay(
      id: id,
      title: tr ? titleTr : titleEn,
      description: tr ? descTr : descEn,
      tags: tr ? tagsTr : tagsEn,
      emoji: emoji,
    );
  }
}
