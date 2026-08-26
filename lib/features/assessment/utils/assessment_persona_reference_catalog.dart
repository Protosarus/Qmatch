class AssessmentPersonaReference {
  const AssessmentPersonaReference({
    required this.id,
    required this.titleTr,
    required this.titleEn,
    required this.descriptionTr,
    required this.descriptionEn,
    required this.signatureTr,
    required this.signatureEn,
    required this.asset,
  });

  final String id;
  final String titleTr;
  final String titleEn;
  final String descriptionTr;
  final String descriptionEn;
  final String signatureTr;
  final String signatureEn;
  final String asset;
}

/// User-approved persona references.
///
/// This catalog is collected independently from the current scoring codes.
/// Code/category mapping will be wired after the complete persona set is
/// approved.
const assessmentPersonaReferenceCatalog = <String, AssessmentPersonaReference>{
  'uygulayici': AssessmentPersonaReference(
    id: 'uygulayici',
    titleTr: 'Uygulayıcı',
    titleEn: 'Executor',
    descriptionTr: 'Planı eyleme, eylemi sonuca dönüştürür.',
    descriptionEn: 'Turns plans into action, and action into results.',
    signatureTr: 'Sonuç Odaklı',
    signatureEn: 'Results Driven',
    asset: 'assets/images/assessment_persona_executor_reward_sparse.png',
  ),
  'koruyucu': AssessmentPersonaReference(
    id: 'koruyucu',
    titleTr: 'Koruyucu',
    titleEn: 'Guardian',
    descriptionTr: 'Bağ kurduğu insanlara güven ve aidiyet hissi verir.',
    descriptionEn:
        'Creates a sense of trust and belonging for the people they value.',
    signatureTr: 'Güven Veren',
    signatureEn: 'Steady Trust',
    asset: 'assets/images/assessment_persona_guardian_reward_sparse.png',
  ),
  'bilge': AssessmentPersonaReference(
    id: 'bilge',
    titleTr: 'Bilge',
    titleEn: 'Sage',
    descriptionTr: 'Bilgiyi derinleştirir, görünenin ardındaki anlamı arar.',
    descriptionEn:
        'Goes deeper into knowledge and searches for meaning beyond the obvious.',
    signatureTr: 'Derin Kavrayış',
    signatureEn: 'Deep Insight',
    asset: 'assets/images/assessment_persona_sage_reward_sparse.png',
  ),
  'lider': AssessmentPersonaReference(
    id: 'lider',
    titleTr: 'Lider',
    titleEn: 'Leader',
    descriptionTr:
        'Yönü belirler, insanları harekete geçirecek cesareti yaratır.',
    descriptionEn:
        'Sets direction and inspires others with the courage to move.',
    signatureTr: 'Yön Veren',
    signatureEn: 'Guiding Force',
    asset: 'assets/images/assessment_persona_leader_reward_sparse.png',
  ),
  'muhafiz': AssessmentPersonaReference(
    id: 'muhafiz',
    titleTr: 'Muhafız',
    titleEn: 'Sentinel',
    descriptionTr: 'Düzeni korur, sınırları gözetir ve istikrarı sürdürür.',
    descriptionEn:
        'Protects order, respects boundaries, and preserves stability.',
    signatureTr: 'Sağlam Duruş',
    signatureEn: 'Steady Ground',
    asset: 'assets/images/assessment_persona_guard_reward_sparse.png',
  ),
  'sifaci': AssessmentPersonaReference(
    id: 'sifaci',
    titleTr: 'Şifacı',
    titleEn: 'Healer',
    descriptionTr:
        'Şefkatle yaklaşır, gerilimi yumuşatır ve dengeyi yeniden kurar.',
    descriptionEn: 'Meets tension with compassion and helps restore balance.',
    signatureTr: 'Şefkatli Denge',
    signatureEn: 'Compassionate Balance',
    asset: 'assets/images/assessment_persona_healer_reward_sparse.png',
  ),
  'yargic': AssessmentPersonaReference(
    id: 'yargic',
    titleTr: 'Yargıç',
    titleEn: 'Judge',
    descriptionTr: 'Ölçer, tartar ve en adil yolu bulmaya çalışır.',
    descriptionEn:
        'Weighs every side and searches for the fairest path forward.',
    signatureTr: 'Adil Karar',
    signatureEn: 'Fair Judgment',
    asset: 'assets/images/assessment_persona_judge_reward_sparse.png',
  ),
  'empat': AssessmentPersonaReference(
    id: 'empat',
    titleTr: 'Empat',
    titleEn: 'Empath',
    descriptionTr:
        'Söylenmeyeni de hisseder, karşısındakinin dünyasına yaklaşır.',
    descriptionEn:
        'Senses what remains unspoken and moves closer to another person’s world.',
    signatureTr: 'Derin Empati',
    signatureEn: 'Deep Empathy',
    asset: 'assets/images/assessment_persona_empath_reward_sparse.png',
  ),
  'cesur': AssessmentPersonaReference(
    id: 'cesur',
    titleTr: 'Cesur',
    titleEn: 'Brave',
    descriptionTr:
        'Belirsizliğe rağmen adım atar, geri çekilmek yerine yüzleşir.',
    descriptionEn:
        'Steps forward despite uncertainty and chooses to face what lies ahead.',
    signatureTr: 'Cesur Adım',
    signatureEn: 'Bold Step',
    asset: 'assets/images/assessment_persona_brave_reward_sparse.png',
  ),
  'kararli': AssessmentPersonaReference(
    id: 'kararli',
    titleTr: 'Kararlı',
    titleEn: 'Determined',
    descriptionTr: 'Bir hedef seçtiğinde engellere rağmen yönünü korur.',
    descriptionEn: 'Once a goal is chosen, keeps course despite the obstacles.',
    signatureTr: 'Sarsılmaz İrade',
    signatureEn: 'Unshaken Will',
    asset: 'assets/images/assessment_persona_determined_reward_sparse.png',
  ),
  'vizyoner': AssessmentPersonaReference(
    id: 'vizyoner',
    titleTr: 'Vizyoner',
    titleEn: 'Visionary',
    descriptionTr:
        'Bugünün sınırlarının ötesinde neyin mümkün olabileceğini görür.',
    descriptionEn:
        'Sees what could become possible beyond the limits of today.',
    signatureTr: 'Gelecek Görüsü',
    signatureEn: 'Future Vision',
    asset: 'assets/images/assessment_persona_visionary_reward_sparse.png',
  ),
  'yaratici': AssessmentPersonaReference(
    id: 'yaratici',
    titleTr: 'Yaratıcı',
    titleEn: 'Creator',
    descriptionTr:
        'Alışılmış olanı yeniden düşünür, kendine özgü yollar üretir.',
    descriptionEn:
        'Reimagines the familiar and creates distinctly original paths.',
    signatureTr: 'Özgün Zihin',
    signatureEn: 'Original Mind',
    asset: 'assets/images/assessment_persona_creator_reward_sparse.png',
  ),
  'iletisimci': AssessmentPersonaReference(
    id: 'iletisimci',
    titleTr: 'İletişimci',
    titleEn: 'Communicator',
    descriptionTr:
        'Düşüncelerini açık eder, kelimelerle yakınlık ve anlayış kurar.',
    descriptionEn:
        'Expresses thoughts clearly and builds understanding through words.',
    signatureTr: 'Güçlü Bağ',
    signatureEn: 'Strong Connection',
    asset: 'assets/images/assessment_persona_communicator_medallion.png',
  ),
  'analist': AssessmentPersonaReference(
    id: 'analist',
    titleTr: 'Analist',
    titleEn: 'Analyst',
    descriptionTr: 'Detayları ayırır, örüntüyü bulur ve sonucu mantıkla kurar.',
    descriptionEn:
        'Breaks down details, finds the pattern, and builds conclusions through logic.',
    signatureTr: 'Keskin Analiz',
    signatureEn: 'Sharp Analysis',
    asset: 'assets/images/assessment_persona_analyst_medallion.png',
  ),
  'donusturucu': AssessmentPersonaReference(
    id: 'donusturucu',
    titleTr: 'Dönüştürücü',
    titleEn: 'Transformer',
    descriptionTr: 'Değişimden kaçmaz; eskiyi dönüştürerek yeni bir yön açar.',
    descriptionEn:
        'Does not resist change; reshapes what exists to open a new direction.',
    signatureTr: 'Değişim Gücü',
    signatureEn: 'Power of Change',
    asset: 'assets/images/assessment_persona_transformer_medallion.png',
  ),
  'bagimsiz': AssessmentPersonaReference(
    id: 'bagimsiz',
    titleTr: 'Bağımsız',
    titleEn: 'Independent',
    descriptionTr: 'Kendi alanını korur, kararlarını kendi pusulasıyla verir.',
    descriptionEn:
        'Protects personal space and makes decisions by an inner compass.',
    signatureTr: 'Özgür Rota',
    signatureEn: 'Own Path',
    asset: 'assets/images/assessment_persona_independent_medallion.png',
  ),
  'sezgisel': AssessmentPersonaReference(
    id: 'sezgisel',
    titleTr: 'Sezgisel',
    titleEn: 'Intuitive',
    descriptionTr: 'İnce işaretleri yakalar, içinden gelen sese kulak verir.',
    descriptionEn:
        'Notices subtle signals and listens closely to inner instinct.',
    signatureTr: 'İçsel Sezgi',
    signatureEn: 'Inner Intuition',
    asset: 'assets/images/assessment_persona_intuitive_medallion.png',
  ),
  'stratejist': AssessmentPersonaReference(
    id: 'stratejist',
    titleTr: 'Stratejist',
    titleEn: 'Strategist',
    descriptionTr: 'Birkaç hamle sonrasını düşünür, yönünü buna göre kurar.',
    descriptionEn:
        'Thinks several moves ahead and shapes direction accordingly.',
    signatureTr: 'Stratejik Öngörü',
    signatureEn: 'Strategic Foresight',
    asset: 'assets/images/assessment_persona_strategist_knight_medallion.png',
  ),
};
