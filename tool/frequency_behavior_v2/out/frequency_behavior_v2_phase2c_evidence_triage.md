# Frequency V2 Phase 2C — Evidence proposal triage

Status: **audit only**. No evidence values applied. Proposal scores unchanged.
Dormant pool `evidence_meta` remains `pending` / null. V2 remains `runtime_selectable=false`.

Source pool fingerprint SHA-256: `d03b2d8c77843d72baf072219c2c0dcae07a0d093dd1bf8c5268f0ef4ca6d56d`
Phase 2B proposal file SHA-256 (unchanged): `b77ea92995ddf22684878b188435f01933f3d001631e32daa7431313dff3ef92`

## Overall finding

**OVERFLAGGED_BY_REVIEW_RULE**

The 397/408 needs_human_review rate is not a bank-wide evidence collapse. Phase 2B set needs_human_review whenever any option lacked a weight on the named primary (356 questions) and/or diagnostic_value was uncertain under that purity rule (372). Secondary weights, ±1 vs ±2, tied evidence scores, and ordinary mixed motives are acceptable behavioral complexity, not defects. After re-triage, REAL_REVIEW_REQUIRED=29, ACCEPTABLE_COMPLEXITY=365, CLEAN=14; KEEP_FLAG=29, CLEAR_FLAG=368.

Interpretation of the 397-rate:

- **A) REAL_EVIDENCE_PROBLEM** — residual queue only (29 questions).
- **B) ACCEPTABLE_BEHAVIORAL_COMPLEXITY** — typical state of this bank (365 questions).
- **C) OVERFLAGGED_BY_REVIEW_RULE** — explains why 397 looked like a crisis.

No predetermined KEEP percentage was targeted.

## Counts

- CLEAN: **14**
- ACCEPTABLE_COMPLEXITY: **365**
- REAL_REVIEW_REQUIRED: **29**

Of previous 397 `needs_human_review=true` flags:

- KEEP_FLAG: **29**
- CLEAR_FLAG: **368**
- previously unflagged (not in the 397): **11**

## Reason-code counts (REAL_REVIEW_REQUIRED questions; multiple codes allowed)

- `SD_DOMINANCE`: 7
- `OBVIOUS_TEST_ANSWER`: 4
- `LOW_PLAUSIBILITY`: 1
- `OPTION_DUPLICATION`: 0
- `HIGH_AMBIGUITY`: 4
- `PRIMARY_AXIS_CONFUSION`: 7
- `CULTURAL_DEPENDENCE`: 10
- `SELF_PRESENTATION_HEAVY`: 7
- `LOW_DIAGNOSTIC_CONTRAST`: 7
- `OTHER`: 0

## REAL_REVIEW_REQUIRED question IDs (29)

`frequency_v2_q0002`, `frequency_v2_q0015`, `frequency_v2_q0020`, `frequency_v2_q0026`, `frequency_v2_q0030`, `frequency_v2_q0035`, `frequency_v2_q0049`, `frequency_v2_q0081`, `frequency_v2_q0097`, `frequency_v2_q0107`, `frequency_v2_q0123`, `frequency_v2_q0152`, `frequency_v2_q0156`, `frequency_v2_q0159`, `frequency_v2_q0176`, `frequency_v2_q0186`, `frequency_v2_q0197`, `frequency_v2_q0203`, `frequency_v2_q0208`, `frequency_v2_q0213`, `frequency_v2_q0227`, `frequency_v2_q0278`, `frequency_v2_q0317`, `frequency_v2_q0332`, `frequency_v2_q0375`, `frequency_v2_q0377`, `frequency_v2_q0393`, `frequency_v2_q0409`, `frequency_v2_q0410`

## Diagnostic-value bias audit (scores not modified)

Mean `diagnostic_value` by signed primary weight:

- +2 (n=326): 0.658
- +1 (n=222): 0.526
- −1 (n=184): 0.545
- −2 (n=160): 0.578
- 0 / off-primary (n=740): 0.269

Absolute primary weight:

- |2|: 0.632
- |1|: 0.534

On-primary vs off-primary:

- on-primary: 0.584
- off-primary: 0.262
- on-primary |2|: 0.632
- on-primary |1|: 0.534

Matched ambiguity × plausibility bins (on-primary only):

- am=0.25 pl=0.50: |2| n=4 mean=0.75; |1| n=0 mean=None; gap=None
- am=0.25 pl=0.75: |2| n=336 mean=0.642; |1| n=178 mean=0.548; gap=0.094
- am=0.25 pl=1.00: |2| n=16 mean=0.703; |1| n=55 mean=0.691; gap=0.012
- am=0.50 pl=0.25: |2| n=56 mean=0.513; |1| n=74 mean=0.375; gap=0.138
- am=0.50 pl=0.50: |2| n=16 mean=0.469; |1| n=37 mean=0.419; gap=0.05
- am=0.50 pl=0.75: |2| n=40 mean=0.744; |1| n=32 mean=0.664; gap=0.08
- am=0.50 pl=1.00: |2| n=0 mean=None; |1| n=1 mean=0.5; gap=None
- am=0.75 pl=0.25: |2| n=3 mean=0.75; |1| n=5 mean=0.75; gap=0.0
- am=0.75 pl=0.50: |2| n=0 mean=None; |1| n=1 mean=0.75; gap=None
- am=0.75 pl=0.75: |2| n=15 mean=0.583; |1| n=23 mean=0.522; gap=0.061

The large |weight|=2 vs otherwise gap in Phase 2B is mostly on-primary vs off-primary presence (off-primary mean diagnostic_value 0.262 vs on-primary 0.584). After restricting to on-primary options and matching ambiguity and plausibility bins, a smaller |2| vs |1| gap remains in the largest bin. That residual tracks more explicit ±2 wording plus Phase 2B axis-cue bonuses, not a silent |weight| formula. Scores were not changed.

### Sample: 20 ±2 options with diagnostic_value ≥ 0.75

- `frequency_v2_q0001_b` `initiative` w=-2 dv=1.00 am=0.50 pl=0.75 judgment=JUSTIFIED_BY_TEXT
  - Kendi akışımda kalırım, ilk adımı onun atması bana daha doğru gelir.
- `frequency_v2_q0002_b` `structure_preference` w=+2 dv=1.00 am=0.25 pl=0.75 judgment=JUSTIFIED_BY_TEXT
  - Biraz gerilirim, günün heba olmaması için en azından bir taslak olmasını tercih ederim.
- `frequency_v2_q0004_b` `social_energy` w=+2 dv=1.00 am=0.50 pl=0.75 judgment=JUSTIFIED_BY_TEXT
  - Gidip kendi başıma yeni insanlarla tanışır ve kendi sohbetimi kurarım.
- `frequency_v2_q0004_d` `social_energy` w=-2 dv=1.00 am=0.25 pl=0.75 judgment=JUSTIFIED_BY_TEXT
  - Bu tarz ortamlar beni yorduğu için erken kalkmak için uygun zamanı kollarım.
- `frequency_v2_q0007_b` `autonomy` w=+2 dv=1.00 am=0.25 pl=0.75 judgment=JUSTIFIED_BY_TEXT
  - Anlayışla karşılarım, benim de yalnız kalıp kendi işlerime bakacağım bir zaman doğmuş olur.
- `frequency_v2_q0008_a` `disclosure_pace` w=+2 dv=1.00 am=0.25 pl=0.75 judgment=JUSTIFIED_BY_TEXT
  - O anda ne hissettiğimi ve ne düşündüğümü açıkça anlatırım.
- `frequency_v2_q0008_d` `disclosure_pace` w=-2 dv=0.75 am=0.50 pl=0.75 judgment=JUSTIFIED_BY_TEXT
  - İlk tepkimi kendime saklar, ancak gerekirse daha sonra açarım.
- `frequency_v2_q0009_a` `closeness_pace` w=+2 dv=0.75 am=0.25 pl=0.75 judgment=JUSTIFIED_BY_TEXT
  - Memnuniyetle katılırım, onun çevresini tanımak süreci hızlandırır.
- `frequency_v2_q0009_b` `closeness_pace` w=-2 dv=0.75 am=0.25 pl=0.75 judgment=JUSTIFIED_BY_TEXT
  - Çok erken olduğunu düşünüp nazikçe reddederim, önce baş başa birbirimizi tanımalıyız.
- `frequency_v2_q0010_b` `contact_need` w=+2 dv=1.00 am=0.25 pl=0.75 judgment=JUSTIFIED_BY_TEXT
  - Fırsat buldukça kısa mesajlar veya komik bir şeyler atarak bağda kalmak isterim.
- `frequency_v2_q0011_a` `adaptability` w=+2 dv=0.75 am=0.25 pl=0.75 judgment=JUSTIFIED_BY_TEXT
  - Anında modumu değiştiririm, benim için ne yaptığımız değil birlikte olmamız önemlidir.
- `frequency_v2_q0014_c` `initiative` w=-2 dv=0.75 am=0.50 pl=0.75 judgment=JUSTIFIED_BY_TEXT
  - "Sen ne yemek istiyorsan bana uyar" der, onun inisiyatif almasını beklerim.
- `frequency_v2_q0015_a` `repair_style` w=+2 dv=0.75 am=0.50 pl=0.75 judgment=JUSTIFIED_BY_TEXT
  - Hemen yanına gidip sarılarak, duygusal bir şekilde özür dilerim.
- `frequency_v2_q0016_a` `boundary_firmness` w=+2 dv=1.00 am=0.50 pl=0.75 judgment=JUSTIFIED_BY_TEXT
  - Kendi sınırlarım nettir, rahatsızlığımı anında ve doğrudan dile getiririm.
- `frequency_v2_q0017_a` `social_energy` w=+2 dv=0.75 am=0.25 pl=0.75 judgment=JUSTIFIED_BY_TEXT
  - Partnerimle ve tüm yakın arkadaşlarımla kalabalık, dışa dönük, gürültülü bir kutlama.
- `frequency_v2_q0018_a` `uncertainty_tolerance` w=+2 dv=0.75 am=0.25 pl=0.75 judgment=JUSTIFIED_BY_TEXT
  - Daha fazla bilgi gelene kadar konuyu bir süre açık bırakabilirim.
- `frequency_v2_q0018_d` `uncertainty_tolerance` w=-2 dv=0.75 am=0.50 pl=0.75 judgment=JUSTIFIED_BY_TEXT
  - Rakamları ve olası çözümleri aynı gün mümkün olduğunca netleştirmeden rahat edemem.
- `frequency_v2_q0019_b` `structure_preference` w=-2 dv=1.00 am=0.25 pl=0.75 judgment=JUSTIFIED_BY_TEXT
  - Sürekli yeni mekanlar, yeni deneyimler keşfetmek isterim; rutin beni sıkar.
- `frequency_v2_q0022_b` `structure_preference` w=-2 dv=1.00 am=0.25 pl=0.75 judgment=JUSTIFIED_BY_TEXT
  - İşleri yaparken anlık gelişmeli, "sen şunu tut, ben bunu alayım" şeklinde organik ilerlemeli.
- `frequency_v2_q0027_a` `autonomy` w=+2 dv=0.75 am=0.25 pl=0.75 judgment=JUSTIFIED_BY_TEXT
  - Onu kesinlikle rahatsız etmem, sorunu tamamen tek başıma veya arkadaşlarımla çözerim.

Judgment counts: {'JUSTIFIED_BY_TEXT': 20}

### Sample: 20 ±1 options with diagnostic_value ≤ 0.25

- `frequency_v2_q0001_c` `initiative` w=+1 dv=0.25 am=0.25 pl=0.75 judgment=WEIGHT_MAGNITUDE_OR_CUE_LEAKAGE
  - Dünkü buluşmanın keyifli olduğunu belirten net, kısa bir mesaj atarım.
- `frequency_v2_q0006_c` `uncertainty_tolerance` w=+1 dv=0.25 am=0.25 pl=0.75 judgment=WEIGHT_MAGNITUDE_OR_CUE_LEAKAGE
  - Benzer hissettiğimizi eylemlerinden görüyorsam konuşulmaması beni rahatsız etmez.
- `frequency_v2_q0018_b` `uncertainty_tolerance` w=+1 dv=0.25 am=0.25 pl=0.75 judgment=WEIGHT_MAGNITUDE_OR_CUE_LEAKAGE
  - Sadece ilk adımı kabaca belirler, geri kalanını netleşince düşünürüm.
- `frequency_v2_q0062_d` `adaptability` w=+1 dv=0.25 am=0.25 pl=0.75 judgment=WEIGHT_MAGNITUDE_OR_CUE_LEAKAGE
  - Kendi alternatif planıma geçerim, fazla üstünde durmam.
- `frequency_v2_q0067_b` `closeness_pace` w=+1 dv=0.00 am=0.50 pl=0.25 judgment=JUSTIFIED_BY_TEXT
  - Bir noktada ben açarım.
- `frequency_v2_q0071_a` `reassurance_need` w=+1 dv=0.25 am=0.25 pl=0.75 judgment=JUSTIFIED_BY_TEXT
  - Ben sorarım, karşılıklılık beklerim.
- `frequency_v2_q0073_c` `boundary_firmness` w=+1 dv=0.25 am=0.50 pl=0.25 judgment=JUSTIFIED_BY_TEXT
  - Ortamı terk ederim.
- `frequency_v2_q0078_c` `initiative` w=+1 dv=0.25 am=0.50 pl=0.25 judgment=JUSTIFIED_BY_TEXT
  - Seçenek sunarım.
- `frequency_v2_q0080_c` `initiative` w=-1 dv=0.25 am=0.50 pl=0.25 judgment=JUSTIFIED_BY_TEXT
  - O yazarsa cevap veririm.
- `frequency_v2_q0082_b` `uncertainty_tolerance` w=+1 dv=0.25 am=0.25 pl=1.00 judgment=WEIGHT_MAGNITUDE_OR_CUE_LEAKAGE
  - İptal olursa kendi planıma geçerim.
- `frequency_v2_q0084_c` `boundary_firmness` w=+1 dv=0.25 am=0.50 pl=0.50 judgment=JUSTIFIED_BY_TEXT
  - Kendim uzaklaşırım.
- `frequency_v2_q0084_d` `boundary_firmness` w=-1 dv=0.25 am=0.50 pl=0.50 judgment=JUSTIFIED_BY_TEXT
  - Alışmaya çalışırım.
- `frequency_v2_q0086_b` `disclosure_pace` w=+1 dv=0.25 am=0.50 pl=0.50 judgment=JUSTIFIED_BY_TEXT
  - Genel hatlarıyla değinirim.
- `frequency_v2_q0100_a` `closeness_pace` w=+1 dv=0.00 am=0.50 pl=0.50 judgment=JUSTIFIED_BY_TEXT
  - Netliğe yaklaşırım.
- `frequency_v2_q0101_c` `initiative` w=+1 dv=0.25 am=0.25 pl=0.75 judgment=WEIGHT_MAGNITUDE_OR_CUE_LEAKAGE
  - “Dün güzeldi” gibi kısa ve net bir mesaj gönderirim.
- `frequency_v2_q0105_c` `initiative` w=+1 dv=0.25 am=0.50 pl=0.75 judgment=WEIGHT_MAGNITUDE_OR_CUE_LEAKAGE
  - Kendi planımı yapar, isterse bana katılmasını söylerim.
- `frequency_v2_q0129_c` `repair_style` w=-1 dv=0.25 am=0.25 pl=0.75 judgment=WEIGHT_MAGNITUDE_OR_CUE_LEAKAGE
  - Bir daha olmaması için birlikte hatırlatma/sistem kurmayı öneririm.
- `frequency_v2_q0133_d` `adaptability` w=+1 dv=0.25 am=0.25 pl=0.75 judgment=WEIGHT_MAGNITUDE_OR_CUE_LEAKAGE
  - Daha çok onun başlatmasına izin verir, müsait oldukça karşılık veririm.
- `frequency_v2_q0145_b` `repair_style` w=-1 dv=0.25 am=0.25 pl=0.75 judgment=WEIGHT_MAGNITUDE_OR_CUE_LEAKAGE
  - Bir daha unutulmaması için ortak bir hatırlatma sistemi kurmayı öneririm.
- `frequency_v2_q0151_b` `structure_preference` w=+1 dv=0.25 am=0.75 pl=0.75 judgment=JUSTIFIED_BY_TEXT
  - Çok hoşuma gider ama günün geri kalanındaki programımı da ufaktan gözden geçiririm.

Judgment counts: {'WEIGHT_MAGNITUDE_OR_CUE_LEAKAGE': 10, 'JUSTIFIED_BY_TEXT': 10}

## Social-desirability audit (scores not modified)

Mean social_desirability by weight sign:

- positive primary weight: 0.517
- negative primary weight: 0.51
- zero / off-primary: 0.505

By primary dimension:

- `contact_need`: n=80 mean=0.487 pos=0.51 neg=0.5
- `closeness_pace`: n=156 mean=0.519 pos=0.5 neg=0.512
- `initiative`: n=116 mean=0.511 pos=0.506 neg=0.53
- `autonomy`: n=228 mean=0.502 pos=0.5 neg=0.51
- `reassurance_need`: n=104 mean=0.471 pos=0.521 neg=0.429
- `uncertainty_tolerance`: n=108 mean=0.5 pos=0.482 neg=0.51
- `disclosure_pace`: n=140 mean=0.536 pos=0.548 neg=0.552
- `boundary_firmness`: n=208 mean=0.517 pos=0.52 neg=0.485
- `repair_style`: n=108 mean=0.519 pos=0.561 neg=0.5
- `social_energy`: n=92 mean=0.511 pos=0.52 neg=0.5
- `structure_preference`: n=144 mean=0.521 pos=0.52 neg=0.5
- `adaptability`: n=148 mean=0.51 pos=0.515 neg=0.519

Focus dimensions:

- `boundary_firmness`: mean=0.517 pos=0.52 neg=0.485 pos−neg=0.035
- `autonomy`: mean=0.502 pos=0.5 neg=0.51 pos−neg=-0.01
- `reassurance_need`: mean=0.471 pos=0.521 neg=0.429 pos−neg=0.092
- `repair_style`: mean=0.519 pos=0.561 neg=0.5 pos−neg=0.061

Notes:

- Overall positive vs negative primary-weight social_desirability means are nearly identical; weight sign is not being used as a desirability proxy.
- reassurance_need negative-weight options have a slightly lower mean social_desirability than positive-weight options (gap 0.092). Reported, not corrected. The absolute means still sit near 0.50.
- repair_style positive-weight options have a slightly higher mean social_desirability (gap 0.061), consistent with immediate-apology wording, not with treating repair as a health score. Reported, not corrected.
- boundary_firmness and autonomy are not systematically treated as more mature/healthy; dimension means sit near the global 0.50 band.

systematic_bias_detected: **false**

## 30-question sample — CLEAN (10)
### `frequency_v2_q0018` — CLEAN

- primary_dimension: `uncertainty_tolerance`
- Phase 2B quality: MEDIUM
- previous needs_human_review: True
- flag_decision: CLEAR_FLAG
- reason_codes: _none_
- stem: Beklenmedik büyük bir ortak masraf çıktı. Tam tutar ve nasıl çözüleceği henüz belli değil. Akşam ne yaparsın?

- `frequency_v2_q0018_a` weights=`{"uncertainty_tolerance": 2.0}`
  - text: Daha fazla bilgi gelene kadar konuyu bir süre açık bırakabilirim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.25
- `frequency_v2_q0018_b` weights=`{"uncertainty_tolerance": 1.0}`
  - text: Sadece ilk adımı kabaca belirler, geri kalanını netleşince düşünürüm.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25
- `frequency_v2_q0018_c` weights=`{"uncertainty_tolerance": -1.0}`
  - text: O akşam olası seçenekleri konuşup belirsizliği azaltmak isterim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.25
- `frequency_v2_q0018_d` weights=`{"uncertainty_tolerance": -2.0}`
  - text: Rakamları ve olası çözümleri aynı gün mümkün olduğunca netleştirmeden rahat edemem.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.50
### `frequency_v2_q0044` — CLEAN

- primary_dimension: `autonomy`
- Phase 2B quality: HIGH
- previous needs_human_review: False
- flag_decision: None
- reason_codes: _none_
- stem: Yoğun geçen bir ayın ardından nihayet boş bir pazar günün var. İdeal olarak nasıl değerlendirirsin?

- `frequency_v2_q0044_a` weights=`{"autonomy": 2.0, "social_energy": -2.0}`
  - text: Kesinlikle tek başıma. Kitap, oyun veya sadece uzanarak hiç kimseyle (partner dahil) konuşmadan.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0044_b` weights=`{"closeness_pace": 2.0, "autonomy": -1.0}`
  - text: Partnerimle yan yana uzanıp dışarı çıkmadan film maratonu yaparak.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0044_c` weights=`{"social_energy": 2.0, "autonomy": -2.0}`
  - text: Partnerim ve arkadaşlarımla dışarıda güzel bir kahvaltı ve kalabalık bir etkinlik yaparak.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0044_d` weights=`{"autonomy": 1.0, "structure_preference": 1.0}`
  - text: Önce yalnız birkaç saat geçirip şarj olurum, akşamüstü partnerimle buluşurum.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.25
### `frequency_v2_q0046` — CLEAN

- primary_dimension: `uncertainty_tolerance`
- Phase 2B quality: HIGH
- previous needs_human_review: False
- flag_decision: None
- reason_codes: _none_
- stem: Partnerin gün ortasında "Akşam seninle bir konu hakkında konuşmam lazım" diye mesaj attı ve çevrimdışı oldu.

- `frequency_v2_q0046_a` weights=`{"uncertainty_tolerance": -2.0, "reassurance_need": 2.0}`
  - text: Akşama kadar tüm senaryoları (en kötüsü dahil) kafamda kurar, stresten işime odaklanamam.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0046_b` weights=`{"uncertainty_tolerance": 1.0}`
  - text: Ne konuşacağını merak etsem de çok panik yapmam, akşama kadar konuyu rafa kaldırırım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0046_c` weights=`{"uncertainty_tolerance": -2.0, "initiative": 1.0}`
  - text: "Önemli bir şey mi, kötü bir durum mu var?" diye sorup hemen ipucu almaya çalışırım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0046_d` weights=`{"uncertainty_tolerance": 2.0, "autonomy": 1.0}`
  - text: Akşam yemeğinde ne yiyeceğimizi planlamaya devam ederim, o an gelene kadar konu bende yok hükmündedir.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
### `frequency_v2_q0063` — CLEAN

- primary_dimension: `uncertainty_tolerance`
- Phase 2B quality: HIGH
- previous needs_human_review: False
- flag_decision: None
- reason_codes: _none_
- stem: İlişki tanımlı değil. Birkaç aydır görüşüyorsunuz ama “ne olduğumuz” konuşulmadı.

- `frequency_v2_q0063_a` weights=`{"uncertainty_tolerance": -2.0, "reassurance_need": 1.0}`
  - text: Bir noktada netleştirmek isterim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.50
- `frequency_v2_q0063_b` weights=`{"uncertainty_tolerance": 2.0}`
  - text: Tanım olmadan da devam edebilirim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0063_c` weights=`{"uncertainty_tolerance": 1.0, "adaptability": 1.0}`
  - text: Duruma göre karar veririm, acele etmem.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0063_d` weights=`{"uncertainty_tolerance": -1.0, "autonomy": 1.0}`
  - text: Tanım yoksa yavaş yavaş geri çekilirim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
### `frequency_v2_q0070` — CLEAN

- primary_dimension: `autonomy`
- Phase 2B quality: HIGH
- previous needs_human_review: False
- flag_decision: None
- reason_codes: _none_
- stem: Partnerin yoğun bir dönemden geçiyor ve bu akşam yanında olmanın iyi geleceğini söylüyor. Senin de önceden yaptığın kişisel planların var. Ne yaparsın?

- `frequency_v2_q0070_a` weights=`{"autonomy": 2.0}`
  - text: Kendi planımı sürdürür, daha sonra görüşmek için ayrı bir zaman ayarlarım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.50
- `frequency_v2_q0070_b` weights=`{"autonomy": 1.0}`
  - text: Planımın bir kısmını korur, bir kısmını onunla geçiririm.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.50
- `frequency_v2_q0070_c` weights=`{"autonomy": -1.0}`
  - text: Planımın çoğunu değiştirip akşamın büyük bölümünde yanında kalırım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.50
- `frequency_v2_q0070_d` weights=`{"autonomy": -2.0}`
  - text: Kendi planımı tamamen bırakıp akşamı onunla geçiririm.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.25, diagnostic_value=0.75, ambiguity=0.50
### `frequency_v2_q0094` — CLEAN

- primary_dimension: `initiative`
- Phase 2B quality: HIGH
- previous needs_human_review: True
- flag_decision: CLEAR_FLAG
- reason_codes: _none_
- stem: Taşınma, büyük bir harcama veya aileyle ilgili ortak bir kararın zamanı yaklaşıyor. İkiniz de henüz konuşmayı başlatmadınız. Ne yaparsın?

- `frequency_v2_q0094_a` weights=`{"initiative": 2.0}`
  - text: Konuyu ben açar ve bir sonraki adımı netleştirmeye çalışırım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.50
- `frequency_v2_q0094_b` weights=`{"initiative": 1.0}`
  - text: İlk olarak bir zaman veya seçenek öneririm.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.25
- `frequency_v2_q0094_c` weights=`{"initiative": -1.0}`
  - text: Partnerim açarsa konuşmaya katılırım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0094_d` weights=`{"initiative": -2.0}`
  - text: Partnerim somut bir seçenek getirene kadar beklerim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=1.00, ambiguity=0.50
### `frequency_v2_q0099` — CLEAN

- primary_dimension: `initiative`
- Phase 2B quality: HIGH
- previous needs_human_review: False
- flag_decision: None
- reason_codes: _none_
- stem: İlişkinin son haftalarda biraz otomatiğe bağlandığını fark ediyorsun; belirgin bir sorun yok ama tempo düşmüş. Ne yaparsın?

- `frequency_v2_q0099_a` weights=`{"initiative": 2.0}`
  - text: Bunu ben açar, birlikte neyi değiştirebileceğimizi konuşmayı öneririm.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=1.00, ambiguity=0.25
- `frequency_v2_q0099_b` weights=`{"initiative": 1.0}`
  - text: Konuyu büyütmeden yeni bir ortak plan öneririm.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.50
- `frequency_v2_q0099_c` weights=`{"initiative": -1.0}`
  - text: Bir süre daha gözler, kendiliğinden değişip değişmediğine bakarım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0099_d` weights=`{"initiative": -2.0}`
  - text: Partnerim gündeme getirmedikçe ben bir adım atmam.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.50
### `frequency_v2_q0122` — CLEAN

- primary_dimension: `repair_style`
- Phase 2B quality: MEDIUM
- previous needs_human_review: True
- flag_decision: CLEAR_FLAG
- reason_codes: _none_
- stem: Tartışma sırasında karşı tarafın sesi belirgin biçimde yükseldi.

- `frequency_v2_q0122_a` weights=`{"boundary_firmness": 1.0, "repair_style": 1.0}`
  - text: Ben de daha güçlü ve net bir tonda konuşmaya devam ederim.
  - social_desirability=0.50, obviousness=0.75, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0122_b` weights=`{"boundary_firmness": 2.0, "repair_style": -2.0}`
  - text: Konuşmayı durdurur, daha sakin bir zamanda devam etmeyi isterim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0122_c` weights=`{"repair_style": 2.0, "reassurance_need": 1.0}`
  - text: Konu açık kalmasın diye o anda çözmeye devam etmeyi tercih ederim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0122_d` weights=`{"autonomy": 2.0, "repair_style": -2.0}`
  - text: Bir süre fiziksel olarak uzaklaşıp kendi kendime sakinleşirim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25
### `frequency_v2_q0125` — CLEAN

- primary_dimension: `repair_style`
- Phase 2B quality: MEDIUM
- previous needs_human_review: True
- flag_decision: CLEAR_FLAG
- reason_codes: _none_
- stem: Tartışma bitti ama senin içinde hâlâ kapanmamış bir şey var.

- `frequency_v2_q0125_a` weights=`{"repair_style": 2.0, "reassurance_need": 1.0}`
  - text: Aynı gün yeniden açarım; içimde kalması beni daha çok rahatsız eder.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25
- `frequency_v2_q0125_b` weights=`{"structure_preference": 1.0, "repair_style": 1.0}`
  - text: Ertesi gün sakin bir zamanda konuşmak için zaman belirlerim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0125_c` weights=`{"repair_style": -2.0, "adaptability": 1.0}`
  - text: Günlük davranışlarımız normale dönerse ayrıca konuşmadan da geçebilirim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0125_d` weights=`{"initiative": -1.0, "repair_style": -1.0}`
  - text: Karşı taraf yeniden açarsa konuşurum; ben başlatmam.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
### `frequency_v2_q0129` — CLEAN

- primary_dimension: `repair_style`
- Phase 2B quality: MEDIUM
- previous needs_human_review: True
- flag_decision: CLEAR_FLAG
- reason_codes: _none_
- stem: Partnerin senin için önemli bir işi unuttu ve bu sana zaman kaybettirdi.

- `frequency_v2_q0129_a` weights=`{"boundary_firmness": 1.0, "repair_style": 1.0}`
  - text: Etkisini o anda açıkça söylerim.
  - social_desirability=0.75, obviousness=0.75, behavioral_plausibility=0.75, self_presentation_risk=0.75, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0129_b` weights=`{"repair_style": -1.0, "structure_preference": 1.0}`
  - text: Önce sorunu çözer, daha sakin bir anda konuşurum.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0129_c` weights=`{"structure_preference": 2.0, "repair_style": -1.0}`
  - text: Bir daha olmaması için birlikte hatırlatma/sistem kurmayı öneririm.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25
- `frequency_v2_q0129_d` weights=`{"uncertainty_tolerance": 1.0, "repair_style": -2.0}`
  - text: Tek seferlikse fazla büyütmeden alternatifimi bulurum.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
## 30-question sample — ACCEPTABLE_COMPLEXITY (10)
### `frequency_v2_q0001` — ACCEPTABLE_COMPLEXITY

- primary_dimension: `initiative`
- Phase 2B quality: LOW
- previous needs_human_review: True
- flag_decision: CLEAR_FLAG
- reason_codes: _none_
- stem: Harika geçen bir ikinci buluşmanın ardından ertesi gün karşı taraftan hiç ses çıkmadı. Sana hangisi daha doğal gelir?

- `frequency_v2_q0001_a` weights=`{"initiative": 2.0, "contact_need": 1.0}`
  - text: İlgisini çekecek komik/ufak bir detay bulup sohbete yön veririm.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0001_b` weights=`{"initiative": -2.0, "uncertainty_tolerance": 1.0}`
  - text: Kendi akışımda kalırım, ilk adımı onun atması bana daha doğru gelir.
  - social_desirability=0.75, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=1.00, ambiguity=0.50
- `frequency_v2_q0001_c` weights=`{"initiative": 1.0, "disclosure_pace": 1.0}`
  - text: Dünkü buluşmanın keyifli olduğunu belirten net, kısa bir mesaj atarım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25
- `frequency_v2_q0001_d` weights=`{"uncertainty_tolerance": 2.0, "reassurance_need": -1.0}`
  - text: Yoğun olabileceğini varsayıp çok analiz etmeden kendi işlerime odaklanırım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.00, ambiguity=0.25
### `frequency_v2_q0004` — ACCEPTABLE_COMPLEXITY

- primary_dimension: `social_energy`
- Phase 2B quality: MEDIUM
- previous needs_human_review: True
- flag_decision: CLEAR_FLAG
- reason_codes: _none_
- stem: Birlikte kalabalık ve pek az kişiyi tanıdığın bir ev partisine gittiniz. Gece boyunca genelde nasıl davranırsın?

- `frequency_v2_q0004_a` weights=`{"social_energy": -1.0, "adaptability": 2.0}`
  - text: Çoğunlukla partnerimin yanında kalır, onun sohbetlerine dahil olurum.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0004_b` weights=`{"social_energy": 2.0, "autonomy": 1.0}`
  - text: Gidip kendi başıma yeni insanlarla tanışır ve kendi sohbetimi kurarım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=1.00, ambiguity=0.50
- `frequency_v2_q0004_c` weights=`{"autonomy": 2.0, "contact_need": -1.0}`
  - text: Göz temasıyla arada bir birbirimizi yoklar ama bağımsız takılırız.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.00, ambiguity=0.75
- `frequency_v2_q0004_d` weights=`{"social_energy": -2.0}`
  - text: Bu tarz ortamlar beni yorduğu için erken kalkmak için uygun zamanı kollarım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.25, diagnostic_value=1.00, ambiguity=0.25
### `frequency_v2_q0005` — ACCEPTABLE_COMPLEXITY

- primary_dimension: `uncertainty_tolerance`
- Phase 2B quality: LOW
- previous needs_human_review: True
- flag_decision: CLEAR_FLAG
- reason_codes: _none_
- stem: Birlikte izlediğiniz bir filmdeki ahlaki bir ikilem üzerine tamamen zıt görüşlere sahipsiniz. Tartışma uzadı, ne yaparsın?

- `frequency_v2_q0005_a` weights=`{"boundary_firmness": 2.0}`
  - text: Fikrinin arkasındaki mantığı sonuna kadar anlamaya ve kendi fikrimi savunmaya devam ederim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25
- `frequency_v2_q0005_b` weights=`{"boundary_firmness": -2.0, "adaptability": 1.0}`
  - text: Farklı düşünmemizi ilginç bulur, konuyu uzatmadan "sen de haklı olabilirsin" derim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25
- `frequency_v2_q0005_c` weights=`{"uncertainty_tolerance": -1.0, "repair_style": -1.0}`
  - text: Tartışmanın gerginleşme ihtimaline karşı konuyu şakaya vurup kapatırım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.25
- `frequency_v2_q0005_d` weights=`{"closeness_pace": 1.0, "repair_style": 1.0}`
  - text: Ne hissettiğini anlamaya odaklanır, fikrim zıt olsa da onun duygusunu onaylarım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25
### `frequency_v2_q0006` — ACCEPTABLE_COMPLEXITY

- primary_dimension: `uncertainty_tolerance`
- Phase 2B quality: LOW
- previous needs_human_review: True
- flag_decision: CLEAR_FLAG
- reason_codes: _none_
- stem: İki aydır çok iyi giden bir görüşme sürecindesiniz ama "biz neyiz?" konuşması hiç yapılmadı. İçsel durumun ne olur?

- `frequency_v2_q0006_a` weights=`{"uncertainty_tolerance": -2.0, "initiative": 2.0}`
  - text: İşlerin nereye gittiğini bilmemek beni huzursuz eder, konuyu bir noktada ben açarım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25
- `frequency_v2_q0006_b` weights=`{"uncertainty_tolerance": 2.0, "closeness_pace": -1.0}`
  - text: İsim koymaya gerek duymam, anı yaşar ve akışın getireceği yere güvenirim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0006_c` weights=`{"reassurance_need": -1.0, "uncertainty_tolerance": 1.0}`
  - text: Benzer hissettiğimizi eylemlerinden görüyorsam konuşulmaması beni rahatsız etmez.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25
- `frequency_v2_q0006_d` weights=`{"initiative": -2.0, "boundary_firmness": -1.0}`
  - text: O bu konuyu açana kadar beklerim, üstüne gitmek istemem.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.50
### `frequency_v2_q0007` — ACCEPTABLE_COMPLEXITY

- primary_dimension: `autonomy`
- Phase 2B quality: MEDIUM
- previous needs_human_review: True
- flag_decision: CLEAR_FLAG
- reason_codes: _none_
- stem: Hafta sonunu birlikte geçirmeyi beklerken, partnerin "Bu hafta sonu sadece evde tek başıma kalıp dinlenmeye ihtiyacım var" dedi. Nasıl karşılarsın?

- `frequency_v2_q0007_a` weights=`{"reassurance_need": 2.0, "autonomy": -2.0}`
  - text: Biraz bozulurum veya aramızda bir sorun olup olmadığını merak ederim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0007_b` weights=`{"autonomy": 2.0, "reassurance_need": -1.0}`
  - text: Anlayışla karşılarım, benim de yalnız kalıp kendi işlerime bakacağım bir zaman doğmuş olur.
  - social_desirability=0.75, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=1.00, ambiguity=0.25
- `frequency_v2_q0007_c` weights=`{"contact_need": 2.0, "autonomy": -1.0}`
  - text: Dinlenmesi için onu yalnız bırakırım ama gün içinde mesajlaşarak temasta kalmak isterim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.75
- `frequency_v2_q0007_d` weights=`{"closeness_pace": 2.0, "autonomy": -2.0}`
  - text: "İstersen sana geleyim, sessizce kendi köşelerimizde dinleniriz" teklifinde bulunurum.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
### `frequency_v2_q0008` — ACCEPTABLE_COMPLEXITY

- primary_dimension: `disclosure_pace`
- Phase 2B quality: HIGH
- previous needs_human_review: True
- flag_decision: CLEAR_FLAG
- reason_codes: _none_
- stem: Partnerin bir davranışını yapıcı biçimde eleştiriyor ve “Sen bunu nasıl görüyorsun?” diye soruyor. Ne yaparsın?

- `frequency_v2_q0008_a` weights=`{"disclosure_pace": 2.0}`
  - text: O anda ne hissettiğimi ve ne düşündüğümü açıkça anlatırım.
  - social_desirability=0.75, obviousness=0.75, behavioral_plausibility=0.75, self_presentation_risk=0.75, diagnostic_value=1.00, ambiguity=0.25
- `frequency_v2_q0008_b` weights=`{"disclosure_pace": 1.0}`
  - text: Kısa bir cevap verir, ayrıntıyı biraz sonra konuşurum.
  - social_desirability=0.75, obviousness=0.75, behavioral_plausibility=0.75, self_presentation_risk=0.75, diagnostic_value=0.75, ambiguity=0.25
- `frequency_v2_q0008_c` weights=`{"disclosure_pace": -1.0}`
  - text: Önce düşünmek istediğimi söyler, toparlanınca konuya dönerim.
  - social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.75, self_presentation_risk=0.25, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0008_d` weights=`{"disclosure_pace": -2.0}`
  - text: İlk tepkimi kendime saklar, ancak gerekirse daha sonra açarım.
  - social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.75, self_presentation_risk=0.25, diagnostic_value=0.75, ambiguity=0.50
### `frequency_v2_q0009` — ACCEPTABLE_COMPLEXITY

- primary_dimension: `closeness_pace`
- Phase 2B quality: LOW
- previous needs_human_review: True
- flag_decision: CLEAR_FLAG
- reason_codes: _none_
- stem: Henüz 3-4 haftadır görüştüğün kişi, seni en yakın arkadaş grubuyla bir akşam yemeğine davet etti. Yaklaşımın ne olur?

- `frequency_v2_q0009_a` weights=`{"closeness_pace": 2.0, "social_energy": 1.0}`
  - text: Memnuniyetle katılırım, onun çevresini tanımak süreci hızlandırır.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.25
- `frequency_v2_q0009_b` weights=`{"disclosure_pace": -2.0, "closeness_pace": -2.0}`
  - text: Çok erken olduğunu düşünüp nazikçe reddederim, önce baş başa birbirimizi tanımalıyız.
  - social_desirability=0.75, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.25
- `frequency_v2_q0009_c` weights=`{"adaptability": 2.0, "boundary_firmness": -1.0}`
  - text: Biraz gerilsem de onu kırmamak için giderim, ama çok ön planda olmam.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.75
- `frequency_v2_q0009_d` weights=`{"disclosure_pace": -1.0, "boundary_firmness": 1.0}`
  - text: Giderim ama sadece gözlemci olurum, kendi sınırlarımı hemen açmam.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.75
### `frequency_v2_q0010` — ACCEPTABLE_COMPLEXITY

- primary_dimension: `contact_need`
- Phase 2B quality: MEDIUM
- previous needs_human_review: True
- flag_decision: CLEAR_FLAG
- reason_codes: _none_
- stem: İkinizin de çok yoğun çalıştığı bir mesai günündesiniz. İletişim dinamiğinizin nasıl olmasını beklersin?

- `frequency_v2_q0010_a` weights=`{"contact_need": -2.0, "autonomy": 1.0}`
  - text: Sadece çok acil durumlarda konuşalım, akşam detaylıca sohbet ederiz.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0010_b` weights=`{"contact_need": 2.0, "adaptability": -1.0}`
  - text: Fırsat buldukça kısa mesajlar veya komik bir şeyler atarak bağda kalmak isterim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=1.00, ambiguity=0.25
- `frequency_v2_q0010_c` weights=`{"adaptability": 2.0, "initiative": -1.0}`
  - text: O ne kadar yazıyorsa ben de o kadar yazarım, onun temposuna uyarım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.00, ambiguity=0.50
- `frequency_v2_q0010_d` weights=`{"structure_preference": 2.0, "contact_need": 1.0}`
  - text: Öğle arası veya belli bir saatte kısa bir telefon görüşmesi yapmayı tercih ederim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
### `frequency_v2_q0011` — ACCEPTABLE_COMPLEXITY

- primary_dimension: `adaptability`
- Phase 2B quality: LOW
- previous needs_human_review: True
- flag_decision: CLEAR_FLAG
- reason_codes: _none_
- stem: Akşam şık bir restorana gitmek üzere hazırlandın ama partnerin son dakika arayıp "Çok yorgunum, evde film ve pizza yapsak uyar mı?" dedi.

- `frequency_v2_q0011_a` weights=`{"structure_preference": -2.0, "adaptability": 2.0}`
  - text: Anında modumu değiştiririm, benim için ne yaptığımız değil birlikte olmamız önemlidir.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.25
- `frequency_v2_q0011_b` weights=`{"structure_preference": 2.0, "uncertainty_tolerance": -1.0}`
  - text: Kabul ederim ama hevesim kırılır, yapılan planlara sadık kalınmasına önem veririm.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.75
- `frequency_v2_q0011_c` weights=`{"boundary_firmness": -1.0}`
  - text: Evde vakit geçirmek uyar, yorgunsa zorlamanın anlamı yok, dinlenmesi daha mühim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0011_d` weights=`{"autonomy": 2.0, "boundary_firmness": 1.0}`
  - text: Onu dinlenmeye bırakıp kendi başıma veya arkadaşlarımla dışarı çıkma planı yaparım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.00, ambiguity=0.25
### `frequency_v2_q0012` — ACCEPTABLE_COMPLEXITY

- primary_dimension: `autonomy`
- Phase 2B quality: MEDIUM
- previous needs_human_review: True
- flag_decision: CLEAR_FLAG
- reason_codes: _none_
- stem: Evde birlikte vakit geçirirken genelde fiziksel mesafeniz nasıl olmalıdır?

- `frequency_v2_q0012_a` weights=`{"closeness_pace": 2.0, "autonomy": -2.0}`
  - text: Sürekli yan yana veya temas halinde olmak, aynı odada aynı şeyi yapmak bana iyi hissettirir.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0012_b` weights=`{"autonomy": 1.0, "adaptability": -1.0}`
  - text: Aynı odada olabiliriz ama herkes kendi kulaklığıyla kendi işine/hobisine bakmalı.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.75
- `frequency_v2_q0012_c` weights=`{"autonomy": 2.0, "closeness_pace": -1.0}`
  - text: Evin farklı odalarında zaman geçirmekten, ara sıra mutfakta karşılaşmaktan hoşlanırım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0012_d` weights=`{"boundary_firmness": 2.0, "autonomy": 2.0}`
  - text: Ortak izlenen bir şey olmadığı sürece sınırlar olmalı, sürekli bir arada olmak beni boğar.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
## 30-question sample — REAL_REVIEW_REQUIRED (10)
### `frequency_v2_q0002` — REAL_REVIEW_REQUIRED

- primary_dimension: `structure_preference`
- Phase 2B quality: MEDIUM
- previous needs_human_review: True
- flag_decision: KEEP_FLAG
- reason_codes: SD_DOMINANCE, SELF_PRESENTATION_HEAVY
- stem: Cumartesi sabahı uyandın, gün için hiçbir planınız yok. Partnerin "Bugün kafamıza göre takılalım, anlık karar veririz" dedi. Ne hissedersin?

- `frequency_v2_q0002_a` weights=`{"structure_preference": -2.0, "adaptability": 1.0}`
  - text: Harika, en sevdiğim şey anın tadını çıkarmaktır.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.25, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0002_b` weights=`{"structure_preference": 2.0}`
  - text: Biraz gerilirim, günün heba olmaması için en azından bir taslak olmasını tercih ederim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.25, diagnostic_value=1.00, ambiguity=0.25
- `frequency_v2_q0002_c` weights=`{"autonomy": 2.0, "structure_preference": -1.0}`
  - text: Uygunum ama kendi yapmam gereken birkaç işi halledip ona sonradan katılırım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.25, diagnostic_value=0.50, ambiguity=0.75
- `frequency_v2_q0002_d` weights=`{"adaptability": 2.0, "initiative": -1.0}`
  - text: Bana uyar, onun enerjisi neye yönelikse ona eşlik etmekten keyif alırım.
  - social_desirability=1.00, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.75, diagnostic_value=0.25, ambiguity=0.25
### `frequency_v2_q0015` — REAL_REVIEW_REQUIRED

- primary_dimension: `repair_style`
- Phase 2B quality: MEDIUM
- previous needs_human_review: True
- flag_decision: KEEP_FLAG
- reason_codes: SD_DOMINANCE, SELF_PRESENTATION_HEAVY
- stem: Stresli bir anında partnerine gereksiz yere sert çıkıştın. 10 dakika sonra durumu fark ettin.

- `frequency_v2_q0015_a` weights=`{"reassurance_need": 1.0, "repair_style": 2.0}`
  - text: Hemen yanına gidip sarılarak, duygusal bir şekilde özür dilerim.
  - social_desirability=1.00, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.75, diagnostic_value=0.75, ambiguity=0.50
- `frequency_v2_q0015_b` weights=`{"boundary_firmness": 1.0, "repair_style": 1.0}`
  - text: Stresimin kaynağını rasyonel bir dille açıklayarak durumu telafi edecek bir konuşma yaparım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0015_c` weights=`{"uncertainty_tolerance": 1.0, "disclosure_pace": -1.0}`
  - text: Olayı çok büyütmeden, normal bir şey söyleyerek (örn. "çay içer misin?") buzları eritirim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25
- `frequency_v2_q0015_d` weights=`{"autonomy": 1.0, "repair_style": -1.0}`
  - text: Bir süre daha kendi alanımda kalır, ikimizin de tamamen sakinleştiğinden emin olunca konuyu açarım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.50
### `frequency_v2_q0020` — REAL_REVIEW_REQUIRED

- primary_dimension: `uncertainty_tolerance`
- Phase 2B quality: LOW
- previous needs_human_review: True
- flag_decision: KEEP_FLAG
- reason_codes: PRIMARY_AXIS_CONFUSION, LOW_DIAGNOSTIC_CONTRAST
- stem: Partnerin bir şeye bariz şekilde canı sıkkın ama sana "bir şey yok, iyiyim" diyor.

- `frequency_v2_q0020_a` weights=`{"reassurance_need": 2.0, "boundary_firmness": -1.0}`
  - text: "Bana anlatabilirsin" diye ısrar eder, aradaki o soğukluğu hemen kırmak isterim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0020_b` weights=`{"autonomy": 1.0, "boundary_firmness": 2.0}`
  - text: Gerçekten anlatmak isteyene kadar bekler, tamamen kendi alanına saygı gösteririm.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.50
- `frequency_v2_q0020_c` weights=`{"contact_need": -1.0}`
  - text: O anlatmayana kadar ben de günlük rutinimde hiçbir şey yokmuş gibi davranmaya devam ederim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0020_d` weights=`{"closeness_pace": 1.0, "disclosure_pace": -1.0}`
  - text: Konuşmaya zorlamam ama fiziksel bir temasla (sarılarak) yanında olduğumu hissettiririm.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.00, ambiguity=0.75
### `frequency_v2_q0026` — REAL_REVIEW_REQUIRED

- primary_dimension: `uncertainty_tolerance`
- Phase 2B quality: LOW
- previous needs_human_review: True
- flag_decision: KEEP_FLAG
- reason_codes: PRIMARY_AXIS_CONFUSION, LOW_DIAGNOSTIC_CONTRAST
- stem: Temel bir inanç veya hayata bakış açısı konusunda partnerinle tamamen zıt olduğunuzu fark ettiniz.

- `frequency_v2_q0026_a` weights=`{"initiative": 1.0}`
  - text: Bu konuyu derinlemesine, belki saatlerce tartışarak ortak bir zemin bulmaya çalışırım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0026_b` weights=`{"boundary_firmness": 2.0, "autonomy": 1.0}`
  - text: Herkesin kendi gerçeği olduğunu kabul eder, konuyu ilişkimizin merkezinden uzak tutarım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0026_c` weights=`{"disclosure_pace": -1.0}`
  - text: Fikirlerini değiştirmeye çalışmam ama onun bakış açısını entelektüel bir merakla deşerim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.75
- `frequency_v2_q0026_d` weights=`{"adaptability": 2.0, "boundary_firmness": -2.0}`
  - text: Bu zıtlığı bir zenginlik olarak görür, onun düşünce yapısına uyumlanabilip uyumlanamayacağıma bakarım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
### `frequency_v2_q0030` — REAL_REVIEW_REQUIRED

- primary_dimension: `uncertainty_tolerance`
- Phase 2B quality: LOW
- previous needs_human_review: True
- flag_decision: KEEP_FLAG
- reason_codes: PRIMARY_AXIS_CONFUSION, LOW_DIAGNOSTIC_CONTRAST
- stem: Partnerinin geçmişiyle ilgili zarar verici olmayan ama senin yeni öğrendiğin önemli bir detayı (örn: eski mesleği) gizlediğini fark ettin.

- `frequency_v2_q0030_a` weights=`{"disclosure_pace": 2.0, "boundary_firmness": 2.0}`
  - text: "Benden bunu neden sakladın?" diyerek dürüstlük ve güven ekseninde sert bir konuşma yaparım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25
- `frequency_v2_q0030_b` weights=`{"disclosure_pace": -2.0, "autonomy": 1.0}`
  - text: Herkesin hazır hissettiği zaman anlatma hakkı olduğunu düşünür, pek üstünde durmam.
  - social_desirability=0.25, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.25
- `frequency_v2_q0030_c` weights=`{"adaptability": 1.0}`
  - text: Neden saklama ihtiyacı duyduğunu anlamak için yargılamadan dinlemeye odaklanırım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.50
- `frequency_v2_q0030_d` weights=`{"reassurance_need": 1.0, "initiative": -1.0}`
  - text: İçten içe kırılırım ama konuyu açmasını onun inisiyatifine bırakırım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.75
### `frequency_v2_q0035` — REAL_REVIEW_REQUIRED

- primary_dimension: `disclosure_pace`
- Phase 2B quality: LOW
- previous needs_human_review: True
- flag_decision: KEEP_FLAG
- reason_codes: PRIMARY_AXIS_CONFUSION, LOW_DIAGNOSTIC_CONTRAST
- stem: Hayatında her şeyin üst üste geldiği, inanılmaz stresli bir dönemdesin. İlişkine nasıl yansır?

- `frequency_v2_q0035_a` weights=`{"contact_need": 2.0, "reassurance_need": 1.0}`
  - text: Stresimi partnerimle sürekli konuşarak, onun desteğine daha çok yaslanarak atlatırım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0035_b` weights=`{"autonomy": 2.0}`
  - text: Kendi içime kapanır, sorunları çözene kadar biraz mesafeli ve sessiz kalırım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.00, ambiguity=0.25
- `frequency_v2_q0035_c` weights=`{"uncertainty_tolerance": 1.0, "structure_preference": 1.0}`
  - text: Günlük rutinimize hiçbir şey yokmuş gibi devam etmeye, ilişkiyi bir kaçış alanı olarak görmeye çalışırım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.00, ambiguity=0.25
- `frequency_v2_q0035_d` weights=`{"boundary_firmness": -2.0, "adaptability": 2.0}`
  - text: Stresim onu da etkilemesin diye aşırı dikkatli davranır, kendi ihtiyaçlarımı geri plana atarım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
### `frequency_v2_q0049` — REAL_REVIEW_REQUIRED

- primary_dimension: `reassurance_need`
- Phase 2B quality: LOW
- previous needs_human_review: True
- flag_decision: KEEP_FLAG
- reason_codes: SD_DOMINANCE, OBVIOUS_TEST_ANSWER, SELF_PRESENTATION_HEAVY
- stem: Partnerinin sosyal medyada eski bir flörtünün fotoğraflarını beğendiğini gördün. Bu sende nasıl bir içsel tepki yaratır?

- `frequency_v2_q0049_a` weights=`{"reassurance_need": 2.0, "boundary_firmness": 1.0}`
  - text: Ciddi bir özgüven/güven sarsıntısı yaşar, konuyu hemen, biraz da suçlayıcı bir tonda açarım.
  - social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0049_b` weights=`{"reassurance_need": -2.0, "autonomy": 1.0}`
  - text: Üstünde durmam. Dijital hareketleri yakından takip eden veya kıskançlık yapan biri değilimdir.
  - social_desirability=0.25, obviousness=0.25, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25
- `frequency_v2_q0049_c` weights=`{"disclosure_pace": -1.0}`
  - text: Rahatsız olurum ama olayı büyütmemek için kendimi tutar, dolaylı yoldan tavır yapabilirim.
  - social_desirability=0.00, obviousness=0.25, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.75
- `frequency_v2_q0049_d` weights=`{"boundary_firmness": 1.0, "disclosure_pace": 1.0}`
  - text: Bunu açık bir iletişim fırsatı görüp, rahatsızlığımı suçlamadan ama net bir şekilde ifade ederim.
  - social_desirability=0.75, obviousness=1.00, behavioral_plausibility=0.75, self_presentation_risk=0.75, diagnostic_value=0.50, ambiguity=0.75
### `frequency_v2_q0081` — REAL_REVIEW_REQUIRED

- primary_dimension: `closeness_pace`
- Phase 2B quality: LOW
- previous needs_human_review: True
- flag_decision: KEEP_FLAG
- reason_codes: CULTURAL_DEPENDENCE
- stem: Partnerin ailesi / yakın çevresiyle tanışma konusu açıldı.

- `frequency_v2_q0081_a` weights=`{"closeness_pace": 2.0}`
  - text: Erken olmasını isterim.
  - social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.25, self_presentation_risk=0.25, diagnostic_value=0.50, ambiguity=0.50
- `frequency_v2_q0081_b` weights=`{"uncertainty_tolerance": 1.0}`
  - text: Zamanı gelince olur.
  - social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.25, self_presentation_risk=0.25, diagnostic_value=0.25, ambiguity=0.50
- `frequency_v2_q0081_c` weights=`{"boundary_firmness": 1.0, "autonomy": 1.0}`
  - text: Ben hazır olunca olur.
  - social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.25, self_presentation_risk=0.25, diagnostic_value=0.25, ambiguity=0.50
- `frequency_v2_q0081_d` weights=`{"closeness_pace": -1.0, "adaptability": 1.0}`
  - text: Çok acele etmeden, doğal aksın.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=1.00, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.25
### `frequency_v2_q0097` — REAL_REVIEW_REQUIRED

- primary_dimension: `repair_style`
- Phase 2B quality: LOW
- previous needs_human_review: True
- flag_decision: KEEP_FLAG
- reason_codes: SD_DOMINANCE, SELF_PRESENTATION_HEAVY
- stem: Bir konuda özür dilemen gereken bir durum oluştu.

- `frequency_v2_q0097_a` weights=`{"repair_style": 1.0, "initiative": 1.0}`
  - text: Hemen ve net özür dilerim.
  - social_desirability=0.75, obviousness=0.50, behavioral_plausibility=0.25, self_presentation_risk=0.75, diagnostic_value=0.75, ambiguity=0.75
- `frequency_v2_q0097_b` weights=`{"disclosure_pace": 1.0, "repair_style": 1.0}`
  - text: Durumu açıklayıp özür eklerim.
  - social_desirability=0.75, obviousness=0.50, behavioral_plausibility=1.00, self_presentation_risk=0.50, diagnostic_value=1.00, ambiguity=0.25
- `frequency_v2_q0097_c` weights=`{"repair_style": 0.0, "adaptability": 1.0}`
  - text: Davranışla telafi ederim.
  - social_desirability=0.25, obviousness=0.25, behavioral_plausibility=0.25, self_presentation_risk=0.25, diagnostic_value=0.25, ambiguity=0.50
- `frequency_v2_q0097_d` weights=`{"repair_style": -2.0, "uncertainty_tolerance": 1.0}`
  - text: Zamanla unutulur diye beklerim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=1.00, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25
### `frequency_v2_q0107` — REAL_REVIEW_REQUIRED

- primary_dimension: `autonomy`
- Phase 2B quality: LOW
- previous needs_human_review: True
- flag_decision: KEEP_FLAG
- reason_codes: HIGH_AMBIGUITY
- stem: Birlikte geçirmeyi düşündüğün hafta sonu için partnerin “Bu hafta sonu biraz yalnız kalmaya ihtiyacım var” dedi.

- `frequency_v2_q0107_a` weights=`{"autonomy": 2.0, "reassurance_need": -1.0}`
  - text: Kendi planlarımı yaparım; bu alanı doğal karşılarım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=1.00, ambiguity=0.25
- `frequency_v2_q0107_b` weights=`{"contact_need": 1.0, "adaptability": 1.0}`
  - text: Alan tanırım ama gün içinde küçük bir temasımızın olmasını isterim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=1.00
- `frequency_v2_q0107_c` weights=`{"reassurance_need": 2.0, "uncertainty_tolerance": -1.0}`
  - text: Aramızda bir sorun olup olmadığını netleştirmek isterim.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.00, ambiguity=0.25
- `frequency_v2_q0107_d` weights=`{"closeness_pace": 1.0, "autonomy": -1.0}`
  - text: İsterse aynı evde/ortamda herkesin kendi halinde olabileceği bir seçenek sunarım.
  - social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.25

## Safety

- Phase 2B proposal scores not modified
- Dormant pool not modified
- DROP options not scored
- `review_status=reviewed` not set
- V2 remains dormant
- No V1 / Firebase / matching / Persona / Discover / C2 / locale-routing change

FREQUENCY V2 PHASE 2C EVIDENCE TRIAGE COMPLETE — NO VALUES APPLIED — V2 STILL DORMANT
