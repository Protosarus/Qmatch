class AssessmentPersonaReference {
  const AssessmentPersonaReference({
    required this.id,
    required this.titleTr,
    required this.titleEn,
    required this.descriptionTr,
    required this.descriptionEn,
    required this.asset,
  });

  final String id;
  final String titleTr;
  final String titleEn;
  final String descriptionTr;
  final String descriptionEn;
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
    descriptionTr: 'Plan yapan, harekete geçen ve sonuca odaklanan güç.',
    descriptionEn:
        'The power that plans, takes action, and focuses on results.',
    asset: 'assets/images/assessment_persona_executor_reward_sparse.png',
  ),
  'koruyucu': AssessmentPersonaReference(
    id: 'koruyucu',
    titleTr: 'Koruyucu',
    titleEn: 'Guardian',
    descriptionTr: 'Sevdiklerini koruyan, güven veren ve sadık kalan güç.',
    descriptionEn:
        'The power that protects loved ones, inspires trust, and remains loyal.',
    asset: 'assets/images/assessment_persona_guardian_reward_sparse.png',
  ),
  'bilge': AssessmentPersonaReference(
    id: 'bilge',
    titleTr: 'Bilge',
    titleEn: 'Sage',
    descriptionTr: 'Bilgiyi arayan, anlayan ve başkalarına ışık tutan güç.',
    descriptionEn:
        'The power that seeks knowledge, understands it, and guides others.',
    asset: 'assets/images/assessment_persona_sage_reward_sparse.png',
  ),
  'lider': AssessmentPersonaReference(
    id: 'lider',
    titleTr: 'Lider',
    titleEn: 'Leader',
    descriptionTr:
        'İlham veren, yönlendiren ve insanları arkasından sürükleyen güç.',
    descriptionEn:
        'The power that inspires, guides, and rallies people behind it.',
    asset: 'assets/images/assessment_persona_leader_reward_sparse.png',
  ),
  'muhafiz': AssessmentPersonaReference(
    id: 'muhafiz',
    titleTr: 'Muhafız',
    titleEn: 'Sentinel',
    descriptionTr: 'Güvende tutan, düzen kuran ve istikrar sağlayan güç.',
    descriptionEn:
        'The power that keeps others safe, establishes order, and provides stability.',
    asset: 'assets/images/assessment_persona_guard_reward_sparse.png',
  ),
  'sifaci': AssessmentPersonaReference(
    id: 'sifaci',
    titleTr: 'Şifacı',
    titleEn: 'Healer',
    descriptionTr: 'İyileştiren, dengeleyen ve şefkatiyle dönüştüren güç.',
    descriptionEn:
        'The power that heals, restores balance, and transforms through compassion.',
    asset: 'assets/images/assessment_persona_healer_reward_sparse.png',
  ),
  'yargic': AssessmentPersonaReference(
    id: 'yargic',
    titleTr: 'Yargıç',
    titleEn: 'Judge',
    descriptionTr:
        'Adil olanı gören, doğru kararlar veren ve dengeyi sağlayan güç.',
    descriptionEn:
        'The power that recognizes what is fair, makes sound decisions, and restores balance.',
    asset: 'assets/images/assessment_persona_judge_reward_sparse.png',
  ),
  'empat': AssessmentPersonaReference(
    id: 'empat',
    titleTr: 'Empat',
    titleEn: 'Empath',
    descriptionTr: 'İnsanları anlayan, kalpten bağ kuran ve destek olan güç.',
    descriptionEn:
        'The power that understands people, connects from the heart, and offers support.',
    asset: 'assets/images/assessment_persona_empath_reward_sparse.png',
  ),
  'cesur': AssessmentPersonaReference(
    id: 'cesur',
    titleTr: 'Cesur',
    titleEn: 'Brave',
    descriptionTr: 'Korkusuzca ilerleyen, risk alan ve meydan okuyan güç.',
    descriptionEn:
        'The power that moves forward fearlessly, takes risks, and embraces challenges.',
    asset: 'assets/images/assessment_persona_brave_reward_sparse.png',
  ),
  'kararli': AssessmentPersonaReference(
    id: 'kararli',
    titleTr: 'Kararlı',
    titleEn: 'Determined',
    descriptionTr: 'Pes etmeyen, azimli ve hedeflerine ulaşan güç.',
    descriptionEn:
        'The power that never gives up, stays determined, and reaches its goals.',
    asset: 'assets/images/assessment_persona_determined_reward_sparse.png',
  ),
  'vizyoner': AssessmentPersonaReference(
    id: 'vizyoner',
    titleTr: 'Vizyoner',
    titleEn: 'Visionary',
    descriptionTr: 'Geleceği gören, hayal eden ve büyük düşünen güç.',
    descriptionEn:
        'The power that sees the future, imagines possibilities, and thinks big.',
    asset: 'assets/images/assessment_persona_visionary_reward_sparse.png',
  ),
  'yaratici': AssessmentPersonaReference(
    id: 'yaratici',
    titleTr: 'Yaratıcı',
    titleEn: 'Creator',
    descriptionTr:
        'Farklı düşünen, ortaya yeni şeyler koyan ve ilham veren güç.',
    descriptionEn:
        'The power that thinks differently, creates new things, and inspires others.',
    asset: 'assets/images/assessment_persona_creator_reward_sparse.png',
  ),
  'iletisimci': AssessmentPersonaReference(
    id: 'iletisimci',
    titleTr: 'İletişimci',
    titleEn: 'Communicator',
    descriptionTr:
        'Kelimeleri doğru kullanan, duyguları ifade eden ve bağlantı kuran güç.',
    descriptionEn:
        'The power that chooses words well, expresses emotions, and builds connections.',
    asset: 'assets/images/assessment_persona_communicator_medallion.png',
  ),
  'analist': AssessmentPersonaReference(
    id: 'analist',
    titleTr: 'Analist',
    titleEn: 'Analyst',
    descriptionTr:
        'Detayları çözen, mantıkla sonuca ulaşan ve analiz eden güç.',
    descriptionEn:
        'The power that deciphers details, reasons toward conclusions, and analyzes.',
    asset: 'assets/images/assessment_persona_analyst_medallion.png',
  ),
  'donusturucu': AssessmentPersonaReference(
    id: 'donusturucu',
    titleTr: 'Dönüştürücü',
    titleEn: 'Transformer',
    descriptionTr: 'Değişimi başlatan, dönüşen ve başkalarını dönüştüren güç.',
    descriptionEn:
        'The power that initiates change, transforms, and transforms others.',
    asset: 'assets/images/assessment_persona_transformer_medallion.png',
  ),
  'bagimsiz': AssessmentPersonaReference(
    id: 'bagimsiz',
    titleTr: 'Bağımsız',
    titleEn: 'Independent',
    descriptionTr:
        'Özgürlüğüne düşkün, kendi yolunu çizen ve bağımsız olan güç.',
    descriptionEn:
        'The power that values freedom, charts its own path, and remains independent.',
    asset: 'assets/images/assessment_persona_independent_medallion.png',
  ),
  'sezgisel': AssessmentPersonaReference(
    id: 'sezgisel',
    titleTr: 'Sezgisel',
    titleEn: 'Intuitive',
    descriptionTr: 'Sezgileri güçlü olan, derinleri gören ve hisseden güç.',
    descriptionEn:
        'The power of strong intuition that sees and feels beneath the surface.',
    asset: 'assets/images/assessment_persona_intuitive_medallion.png',
  ),
  'stratejist': AssessmentPersonaReference(
    id: 'stratejist',
    titleTr: 'Stratejist',
    titleEn: 'Strategist',
    descriptionTr: 'Hamlelerini önceden gören, planlayan güç.',
    descriptionEn: 'The power that sees and plans every move ahead.',
    asset: 'assets/images/assessment_persona_strategist_knight_medallion.png',
  ),
};
