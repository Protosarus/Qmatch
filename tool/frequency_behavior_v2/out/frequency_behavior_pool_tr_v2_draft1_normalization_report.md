# Frequency V2 426-pool normalization report

Source: `docs/qmatch_frequency_v2_426_unique_source_pool_tr.txt`
schema_version: `qmatch_frequency_behavior_pool_v2`
pool_version: `frequency_behavior_pool_tr_v2_draft1`
scoring_policy_version: `frequency_behavior_12d_signed_evidence_v2`
Status: **draft_not_runtime** — not selected by live Frequency routing.

## Counts

- Parsed FQ blocks: 426
- Parsed questions in pool: 426
- Parsed options: 1704
- Exact duplicate normalized prompts: 0
- Exact duplicate option texts within an item: 0
- Exact duplicate option texts across items: 132
- Likely semantic near-duplicate clusters (sim≥0.62): 22
- Items in those clusters: 49
- Safe alias applications (label occurrences): 805
- Items with processing_style (NOT mapped): 140
- Unknown dimension labels: {'conflict_approach': 2, 'baseline': 1, 'reciprocity': 1, 'trust': 1}
- High social-desirability heuristic flags: 32
- Rewrite / manual-cleanup candidates: 39
- Malformed/incomplete parse: 0

## Alias policy

Normalized only after label match:

- `initiative_tendency` → `initiative`
- `autonomy_need` → `autonomy`
- `boundary_style` → `boundary_firmness`
- `rhythm_adaptation` → `adaptability`

`processing_style` is **never** mapped to `repair_style`.

## processing_style items

- `frequency_v2_q0003` (FQ003 / SOURCE_01) primary_raw=['processing_style']
- `frequency_v2_q0005` (FQ005 / SOURCE_01) primary_raw=['boundary_style']
- `frequency_v2_q0008` (FQ008 / SOURCE_01) primary_raw=['processing_style']
- `frequency_v2_q0011` (FQ011 / SOURCE_01) primary_raw=['structure_preference']
- `frequency_v2_q0013` (FQ013 / SOURCE_01) primary_raw=['disclosure_pace']
- `frequency_v2_q0015` (FQ015 / SOURCE_01) primary_raw=['processing_style']
- `frequency_v2_q0016` (FQ016 / SOURCE_01) primary_raw=['boundary_style']
- `frequency_v2_q0018` (FQ018 / SOURCE_01) primary_raw=['uncertainty_tolerance']
- `frequency_v2_q0020` (FQ020 / SOURCE_01) primary_raw=['boundary_style']
- `frequency_v2_q0023` (FQ023 / SOURCE_01) primary_raw=['closeness_pace']
- `frequency_v2_q0025` (FQ025 / SOURCE_01) primary_raw=['uncertainty_tolerance']
- `frequency_v2_q0026` (FQ026 / SOURCE_01) primary_raw=['processing_style']
- `frequency_v2_q0027` (FQ027 / SOURCE_01) primary_raw=['reassurance_need']
- `frequency_v2_q0029` (FQ029 / SOURCE_01) primary_raw=['processing_style']
- `frequency_v2_q0030` (FQ030 / SOURCE_01) primary_raw=['disclosure_pace']
- `frequency_v2_q0031` (FQ031 / SOURCE_01) primary_raw=['rhythm_adaptation']
- `frequency_v2_q0033` (FQ033 / SOURCE_01) primary_raw=['closeness_pace']
- `frequency_v2_q0035` (FQ035 / SOURCE_01) primary_raw=['contact_need']
- `frequency_v2_q0036` (FQ036 / SOURCE_01) primary_raw=['reassurance_need']
- `frequency_v2_q0037` (FQ037 / SOURCE_01) primary_raw=['boundary_style']
- `frequency_v2_q0038` (FQ038 / SOURCE_01) primary_raw=['structure_preference']
- `frequency_v2_q0043` (FQ043 / SOURCE_01) primary_raw=['processing_style']
- `frequency_v2_q0046` (FQ046 / SOURCE_01) primary_raw=['uncertainty_tolerance']
- `frequency_v2_q0047` (FQ047 / SOURCE_01) primary_raw=['conflict_approach']
- `frequency_v2_q0048` (FQ048 / SOURCE_01) primary_raw=['rhythm_adaptation']
- `frequency_v2_q0049` (FQ049 / SOURCE_01) primary_raw=['reassurance_need']
- `frequency_v2_q0152` (FQ152 / SOURCE_04) primary_raw=['uncertainty_tolerance']
- `frequency_v2_q0154` (FQ154 / SOURCE_04) primary_raw=['initiative_tendency']
- `frequency_v2_q0155` (FQ155 / SOURCE_04) primary_raw=['autonomy_need']
- `frequency_v2_q0158` (FQ158 / SOURCE_04) primary_raw=['boundary_style']
- `frequency_v2_q0160` (FQ160 / SOURCE_04) primary_raw=['closeness_pace']
- `frequency_v2_q0162` (FQ162 / SOURCE_04) primary_raw=['reassurance_need']
- `frequency_v2_q0163` (FQ163 / SOURCE_04) primary_raw=['processing_style']
- `frequency_v2_q0164` (FQ164 / SOURCE_04) primary_raw=['uncertainty_tolerance']
- `frequency_v2_q0166` (FQ166 / SOURCE_04) primary_raw=['processing_style']
- `frequency_v2_q0167` (FQ167 / SOURCE_04) primary_raw=['reassurance_need']
- `frequency_v2_q0168` (FQ168 / SOURCE_04) primary_raw=['rhythm_adaptation']
- `frequency_v2_q0169` (FQ169 / SOURCE_04) primary_raw=['contact_need']
- `frequency_v2_q0170` (FQ170 / SOURCE_04) primary_raw=['boundary_style']
- `frequency_v2_q0171` (FQ171 / SOURCE_04) primary_raw=['reassurance_need']
- `frequency_v2_q0172` (FQ172 / SOURCE_04) primary_raw=['structure_preference']
- `frequency_v2_q0173` (FQ173 / SOURCE_04) primary_raw=['uncertainty_tolerance']
- `frequency_v2_q0174` (FQ174 / SOURCE_04) primary_raw=['boundary_style']
- `frequency_v2_q0176` (FQ176 / SOURCE_04) primary_raw=['rhythm_adaptation']
- `frequency_v2_q0177` (FQ177 / SOURCE_04) primary_raw=['disclosure_pace']
- `frequency_v2_q0178` (FQ178 / SOURCE_04) primary_raw=['contact_need']
- `frequency_v2_q0180` (FQ180 / SOURCE_04) primary_raw=['processing_style']
- `frequency_v2_q0181` (FQ181 / SOURCE_04) primary_raw=['closeness_pace']
- `frequency_v2_q0182` (FQ182 / SOURCE_04) primary_raw=['structure_preference']
- `frequency_v2_q0183` (FQ183 / SOURCE_04) primary_raw=['processing_style']
- `frequency_v2_q0184` (FQ184 / SOURCE_04) primary_raw=['autonomy_need']
- `frequency_v2_q0185` (FQ185 / SOURCE_04) primary_raw=['boundary_style']
- `frequency_v2_q0186` (FQ186 / SOURCE_04) primary_raw=['processing_style']
- `frequency_v2_q0187` (FQ187 / SOURCE_04) primary_raw=['contact_need']
- `frequency_v2_q0190` (FQ190 / SOURCE_04) primary_raw=['uncertainty_tolerance']
- `frequency_v2_q0191` (FQ191 / SOURCE_04) primary_raw=['reassurance_need']
- `frequency_v2_q0192` (FQ192 / SOURCE_04) primary_raw=['processing_style']
- `frequency_v2_q0193` (FQ193 / SOURCE_04) primary_raw=['disclosure_pace']
- `frequency_v2_q0195` (FQ195 / SOURCE_04) primary_raw=['uncertainty_tolerance']
- `frequency_v2_q0198` (FQ198 / SOURCE_04) primary_raw=['rhythm_adaptation']
- `frequency_v2_q0199` (FQ199 / SOURCE_04) primary_raw=['disclosure_pace']
- `frequency_v2_q0200` (FQ200 / SOURCE_04) primary_raw=['boundary_style']
- `frequency_v2_q0252` (FQ252 / SOURCE_06) primary_raw=['processing_style']
- `frequency_v2_q0253` (FQ253 / SOURCE_06) primary_raw=['autonomy_need']
- `frequency_v2_q0255` (FQ255 / SOURCE_06) primary_raw=['uncertainty_tolerance']
- `frequency_v2_q0256` (FQ256 / SOURCE_06) primary_raw=['disclosure_pace']
- `frequency_v2_q0258` (FQ258 / SOURCE_06) primary_raw=['processing_style']
- `frequency_v2_q0259` (FQ259 / SOURCE_06) primary_raw=['contact_need']
- `frequency_v2_q0260` (FQ260 / SOURCE_06) primary_raw=['boundary_style']
- `frequency_v2_q0261` (FQ261 / SOURCE_06) primary_raw=['disclosure_pace']
- `frequency_v2_q0262` (FQ262 / SOURCE_06) primary_raw=['disclosure_pace']
- `frequency_v2_q0263` (FQ263 / SOURCE_06) primary_raw=['boundary_style']
- `frequency_v2_q0264` (FQ264 / SOURCE_06) primary_raw=['processing_style']
- `frequency_v2_q0266` (FQ266 / SOURCE_06) primary_raw=['structure_preference']
- `frequency_v2_q0267` (FQ267 / SOURCE_06) primary_raw=['uncertainty_tolerance']
- `frequency_v2_q0268` (FQ268 / SOURCE_06) primary_raw=['rhythm_adaptation']
- `frequency_v2_q0270` (FQ270 / SOURCE_06) primary_raw=['reassurance_need']
- `frequency_v2_q0271` (FQ271 / SOURCE_06) primary_raw=['processing_style']
- `frequency_v2_q0272` (FQ272 / SOURCE_06) primary_raw=['uncertainty_tolerance']
- `frequency_v2_q0273` (FQ273 / SOURCE_06) primary_raw=['structure_preference']
- `frequency_v2_q0274` (FQ274 / SOURCE_06) primary_raw=['closeness_pace']
- `frequency_v2_q0276` (FQ276 / SOURCE_06) primary_raw=['disclosure_pace']
- `frequency_v2_q0277` (FQ277 / SOURCE_06) primary_raw=['structure_preference']
- `frequency_v2_q0278` (FQ278 / SOURCE_06) primary_raw=['boundary_style']
- `frequency_v2_q0282` (FQ282 / SOURCE_06) primary_raw=['processing_style']
- `frequency_v2_q0283` (FQ283 / SOURCE_06) primary_raw=['reassurance_need']
- `frequency_v2_q0284` (FQ284 / SOURCE_06) primary_raw=['boundary_style']
- `frequency_v2_q0285` (FQ285 / SOURCE_06) primary_raw=['structure_preference']
- `frequency_v2_q0286` (FQ286 / SOURCE_06) primary_raw=['social_energy']
- `frequency_v2_q0287` (FQ287 / SOURCE_06) primary_raw=['processing_style']
- `frequency_v2_q0288` (FQ288 / SOURCE_06) primary_raw=['structure_preference']
- `frequency_v2_q0289` (FQ289 / SOURCE_06) primary_raw=['reassurance_need']
- `frequency_v2_q0290` (FQ290 / SOURCE_06) primary_raw=['boundary_style']
- `frequency_v2_q0292` (FQ292 / SOURCE_06) primary_raw=['processing_style']
- `frequency_v2_q0293` (FQ293 / SOURCE_06) primary_raw=['disclosure_pace']
- `frequency_v2_q0294` (FQ294 / SOURCE_06) primary_raw=['boundary_style']
- `frequency_v2_q0295` (FQ295 / SOURCE_06) primary_raw=['processing_style']
- `frequency_v2_q0296` (FQ296 / SOURCE_06) primary_raw=['boundary_style']
- `frequency_v2_q0297` (FQ297 / SOURCE_06) primary_raw=['autonomy_need']
- `frequency_v2_q0298` (FQ298 / SOURCE_06) primary_raw=['uncertainty_tolerance']
- `frequency_v2_q0300` (FQ300 / SOURCE_06) primary_raw=['autonomy_need']
- `frequency_v2_q0344` (FQ344 / SOURCE_08) primary_raw=['boundary_style']
- `frequency_v2_q0346` (FQ346 / SOURCE_08) primary_raw=['processing_style']
- `frequency_v2_q0347` (FQ347 / SOURCE_08) primary_raw=['reassurance_need']
- `frequency_v2_q0348` (FQ348 / SOURCE_08) primary_raw=['boundary_style']
- `frequency_v2_q0351` (FQ351 / SOURCE_08) primary_raw=['boundary_style']
- `frequency_v2_q0352` (FQ352 / SOURCE_08) primary_raw=['closeness_pace']
- `frequency_v2_q0353` (FQ353 / SOURCE_08) primary_raw=['contact_need']
- `frequency_v2_q0354` (FQ354 / SOURCE_08) primary_raw=['disclosure_pace']
- `frequency_v2_q0355` (FQ355 / SOURCE_08) primary_raw=['structure_preference']
- `frequency_v2_q0356` (FQ356 / SOURCE_08) primary_raw=['rhythm_adaptation']
- `frequency_v2_q0357` (FQ357 / SOURCE_08) primary_raw=['rhythm_adaptation']
- `frequency_v2_q0358` (FQ358 / SOURCE_08) primary_raw=['boundary_style']
- `frequency_v2_q0359` (FQ359 / SOURCE_08) primary_raw=['initiative_tendency']
- `frequency_v2_q0360` (FQ360 / SOURCE_08) primary_raw=['uncertainty_tolerance']
- `frequency_v2_q0361` (FQ361 / SOURCE_08) primary_raw=['reassurance_need']
- `frequency_v2_q0364` (FQ364 / SOURCE_08) primary_raw=['boundary_style']
- `frequency_v2_q0365` (FQ365 / SOURCE_08) primary_raw=['processing_style']
- `frequency_v2_q0367` (FQ367 / SOURCE_08) primary_raw=['autonomy_need']
- `frequency_v2_q0368` (FQ368 / SOURCE_08) primary_raw=['autonomy_need']
- `frequency_v2_q0369` (FQ369 / SOURCE_08) primary_raw=['autonomy_need']
- `frequency_v2_q0370` (FQ370 / SOURCE_08) primary_raw=['processing_style']
- `frequency_v2_q0371` (FQ371 / SOURCE_08) primary_raw=['boundary_style']
- `frequency_v2_q0373` (FQ373 / SOURCE_08) primary_raw=['reassurance_need']
- `frequency_v2_q0374` (FQ374 / SOURCE_08) primary_raw=['boundary_style']
- `frequency_v2_q0375` (FQ375 / SOURCE_08) primary_raw=['initiative_tendency']
- `frequency_v2_q0376` (FQ376 / SOURCE_08) primary_raw=['autonomy_need']
- `frequency_v2_q0377` (FQ377 / SOURCE_08) primary_raw=['processing_style']
- `frequency_v2_q0379` (FQ379 / SOURCE_08) primary_raw=['autonomy_need']
- `frequency_v2_q0380` (FQ380 / SOURCE_08) primary_raw=['processing_style']
- `frequency_v2_q0381` (FQ381 / SOURCE_08) primary_raw=['boundary_style']
- `frequency_v2_q0382` (FQ382 / SOURCE_08) primary_raw=['structure_preference']
- `frequency_v2_q0383` (FQ383 / SOURCE_08) primary_raw=['processing_style']
- `frequency_v2_q0387` (FQ387 / SOURCE_08) primary_raw=['reassurance_need']
- `frequency_v2_q0388` (FQ388 / SOURCE_08) primary_raw=['structure_preference']
- `frequency_v2_q0389` (FQ389 / SOURCE_08) primary_raw=['boundary_style']
- `frequency_v2_q0390` (FQ390 / SOURCE_08) primary_raw=['processing_style']
- `frequency_v2_q0391` (FQ391 / SOURCE_08) primary_raw=['social_energy']
- `frequency_v2_q0392` (FQ392 / SOURCE_08) primary_raw=['processing_style']
- `frequency_v2_q0393` (FQ393 / SOURCE_08) primary_raw=['uncertainty_tolerance']

## Unknown labels

- `conflict_approach`: 2 occurrence(s)
- `baseline`: 1 occurrence(s)
- `reciprocity`: 1 occurrence(s)
- `trust`: 1 occurrence(s)

## Exact duplicate prompts

- none (source unique-prompt policy held)

## Duplicate option texts across items (top 25)

- `Konuyu kapatırım.` — 11 items: frequency_v2_q0222, frequency_v2_q0229, frequency_v2_q0233, frequency_v2_q0321, frequency_v2_q0331, frequency_v2_q0338, frequency_v2_q0400, frequency_v2_q0408, frequency_v2_q0413, frequency_v2_q0418, frequency_v2_q0425
- `Alan tanırım.` — 6 items: frequency_v2_q0224, frequency_v2_q0231, frequency_v2_q0242, frequency_v2_q0317, frequency_v2_q0328, frequency_v2_q0409
- `Umursamam.` — 6 items: frequency_v2_q0235, frequency_v2_q0245, frequency_v2_q0315, frequency_v2_q0343, frequency_v2_q0415, frequency_v2_q0421
- `“Biraz erken” derim.` — 6 items: frequency_v2_q0213, frequency_v2_q0220, frequency_v2_q0241, frequency_v2_q0398, frequency_v2_q0410, frequency_v2_q0422
- `“Bu sefer olmaz” derim.` — 6 items: frequency_v2_q0098, frequency_v2_q0227, frequency_v2_q0243, frequency_v2_q0332, frequency_v2_q0397, frequency_v2_q0423
- `Açıklama yaparım.` — 5 items: frequency_v2_q0216, frequency_v2_q0233, frequency_v2_q0338, frequency_v2_q0408, frequency_v2_q0418
- `Kendi tempomu korurum.` — 5 items: frequency_v2_q0100, frequency_v2_q0244, frequency_v2_q0248, frequency_v2_q0339, frequency_v2_q0395
- `“Biraz yavaş gidelim” derim.` — 5 items: frequency_v2_q0215, frequency_v2_q0308, frequency_v2_q0319, frequency_v2_q0407, frequency_v2_q0414
- `Alışmaya çalışırım.` — 4 items: frequency_v2_q0084, frequency_v2_q0236, frequency_v2_q0396, frequency_v2_q0419
- `Anlarım, ona göre davranırım.` — 4 items: frequency_v2_q0095, frequency_v2_q0247, frequency_v2_q0336, frequency_v2_q0420
- `Açıkça anlatırım.` — 4 items: frequency_v2_q0086, frequency_v2_q0239, frequency_v2_q0240, frequency_v2_q0327
- `Değiştirmeye çalışırım.` — 4 items: frequency_v2_q0206, frequency_v2_q0321, frequency_v2_q0340, frequency_v2_q0424
- `Dinlerim ama kendimden az bahsederim.` — 4 items: frequency_v2_q0215, frequency_v2_q0238, frequency_v2_q0313, frequency_v2_q0414
- `Direkt sorarım.` — 4 items: frequency_v2_q0095, frequency_v2_q0247, frequency_v2_q0336, frequency_v2_q0420
- `Görmezden gelirim.` — 4 items: frequency_v2_q0095, frequency_v2_q0247, frequency_v2_q0336, frequency_v2_q0420
- `Kabul ederim.` — 4 items: frequency_v2_q0208, frequency_v2_q0213, frequency_v2_q0402, frequency_v2_q0410
- `Karşılıklı olarak onun da bir şeyini söylerim.` — 4 items: frequency_v2_q0206, frequency_v2_q0324, frequency_v2_q0340, frequency_v2_q0424
- `Katılırım.` — 4 items: frequency_v2_q0098, frequency_v2_q0214, frequency_v2_q0243, frequency_v2_q0423
- `Ne kadar süreceğini sorarım.` — 4 items: frequency_v2_q0087, frequency_v2_q0224, frequency_v2_q0317, frequency_v2_q0409
- `O netleşsin diye beklerim.` — 4 items: frequency_v2_q0095, frequency_v2_q0247, frequency_v2_q0336, frequency_v2_q0420
- `Onun temposuna uyum sağlarım.` — 4 items: frequency_v2_q0058, frequency_v2_q0223, frequency_v2_q0234, frequency_v2_q0417
- `Orta yol buluruz.` — 4 items: frequency_v2_q0085, frequency_v2_q0217, frequency_v2_q0309, frequency_v2_q0412
- `Seçici olurum.` — 4 items: frequency_v2_q0098, frequency_v2_q0243, frequency_v2_q0307, frequency_v2_q0423
- `“Biraz zamana ihtiyacım var” derim.` — 4 items: frequency_v2_q0225, frequency_v2_q0244, frequency_v2_q0322, frequency_v2_q0330
- `“Sen karar ver” derim.` — 4 items: frequency_v2_q0226, frequency_v2_q0314, frequency_v2_q0318, frequency_v2_q0411

## Semantic near-duplicate clusters (top 20)

- size=3 max_sim=1.0 ids=frequency_v2_q0228, frequency_v2_q0333, frequency_v2_q0426
  - Yeni biriyle mesajlaşırken o çok uzun ve detaylı yazıyor, siz daha kısa yazmayı seviyorsunuz.
- size=3 max_sim=0.929 ids=frequency_v2_q0243, frequency_v2_q0307, frequency_v2_q0423
  - Partneriniz sizinle aynı anda birden fazla plan yapıyor ve sizi de dahil etmek istiyor.
- size=3 max_sim=0.909 ids=frequency_v2_q0247, frequency_v2_q0336, frequency_v2_q0420
  - Partneriniz sizinle ilgili bir konuyu (duygu, ihtiyaç, şikâyet) dolaylı yoldan anlatıyor.
- size=3 max_sim=0.9 ids=frequency_v2_q0315, frequency_v2_q0343, frequency_v2_q0415
  - Partneriniz sizin bir başarınızı (iş, kişisel) duyunca beklediğinizden daha az tepki verdi.
- size=3 max_sim=0.833 ids=frequency_v2_q0206, frequency_v2_q0340, frequency_v2_q0424
  - Partneriniz sizin bir alışkanlığınızı (geç kalma, dağınıklık, sesli yemek yeme vb.) sürekli dile getiriyor.
- size=2 max_sim=1.0 ids=frequency_v2_q0318, frequency_v2_q0411
  - Partneriniz sizinle aynı anda hem evde kalmak hem de dışarı çıkmak istiyor ve karar veremiyor.
- size=2 max_sim=0.9 ids=frequency_v2_q0237, frequency_v2_q0342
  - Bir planınız vardı. Partneriniz son anda “bugün içimden gelmiyor” dedi.
- size=2 max_sim=0.9 ids=frequency_v2_q0245, frequency_v2_q0421
  - Partneriniz sizin bir kararınızı (saç kesimi, kıyafet, hobiniz) beğenmediğini söyledi.
- size=2 max_sim=0.889 ids=frequency_v2_q0246, frequency_v2_q0335
  - Birlikte bir film / dizi seçerken sürekli aynı türde anlaşamıyorsunuz.
- size=2 max_sim=0.846 ids=frequency_v2_q0215, frequency_v2_q0414
  - Yeni biriyle konuşurken o çok hızlı derin konulara giriyor (aile travması, geçmiş yaralar).
- size=2 max_sim=0.825 ids=frequency_v2_q0222, frequency_v2_q0413
  - Partneriniz sizin bir arkadaşınızla olan yakınlığınızdan rahatsız olduğunu belli ediyor.
- size=2 max_sim=0.818 ids=frequency_v2_q0224, frequency_v2_q0409
  - Bir tartışma sonrası partneriniz “biraz yalnız kalmam lazım” dedi.
- size=2 max_sim=0.8 ids=frequency_v2_q0331, frequency_v2_q0425
  - Bir tartışmada partneriniz haklı olduğunu düşünüyor ve geri adım atmıyor.
- size=2 max_sim=0.786 ids=frequency_v2_q0234, frequency_v2_q0417
  - Birlikte bir etkinliğe (konser, düğün, parti) gittiniz. Partneriniz çok sosyal, siz daha geri plandasınız.
- size=2 max_sim=0.75 ids=frequency_v2_q0031, frequency_v2_q0115
  - Birlikte yaşamaya veya uzun süre kalmaya başladınız. O gece kuşu, sen erkencisin.
- size=2 max_sim=0.75 ids=frequency_v2_q0225, frequency_v2_q0330
  - Partneriniz sizinle ilgili olumlu bir duyguyu (aşk, bağlılık, gelecek hayali) ilk kez açıkça ifade etti.
- size=2 max_sim=0.75 ids=frequency_v2_q0230, frequency_v2_q0341
  - Partneriniz sizinle ilgili bir sırrı (sağlık, aile, geçmiş) paylaştı ve “kimseye söyleme” dedi.
- size=2 max_sim=0.714 ids=frequency_v2_q0015, frequency_v2_q0123
  - Stresli bir anında partnerine gereksiz yere sert çıkıştın. 10 dakika sonra durumu fark ettin.
- size=2 max_sim=0.714 ids=frequency_v2_q0323, frequency_v2_q0404
  - Bir planınız vardı. Partneriniz “belki başka bir şey yaparız” diye belirsiz konuşuyor.
- size=2 max_sim=0.696 ids=frequency_v2_q0244, frequency_v2_q0322
  - Uzun bir ayrılıktan sonra yeniden bir araya geldiniz. Partneriniz hemen yoğun yakınlık istiyor.

## High social-desirability risk (heuristic, not a lie score)

These flags are review hints. They are not `truth_score` / `lie_score`.

- `frequency_v2_q0003` flags=['high_social_desirability_risk']: Partnerin işten çok gergin ve morali bozuk döndü. Olayı anlatıyor. Senin ilk refleksin ne olur?
- `frequency_v2_q0007` flags=['high_social_desirability_risk', 'one_option_socially_preferred']: Hafta sonunu birlikte geçirmeyi beklerken, partnerin "Bu hafta sonu sadece evde tek başıma kalıp dinlenmeye ihtiyacım var" dedi. Nasıl karşı
- `frequency_v2_q0015` flags=['one_option_socially_preferred']: Stresli bir anında partnerine gereksiz yere sert çıkıştın. 10 dakika sonra durumu fark ettin.
- `frequency_v2_q0018` flags=['one_option_socially_preferred']: Beklenmedik büyük bir ortak masraf (örn: aracın bozulması, evin bir masrafı) çıktı.
- `frequency_v2_q0020` flags=['high_social_desirability_risk']: Partnerin bir şeye bariz şekilde canı sıkkın ama sana "bir şey yok, iyiyim" diyor.
- `frequency_v2_q0031` flags=['high_social_desirability_risk']: Birlikte yaşamaya veya uzun süre kalmaya başladınız. O gece kuşu, sen erkencisin.
- `frequency_v2_q0047` flags=['one_option_socially_preferred']: Evde birlikte önemli bir işi yetiştirirken bilgisayar/internet aniden kilitlendi ve veriler kayboldu.
- `frequency_v2_q0049` flags=['high_social_desirability_risk', 'too_context_or_feeling_dependent']: Partnerinin sosyal medyada eski bir flörtünün fotoğraflarını beğendiğini gördün. Bu sende nasıl bir içsel tepki yaratır?
- `frequency_v2_q0065` flags=['high_social_desirability_risk']: Partnerin seninle ilgili bir sınırını (zaman, konu, davranış) ilk kez net ifade etti.
- `frequency_v2_q0097` flags=['one_option_socially_preferred']: Bir konuda özür dilemen gereken bir durum oluştu.
- `frequency_v2_q0123` flags=['high_social_desirability_risk', 'one_option_socially_preferred']: Stresli bir anında partnerine gereksiz sert çıktığını on dakika sonra fark ettin.
- `frequency_v2_q0128` flags=['high_social_desirability_risk', 'one_option_socially_preferred']: Partnerin kariyeriyle ilgili riskli bir karar için fikrini sordu.
- `frequency_v2_q0158` flags=['high_social_desirability_risk']: Partnerinin buluşmalara sürekli 15-20 dakika geç kalma huyu var. Bir süre sonra ne yaparsın?
- `frequency_v2_q0166` flags=['high_social_desirability_risk']: Arabada uzun yoldasınız ve bir konu yüzünden sesler yükseldi, kavga çıktı. İdeal çözüm yöntemin nedir?
- `frequency_v2_q0167` flags=['high_social_desirability_risk', 'one_option_socially_preferred']: Birlikte geçireceğiniz tek boş gününüz. Partnerin, yakın bir arkadaşının büyük bir krizi (örn: ayrılık) olduğunu ve onun yanına gitmesi gere
- `frequency_v2_q0169` flags=['high_social_desirability_risk']: Hayatındaki işler hiç yolunda gitmiyor. Partnerinin sana yaklaşımı nasıl olmalı?
- `frequency_v2_q0170` flags=['one_option_socially_preferred']: Kötü bir tartışmadan sonra "Birkaç saat yalnız kalmaya ihtiyacım var" dedin. Ama partnerin konuyu çözmek için sürekli konuşmak istiyor.
- `frequency_v2_q0176` flags=['high_social_desirability_risk']: Partnerin bir belgesel izledi ve o günden sonra tamamen vegan/çok sıkı bir diyete geçmeye karar verdi.
- `frequency_v2_q0183` flags=['high_social_desirability_risk']: Sen ağlayarak veya çok sinirli bir şekilde bir derdini anlatırken, partnerin sürekli "Şöyle yapmalısın, şurayı ara" diye çözümler sunuyor.
- `frequency_v2_q0186` flags=['one_option_socially_preferred']: Büyük bir kavgada bağırdın, çağırdın. Ancak 10 dakika sonra aslında tamamen *senin haksız olduğunu* fark ettin.
- `frequency_v2_q0187` flags=['high_social_desirability_risk']: Akşam birlikte film izliyorsunuz ama partnerin sürekli telefonuyla oynuyor, gülümsüyor, birilerine yazıyor.
- `frequency_v2_q0261` flags=['high_social_desirability_risk']: İkiniz arasında ufak bir yanlış anlaşılma oldu. Partnerin olayı sana uzun uzun, detaylıca ve kendini sürekli savunarak açıklamaya çalışıyor.
- `frequency_v2_q0271` flags=['one_option_socially_preferred']: Tatilde kiraladığınız otel odası fotoğraflardaki gibi çıkmadı, berbat durumda. Partnerin çok sinirlendi.
- `frequency_v2_q0283` flags=['one_option_socially_preferred']: Gece 3'te uyandın, çok yoğun bir gelecek kaygısı veya korku hissi yaşıyorsun. Yanında partnerin uyuyor.
- `frequency_v2_q0287` flags=['high_social_desirability_risk']: İkiniz de çok ilgili olduğunuz tarihi/siyasi bir konuda farklı uçlardasınız. Tartışma hararetlendi.
- `frequency_v2_q0292` flags=['one_option_socially_preferred']: Partnerin elindeki kahveyi tamamen senin yeni bilgisayarının veya çok sevdiğin bir kıyafetinin üstüne döktü.
- `frequency_v2_q0300` flags=['high_social_desirability_risk']: İlişkinizin 3. yılında partnerin, manevi/felsefi olarak tamamen farklı bir yola girdi (örn: minimalist yaşam, inziva vs.).
- `frequency_v2_q0347` flags=['high_social_desirability_risk', 'one_option_socially_preferred']: 3. buluşmanız için hazırsın. 1 saat kala "Çok acil bir ailevi durum çıktı, iptal etmem gerek" diye mesaj attı.
- `frequency_v2_q0348` flags=['high_social_desirability_risk']: Birlikte yaşadığınız dönemde, partnerin sana hiç danışmadan kendi birikiminden yakın bir arkadaşına yüklü bir borç verdi.
- `frequency_v2_q0353` flags=['high_social_desirability_risk']: Baş başa yemek yerken partnerinin telefonu masada ve ekranı yukarı bakıyor. Sürekli bildirimler yanıp sönüyor.
- `frequency_v2_q0369` flags=['high_social_desirability_risk', 'one_option_socially_preferred']: Partnerin yıllardır yapmak istediği ama gelir garantisi olmayan sanatsal/serbest bir mesleğe (örn: müzisyenlik) geçmek istediğini açıkladı.
- `frequency_v2_q0378` flags=['high_social_desirability_risk', 'one_option_socially_preferred']: İlişkinin 2. yılında partnerin sana, kendi başına tek başına 1 haftalık bir sırt çantalı tura çıkmak istediğini söyledi.

## Rewrite / incomplete / weak-tradeoff candidates

- `frequency_v2_q0003` issues=['no_canonical_primary', 'option_missing_canonical_weights', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=['high_social_desirability_risk']
- `frequency_v2_q0008` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=[]
- `frequency_v2_q0015` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=['one_option_socially_preferred']
- `frequency_v2_q0026` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=[]
- `frequency_v2_q0029` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=[]
- `frequency_v2_q0039` issues=[] flags=['weak_tradeoff_language']
- `frequency_v2_q0043` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=[]
- `frequency_v2_q0047` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=['one_option_socially_preferred']
- `frequency_v2_q0049` issues=['processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=['high_social_desirability_risk', 'too_context_or_feeling_dependent']
- `frequency_v2_q0080` issues=[] flags=['weak_tradeoff_language']
- `frequency_v2_q0157` issues=[] flags=['weak_tradeoff_language']
- `frequency_v2_q0163` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=[]
- `frequency_v2_q0166` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=['high_social_desirability_risk']
- `frequency_v2_q0180` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=[]
- `frequency_v2_q0183` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=['high_social_desirability_risk']
- `frequency_v2_q0186` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=['one_option_socially_preferred']
- `frequency_v2_q0191` issues=['processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=['too_context_or_feeling_dependent']
- `frequency_v2_q0192` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=[]
- `frequency_v2_q0226` issues=[] flags=['weak_tradeoff_language']
- `frequency_v2_q0252` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=[]
- `frequency_v2_q0255` issues=['processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=['weak_tradeoff_language']
- `frequency_v2_q0258` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=[]
- `frequency_v2_q0264` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=[]
- `frequency_v2_q0271` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=['one_option_socially_preferred']
- `frequency_v2_q0282` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=[]
- `frequency_v2_q0285` issues=['processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=['weak_tradeoff_language']
- `frequency_v2_q0287` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=['high_social_desirability_risk']
- `frequency_v2_q0292` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=['one_option_socially_preferred']
- `frequency_v2_q0295` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=[]
- `frequency_v2_q0326` issues=[] flags=['weak_tradeoff_language']
- `frequency_v2_q0345` issues=[] flags=['weak_tradeoff_language']
- `frequency_v2_q0346` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=[]
- `frequency_v2_q0365` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=[]
- `frequency_v2_q0370` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=[]
- `frequency_v2_q0377` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=[]
- `frequency_v2_q0380` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=[]
- `frequency_v2_q0383` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=[]
- `frequency_v2_q0390` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=[]
- `frequency_v2_q0392` issues=['no_canonical_primary', 'processing_style_manual_review', 'unknown_or_blocked_dimension_labels'] flags=[]

## Second-layer evidence

All 1,704 `evidence_meta` values are `null` with `review_status=pending`.
No numeric social_desirability / plausibility / etc. was invented.

## Live production

This generator does not write:

- `assets/data/assessment_v3/frequency/frequency_bank_tr_v1.json`
- `assets/data/assessment_v3/frequency/frequency_bank_en_v1.json`
- `pubspec.yaml`
- Frequency locale routing

## Recommended next phase

Human metadata review: re-score every `processing_style` item onto the 12D vocabulary or drop it from production selection; fill evidence_meta only where a reviewer can defend a [0,1] value; resolve near-duplicate clusters before activating a 50-of-426 selector.

