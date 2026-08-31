# Frequency V2 Phase 1C — Apply approved 12D decisions

Status: **draft_not_runtime**. V2 remains dormant. Evidence-layer values were not assigned.

Authority: `docs/qmatch_frequency_v2_phase1b_human_decisions.txt`
If this file differed from the Phase 1B packet, the human file won.

## Counts

- **Option weight sets changed:** 51
- **Full stems rewritten:** 4 (`frequency_v2_q0169, frequency_v2_q0191, frequency_v2_q0274, frequency_v2_q0295`)
- **Individual options rewritten:** 4 (`frequency_v2_q0193_c, frequency_v2_q0272_b, frequency_v2_q0344_d, frequency_v2_q0347_b`)
- **Legacy/unknown labels remaining (review unresolved):** {}
- **processing_style weights remaining (option unresolved_weights):** 0
- **12D dimensions used in pool behavioral_weights:** contact_need, closeness_pace, initiative, autonomy, reassurance_need, uncertainty_tolerance, disclosure_pace, boundary_firmness, repair_style, social_energy, structure_preference, adaptability
- **Options with zero canonical behavioral evidence:** 0
- **Questions with no scorable options:** 0
- **Questions with pending primary review:** 29
- **evidence_meta:** still all `null` / `review_status=pending` (unassigned)
- **V1 SHA-256:** not modified in this phase (confirmed by tests)
- **Live runtime:** unchanged (locale still loads `frequency_bank_*_v1`; `runtime_selectable=false`)
- **Non-canonical weight leaks in pool JSON:** 0

## repair_style orientation (enforced as documentation, not a moral score)

- `+2` = immediate / active repair engagement
- `+1` = mildly active repair / constructive revisit
- `-1` = delayed / partial / mixed repair, often pause-then-return
- `-2` = blocked / withdrawn / shut-down repair with no explicit return in the option

Negative values are a pacing/engagement direction, not unhealthy/toxic/bad.

## Stem rewrites applied

### `frequency_v2_q0169`

Hayatındaki işler hiç yolunda gitmiyor. Bu dönemde partnerinle iletişimini ve desteği nasıl yönetirsin?

- `frequency_v2_q0169_a`: Daha sık yazar veya arar, günü anlatır, yanında olmasını açıkça isterim.
  - contact_need +2, reassurance_need +2
- `frequency_v2_q0169_b`: Yemek, fatura gibi somut işleri paylaşmayı önerir, ondan bir işi üstlenmesini isterim.
  - closeness_pace +1, initiative +1
- `frequency_v2_q0169_c`: Konuyu ben açana kadar temasımı azaltır, kendi halime çekilirim.
  - autonomy +2, boundary_firmness +2
- `frequency_v2_q0169_d`: Kafamı dağıtacak bir plan öneririm; dışarı çıkmayı veya hafif bir şey yapmayı teklif ederim.
  - social_energy +1, adaptability +1

### `frequency_v2_q0191`

İlişkiniz günlük rutine oturduğunda, bağı sürdürmek sana en doğal olarak nasıl gelir?

- `frequency_v2_q0191_a`: Gün içinde birkaç kez açıkça "yanındayım / iyi ki varsın" der, sözel yakınlığı sürdürürüm.
  - reassurance_need +2, disclosure_pace +1
- `frequency_v2_q0191_b`: Konuşmasak da yan yana vakit geçiririm; sessiz ortaklık bana yeter.
  - closeness_pace +2
- `frequency_v2_q0191_c`: Gündüz herkes kendi işine bakar; akşam ortak zamanda buluşuruz.
  - autonomy +2, boundary_firmness +1
- `frequency_v2_q0191_d`: Ortak takvimi ve para planını net tutarım; neyin ne zaman olacağını bilmek isterim.
  - uncertainty_tolerance -2, structure_preference +2

### `frequency_v2_q0274`

Birlikte kanepede otururken yarım saattir ikiniz de hiç konuşmadınız. Sen ne yaparsın?

- `frequency_v2_q0274_a`: "Sıkıldın mı / bir şey mi var?" diye sorar, sessizliği bozarım.
  - contact_need +1, reassurance_need +2
- `frequency_v2_q0274_b`: Sessizce oturmaya devam ederim; konuşmaya gerek duymam.
  - closeness_pace +2
- `frequency_v2_q0274_c`: Kendi işime veya telefona dönerim; sessizliği bozmam.
  - autonomy +2, uncertainty_tolerance +1
- `frequency_v2_q0274_d`: Müzik açar veya kalkıp başka bir işle meşgul olurum.
  - social_energy +1, structure_preference -1

### `frequency_v2_q0295`

Günün stresiyle sessizce ağlamaya başladın. Partnerin odaya girdi. Sen ne yaparsın?

- `frequency_v2_q0295_a`: Soru sormasını beklemeden ona uzanır, sarılmasını isterim.
  - contact_need +2, reassurance_need +2
- `frequency_v2_q0295_b`: "Anlatmak istersem çağırırım" der, biraz kendi halime çekilirim.
  - autonomy +2
- `frequency_v2_q0295_c`: Ne olduğunu hemen anlatır, birlikte bir çıkış ararım.
  - initiative +1, disclosure_pace +1
- `frequency_v2_q0295_d`: Konuyu dağıtacak bir şey öneririm; kısa bir şaka, film veya müzik açmayı teklif ederim.
  - uncertainty_tolerance +1, adaptability +1

## Single-option rewrites applied

- `frequency_v2_q0193_c`: O an teşekkür ederim; sonraki günlerde hediyeyi pek kullanmam, sonra konuyu dolaylı şekilde açarım.
  - reassurance_need +1, disclosure_pace -1
- `frequency_v2_q0272_b`: O an üstüne gitmem; sohbetin devamında cevaplarımı kısaltır, konuyu başka bir yere çeviririm.
  - reassurance_need +2, disclosure_pace -1
- `frequency_v2_q0344_d`: Çıkışta "Bir dahakine söyleyelim, böyle geçiştirmek bana zor geliyor" derim.
  - boundary_firmness +2
- `frequency_v2_q0347_b`: İptali anladığımı söylerim; ertesi gün "Dün ne olmuştu, şimdi her şey yolunda mı?" diye sorarım.
  - reassurance_need +1, uncertainty_tolerance -1

## Option IDs whose canonical weights changed

- `frequency_v2_q0169_b` → closeness_pace +1, initiative +1
- `frequency_v2_q0295_c` → initiative +1, disclosure_pace +1
- `frequency_v2_q0193_c` → reassurance_need +1, disclosure_pace -1
- `frequency_v2_q0272_b` → reassurance_need +2, disclosure_pace -1
- `frequency_v2_q0347_b` → reassurance_need +1, uncertainty_tolerance -1
- `frequency_v2_q0003_a` → initiative +1
- `frequency_v2_q0005_c` → uncertainty_tolerance -1, repair_style -1
- `frequency_v2_q0005_d` → closeness_pace +1, repair_style +1
- `frequency_v2_q0015_a` → reassurance_need +1, repair_style +2
- `frequency_v2_q0015_b` → boundary_firmness +1, repair_style +1
- `frequency_v2_q0015_d` → autonomy +1, repair_style -1
- `frequency_v2_q0029_a` → uncertainty_tolerance -1, repair_style +1
- `frequency_v2_q0037_a` → closeness_pace +1, repair_style +2
- `frequency_v2_q0037_b` → boundary_firmness +2, repair_style -1
- `frequency_v2_q0043_a` → initiative +1, structure_preference +1
- `frequency_v2_q0166_a` → closeness_pace +1, repair_style +2
- `frequency_v2_q0166_b` → autonomy +2, repair_style -1
- `frequency_v2_q0170_d` → repair_style -1, structure_preference +1
- `frequency_v2_q0186_b` → boundary_firmness -1, repair_style +2
- `frequency_v2_q0252_a` → disclosure_pace +1, repair_style +1
- `frequency_v2_q0261_a` → contact_need -1, repair_style -1
- `frequency_v2_q0357_d` → uncertainty_tolerance +1, adaptability +1
- `frequency_v2_q0369_a` → closeness_pace +1, structure_preference +1
- `frequency_v2_q0380_a` → initiative +2
- `frequency_v2_q0016_c` → disclosure_pace -1
- `frequency_v2_q0026_a` → initiative +1
- `frequency_v2_q0027_d` → autonomy +1, disclosure_pace -1
- `frequency_v2_q0038_d` → uncertainty_tolerance +1, adaptability +1
- `frequency_v2_q0154_b` → structure_preference +2
- `frequency_v2_q0163_b` → disclosure_pace +2
- `frequency_v2_q0166_d` → boundary_firmness +2, repair_style -1
- `frequency_v2_q0170_c` → boundary_firmness -1, repair_style -2
- `frequency_v2_q0183_b` → adaptability +1
- `frequency_v2_q0185_b` → uncertainty_tolerance -1
- `frequency_v2_q0186_d` → boundary_firmness +2, repair_style -1
- `frequency_v2_q0195_d` → reassurance_need +1, uncertainty_tolerance -2
- `frequency_v2_q0198_a` → adaptability -1
- `frequency_v2_q0252_c` → disclosure_pace -1, repair_style -1
- `frequency_v2_q0256_c` → initiative +1
- `frequency_v2_q0264_b` → autonomy +2, disclosure_pace -1
- `frequency_v2_q0271_d` → initiative +1, autonomy +1
- `frequency_v2_q0288_d` → initiative +1, boundary_firmness +1
- `frequency_v2_q0346_c` → initiative +1, disclosure_pace -1
- `frequency_v2_q0351_a` → adaptability +1
- `frequency_v2_q0354_c` → adaptability +1
- `frequency_v2_q0356_d` → reassurance_need +1, uncertainty_tolerance -1
- `frequency_v2_q0358_d` → initiative +1, uncertainty_tolerance +1
- `frequency_v2_q0359_d` → initiative +1, boundary_firmness +1
- `frequency_v2_q0370_d` → uncertainty_tolerance -2, boundary_firmness -1
- `frequency_v2_q0390_d` → repair_style +1, social_energy -1
- `frequency_v2_q0392_a` → closeness_pace +1, initiative +1

## Safety

- Source pool text file not modified
- Frequency V1 banks not modified
- pubspec.yaml not modified
- Live locale routing not modified
- Discover / Persona / matching / canonical_v1 / C2 / FrequencyTo20dRuntimeAdapter not modified
- No 12D→6D map
- No Firebase deploy
- No commit/push

FREQUENCY V2 PHASE 1C APPROVED 12D DECISIONS APPLIED — V2 STILL DORMANT
