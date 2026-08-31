import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

class FrequencyBehaviorV2DraftLoader {
  FrequencyBehaviorV2DraftLoader._();

  static String get repoRoot => Directory.current.path;

  static FrequencyBehaviorV2PoolDocument loadPool() {
    final text = File(
      '$repoRoot/${FrequencyBehaviorV2Contract.draftPoolRelativePath}',
    ).readAsStringSync();
    return FrequencyBehaviorV2PoolDocument.fromJson(
      jsonDecode(text) as Map<String, dynamic>,
    );
  }

  static FrequencyBehaviorV2PoolDocument loadEnPool() {
    final text = File(
      '$repoRoot/${FrequencyBehaviorV2Contract.draftPoolEnRelativePath}',
    ).readAsStringSync();
    return FrequencyBehaviorV2PoolDocument.fromJson(
      jsonDecode(text) as Map<String, dynamic>,
    );
  }

  static Map<String, dynamic> loadReviewJson() {
    final text = File(
      '$repoRoot/${FrequencyBehaviorV2Contract.draftReviewRelativePath}',
    ).readAsStringSync();
    return Map<String, dynamic>.from(jsonDecode(text) as Map);
  }

  static Map<String, dynamic> loadEnReviewJson() {
    final text = File(
      '$repoRoot/${FrequencyBehaviorV2Contract.draftReviewEnRelativePath}',
    ).readAsStringSync();
    return Map<String, dynamic>.from(jsonDecode(text) as Map);
  }

  static Map<String, Map<String, dynamic>> reviewByItemId() {
    final doc = loadReviewJson();
    final out = <String, Map<String, dynamic>>{};
    for (final raw in doc['items'] as List) {
      final m = Map<String, dynamic>.from(raw as Map);
      out[m['item_id'] as String] = m;
    }
    return out;
  }

  static Map<String, Map<String, dynamic>> enReviewByItemId() {
    final doc = loadEnReviewJson();
    final out = <String, Map<String, dynamic>>{};
    for (final raw in doc['items'] as List) {
      final m = Map<String, dynamic>.from(raw as Map);
      out[m['item_id'] as String] = m;
    }
    return out;
  }

  static List<List<String>> loadNearDuplicateClusters() {
    final doc = loadReviewJson();
    final raw = doc['semantic_near_duplicate_clusters'] as List? ?? const [];
    return [
      for (final c in raw)
        [
          for (final id
              in Map<String, dynamic>.from(c as Map)['item_ids'] as List)
            id.toString(),
        ],
    ];
  }

  static List<List<String>> loadEnNearDuplicateClusters() {
    final doc = loadEnReviewJson();
    final raw = doc['semantic_near_duplicate_clusters'] as List? ?? const [];
    return [
      for (final c in raw)
        [
          for (final id
              in Map<String, dynamic>.from(c as Map)['item_ids'] as List)
            id.toString(),
        ],
    ];
  }

  static String loadSourceText() => File(
        '$repoRoot/${FrequencyBehaviorV2Contract.sourcePoolRelativePath}',
      ).readAsStringSync();

  /// Phase 1C human-authority exact option weights (76).
  static const Map<String, Map<String, double>> phase1cExpectedWeights = {
    'frequency_v2_q0003_a': {'initiative': 1.0},
    'frequency_v2_q0005_c': {
      'uncertainty_tolerance': -1.0,
      'repair_style': -1.0
    },
    'frequency_v2_q0005_d': {'closeness_pace': 1.0, 'repair_style': 1.0},
    'frequency_v2_q0008_a': {'disclosure_pace': -1.0},
    'frequency_v2_q0015_a': {'reassurance_need': 1.0, 'repair_style': 2.0},
    'frequency_v2_q0015_b': {'boundary_firmness': 1.0, 'repair_style': 1.0},
    'frequency_v2_q0015_d': {'autonomy': 1.0, 'repair_style': -1.0},
    'frequency_v2_q0016_c': {'disclosure_pace': -1.0},
    'frequency_v2_q0026_a': {'initiative': 1.0},
    'frequency_v2_q0027_d': {'autonomy': 1.0, 'disclosure_pace': -1.0},
    'frequency_v2_q0029_a': {
      'uncertainty_tolerance': -1.0,
      'repair_style': 1.0
    },
    'frequency_v2_q0030_c': {'adaptability': 1.0},
    'frequency_v2_q0033_b': {'closeness_pace': -2.0},
    'frequency_v2_q0037_a': {'closeness_pace': 1.0, 'repair_style': 2.0},
    'frequency_v2_q0037_b': {'boundary_firmness': 2.0, 'repair_style': -1.0},
    'frequency_v2_q0038_d': {'uncertainty_tolerance': 1.0, 'adaptability': 1.0},
    'frequency_v2_q0043_a': {'initiative': 1.0, 'structure_preference': 1.0},
    'frequency_v2_q0154_b': {'structure_preference': 2.0},
    'frequency_v2_q0163_b': {'disclosure_pace': 2.0},
    'frequency_v2_q0166_a': {'closeness_pace': 1.0, 'repair_style': 2.0},
    'frequency_v2_q0166_b': {'autonomy': 2.0, 'repair_style': -1.0},
    'frequency_v2_q0166_d': {'boundary_firmness': 2.0, 'repair_style': -1.0},
    'frequency_v2_q0169_a': {'contact_need': 2.0, 'reassurance_need': 2.0},
    'frequency_v2_q0169_b': {'closeness_pace': 1.0, 'initiative': 1.0},
    'frequency_v2_q0169_c': {'autonomy': 2.0, 'boundary_firmness': 2.0},
    'frequency_v2_q0169_d': {'social_energy': 1.0, 'adaptability': 1.0},
    'frequency_v2_q0170_c': {'boundary_firmness': -1.0, 'repair_style': -2.0},
    'frequency_v2_q0170_d': {'repair_style': -1.0, 'structure_preference': 1.0},
    'frequency_v2_q0183_a': {'reassurance_need': 1.0},
    'frequency_v2_q0183_b': {'adaptability': 1.0},
    'frequency_v2_q0185_b': {'uncertainty_tolerance': -1.0},
    'frequency_v2_q0186_b': {'boundary_firmness': -1.0, 'repair_style': 2.0},
    'frequency_v2_q0186_d': {'boundary_firmness': 2.0, 'repair_style': -1.0},
    'frequency_v2_q0191_a': {'reassurance_need': 2.0, 'disclosure_pace': 1.0},
    'frequency_v2_q0191_b': {'closeness_pace': 2.0},
    'frequency_v2_q0191_c': {'autonomy': 2.0, 'boundary_firmness': 1.0},
    'frequency_v2_q0191_d': {
      'uncertainty_tolerance': -2.0,
      'structure_preference': 2.0
    },
    'frequency_v2_q0192_b': {'initiative': 1.0},
    'frequency_v2_q0193_c': {'reassurance_need': 1.0, 'disclosure_pace': -1.0},
    'frequency_v2_q0195_c': {'boundary_firmness': 2.0},
    'frequency_v2_q0195_d': {
      'reassurance_need': 1.0,
      'uncertainty_tolerance': -2.0
    },
    'frequency_v2_q0198_a': {'adaptability': -1.0},
    'frequency_v2_q0252_a': {'disclosure_pace': 1.0, 'repair_style': 1.0},
    'frequency_v2_q0252_c': {'disclosure_pace': -1.0, 'repair_style': -1.0},
    'frequency_v2_q0256_c': {'initiative': 1.0},
    'frequency_v2_q0261_a': {'contact_need': -1.0, 'repair_style': -1.0},
    'frequency_v2_q0264_b': {'autonomy': 2.0, 'disclosure_pace': -1.0},
    'frequency_v2_q0271_d': {'initiative': 1.0, 'autonomy': 1.0},
    'frequency_v2_q0272_b': {'reassurance_need': 2.0, 'disclosure_pace': -1.0},
    'frequency_v2_q0274_a': {'contact_need': 1.0, 'reassurance_need': 2.0},
    'frequency_v2_q0274_b': {'closeness_pace': 2.0},
    'frequency_v2_q0274_c': {'autonomy': 2.0, 'uncertainty_tolerance': 1.0},
    'frequency_v2_q0274_d': {
      'social_energy': 1.0,
      'structure_preference': -1.0
    },
    'frequency_v2_q0278_a': {'adaptability': 1.0},
    'frequency_v2_q0287_b': {'initiative': 1.0},
    'frequency_v2_q0288_d': {'initiative': 1.0, 'boundary_firmness': 1.0},
    'frequency_v2_q0295_a': {'contact_need': 2.0, 'reassurance_need': 2.0},
    'frequency_v2_q0295_b': {'autonomy': 2.0},
    'frequency_v2_q0295_c': {'initiative': 1.0, 'disclosure_pace': 1.0},
    'frequency_v2_q0295_d': {'uncertainty_tolerance': 1.0, 'adaptability': 1.0},
    'frequency_v2_q0344_d': {'boundary_firmness': 2.0},
    'frequency_v2_q0346_c': {'initiative': 1.0, 'disclosure_pace': -1.0},
    'frequency_v2_q0347_b': {
      'reassurance_need': 1.0,
      'uncertainty_tolerance': -1.0
    },
    'frequency_v2_q0351_a': {'adaptability': 1.0},
    'frequency_v2_q0354_c': {'adaptability': 1.0},
    'frequency_v2_q0356_d': {
      'reassurance_need': 1.0,
      'uncertainty_tolerance': -1.0
    },
    'frequency_v2_q0357_d': {'uncertainty_tolerance': 1.0, 'adaptability': 1.0},
    'frequency_v2_q0358_d': {'initiative': 1.0, 'uncertainty_tolerance': 1.0},
    'frequency_v2_q0359_d': {'initiative': 1.0, 'boundary_firmness': 1.0},
    'frequency_v2_q0364_c': {'reassurance_need': 1.0},
    'frequency_v2_q0369_a': {
      'closeness_pace': 1.0,
      'structure_preference': 1.0
    },
    'frequency_v2_q0370_d': {
      'uncertainty_tolerance': -2.0,
      'boundary_firmness': -1.0
    },
    'frequency_v2_q0380_a': {'initiative': 2.0},
    'frequency_v2_q0381_c': {'disclosure_pace': -2.0},
    'frequency_v2_q0390_d': {'repair_style': 1.0, 'social_energy': -1.0},
    'frequency_v2_q0392_a': {'closeness_pace': 1.0, 'initiative': 1.0},
  };

  static const List<String> phase1fApprovedPrimaryIds = [
    'frequency_v2_q0009',
    'frequency_v2_q0015',
    'frequency_v2_q0020',
    'frequency_v2_q0027',
    'frequency_v2_q0028',
    'frequency_v2_q0038',
    'frequency_v2_q0064',
    'frequency_v2_q0071',
    'frequency_v2_q0076',
    'frequency_v2_q0134',
    'frequency_v2_q0156',
    'frequency_v2_q0166',
    'frequency_v2_q0186',
    'frequency_v2_q0228',
    'frequency_v2_q0255',
    'frequency_v2_q0258',
    'frequency_v2_q0261',
    'frequency_v2_q0264',
    'frequency_v2_q0272',
    'frequency_v2_q0275',
    'frequency_v2_q0282',
    'frequency_v2_q0284',
    'frequency_v2_q0288',
    'frequency_v2_q0290',
    'frequency_v2_q0294',
    'frequency_v2_q0298',
    'frequency_v2_q0317',
    'frequency_v2_q0346',
    'frequency_v2_q0348',
    'frequency_v2_q0352',
    'frequency_v2_q0358',
    'frequency_v2_q0360',
    'frequency_v2_q0370',
    'frequency_v2_q0375',
    'frequency_v2_q0382',
    'frequency_v2_q0390',
    'frequency_v2_q0393',
    'frequency_v2_q0409',
    'frequency_v2_q0005',
    'frequency_v2_q0011',
    'frequency_v2_q0021',
    'frequency_v2_q0026',
    'frequency_v2_q0030',
    'frequency_v2_q0033',
    'frequency_v2_q0035',
    'frequency_v2_q0065',
    'frequency_v2_q0130',
    'frequency_v2_q0139',
    'frequency_v2_q0274',
    'frequency_v2_q0286',
    'frequency_v2_q0356',
    'frequency_v2_q0363',
    'frequency_v2_q0377',
    'frequency_v2_q0392',
  ];

  static const List<String> phase1fRewritePendingIds = [
    'frequency_v2_q0037',
    'frequency_v2_q0163',
    'frequency_v2_q0295',
    'frequency_v2_q0365',
    'frequency_v2_q0406',
    'frequency_v2_q0039',
    'frequency_v2_q0254',
    'frequency_v2_q0281',
    'frequency_v2_q0353',
    'frequency_v2_q0372',
    'frequency_v2_q0383',
    'frequency_v2_q0008',
    'frequency_v2_q0018',
    'frequency_v2_q0043',
    'frequency_v2_q0070',
    'frequency_v2_q0094',
    'frequency_v2_q0099',
    'frequency_v2_q0113',
    'frequency_v2_q0180',
    'frequency_v2_q0183',
    'frequency_v2_q0192',
    'frequency_v2_q0266',
    'frequency_v2_q0271',
    'frequency_v2_q0287',
    'frequency_v2_q0301',
    'frequency_v2_q0391',
  ];

  static const List<String> phase1fDropFromSelectableIds = [
    'frequency_v2_q0333',
    'frequency_v2_q0373',
    'frequency_v2_q0426',
    'frequency_v2_q0003',
    'frequency_v2_q0023',
    'frequency_v2_q0029',
    'frequency_v2_q0047',
    'frequency_v2_q0127',
    'frequency_v2_q0128',
    'frequency_v2_q0135',
    'frequency_v2_q0153',
    'frequency_v2_q0191',
    'frequency_v2_q0252',
    'frequency_v2_q0292',
    'frequency_v2_q0321',
    'frequency_v2_q0361',
    'frequency_v2_q0380',
    'frequency_v2_q0405',
  ];

  static const List<String> phase2eRewriteIds = [
    'frequency_v2_q0020',
    'frequency_v2_q0026',
    'frequency_v2_q0030',
    'frequency_v2_q0035',
    'frequency_v2_q0213',
    'frequency_v2_q0317',
    'frequency_v2_q0377',
    'frequency_v2_q0393',
    'frequency_v2_q0409',
    'frequency_v2_q0410',
  ];

  static const List<String> phase2eNewDropIds = [
    'frequency_v2_q0123',
    'frequency_v2_q0332',
  ];

  static const List<String> phase2fNewDropIds = [
    'frequency_v2_q0409',
  ];

  static const List<String> phase2fUnchangedRewrittenIds = [
    'frequency_v2_q0213',
    'frequency_v2_q0377',
    'frequency_v2_q0410',
  ];

  static const List<String> phase2fOverrideQuestionIds = [
    'frequency_v2_q0020',
    'frequency_v2_q0026',
    'frequency_v2_q0030',
    'frequency_v2_q0035',
    'frequency_v2_q0317',
    'frequency_v2_q0393',
  ];

  static const Map<String, String> phase1cStemPrompts = {
    'frequency_v2_q0169':
        'Hayatındaki işler hiç yolunda gitmiyor. Bu dönemde partnerinle iletişimini ve desteği nasıl yönetirsin?',
    'frequency_v2_q0191':
        'İlişkiniz günlük rutine oturduğunda, bağı sürdürmek sana en doğal olarak nasıl gelir?',
    'frequency_v2_q0274':
        'Birlikte kanepede otururken yarım saattir ikiniz de hiç konuşmadınız. Sen ne yaparsın?',
    'frequency_v2_q0295':
        'Günün stresiyle sessizce ağlamaya başladın. Partnerin odaya girdi. Sen ne yaparsın?',
  };

  static const Map<String, String> phase1cRewrittenOptionTexts = {
    'frequency_v2_q0169_a':
        'Daha sık yazar veya arar, günü anlatır, yanında olmasını açıkça isterim.',
    'frequency_v2_q0169_b':
        'Yemek, fatura gibi somut işleri paylaşmayı önerir, ondan bir işi üstlenmesini isterim.',
    'frequency_v2_q0169_c':
        'Konuyu ben açana kadar temasımı azaltır, kendi halime çekilirim.',
    'frequency_v2_q0169_d':
        'Kafamı dağıtacak bir plan öneririm; dışarı çıkmayı veya hafif bir şey yapmayı teklif ederim.',
    'frequency_v2_q0191_a':
        'Gün içinde birkaç kez açıkça "yanındayım / iyi ki varsın" der, sözel yakınlığı sürdürürüm.',
    'frequency_v2_q0191_b':
        'Konuşmasak da yan yana vakit geçiririm; sessiz ortaklık bana yeter.',
    'frequency_v2_q0191_c':
        'Gündüz herkes kendi işine bakar; akşam ortak zamanda buluşuruz.',
    'frequency_v2_q0191_d':
        'Ortak takvimi ve para planını net tutarım; neyin ne zaman olacağını bilmek isterim.',
    'frequency_v2_q0274_a':
        '"Sıkıldın mı / bir şey mi var?" diye sorar, sessizliği bozarım.',
    'frequency_v2_q0274_b':
        'Sessizce oturmaya devam ederim; konuşmaya gerek duymam.',
    'frequency_v2_q0274_c':
        'Kendi işime veya telefona dönerim; sessizliği bozmam.',
    'frequency_v2_q0274_d':
        'Müzik açar veya kalkıp başka bir işle meşgul olurum.',
    'frequency_v2_q0295_a':
        'Soru sormasını beklemeden ona uzanır, sarılmasını isterim.',
    'frequency_v2_q0295_b':
        '"Anlatmak istersem çağırırım" der, biraz kendi halime çekilirim.',
    'frequency_v2_q0295_c':
        'Ne olduğunu hemen anlatır, birlikte bir çıkış ararım.',
    'frequency_v2_q0295_d':
        'Konuyu dağıtacak bir şey öneririm; kısa bir şaka, film veya müzik açmayı teklif ederim.',
    'frequency_v2_q0193_c':
        'O an teşekkür ederim; sonraki günlerde hediyeyi pek kullanmam, sonra konuyu dolaylı şekilde açarım.',
    'frequency_v2_q0272_b':
        'O an üstüne gitmem; sohbetin devamında cevaplarımı kısaltır, konuyu başka bir yere çeviririm.',
    'frequency_v2_q0344_d':
        'Çıkışta "Bir dahakine söyleyelim, böyle geçiştirmek bana zor geliyor" derim.',
    'frequency_v2_q0347_b':
        'İptali anladığımı söylerim; ertesi gün "Dün ne olmuştu, şimdi her şey yolunda mı?" diye sorarım.',
  };

  static String itemIdFromOptionId(String optionId) {
    final i = optionId.lastIndexOf('_');
    return optionId.substring(0, i);
  }

  /// Parse the Phase 1G human-authority rewrite file.
  static Map<String, FrequencyBehaviorV2Phase1gRewrite> loadPhase1gRewrites() {
    return _parseRewriteAuthority(
      File('$repoRoot/${FrequencyBehaviorV2Contract.humanDecisionPhase1gFile}')
          .readAsStringSync(),
      endMarker: 'FINAL APPROVAL STATUS',
    );
  }

  /// Parse the Phase 2E human-authority rewrite blocks.
  static Map<String, FrequencyBehaviorV2Phase1gRewrite> loadPhase2eRewrites() {
    final text = File(
      '$repoRoot/${FrequencyBehaviorV2Contract.humanDecisionPhase2eFile}',
    ).readAsStringSync();
    final body =
        text.split('D. REWRITE REQUIRED')[1].split('E. ±1 DIAGNOSTIC')[0];
    return _parseRewriteAuthority(body, endMarker: null);
  }

  static Map<String, FrequencyBehaviorV2Phase1gRewrite> _parseRewriteAuthority(
    String text, {
    required String? endMarker,
  }) {
    final idRe =
        RegExp(r'^(\d+)\)\s+(frequency_v2_q\d{4})\s*$', multiLine: true);
    final matches = idRe.allMatches(text).toList();
    final end = endMarker == null ? -1 : text.indexOf(endMarker);
    final out = <String, FrequencyBehaviorV2Phase1gRewrite>{};
    for (var i = 0; i < matches.length; i++) {
      final qid = matches[i].group(2)!;
      final start = matches[i].end;
      final stop = i + 1 < matches.length
          ? matches[i + 1].start
          : (end > 0 ? end : text.length);
      final block = text.substring(start, stop);
      final primary = RegExp(
        r'^primary_dimension:\s*([a-z_]+)\s*$',
        multiLine: true,
      ).firstMatch(block)!.group(1)!;
      final secondary = RegExp(
        r'^secondary_dimensions:\s*(.+?)\s*$',
        multiLine: true,
      ).firstMatch(block)!.group(1)!.trim();
      final stem = RegExp(
        r'STEM:\s*\n(.+?)\nA:',
        dotAll: true,
      ).firstMatch(block)!.group(1)!.trim();
      final optionTexts = <String, String>{};
      final optionWeights = <String, Map<String, double>>{};
      for (final letter in ['A', 'B', 'C', 'D']) {
        final om = RegExp(
          '^$letter:\\s*(.+)\\nweight:\\s*([a-z_]+)\\s*([+-]?\\d+)\\s*\$',
          multiLine: true,
        ).firstMatch(block)!;
        final oid = '${qid}_${letter.toLowerCase()}';
        optionTexts[oid] = om.group(1)!.trim();
        optionWeights[oid] = {om.group(2)!: double.parse(om.group(3)!)};
      }
      out[qid] = FrequencyBehaviorV2Phase1gRewrite(
        itemId: qid,
        primary: primary,
        secondaryRaw: secondary,
        prompt: stem,
        optionTexts: optionTexts,
        optionWeights: optionWeights,
      );
    }
    return out;
  }
}

class FrequencyBehaviorV2Phase1gRewrite {
  const FrequencyBehaviorV2Phase1gRewrite({
    required this.itemId,
    required this.primary,
    required this.secondaryRaw,
    required this.prompt,
    required this.optionTexts,
    required this.optionWeights,
  });

  final String itemId;
  final String primary;
  final String secondaryRaw;
  final String prompt;
  final Map<String, String> optionTexts;
  final Map<String, Map<String, double>> optionWeights;
}
