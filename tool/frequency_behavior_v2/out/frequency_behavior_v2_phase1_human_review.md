# Frequency V2 Phase 1 — Human Review Report

Status: **proposal only**. Normalized draft JSON was not modified. Frequency V1, pubspec, live locale routing, Discover, Persona, matching, `canonical_v1`, and `FrequencyTo20dRuntimeAdapter` were not touched. V2 was not activated. Second-layer evidence (`social_desirability`, `behavioral_plausibility`, `self_presentation_risk`) was not assigned.

## Review rules actually used

- Canonical targets are only the 12 Frequency V2 dimensions. Unknown labels were never treated as aliases.
- `processing_style` was **not** mapped to `repair_style`. `repair_style` is used only when the option is specifically about conflict repair, post-conflict processing, or repair behavior.
- Old `processing_style` in this bank is mostly a rational-vs-emotional bipolar. Where that bipolar does not cleanly measure a 12D act, the recommendation is **DROP_WEIGHT**.
- Existing non-processing canonical weights were kept unless they were clearly the wrong construct for the same option (called out in the reason).
- Signed weights stay in the authored `±1` / `±2` convention. Old `±2` was not preserved just to keep a number.
- Classifications are recommendations, not scientific claims. Confidence is `high` / `medium` / `low`.

## Item-level unknown constructs (not option weights)

| Question | Unknown label | Recommendation |
|---|---|---|
| `frequency_v2_q0016` | `conflict_approach` (secondary) | Drop the label. The item is a messy-habit / boundary item. Primary stays `boundary_firmness`. Do not import an EQ conflict_approach construct. |
| `frequency_v2_q0047` | `conflict_approach` (source primary) | Drop the label. The prompt is a shared technical outage, not a relational rupture. Remaining 12D mass sits on `initiative` and `uncertainty_tolerance`. Not `repair_style`. |
| `frequency_v2_q0034` | `baseline` on option B | Drop. 'Trust as default' is not a 12D. Keep `uncertainty_tolerance +1`. |
| `frequency_v2_q0208` | `reciprocity` on option C | Drop. Turn-taking is already `structure_preference +1`. Reciprocity is not a 12D. |
| `frequency_v2_q0385` | `trust` (source secondary, no option weight) | Drop the item-level label. All four options already have 12D scores. Do not create a trust dimension. |

## Per-option review

### frequency_v2_q0003

**Question ID:** `frequency_v2_q0003`

**Question text:** Partnerin işten çok gergin ve morali bozuk döndü. Olayı anlatıyor. Senin ilk refleksin ne olur?

**Context:** support

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0003_a`

**Option ID:** `frequency_v2_q0003_a`

**Option text:** Neden böyle olduğunu mantıklıca analiz edip ona çözüm yolları sunmak.

**Existing canonical weights:** (none)

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `CLEAR_REMAP`

**Proposed canonical weights:** `initiative +1`

**Reason:** The act is offering solutions, which is taking initiative on the partner's problem. The 'logical analysis' half of the option is cognitive style, not a 12D, so this is +1 not +2. Not conflict repair.

**Confidence:** medium

#### Option `frequency_v2_q0003_b`

**Option ID:** `frequency_v2_q0003_b`

**Option text:** Haklılığına vurgu yapıp duygusal olarak yanında durduğumu hissettirmek.

**Existing canonical weights:** `reassurance_need +1`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `reassurance_need +1`

**Reason:** Emotional standing-by is already reassurance_need +1. processing_style−2 is the old 'emotional vs rational' pole and is not conflict repair.

**Confidence:** high

#### Option `frequency_v2_q0003_c`

**Option ID:** `frequency_v2_q0003_c`

**Option text:** Sakinleşmesi için ona biraz alan tanıyıp, iyi hissettiğinde konuyu açmasını beklemek.

**Existing canonical weights:** `autonomy +1`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `autonomy +1`

**Reason:** Giving space until they open is already autonomy +1. The leftover processing_style+1 is delay-as-rationality, not a 12D.

**Confidence:** high

### frequency_v2_q0005

**Question ID:** `frequency_v2_q0005`

**Question text:** Birlikte izlediğiniz bir filmdeki ahlaki bir ikilem üzerine tamamen zıt görüşlere sahipsiniz. Tartışma uzadı, ne yaparsın?

**Context:** conflict

**Draft primary:** `boundary_firmness` · **Source primary raw:** `boundary_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0005_a`

**Option ID:** `frequency_v2_q0005_a`

**Option text:** Fikrinin arkasındaki mantığı sonuna kadar anlamaya ve kendi fikrimi savunmaya devam ederim.

**Existing canonical weights:** `boundary_firmness +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `boundary_firmness +2`

**Reason:** Defending a view to the end is already boundary_firmness +2. 'Understanding the logic' is intellectual style, not a canonical dimension.

**Confidence:** high

#### Option `frequency_v2_q0005_c`

**Option ID:** `frequency_v2_q0005_c`

**Option text:** Tartışmanın gerginleşme ihtimaline karşı konuyu şakaya vurup kapatırım.

**Existing canonical weights:** `uncertainty_tolerance -1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `CLEAR_REMAP`

**Proposed canonical weights:** `uncertainty_tolerance -1`, `repair_style -2`

**Reason:** This is a live disagreement being joke-closed to avoid processing it. That is avoidant repair behavior, not 'being rational'. Keep the existing tension-avoidance (uncertainty_tolerance −1).

**Confidence:** high

#### Option `frequency_v2_q0005_d`

**Option ID:** `frequency_v2_q0005_d`

**Option text:** Ne hissettiğini anlamaya odaklanır, fikrim zıt olsa da onun duygusunu onaylarım.

**Existing canonical weights:** `closeness_pace +1`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `CLEAR_REMAP`

**Proposed canonical weights:** `closeness_pace +1`, `repair_style +1`

**Reason:** Validating the partner's feeling during a clash is emotion-focused conflict processing. closeness_pace is a stretch but still describes staying with the other person's inner state; repair_style +1 is the defensible added score. Not +2: they are not repairing a rupture so much as holding the disagreement.

**Confidence:** medium

### frequency_v2_q0008

**Question ID:** `frequency_v2_q0008`

**Question text:** Partnerin, senin bir davranış tarzını oldukça net ve yapıcı bir şekilde eleştirdi. İlk tepkin genelde nasıl şekillenir?

**Context:** conflict

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0008_a`

**Option ID:** `frequency_v2_q0008_a`

**Option text:** Savunmaya geçmeden önce kendi içimde bunu mantıklı bir şekilde tartmak için sessizleşirim.

**Existing canonical weights:** `disclosure_pace -1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `disclosure_pace -1`

**Reason:** Silence-to-think after criticism could be delayed repair, low disclosure, or mere cognitive style. disclosure_pace −1 already exists; adding repair_style would double-count without knowing whether the silence is repair work or shutdown.

**Confidence:** low

#### Option `frequency_v2_q0008_b`

**Option ID:** `frequency_v2_q0008_b`

**Option text:** O an üzüldüğümü veya bozulduğumu saklamam, duygumu anında belli ederim.

**Existing canonical weights:** `disclosure_pace +1`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `disclosure_pace +1`

**Reason:** Showing hurt immediately is already disclosure_pace +1. processing_style−2 would only restate affect vs reason.

**Confidence:** high

### frequency_v2_q0011

**Question ID:** `frequency_v2_q0011`

**Question text:** Akşam şık bir restorana gitmek üzere hazırlandın ama partnerin son dakika arayıp "Çok yorgunum, evde film ve pizza yapsak uyar mı?" dedi.

**Context:** planning

**Draft primary:** `structure_preference` · **Source primary raw:** `structure_preference` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0011_c`

**Option ID:** `frequency_v2_q0011_c`

**Option text:** Evde vakit geçirmek uyar, yorgunsa zorlamanın anlamı yok, dinlenmesi daha mühim.

**Existing canonical weights:** `boundary_firmness -1`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `boundary_firmness -1`

**Reason:** Not forcing a tired partner is deference/compassion. boundary_firmness −1 already leans that way. processing_style−1 is not adaptability or repair.

**Confidence:** high

### frequency_v2_q0013

**Question ID:** `frequency_v2_q0013`

**Question text:** Geçmişteki büyük bir pişmanlığını veya travmanı yeni bir partnere ne zaman anlatırsın?

**Context:** early_dating, uncertainty

**Draft primary:** `disclosure_pace` · **Source primary raw:** `disclosure_pace` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0013_d`

**Option ID:** `frequency_v2_q0013_d`

**Option text:** Gerçekten gerekli değilse hiç açmamayı, bugüne ve geleceğe odaklanmayı tercih ederim.

**Existing canonical weights:** `disclosure_pace -2`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `disclosure_pace -2`

**Reason:** Never telling a trauma unless necessary is already disclosure_pace −2. processing_style+2 ('focus on today') is a justification, not a new 12D.

**Confidence:** high

### frequency_v2_q0015

**Question ID:** `frequency_v2_q0015`

**Question text:** Stresli bir anında partnerine gereksiz yere sert çıkıştın. 10 dakika sonra durumu fark ettin.

**Context:** conflict

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0015_a`

**Option ID:** `frequency_v2_q0015_a`

**Option text:** Hemen yanına gidip sarılarak, duygusal bir şekilde özür dilerim.

**Existing canonical weights:** `reassurance_need +1`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `CLEAR_REMAP`

**Proposed canonical weights:** `reassurance_need +1`, `repair_style +2`

**Reason:** Immediate hug-and-apology after snapping is post-conflict repair, the one case where processing_style−2 actually meant repair. Keep reassurance_need +1 (seeking/giving emotional reconnection).

**Confidence:** high

#### Option `frequency_v2_q0015_b`

**Option ID:** `frequency_v2_q0015_b`

**Option text:** Stresimin kaynağını rasyonel bir dille açıklayarak durumu telafi edecek bir konuşma yaparım.

**Existing canonical weights:** `boundary_firmness +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `CLEAR_REMAP`

**Proposed canonical weights:** `boundary_firmness +1`, `repair_style +1`

**Reason:** Explaining the stress source in order to make amends is verbal repair, not a generic 'rational personality'. Keep boundary_firmness +1 (stating one's account). Not +2: the same wording can also be self-justifying rather than repairing.

**Confidence:** medium

#### Option `frequency_v2_q0015_d`

**Option ID:** `frequency_v2_q0015_d`

**Option text:** Bir süre daha kendi alanımda kalır, ikimizin de tamamen sakinleştiğinden emin olunca konuyu açarım.

**Existing canonical weights:** `autonomy +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `CLEAR_REMAP`

**Proposed canonical weights:** `autonomy +1`, `repair_style -1`

**Reason:** Waiting until both are calm is delayed repair plus space. autonomy +1 already fits; remap the leftover processing_style to repair_style −1 rather than forcing it to +2 structure/logic.

**Confidence:** high

### frequency_v2_q0016

**Question ID:** `frequency_v2_q0016`

**Question text:** Partnerinin ufak ama senin günlük ritmini bozan bir alışkanlığı var (örn: eşyaları dağınık bırakmak).

**Context:** established

**Draft primary:** `boundary_firmness` · **Source primary raw:** `boundary_style` · **Unresolved labels:** `conflict_approach`, `processing_style`

#### Option `frequency_v2_q0016_a`

**Option ID:** `frequency_v2_q0016_a`

**Option text:** Kendi sınırlarım nettir, rahatsızlığımı anında ve doğrudan dile getiririm.

**Existing canonical weights:** `boundary_firmness +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `boundary_firmness +2`

**Reason:** Immediate direct limit is already boundary_firmness +2. processing_style+1 was 'I communicate clearly/rationally' and is redundant. Item-level conflict_approach is also not a 12D.

**Confidence:** high

#### Option `frequency_v2_q0016_c`

**Option ID:** `frequency_v2_q0016_c`

**Option text:** Konuyu ciddi bir tartışmaya çevirmeden, şakayla karışık laf sokarak belli ederim.

**Existing canonical weights:** `uncertainty_tolerance +1`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `uncertainty_tolerance +1`

**Reason:** Joke-hinting about mess could be low disclosure, avoidant repair, or low-stakes teasing. uncertainty_tolerance +1 is a weak existing fit. No single 12D is safe.

**Confidence:** low

### frequency_v2_q0018

**Question ID:** `frequency_v2_q0018`

**Question text:** Beklenmedik büyük bir ortak masraf (örn: aracın bozulması, evin bir masrafı) çıktı.

**Context:** support

**Draft primary:** `uncertainty_tolerance` · **Source primary raw:** `uncertainty_tolerance` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0018_a`

**Option ID:** `frequency_v2_q0018_a`

**Option text:** Hızla bütçe analizi yapar, alternatifleri listeler, duygusal tepki vermeden çözerim.

**Existing canonical weights:** `structure_preference +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +1`

**Reason:** Budget analysis and listing alternatives is already structure_preference +1. Do not inflate to +2 just to keep the old processing_style+2.

**Confidence:** high

#### Option `frequency_v2_q0018_b`

**Option ID:** `frequency_v2_q0018_b`

**Option text:** Stresimi partnerimle paylaşır, bu zorlukta onun "hallederiz" desteğine ihtiyaç duyarım.

**Existing canonical weights:** `reassurance_need +2`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `reassurance_need +2`

**Reason:** Sharing stress and needing 'hallederiz' is already reassurance_need +2. processing_style−1 is affect coloring.

**Confidence:** high

### frequency_v2_q0020

**Question ID:** `frequency_v2_q0020`

**Question text:** Partnerin bir şeye bariz şekilde canı sıkkın ama sana "bir şey yok, iyiyim" diyor.

**Context:** support

**Draft primary:** `boundary_firmness` · **Source primary raw:** `boundary_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0020_c`

**Option ID:** `frequency_v2_q0020_c`

**Option text:** O anlatmayana kadar ben de günlük rutinimde hiçbir şey yokmuş gibi davranmaya devam ederim.

**Existing canonical weights:** `contact_need -1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `contact_need -1`

**Reason:** Continuing routine as if nothing is wrong is already contact_need −1. processing_style+2 (cool compartmentalizing) is not a 12D and is not repair.

**Confidence:** high

### frequency_v2_q0023

**Question ID:** `frequency_v2_q0023`

**Question text:** Sevdiğini ve değer verdiğini genelde en net nasıl belli edersin?

**Context:** early_dating, uncertainty

**Draft primary:** `closeness_pace` · **Source primary raw:** `closeness_pace` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0023_b`

**Option ID:** `frequency_v2_q0023_b`

**Option text:** Onun için bir şeyler yaparak, hayatını kolaylaştıracak pratik çözümler sunarak.

**Existing canonical weights:** `disclosure_pace -1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `disclosure_pace -1`

**Reason:** Love shown via practical help is a care language, not processing_style. disclosure_pace −1 already marks low verbal expression. Acts of service is not a 12D.

**Confidence:** high

### frequency_v2_q0025

**Question ID:** `frequency_v2_q0025`

**Question text:** Gün içinde partnerinden sonu nokta ile biten, alışılmışın dışında kısa ve soğuk hissettiren bir mesaj aldın.

**Context:** uncertainty

**Draft primary:** `uncertainty_tolerance` · **Source primary raw:** `uncertainty_tolerance` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0025_b`

**Option ID:** `frequency_v2_q0025_b`

**Option text:** Acaba bir şeye mi kırıldı diye geçmiş konuşmaları kendi içimde analiz ederim.

**Existing canonical weights:** `reassurance_need +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `reassurance_need +1`

**Reason:** Ruminating over past chats is internal analysis. reassurance_need +1 already captures the worry. processing_style+2 is not a 12D.

**Confidence:** high

#### Option `frequency_v2_q0025_d`

**Option ID:** `frequency_v2_q0025_d`

**Option text:** Akşam yüz yüze veya telefonda konuşana kadar bu durumu hiç kafama takmam.

**Existing canonical weights:** `autonomy +1`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `autonomy +1`

**Reason:** Not dwelling until evening is already autonomy +1 (and overlaps uncertainty_tolerance, which this option does not need extra). Drop the processing tag.

**Confidence:** high

### frequency_v2_q0026

**Question ID:** `frequency_v2_q0026`

**Question text:** Temel bir inanç veya hayata bakış açısı konusunda partnerinle tamamen zıt olduğunuzu fark ettiniz.

**Context:** conflict

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0026_a`

**Option ID:** `frequency_v2_q0026_a`

**Option text:** Bu konuyu derinlemesine, belki saatlerce tartışarak ortak bir zemin bulmaya çalışırım.

**Existing canonical weights:** `closeness_pace +1`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `closeness_pace +1`

**Reason:** Hours of debate to find common ground could be initiative, closeness, or even repair if treated as conflict. It is also just intellectual engagement, which is not a 12D. closeness_pace +1 is already a stretch.

**Confidence:** low

#### Option `frequency_v2_q0026_c`

**Option ID:** `frequency_v2_q0026_c`

**Option text:** Fikirlerini değiştirmeye çalışmam ama onun bakış açısını entelektüel bir merakla deşerim.

**Existing canonical weights:** `disclosure_pace -1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `disclosure_pace -1`

**Reason:** Intellectual probing without trying to convert is curiosity, not a 12D. disclosure_pace −1 (not putting one's own view forward) is the only usable score.

**Confidence:** high

### frequency_v2_q0027

**Question ID:** `frequency_v2_q0027`

**Question text:** Acil çözmen gereken zor bir problemin var, ama partnerin o gün çok kritik bir iş toplantısında.

**Context:** support

**Draft primary:** `reassurance_need` · **Source primary raw:** `reassurance_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0027_d`

**Option ID:** `frequency_v2_q0027_d`

**Option text:** Krizi fırsata çevirip işe odaklanırım, ona ancak akşam detaylıca olanları anlatırım.

**Existing canonical weights:** `adaptability -1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `adaptability -1`

**Reason:** Compartmentalizing a crisis until evening could be autonomy, delayed disclosure, or low adaptability (not matching the partner's availability). adaptability −1 is not obviously right. Do not map processing_style+2 to structure.

**Confidence:** low

### frequency_v2_q0029

**Question ID:** `frequency_v2_q0029`

**Question text:** Partnerin basit bir unutkanlık yaptı (örn: senin için önemli bir evrakı almayı unuttu) ve bu sana zaman kaybettirdi.

**Context:** conflict

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0029_a`

**Option ID:** `frequency_v2_q0029_a`

**Option text:** Sinirlendiğimi belli ederim ama sonrasında hemen affedici moda geçerim.

**Existing canonical weights:** `uncertainty_tolerance -1`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `CLEAR_REMAP`

**Proposed canonical weights:** `uncertainty_tolerance -1`, `repair_style +1`

**Reason:** Showing anger then quickly forgiving is a short repair cycle after a small hurt. Keep uncertainty_tolerance −1 (low tolerance for the disruption). Not +2: the option is a flash of affect, not a full repair method.

**Confidence:** medium

#### Option `frequency_v2_q0029_c`

**Option ID:** `frequency_v2_q0029_c`

**Option text:** Neden unuttuğunu anlamaya çalışır, bir daha olmaması için ona bir sistem/çözüm öneririm.

**Existing canonical weights:** `structure_preference +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +1`

**Reason:** Proposing a system so the forgetfulness does not repeat is already structure_preference +1. processing_style+2 is the same idea restated.

**Confidence:** high

### frequency_v2_q0030

**Question ID:** `frequency_v2_q0030`

**Question text:** Partnerinin geçmişiyle ilgili zarar verici olmayan ama senin yeni öğrendiğin önemli bir detayı (örn: eski mesleği) gizlediğini fark ettin.

**Context:** uncertainty

**Draft primary:** `disclosure_pace` · **Source primary raw:** `disclosure_pace` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0030_c`

**Option ID:** `frequency_v2_q0030_c`

**Option text:** Neden saklama ihtiyacı duyduğunu anlamak için yargılamadan dinlemeye odaklanırım.

**Existing canonical weights:** `adaptability +1`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `adaptability +1`

**Reason:** Non-judgmental listening about a hidden past could be disclosure_pace, closeness, or adaptability. Existing adaptability +1 is plausible; processing_style+1 does not clearly add a second dimension.

**Confidence:** low

### frequency_v2_q0031

**Question ID:** `frequency_v2_q0031`

**Question text:** Birlikte yaşamaya veya uzun süre kalmaya başladınız. O gece kuşu, sen erkencisin.

**Context:** established

**Draft primary:** `adaptability` · **Source primary raw:** `rhythm_adaptation` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0031_d`

**Option ID:** `frequency_v2_q0031_d`

**Option text:** Sabah ben kalktığımda onu uyandırmamaya, akşam o uyumadığında bana saygı duymasına dikkat ederim.

**Existing canonical weights:** `boundary_firmness +1`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `boundary_firmness +1`

**Reason:** Mutual respect for sleep windows is already boundary_firmness +1. processing_style+1 does not add structure or repair.

**Confidence:** high

### frequency_v2_q0033

**Question ID:** `frequency_v2_q0033`

**Question text:** Bir ilişkide "Seni seviyorum" demek veya derin duyguları itiraf etmek sence nasıl bir süreçtir?

**Context:** early_dating, uncertainty

**Draft primary:** `closeness_pace` · **Source primary raw:** `closeness_pace` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0033_b`

**Option ID:** `frequency_v2_q0033_b`

**Option text:** Zamanın geçmesini, güvenin oturmasını ve mantığımla da emin olmayı beklerim.

**Existing canonical weights:** `closeness_pace -2`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `closeness_pace -2`

**Reason:** Waiting for trust AND 'mantığımla da emin olmak' mixes slow closeness (already −2) with uncertainty intolerance. Adding uncertainty_tolerance −1 is tempting but not entailed; some people wait for trust without being low-UT.

**Confidence:** medium

### frequency_v2_q0034

**Question ID:** `frequency_v2_q0034`

**Question text:** Uzun süreli bir ilişkide telefon/bilgisayar şifreleri, mesajlaşmaların açıklığı konusunda ne düşünürsün?

**Context:** boundaries

**Draft primary:** `autonomy` · **Source primary raw:** `autonomy_need` · **Unresolved labels:** `baseline`

#### Option `frequency_v2_q0034_b`

**Option ID:** `frequency_v2_q0034_b`

**Option text:** Şifreleri bilebiliriz ama birbirimizin telefonunu kurcalamak aklımıza bile gelmez.

**Existing canonical weights:** `uncertainty_tolerance +1`

**Legacy/unknown weights:** `baseline +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `uncertainty_tolerance +1`

**Reason:** Legacy baseline+1 was 'trust as default' (we could know passwords but would not snoop). Trust/baseline is not a 12D. Keep uncertainty_tolerance +1 (living with access-without-use). Do not invent a trust dimension.

**Confidence:** high

### frequency_v2_q0035

**Question ID:** `frequency_v2_q0035`

**Question text:** Hayatında her şeyin üst üste geldiği, inanılmaz stresli bir dönemdesin. İlişkine nasıl yansır?

**Context:** support

**Draft primary:** `contact_need` · **Source primary raw:** `contact_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0035_b`

**Option ID:** `frequency_v2_q0035_b`

**Option text:** Kendi içime kapanır, sorunları çözene kadar biraz mesafeli ve sessiz kalırım.

**Existing canonical weights:** `autonomy +2`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `autonomy +2`

**Reason:** Withdrawing until problems are solved is already autonomy +2. processing_style+2 is 'I handle it in my head', not a second dimension.

**Confidence:** high

### frequency_v2_q0036

**Question ID:** `frequency_v2_q0036`

**Question text:** Önem verdiğin bir kutlama yemeğiniz var. Partnerin işten çok bitkin geldi ve "Gidemeyeceğim, halim yok" dedi.

**Context:** planning

**Draft primary:** `reassurance_need` · **Source primary raw:** `reassurance_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0036_b`

**Option ID:** `frequency_v2_q0036_b`

**Option text:** Çok üzülürüm ama belli etmemeye çalışarak ona dinlenmesi için ortam hazırlarım.

**Existing canonical weights:** `boundary_firmness -2`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `boundary_firmness -2`

**Reason:** Hiding disappointment and preparing rest is already boundary_firmness −2 (self-erasure). processing_style−1 is leftover affect.

**Confidence:** high

### frequency_v2_q0037

**Question ID:** `frequency_v2_q0037`

**Question text:** Gece uyumak üzeresin, çok yorgunsun. Partnerin aniden ilişkinizle ilgili derin ve ciddi bir konuyu açtı.

**Context:** conflict

**Draft primary:** `boundary_firmness` · **Source primary raw:** `boundary_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0037_a`

**Option ID:** `frequency_v2_q0037_a`

**Option text:** Uykumu böler, konu çözülene kadar saatlerce konuşurum. Çözmeden uyuyamam.

**Existing canonical weights:** `closeness_pace +1`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `CLEAR_REMAP`

**Proposed canonical weights:** `closeness_pace +1`, `repair_style +2`

**Reason:** Cannot sleep until the relationship topic is processed: this is immediate conflict processing, i.e. high repair_style. closeness_pace +1 (staying in the conversation) still fits.

**Confidence:** high

#### Option `frequency_v2_q0037_b`

**Option ID:** `frequency_v2_q0037_b`

**Option text:** "Bunu şimdi konuşmayalım, yarın sabah taze kafayla değerlendirelim" diyerek sınırı çekerim.

**Existing canonical weights:** `boundary_firmness +2`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `CLEAR_REMAP`

**Proposed canonical weights:** `boundary_firmness +2`, `repair_style -1`

**Reason:** Explicitly postponing the talk until morning is delayed repair plus a firm limit. Keep boundary_firmness +2; do not treat 'fresh head' as structure_preference.

**Confidence:** high

### frequency_v2_q0038

**Question ID:** `frequency_v2_q0038`

**Question text:** Sen çok düzenlisin, partnerin ise daha "dağınık" bir düzene sahip. Nasıl ilerlersiniz?

**Context:** established

**Draft primary:** `structure_preference` · **Source primary raw:** `structure_preference` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0038_d`

**Option ID:** `frequency_v2_q0038_d`

**Option text:** Zamanla ortada bir yerde buluşuruz, bu konuyu büyük bir çatışma haline getirmem.

**Existing canonical weights:** `uncertainty_tolerance +1`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `uncertainty_tolerance +1`

**Reason:** 'Zamanla ortada buluşuruz, çatışma haline getirmem' could be adaptability, avoidant repair, or genuine UT. Existing uncertainty_tolerance +1 is one reading; processing_style+1 should not auto-become structure or repair.

**Confidence:** low

### frequency_v2_q0043

**Question ID:** `frequency_v2_q0043`

**Question text:** Partnerin kariyeriyle ilgili çok riskli ve zor bir karar aşamasında ve sana danıştı.

**Context:** support

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0043_a`

**Option ID:** `frequency_v2_q0043_a`

**Option text:** Artıları, eksileri masaya yatırır, en rasyonel kararı alması için analitik bir tablo çizerim.

**Existing canonical weights:** `initiative +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `CLEAR_REMAP`

**Proposed canonical weights:** `initiative +1`, `structure_preference +1`

**Reason:** Building a plus/minus table for a career decision is structured problem-solving, not repair. Keep initiative +1 (taking the advisor role) and add structure_preference +1. Not +2: this is advice, not running the partner's life.

**Confidence:** medium

#### Option `frequency_v2_q0043_b`

**Option ID:** `frequency_v2_q0043_b`

**Option text:** "Senin içinden ne geçiyor? Seni ne mutlu edecek?" diyerek onun duygularına ayna tutarım.

**Existing canonical weights:** `closeness_pace +1`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `closeness_pace +1`

**Reason:** Mirroring 'what would make you happy' is already closeness_pace +1. processing_style−2 is the old emotional pole. This is support, not conflict repair.

**Confidence:** high

### frequency_v2_q0046

**Question ID:** `frequency_v2_q0046`

**Question text:** Partnerin gün ortasında "Akşam seninle bir konu hakkında konuşmam lazım" diye mesaj attı ve çevrimdışı oldu.

**Context:** unclassified

**Draft primary:** `uncertainty_tolerance` · **Source primary raw:** `uncertainty_tolerance` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0046_b`

**Option ID:** `frequency_v2_q0046_b`

**Option text:** Ne konuşacağını merak etsem de çok panik yapmam, akşama kadar konuyu rafa kaldırırım.

**Existing canonical weights:** `uncertainty_tolerance +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `uncertainty_tolerance +1`

**Reason:** Shelving the 'we need to talk' message until evening is already uncertainty_tolerance +1. processing_style+2 is cool-headedness, not a 12D.

**Confidence:** high

### frequency_v2_q0047

**Question ID:** `frequency_v2_q0047`

**Question text:** Evde birlikte önemli bir işi yetiştirirken bilgisayar/internet aniden kilitlendi ve veriler kayboldu.

**Context:** unclassified

**Draft primary:** (none) · **Source primary raw:** `conflict_approach` · **Unresolved labels:** `conflict_approach`, `processing_style`

#### Option `frequency_v2_q0047_a`

**Option ID:** `frequency_v2_q0047_a`

**Option text:** Hemen panik veya öfke yaşar, hissettiğim çaresizliği sesli şekilde dışa vururum.

**Existing canonical weights:** `uncertainty_tolerance -1`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `uncertainty_tolerance -1`

**Reason:** This is a technical crisis, not interpersonal conflict. Voicing panic is already uncertainty_tolerance −1. processing_style−2 and item-level conflict_approach are both the wrong construct. Not repair_style.

**Confidence:** high

#### Option `frequency_v2_q0047_b`

**Option ID:** `frequency_v2_q0047_b`

**Option text:** Sıfır duygu ile anında çözüm moduna geçer, teknik destek arar, plan B'yi uygularım.

**Existing canonical weights:** `initiative +2`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `initiative +2`

**Reason:** Zero-affect solution mode is already initiative +2. processing_style+2 is the rational pole of the same crisis item. conflict_approach must not be aliased to repair_style; there is no relational rupture.

**Confidence:** high

### frequency_v2_q0048

**Question ID:** `frequency_v2_q0048`

**Question text:** 1 yıllık ilişkide partnerin "İşim gereği 2 yıl başka bir şehirde yaşamam gerekebilir, benimle gelir misin?" dedi.

**Context:** unclassified

**Draft primary:** `adaptability` · **Source primary raw:** `rhythm_adaptation` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0048_c`

**Option ID:** `frequency_v2_q0048_c`

**Option text:** İyice düşünmek için zaman isterim, finansal, kariyer ve mantıksal tüm koşulları kağıda dökerim.

**Existing canonical weights:** `structure_preference +2`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +2`

**Reason:** Writing down financial/career conditions is already structure_preference +2. processing_style+2 is duplicate.

**Confidence:** high

### frequency_v2_q0049

**Question ID:** `frequency_v2_q0049`

**Question text:** Partnerinin sosyal medyada eski bir flörtünün fotoğraflarını beğendiğini gördün. Bu sende nasıl bir içsel tepki yaratır?

**Context:** uncertainty

**Draft primary:** `reassurance_need` · **Source primary raw:** `reassurance_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0049_c`

**Option ID:** `frequency_v2_q0049_c`

**Option text:** Rahatsız olurum ama olayı büyütmemek için kendimi tutar, dolaylı yoldan tavır yapabilirim.

**Existing canonical weights:** `disclosure_pace -1`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `disclosure_pace -1`

**Reason:** Holding back and maybe hinting is already disclosure_pace −1. processing_style−1 is not a second score.

**Confidence:** high

### frequency_v2_q0152

**Question ID:** `frequency_v2_q0152`

**Question text:** Flört dönemindesiniz. Partnerinin, eski sevgilisiyle sosyal medyada hala takipleştiğini fark ettin. İlk tepkin genelde ne olur?

**Context:** early_dating, uncertainty

**Draft primary:** `uncertainty_tolerance` · **Source primary raw:** `uncertainty_tolerance` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0152_b`

**Option ID:** `frequency_v2_q0152_b`

**Option text:** Biraz kafama takılır, güvenimi tazelemek için bana karşı olan ilgisini daha yakından gözlemlerim.

**Existing canonical weights:** `reassurance_need +1`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `reassurance_need +1`

**Reason:** Watching their interest more closely is already reassurance_need +1. processing_style+1 is rumination, not a 12D.

**Confidence:** high

### frequency_v2_q0154

**Question ID:** `frequency_v2_q0154`

**Question text:** Birlikte ilk kez 3 günlük bir tatile çıkacaksınız. Planlama süreci sence nasıl işlemeli?

**Context:** planning

**Draft primary:** `initiative` · **Source primary raw:** `initiative_tendency` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0154_b`

**Option ID:** `frequency_v2_q0154_b`

**Option text:** İkimiz boş bir akşamda bilgisayar başına oturup her adımı ortaklaşa ve eşit şekilde planlamalıyız.

**Existing canonical weights:** `closeness_pace +1`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `closeness_pace +1`

**Reason:** Planning the trip jointly is collaborative process. That could be low initiative (shared control), closeness, or structure. closeness_pace +1 is already odd for a logistics item. processing_style−1 has no unique 12D home.

**Confidence:** low

### frequency_v2_q0155

**Question ID:** `frequency_v2_q0155`

**Question text:** Partnerin ağır bir grip oldu ve evde yatıyor. Ona nasıl destek olmayı tercih edersin?

**Context:** support

**Draft primary:** `autonomy` · **Source primary raw:** `autonomy_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0155_b`

**Option ID:** `frequency_v2_q0155_b`

**Option text:** İhtiyaçlarını (ilaç, yemek) kapısına bırakır veya sipariş eder, ona dinlenmesi için yalnızlık tanırım.

**Existing canonical weights:** `autonomy +1`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `autonomy +1`

**Reason:** Leaving supplies at the door is already autonomy +1. processing_style+1 does not make this structure or repair.

**Confidence:** high

### frequency_v2_q0158

**Question ID:** `frequency_v2_q0158`

**Question text:** Partnerinin buluşmalara sürekli 15-20 dakika geç kalma huyu var. Bir süre sonra ne yaparsın?

**Context:** conflict

**Draft primary:** `boundary_firmness` · **Source primary raw:** `boundary_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0158_a`

**Option ID:** `frequency_v2_q0158_a`

**Option text:** "Beni bekletmen zamanıma saygısızlık hissettiriyor" diyerek net bir sınır çeker ve düzeltmesini isterim.

**Existing canonical weights:** `boundary_firmness +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `boundary_firmness +2`

**Reason:** Stating that lateness feels disrespectful is already boundary_firmness +2. processing_style+1 is redundant 'clear communication'.

**Confidence:** high

#### Option `frequency_v2_q0158_b`

**Option ID:** `frequency_v2_q0158_b`

**Option text:** Onu değiştirmeye çalışmak yerine, buluşmalara ben de bilerek biraz geç gitmeye başlarım.

**Existing canonical weights:** `adaptability +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `adaptability +1`

**Reason:** Arriving late on purpose is already adaptability +1 (matching their habit), arguably a cynical one. processing_style+2 is not a 12D.

**Confidence:** high

#### Option `frequency_v2_q0158_d`

**Option ID:** `frequency_v2_q0158_d`

**Option text:** Her geç kaldığında espriyle karışık laf sokar ama büyük bir kavgaya dönüştürmem.

**Existing canonical weights:** `disclosure_pace -1`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `disclosure_pace -1`

**Reason:** Joke-needling without a fight is already disclosure_pace −1. processing_style−1 is the same indirectness.

**Confidence:** high

### frequency_v2_q0160

**Question ID:** `frequency_v2_q0160`

**Question text:** Partnerin kendi evinde ilk defa gece kalıp sabah gittikten sonra, bilerek diş fırçasını ve tişörtünü banyoda bıraktığını fark ettin.

**Context:** early_dating, uncertainty

**Draft primary:** `closeness_pace` · **Source primary raw:** `closeness_pace` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0160_c`

**Option ID:** `frequency_v2_q0160_c`

**Option text:** Hiçbir anlam yüklemem, bir dahaki gelişinde rahat etmesi için pratik bir hareket olarak görürüm.

**Existing canonical weights:** `uncertainty_tolerance +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `uncertainty_tolerance +1`

**Reason:** Reading a left toothbrush as mere practicality is already uncertainty_tolerance +1. processing_style+2 is 'I don't over-interpret', not a 12D.

**Confidence:** high

### frequency_v2_q0162

**Question ID:** `frequency_v2_q0162`

**Question text:** Partnerin aylardır beklediği çok büyük bir terfiyi aldı ama şirket onu akşam ani bir kutlama yemeğine zorunlu tuttu. Sizin planınız iptal oldu.

**Context:** support

**Draft primary:** `reassurance_need` · **Source primary raw:** `reassurance_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0162_b`

**Option ID:** `frequency_v2_q0162_b`

**Option text:** Durumu tamamen mantıklı bulur, onun başarısına odaklanır, planı başka güne ertelerim.

**Existing canonical weights:** `uncertainty_tolerance +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `uncertainty_tolerance +1`

**Reason:** Finding the work dinner logically fine is already uncertainty_tolerance +1. processing_style+2 is the rational tag again.

**Confidence:** high

### frequency_v2_q0163

**Question ID:** `frequency_v2_q0163`

**Question text:** Sen iş yerinde berbat ve stresli bir gün geçirdin, partnerin ise harika haberler aldığı enerjik bir gün geçirdi. Akşam buluştunuz.

**Context:** support

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0163_b`

**Option ID:** `frequency_v2_q0163_b`

**Option text:** Önce kendi kötü günümü uzun uzun anlatıp deşarj olurum, sonra onun sevincini dinlerim.

**Existing canonical weights:** `boundary_firmness +1`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `boundary_firmness +1`

**Reason:** Dumping the bad day first then listening could be high disclosure, contact_need, or boundary (claiming airtime). boundary_firmness +1 is a questionable existing weight. processing_style−2 should not become repair_style; this is not a couple fight.

**Confidence:** medium

### frequency_v2_q0164

**Question ID:** `frequency_v2_q0164`

**Question text:** Partnerinden, normalde kullanmadığı kadar soğuk ve "İyi peki, sen bilirsin." şeklinde bir mesaj aldın.

**Context:** conflict

**Draft primary:** `uncertainty_tolerance` · **Source primary raw:** `uncertainty_tolerance` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0164_c`

**Option ID:** `frequency_v2_q0164_c`

**Option text:** Yazdığı şeyi harfi harfine doğru kabul eder, altında bir şey aramadan normal davranmaya devam ederim.

**Existing canonical weights:** `uncertainty_tolerance +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `uncertainty_tolerance +1`

**Reason:** Taking 'sen bilirsin' at face value is already uncertainty_tolerance +1. processing_style+2 is not a dimension.

**Confidence:** high

### frequency_v2_q0166

**Question ID:** `frequency_v2_q0166`

**Question text:** Arabada uzun yoldasınız ve bir konu yüzünden sesler yükseldi, kavga çıktı. İdeal çözüm yöntemin nedir?

**Context:** conflict

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0166_a`

**Option ID:** `frequency_v2_q0166_a`

**Option text:** Arabayı sağa çekip veya yola devam edip, konu tamamen tatlıya bağlanana kadar konuşmak.

**Existing canonical weights:** `closeness_pace +1`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `CLEAR_REMAP`

**Proposed canonical weights:** `closeness_pace +1`, `repair_style +2`

**Reason:** A car fight processed until it is resolved is immediate repair. closeness_pace +1 (staying in the interaction) remains reasonable.

**Confidence:** high

#### Option `frequency_v2_q0166_b`

**Option ID:** `frequency_v2_q0166_b`

**Option text:** Radyoyu açıp, sessizliğe bürünüp en az 1 saat kendi düşüncelerimle baş başa kalmak.

**Existing canonical weights:** `autonomy +2`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `CLEAR_REMAP`

**Proposed canonical weights:** `autonomy +2`, `repair_style -2`

**Reason:** Radio on, hour of silence after a fight is withdrawal from repair, not 'being analytical'. Keep autonomy +2.

**Confidence:** high

#### Option `frequency_v2_q0166_d`

**Option ID:** `frequency_v2_q0166_d`

**Option text:** Mantıklı argümanlarımı sonuna kadar sunmak ve onun nerede hatalı olduğunu netleştirmek.

**Existing canonical weights:** `boundary_firmness +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `boundary_firmness +2`

**Reason:** Arguing until the partner's error is proven is winning a fight, not repair, and not 'processing_style'. boundary_firmness +2 already captures standing one's ground. Adding initiative or negative repair_style would pick a theory we cannot defend from the wording alone.

**Confidence:** medium

### frequency_v2_q0167

**Question ID:** `frequency_v2_q0167`

**Question text:** Birlikte geçireceğiniz tek boş gününüz. Partnerin, yakın bir arkadaşının büyük bir krizi (örn: ayrılık) olduğunu ve onun yanına gitmesi gerektiğini söyledi.

**Context:** planning

**Draft primary:** `reassurance_need` · **Source primary raw:** `reassurance_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0167_d`

**Option ID:** `frequency_v2_q0167_d`

**Option text:** Arkadaşının krizinin gerçekten bizim günümüzü iptal etmeye değip değmeyeceğini biraz sorgularım.

**Existing canonical weights:** `boundary_firmness +2`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `boundary_firmness +2`

**Reason:** Questioning whether the friend's crisis warrants cancelling is already boundary_firmness +2. processing_style−1 is leftover affect.

**Confidence:** high

### frequency_v2_q0168

**Question ID:** `frequency_v2_q0168`

**Question text:** Sen hafta sonu sabah 8'de kalkıp güne başlamayı seviyorsun. Partnerin ise öğlen 1'e kadar uyumak istiyor.

**Context:** established

**Draft primary:** `adaptability` · **Source primary raw:** `rhythm_adaptation` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0168_c`

**Option ID:** `frequency_v2_q0168_c`

**Option text:** Ortak bir ritim bulmak için onun biraz daha erken, benim biraz daha geç kalkmamı teklif ederim.

**Existing canonical weights:** `structure_preference +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +2`

**Reason:** Proposing a shared wake time is already structure_preference +2. processing_style+1 is duplicate.

**Confidence:** high

### frequency_v2_q0169

**Question ID:** `frequency_v2_q0169`

**Question text:** Hayatındaki işler hiç yolunda gitmiyor. Partnerinin sana yaklaşımı nasıl olmalı?

**Context:** support

**Draft primary:** `contact_need` · **Source primary raw:** `contact_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0169_b`

**Option ID:** `frequency_v2_q0169_b`

**Option text:** Benim yerime pratik işlerimi (fatura ödemek, yemek yapmak) halledip omuzumdaki yükü almalı.

**Existing canonical weights:** `closeness_pace +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `REWRITE_REQUIRED`

**Proposed canonical weights:** `closeness_pace +1`

**Reason:** The stem asks how the partner should approach you, so this option scores a desired-care-language, not a respondent 12D act. processing_style+2 (instrumental help) cannot be remapped until the item is rewritten as 'what do YOU do'.

**Confidence:** high

### frequency_v2_q0170

**Question ID:** `frequency_v2_q0170`

**Question text:** Kötü bir tartışmadan sonra "Birkaç saat yalnız kalmaya ihtiyacım var" dedin. Ama partnerin konuyu çözmek için sürekli konuşmak istiyor.

**Context:** boundaries

**Draft primary:** `boundary_firmness` · **Source primary raw:** `boundary_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0170_c`

**Option ID:** `frequency_v2_q0170_c`

**Option text:** Konuşmasına izin veririm ama dinlemediğimi, sadece beklediğimi belli eden sessiz bir tavır alırım.

**Existing canonical weights:** `uncertainty_tolerance -1`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `uncertainty_tolerance -1`

**Reason:** Allowing talk while visibly not listening is blocked/passive-aggressive repair, low disclosure, or weak boundary. uncertainty_tolerance −1 is a poor existing fit. Needs a human call before any remap.

**Confidence:** low

#### Option `frequency_v2_q0170_d`

**Option ID:** `frequency_v2_q0170_d`

**Option text:** Mantıklı bir şekilde neden şu an konuşmanın zarar vereceğini açıklar, saat vererek (örn: "akşam konuşalım") sınırı çizerim.

**Existing canonical weights:** `structure_preference +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `CLEAR_REMAP`

**Proposed canonical weights:** `repair_style -1`, `structure_preference +1`

**Reason:** Explaining why talking now would harm, then time-boxing ('akşam konuşalım') is delayed, scheduled repair. Keep structure_preference +1. This is the rare processing_style+2 that is actually about post-conflict process, not IQ.

**Confidence:** high

### frequency_v2_q0171

**Question ID:** `frequency_v2_q0171`

**Question text:** Gittiğiniz bir mekanda barmenin/garsonun partnerine açıkça flörtöz davrandığını fark ettin. Partnerin ise sadece kibarca gülümsedi.

**Context:** uncertainty

**Draft primary:** `reassurance_need` · **Source primary raw:** `reassurance_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0171_d`

**Option ID:** `frequency_v2_q0171_d`

**Option text:** Mekandan çıktıktan sonra bunu partnerime şakayla karışık sorar, tepkisini ölçerim.

**Existing canonical weights:** `disclosure_pace -1`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `disclosure_pace -1`

**Reason:** Joke-asking after leaving the venue is already disclosure_pace −1. processing_style+1 is not repair (the conflict is with a bartender, not a rupture).

**Confidence:** high

### frequency_v2_q0172

**Question ID:** `frequency_v2_q0172`

**Question text:** Ortak yaşayacağınız eve eşya bakıyorsunuz. Seçim süreciniz genelde nasıldır?

**Context:** established

**Draft primary:** `structure_preference` · **Source primary raw:** `structure_preference` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0172_a`

**Option ID:** `frequency_v2_q0172_a`

**Option text:** Ne alacağımızı gitmeden önce listeler, ölçülerini alır, plana tamamen sadık kalarak hızlıca çıkarız.

**Existing canonical weights:** `structure_preference +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +2`

**Reason:** Pre-list, measure, stick to the plan is already structure_preference +2. processing_style+1 is duplicate.

**Confidence:** high

### frequency_v2_q0173

**Question ID:** `frequency_v2_q0173`

**Question text:** Partnerin yıllardır çalıştığı garantili işinden istifa edip, riskli bir girişim kurmak istediğini söyledi.

**Context:** planning

**Draft primary:** `uncertainty_tolerance` · **Source primary raw:** `uncertainty_tolerance` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0173_c`

**Option ID:** `frequency_v2_q0173_c`

**Option text:** Çok endişelenirim ama hevesini kırmamak için endişemi içimde yaşar, ona yansıtmam.

**Existing canonical weights:** `disclosure_pace -2`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `disclosure_pace -2`

**Reason:** Hiding worry to protect their enthusiasm is already disclosure_pace −2. processing_style−1 is affect.

**Confidence:** high

### frequency_v2_q0174

**Question ID:** `frequency_v2_q0174`

**Question text:** Partnerin çok istediği için bir köpek sahiplendiniz. Ancak sabah yürüyüşleri çoğunlukla sana kalmaya başladı.

**Context:** established

**Draft primary:** `boundary_firmness` · **Source primary raw:** `boundary_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0174_a`

**Option ID:** `frequency_v2_q0174_a`

**Option text:** "Bunu sen istedin, sorumluluk da senin" diyerek net bir şekilde yürüyüşleri yapmayı reddederim.

**Existing canonical weights:** `boundary_firmness +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `boundary_firmness +2`

**Reason:** Refusing the walks they asked for is already boundary_firmness +2. processing_style+1 is redundant.

**Confidence:** high

#### Option `frequency_v2_q0174_d`

**Option ID:** `frequency_v2_q0174_d`

**Option text:** Konuyu ara sıra şakaya vurarak ona sorumluluğunu hatırlatmaya çalışırım ama kriz çıkarmam.

**Existing canonical weights:** `disclosure_pace -1`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `disclosure_pace -1`

**Reason:** Joke reminders without a crisis is already disclosure_pace −1. processing_style−1 is the same indirectness.

**Confidence:** high

### frequency_v2_q0176

**Question ID:** `frequency_v2_q0176`

**Question text:** Partnerin bir belgesel izledi ve o günden sonra tamamen vegan/çok sıkı bir diyete geçmeye karar verdi.

**Context:** established

**Draft primary:** `adaptability` · **Source primary raw:** `rhythm_adaptation` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0176_d`

**Option ID:** `frequency_v2_q0176_d`

**Option text:** Ne kadar sürdürebileceğini görmek için önce uzaktan izler, sonra duruma göre şekil alırım.

**Existing canonical weights:** `disclosure_pace -1`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `disclosure_pace -1`

**Reason:** Wait-and-see whether the vegan diet lasts is already disclosure_pace −1. processing_style+1 is not adaptability (that would be joining the diet).

**Confidence:** high

### frequency_v2_q0177

**Question ID:** `frequency_v2_q0177`

**Question text:** Bedensel veya psikolojik derin bir özgüvensizliğini partnerinle nasıl paylaşırsın?

**Context:** early_dating, uncertainty

**Draft primary:** `disclosure_pace` · **Source primary raw:** `disclosure_pace` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0177_d`

**Option ID:** `frequency_v2_q0177_d`

**Option text:** Bunu çok rasyonel bir bilgi verir gibi, dramatize etmeden kısa ve net bir şekilde açıklarım.

**Existing canonical weights:** `closeness_pace -1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `closeness_pace -1`

**Reason:** Disclosing an insecurity in a dry, undramatic way is already closeness_pace −1. processing_style+2 is tone, not a 12D. Do not add disclosure_pace without a human pass on valence.

**Confidence:** high

### frequency_v2_q0178

**Question ID:** `frequency_v2_q0178`

**Question text:** Arabada 40 dakikalık bir yoldasınız. Partnerin radyoyu kapattı, yola bakıyor ve hiç konuşmuyor.

**Context:** established

**Draft primary:** `contact_need` · **Source primary raw:** `contact_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0178_c`

**Option ID:** `frequency_v2_q0178_c`

**Option text:** Sıkılırım, müziği tekrar açar veya komik bir konu açarak havayı canlandırmaya çalışırım.

**Existing canonical weights:** `social_energy +1`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `social_energy +1`

**Reason:** Breaking car silence with music or a joke is already social_energy +1. processing_style−1 is not a second dimension.

**Confidence:** high

### frequency_v2_q0180

**Question ID:** `frequency_v2_q0180`

**Question text:** İkinizi de etkileyen ortak bir maddi kayıp (örn: yanlış bir yatırım veya yüksek bir trafik cezası) yaşandı.

**Context:** support

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0180_a`

**Option ID:** `frequency_v2_q0180_a`

**Option text:** Suçlunun kim olduğuna odaklanmadan hemen zararı nasıl kapatacağımızın matematiksel planını yaparım.

**Existing canonical weights:** `structure_preference +2`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +2`

**Reason:** Math plan to close a shared loss is already structure_preference +2. processing_style+2 is duplicate. Not repair unless the loss is framed as a couple fight, which it is not.

**Confidence:** high

#### Option `frequency_v2_q0180_b`

**Option ID:** `frequency_v2_q0180_b`

**Option text:** Çok üzülür, moral bozukluğumu günlerce üzerimden atamam, onun beni teselli etmesini beklerim.

**Existing canonical weights:** `reassurance_need +1`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `reassurance_need +1`

**Reason:** Days of morale collapse waiting for comfort is already reassurance_need +1. processing_style−2 is affect.

**Confidence:** high

### frequency_v2_q0181

**Question ID:** `frequency_v2_q0181`

**Question text:** Daha 2. aydasınız. Partnerin bir sohbet sırasında "Gelecekteki çocuklarımıza şu ismi koyarız" diye bir espri yaptı.

**Context:** early_dating

**Draft primary:** `closeness_pace` · **Source primary raw:** `closeness_pace` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0181_c`

**Option ID:** `frequency_v2_q0181_c`

**Option text:** Ben de espriyle karşılık veririm ama içten içe "daha çok erken" diye durumu tartar, not alırım.

**Existing canonical weights:** `uncertainty_tolerance +1`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `uncertainty_tolerance +1`

**Reason:** Joking back while privately noting 'too early' is already uncertainty_tolerance +1. processing_style+1 is internal appraisal, not a 12D act.

**Confidence:** high

### frequency_v2_q0182

**Question ID:** `frequency_v2_q0182`

**Question text:** Cuma öğleden sonra. Partnerin iş yerine geldi ve "Çantana iki parça eşya koy, 1 saat sonra uçağımız var, hafta sonu gidiyoruz!" dedi.

**Context:** unclassified

**Draft primary:** `structure_preference` · **Source primary raw:** `structure_preference` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0182_d`

**Option ID:** `frequency_v2_q0182_d`

**Option text:** Hemen organize olup çantayı hazırlarım, o ne derse uyum sağlamak bana zor gelmez.

**Existing canonical weights:** `adaptability +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `adaptability +2`

**Reason:** Packing immediately for a surprise trip is already adaptability +2. processing_style+1 is 'I can organize fast', not extra structure.

**Confidence:** high

### frequency_v2_q0183

**Question ID:** `frequency_v2_q0183`

**Question text:** Sen ağlayarak veya çok sinirli bir şekilde bir derdini anlatırken, partnerin sürekli "Şöyle yapmalısın, şurayı ara" diye çözümler sunuyor.

**Context:** support

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0183_a`

**Option ID:** `frequency_v2_q0183_a`

**Option text:** Bana akıl vermesi değil, sadece "çok haklısın, ne kadar üzücü" demesi gerektiği için sinirlenirim.

**Existing canonical weights:** `reassurance_need +1`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `reassurance_need +1`

**Reason:** Anger that the partner offered solutions rather than validation is a support-language preference. It is not the respondent's repair_style. reassurance_need +1 fits; processing_style−2 should not be copied onto repair_style.

**Confidence:** medium

#### Option `frequency_v2_q0183_b`

**Option ID:** `frequency_v2_q0183_b`

**Option text:** Onun beni önemseme şeklinin bu olduğunu anlar, verdiği tavsiyeleri mantık süzgecinden geçiririm.

**Existing canonical weights:** `boundary_firmness -1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `boundary_firmness -1`

**Reason:** Treating unsolicited advice as care and filtering it logically could be adaptability, low boundary, or nothing 12D. boundary_firmness −1 is thin. Do not map to structure_preference.

**Confidence:** low

### frequency_v2_q0184

**Question ID:** `frequency_v2_q0184`

**Question text:** Partnerin çok yoğun bir sınava/projeye hazırlanıyor ve "Bu ay hafta sonları görüşemeyebiliriz, ders çalışmalıyım" dedi.

**Context:** unclassified

**Draft primary:** `autonomy` · **Source primary raw:** `autonomy_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0184_c`

**Option ID:** `frequency_v2_q0184_c`

**Option text:** Geleceği için yapması gereken buysa, kurallara tam olarak uyar ve onu motive ederim.

**Existing canonical weights:** `structure_preference +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +2`

**Reason:** Fully honoring their exam-month rule is already structure_preference +2. processing_style+1 is duplicate.

**Confidence:** high

### frequency_v2_q0185

**Question ID:** `frequency_v2_q0185`

**Question text:** En güvendiğin arkadaşın, partnerinin sana pek uygun olmadığını ve sana iyi gelmediğini düşündüğünü söyledi.

**Context:** social

**Draft primary:** `boundary_firmness` · **Source primary raw:** `boundary_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0185_b`

**Option ID:** `frequency_v2_q0185_b`

**Option text:** Arkadaşımın dışarıdan gördüğü ve benim göremediğim bir şey olabilir diye bunu ciddiye alır, analiz ederim.

**Existing canonical weights:** `boundary_firmness -1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `boundary_firmness -1`

**Reason:** Taking a friend's warning seriously and 'analyzing' it could be uncertainty, low boundary, or healthy reality-testing. processing_style+2 is the old rational tag and is not a 12D.

**Confidence:** low

### frequency_v2_q0186

**Question ID:** `frequency_v2_q0186`

**Question text:** Büyük bir kavgada bağırdın, çağırdın. Ancak 10 dakika sonra aslında tamamen *senin haksız olduğunu* fark ettin.

**Context:** conflict

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0186_b`

**Option ID:** `frequency_v2_q0186_b`

**Option text:** Anında yanına gider, gurur yapmadan "Ben yanlış anlamışım, çok özür dilerim" derim.

**Existing canonical weights:** `boundary_firmness -1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `CLEAR_REMAP`

**Proposed canonical weights:** `boundary_firmness -1`, `repair_style +2`

**Reason:** Immediate full apology after realizing they were wrong is high repair_style. Keep boundary_firmness −1 (dropping the defensive stance). processing_style+2 here was mis-tagged; the behavior is repair, not analysis.

**Confidence:** high

#### Option `frequency_v2_q0186_d`

**Option ID:** `frequency_v2_q0186_d`

**Option text:** Haklı olduğu tarafları kabul etsem de, benim o tepkiyi vermeme neden olan "onun" hatasını da masaya sürerim.

**Existing canonical weights:** `boundary_firmness +2`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `boundary_firmness +2`

**Reason:** Apologizing for being wrong AND putting the partner's contribution on the table is mixed repair and score-keeping. boundary_firmness +2 already exists. Choosing repair_style +1 vs 0 vs −1 is a judgment call.

**Confidence:** medium

### frequency_v2_q0187

**Question ID:** `frequency_v2_q0187`

**Question text:** Akşam birlikte film izliyorsunuz ama partnerin sürekli telefonuyla oynuyor, gülümsüyor, birilerine yazıyor.

**Context:** boundaries

**Draft primary:** `contact_need` · **Source primary raw:** `contact_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0187_d`

**Option ID:** `frequency_v2_q0187_d`

**Option text:** Ben de kendi telefonumu elime alır, kendi dijital dünyama dalarım.

**Existing canonical weights:** `adaptability +1`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `adaptability +1`

**Reason:** Picking up one's own phone to match is already adaptability +1. processing_style+1 is not autonomy (that is option B).

**Confidence:** high

### frequency_v2_q0190

**Question ID:** `frequency_v2_q0190`

**Question text:** Hafta sonu öğlen mesaj attın, görüldü oldu ama partnerin tam 6 saat boyunca cevap vermedi.

**Context:** unclassified

**Draft primary:** `uncertainty_tolerance` · **Source primary raw:** `uncertainty_tolerance` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0190_c`

**Option ID:** `frequency_v2_q0190_c`

**Option text:** Görüldü atıp bırakmasına sinirlenir, o yazana kadar ben de asla yazmama kararı alırım.

**Existing canonical weights:** `boundary_firmness +1`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `boundary_firmness +1`

**Reason:** Refusing to write until they write is already boundary_firmness +1. processing_style−1 is leftover affect.

**Confidence:** high

### frequency_v2_q0191

**Question ID:** `frequency_v2_q0191`

**Question text:** Bir ilişkide kendini en güvende hissettiğin an hangisidir?

**Context:** established

**Draft primary:** `reassurance_need` · **Source primary raw:** `reassurance_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0191_b`

**Option ID:** `frequency_v2_q0191_b`

**Option text:** Birlikte yan yana sessizce oturup, kelimelere ihtiyaç duymadan anlaştığımız an.

**Existing canonical weights:** `closeness_pace +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `REWRITE_REQUIRED`

**Proposed canonical weights:** `closeness_pace +2`

**Reason:** The stem is a feeling ('en güvende hissettiğin an'), not a behavior. Silent side-by-side ease is closeness, but processing_style+1 has nothing defensible to map until the question asks for an act.

**Confidence:** high

### frequency_v2_q0192

**Question ID:** `frequency_v2_q0192`

**Question text:** Partnerin hiç beklemediğin bir anda, çok küçük bir sebepten dolayı sinirleri bozulup ağlamaya başladı.

**Context:** support

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0192_a`

**Option ID:** `frequency_v2_q0192_a`

**Option text:** Hemen sarılır, onunla beraber duyguya girer, sakinleşene kadar fiziksel temas kurarım.

**Existing canonical weights:** `closeness_pace +2`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `closeness_pace +2`

**Reason:** Joining the crying with touch is already closeness_pace +2. This is support, not couple-conflict repair. Drop processing_style−1.

**Confidence:** high

#### Option `frequency_v2_q0192_b`

**Option ID:** `frequency_v2_q0192_b`

**Option text:** Sakin ve şefkatli kalır, "Buna bu kadar üzülmenin asıl sebebi ne?" diye sorarak kök sorunu anlamaya çalışırım.

**Existing canonical weights:** `initiative +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `initiative +1`

**Reason:** Asking for the root cause of sudden tears could be initiative, structure, closeness, or unhelpful psychologizing. Not repair_style (no couple rupture). initiative +1 is one reading; processing_style+2 should not auto-add structure_preference.

**Confidence:** medium

### frequency_v2_q0193

**Question ID:** `frequency_v2_q0193`

**Question text:** Doğum gününde partnerin sana hiç tarzın olmayan, belli ki özenmeden seçilmiş veya yanlış anlaşılmış bir hediye aldı.

**Context:** established

**Draft primary:** `disclosure_pace` · **Source primary raw:** `disclosure_pace` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0193_c`

**Option ID:** `frequency_v2_q0193_c`

**Option text:** O an mutlu görünürüm ama sonrasında günlerce içten içe "beni hiç tanımamış" diye üzülürüm.

**Existing canonical weights:** `reassurance_need +1`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `REWRITE_REQUIRED`

**Proposed canonical weights:** `reassurance_need +1`

**Reason:** The option is purely internal ('günlerce içten içe üzülürüm') with no observable act. processing_style−2 is affect, not a 12D. Needs a behavioral tell (withdrawal, hinting, later confrontation) before scoring.

**Confidence:** medium

#### Option `frequency_v2_q0193_d`

**Option ID:** `frequency_v2_q0193_d`

**Option text:** Şakaya vurarak "Bunu cidden bana mı aldın?" der, durumu yumuşatarak fikrimi belli ederim.

**Existing canonical weights:** `uncertainty_tolerance +1`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `uncertainty_tolerance +1`

**Reason:** Joke-softening a bad gift is already uncertainty_tolerance +1. processing_style+1 is tone, not a 12D.

**Confidence:** high

### frequency_v2_q0195

**Question ID:** `frequency_v2_q0195`

**Question text:** Partnerinin telefonunda şüpheli bir mesaj bildirimi gördün (ekran kilitli).

**Context:** uncertainty

**Draft primary:** `uncertainty_tolerance` · **Source primary raw:** `uncertainty_tolerance` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0195_c`

**Option ID:** `frequency_v2_q0195_c`

**Option text:** Kendime hakim olur, telefonu kurcalamanın sınırı aşmak olduğuna inandığım için bakmam.

**Existing canonical weights:** `boundary_firmness +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `boundary_firmness +2`

**Reason:** Not snooping because it would cross a line is already boundary_firmness +2. processing_style+1 is self-control/rationalization, not a second 12D. Could also be read as uncertainty_tolerance +1 (living with not knowing).

**Confidence:** low

#### Option `frequency_v2_q0195_d`

**Option ID:** `frequency_v2_q0195_d`

**Option text:** Mesajın devamı gelecek mi veya davranışlarında bir tuhaflık var mı diye günlerce uzaktan izlerim.

**Existing canonical weights:** `uncertainty_tolerance +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `uncertainty_tolerance +1`

**Reason:** Days of distal watching after a notification could be low UT (cannot let it go), high UT (does not confront), reassurance_need, or a surveillance item that should not be in Frequency at all. Existing uncertainty_tolerance +1 points the wrong way if this is rumination.

**Confidence:** low

### frequency_v2_q0198

**Question ID:** `frequency_v2_q0198`

**Question text:** Partnerin o gün nedensiz yere çok huysuz, her şeye itiraz ediyor ve negatif bir enerji yayıyor.

**Context:** support

**Draft primary:** `adaptability` · **Source primary raw:** `rhythm_adaptation` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0198_a`

**Option ID:** `frequency_v2_q0198_a`

**Option text:** Bu negatiflik bana da geçer, ben de sinirlenmeye ve ona sert tepkiler vermeye başlarım.

**Existing canonical weights:** `adaptability +1`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `adaptability +1`

**Reason:** Catching the partner's irritability is emotional contagion. adaptability +1 is an awkward existing score (matching by getting worse). processing_style−2 is not a 12D. Could be low adaptability instead.

**Confidence:** low

### frequency_v2_q0199

**Question ID:** `frequency_v2_q0199`

**Question text:** Henüz tanışma aşamasındasınız. Partnerin sürekli eski anılarından, lise yıllarından ve çocukluğundan bahsediyor.

**Context:** early_dating

**Draft primary:** `disclosure_pace` · **Source primary raw:** `disclosure_pace` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0199_c`

**Option ID:** `frequency_v2_q0199_c`

**Option text:** Geçmişe bu kadar odaklanması beni sıkar, şu anki hayata ve geleceğe odaklanmayı tercih ederim.

**Existing canonical weights:** `structure_preference +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +1`

**Reason:** Preferring present/future over childhood stories is already structure_preference +1 (a stretch, but present). processing_style+2 is 'I don't do nostalgia', not a new dimension.

**Confidence:** high

### frequency_v2_q0200

**Question ID:** `frequency_v2_q0200`

**Question text:** Partnerin, senin giyim tarzın veya saç şeklinle ilgili "Şöyle yapsan sana daha çok yakışır" diye ısrarlı bir öneride bulunuyor.

**Context:** established

**Draft primary:** `boundary_firmness` · **Source primary raw:** `boundary_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0200_d`

**Option ID:** `frequency_v2_q0200_d`

**Option text:** Eleştiriyi mantıklı bulursam uygularım, ama tamamen o istiyor diye tarzımı değiştirmem.

**Existing canonical weights:** `autonomy +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `autonomy +1`

**Reason:** Changing style only if the critique is logical is already autonomy +1. The logic filter is processing_style coloring, not a 12D.

**Confidence:** high

### frequency_v2_q0208

**Question ID:** `frequency_v2_q0208`

**Question text:** Birlikte bir akşam yemeğine gittiniz. Hesap geldiğinde partneriniz “ben bakayım” diyor.

**Context:** early_dating

**Draft primary:** `autonomy`, `structure_preference` · **Source primary raw:** `autonomy`, `structure_preference` · **Unresolved labels:** `reciprocity`

#### Option `frequency_v2_q0208_c`

**Option ID:** `frequency_v2_q0208_c`

**Option text:** “Bu sefer sen, sonra ben” derim.

**Existing canonical weights:** `structure_preference +1`

**Legacy/unknown weights:** `reciprocity +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +1`

**Reason:** Legacy reciprocity+1 ('bu sefer sen, sonra ben') is turn-taking as a rule. Reciprocity is not a 12D. Keep structure_preference +1. Do not invent a fairness dimension.

**Confidence:** high

### frequency_v2_q0252

**Question ID:** `frequency_v2_q0252`

**Question text:** Partnerin evdeyken senin için manevi değeri çok yüksek olan bir eşyayı (örn: eski bir vazo/kupa) yanlışlıkla kırdı.

**Context:** conflict

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0252_a`

**Option ID:** `frequency_v2_q0252_a`

**Option text:** O anki refleksimle sinirlendiğimi belli ederim ama sonrasında toparlayıp affederim.

**Existing canonical weights:** `disclosure_pace +1`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `CLEAR_REMAP`

**Proposed canonical weights:** `disclosure_pace +1`, `repair_style +1`

**Reason:** Show irritation then forgive after a broken object: short repair cycle. Keep disclosure_pace +1 (the irritation is shown). Not +2: this is a flash-and-forgive, not a repair method.

**Confidence:** medium

#### Option `frequency_v2_q0252_c`

**Option ID:** `frequency_v2_q0252_c`

**Option text:** Neden dikkat etmediğini sorgular, içsel bir kızgınlık yaşar ama tartışmamak için sessiz kalırım.

**Existing canonical weights:** `boundary_firmness +1`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `boundary_firmness +1`

**Reason:** Questioning carelessness then staying silently angry mixes boundary, low disclosure, and unfinished repair. boundary_firmness +1 is only partly right. No clean remap.

**Confidence:** low

#### Option `frequency_v2_q0252_d`

**Option ID:** `frequency_v2_q0252_d`

**Option text:** Mantıklı bir şekilde "Olan oldu" der, sadece parçaları hızlıca temizlemeye odaklanırım.

**Existing canonical weights:** `uncertainty_tolerance +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `uncertainty_tolerance +1`

**Reason:** 'Olan oldu' and cleaning up is already uncertainty_tolerance +1. processing_style+2 is cool instrumentalism, not structure (no plan is described).

**Confidence:** high

### frequency_v2_q0253

**Question ID:** `frequency_v2_q0253`

**Question text:** İkinizin de çok sevdiği ortak bir diziye başladınız. Sen çok merak ediyorsun ama onun o gece izleyecek hali yok.

**Context:** established

**Draft primary:** `autonomy` · **Source primary raw:** `autonomy_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0253_d`

**Option ID:** `frequency_v2_q0253_d`

**Option text:** Ortak bir zaman yaratmak için "Peki ne zaman izleriz?" diye net bir gün belirlemeye çalışırım.

**Existing canonical weights:** `structure_preference +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +2`

**Reason:** Booking a night to watch together is already structure_preference +2. processing_style+1 is duplicate.

**Confidence:** high

### frequency_v2_q0255

**Question ID:** `frequency_v2_q0255`

**Question text:** Çok heves ettiğiniz bir etkinliğe (örn: konser/tiyatro) giderken berbat bir trafiğe yakalandınız ve yetişemeyeceğiniz kesinleşti.

**Context:** support

**Draft primary:** `uncertainty_tolerance` · **Source primary raw:** `uncertainty_tolerance` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0255_a`

**Option ID:** `frequency_v2_q0255_a`

**Option text:** Arabada sinir krizleri geçirir, isyan eder, o akşamın tüm enerjisini düşürürüm.

**Existing canonical weights:** `uncertainty_tolerance -2`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `uncertainty_tolerance -2`

**Reason:** Traffic tantrum is already uncertainty_tolerance −2. processing_style−2 is the same affect. Not repair.

**Confidence:** high

#### Option `frequency_v2_q0255_b`

**Option ID:** `frequency_v2_q0255_b`

**Option text:** Bilet yandı diye üzülürüm ama hemen "Madem öyle, şurada yemek yiyelim" diyerek yeni plan yaparım.

**Existing canonical weights:** `initiative +2`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `initiative +2`

**Reason:** Immediately proposing dinner instead is already initiative +2. processing_style+2 is duplicate problem-solving.

**Confidence:** high

### frequency_v2_q0256

**Question ID:** `frequency_v2_q0256`

**Question text:** Partnerine bir hediye aldın ama paketi açtığında yüzündeki yarım saniyelik ifadeden aslında hiç beğenmediğini anladın.

**Context:** early_dating, uncertainty

**Draft primary:** `disclosure_pace` · **Source primary raw:** `disclosure_pace` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0256_c`

**Option ID:** `frequency_v2_q0256_c`

**Option text:** "İstersen değiştirebiliriz, fişi bende" diyerek pratik ve rasyonel bir çözüm sunarım.

**Existing canonical weights:** `boundary_firmness +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `boundary_firmness +1`

**Reason:** Offering to exchange the gift with the receipt is practical problem-solving. Could be initiative, structure, or low closeness (skipping the feeling). boundary_firmness +1 is a weak existing fit. Not repair.

**Confidence:** medium

### frequency_v2_q0258

**Question ID:** `frequency_v2_q0258`

**Question text:** Çok severek okuduğun derin bir kitabı/makaleyi partnerinle paylaştın ama o "Çok sıkıcıymış" deyip kestirip attı.

**Context:** established

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0258_b`

**Option ID:** `frequency_v2_q0258_b`

**Option text:** Anlaması için kitabın/makalenin ana fikrini farklı bir yolla ona açıklamaya çabalarım.

**Existing canonical weights:** `initiative +1`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `initiative +1`

**Reason:** Re-explaining a dismissed book is already initiative +1. processing_style+1 is the same persistence.

**Confidence:** high

### frequency_v2_q0259

**Question ID:** `frequency_v2_q0259`

**Question text:** Sabah uyandığınızda güne başlama rutinin nasıldır?

**Context:** established

**Draft primary:** `contact_need` · **Source primary raw:** `contact_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0259_d`

**Option ID:** `frequency_v2_q0259_d`

**Option text:** Yataktan hızlıca kalkıp işe/güne hazırlanmaya başlarım, romantik rutinlere pek vakit ayırmam.

**Existing canonical weights:** `structure_preference +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +2`

**Reason:** Getting up into the day with little morning romance is already structure_preference +2. processing_style+1 is task-orientation coloring.

**Confidence:** high

### frequency_v2_q0260

**Question ID:** `frequency_v2_q0260`

**Question text:** Senin yakın bir arkadaşın, partnerinle evdeyken aniden "Aşağıdayım, kahveye geliyorum" dedi. Partnerinin üstü başı dağınık.

**Context:** boundaries

**Draft primary:** `boundary_firmness` · **Source primary raw:** `boundary_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0260_c`

**Option ID:** `frequency_v2_q0260_c`

**Option text:** Partnerime panikle "Arkadaşım geliyor, çabuk toparlan" diyerek ortamı hızlıca düzenlerim.

**Existing canonical weights:** `structure_preference +1`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +1`

**Reason:** Panic-tidying before a friend arrives is already structure_preference +1. processing_style−1 is leftover affect.

**Confidence:** high

#### Option `frequency_v2_q0260_d`

**Option ID:** `frequency_v2_q0260_d`

**Option text:** Partnerime "İstersen sen odada takıl, biz salonda otururuz" diyerek ona kaçış alanı sunarım.

**Existing canonical weights:** `autonomy +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `autonomy +2`

**Reason:** Offering the partner an escape room is already autonomy +2. processing_style+1 is not a second score.

**Confidence:** high

### frequency_v2_q0261

**Question ID:** `frequency_v2_q0261`

**Question text:** İkiniz arasında ufak bir yanlış anlaşılma oldu. Partnerin olayı sana uzun uzun, detaylıca ve kendini sürekli savunarak açıklamaya çalışıyor.

**Context:** conflict

**Draft primary:** `disclosure_pace` · **Source primary raw:** `disclosure_pace` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0261_a`

**Option ID:** `frequency_v2_q0261_a`

**Option text:** "Anladım, sorun yok" diyerek onu hızlıca durdurur ve konuyu kestirip atarım.

**Existing canonical weights:** `contact_need -1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `CLEAR_REMAP`

**Proposed canonical weights:** `contact_need -1`, `repair_style -2`

**Reason:** Cutting off the partner's processing of a misunderstanding is avoidant repair. contact_need −1 is weak but still describes wanting the interaction over; do not inflate it. processing_style+2 was 'shut it down rationally' and should not become structure_preference.

**Confidence:** medium

#### Option `frequency_v2_q0261_c`

**Option ID:** `frequency_v2_q0261_c`

**Option text:** O kendini açıklarken ben de olayın bana hissettirdiklerini aynı uzunlukta anlatma ihtiyacı duyarım.

**Existing canonical weights:** `disclosure_pace +2`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `disclosure_pace +2`

**Reason:** Matching a long explanation with one's own feelings is already disclosure_pace +2. processing_style−1 is affect vs reason again.

**Confidence:** high

### frequency_v2_q0262

**Question ID:** `frequency_v2_q0262`

**Question text:** İş yerinden beklenmedik, yüklü bir prim/bonus aldın. Henüz ilişkinin 4. ayındasınız.

**Context:** uncertainty

**Draft primary:** `disclosure_pace` · **Source primary raw:** `disclosure_pace` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0262_d`

**Option ID:** `frequency_v2_q0262_d`

**Option text:** Gelecek buluşmada ona güzel bir ısmarlama yapar, "İşler iyi gitti" der konuyu kapatırım.

**Existing canonical weights:** `initiative +1`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `initiative +1`

**Reason:** Treating them to a meal and saying work went well is already initiative +1. processing_style+1 is not disclosure (the amount is still hidden).

**Confidence:** high

### frequency_v2_q0263

**Question ID:** `frequency_v2_q0263`

**Question text:** Birlikte çalışırken/otururken, partnerinin yaptığı sürekli ve ritmik bir ses (örn: kalem tıklatmak, ayak sallamak) seni inanılmaz irite etti.

**Context:** established

**Draft primary:** `boundary_firmness` · **Source primary raw:** `boundary_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0263_a`

**Option ID:** `frequency_v2_q0263_a`

**Option text:** Rahatsız olduğumu anında ve kibar bir dille söyleyip durmasını isterim.

**Existing canonical weights:** `boundary_firmness +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `boundary_firmness +2`

**Reason:** Asking them to stop clicking a pen is already boundary_firmness +2. processing_style+1 is redundant.

**Confidence:** high

#### Option `frequency_v2_q0263_c`

**Option ID:** `frequency_v2_q0263_c`

**Option text:** Şakayla karışık veya abartılı bir mimikle (örn: oflayarak) rahatsız olduğumu dolaylı yoldan belli ederim.

**Existing canonical weights:** `disclosure_pace -1`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `disclosure_pace -1`

**Reason:** Joke or exaggerated sigh is already disclosure_pace −1. processing_style−1 is the same indirectness.

**Confidence:** high

### frequency_v2_q0264

**Question ID:** `frequency_v2_q0264`

**Question text:** Kendi hayatınla ilgili çok kötü bir haber aldın. Partnerine bu haberi nasıl verirsin?

**Context:** support

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0264_a`

**Option ID:** `frequency_v2_q0264_a`

**Option text:** Olayın şokuyla hemen onu arar, ağlayarak veya panik içinde anlatırım.

**Existing canonical weights:** `reassurance_need +2`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `reassurance_need +2`

**Reason:** Immediate crying call with bad news is already reassurance_need +2. processing_style−2 is affect, not repair (no couple rupture).

**Confidence:** high

#### Option `frequency_v2_q0264_b`

**Option ID:** `frequency_v2_q0264_b`

**Option text:** Önce kendi içimde olayı sindirir, ne yapacağımı planlar, ona sadece "son durumu" bildiririm.

**Existing canonical weights:** `autonomy +2`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `autonomy +2`

**Reason:** Digest internally, plan, then report the outcome could be autonomy (already +2), structure_preference, or delayed disclosure. Adding structure would double-count the same 'I handle it alone' story.

**Confidence:** medium

### frequency_v2_q0266

**Question ID:** `frequency_v2_q0266`

**Question text:** Partnerin, o gün yapması gereken ve senin için de önemli olan basit bir evrak işini unuttu.

**Context:** planning

**Draft primary:** `structure_preference` · **Source primary raw:** `structure_preference` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0266_b`

**Option ID:** `frequency_v2_q0266_b`

**Option text:** Kızsam da "Tamam ben hallederim" diyerek işi ondan alır ve hızla kendim çözerim.

**Existing canonical weights:** `initiative +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `initiative +2`

**Reason:** Taking the forgotten errand and doing it is already initiative +2. processing_style+1 is duplicate.

**Confidence:** high

#### Option `frequency_v2_q0266_d`

**Option ID:** `frequency_v2_q0266_d`

**Option text:** Kendisini kötü hissetmesin diye "Olur öyle, çok yoğundun zaten" diyerek onu teselli ederim.

**Existing canonical weights:** `adaptability +2`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `adaptability +2`

**Reason:** Consoling them about the forgotten errand is already adaptability +2. processing_style−1 is affect.

**Confidence:** high

### frequency_v2_q0267

**Question ID:** `frequency_v2_q0267`

**Question text:** İlişkinizin 1. yılında partnerin sana 5 yıl sonra yaşamak istediği ülkeyi veya hayalindeki evi anlatıyor.

**Context:** planning

**Draft primary:** `uncertainty_tolerance` · **Source primary raw:** `uncertainty_tolerance` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0267_c`

**Option ID:** `frequency_v2_q0267_c`

**Option text:** Bu hayallerin mantıksal ve finansal olarak ne kadar gerçekçi olduğunu sorgularım.

**Existing canonical weights:** `structure_preference +2`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +2`

**Reason:** Stress-testing a 5-year dream financially is already structure_preference +2. processing_style+2 is duplicate.

**Confidence:** high

### frequency_v2_q0268

**Question ID:** `frequency_v2_q0268`

**Question text:** Aynı evdesiniz, sen çok üşüyorsun ama partnerin hep terliyor ve camı/klimayı açmak istiyor.

**Context:** established

**Draft primary:** `adaptability` · **Source primary raw:** `rhythm_adaptation` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0268_b`

**Option ID:** `frequency_v2_q0268_b`

**Option text:** Mantıklı bir orta nokta bulana kadar (klimanın derecesini sabitlemek gibi) müzakere ederim.

**Existing canonical weights:** `structure_preference +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +1`

**Reason:** Negotiating a thermostat middle is already structure_preference +1. processing_style+2 is the same 'find a rule'.

**Confidence:** high

### frequency_v2_q0270

**Question ID:** `frequency_v2_q0270`

**Question text:** Gün içinde partnerine sana çok komik gelen bir video/caps attın. O ise sadece "👍" (beğenme) emojisi attı.

**Context:** uncertainty

**Draft primary:** `reassurance_need` · **Source primary raw:** `reassurance_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0270_b`

**Option ID:** `frequency_v2_q0270_b`

**Option text:** Meşgul olduğunu düşünürüm, üstünde durmam ve kendi işime bakarım.

**Existing canonical weights:** `uncertainty_tolerance +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `uncertainty_tolerance +2`

**Reason:** Assuming they are busy after a thumbs-up is already uncertainty_tolerance +2. processing_style+1 is duplicate coolness.

**Confidence:** high

#### Option `frequency_v2_q0270_d`

**Option ID:** `frequency_v2_q0270_d`

**Option text:** Ben de ona bir sonraki mesajında aynı soğuklukta cevap vererek tepkimi gösteririm.

**Existing canonical weights:** `boundary_firmness +1`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `boundary_firmness +1`

**Reason:** Matching coldness in the next reply is already boundary_firmness +1. processing_style−1 is leftover affect.

**Confidence:** high

### frequency_v2_q0271

**Question ID:** `frequency_v2_q0271`

**Question text:** Tatilde kiraladığınız otel odası fotoğraflardaki gibi çıkmadı, berbat durumda. Partnerin çok sinirlendi.

**Context:** support

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0271_a`

**Option ID:** `frequency_v2_q0271_a`

**Option text:** Onun sinirine hak verir, ben de onunla birlikte otel yönetimine veya duruma öfkelenirim.

**Existing canonical weights:** `adaptability +1`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `adaptability +1`

**Reason:** Joining anger at the hotel is already adaptability +1. processing_style−1 is affect contagion, not repair_style.

**Confidence:** high

#### Option `frequency_v2_q0271_b`

**Option ID:** `frequency_v2_q0271_b`

**Option text:** Onu sakinleştirip "Çözüm bulalım, başka otellere bakalım" diyerek anında kriz yöneticisi olurum.

**Existing canonical weights:** `initiative +2`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `initiative +2`

**Reason:** Becoming crisis manager is already initiative +2. processing_style+2 is duplicate.

**Confidence:** high

#### Option `frequency_v2_q0271_d`

**Option ID:** `frequency_v2_q0271_d`

**Option text:** O sinirliyken uzak durur, sinirinin yatışmasını bekler, bu sırada kendi alternatiflerimi sessizce araştırırım.

**Existing canonical weights:** `autonomy +1`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `autonomy +1`

**Reason:** Waiting out the partner's anger while silently researching hotels is delayed support plus autonomy. Could also be initiative (already researching) or low repair engagement. autonomy +1 is incomplete.

**Confidence:** low

### frequency_v2_q0272

**Question ID:** `frequency_v2_q0272`

**Question text:** Bir sohbet esnasında partnerin, içinde hiçbir romantik duygu barındırmayan ama eski sevgilisinin de olduğu nötr bir anıyı anlattı (örn: "Eski sevgilimle o filme gitmiştik").

**Context:** early_dating, uncertainty

**Draft primary:** `uncertainty_tolerance` · **Source primary raw:** `uncertainty_tolerance` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0272_b`

**Option ID:** `frequency_v2_q0272_b`

**Option text:** Kıskandığımı belli etmem ama eski ilişkilerinin hala aklına geliyor olması beni içten içe gerer.

**Existing canonical weights:** `reassurance_need +2`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `REWRITE_REQUIRED`

**Proposed canonical weights:** `reassurance_need +2`

**Reason:** Covert jealousy with an explicit 'I don't show it' is an internal state. processing_style−1 cannot be mapped. Rewrite to a visible act or drop the option from scoring.

**Confidence:** medium

### frequency_v2_q0273

**Question ID:** `frequency_v2_q0273`

**Question text:** Akşam için birlikte yeni bir yemek tarifi denemeye karar verdiniz. Mutfaktaki tarzınız nedir?

**Context:** planning

**Draft primary:** `structure_preference` · **Source primary raw:** `structure_preference` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0273_a`

**Option ID:** `frequency_v2_q0273_a`

**Option text:** Bütün malzemeleri gramı gramına ölçer, tarifi harfi harfine uygularım.

**Existing canonical weights:** `structure_preference +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +2`

**Reason:** Gram-perfect recipe following is already structure_preference +2. processing_style+1 is duplicate.

**Confidence:** high

### frequency_v2_q0274

**Question ID:** `frequency_v2_q0274`

**Question text:** Birlikte kanepede otururken yarım saattir ikiniz de hiç konuşmadınız. İçinden ne geçer?

**Context:** established

**Draft primary:** `closeness_pace` · **Source primary raw:** `closeness_pace` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0274_b`

**Option ID:** `frequency_v2_q0274_b`

**Option text:** Birlikteyken yaşanan bu sessizliklerin dünyanın en huzurlu şeyi olduğunu düşünürüm.

**Existing canonical weights:** `closeness_pace +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `REWRITE_REQUIRED`

**Proposed canonical weights:** `closeness_pace +2`

**Reason:** Stem is 'içinden ne geçer' (what passes through your mind). Rating silence as peaceful is a feeling, not a 12D behavior. processing_style+1 is not mappable.

**Confidence:** high

### frequency_v2_q0276

**Question ID:** `frequency_v2_q0276`

**Question text:** Yeni başladığınız dönemde partnerin sana aniden "Hayattaki en büyük korkun/travman ne?" diye sordu.

**Context:** early_dating

**Draft primary:** `disclosure_pace` · **Source primary raw:** `disclosure_pace` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0276_c`

**Option ID:** `frequency_v2_q0276_c`

**Option text:** Neden bunu sorduğunu anlamaya çalışır, analitik ve felsefi bir boyuttan cevap veririm.

**Existing canonical weights:** `uncertainty_tolerance +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `uncertainty_tolerance +1`

**Reason:** Answering a trauma question analytically/philosophically is cognitive style. uncertainty_tolerance +1 is a weak existing score; processing_style+2 should not add a second dim.

**Confidence:** high

### frequency_v2_q0277

**Question ID:** `frequency_v2_q0277`

**Question text:** Cumartesi günü temizlik, çamaşır, alışveriş gibi birikmiş ev işleri var.

**Context:** planning

**Draft primary:** `structure_preference` · **Source primary raw:** `structure_preference` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0277_a`

**Option ID:** `frequency_v2_q0277_a`

**Option text:** "Önce işler biter, sonra dinlenilir" kuralıyla sabahtan her şeyi halledip akşama rahat etmeyi seçerim.

**Existing canonical weights:** `structure_preference +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +2`

**Reason:** Chores first, rest later is already structure_preference +2. processing_style+1 is duplicate.

**Confidence:** high

### frequency_v2_q0278

**Question ID:** `frequency_v2_q0278`

**Question text:** Kendi kariyerin/ailenle ilgili bir konuyu anlatırken partnerin sürekli ne yapman gerektiği konusunda sana akıl veriyor.

**Context:** conflict

**Draft primary:** `boundary_firmness` · **Source primary raw:** `boundary_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0278_a`

**Option ID:** `frequency_v2_q0278_a`

**Option text:** Fikirlerini dikkate alır, objektif bir göz olduğu için söylediklerini faydalı bulurum.

**Existing canonical weights:** `adaptability +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `adaptability +1`

**Reason:** Finding unsolicited career advice useful could be adaptability, low boundary, or simply not a Frequency dimension (coachability). processing_style+2 is the old 'I like logic' tag.

**Confidence:** low

#### Option `frequency_v2_q0278_c`

**Option ID:** `frequency_v2_q0278_c`

**Option text:** Tavsiyelerine uyuyormuş gibi görünür ama sonunda yine tamamen kendi bildiğimi okurum.

**Existing canonical weights:** `autonomy +2`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `autonomy +2`

**Reason:** Appearing to take advice then doing one's own thing is already autonomy +2. processing_style−1 is not a 12D (it is concealment).

**Confidence:** high

### frequency_v2_q0282

**Question ID:** `frequency_v2_q0282`

**Question text:** Partnerinin lüks sayılabilecek bir harcaması oldu (örn: pahalı bir çanta/saat), sen ise birikim yapmayı seven birisin.

**Context:** planning

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0282_b`

**Option ID:** `frequency_v2_q0282_b`

**Option text:** Para konusundaki bu farklılığın gelecekte sorun yaratıp yaratmayacağını içten içe analiz etmeye başlarım.

**Existing canonical weights:** `structure_preference +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +1`

**Reason:** Privately analyzing whether money styles will clash is already structure_preference +1. processing_style+2 is rumination, not extra structure.

**Confidence:** high

### frequency_v2_q0283

**Question ID:** `frequency_v2_q0283`

**Question text:** Gece 3'te uyandın, çok yoğun bir gelecek kaygısı veya korku hissi yaşıyorsun. Yanında partnerin uyuyor.

**Context:** support

**Draft primary:** `reassurance_need` · **Source primary raw:** `reassurance_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0283_b`

**Option ID:** `frequency_v2_q0283_b`

**Option text:** Uykusunu bölmemek için kalkar, salona geçer, düşüncelerimle yalnız başıma başa çıkmaya çalışırım.

**Existing canonical weights:** `autonomy +2`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `autonomy +2`

**Reason:** Leaving the bed to sit with anxiety alone is already autonomy +2. processing_style+2 is 'I process internally', not a 12D.

**Confidence:** high

#### Option `frequency_v2_q0283_d`

**Option ID:** `frequency_v2_q0283_d`

**Option text:** Telefonda dikkat dağıtıcı bir şeyler izler veya okur, zihnimi kendim dağıtarak uykuya dönmeyi denerim.

**Existing canonical weights:** `autonomy +1`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `autonomy +1`

**Reason:** Self-soothing with the phone is already autonomy +1. processing_style+1 is not a second score.

**Confidence:** high

### frequency_v2_q0284

**Question ID:** `frequency_v2_q0284`

**Question text:** Partnerin aniden saçını çok farklı (ve senin hiç beğenmediğin) bir renge boyattı/kestirdi.

**Context:** established

**Draft primary:** `boundary_firmness` · **Source primary raw:** `boundary_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0284_c`

**Option ID:** `frequency_v2_q0284_c`

**Option text:** "Değişiklik iyidir, cesaretine sağlık" diyerek nötr ama destekleyici bir tepki veririm.

**Existing canonical weights:** `uncertainty_tolerance +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `uncertainty_tolerance +2`

**Reason:** Neutral supportive comment on a haircut is already uncertainty_tolerance +2. processing_style+1 is tone.

**Confidence:** high

#### Option `frequency_v2_q0284_d`

**Option ID:** `frequency_v2_q0284_d`

**Option text:** Alışmakta zorlanırım ama bunu dışa vurmam, tamamen onun bedeni ve kendi kararı olduğunu kendime hatırlatırım.

**Existing canonical weights:** `autonomy +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `autonomy +2`

**Reason:** Privately reminding oneself it is their body is already autonomy +2. processing_style+1 is internal talk, not a 12D act.

**Confidence:** high

### frequency_v2_q0285

**Question ID:** `frequency_v2_q0285`

**Question text:** Birlikte araba veya yürüyüşle bir yere gidiyorsunuz. Partnerin "Şu sokağa hiç girmedik, buradan sapsak mı?" dedi.

**Context:** unclassified

**Draft primary:** `structure_preference` · **Source primary raw:** `structure_preference` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0285_b`

**Option ID:** `frequency_v2_q0285_b`

**Option text:** Olabilir derim ama içten içe "Acaba çok mu uzayacak, trafik var mıdır?" diye hesap yaparım.

**Existing canonical weights:** `structure_preference +1`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +1`

**Reason:** Mentally calculating delay/traffic is already structure_preference +1. processing_style+1 is the same calculation.

**Confidence:** high

### frequency_v2_q0286

**Question ID:** `frequency_v2_q0286`

**Question text:** Partnerin seni en yakın (tek) arkadaşıyla tanıştırdı. Gece boyu kendi aralarındaki iç şakaları konuşup güldüler.

**Context:** social

**Draft primary:** `social_energy` · **Source primary raw:** `social_energy` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0286_b`

**Option ID:** `frequency_v2_q0286_b`

**Option text:** Onların o bağını izlemek hoşuma gider, karışmadan onları seyrederim.

**Existing canonical weights:** `autonomy +1`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `autonomy +1`

**Reason:** Watching their in-joke bond from outside is already autonomy +1. processing_style+1 is not social_energy.

**Confidence:** high

### frequency_v2_q0287

**Question ID:** `frequency_v2_q0287`

**Question text:** İkiniz de çok ilgili olduğunuz tarihi/siyasi bir konuda farklı uçlardasınız. Tartışma hararetlendi.

**Context:** conflict

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0287_b`

**Option ID:** `frequency_v2_q0287_b`

**Option text:** Saygı çerçevesinde kalarak, argümanlarımı makale ve kanıtlarla sunar, onu ikna etmeye çalışırım.

**Existing canonical weights:** `initiative +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `initiative +1`

**Reason:** Arguing politics with articles is debate, not repair. initiative +1 is one reading; it could also be boundary_firmness or nothing 12D (intellectual style). Do not map processing_style+2 to structure_preference.

**Confidence:** medium

#### Option `frequency_v2_q0287_c`

**Option ID:** `frequency_v2_q0287_c`

**Option text:** Onun düşüncelerini çok sert ve saçma bulursam, açıkça eleştirir ve geri adım atmam.

**Existing canonical weights:** `boundary_firmness +2`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `boundary_firmness +2`

**Reason:** Openly criticizing a view one finds absurd is already boundary_firmness +2. processing_style−1 is leftover affect.

**Confidence:** high

### frequency_v2_q0288

**Question ID:** `frequency_v2_q0288`

**Question text:** Partnerin genel olarak çok kararsız biri. Nereye gidileceğini, ne yeneceğini sana bırakıyor.

**Context:** planning

**Draft primary:** `structure_preference` · **Source primary raw:** `structure_preference` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0288_d`

**Option ID:** `frequency_v2_q0288_d`

**Option text:** Onun ne istediğini bulması için farklı seçenekler sunarak onu nazikçe karar vermeye zorlarım.

**Existing canonical weights:** `boundary_firmness +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `boundary_firmness +1`

**Reason:** Offering options to nudge a decision could be initiative, structure, or boundary (refusing to carry all decisions). boundary_firmness +1 is only one of those. processing_style+2 is not itself a dimension.

**Confidence:** medium

### frequency_v2_q0289

**Question ID:** `frequency_v2_q0289`

**Question text:** Partnerin sana açıkça göstererek "Eski sevgilim doğum günümü kutlamış" dedi ve sildi.

**Context:** uncertainty

**Draft primary:** `reassurance_need` · **Source primary raw:** `reassurance_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0289_a`

**Option ID:** `frequency_v2_q0289_a`

**Option text:** Gösterdiği için teşekkür ederim ama içime kurt düşer, o gün modum bariz şekilde düşer.

**Existing canonical weights:** `reassurance_need +2`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `reassurance_need +2`

**Reason:** Thanking them for showing the ex message while mood-dropping is already reassurance_need +2. processing_style−1 is affect.

**Confidence:** high

#### Option `frequency_v2_q0289_c`

**Option ID:** `frequency_v2_q0289_c`

**Option text:** Neden sildiğini sorgular, "Silmene gerek yoktu" diyerek onun bu davranışını analiz ederim.

**Existing canonical weights:** `boundary_firmness -1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `boundary_firmness -1`

**Reason:** Analyzing why they deleted it is already boundary_firmness −1 (over-engaging). processing_style+2 is rumination, not a 12D.

**Confidence:** high

### frequency_v2_q0290

**Question ID:** `frequency_v2_q0290`

**Question text:** Partnerin çok hasta ama inatla "Doktora gitmeyeceğim, bana bir şey olmaz" diyip işe gitmeye çalışıyor.

**Context:** unclassified

**Draft primary:** `boundary_firmness` · **Source primary raw:** `boundary_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0290_d`

**Option ID:** `frequency_v2_q0290_d`

**Option text:** Mantıklı olarak vücudunun neden dinlenmeye ihtiyacı olduğunu tıbbi/pratik kanıtlarla açıklamaya çalışırım.

**Existing canonical weights:** `structure_preference +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +1`

**Reason:** Medical/practical arguments to skip work while sick is already structure_preference +1. processing_style+2 is the same persuasion style.

**Confidence:** high

### frequency_v2_q0292

**Question ID:** `frequency_v2_q0292`

**Question text:** Partnerin elindeki kahveyi tamamen senin yeni bilgisayarının veya çok sevdiğin bir kıyafetinin üstüne döktü.

**Context:** support

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0292_a`

**Option ID:** `frequency_v2_q0292_a`

**Option text:** O anki refleksle bağırır, kızar, durumun yarattığı stresi tüm vücudumla dışa vururum.

**Existing canonical weights:** `boundary_firmness +1`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `boundary_firmness +1`

**Reason:** Yelling when coffee hits the laptop is already boundary_firmness +1. This is startle/anger, not couple-conflict repair. Drop processing_style−2.

**Confidence:** high

#### Option `frequency_v2_q0292_b`

**Option ID:** `frequency_v2_q0292_b`

**Option text:** Hiçbir duygu belirtisi göstermeden sadece bezi kapıp temizlemeye ve hasar tespiti yapmaya odaklanırım.

**Existing canonical weights:** `structure_preference +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +1`

**Reason:** Zero-affect cleanup and damage check is already structure_preference +1. processing_style+2 is the rational pole of the same accident, not a new dim.

**Confidence:** high

### frequency_v2_q0293

**Question ID:** `frequency_v2_q0293`

**Question text:** Günlük ofis/arkadaş dedikodularını partnerinle ne derece paylaşırsın?

**Context:** uncertainty

**Draft primary:** `disclosure_pace` · **Source primary raw:** `disclosure_pace` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0293_b`

**Option ID:** `frequency_v2_q0293_b`

**Option text:** Sadece onun da tanıdığı veya gerçekten ilginç bulacağı çok büyük bir olay varsa kısaca bahsederim.

**Existing canonical weights:** `autonomy +1`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `autonomy +1`

**Reason:** Only sharing office gossip if they would care is already autonomy +1. processing_style+1 is a filter, not a 12D.

**Confidence:** high

### frequency_v2_q0294

**Question ID:** `frequency_v2_q0294`

**Question text:** Uyurken senin tarafın hep sıcak, partnerinin tarafı hep serin olsun istiyor. Yataktaki denge nasıl sağlanır?

**Context:** unclassified

**Draft primary:** `boundary_firmness` · **Source primary raw:** `boundary_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0294_c`

**Option ID:** `frequency_v2_q0294_c`

**Option text:** Kombiyi/klimayı tam orta dereceye ayarlar, ne senin dediğin ne benim dediğim olsun mantığını uygularım.

**Existing canonical weights:** `structure_preference +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +1`

**Reason:** Setting climate to a midpoint is already structure_preference +1. processing_style+2 is duplicate 'fair rule'.

**Confidence:** high

### frequency_v2_q0295

**Question ID:** `frequency_v2_q0295`

**Question text:** Sen günün stresiyle koltukta otururken sessizce ağlamaya başladın. Partnerin ne yapsa sana iyi gelir?

**Context:** support

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0295_b`

**Option ID:** `frequency_v2_q0295_b`

**Option text:** Bir bardak su ve peçete getirip, "Anlatmak istersen buradayım" diyerek beni kendi halime bırakması.

**Existing canonical weights:** `autonomy +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `REWRITE_REQUIRED`

**Proposed canonical weights:** `autonomy +2`

**Reason:** Stem asks what the partner should do that would help you. This is preferred support, not respondent behavior. processing_style+1 cannot be remapped on a care-language item.

**Confidence:** high

#### Option `frequency_v2_q0295_c`

**Option ID:** `frequency_v2_q0295_c`

**Option text:** "Ne oldu, neden ağlıyorsun, kim seni üzdü?" diyerek sorunu anında bulmaya ve çözmeye çalışması.

**Existing canonical weights:** `initiative +2`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `REWRITE_REQUIRED`

**Proposed canonical weights:** `initiative +2`

**Reason:** Same stem: desired partner problem-solving, not the respondent's initiative. Do not treat processing_style−1 as a 12D score.

**Confidence:** high

### frequency_v2_q0296

**Question ID:** `frequency_v2_q0296`

**Question text:** Sen çok sıkı bir diyettesin. Partnerin ise karşında iştahla hamburger, pizza yiyip sana da teklif ediyor.

**Context:** established

**Draft primary:** `boundary_firmness` · **Source primary raw:** `boundary_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0296_b`

**Option ID:** `frequency_v2_q0296_b`

**Option text:** Çok iradeliyimdir, onun yediği umurumda olmaz, kendi salatamı keyifle yerim.

**Existing canonical weights:** `autonomy +2`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `autonomy +2`

**Reason:** Unbothered willpower next to pizza is already autonomy +2. processing_style+2 is self-control coloring.

**Confidence:** high

### frequency_v2_q0297

**Question ID:** `frequency_v2_q0297`

**Question text:** Evde bir şeyi tamir etmeye/kurmaya çalışıyorsun. Başaramadın. Partnerin geldi ve elinden aleti alıp "Dur ben yapayım" dedi.

**Context:** boundaries

**Draft primary:** `autonomy` · **Source primary raw:** `autonomy_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0297_d`

**Option ID:** `frequency_v2_q0297_d`

**Option text:** Yapmasını izler, bu sırada ona tavsiyeler vererek sürecin mantıksal kontrolünü elde tutmaya çalışırım.

**Existing canonical weights:** `structure_preference +1`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +1`

**Reason:** Giving instructions while they finish the repair is already structure_preference +1. processing_style+1 is the same control-of-process.

**Confidence:** high

### frequency_v2_q0298

**Question ID:** `frequency_v2_q0298`

**Question text:** Aylardır planladığınız açık hava pikniği/festivali, sabah aniden bastıran şiddetli bir yağmurla tamamen iptal oldu.

**Context:** support

**Draft primary:** `uncertainty_tolerance` · **Source primary raw:** `uncertainty_tolerance` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0298_a`

**Option ID:** `frequency_v2_q0298_a`

**Option text:** Günün mahvolduğuna çok üzülür, saatlerce bu şanssızlığa söylenirim.

**Existing canonical weights:** `uncertainty_tolerance -2`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `uncertainty_tolerance -2`

**Reason:** Hours of complaining about cancelled picnic weather is already uncertainty_tolerance −2. processing_style−2 is affect.

**Confidence:** high

#### Option `frequency_v2_q0298_d`

**Option ID:** `frequency_v2_q0298_d`

**Option text:** Hemen kapalı mekanda yapılabilecek (sinema, müze) B planlarını araştırıp masaya sunarım.

**Existing canonical weights:** `structure_preference +2`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +2`

**Reason:** Researching indoor plan B is already structure_preference +2. processing_style+2 is duplicate.

**Confidence:** high

### frequency_v2_q0300

**Question ID:** `frequency_v2_q0300`

**Question text:** İlişkinizin 3. yılında partnerin, manevi/felsefi olarak tamamen farklı bir yola girdi (örn: minimalist yaşam, inziva vs.).

**Context:** planning

**Draft primary:** `autonomy` · **Source primary raw:** `autonomy_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0300_d`

**Option ID:** `frequency_v2_q0300_d`

**Option text:** Merakla araştırırım, mantıklı bulduğum kısımlarını kendi hayatıma alırım, bulmadıklarımı dışarıda bırakırım.

**Existing canonical weights:** `autonomy +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `autonomy +1`

**Reason:** Taking only the parts of their new philosophy that seem logical is already autonomy +1. processing_style+2 is the filter, not a new dim.

**Confidence:** high

### frequency_v2_q0344

**Question ID:** `frequency_v2_q0344`

**Question text:** Partnerinle şık bir restorana gittiniz. Onun sipariş ettiği yemek tamamen yanlış geldi ama o "Sorun değil, bunu da yerim" deyip sessiz kaldı.

**Context:** social

**Draft primary:** `boundary_firmness` · **Source primary raw:** `boundary_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0344_b`

**Option ID:** `frequency_v2_q0344_b`

**Option text:** "Emin misin, değiştirelim" diye birkaç kez sorarım ama istemezse üstelemem.

**Existing canonical weights:** `adaptability +1`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `adaptability +1`

**Reason:** Asking a few times then stopping is already adaptability +1. processing_style+1 is not initiative (that is option A).

**Confidence:** high

#### Option `frequency_v2_q0344_d`

**Option ID:** `frequency_v2_q0344_d`

**Option text:** Hakkını aramadığı için içten içe rahatsız olurum, bu fazla uyumlu tavır beni biraz iter.

**Existing canonical weights:** `boundary_firmness +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `REWRITE_REQUIRED`

**Proposed canonical weights:** `boundary_firmness +2`

**Reason:** Internal repulsion at the partner's passivity ('içten içe rahatsız… biraz iter') has no act. boundary_firmness +2 is already a stretch for a private feeling; processing_style+1 should not be added. Needs a behavioral option or rewrite.

**Confidence:** medium

### frequency_v2_q0346

**Question ID:** `frequency_v2_q0346`

**Question text:** Yabancı bir şehre tatile gittiniz. Partnerin navigasyon görevini üstlendi ama sizi tamamen yanlış bir yere götürüp kaybettirdi.

**Context:** support

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0346_a`

**Option ID:** `frequency_v2_q0346_a`

**Option text:** "Neden dikkat etmedin" diye kızar, kontrolü elime alıp doğru yolu ben bulmaya çalışırım.

**Existing canonical weights:** `initiative +2`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `initiative +2`

**Reason:** Getting angry and taking over navigation is already initiative +2. This is irritation at a task error, not relational repair. Drop processing_style−2.

**Confidence:** high

#### Option `frequency_v2_q0346_c`

**Option ID:** `frequency_v2_q0346_c`

**Option text:** Kendi telefonumdan sessizce haritayı açar, ona belli etmeden doğru yolu bulması için ufak kopyalar veririm.

**Existing canonical weights:** `boundary_firmness -1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `boundary_firmness -1`

**Reason:** Silently opening a map and feeding hints could be low boundary, initiative, adaptability, or avoidant disclosure. processing_style+2 ('I solve it quietly') is not a 12D.

**Confidence:** low

#### Option `frequency_v2_q0346_d`

**Option ID:** `frequency_v2_q0346_d`

**Option text:** Bir kafeye oturup dinlenmeyi, biraz sakinleştikten sonra yolu bulmayı teklif ederim.

**Existing canonical weights:** `autonomy +1`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `autonomy +1`

**Reason:** Cafe pause then find the way is already autonomy +1. processing_style+1 is delay-as-rationality, not repair.

**Confidence:** high

### frequency_v2_q0347

**Question ID:** `frequency_v2_q0347`

**Question text:** 3. buluşmanız için hazırsın. 1 saat kala "Çok acil bir ailevi durum çıktı, iptal etmem gerek" diye mesaj attı.

**Context:** early_dating

**Draft primary:** `reassurance_need` · **Source primary raw:** `reassurance_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0347_b`

**Option ID:** `frequency_v2_q0347_b`

**Option text:** Anlayışla karşılarım ama içimde "Acaba bahane mi?" diye ufak bir şüphe oluşur.

**Existing canonical weights:** `reassurance_need +2`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `REWRITE_REQUIRED`

**Proposed canonical weights:** `reassurance_need +2`

**Reason:** The only content is an inner suspicion ('bahane mi?') while outwardly being understanding. processing_style−1 is not a 12D. Needs a behavioral leak or should not be scored.

**Confidence:** medium

### frequency_v2_q0348

**Question ID:** `frequency_v2_q0348`

**Question text:** Birlikte yaşadığınız dönemde, partnerin sana hiç danışmadan kendi birikiminden yakın bir arkadaşına yüklü bir borç verdi.

**Context:** uncertainty

**Draft primary:** `boundary_firmness` · **Source primary raw:** `boundary_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0348_c`

**Option ID:** `frequency_v2_q0348_c`

**Option text:** Borç verdiği kişinin geri ödeme potansiyelini ve bu durumun bizim bütçemizi nasıl etkileyeceğini sorgularım.

**Existing canonical weights:** `structure_preference +2`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +2`

**Reason:** Questioning repayment odds and budget impact is already structure_preference +2. processing_style+2 is duplicate.

**Confidence:** high

#### Option `frequency_v2_q0348_d`

**Option ID:** `frequency_v2_q0348_d`

**Option text:** O an bir şey demem ama o para geri gelmezse bunu büyük bir kriz konusu yaparım.

**Existing canonical weights:** `disclosure_pace -1`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `disclosure_pace -1`

**Reason:** Saying nothing now, making it a crisis if unpaid is already disclosure_pace −1. processing_style−1 is leftover affect.

**Confidence:** high

### frequency_v2_q0351

**Question ID:** `frequency_v2_q0351`

**Question text:** Yaptığın bir işle (yemek, sunum, çizim) ilgili partnerinden fikir almadığın halde sana oldukça yapıcı ama eleştirel bir yorum yaptı.

**Context:** conflict

**Draft primary:** `boundary_firmness` · **Source primary raw:** `boundary_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0351_a`

**Option ID:** `frequency_v2_q0351_a`

**Option text:** Eleştiriyi mantık süzgecinden geçirir, haklıysa kendimi geliştirmek için bunu memnuniyetle kabul ederim.

**Existing canonical weights:** `boundary_firmness -1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `boundary_firmness -1`

**Reason:** Accepting criticism if it passes a logic filter could be low boundary, high adaptability, or non-12D openness to feedback. processing_style+2 should not become structure_preference.

**Confidence:** medium

#### Option `frequency_v2_q0351_c`

**Option ID:** `frequency_v2_q0351_c`

**Option text:** Eleştirilmek o an hevesimi kırar, modum düşer ve ona karşı biraz sessizleşirim.

**Existing canonical weights:** `reassurance_need +2`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `reassurance_need +2`

**Reason:** Going quiet after unsolicited critique is already reassurance_need +2. processing_style−1 is affect.

**Confidence:** high

### frequency_v2_q0352

**Question ID:** `frequency_v2_q0352`

**Question text:** Netflix/Spotify gibi ortak kullanılabilecek platformlarda kendi profillerinizi/şifrelerinizi birleştirmek sence nasıl bir fikirdir?

**Context:** boundaries

**Draft primary:** `closeness_pace` · **Source primary raw:** `closeness_pace` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0352_d`

**Option ID:** `frequency_v2_q0352_d`

**Option text:** Ortak kullanıma karşı değilim ama bütçe planlaması açısından kimin neyi ödediğinin net olmasını isterim.

**Existing canonical weights:** `structure_preference +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +2`

**Reason:** Sharing accounts only if who pays is clear is already structure_preference +2. processing_style+1 is duplicate.

**Confidence:** high

### frequency_v2_q0353

**Question ID:** `frequency_v2_q0353`

**Question text:** Baş başa yemek yerken partnerinin telefonu masada ve ekranı yukarı bakıyor. Sürekli bildirimler yanıp sönüyor.

**Context:** established

**Draft primary:** `contact_need` · **Source primary raw:** `contact_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0353_b`

**Option ID:** `frequency_v2_q0353_b`

**Option text:** Gözüm ister istemez ekrana kayar, kimden mesaj geldiğini merak etsem de bir şey demem.

**Existing canonical weights:** `reassurance_need +2`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `reassurance_need +2`

**Reason:** Glancing at notifications but saying nothing is already reassurance_need +2. processing_style−1 is not a 12D.

**Confidence:** high

### frequency_v2_q0354

**Question ID:** `frequency_v2_q0354`

**Question text:** Gece 02:00. Uyumak üzeresin ama partnerin hayat, evren, çocukluğu ve korkuları hakkında çok derin bir sohbete başladı.

**Context:** early_dating, uncertainty

**Draft primary:** `disclosure_pace` · **Source primary raw:** `disclosure_pace` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0354_c`

**Option ID:** `frequency_v2_q0354_c`

**Option text:** Gözlerim kapanıyor olsa bile mantıklı cevaplar vermeye ve onun zihnine ayak uydurmaya çalışırım.

**Existing canonical weights:** `structure_preference -1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `structure_preference -1`

**Reason:** Trying to give 'logical answers' while falling asleep could be adaptability (matching their depth), low boundary, or disclosure. structure_preference −1 is a strange existing weight. processing_style+2 is cognitive coloring.

**Confidence:** low

### frequency_v2_q0355

**Question ID:** `frequency_v2_q0355`

**Question text:** Sen işteyken partnerin aradı ve "Yolda yaralı bir kedi/köpek buldum, eve getiriyorum" dedi. Önceden böyle bir planınız yoktu.

**Context:** established

**Draft primary:** `structure_preference` · **Source primary raw:** `structure_preference` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0355_b`

**Option ID:** `frequency_v2_q0355_b`

**Option text:** Kabul ederim ama içten içe "Bunun masrafı, tuvalet eğitimi, düzeni ne olacak?" diye hesap yapmaya başlarım.

**Existing canonical weights:** `structure_preference +2`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +2`

**Reason:** Immediately costing the surprise pet is already structure_preference +2. processing_style+2 is duplicate.

**Confidence:** high

### frequency_v2_q0356

**Question ID:** `frequency_v2_q0356`

**Question text:** 1 haftalık deniz tatilinizin daha 2. gününde sen çok fena güneş geçmesi/gıda zehirlenmesi yaşadın ve odadasın.

**Context:** support

**Draft primary:** `adaptability` · **Source primary raw:** `rhythm_adaptation` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0356_c`

**Option ID:** `frequency_v2_q0356_c`

**Option text:** Birkaç saatte bir beni kontrole gelmesini ama aralarda kendi tatilini yapmasını makul bulurum.

**Existing canonical weights:** `structure_preference +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +1`

**Reason:** Check-ins every few hours plus they still holiday is already structure_preference +1. processing_style+2 is not extra adaptability.

**Confidence:** high

#### Option `frequency_v2_q0356_d`

**Option ID:** `frequency_v2_q0356_d`

**Option text:** Modum düşer, kendimi suçlu hissederim ve onun da keyfi kaçtı diye tatili tamamen bitirmeyi teklif ederim.

**Existing canonical weights:** `uncertainty_tolerance -1`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `uncertainty_tolerance -1`

**Reason:** Guilt plus offering to cancel the trip mixes reassurance_need, low UT, and over-adaptation. uncertainty_tolerance −1 is only a fragment. processing_style−2 is affect, not a dimension.

**Confidence:** low

### frequency_v2_q0357

**Question ID:** `frequency_v2_q0357`

**Question text:** Birlikte uzun yola çıkacaksınız ancak müzik zevkleriniz birbirinden siyah ve beyaz kadar farklı.

**Context:** established

**Draft primary:** `adaptability` · **Source primary raw:** `rhythm_adaptation` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0357_d`

**Option ID:** `frequency_v2_q0357_d`

**Option text:** İkimizin de çok sevmediği ama rahatsız da olmadığı "nötr" bir radyo/podcast açar, ortak zemin bulurum.

**Existing canonical weights:** `uncertainty_tolerance +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `CLEAR_REMAP`

**Proposed canonical weights:** `uncertainty_tolerance +1`, `adaptability +1`

**Reason:** Picking a neutral radio/podcast neither person loves is matching to a shared middle, i.e. adaptability. Keep uncertainty_tolerance +1 (tolerating a non-preferred soundtrack). Not repair.

**Confidence:** medium

### frequency_v2_q0358

**Question ID:** `frequency_v2_q0358`

**Question text:** Partnerin sosyal medyada çok tartışmalı ve senin hiç katılmadığın, hatta rahatsız olduğun bir politik/sosyal görüş paylaştı.

**Context:** social

**Draft primary:** `boundary_firmness` · **Source primary raw:** `boundary_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0358_d`

**Option ID:** `frequency_v2_q0358_d`

**Option text:** Fikrinin kökenini anlamak için yargılamadan, sadece meraktan "O paylaşımında ne demek istedin?" diye sorarım.

**Existing canonical weights:** `uncertainty_tolerance +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `uncertainty_tolerance +1`

**Reason:** Curious, non-judgmental asking about a post could be disclosure, closeness, UT, or none. uncertainty_tolerance +1 is not uniquely implied. Not repair.

**Confidence:** low

### frequency_v2_q0359

**Question ID:** `frequency_v2_q0359`

**Question text:** Sinemadasınız ve arkanızdaki çift sürekli yüksek sesle konuşuyor. Partnerin rahatsız olduğunu belli ediyor ama bir şey demiyor.

**Context:** social

**Draft primary:** `initiative` · **Source primary raw:** `initiative_tendency` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0359_b`

**Option ID:** `frequency_v2_q0359_b`

**Option text:** Partnerime fısıldayıp "İstersen yerimizi değiştirelim" der, çatışmadan uzak bir çözüm üretirim.

**Existing canonical weights:** `uncertainty_tolerance +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `uncertainty_tolerance +1`

**Reason:** Offering to change seats to avoid confronting strangers is already uncertainty_tolerance +1. processing_style+2 is conflict-avoidance coloring; this is not couple repair_style.

**Confidence:** high

#### Option `frequency_v2_q0359_d`

**Option ID:** `frequency_v2_q0359_d`

**Option text:** Yüksek sesle "ŞŞŞŞ!" yaparak isimsiz bir uyarı gönderir, duruma gerginlik katmadan sorunu çözerim.

**Existing canonical weights:** `social_energy +1`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `social_energy +1`

**Reason:** A public 'şşş' is social control, possibly initiative or boundary. social_energy +1 is a poor existing fit. processing_style−1 does not clarify it.

**Confidence:** low

### frequency_v2_q0360

**Question ID:** `frequency_v2_q0360`

**Question text:** Sadece kahve içmek için buluşacaktınız ama partnerin elinde büyük ve anlamlı bir hediye ile geldi. (Özel bir gün değil)

**Context:** early_dating

**Draft primary:** `uncertainty_tolerance` · **Source primary raw:** `uncertainty_tolerance` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0360_b`

**Option ID:** `frequency_v2_q0360_b`

**Option text:** Mutlu olurum ama "Ben bir şey almadım, mahcup oldum" diyerek hafif bir borçluluk hissederim.

**Existing canonical weights:** `structure_preference +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +2`

**Reason:** Feeling indebted because you brought no gift is already (oddly) structure_preference +2. Reciprocity/obligation is not a 12D. processing_style+1 should not be added; the existing structure score itself is a stretch and should be reviewed later, but that is out of scope for this leftover tag.

**Confidence:** medium

### frequency_v2_q0361

**Question ID:** `frequency_v2_q0361`

**Question text:** Partnerin ani bir kararla işten çıkarıldı. Çok moralsiz ve ne yapacağını bilmiyor.

**Context:** support

**Draft primary:** `reassurance_need` · **Source primary raw:** `reassurance_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0361_a`

**Option ID:** `frequency_v2_q0361_a`

**Option text:** İlk günlerde ona sadece duygusal bir sığınak olur, konuyu hiç açmadan onu şımartırım.

**Existing canonical weights:** `closeness_pace +2`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `closeness_pace +2`

**Reason:** Being an emotional shelter without bringing up the job is already closeness_pace +2. processing_style−1 is support-language, not repair.

**Confidence:** high

#### Option `frequency_v2_q0361_b`

**Option ID:** `frequency_v2_q0361_b`

**Option text:** Hemen CV'sini güncellemesi için yardım teklif eder, ona iş ilanları atmaya başlarım.

**Existing canonical weights:** `initiative +2`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `initiative +2`

**Reason:** Sending job listings immediately is already initiative +2. processing_style+2 is duplicate instrumental help.

**Confidence:** high

### frequency_v2_q0364

**Question ID:** `frequency_v2_q0364`

**Question text:** Giyim tarzın veya işyerindeki karşı cins arkadaşların konusunda partnerin çok ufak ama istikrarlı kıskançlık krizleri yaratıyor.

**Context:** uncertainty

**Draft primary:** `boundary_firmness` · **Source primary raw:** `boundary_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0364_c`

**Option ID:** `frequency_v2_q0364_c`

**Option text:** Neden kıskandığını derinlemesine konuşur, mantıklı güvenceler vererek korkularını gidermeye çalışırım.

**Existing canonical weights:** `reassurance_need +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `reassurance_need +1`

**Reason:** Deep-talk plus 'mantıklı güvenceler' for jealousy could be giving reassurance, adaptability, or a repair-like conversation that is not post-conflict repair. reassurance_need +1 already exists; processing_style+2 should not add structure.

**Confidence:** medium

### frequency_v2_q0365

**Question ID:** `frequency_v2_q0365`

**Question text:** İlişkiniz için çok önemli bir tarihi (yıldönümü) partnerin tamamen unuttu ve o güne normal bir gün gibi devam ediyor.

**Context:** conflict

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0365_c`

**Option ID:** `frequency_v2_q0365_c`

**Option text:** Sabah ilk iş ben kutlar, ona unuttuğu için ufak bir şaka yapar, konuyu tatlıya bağlarım.

**Existing canonical weights:** `initiative +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `initiative +2`

**Reason:** Celebrating first and joking about the forgotten anniversary is already initiative +2. That could have been repair, but initiative already captures taking the lead. Do not stack repair_style on top.

**Confidence:** high

### frequency_v2_q0367

**Question ID:** `frequency_v2_q0367`

**Question text:** Senin en sevdiğin, başyapıt dediğin filmi birlikte izlediniz ve o "Bu hayatımda izlediğim en kötü filmdi" dedi.

**Context:** established

**Draft primary:** `autonomy` · **Source primary raw:** `autonomy_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0367_b`

**Option ID:** `frequency_v2_q0367_b`

**Option text:** O filmin neden bir başyapıt olduğunu uzun uzun kanıtlamaya ve fikrini değiştirmeye çalışırım.

**Existing canonical weights:** `initiative +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `initiative +2`

**Reason:** Long argument that a film is a masterpiece is already initiative +2. processing_style+1 is debate style, not a 12D.

**Confidence:** high

### frequency_v2_q0368

**Question ID:** `frequency_v2_q0368`

**Question text:** Tatile gittiniz ama bu sefer *partnerin* çok fena hastalandı ve odadan çıkamıyor.

**Context:** unclassified

**Draft primary:** `autonomy` · **Source primary raw:** `autonomy_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0368_c`

**Option ID:** `frequency_v2_q0368_c`

**Option text:** Onun yalnız kalmaktan hoşlanıp hoşlanmadığını sorar, ona göre aksiyon alırım.

**Existing canonical weights:** `adaptability +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `adaptability +1`

**Reason:** Asking whether they want company when sick, then acting is already adaptability +1. processing_style+2 is duplicate matching.

**Confidence:** high

#### Option `frequency_v2_q0368_d`

**Option ID:** `frequency_v2_q0368_d`

**Option text:** İkimiz için de çok üzülür, tatil bozulduğu için sürekli "Keşke böyle olmasaydı" diyerek moral bozukluğumu yansıtırım.

**Existing canonical weights:** `uncertainty_tolerance -1`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `uncertainty_tolerance -1`

**Reason:** Lamenting the ruined holiday is already uncertainty_tolerance −1. processing_style−2 is affect.

**Confidence:** high

### frequency_v2_q0369

**Question ID:** `frequency_v2_q0369`

**Question text:** Partnerin yıllardır yapmak istediği ama gelir garantisi olmayan sanatsal/serbest bir mesleğe (örn: müzisyenlik) geçmek istediğini açıkladı.

**Context:** planning

**Draft primary:** `autonomy` · **Source primary raw:** `autonomy_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0369_a`

**Option ID:** `frequency_v2_q0369_a`

**Option text:** Birlikte finansal bir plan yaparız, ben bir süre evin yükünü çekerim, hayalini yaşamasını desteklerim.

**Existing canonical weights:** `closeness_pace +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `CLEAR_REMAP`

**Proposed canonical weights:** `closeness_pace +1`, `structure_preference +1`

**Reason:** Joint financial planning plus carrying household load is structure plus closeness, not processing_style. Existing closeness_pace +1 stays; add structure_preference +1. Not +2: support is mixed with planning, and 'I'll carry the house' is also adaptability/closeness.

**Confidence:** medium

### frequency_v2_q0370

**Question ID:** `frequency_v2_q0370`

**Question text:** Gece yarısı partnerinin telefonuna kayıtlı olmayan bir numaradan sadece "Uyudun mu?" mesajı geldi.

**Context:** uncertainty

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0370_c`

**Option ID:** `frequency_v2_q0370_c`

**Option text:** Şüpheye düşerim, ertesi gün hareketlerini gözlemler, kendisinin bana bir şey açıklamasını beklerim.

**Existing canonical weights:** `disclosure_pace -1`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `disclosure_pace -1`

**Reason:** Watching and waiting for them to explain a night text is already disclosure_pace −1. processing_style−1 is not a second score.

**Confidence:** high

#### Option `frequency_v2_q0370_d`

**Option ID:** `frequency_v2_q0370_d`

**Option text:** Numaranın kime ait olduğunu kendi telefonumdan/uygulamalardan gizlice araştırmaya çalışırım.

**Existing canonical weights:** `boundary_firmness -1`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `boundary_firmness -1`

**Reason:** Secretly researching an unknown number is low boundary and low uncertainty_tolerance / high reassurance, and may not belong in a 12D behavioral bank at all. processing_style−2 is not a map; it is a dumping ground for 'emotional/paranoid'.

**Confidence:** medium

### frequency_v2_q0371

**Question ID:** `frequency_v2_q0371`

**Question text:** Partnerin son zamanlarda inanılmaz derecede yüksek sesle horlamaya başladı ve hiç uyuyamıyorsun.

**Context:** established

**Draft primary:** `boundary_firmness` · **Source primary raw:** `boundary_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0371_c`

**Option ID:** `frequency_v2_q0371_c`

**Option text:** Sabah ona "Horlaman yüzünden uyuyamıyorum, doktora gitmelisin" diyerek sorunu direkt yüzüne vururum.

**Existing canonical weights:** `boundary_firmness +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `boundary_firmness +2`

**Reason:** Telling them to see a doctor about snoring is already boundary_firmness +2. processing_style+1 is redundant directness.

**Confidence:** high

### frequency_v2_q0373

**Question ID:** `frequency_v2_q0373`

**Question text:** Beraber çok dramatik bir film izlerken partnerin hıçkırarak ağlamaya başladı.

**Context:** unclassified

**Draft primary:** `reassurance_need` · **Source primary raw:** `reassurance_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0373_b`

**Option ID:** `frequency_v2_q0373_b`

**Option text:** Sessizce ona peçete uzatır, filme odaklanmasını bölmeden kendi halinde ağlamasına izin veririm.

**Existing canonical weights:** `autonomy +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `autonomy +1`

**Reason:** Passing a tissue and letting them cry at a film is already autonomy +1. processing_style+2 is 'I don't join the emotion', not a 12D.

**Confidence:** high

#### Option `frequency_v2_q0373_d`

**Option ID:** `frequency_v2_q0373_d`

**Option text:** "Alt tarafı film, neden bu kadar etkilendin?" diyerek bu aşırı duygusallığı anlamlandıramadığımı belli ederim.

**Existing canonical weights:** `boundary_firmness +1`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `boundary_firmness +1`

**Reason:** 'It's just a movie' is already boundary_firmness +1. processing_style−2 is dismissiveness coloring, not a new dim.

**Confidence:** high

### frequency_v2_q0374

**Question ID:** `frequency_v2_q0374`

**Question text:** Beraber tatile çıktınız. Partnerin diş fırçasını unutmuş ve sana sormadan seninkini kullanmış.

**Context:** boundaries

**Draft primary:** `boundary_firmness` · **Source primary raw:** `boundary_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0374_c`

**Option ID:** `frequency_v2_q0374_c`

**Option text:** İğrensem de onu kırmamak için "Bir dahakine bakkaldan alalım" der, o fırçayı atıp kendime yeni alırım.

**Existing canonical weights:** `disclosure_pace -1`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `disclosure_pace -1`

**Reason:** Hiding disgust and replacing the toothbrush is already disclosure_pace −1. processing_style+1 is not a 12D.

**Confidence:** high

### frequency_v2_q0375

**Question ID:** `frequency_v2_q0375`

**Question text:** Partnerin sana "Birlikte bir kafe/girişim açalım, hem beraber çalışır hem kazanırız" fikriyle geldi.

**Context:** planning

**Draft primary:** `initiative` · **Source primary raw:** `initiative_tendency` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0375_c`

**Option ID:** `frequency_v2_q0375_c`

**Option text:** "Riskleri, iş planını, görev dağılımını kağıda dökelim, ona göre karar verelim" diyerek süreci analitikleştiririm.

**Existing canonical weights:** `structure_preference +2`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +2`

**Reason:** Papering risks, plan, and roles before a joint cafe is already structure_preference +2. processing_style+2 is duplicate.

**Confidence:** high

### frequency_v2_q0376

**Question ID:** `frequency_v2_q0376`

**Question text:** Gece su içmek için kalktın. Yatağa döndüğünde partnerinin de uyanık olduğunu fark ettin.

**Context:** unclassified

**Draft primary:** `autonomy` · **Source primary raw:** `autonomy_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0376_d`

**Option ID:** `frequency_v2_q0376_d`

**Option text:** Onun neden uyanık olduğunu (stresli mi?) anlamak için "Bir sorun mu var?" diye kısa bir check-in yaparım.

**Existing canonical weights:** `reassurance_need +1`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `reassurance_need +1`

**Reason:** A short 'is something wrong?' check-in is already reassurance_need +1. processing_style+1 is not extra.

**Confidence:** high

### frequency_v2_q0377

**Question ID:** `frequency_v2_q0377`

**Question text:** Çok lüks bir restoranda yemeğinizi yediniz, hesap geldi ve partnerin cüzdanını/kartını evde unuttuğunu fark etti.

**Context:** support

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0377_a`

**Option ID:** `frequency_v2_q0377_a`

**Option text:** "Yine mi dikkatsizlik!" diye ufak bir sitem eder, hesabı ben öderim ama dönüşte söylenirim.

**Existing canonical weights:** `boundary_firmness +1`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `boundary_firmness +1`

**Reason:** A small reproach about the forgotten card is already boundary_firmness +1. processing_style−2 is affect. Not repair of a relationship fight.

**Confidence:** high

### frequency_v2_q0379

**Question ID:** `frequency_v2_q0379`

**Question text:** İkiniz de aynı spor salonuna yazıldınız. Antrenman dinamiğiniz nasıl olmalıdır?

**Context:** established

**Draft primary:** `autonomy` · **Source primary raw:** `autonomy_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0379_c`

**Option ID:** `frequency_v2_q0379_c`

**Option text:** O günkü antrenmanımız aynıysa beraber yaparız, farklıysa kimse kimseyi beklemez.

**Existing canonical weights:** `uncertainty_tolerance +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `uncertainty_tolerance +1`

**Reason:** Train together only if the workout matches is already uncertainty_tolerance +1 (a stretch). processing_style+2 is 'it depends', not a 12D. Could have been adaptability; do not invent that without a human pass.

**Confidence:** high

### frequency_v2_q0380

**Question ID:** `frequency_v2_q0380`

**Question text:** Bir partidesiniz ve partnerin içkiyi fazla kaçırdı, saçmalamaya ve dengesini kaybetmeye başladı.

**Context:** social

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0380_a`

**Option ID:** `frequency_v2_q0380_a`

**Option text:** Hemen müdahale eder, koluna girer ve kimseye belli etmeden onu hızla eve götürürüm.

**Existing canonical weights:** `structure_preference +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `CLEAR_REMAP`

**Proposed canonical weights:** `initiative +2`

**Reason:** Taking the drunk partner's arm and leaving is crisis initiative, not processing_style and not structure_preference. Drop the existing structure_preference +1; it does not measure planning here.

**Confidence:** medium

### frequency_v2_q0381

**Question ID:** `frequency_v2_q0381`

**Question text:** Yıllardır tuttuğun çok özel, karanlık veya derin düşüncelerinin olduğu bir günlüğün var. Partnerin bunu masada açık bulup okuduğunu itiraf etti.

**Context:** boundaries

**Draft primary:** `boundary_firmness` · **Source primary raw:** `boundary_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0381_c`

**Option ID:** `frequency_v2_q0381_c`

**Option text:** Çok bozulurum ama kavga çıkmasın diye günlüğü sessizce çöpe atar veya saklar, konuyu kapatırım.

**Existing canonical weights:** `disclosure_pace -2`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `disclosure_pace -2`

**Reason:** Binning the diary and closing the topic to avoid a fight could be low disclosure (already −2) or avoidant repair. Adding repair_style −2 would double-count the same shutdown.

**Confidence:** medium

### frequency_v2_q0382

**Question ID:** `frequency_v2_q0382`

**Question text:** Kış ortasında evin kombisi bozuldu ve aniden çok yüklü (bir maaş kadar) bir tamir masrafı çıktı.

**Context:** support

**Draft primary:** `structure_preference` · **Source primary raw:** `structure_preference` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0382_a`

**Option ID:** `frequency_v2_q0382_a`

**Option text:** Panik yapmadan hemen usta çağırır, pazarlığını yapar, ödeme planını çözer ve işi bitiririm.

**Existing canonical weights:** `initiative +2`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `initiative +2`

**Reason:** Calling a technician and negotiating payment is already initiative +2. processing_style+2 is duplicate crisis handling, not repair.

**Confidence:** high

#### Option `frequency_v2_q0382_b`

**Option ID:** `frequency_v2_q0382_b`

**Option text:** Paramızın bittiğine çok üzülür, günlerce "Bizi neden hep böyle şeyler buluyor" diye söylenirim.

**Existing canonical weights:** `uncertainty_tolerance -2`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `uncertainty_tolerance -2`

**Reason:** Days of 'why us' about a boiler bill is already uncertainty_tolerance −2. processing_style−2 is affect.

**Confidence:** high

### frequency_v2_q0383

**Question ID:** `frequency_v2_q0383`

**Question text:** Sen çok gerçekçi, bazen karamsar birisin. Partnerin ise her felakette "Evrene iyi mesaj yollayalım, her şey harika olacak" diyen biri.

**Context:** support

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0383_a`

**Option ID:** `frequency_v2_q0383_a`

**Option text:** Bu toksik pozitiflik beni çileden çıkarır, durumun vehametini ona kanıtlamaya çalışırım.

**Existing canonical weights:** `boundary_firmness +2`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `boundary_firmness +2`

**Reason:** Pushing back on toxic positivity is already boundary_firmness +2. processing_style−1 is leftover affect. Not repair_style.

**Confidence:** high

### frequency_v2_q0385

**Question ID:** `frequency_v2_q0385`

**Question text:** Partnerinin geçmişiyle ilgili, sana zarar vermeyecek ama bilmediğin sırlar olduğunu seziyorsun.

**Context:** unclassified

**Draft primary:** `disclosure_pace` · **Source primary raw:** `disclosure_pace` · **Unresolved labels:** `trust`

#### Option `frequency_v2_q0385_a`

**Option ID:** `frequency_v2_q0385_a`

**Option text:** Herkesin bir gizli odası olmalıdır, anlatmak istemediği sürece sormam ve kurcalamam.

**Existing canonical weights:** `autonomy +2`, `disclosure_pace -2`

**Legacy/unknown weights:** (none at option level; item-level `trust`)

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `autonomy +2`, `disclosure_pace -2`

**Reason:** Item-level secondary `trust` is not a 12D. This option already scores disclosure_pace −2 and autonomy +2 (do not pry). No option-level trust weight exists; drop the label, keep the 12D scores.

**Confidence:** high

#### Option `frequency_v2_q0385_b`

**Option ID:** `frequency_v2_q0385_b`

**Option text:** Bunu hissetmek beni huzursuz eder, "Benden sakladığın bir şey mi var?" diye direkt sorarım.

**Existing canonical weights:** `reassurance_need +2`, `disclosure_pace +1`

**Legacy/unknown weights:** (none at option level; item-level `trust`)

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `reassurance_need +2`, `disclosure_pace +1`

**Reason:** Item-level `trust` is not a 12D. Direct 'are you hiding something?' is already reassurance_need +2 and disclosure_pace +1. Drop trust; do not invent a trust dimension.

**Confidence:** high

#### Option `frequency_v2_q0385_c`

**Option ID:** `frequency_v2_q0385_c`

**Option text:** Anlatması için güven ortamı yaratır, ben kendi sırlarımı vererek onu da cesaretlendiririm.

**Existing canonical weights:** `closeness_pace +1`, `disclosure_pace +2`

**Legacy/unknown weights:** (none at option level; item-level `trust`)

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `closeness_pace +1`, `disclosure_pace +2`

**Reason:** Item-level `trust` is not a 12D. Reciprocal secret-sharing is already disclosure_pace +2 and closeness_pace +1. Drop trust.

**Confidence:** high

#### Option `frequency_v2_q0385_d`

**Option ID:** `frequency_v2_q0385_d`

**Option text:** Sır tutması onda gizemli bir hava yaratır, bu mesafeli hali bir nebze hoşuma gider.

**Existing canonical weights:** `uncertainty_tolerance +2`, `boundary_firmness +1`

**Legacy/unknown weights:** (none at option level; item-level `trust`)

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `uncertainty_tolerance +2`, `boundary_firmness +1`

**Reason:** Item-level `trust` is not a 12D. Enjoying mysterious distance is already uncertainty_tolerance +2 and boundary_firmness +1. Drop trust.

**Confidence:** high

### frequency_v2_q0387

**Question ID:** `frequency_v2_q0387`

**Question text:** Partnerin gün boyu senin attığın mesaja cevap vermedi, ama Instagram/Twitter'da aktif olduğunu görüyorsun.

**Context:** uncertainty

**Draft primary:** `reassurance_need` · **Source primary raw:** `reassurance_need` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0387_b`

**Option ID:** `frequency_v2_q0387_b`

**Option text:** Sosyal medyada pasif takılmakla mesajlaşmanın farklı enerjiler olduğunu bilir, hiç umursamam.

**Existing canonical weights:** `uncertainty_tolerance +2`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `uncertainty_tolerance +2`

**Reason:** Treating social-media lurking as different from messaging is already uncertainty_tolerance +2. processing_style+2 is the same unbothered reading.

**Confidence:** high

#### Option `frequency_v2_q0387_c`

**Option ID:** `frequency_v2_q0387_c`

**Option text:** Ben de ona yazmayı bırakır, kendi sosyal medyamda eğlendiğimi gösteren şeyler paylaşırım.

**Existing canonical weights:** `disclosure_pace -1`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `disclosure_pace -1`

**Reason:** Stopping texts and posting fun stories is already disclosure_pace −1. processing_style−1 is leftover affect.

**Confidence:** high

### frequency_v2_q0388

**Question ID:** `frequency_v2_q0388`

**Question text:** Yaklaşan bir özel gün için partnerine hediye alma stratejin nedir?

**Context:** planning

**Draft primary:** `structure_preference` · **Source primary raw:** `structure_preference` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0388_a`

**Option ID:** `frequency_v2_q0388_a`

**Option text:** Haftalar öncesinden neye ihtiyacı olduğunu gizlice analiz eder, alır ve paketletirim.

**Existing canonical weights:** `structure_preference +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `structure_preference +2`

**Reason:** Weeks-ahead secret gift analysis is already structure_preference +2. processing_style+1 is duplicate.

**Confidence:** high

#### Option `frequency_v2_q0388_c`

**Option ID:** `frequency_v2_q0388_c`

**Option text:** "Sana ne alayım, neye ihtiyacın var?" diye açıkça sorar, işi garantiye alırım.

**Existing canonical weights:** `uncertainty_tolerance -1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `uncertainty_tolerance -1`

**Reason:** Asking what they need to guarantee a good gift is already uncertainty_tolerance −1. processing_style+2 is the same need for certainty, not extra structure.

**Confidence:** high

### frequency_v2_q0389

**Question ID:** `frequency_v2_q0389`

**Question text:** Partnerinin şehir dışından gelen bir arkadaşı, haber vermeden "Birkaç gün sizde kalabilir miyim?" diye kapıya geldi.

**Context:** boundaries

**Draft primary:** `boundary_firmness` · **Source primary raw:** `boundary_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0389_c`

**Option ID:** `frequency_v2_q0389_c`

**Option text:** Partnerime "Sen ilgilen" der, misafir yokmuş gibi kendi odamda takılmaya devam ederim.

**Existing canonical weights:** `autonomy +2`

**Legacy/unknown weights:** `processing_style +1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `autonomy +2`

**Reason:** Telling the partner to host while you stay in your room is already autonomy +2. processing_style+1 is not a second score.

**Confidence:** high

### frequency_v2_q0390

**Question ID:** `frequency_v2_q0390`

**Question text:** Sokakta yürürken veya kafedeyken ilişkinizle ilgili çok gergin bir tartışma alevlendi.

**Context:** conflict

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0390_a`

**Option ID:** `frequency_v2_q0390_a`

**Option text:** Ortamın kalabalık olması umurumda olmaz, duygumu saklayamam, sesim yükselir ve orada tartışırım.

**Existing canonical weights:** `disclosure_pace +1`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `disclosure_pace +1`

**Reason:** Raising voice in a public fight is already disclosure_pace +1. processing_style−2 is affect. Could have been social_energy; do not add it here.

**Confidence:** high

#### Option `frequency_v2_q0390_d`

**Option ID:** `frequency_v2_q0390_d`

**Option text:** Fısıldayarak veya masaya doğru eğilerek, dışarıya hiç belli etmeden kelime savaşına devam ederim.

**Existing canonical weights:** `autonomy +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `autonomy +1`

**Reason:** Whisper-fighting in public could be high disclosure (still arguing), low social_energy, or 'controlled' processing. autonomy +1 is a weak existing fit. processing_style+2 does not pick a winner.

**Confidence:** low

### frequency_v2_q0391

**Question ID:** `frequency_v2_q0391`

**Question text:** Birlikte bir kafede otururken, senin eski sevgilinin çok yakın bir arkadaşı masanıza gelip selam verdi.

**Context:** social

**Draft primary:** `social_energy` · **Source primary raw:** `social_energy` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0391_a`

**Option ID:** `frequency_v2_q0391_a`

**Option text:** Gerilirim, sadece "Merhaba" derim ve o gidene kadar partnerimle göz temasından kaçınırım.

**Existing canonical weights:** `uncertainty_tolerance -2`

**Legacy/unknown weights:** `processing_style -1`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `uncertainty_tolerance -2`

**Reason:** Freezing and avoiding eye contact with an ex's friend is already uncertainty_tolerance −2. processing_style−1 is leftover affect.

**Confidence:** high

### frequency_v2_q0392

**Question ID:** `frequency_v2_q0392`

**Question text:** Partnerin "Artık diyeti ve sporu bırakıyorum, hayatı yaşayacağım" diyerek aylar süren disiplinini bir günde çöpe attı.

**Context:** established

**Draft primary:** (none) · **Source primary raw:** `processing_style` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0392_a`

**Option ID:** `frequency_v2_q0392_a`

**Option text:** "Neden böyle hissettin, yoruldun mu?" diyerek altta yatan psikolojik sebebi anlamaya çalışırım.

**Existing canonical weights:** `closeness_pace +1`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `HUMAN_DECISION_REQUIRED`

**Proposed canonical weights:** `closeness_pace +1`

**Reason:** Asking the psychological reason they dropped diet/sport could be closeness, initiative, or non-12D amateur therapy. closeness_pace +1 is one reading. processing_style+2 is not structure or repair.

**Confidence:** low

### frequency_v2_q0393

**Question ID:** `frequency_v2_q0393`

**Question text:** Şık giyindiniz, yürüyerek bir davete gidiyorsunuz. Birden sağanak yağmur bastırdı ve şemsiye yok.

**Context:** unclassified

**Draft primary:** `uncertainty_tolerance` · **Source primary raw:** `uncertainty_tolerance` · **Unresolved labels:** `processing_style`

#### Option `frequency_v2_q0393_a`

**Option ID:** `frequency_v2_q0393_a`

**Option text:** Sinir krizi geçiririm, saçım/başım bozuldu diye tüm geceyi partnerime zehir edebilirim.

**Existing canonical weights:** `uncertainty_tolerance -2`

**Legacy/unknown weights:** `processing_style -2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `uncertainty_tolerance -2`

**Reason:** Ruining the night over ruined hair in rain is already uncertainty_tolerance −2. processing_style−2 is the same affect. Not repair.

**Confidence:** high

#### Option `frequency_v2_q0393_c`

**Option ID:** `frequency_v2_q0393_c`

**Option text:** Anında bir saçak altı bulur, en yakın mağazadan şemsiye almak veya taksi çağırmak için fırlarım.

**Existing canonical weights:** `initiative +2`

**Legacy/unknown weights:** `processing_style +2`

**Classification:** `DROP_WEIGHT`

**Proposed canonical weights:** `initiative +2`

**Reason:** Immediately finding shelter, umbrella, or a taxi is already initiative +2. processing_style+2 is duplicate problem-solving.

**Confidence:** high

---

## Totals

1. **Total affected questions:** 143
2. **Total affected options reviewed:** 208 (204 with option-level unknown weights + 4 `frequency_v2_q0385` options for item-level `trust`)
3. **CLEAR_REMAP:** 19
4. **DROP_WEIGHT:** 143
5. **REWRITE_REQUIRED:** 9
6. **HUMAN_DECISION_REQUIRED:** 37

7. **Count by proposed canonical dimension** (number of reviewed options whose proposed set includes that dimension; not a strength sum):

   - `contact_need`: 2
   - `closeness_pace`: 16
   - `initiative`: 18
   - `autonomy`: 24
   - `reassurance_need`: 17
   - `uncertainty_tolerance`: 32
   - `disclosure_pace`: 23
   - `boundary_firmness`: 35
   - `repair_style`: 14
   - `social_energy`: 2
   - `structure_preference`: 34
   - `adaptability`: 12

8. **Questions where primary_dimension would change** (source/draft primary is an unknown or empty, or proposed 12D mass clearly shifts the lead dimension):

   - `frequency_v2_q0003`: draft primary (none) / source raw ['processing_style'] → proposed lead `initiative` (unknown_or_empty_source_primary)
   - `frequency_v2_q0008`: draft primary (none) / source raw ['processing_style'] → proposed lead `boundary_firmness` (unknown_or_empty_source_primary)
   - `frequency_v2_q0015`: draft primary (none) / source raw ['processing_style'] → proposed lead `repair_style` (unknown_or_empty_source_primary)
   - `frequency_v2_q0026`: draft primary (none) / source raw ['processing_style'] → proposed lead `boundary_firmness` (unknown_or_empty_source_primary)
   - `frequency_v2_q0029`: draft primary (none) / source raw ['processing_style'] → proposed lead `uncertainty_tolerance` (unknown_or_empty_source_primary)
   - `frequency_v2_q0037`: draft primary ['boundary_firmness'] / source raw ['boundary_style'] → proposed lead `repair_style` (lead_shifted_by_this_review)
   - `frequency_v2_q0043`: draft primary (none) / source raw ['processing_style'] → proposed lead `initiative` (unknown_or_empty_source_primary)
   - `frequency_v2_q0047`: draft primary (none) / source raw ['conflict_approach'] → proposed lead `uncertainty_tolerance` (unknown_or_empty_source_primary)
   - `frequency_v2_q0163`: draft primary (none) / source raw ['processing_style'] → proposed lead `disclosure_pace` (unknown_or_empty_source_primary)
   - `frequency_v2_q0166`: draft primary (none) / source raw ['processing_style'] → proposed lead `repair_style` (unknown_or_empty_source_primary)
   - `frequency_v2_q0180`: draft primary (none) / source raw ['processing_style'] → proposed lead `structure_preference` (unknown_or_empty_source_primary)
   - `frequency_v2_q0183`: draft primary (none) / source raw ['processing_style'] → proposed lead `boundary_firmness` (unknown_or_empty_source_primary)
   - `frequency_v2_q0186`: draft primary (none) / source raw ['processing_style'] → proposed lead `boundary_firmness` (unknown_or_empty_source_primary)
   - `frequency_v2_q0192`: draft primary (none) / source raw ['processing_style'] → proposed lead `closeness_pace` (unknown_or_empty_source_primary)
   - `frequency_v2_q0252`: draft primary (none) / source raw ['processing_style'] → proposed lead `boundary_firmness` (unknown_or_empty_source_primary)
   - `frequency_v2_q0258`: draft primary (none) / source raw ['processing_style'] → proposed lead `boundary_firmness` (unknown_or_empty_source_primary)
   - `frequency_v2_q0264`: draft primary (none) / source raw ['processing_style'] → proposed lead `reassurance_need` (unknown_or_empty_source_primary)
   - `frequency_v2_q0271`: draft primary (none) / source raw ['processing_style'] → proposed lead `initiative` (unknown_or_empty_source_primary)
   - `frequency_v2_q0282`: draft primary (none) / source raw ['processing_style'] → proposed lead `boundary_firmness` (unknown_or_empty_source_primary)
   - `frequency_v2_q0287`: draft primary (none) / source raw ['processing_style'] → proposed lead `boundary_firmness` (unknown_or_empty_source_primary)
   - `frequency_v2_q0292`: draft primary (none) / source raw ['processing_style'] → proposed lead `boundary_firmness` (unknown_or_empty_source_primary)
   - `frequency_v2_q0295`: draft primary (none) / source raw ['processing_style'] → proposed lead `reassurance_need` (unknown_or_empty_source_primary)
   - `frequency_v2_q0346`: draft primary (none) / source raw ['processing_style'] → proposed lead `initiative` (unknown_or_empty_source_primary)
   - `frequency_v2_q0365`: draft primary (none) / source raw ['processing_style'] → proposed lead `structure_preference` (unknown_or_empty_source_primary)
   - `frequency_v2_q0370`: draft primary (none) / source raw ['processing_style'] → proposed lead `initiative` (unknown_or_empty_source_primary)
   - `frequency_v2_q0377`: draft primary (none) / source raw ['processing_style'] → proposed lead `boundary_firmness` (unknown_or_empty_source_primary)
   - `frequency_v2_q0380`: draft primary (none) / source raw ['processing_style'] → proposed lead `social_energy` (unknown_or_empty_source_primary)
   - `frequency_v2_q0383`: draft primary (none) / source raw ['processing_style'] → proposed lead `boundary_firmness` (unknown_or_empty_source_primary)
   - `frequency_v2_q0390`: draft primary (none) / source raw ['processing_style'] → proposed lead `structure_preference` (unknown_or_empty_source_primary)
   - `frequency_v2_q0392`: draft primary (none) / source raw ['processing_style'] → proposed lead `autonomy` (unknown_or_empty_source_primary)

9. **Questions that would become unscorable without rewrite** (stem is not a respondent behavior, or remaining 12D weights would be empty):

   - `frequency_v2_q0169`: stem is feeling or desired-partner-behavior; not a respondent 12D act without rewrite
   - `frequency_v2_q0191`: stem is feeling or desired-partner-behavior; not a respondent 12D act without rewrite
   - `frequency_v2_q0274`: stem is feeling or desired-partner-behavior; not a respondent 12D act without rewrite
   - `frequency_v2_q0295`: stem is feeling or desired-partner-behavior; not a respondent 12D act without rewrite

    Options flagged `REWRITE_REQUIRED` (question may still be scorable via other options):

    - `frequency_v2_q0169_b`
    - `frequency_v2_q0191_b`
    - `frequency_v2_q0193_c`
    - `frequency_v2_q0272_b`
    - `frequency_v2_q0274_b`
    - `frequency_v2_q0295_b`
    - `frequency_v2_q0295_c`
    - `frequency_v2_q0344_d`
    - `frequency_v2_q0347_b`

10. **Suspicious cases where one option becomes much more heavily weighted than the other three** (after applying proposals to reviewed options; only reviewed options that *gained* mass and ended strictly heavier than every sibling):

   - None. Conservative remaps did not create a unique overweight option. Near-miss growth (CLEAR_REMAP abs-mass rose by ≥2, but a sibling still matches or exceeds it):
   - `frequency_v2_q0005_c`: 1 → 3 (`repair_style −2`, `uncertainty_tolerance −1`); sibling B remains abs 3
   - `frequency_v2_q0015_a`: 1 → 3 (`repair_style +2`, `reassurance_need +1`); siblings sit at abs 2
   - `frequency_v2_q0037_a`: 1 → 3 (`repair_style +2`, `closeness_pace +1`); sibling B also abs 3 after remap
   - `frequency_v2_q0166_a`: 1 → 3 (`repair_style +2`, `closeness_pace +1`); siblings B/C already abs 4
   - `frequency_v2_q0166_b`: 2 → 4 (`repair_style −2`, `autonomy +2`); sibling C already abs 4
   - `frequency_v2_q0186_b`: 1 → 3 (`repair_style +2`, `boundary_firmness −1`); sibling A already abs 3
   - `frequency_v2_q0261_a`: 1 → 3 (`repair_style −2`, `contact_need −1`); sibling B already abs 3

## Coverage check

- Decision rows: 208
- Classification sum: 208
- Draft pool JSON: **unchanged**
- Live Frequency V1 banks: **unchanged**

FREQUENCY V2 PHASE 1 HUMAN REVIEW REPORT READY — NO DATA MODIFIED
