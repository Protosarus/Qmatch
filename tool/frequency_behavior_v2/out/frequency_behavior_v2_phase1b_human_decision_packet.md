# Frequency V2 Phase 1B — Human Decision Packet

Status: **read-only / proposal only**. This packet does not modify the normalized V2 JSON, the source pool, Frequency V1, pubspec, runtime routing, Firebase, Discover, matching, Persona, `canonical_v1`, or C2.

Source: `tool/frequency_behavior_v2/out/frequency_behavior_v2_phase1_human_review.md`

Ordinary `DROP_WEIGHT` rows are omitted unless needed to understand a primary-dimension change or a stem rewrite.

Do not assign `social_desirability`, obviousness, `behavioral_plausibility`, `self_presentation_risk`, diagnostic_value, or `ambiguity` in this pass.

`processing_style` is still not aliased to `repair_style`.

How to use: accept / reject / pick the alternative for each card. Stem rewrites in §E replace the whole item, not one option.

## A. CLEAR_REMAP

Count: **19**. These can be applied if a human agrees. Alternatives are listed even when the main proposal is strong.

### frequency_v2_q0003_a

**QUESTION ID:** `frequency_v2_q0003`

**QUESTION TEXT:** Partnerin işten çok gergin ve morali bozuk döndü. Olayı anlatıyor. Senin ilk refleksin ne olur?

**CONTEXT:** support

**OPTION ID:** `frequency_v2_q0003_a`

**OPTION TEXT:** Neden böyle olduğunu mantıklıca analiz edip ona çözüm yolları sunmak.

**CURRENT CANONICAL WEIGHTS:** (none)

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `CLEAR_REMAP`

**PROPOSED CANONICAL WEIGHTS:** `initiative +1`

**REASON:** The act is offering solutions, which is taking initiative on the partner's problem. The 'logical analysis' half of the option is cognitive style, not a 12D, so this is +1 not +2. Not conflict repair.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** `structure_preference +1` (listing causes/solutions as a plan) instead of, or alongside, `initiative +1`.

**RISK IF ACCEPTED:** People who default to advice-giving would be scored as high-initiative even when they are not taking charge of the relationship.

### frequency_v2_q0005_c

**QUESTION ID:** `frequency_v2_q0005`

**QUESTION TEXT:** Birlikte izlediğiniz bir filmdeki ahlaki bir ikilem üzerine tamamen zıt görüşlere sahipsiniz. Tartışma uzadı, ne yaparsın?

**CONTEXT:** conflict

**OPTION ID:** `frequency_v2_q0005_c`

**OPTION TEXT:** Tartışmanın gerginleşme ihtimaline karşı konuyu şakaya vurup kapatırım.

**CURRENT CANONICAL WEIGHTS:** `uncertainty_tolerance -1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `CLEAR_REMAP`

**PROPOSED CANONICAL WEIGHTS:** `uncertainty_tolerance -1`, `repair_style -2`

**REASON:** This is a live disagreement being joke-closed to avoid processing it. That is avoidant repair behavior, not 'being rational'. Keep the existing tension-avoidance (uncertainty_tolerance −1).

**CONFIDENCE:** high

**ALTERNATIVE INTERPRETATION:** `disclosure_pace −1` (sidestep the clash) or `adaptability +1` (defuse the mood) instead of `repair_style −2`.

**RISK IF ACCEPTED:** A movie-argument joke-close would be stored as avoidant couple-repair, understating actual post-conflict repair elsewhere.

### frequency_v2_q0005_d

**QUESTION ID:** `frequency_v2_q0005`

**QUESTION TEXT:** Birlikte izlediğiniz bir filmdeki ahlaki bir ikilem üzerine tamamen zıt görüşlere sahipsiniz. Tartışma uzadı, ne yaparsın?

**CONTEXT:** conflict

**OPTION ID:** `frequency_v2_q0005_d`

**OPTION TEXT:** Ne hissettiğini anlamaya odaklanır, fikrim zıt olsa da onun duygusunu onaylarım.

**CURRENT CANONICAL WEIGHTS:** `closeness_pace +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style -2`

**CURRENT CLASSIFICATION:** `CLEAR_REMAP`

**PROPOSED CANONICAL WEIGHTS:** `closeness_pace +1`, `repair_style +1`

**REASON:** Validating the partner's feeling during a clash is emotion-focused conflict processing. closeness_pace is a stretch but still describes staying with the other person's inner state; repair_style +1 is the defensible added score. Not +2: they are not repairing a rupture so much as holding the disagreement.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** Keep only `closeness_pace +1` and DROP the repair add — this is holding a disagreement, not repairing a rupture.

**RISK IF ACCEPTED:** Emotion-focused listening in debate would be counted as high repair_style, mixing support-in-disagreement with rupture repair.

### frequency_v2_q0015_a

**QUESTION ID:** `frequency_v2_q0015`

**QUESTION TEXT:** Stresli bir anında partnerine gereksiz yere sert çıkıştın. 10 dakika sonra durumu fark ettin.

**CONTEXT:** conflict

**OPTION ID:** `frequency_v2_q0015_a`

**OPTION TEXT:** Hemen yanına gidip sarılarak, duygusal bir şekilde özür dilerim.

**CURRENT CANONICAL WEIGHTS:** `reassurance_need +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style -2`

**CURRENT CLASSIFICATION:** `CLEAR_REMAP`

**PROPOSED CANONICAL WEIGHTS:** `reassurance_need +1`, `repair_style +2`

**REASON:** Immediate hug-and-apology after snapping is post-conflict repair, the one case where processing_style−2 actually meant repair. Keep reassurance_need +1 (seeking/giving emotional reconnection).

**CONFIDENCE:** high

**ALTERNATIVE INTERPRETATION:** NONE — this is one of the cleanest repair acts in the leftover set.

**RISK IF ACCEPTED:** If this is really reassurance-seeking more than repair, repair_style would be inflated for people who hug-apologize mainly to feel close again.

### frequency_v2_q0015_b

**QUESTION ID:** `frequency_v2_q0015`

**QUESTION TEXT:** Stresli bir anında partnerine gereksiz yere sert çıkıştın. 10 dakika sonra durumu fark ettin.

**CONTEXT:** conflict

**OPTION ID:** `frequency_v2_q0015_b`

**OPTION TEXT:** Stresimin kaynağını rasyonel bir dille açıklayarak durumu telafi edecek bir konuşma yaparım.

**CURRENT CANONICAL WEIGHTS:** `boundary_firmness +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `CLEAR_REMAP`

**PROPOSED CANONICAL WEIGHTS:** `boundary_firmness +1`, `repair_style +1`

**REASON:** Explaining the stress source in order to make amends is verbal repair, not a generic 'rational personality'. Keep boundary_firmness +1 (stating one's account). Not +2: the same wording can also be self-justifying rather than repairing.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** `structure_preference +1` (explaining causes as a system) and keep repair at 0, or `repair_style +2` if the human reads this as a full amends talk.

**RISK IF ACCEPTED:** Self-justifying explanations after snapping would be scored as constructive repair.

### frequency_v2_q0015_d

**QUESTION ID:** `frequency_v2_q0015`

**QUESTION TEXT:** Stresli bir anında partnerine gereksiz yere sert çıkıştın. 10 dakika sonra durumu fark ettin.

**CONTEXT:** conflict

**OPTION ID:** `frequency_v2_q0015_d`

**OPTION TEXT:** Bir süre daha kendi alanımda kalır, ikimizin de tamamen sakinleştiğinden emin olunca konuyu açarım.

**CURRENT CANONICAL WEIGHTS:** `autonomy +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `CLEAR_REMAP`

**PROPOSED CANONICAL WEIGHTS:** `autonomy +1`, `repair_style -1`

**REASON:** Waiting until both are calm is delayed repair plus space. autonomy +1 already fits; remap the leftover processing_style to repair_style −1 rather than forcing it to +2 structure/logic.

**CONFIDENCE:** high

**ALTERNATIVE INTERPRETATION:** Keep `autonomy +1` only (DROP repair_style). Delay can be space-need without a repair method.

**RISK IF ACCEPTED:** Space-takers after conflict would look low-repair even when they do return and talk.

### frequency_v2_q0029_a

**QUESTION ID:** `frequency_v2_q0029`

**QUESTION TEXT:** Partnerin basit bir unutkanlık yaptı (örn: senin için önemli bir evrakı almayı unuttu) ve bu sana zaman kaybettirdi.

**CONTEXT:** conflict

**OPTION ID:** `frequency_v2_q0029_a`

**OPTION TEXT:** Sinirlendiğimi belli ederim ama sonrasında hemen affedici moda geçerim.

**CURRENT CANONICAL WEIGHTS:** `uncertainty_tolerance -1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style -2`

**CURRENT CLASSIFICATION:** `CLEAR_REMAP`

**PROPOSED CANONICAL WEIGHTS:** `uncertainty_tolerance -1`, `repair_style +1`

**REASON:** Showing anger then quickly forgiving is a short repair cycle after a small hurt. Keep uncertainty_tolerance −1 (low tolerance for the disruption). Not +2: the option is a flash of affect, not a full repair method.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** Keep `uncertainty_tolerance −1` only. Flash-anger-then-forgive may be affect, not a repair method.

**RISK IF ACCEPTED:** Quick-forgive flashes would be stored as active repair, overstating how they handle real ruptures.

### frequency_v2_q0037_a

**QUESTION ID:** `frequency_v2_q0037`

**QUESTION TEXT:** Gece uyumak üzeresin, çok yorgunsun. Partnerin aniden ilişkinizle ilgili derin ve ciddi bir konuyu açtı.

**CONTEXT:** conflict

**OPTION ID:** `frequency_v2_q0037_a`

**OPTION TEXT:** Uykumu böler, konu çözülene kadar saatlerce konuşurum. Çözmeden uyuyamam.

**CURRENT CANONICAL WEIGHTS:** `closeness_pace +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style -2`

**CURRENT CLASSIFICATION:** `CLEAR_REMAP`

**PROPOSED CANONICAL WEIGHTS:** `closeness_pace +1`, `repair_style +2`

**REASON:** Cannot sleep until the relationship topic is processed: this is immediate conflict processing, i.e. high repair_style. closeness_pace +1 (staying in the conversation) still fits.

**CONFIDENCE:** high

**ALTERNATIVE INTERPRETATION:** Keep `closeness_pace +1` plus `boundary_firmness −1` (cannot hold a sleep limit) instead of repair_style +2.

**RISK IF ACCEPTED:** Night-talk insistence would dominate repair_style for people who process immediately but repair poorly by day.

### frequency_v2_q0037_b

**QUESTION ID:** `frequency_v2_q0037`

**QUESTION TEXT:** Gece uyumak üzeresin, çok yorgunsun. Partnerin aniden ilişkinizle ilgili derin ve ciddi bir konuyu açtı.

**CONTEXT:** conflict

**OPTION ID:** `frequency_v2_q0037_b`

**OPTION TEXT:** "Bunu şimdi konuşmayalım, yarın sabah taze kafayla değerlendirelim" diyerek sınırı çekerim.

**CURRENT CANONICAL WEIGHTS:** `boundary_firmness +2`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `CLEAR_REMAP`

**PROPOSED CANONICAL WEIGHTS:** `boundary_firmness +2`, `repair_style -1`

**REASON:** Explicitly postponing the talk until morning is delayed repair plus a firm limit. Keep boundary_firmness +2; do not treat 'fresh head' as structure_preference.

**CONFIDENCE:** high

**ALTERNATIVE INTERPRETATION:** Keep `boundary_firmness +2` only. 'Tomorrow morning' is a limit; it is not necessarily low repair.

**RISK IF ACCEPTED:** People who postpone a 1 a.m. talk would look low-repair even when they do repair well after sleep.

### frequency_v2_q0043_a

**QUESTION ID:** `frequency_v2_q0043`

**QUESTION TEXT:** Partnerin kariyeriyle ilgili çok riskli ve zor bir karar aşamasında ve sana danıştı.

**CONTEXT:** support

**OPTION ID:** `frequency_v2_q0043_a`

**OPTION TEXT:** Artıları, eksileri masaya yatırır, en rasyonel kararı alması için analitik bir tablo çizerim.

**CURRENT CANONICAL WEIGHTS:** `initiative +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `CLEAR_REMAP`

**PROPOSED CANONICAL WEIGHTS:** `initiative +1`, `structure_preference +1`

**REASON:** Building a plus/minus table for a career decision is structured problem-solving, not repair. Keep initiative +1 (taking the advisor role) and add structure_preference +1. Not +2: this is advice, not running the partner's life.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** `initiative +1` only (DROP the structure add). A plus/minus list is advice, not a household system.

**RISK IF ACCEPTED:** Advisor-types would be scored as high structure_preference without living by plans themselves.

### frequency_v2_q0166_a

**QUESTION ID:** `frequency_v2_q0166`

**QUESTION TEXT:** Arabada uzun yoldasınız ve bir konu yüzünden sesler yükseldi, kavga çıktı. İdeal çözüm yöntemin nedir?

**CONTEXT:** conflict

**OPTION ID:** `frequency_v2_q0166_a`

**OPTION TEXT:** Arabayı sağa çekip veya yola devam edip, konu tamamen tatlıya bağlanana kadar konuşmak.

**CURRENT CANONICAL WEIGHTS:** `closeness_pace +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style -2`

**CURRENT CLASSIFICATION:** `CLEAR_REMAP`

**PROPOSED CANONICAL WEIGHTS:** `closeness_pace +1`, `repair_style +2`

**REASON:** A car fight processed until it is resolved is immediate repair. closeness_pace +1 (staying in the interaction) remains reasonable.

**CONFIDENCE:** high

**ALTERNATIVE INTERPRETATION:** NONE for repair_style +2. Optional extra: DROP `closeness_pace +1` as redundant with staying in the fight.

**RISK IF ACCEPTED:** Car-fight processors would look high-closeness as well as high-repair, double-counting the same stay-in-it act.

### frequency_v2_q0166_b

**QUESTION ID:** `frequency_v2_q0166`

**QUESTION TEXT:** Arabada uzun yoldasınız ve bir konu yüzünden sesler yükseldi, kavga çıktı. İdeal çözüm yöntemin nedir?

**CONTEXT:** conflict

**OPTION ID:** `frequency_v2_q0166_b`

**OPTION TEXT:** Radyoyu açıp, sessizliğe bürünüp en az 1 saat kendi düşüncelerimle baş başa kalmak.

**CURRENT CANONICAL WEIGHTS:** `autonomy +2`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `CLEAR_REMAP`

**PROPOSED CANONICAL WEIGHTS:** `autonomy +2`, `repair_style -2`

**REASON:** Radio on, hour of silence after a fight is withdrawal from repair, not 'being analytical'. Keep autonomy +2.

**CONFIDENCE:** high

**ALTERNATIVE INTERPRETATION:** `repair_style −1` (not −2) if the hour of silence is cooling, not refusing repair.

**RISK IF ACCEPTED:** People who need a silent drive after a fight would look like they never repair.

### frequency_v2_q0170_d

**QUESTION ID:** `frequency_v2_q0170`

**QUESTION TEXT:** Kötü bir tartışmadan sonra "Birkaç saat yalnız kalmaya ihtiyacım var" dedin. Ama partnerin konuyu çözmek için sürekli konuşmak istiyor.

**CONTEXT:** boundaries

**OPTION ID:** `frequency_v2_q0170_d`

**OPTION TEXT:** Mantıklı bir şekilde neden şu an konuşmanın zarar vereceğini açıklar, saat vererek (örn: "akşam konuşalım") sınırı çizerim.

**CURRENT CANONICAL WEIGHTS:** `structure_preference +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `CLEAR_REMAP`

**PROPOSED CANONICAL WEIGHTS:** `repair_style -1`, `structure_preference +1`

**REASON:** Explaining why talking now would harm, then time-boxing ('akşam konuşalım') is delayed, scheduled repair. Keep structure_preference +1. This is the rare processing_style+2 that is actually about post-conflict process, not IQ.

**CONFIDENCE:** high

**ALTERNATIVE INTERPRETATION:** `boundary_firmness +1` instead of `repair_style −1` (time-box as a limit, not delayed repair).

**RISK IF ACCEPTED:** Scheduled 'talk tonight' would be stored as low repair rather than firm, organized reconnection.

### frequency_v2_q0186_b

**QUESTION ID:** `frequency_v2_q0186`

**QUESTION TEXT:** Büyük bir kavgada bağırdın, çağırdın. Ancak 10 dakika sonra aslında tamamen *senin haksız olduğunu* fark ettin.

**CONTEXT:** conflict

**OPTION ID:** `frequency_v2_q0186_b`

**OPTION TEXT:** Anında yanına gider, gurur yapmadan "Ben yanlış anlamışım, çok özür dilerim" derim.

**CURRENT CANONICAL WEIGHTS:** `boundary_firmness -1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `CLEAR_REMAP`

**PROPOSED CANONICAL WEIGHTS:** `boundary_firmness -1`, `repair_style +2`

**REASON:** Immediate full apology after realizing they were wrong is high repair_style. Keep boundary_firmness −1 (dropping the defensive stance). processing_style+2 here was mis-tagged; the behavior is repair, not analysis.

**CONFIDENCE:** high

**ALTERNATIVE INTERPRETATION:** NONE — immediate full apology after being wrong is a core repair act.

**RISK IF ACCEPTED:** Pride-swallowing apology would over-weight repair_style if the person otherwise score-keeps (see option D).

### frequency_v2_q0252_a

**QUESTION ID:** `frequency_v2_q0252`

**QUESTION TEXT:** Partnerin evdeyken senin için manevi değeri çok yüksek olan bir eşyayı (örn: eski bir vazo/kupa) yanlışlıkla kırdı.

**CONTEXT:** conflict

**OPTION ID:** `frequency_v2_q0252_a`

**OPTION TEXT:** O anki refleksimle sinirlendiğimi belli ederim ama sonrasında toparlayıp affederim.

**CURRENT CANONICAL WEIGHTS:** `disclosure_pace +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style -2`

**CURRENT CLASSIFICATION:** `CLEAR_REMAP`

**PROPOSED CANONICAL WEIGHTS:** `disclosure_pace +1`, `repair_style +1`

**REASON:** Show irritation then forgive after a broken object: short repair cycle. Keep disclosure_pace +1 (the irritation is shown). Not +2: this is a flash-and-forgive, not a repair method.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** Keep `disclosure_pace +1` only. Flash-anger-then-forgive over a broken object may not be couple-repair.

**RISK IF ACCEPTED:** Startle-then-forgive would be stored as repair method, mixing accident-affect with rupture repair.

### frequency_v2_q0261_a

**QUESTION ID:** `frequency_v2_q0261`

**QUESTION TEXT:** İkiniz arasında ufak bir yanlış anlaşılma oldu. Partnerin olayı sana uzun uzun, detaylıca ve kendini sürekli savunarak açıklamaya çalışıyor.

**CONTEXT:** conflict

**OPTION ID:** `frequency_v2_q0261_a`

**OPTION TEXT:** "Anladım, sorun yok" diyerek onu hızlıca durdurur ve konuyu kestirip atarım.

**CURRENT CANONICAL WEIGHTS:** `contact_need -1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `CLEAR_REMAP`

**PROPOSED CANONICAL WEIGHTS:** `contact_need -1`, `repair_style -2`

**REASON:** Cutting off the partner's processing of a misunderstanding is avoidant repair. contact_need −1 is weak but still describes wanting the interaction over; do not inflate it. processing_style+2 was 'shut it down rationally' and should not become structure_preference.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** `disclosure_pace −1` or DROP `contact_need −1` as a weak leftover. Repair_style −2 may overfit a small misunderstanding.

**RISK IF ACCEPTED:** People who hate looping a small mix-up would look strongly avoidant-repair.

### frequency_v2_q0357_d

**QUESTION ID:** `frequency_v2_q0357`

**QUESTION TEXT:** Birlikte uzun yola çıkacaksınız ancak müzik zevkleriniz birbirinden siyah ve beyaz kadar farklı.

**CONTEXT:** established

**OPTION ID:** `frequency_v2_q0357_d`

**OPTION TEXT:** İkimizin de çok sevmediği ama rahatsız da olmadığı "nötr" bir radyo/podcast açar, ortak zemin bulurum.

**CURRENT CANONICAL WEIGHTS:** `uncertainty_tolerance +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `CLEAR_REMAP`

**PROPOSED CANONICAL WEIGHTS:** `uncertainty_tolerance +1`, `adaptability +1`

**REASON:** Picking a neutral radio/podcast neither person loves is matching to a shared middle, i.e. adaptability. Keep uncertainty_tolerance +1 (tolerating a non-preferred soundtrack). Not repair.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** `structure_preference +1` (a shared default rule) instead of `adaptability +1`.

**RISK IF ACCEPTED:** Compromise-by-neutral-media would be scored as high adaptability when it is actually a fixed middle rule.

### frequency_v2_q0369_a

**QUESTION ID:** `frequency_v2_q0369`

**QUESTION TEXT:** Partnerin yıllardır yapmak istediği ama gelir garantisi olmayan sanatsal/serbest bir mesleğe (örn: müzisyenlik) geçmek istediğini açıkladı.

**CONTEXT:** planning

**OPTION ID:** `frequency_v2_q0369_a`

**OPTION TEXT:** Birlikte finansal bir plan yaparız, ben bir süre evin yükünü çekerim, hayalini yaşamasını desteklerim.

**CURRENT CANONICAL WEIGHTS:** `closeness_pace +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `CLEAR_REMAP`

**PROPOSED CANONICAL WEIGHTS:** `closeness_pace +1`, `structure_preference +1`

**REASON:** Joint financial planning plus carrying household load is structure plus closeness, not processing_style. Existing closeness_pace +1 stays; add structure_preference +1. Not +2: support is mixed with planning, and 'I'll carry the house' is also adaptability/closeness.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** `adaptability +1` (carrying household load for their path) instead of `structure_preference +1`.

**RISK IF ACCEPTED:** Career-support via planning would be stored as structure_preference, missing the closeness/load-sharing half.

### frequency_v2_q0380_a

**QUESTION ID:** `frequency_v2_q0380`

**QUESTION TEXT:** Bir partidesiniz ve partnerin içkiyi fazla kaçırdı, saçmalamaya ve dengesini kaybetmeye başladı.

**CONTEXT:** social

**OPTION ID:** `frequency_v2_q0380_a`

**OPTION TEXT:** Hemen müdahale eder, koluna girer ve kimseye belli etmeden onu hızla eve götürürüm.

**CURRENT CANONICAL WEIGHTS:** `structure_preference +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `CLEAR_REMAP`

**PROPOSED CANONICAL WEIGHTS:** `initiative +2`

**REASON:** Taking the drunk partner's arm and leaving is crisis initiative, not processing_style and not structure_preference. Drop the existing structure_preference +1; it does not measure planning here.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** Keep `initiative +2` and restore `structure_preference +1` if extracting them is read as running a plan. Or `social_energy −1` (leave the party).

**RISK IF ACCEPTED:** Crisis extraction would inflate initiative for people who are otherwise low-initiative but cannot leave a drunk partner in public.

## B. HUMAN_DECISION_REQUIRED

Count: **37**. No safe automated remap. Proposed canonical weights = existing 12D only (legacy leftover not added). Pick an alternative, keep existing, or send to rewrite.

### frequency_v2_q0008_a

**QUESTION ID:** `frequency_v2_q0008`

**QUESTION TEXT:** Partnerin, senin bir davranış tarzını oldukça net ve yapıcı bir şekilde eleştirdi. İlk tepkin genelde nasıl şekillenir?

**CONTEXT:** conflict

**OPTION ID:** `frequency_v2_q0008_a`

**OPTION TEXT:** Savunmaya geçmeden önce kendi içimde bunu mantıklı bir şekilde tartmak için sessizleşirim.

**CURRENT CANONICAL WEIGHTS:** `disclosure_pace -1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `disclosure_pace -1`

**REASON:** Silence-to-think after criticism could be delayed repair, low disclosure, or mere cognitive style. disclosure_pace −1 already exists; adding repair_style would double-count without knowing whether the silence is repair work or shutdown.

**CONFIDENCE:** low

**ALTERNATIVE INTERPRETATION:** A: keep `disclosure_pace −1` only (recommended until a human picks). B: add `repair_style −1` if the silence is shutdown. C: add `repair_style +1` if it is private processing before amends.

**RISK IF ACCEPTED:** Choosing B would mark thoughtful pauses as avoidant repair; choosing C would mark shutdown as high repair.

### frequency_v2_q0016_c

**QUESTION ID:** `frequency_v2_q0016`

**QUESTION TEXT:** Partnerinin ufak ama senin günlük ritmini bozan bir alışkanlığı var (örn: eşyaları dağınık bırakmak).

**CONTEXT:** established

**OPTION ID:** `frequency_v2_q0016_c`

**OPTION TEXT:** Konuyu ciddi bir tartışmaya çevirmeden, şakayla karışık laf sokarak belli ederim.

**CURRENT CANONICAL WEIGHTS:** `uncertainty_tolerance +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style -1`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `uncertainty_tolerance +1`

**REASON:** Joke-hinting about mess could be low disclosure, avoidant repair, or low-stakes teasing. uncertainty_tolerance +1 is a weak existing fit. No single 12D is safe.

**CONFIDENCE:** low

**ALTERNATIVE INTERPRETATION:** A: `disclosure_pace −1` (indirect hint). B: `repair_style −1` (won't process the irritation). C: keep weak `uncertainty_tolerance +1`. D: DROP leftover, keep nothing extra.

**RISK IF ACCEPTED:** Joke-hints about mess would be stored as a conflict-repair style they may not use in real fights.

### frequency_v2_q0026_a

**QUESTION ID:** `frequency_v2_q0026`

**QUESTION TEXT:** Temel bir inanç veya hayata bakış açısı konusunda partnerinle tamamen zıt olduğunuzu fark ettiniz.

**CONTEXT:** conflict

**OPTION ID:** `frequency_v2_q0026_a`

**OPTION TEXT:** Bu konuyu derinlemesine, belki saatlerce tartışarak ortak bir zemin bulmaya çalışırım.

**CURRENT CANONICAL WEIGHTS:** `closeness_pace +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style -1`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `closeness_pace +1`

**REASON:** Hours of debate to find common ground could be initiative, closeness, or even repair if treated as conflict. It is also just intellectual engagement, which is not a 12D. closeness_pace +1 is already a stretch.

**CONFIDENCE:** low

**ALTERNATIVE INTERPRETATION:** A: `initiative +1` (driving the debate). B: `repair_style +1` only if worldview clash is treated as a rupture. C: DROP leftover; keep `closeness_pace +1`. D: no 12D (intellectual hobby).

**RISK IF ACCEPTED:** Hours of ideological debate would be stored as closeness or repair rather than optional intellectual engagement.

### frequency_v2_q0027_d

**QUESTION ID:** `frequency_v2_q0027`

**QUESTION TEXT:** Acil çözmen gereken zor bir problemin var, ama partnerin o gün çok kritik bir iş toplantısında.

**CONTEXT:** support

**OPTION ID:** `frequency_v2_q0027_d`

**OPTION TEXT:** Krizi fırsata çevirip işe odaklanırım, ona ancak akşam detaylıca olanları anlatırım.

**CURRENT CANONICAL WEIGHTS:** `adaptability -1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `adaptability -1`

**REASON:** Compartmentalizing a crisis until evening could be autonomy, delayed disclosure, or low adaptability (not matching the partner's availability). adaptability −1 is not obviously right. Do not map processing_style+2 to structure.

**CONFIDENCE:** low

**ALTERNATIVE INTERPRETATION:** A: `disclosure_pace −1` (tell later). B: `autonomy +1` (handle it alone). C: keep `adaptability −1`. D: DROP leftover.

**RISK IF ACCEPTED:** Compartmentalizing until evening would be scored as rigidity/low adaptability instead of ordinary work-hours boundaries.

### frequency_v2_q0030_c

**QUESTION ID:** `frequency_v2_q0030`

**QUESTION TEXT:** Partnerinin geçmişiyle ilgili zarar verici olmayan ama senin yeni öğrendiğin önemli bir detayı (örn: eski mesleği) gizlediğini fark ettin.

**CONTEXT:** uncertainty

**OPTION ID:** `frequency_v2_q0030_c`

**OPTION TEXT:** Neden saklama ihtiyacı duyduğunu anlamak için yargılamadan dinlemeye odaklanırım.

**CURRENT CANONICAL WEIGHTS:** `adaptability +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +1`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `adaptability +1`

**REASON:** Non-judgmental listening about a hidden past could be disclosure_pace, closeness, or adaptability. Existing adaptability +1 is plausible; processing_style+1 does not clearly add a second dimension.

**CONFIDENCE:** low

**ALTERNATIVE INTERPRETATION:** A: `closeness_pace +1` (staying with their reason). B: `disclosure_pace +1` (inviting the story). C: keep `adaptability +1` only.

**RISK IF ACCEPTED:** Non-judgmental listening would be double-counted if a second dimension is added on top of adaptability.

### frequency_v2_q0033_b

**QUESTION ID:** `frequency_v2_q0033`

**QUESTION TEXT:** Bir ilişkide "Seni seviyorum" demek veya derin duyguları itiraf etmek sence nasıl bir süreçtir?

**CONTEXT:** early_dating, uncertainty

**OPTION ID:** `frequency_v2_q0033_b`

**OPTION TEXT:** Zamanın geçmesini, güvenin oturmasını ve mantığımla da emin olmayı beklerim.

**CURRENT CANONICAL WEIGHTS:** `closeness_pace -2`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `closeness_pace -2`

**REASON:** Waiting for trust AND 'mantığımla da emin olmak' mixes slow closeness (already −2) with uncertainty intolerance. Adding uncertainty_tolerance −1 is tempting but not entailed; some people wait for trust without being low-UT.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** A: keep `closeness_pace −2` only. B: add `uncertainty_tolerance −1` ('mantığımla emin olmak').

**RISK IF ACCEPTED:** Slow I-love-you timing would be stored as low uncertainty_tolerance, mixing caution-about-love with intolerance of ambiguity.

### frequency_v2_q0038_d

**QUESTION ID:** `frequency_v2_q0038`

**QUESTION TEXT:** Sen çok düzenlisin, partnerin ise daha "dağınık" bir düzene sahip. Nasıl ilerlersiniz?

**CONTEXT:** established

**OPTION ID:** `frequency_v2_q0038_d`

**OPTION TEXT:** Zamanla ortada bir yerde buluşuruz, bu konuyu büyük bir çatışma haline getirmem.

**CURRENT CANONICAL WEIGHTS:** `uncertainty_tolerance +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +1`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `uncertainty_tolerance +1`

**REASON:** 'Zamanla ortada buluşuruz, çatışma haline getirmem' could be adaptability, avoidant repair, or genuine UT. Existing uncertainty_tolerance +1 is one reading; processing_style+1 should not auto-become structure or repair.

**CONFIDENCE:** low

**ALTERNATIVE INTERPRETATION:** A: `adaptability +1` (meet in the middle over time). B: `repair_style −1` (won't make it a fight). C: keep `uncertainty_tolerance +1`.

**RISK IF ACCEPTED:** Not turning messiness into a fight would be scored as high UT or low repair, depending on the call, with opposite pairing implications.

### frequency_v2_q0154_b

**QUESTION ID:** `frequency_v2_q0154`

**QUESTION TEXT:** Birlikte ilk kez 3 günlük bir tatile çıkacaksınız. Planlama süreci sence nasıl işlemeli?

**CONTEXT:** planning

**OPTION ID:** `frequency_v2_q0154_b`

**OPTION TEXT:** İkimiz boş bir akşamda bilgisayar başına oturup her adımı ortaklaşa ve eşit şekilde planlamalıyız.

**CURRENT CANONICAL WEIGHTS:** `closeness_pace +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style -1`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `closeness_pace +1`

**REASON:** Planning the trip jointly is collaborative process. That could be low initiative (shared control), closeness, or structure. closeness_pace +1 is already odd for a logistics item. processing_style−1 has no unique 12D home.

**CONFIDENCE:** low

**ALTERNATIVE INTERPRETATION:** A: `structure_preference +1` (joint planning session). B: `initiative −1` (shared control). C: keep `closeness_pace +1`. D: DROP leftover.

**RISK IF ACCEPTED:** Wanting to plan a trip together would be stored as closeness rather than structure/shared initiative.

### frequency_v2_q0163_b

**QUESTION ID:** `frequency_v2_q0163`

**QUESTION TEXT:** Sen iş yerinde berbat ve stresli bir gün geçirdin, partnerin ise harika haberler aldığı enerjik bir gün geçirdi. Akşam buluştunuz.

**CONTEXT:** support

**OPTION ID:** `frequency_v2_q0163_b`

**OPTION TEXT:** Önce kendi kötü günümü uzun uzun anlatıp deşarj olurum, sonra onun sevincini dinlerim.

**CURRENT CANONICAL WEIGHTS:** `boundary_firmness +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style -2`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `boundary_firmness +1`

**REASON:** Dumping the bad day first then listening could be high disclosure, contact_need, or boundary (claiming airtime). boundary_firmness +1 is a questionable existing weight. processing_style−2 should not become repair_style; this is not a couple fight.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** A: `disclosure_pace +2` (dump then listen). B: `contact_need +1`. C: keep `boundary_firmness +1`. D: DROP leftover.

**RISK IF ACCEPTED:** Claiming airtime after a bad day would be stored as high boundary_firmness, a poor fit for support-sharing.

### frequency_v2_q0166_d

**QUESTION ID:** `frequency_v2_q0166`

**QUESTION TEXT:** Arabada uzun yoldasınız ve bir konu yüzünden sesler yükseldi, kavga çıktı. İdeal çözüm yöntemin nedir?

**CONTEXT:** conflict

**OPTION ID:** `frequency_v2_q0166_d`

**OPTION TEXT:** Mantıklı argümanlarımı sonuna kadar sunmak ve onun nerede hatalı olduğunu netleştirmek.

**CURRENT CANONICAL WEIGHTS:** `boundary_firmness +2`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +1`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `boundary_firmness +2`

**REASON:** Arguing until the partner's error is proven is winning a fight, not repair, and not 'processing_style'. boundary_firmness +2 already captures standing one's ground. Adding initiative or negative repair_style would pick a theory we cannot defend from the wording alone.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** A: keep `boundary_firmness +2` only. B: add `repair_style −1` (winning vs repairing). C: add `initiative +1` (driving the argument).

**RISK IF ACCEPTED:** Proving the partner wrong would be stored as high repair or high initiative rather than standing one's ground.

### frequency_v2_q0170_c

**QUESTION ID:** `frequency_v2_q0170`

**QUESTION TEXT:** Kötü bir tartışmadan sonra "Birkaç saat yalnız kalmaya ihtiyacım var" dedin. Ama partnerin konuyu çözmek için sürekli konuşmak istiyor.

**CONTEXT:** boundaries

**OPTION ID:** `frequency_v2_q0170_c`

**OPTION TEXT:** Konuşmasına izin veririm ama dinlemediğimi, sadece beklediğimi belli eden sessiz bir tavır alırım.

**CURRENT CANONICAL WEIGHTS:** `uncertainty_tolerance -1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style -1`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `uncertainty_tolerance -1`

**REASON:** Allowing talk while visibly not listening is blocked/passive-aggressive repair, low disclosure, or weak boundary. uncertainty_tolerance −1 is a poor existing fit. Needs a human call before any remap.

**CONFIDENCE:** low

**ALTERNATIVE INTERPRETATION:** A: `repair_style −2` (blocked processing). B: `disclosure_pace −1`. C: `boundary_firmness −1` (cannot hold the space request). D: DROP leftover; replace `uncertainty_tolerance −1`.

**RISK IF ACCEPTED:** Passive-listening-while-checked-out would be scored as low UT rather than stalled repair or weak boundary.

### frequency_v2_q0183_a

**QUESTION ID:** `frequency_v2_q0183`

**QUESTION TEXT:** Sen ağlayarak veya çok sinirli bir şekilde bir derdini anlatırken, partnerin sürekli "Şöyle yapmalısın, şurayı ara" diye çözümler sunuyor.

**CONTEXT:** support

**OPTION ID:** `frequency_v2_q0183_a`

**OPTION TEXT:** Bana akıl vermesi değil, sadece "çok haklısın, ne kadar üzücü" demesi gerektiği için sinirlenirim.

**CURRENT CANONICAL WEIGHTS:** `reassurance_need +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style -2`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `reassurance_need +1`

**REASON:** Anger that the partner offered solutions rather than validation is a support-language preference. It is not the respondent's repair_style. reassurance_need +1 fits; processing_style−2 should not be copied onto repair_style.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** A: keep `reassurance_need +1` (recommended). B: `boundary_firmness +1` (rejecting solution-mode). Do not map to repair_style.

**RISK IF ACCEPTED:** Wanting validation rather than tips would be stored as a repair method, distorting post-conflict scores.

### frequency_v2_q0183_b

**QUESTION ID:** `frequency_v2_q0183`

**QUESTION TEXT:** Sen ağlayarak veya çok sinirli bir şekilde bir derdini anlatırken, partnerin sürekli "Şöyle yapmalısın, şurayı ara" diye çözümler sunuyor.

**CONTEXT:** support

**OPTION ID:** `frequency_v2_q0183_b`

**OPTION TEXT:** Onun beni önemseme şeklinin bu olduğunu anlar, verdiği tavsiyeleri mantık süzgecinden geçiririm.

**CURRENT CANONICAL WEIGHTS:** `boundary_firmness -1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `boundary_firmness -1`

**REASON:** Treating unsolicited advice as care and filtering it logically could be adaptability, low boundary, or nothing 12D. boundary_firmness −1 is thin. Do not map to structure_preference.

**CONFIDENCE:** low

**ALTERNATIVE INTERPRETATION:** A: `adaptability +1` (taking their care language). B: keep `boundary_firmness −1`. C: DROP leftover (not a 12D).

**RISK IF ACCEPTED:** Accepting advice-as-care would be scored as low boundary rather than matching the partner's support style.

### frequency_v2_q0185_b

**QUESTION ID:** `frequency_v2_q0185`

**QUESTION TEXT:** En güvendiğin arkadaşın, partnerinin sana pek uygun olmadığını ve sana iyi gelmediğini düşündüğünü söyledi.

**CONTEXT:** social

**OPTION ID:** `frequency_v2_q0185_b`

**OPTION TEXT:** Arkadaşımın dışarıdan gördüğü ve benim göremediğim bir şey olabilir diye bunu ciddiye alır, analiz ederim.

**CURRENT CANONICAL WEIGHTS:** `boundary_firmness -1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `boundary_firmness -1`

**REASON:** Taking a friend's warning seriously and 'analyzing' it could be uncertainty, low boundary, or healthy reality-testing. processing_style+2 is the old rational tag and is not a 12D.

**CONFIDENCE:** low

**ALTERNATIVE INTERPRETATION:** A: `uncertainty_tolerance −1` (the warning creates doubt). B: keep `boundary_firmness −1`. C: DROP leftover (reality-testing is not 12D).

**RISK IF ACCEPTED:** Taking a friend's concern seriously would look like weak boundaries instead of ordinary uncertainty.

### frequency_v2_q0186_d

**QUESTION ID:** `frequency_v2_q0186`

**QUESTION TEXT:** Büyük bir kavgada bağırdın, çağırdın. Ancak 10 dakika sonra aslında tamamen *senin haksız olduğunu* fark ettin.

**CONTEXT:** conflict

**OPTION ID:** `frequency_v2_q0186_d`

**OPTION TEXT:** Haklı olduğu tarafları kabul etsem de, benim o tepkiyi vermeme neden olan "onun" hatasını da masaya sürerim.

**CURRENT CANONICAL WEIGHTS:** `boundary_firmness +2`

**LEGACY / UNKNOWN WEIGHT:** `processing_style -1`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `boundary_firmness +2`

**REASON:** Apologizing for being wrong AND putting the partner's contribution on the table is mixed repair and score-keeping. boundary_firmness +2 already exists. Choosing repair_style +1 vs 0 vs −1 is a judgment call.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** A: add `repair_style +1` (admits fault and still talks it through). B: add `repair_style −1` (score-keeping). C: keep `boundary_firmness +2` only.

**RISK IF ACCEPTED:** Partial apology-plus-counterclaim would be stored as high repair or as non-repair depending on the call — opposite pairing signals.

### frequency_v2_q0192_b

**QUESTION ID:** `frequency_v2_q0192`

**QUESTION TEXT:** Partnerin hiç beklemediğin bir anda, çok küçük bir sebepten dolayı sinirleri bozulup ağlamaya başladı.

**CONTEXT:** support

**OPTION ID:** `frequency_v2_q0192_b`

**OPTION TEXT:** Sakin ve şefkatli kalır, "Buna bu kadar üzülmenin asıl sebebi ne?" diye sorarak kök sorunu anlamaya çalışırım.

**CURRENT CANONICAL WEIGHTS:** `initiative +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `initiative +1`

**REASON:** Asking for the root cause of sudden tears could be initiative, structure, closeness, or unhelpful psychologizing. Not repair_style (no couple rupture). initiative +1 is one reading; processing_style+2 should not auto-add structure_preference.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** A: keep `initiative +1`. B: `closeness_pace +1` (staying with the feeling via questions). C: DROP leftover (psychologizing is not 12D).

**RISK IF ACCEPTED:** Asking 'what's the real reason' during tears would be scored as high initiative / problem-solving, including for people who are just trying to understand.

### frequency_v2_q0195_c

**QUESTION ID:** `frequency_v2_q0195`

**QUESTION TEXT:** Partnerinin telefonunda şüpheli bir mesaj bildirimi gördün (ekran kilitli).

**CONTEXT:** uncertainty

**OPTION ID:** `frequency_v2_q0195_c`

**OPTION TEXT:** Kendime hakim olur, telefonu kurcalamanın sınırı aşmak olduğuna inandığım için bakmam.

**CURRENT CANONICAL WEIGHTS:** `boundary_firmness +2`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +1`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `boundary_firmness +2`

**REASON:** Not snooping because it would cross a line is already boundary_firmness +2. processing_style+1 is self-control/rationalization, not a second 12D. Could also be read as uncertainty_tolerance +1 (living with not knowing).

**CONFIDENCE:** low

**ALTERNATIVE INTERPRETATION:** A: keep `boundary_firmness +2` only. B: add `uncertainty_tolerance +1` (live with not knowing). C: DROP leftover.

**RISK IF ACCEPTED:** Not snooping would be stored as high UT as well as high boundary, mixing privacy ethics with ambiguity-tolerance.

### frequency_v2_q0195_d

**QUESTION ID:** `frequency_v2_q0195`

**QUESTION TEXT:** Partnerinin telefonunda şüpheli bir mesaj bildirimi gördün (ekran kilitli).

**CONTEXT:** uncertainty

**OPTION ID:** `frequency_v2_q0195_d`

**OPTION TEXT:** Mesajın devamı gelecek mi veya davranışlarında bir tuhaflık var mı diye günlerce uzaktan izlerim.

**CURRENT CANONICAL WEIGHTS:** `uncertainty_tolerance +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `uncertainty_tolerance +1`

**REASON:** Days of distal watching after a notification could be low UT (cannot let it go), high UT (does not confront), reassurance_need, or a surveillance item that should not be in Frequency at all. Existing uncertainty_tolerance +1 points the wrong way if this is rumination.

**CONFIDENCE:** low

**ALTERNATIVE INTERPRETATION:** A: `uncertainty_tolerance −2` (cannot let it go). B: `reassurance_need +1`. C: keep the existing `uncertainty_tolerance +1` (probably the wrong sign). D: drop the option from the bank (surveillance).

**RISK IF ACCEPTED:** Days of watching would be stored as high UT if the current sign is kept, which is the opposite of rumination.

### frequency_v2_q0198_a

**QUESTION ID:** `frequency_v2_q0198`

**QUESTION TEXT:** Partnerin o gün nedensiz yere çok huysuz, her şeye itiraz ediyor ve negatif bir enerji yayıyor.

**CONTEXT:** support

**OPTION ID:** `frequency_v2_q0198_a`

**OPTION TEXT:** Bu negatiflik bana da geçer, ben de sinirlenmeye ve ona sert tepkiler vermeye başlarım.

**CURRENT CANONICAL WEIGHTS:** `adaptability +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style -2`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `adaptability +1`

**REASON:** Catching the partner's irritability is emotional contagion. adaptability +1 is an awkward existing score (matching by getting worse). processing_style−2 is not a 12D. Could be low adaptability instead.

**CONFIDENCE:** low

**ALTERNATIVE INTERPRETATION:** A: `adaptability −1` (matching by getting worse is failed matching). B: keep `adaptability +1`. C: DROP leftover (contagion is not 12D).

**RISK IF ACCEPTED:** Catching a bad mood would be scored as high adaptability, i.e. the opposite of 'I get pulled into the spiral'.

### frequency_v2_q0252_c

**QUESTION ID:** `frequency_v2_q0252`

**QUESTION TEXT:** Partnerin evdeyken senin için manevi değeri çok yüksek olan bir eşyayı (örn: eski bir vazo/kupa) yanlışlıkla kırdı.

**CONTEXT:** conflict

**OPTION ID:** `frequency_v2_q0252_c`

**OPTION TEXT:** Neden dikkat etmediğini sorgular, içsel bir kızgınlık yaşar ama tartışmamak için sessiz kalırım.

**CURRENT CANONICAL WEIGHTS:** `boundary_firmness +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style -1`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `boundary_firmness +1`

**REASON:** Questioning carelessness then staying silently angry mixes boundary, low disclosure, and unfinished repair. boundary_firmness +1 is only partly right. No clean remap.

**CONFIDENCE:** low

**ALTERNATIVE INTERPRETATION:** A: `disclosure_pace −1` (silent anger). B: `repair_style −1` (unfinished). C: keep `boundary_firmness +1`.

**RISK IF ACCEPTED:** Silent questioning after a broken object would be stored as firm boundaries rather than withheld repair/disclosure.

### frequency_v2_q0256_c

**QUESTION ID:** `frequency_v2_q0256`

**QUESTION TEXT:** Partnerine bir hediye aldın ama paketi açtığında yüzündeki yarım saniyelik ifadeden aslında hiç beğenmediğini anladın.

**CONTEXT:** early_dating, uncertainty

**OPTION ID:** `frequency_v2_q0256_c`

**OPTION TEXT:** "İstersen değiştirebiliriz, fişi bende" diyerek pratik ve rasyonel bir çözüm sunarım.

**CURRENT CANONICAL WEIGHTS:** `boundary_firmness +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `boundary_firmness +1`

**REASON:** Offering to exchange the gift with the receipt is practical problem-solving. Could be initiative, structure, or low closeness (skipping the feeling). boundary_firmness +1 is a weak existing fit. Not repair.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** A: `initiative +1`. B: `structure_preference +1` (receipt as a system). C: keep `boundary_firmness +1`. D: DROP leftover.

**RISK IF ACCEPTED:** Offering to exchange a gift would be scored as high boundary instead of practical initiative, missing the skip-the-feeling reading.

### frequency_v2_q0264_b

**QUESTION ID:** `frequency_v2_q0264`

**QUESTION TEXT:** Kendi hayatınla ilgili çok kötü bir haber aldın. Partnerine bu haberi nasıl verirsin?

**CONTEXT:** support

**OPTION ID:** `frequency_v2_q0264_b`

**OPTION TEXT:** Önce kendi içimde olayı sindirir, ne yapacağımı planlar, ona sadece "son durumu" bildiririm.

**CURRENT CANONICAL WEIGHTS:** `autonomy +2`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `autonomy +2`

**REASON:** Digest internally, plan, then report the outcome could be autonomy (already +2), structure_preference, or delayed disclosure. Adding structure would double-count the same 'I handle it alone' story.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** A: keep `autonomy +2` only. B: add `disclosure_pace −1`. C: add `structure_preference +1`. Do not add both B and C.

**RISK IF ACCEPTED:** Solo-digest-then-report would be double-counted as autonomy plus structure plus low disclosure for the same 'I handle it alone' story.

### frequency_v2_q0271_d

**QUESTION ID:** `frequency_v2_q0271`

**QUESTION TEXT:** Tatilde kiraladığınız otel odası fotoğraflardaki gibi çıkmadı, berbat durumda. Partnerin çok sinirlendi.

**CONTEXT:** support

**OPTION ID:** `frequency_v2_q0271_d`

**OPTION TEXT:** O sinirliyken uzak durur, sinirinin yatışmasını bekler, bu sırada kendi alternatiflerimi sessizce araştırırım.

**CURRENT CANONICAL WEIGHTS:** `autonomy +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +1`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `autonomy +1`

**REASON:** Waiting out the partner's anger while silently researching hotels is delayed support plus autonomy. Could also be initiative (already researching) or low repair engagement. autonomy +1 is incomplete.

**CONFIDENCE:** low

**ALTERNATIVE INTERPRETATION:** A: add `initiative +1` (already researching). B: add `repair_style −1` (won't engage their anger). C: keep `autonomy +1`.

**RISK IF ACCEPTED:** Waiting out hotel-anger while googling would look like low repair rather than crisis initiative plus space.

### frequency_v2_q0278_a

**QUESTION ID:** `frequency_v2_q0278`

**QUESTION TEXT:** Kendi kariyerin/ailenle ilgili bir konuyu anlatırken partnerin sürekli ne yapman gerektiği konusunda sana akıl veriyor.

**CONTEXT:** conflict

**OPTION ID:** `frequency_v2_q0278_a`

**OPTION TEXT:** Fikirlerini dikkate alır, objektif bir göz olduğu için söylediklerini faydalı bulurum.

**CURRENT CANONICAL WEIGHTS:** `adaptability +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `adaptability +1`

**REASON:** Finding unsolicited career advice useful could be adaptability, low boundary, or simply not a Frequency dimension (coachability). processing_style+2 is the old 'I like logic' tag.

**CONFIDENCE:** low

**ALTERNATIVE INTERPRETATION:** A: keep `adaptability +1`. B: `boundary_firmness −1`. C: DROP leftover (coachability is not a 12D).

**RISK IF ACCEPTED:** Finding unsolicited advice useful would be stored as high adaptability / low boundary for people who just like extra input.

### frequency_v2_q0287_b

**QUESTION ID:** `frequency_v2_q0287`

**QUESTION TEXT:** İkiniz de çok ilgili olduğunuz tarihi/siyasi bir konuda farklı uçlardasınız. Tartışma hararetlendi.

**CONTEXT:** conflict

**OPTION ID:** `frequency_v2_q0287_b`

**OPTION TEXT:** Saygı çerçevesinde kalarak, argümanlarımı makale ve kanıtlarla sunar, onu ikna etmeye çalışırım.

**CURRENT CANONICAL WEIGHTS:** `initiative +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `initiative +1`

**REASON:** Arguing politics with articles is debate, not repair. initiative +1 is one reading; it could also be boundary_firmness or nothing 12D (intellectual style). Do not map processing_style+2 to structure_preference.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** A: keep `initiative +1`. B: `boundary_firmness +1` (won't yield the view). C: DROP leftover (debate style is not 12D).

**RISK IF ACCEPTED:** Evidence-based political argument would be stored as relationship initiative, inflating 'takes the lead' in couple life.

### frequency_v2_q0288_d

**QUESTION ID:** `frequency_v2_q0288`

**QUESTION TEXT:** Partnerin genel olarak çok kararsız biri. Nereye gidileceğini, ne yeneceğini sana bırakıyor.

**CONTEXT:** planning

**OPTION ID:** `frequency_v2_q0288_d`

**OPTION TEXT:** Onun ne istediğini bulması için farklı seçenekler sunarak onu nazikçe karar vermeye zorlarım.

**CURRENT CANONICAL WEIGHTS:** `boundary_firmness +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `boundary_firmness +1`

**REASON:** Offering options to nudge a decision could be initiative, structure, or boundary (refusing to carry all decisions). boundary_firmness +1 is only one of those. processing_style+2 is not itself a dimension.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** A: `initiative +1` (driving a decision). B: `structure_preference +1` (choice architecture). C: keep `boundary_firmness +1`.

**RISK IF ACCEPTED:** Nudging a decisive choice would be stored as boundary rather than shared-planning initiative.

### frequency_v2_q0346_c

**QUESTION ID:** `frequency_v2_q0346`

**QUESTION TEXT:** Yabancı bir şehre tatile gittiniz. Partnerin navigasyon görevini üstlendi ama sizi tamamen yanlış bir yere götürüp kaybettirdi.

**CONTEXT:** support

**OPTION ID:** `frequency_v2_q0346_c`

**OPTION TEXT:** Kendi telefonumdan sessizce haritayı açar, ona belli etmeden doğru yolu bulması için ufak kopyalar veririm.

**CURRENT CANONICAL WEIGHTS:** `boundary_firmness -1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `boundary_firmness -1`

**REASON:** Silently opening a map and feeding hints could be low boundary, initiative, adaptability, or avoidant disclosure. processing_style+2 ('I solve it quietly') is not a 12D.

**CONFIDENCE:** low

**ALTERNATIVE INTERPRETATION:** A: `initiative +1` (quietly fixing). B: `disclosure_pace −1`. C: keep `boundary_firmness −1`. D: `adaptability +1`.

**RISK IF ACCEPTED:** Silent map-hints would be scored as weak boundaries instead of low-conflict initiative.

### frequency_v2_q0351_a

**QUESTION ID:** `frequency_v2_q0351`

**QUESTION TEXT:** Yaptığın bir işle (yemek, sunum, çizim) ilgili partnerinden fikir almadığın halde sana oldukça yapıcı ama eleştirel bir yorum yaptı.

**CONTEXT:** conflict

**OPTION ID:** `frequency_v2_q0351_a`

**OPTION TEXT:** Eleştiriyi mantık süzgecinden geçirir, haklıysa kendimi geliştirmek için bunu memnuniyetle kabul ederim.

**CURRENT CANONICAL WEIGHTS:** `boundary_firmness -1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `boundary_firmness -1`

**REASON:** Accepting criticism if it passes a logic filter could be low boundary, high adaptability, or non-12D openness to feedback. processing_style+2 should not become structure_preference.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** A: keep `boundary_firmness −1`. B: `adaptability +1`. C: DROP leftover (openness to critique is not 12D).

**RISK IF ACCEPTED:** Accepting useful critique would look like weak boundaries rather than ordinary flexibility.

### frequency_v2_q0354_c

**QUESTION ID:** `frequency_v2_q0354`

**QUESTION TEXT:** Gece 02:00. Uyumak üzeresin ama partnerin hayat, evren, çocukluğu ve korkuları hakkında çok derin bir sohbete başladı.

**CONTEXT:** early_dating, uncertainty

**OPTION ID:** `frequency_v2_q0354_c`

**OPTION TEXT:** Gözlerim kapanıyor olsa bile mantıklı cevaplar vermeye ve onun zihnine ayak uydurmaya çalışırım.

**CURRENT CANONICAL WEIGHTS:** `structure_preference -1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `structure_preference -1`

**REASON:** Trying to give 'logical answers' while falling asleep could be adaptability (matching their depth), low boundary, or disclosure. structure_preference −1 is a strange existing weight. processing_style+2 is cognitive coloring.

**CONFIDENCE:** low

**ALTERNATIVE INTERPRETATION:** A: `adaptability +1` (matching their depth despite sleep). B: `disclosure_pace +1`. C: replace `structure_preference −1` (poor existing fit). D: DROP leftover.

**RISK IF ACCEPTED:** Trying to keep up at 2 a.m. would be stored as low structure rather than matching / staying in disclosure.

### frequency_v2_q0356_d

**QUESTION ID:** `frequency_v2_q0356`

**QUESTION TEXT:** 1 haftalık deniz tatilinizin daha 2. gününde sen çok fena güneş geçmesi/gıda zehirlenmesi yaşadın ve odadasın.

**CONTEXT:** support

**OPTION ID:** `frequency_v2_q0356_d`

**OPTION TEXT:** Modum düşer, kendimi suçlu hissederim ve onun da keyfi kaçtı diye tatili tamamen bitirmeyi teklif ederim.

**CURRENT CANONICAL WEIGHTS:** `uncertainty_tolerance -1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style -2`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `uncertainty_tolerance -1`

**REASON:** Guilt plus offering to cancel the trip mixes reassurance_need, low UT, and over-adaptation. uncertainty_tolerance −1 is only a fragment. processing_style−2 is affect, not a dimension.

**CONFIDENCE:** low

**ALTERNATIVE INTERPRETATION:** A: `reassurance_need +1` (guilt). B: `adaptability −1` or +1 depending on whether cancelling is over-matching. C: keep `uncertainty_tolerance −1`.

**RISK IF ACCEPTED:** Offering to cancel a trip out of guilt would be stored only as low UT, missing the reassurance/over-adaptation mix.

### frequency_v2_q0358_d

**QUESTION ID:** `frequency_v2_q0358`

**QUESTION TEXT:** Partnerin sosyal medyada çok tartışmalı ve senin hiç katılmadığın, hatta rahatsız olduğun bir politik/sosyal görüş paylaştı.

**CONTEXT:** social

**OPTION ID:** `frequency_v2_q0358_d`

**OPTION TEXT:** Fikrinin kökenini anlamak için yargılamadan, sadece meraktan "O paylaşımında ne demek istedin?" diye sorarım.

**CURRENT CANONICAL WEIGHTS:** `uncertainty_tolerance +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `uncertainty_tolerance +1`

**REASON:** Curious, non-judgmental asking about a post could be disclosure, closeness, UT, or none. uncertainty_tolerance +1 is not uniquely implied. Not repair.

**CONFIDENCE:** low

**ALTERNATIVE INTERPRETATION:** A: `disclosure_pace +1` (asking). B: `closeness_pace +1`. C: keep `uncertainty_tolerance +1`. D: DROP leftover.

**RISK IF ACCEPTED:** Curious follow-up on a post would be stored as high UT rather than disclosure/closeness.

### frequency_v2_q0359_d

**QUESTION ID:** `frequency_v2_q0359`

**QUESTION TEXT:** Sinemadasınız ve arkanızdaki çift sürekli yüksek sesle konuşuyor. Partnerin rahatsız olduğunu belli ediyor ama bir şey demiyor.

**CONTEXT:** social

**OPTION ID:** `frequency_v2_q0359_d`

**OPTION TEXT:** Yüksek sesle "ŞŞŞŞ!" yaparak isimsiz bir uyarı gönderir, duruma gerginlik katmadan sorunu çözerim.

**CURRENT CANONICAL WEIGHTS:** `social_energy +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style -1`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `social_energy +1`

**REASON:** A public 'şşş' is social control, possibly initiative or boundary. social_energy +1 is a poor existing fit. processing_style−1 does not clarify it.

**CONFIDENCE:** low

**ALTERNATIVE INTERPRETATION:** A: `initiative +1`. B: `boundary_firmness +1`. C: replace `social_energy +1` (poor existing fit). D: DROP leftover.

**RISK IF ACCEPTED:** A public shush would be stored as high social_energy, i.e. the opposite of 'I don't want a scene but I still intervene'.

### frequency_v2_q0364_c

**QUESTION ID:** `frequency_v2_q0364`

**QUESTION TEXT:** Giyim tarzın veya işyerindeki karşı cins arkadaşların konusunda partnerin çok ufak ama istikrarlı kıskançlık krizleri yaratıyor.

**CONTEXT:** uncertainty

**OPTION ID:** `frequency_v2_q0364_c`

**OPTION TEXT:** Neden kıskandığını derinlemesine konuşur, mantıklı güvenceler vererek korkularını gidermeye çalışırım.

**CURRENT CANONICAL WEIGHTS:** `reassurance_need +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `reassurance_need +1`

**REASON:** Deep-talk plus 'mantıklı güvenceler' for jealousy could be giving reassurance, adaptability, or a repair-like conversation that is not post-conflict repair. reassurance_need +1 already exists; processing_style+2 should not add structure.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** A: keep `reassurance_need +1` (giving reassurance). B: `adaptability +1` (accommodating the jealousy). Do not add repair_style (no rupture).

**RISK IF ACCEPTED:** Talking through jealousy would be stored as high repair or high adaptability, mixing accommodation with post-conflict repair.

### frequency_v2_q0370_d

**QUESTION ID:** `frequency_v2_q0370`

**QUESTION TEXT:** Gece yarısı partnerinin telefonuna kayıtlı olmayan bir numaradan sadece "Uyudun mu?" mesajı geldi.

**CONTEXT:** uncertainty

**OPTION ID:** `frequency_v2_q0370_d`

**OPTION TEXT:** Numaranın kime ait olduğunu kendi telefonumdan/uygulamalardan gizlice araştırmaya çalışırım.

**CURRENT CANONICAL WEIGHTS:** `boundary_firmness -1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style -2`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `boundary_firmness -1`

**REASON:** Secretly researching an unknown number is low boundary and low uncertainty_tolerance / high reassurance, and may not belong in a 12D behavioral bank at all. processing_style−2 is not a map; it is a dumping ground for 'emotional/paranoid'.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** A: `uncertainty_tolerance −2` plus `boundary_firmness −1`. B: `reassurance_need +1`. C: drop the option from the 12D bank (covert checking is a different construct).

**RISK IF ACCEPTED:** Secret number-lookup would be stored as ordinary low-boundary behavior rather than flagged as a non-12D surveillance act.

### frequency_v2_q0381_c

**QUESTION ID:** `frequency_v2_q0381`

**QUESTION TEXT:** Yıllardır tuttuğun çok özel, karanlık veya derin düşüncelerinin olduğu bir günlüğün var. Partnerin bunu masada açık bulup okuduğunu itiraf etti.

**CONTEXT:** boundaries

**OPTION ID:** `frequency_v2_q0381_c`

**OPTION TEXT:** Çok bozulurum ama kavga çıkmasın diye günlüğü sessizce çöpe atar veya saklar, konuyu kapatırım.

**CURRENT CANONICAL WEIGHTS:** `disclosure_pace -2`

**LEGACY / UNKNOWN WEIGHT:** `processing_style -1`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `disclosure_pace -2`

**REASON:** Binning the diary and closing the topic to avoid a fight could be low disclosure (already −2) or avoidant repair. Adding repair_style −2 would double-count the same shutdown.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** A: keep `disclosure_pace −2` only. B: add `repair_style −2` if closing the topic is avoidant repair. Do not add both at full strength.

**RISK IF ACCEPTED:** Shutting down after a diary breach would double-count as both extremely low disclosure and extremely avoidant repair.

### frequency_v2_q0390_d

**QUESTION ID:** `frequency_v2_q0390`

**QUESTION TEXT:** Sokakta yürürken veya kafedeyken ilişkinizle ilgili çok gergin bir tartışma alevlendi.

**CONTEXT:** conflict

**OPTION ID:** `frequency_v2_q0390_d`

**OPTION TEXT:** Fısıldayarak veya masaya doğru eğilerek, dışarıya hiç belli etmeden kelime savaşına devam ederim.

**CURRENT CANONICAL WEIGHTS:** `autonomy +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `autonomy +1`

**REASON:** Whisper-fighting in public could be high disclosure (still arguing), low social_energy, or 'controlled' processing. autonomy +1 is a weak existing fit. processing_style+2 does not pick a winner.

**CONFIDENCE:** low

**ALTERNATIVE INTERPRETATION:** A: `disclosure_pace +1` (still arguing). B: `social_energy −1` (hide it from the room). C: replace `autonomy +1` (weak fit).

**RISK IF ACCEPTED:** Whisper-fighting would be stored as high autonomy rather than 'I still process the fight but I hide it in public'.

### frequency_v2_q0392_a

**QUESTION ID:** `frequency_v2_q0392`

**QUESTION TEXT:** Partnerin "Artık diyeti ve sporu bırakıyorum, hayatı yaşayacağım" diyerek aylar süren disiplinini bir günde çöpe attı.

**CONTEXT:** established

**OPTION ID:** `frequency_v2_q0392_a`

**OPTION TEXT:** "Neden böyle hissettin, yoruldun mu?" diyerek altta yatan psikolojik sebebi anlamaya çalışırım.

**CURRENT CANONICAL WEIGHTS:** `closeness_pace +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `HUMAN_DECISION_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `closeness_pace +1`

**REASON:** Asking the psychological reason they dropped diet/sport could be closeness, initiative, or non-12D amateur therapy. closeness_pace +1 is one reading. processing_style+2 is not structure or repair.

**CONFIDENCE:** low

**ALTERNATIVE INTERPRETATION:** A: keep `closeness_pace +1`. B: `initiative +1` (they start the why-talk). C: DROP leftover (not 12D therapy).

**RISK IF ACCEPTED:** Asking why they dropped a routine would be stored as closeness or amateur-analysis initiative, neither of which is clearly right.

## C. REWRITE_REQUIRED

Count: **9**. Four of these sit on stems that are not respondent behavior (see §E). The other four need an observable tell on a single option.

### frequency_v2_q0169_b

**QUESTION ID:** `frequency_v2_q0169`

**QUESTION TEXT:** Hayatındaki işler hiç yolunda gitmiyor. Partnerinin sana yaklaşımı nasıl olmalı?

**CONTEXT:** support

**OPTION ID:** `frequency_v2_q0169_b`

**OPTION TEXT:** Benim yerime pratik işlerimi (fatura ödemek, yemek yapmak) halledip omuzumdaki yükü almalı.

**CURRENT CANONICAL WEIGHTS:** `closeness_pace +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +2`

**CURRENT CLASSIFICATION:** `REWRITE_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `closeness_pace +1`

**REASON:** The stem asks how the partner should approach you, so this option scores a desired-care-language, not a respondent 12D act. processing_style+2 (instrumental help) cannot be remapped until the item is rewritten as 'what do YOU do'.

**CONFIDENCE:** high

**ALTERNATIVE INTERPRETATION:** NONE until the stem is rewritten as respondent behavior. After rewrite, `initiative +1` / `structure_preference +1` (asking for practical help) is defensible.

**RISK IF ACCEPTED:** If scored as-is, desired partner acts-of-service would be stored as the respondent's closeness_pace.

**ORIGINAL:** Hayatındaki işler hiç yolunda gitmiyor. Partnerinin sana yaklaşımı nasıl olmalı?

**PROPOSED REWRITE:** Full stem + four-option rewrite is in §E (`frequency_v2_q0169`).

**WHY THIS REWRITE IS BETTER:** Stem currently asks how the partner should approach you. Rewrite as what you do when work is stacked.

### frequency_v2_q0191_b

**QUESTION ID:** `frequency_v2_q0191`

**QUESTION TEXT:** Bir ilişkide kendini en güvende hissettiğin an hangisidir?

**CONTEXT:** established

**OPTION ID:** `frequency_v2_q0191_b`

**OPTION TEXT:** Birlikte yan yana sessizce oturup, kelimelere ihtiyaç duymadan anlaştığımız an.

**CURRENT CANONICAL WEIGHTS:** `closeness_pace +2`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +1`

**CURRENT CLASSIFICATION:** `REWRITE_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `closeness_pace +2`

**REASON:** The stem is a feeling ('en güvende hissettiğin an'), not a behavior. Silent side-by-side ease is closeness, but processing_style+1 has nothing defensible to map until the question asks for an act.

**CONFIDENCE:** high

**ALTERNATIVE INTERPRETATION:** NONE until the stem asks for a behavior. After rewrite, silent side-by-side time can stay `closeness_pace +2`.

**RISK IF ACCEPTED:** If scored as-is, a feeling of safety would be stored as a closeness-pace behavior they may not actually choose.

**ORIGINAL:** Bir ilişkide kendini en güvende hissettiğin an hangisidir?

**PROPOSED REWRITE:** Full stem + four-option rewrite is in §E (`frequency_v2_q0191`).

**WHY THIS REWRITE IS BETTER:** Stem is a feeling ('en güvende hissettiğin an'). Rewrite as how you actually keep the relationship feeling settled.

### frequency_v2_q0193_c

**QUESTION ID:** `frequency_v2_q0193`

**QUESTION TEXT:** Doğum gününde partnerin sana hiç tarzın olmayan, belli ki özenmeden seçilmiş veya yanlış anlaşılmış bir hediye aldı.

**CONTEXT:** established

**OPTION ID:** `frequency_v2_q0193_c`

**OPTION TEXT:** O an mutlu görünürüm ama sonrasında günlerce içten içe "beni hiç tanımamış" diye üzülürüm.

**CURRENT CANONICAL WEIGHTS:** `reassurance_need +1`

**LEGACY / UNKNOWN WEIGHT:** `processing_style -2`

**CURRENT CLASSIFICATION:** `REWRITE_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `reassurance_need +1`

**REASON:** The option is purely internal ('günlerce içten içe üzülürüm') with no observable act. processing_style−2 is affect, not a 12D. Needs a behavioral tell (withdrawal, hinting, later confrontation) before scoring.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** If rewritten as delayed cooling/hinting: `reassurance_need +1` plus `disclosure_pace −1`. If left internal: DROP the option from scoring.

**RISK IF ACCEPTED:** Covert multi-day hurt would be stored as reassurance_need with no observable act, so pairing cannot see the delayed tell.

**ORIGINAL:** O an mutlu görünürüm ama sonrasında günlerce içten içe "beni hiç tanımamış" diye üzülürüm.

**PROPOSED REWRITE:** O an teşekkür ederim; sonraki günlerde hediyeyi kullanmam ve konuyu dolaylı biçimde, geç açarım.

**PROPOSED WEIGHTS AFTER REWRITE:** reassurance_need +1, disclosure_pace −1

**WHY THIS REWRITE IS BETTER:** Turns a multi-day private feeling into an observable delayed tell (not using the gift, bringing it up later indirectly) without making C the 'bad/passive-aggressive' option. A still hides it, B still says it immediately, D still jokes. Stays in reassurance_need / low disclosure, not morality.

### frequency_v2_q0272_b

**QUESTION ID:** `frequency_v2_q0272`

**QUESTION TEXT:** Bir sohbet esnasında partnerin, içinde hiçbir romantik duygu barındırmayan ama eski sevgilisinin de olduğu nötr bir anıyı anlattı (örn: "Eski sevgilimle o filme gitmiştik").

**CONTEXT:** early_dating, uncertainty

**OPTION ID:** `frequency_v2_q0272_b`

**OPTION TEXT:** Kıskandığımı belli etmem ama eski ilişkilerinin hala aklına geliyor olması beni içten içe gerer.

**CURRENT CANONICAL WEIGHTS:** `reassurance_need +2`

**LEGACY / UNKNOWN WEIGHT:** `processing_style -1`

**CURRENT CLASSIFICATION:** `REWRITE_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `reassurance_need +2`

**REASON:** Covert jealousy with an explicit 'I don't show it' is an internal state. processing_style−1 cannot be mapped. Rewrite to a visible act or drop the option from scoring.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** If rewritten as a later check-in or visible cooling: `reassurance_need +2` plus `disclosure_pace −1`. If left internal: DROP.

**RISK IF ACCEPTED:** Unshown jealousy would be stored as high reassurance_need even when the partner never sees a behavior.

**ORIGINAL:** Kıskandığımı belli etmem ama eski ilişkilerinin hala aklına geliyor olması beni içten içe gerer.

**PROPOSED REWRITE:** O an üstüne gitmem; sohbetin devamında biraz kısılır, konuyu başka bir şeye çeviririm.

**PROPOSED WEIGHTS AFTER REWRITE:** reassurance_need +2, disclosure_pace −1

**WHY THIS REWRITE IS BETTER:** Keeps the 'I don't confront it head-on' meaning but adds a visible cooling/topic-change. A still lets it go, C still sets a name-rule, D still reciprocates with a story. No jealousy/pathology label.

### frequency_v2_q0274_b

**QUESTION ID:** `frequency_v2_q0274`

**QUESTION TEXT:** Birlikte kanepede otururken yarım saattir ikiniz de hiç konuşmadınız. İçinden ne geçer?

**CONTEXT:** established

**OPTION ID:** `frequency_v2_q0274_b`

**OPTION TEXT:** Birlikteyken yaşanan bu sessizliklerin dünyanın en huzurlu şeyi olduğunu düşünürüm.

**CURRENT CANONICAL WEIGHTS:** `closeness_pace +2`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +1`

**CURRENT CLASSIFICATION:** `REWRITE_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `closeness_pace +2`

**REASON:** Stem is 'içinden ne geçer' (what passes through your mind). Rating silence as peaceful is a feeling, not a 12D behavior. processing_style+1 is not mappable.

**CONFIDENCE:** high

**ALTERNATIVE INTERPRETATION:** NONE until the stem asks what they do. After rewrite, staying in the silence can stay `closeness_pace +2`.

**RISK IF ACCEPTED:** A peaceful feeling about silence would be stored as closeness-pace behavior they may not actually maintain.

**ORIGINAL:** Birlikte kanepede otururken yarım saattir ikiniz de hiç konuşmadınız. İçinden ne geçer?

**PROPOSED REWRITE:** Full stem + four-option rewrite is in §E (`frequency_v2_q0274`).

**WHY THIS REWRITE IS BETTER:** Stem is 'içinden ne geçer'. Rewrite as what you do in the shared silence.

### frequency_v2_q0295_b

**QUESTION ID:** `frequency_v2_q0295`

**QUESTION TEXT:** Sen günün stresiyle koltukta otururken sessizce ağlamaya başladın. Partnerin ne yapsa sana iyi gelir?

**CONTEXT:** support

**OPTION ID:** `frequency_v2_q0295_b`

**OPTION TEXT:** Bir bardak su ve peçete getirip, "Anlatmak istersen buradayım" diyerek beni kendi halime bırakması.

**CURRENT CANONICAL WEIGHTS:** `autonomy +2`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +1`

**CURRENT CLASSIFICATION:** `REWRITE_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `autonomy +2`

**REASON:** Stem asks what the partner should do that would help you. This is preferred support, not respondent behavior. processing_style+1 cannot be remapped on a care-language item.

**CONFIDENCE:** high

**ALTERNATIVE INTERPRETATION:** NONE until the stem is respondent-sided. After rewrite, asking for space while remaining reachable can stay `autonomy +2`.

**RISK IF ACCEPTED:** Preferred partner care would be stored as the respondent's autonomy, inverting who is acting.

**ORIGINAL:** Sen günün stresiyle koltukta otururken sessizce ağlamaya başladın. Partnerin ne yapsa sana iyi gelir?

**PROPOSED REWRITE:** Full stem + four-option rewrite is in §E (`frequency_v2_q0295`).

**WHY THIS REWRITE IS BETTER:** Stem asks what the partner should do. Rewrite as what you do when they walk in while you are crying.

### frequency_v2_q0295_c

**QUESTION ID:** `frequency_v2_q0295`

**QUESTION TEXT:** Sen günün stresiyle koltukta otururken sessizce ağlamaya başladın. Partnerin ne yapsa sana iyi gelir?

**CONTEXT:** support

**OPTION ID:** `frequency_v2_q0295_c`

**OPTION TEXT:** "Ne oldu, neden ağlıyorsun, kim seni üzdü?" diyerek sorunu anında bulmaya ve çözmeye çalışması.

**CURRENT CANONICAL WEIGHTS:** `initiative +2`

**LEGACY / UNKNOWN WEIGHT:** `processing_style -1`

**CURRENT CLASSIFICATION:** `REWRITE_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `initiative +2`

**REASON:** Same stem: desired partner problem-solving, not the respondent's initiative. Do not treat processing_style−1 as a 12D score.

**CONFIDENCE:** high

**ALTERNATIVE INTERPRETATION:** NONE until the stem is respondent-sided. After rewrite, telling the cause and looking for an exit can be `initiative +1` plus `disclosure_pace +1`.

**RISK IF ACCEPTED:** Wanting the partner to interrogate the problem would be stored as the respondent's initiative.

**ORIGINAL:** Sen günün stresiyle koltukta otururken sessizce ağlamaya başladın. Partnerin ne yapsa sana iyi gelir?

**PROPOSED REWRITE:** Full stem + four-option rewrite is in §E (`frequency_v2_q0295`).

**WHY THIS REWRITE IS BETTER:** Same stem problem as B. Option C currently scores desired partner problem-solving as respondent initiative.

### frequency_v2_q0344_d

**QUESTION ID:** `frequency_v2_q0344`

**QUESTION TEXT:** Partnerinle şık bir restorana gittiniz. Onun sipariş ettiği yemek tamamen yanlış geldi ama o "Sorun değil, bunu da yerim" deyip sessiz kaldı.

**CONTEXT:** social

**OPTION ID:** `frequency_v2_q0344_d`

**OPTION TEXT:** Hakkını aramadığı için içten içe rahatsız olurum, bu fazla uyumlu tavır beni biraz iter.

**CURRENT CANONICAL WEIGHTS:** `boundary_firmness +2`

**LEGACY / UNKNOWN WEIGHT:** `processing_style +1`

**CURRENT CLASSIFICATION:** `REWRITE_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `boundary_firmness +2`

**REASON:** Internal repulsion at the partner's passivity ('içten içe rahatsız… biraz iter') has no act. boundary_firmness +2 is already a stretch for a private feeling; processing_style+1 should not be added. Needs a behavioral option or rewrite.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** If rewritten as a later comment: keep `boundary_firmness +2`. If left internal: DROP; +2 on a private feeling is already too strong.

**RISK IF ACCEPTED:** Private irritation at passivity would be stored as very high boundary_firmness with no act the partner can meet.

**ORIGINAL:** Hakkını aramadığı için içten içe rahatsız olurum, bu fazla uyumlu tavır beni biraz iter.

**PROPOSED REWRITE:** Çıkışta "Bir dahakine söyleyelim, böyle geçiştirmek bana zor geliyor" derim.

**PROPOSED WEIGHTS AFTER REWRITE:** boundary_firmness +2

**WHY THIS REWRITE IS BETTER:** Private repulsion becomes a later, specific comment. A still takes over with the waiter, B still checks then stops, C still does not intervene. D is firm without a 'spineless partner' frame.

### frequency_v2_q0347_b

**QUESTION ID:** `frequency_v2_q0347`

**QUESTION TEXT:** 3. buluşmanız için hazırsın. 1 saat kala "Çok acil bir ailevi durum çıktı, iptal etmem gerek" diye mesaj attı.

**CONTEXT:** early_dating

**OPTION ID:** `frequency_v2_q0347_b`

**OPTION TEXT:** Anlayışla karşılarım ama içimde "Acaba bahane mi?" diye ufak bir şüphe oluşur.

**CURRENT CANONICAL WEIGHTS:** `reassurance_need +2`

**LEGACY / UNKNOWN WEIGHT:** `processing_style -1`

**CURRENT CLASSIFICATION:** `REWRITE_REQUIRED`

**PROPOSED CANONICAL WEIGHTS:** `reassurance_need +2`

**REASON:** The only content is an inner suspicion ('bahane mi?') while outwardly being understanding. processing_style−1 is not a 12D. Needs a behavioral leak or should not be scored.

**CONFIDENCE:** medium

**ALTERNATIVE INTERPRETATION:** If rewritten as a short next-day netlik ask: `reassurance_need +2` plus `uncertainty_tolerance −1`. If left internal: DROP.

**RISK IF ACCEPTED:** Unspoken suspicion of an excuse would be stored as high reassurance_need with no visible check-in.

**ORIGINAL:** Anlayışla karşılarım ama içimde "Acaba bahane mi?" diye ufak bir şüphe oluşur.

**PROPOSED REWRITE:** İptali anladığımı söylerim; ertesi gün kısa bir "Ne olmuştu, her şey yolunda mı?" mesajı atarım.

**PROPOSED WEIGHTS AFTER REWRITE:** reassurance_need +2, uncertainty_tolerance −1

**WHY THIS REWRITE IS BETTER:** Inner suspicion becomes a small next-day netlik ask. A still makes another plan, C still offers help now, D still waits for them to reschedule. No lie-detection / 'are they lying' option.

## D. PRIMARY_DIMENSION WOULD CHANGE

Count: **30**. Almost all of these had empty/`processing_style`/`conflict_approach` source primaries. After dropping leftovers (and applying accepted remaps), remaining 12D abs-mass has a new lead. Ties are possible; the listed lead is the Phase 1 heuristic.

| Question | Source / draft primary | Proposed lead | Why this packet includes it |
|---|---|---|---|
| `frequency_v2_q0003` | (none) | `initiative` | flagged A `CLEAR_REMAP`; processing leftover dropped on B, C |
| `frequency_v2_q0008` | (none) | `boundary_firmness` | flagged A `HUMAN_DECISION_REQUIRED`; processing leftover dropped on B |
| `frequency_v2_q0015` | (none) | `repair_style` | flagged A `CLEAR_REMAP`, B `CLEAR_REMAP`, D `CLEAR_REMAP` |
| `frequency_v2_q0026` | (none) | `boundary_firmness` | flagged A `HUMAN_DECISION_REQUIRED`; processing leftover dropped on C |
| `frequency_v2_q0029` | (none) | `uncertainty_tolerance` | flagged A `CLEAR_REMAP`; processing leftover dropped on C |
| `frequency_v2_q0037` | `boundary_firmness` | `repair_style` | flagged A `CLEAR_REMAP`, B `CLEAR_REMAP` |
| `frequency_v2_q0043` | (none) | `initiative` | flagged A `CLEAR_REMAP`; processing leftover dropped on B |
| `frequency_v2_q0047` | (none) | `uncertainty_tolerance` | processing leftover dropped on A, B; remaining mass on unscored siblings |
| `frequency_v2_q0163` | (none) | `disclosure_pace` | flagged B `HUMAN_DECISION_REQUIRED` |
| `frequency_v2_q0166` | (none) | `repair_style` | flagged A `CLEAR_REMAP`, B `CLEAR_REMAP`, D `HUMAN_DECISION_REQUIRED` |
| `frequency_v2_q0180` | (none) | `structure_preference` | processing leftover dropped on A, B; remaining mass on unscored siblings |
| `frequency_v2_q0183` | (none) | `boundary_firmness` | flagged A `HUMAN_DECISION_REQUIRED`, B `HUMAN_DECISION_REQUIRED` |
| `frequency_v2_q0186` | (none) | `boundary_firmness` | flagged B `CLEAR_REMAP`, D `HUMAN_DECISION_REQUIRED` |
| `frequency_v2_q0192` | (none) | `closeness_pace` | flagged B `HUMAN_DECISION_REQUIRED`; processing leftover dropped on A |
| `frequency_v2_q0252` | (none) | `boundary_firmness` | flagged A `CLEAR_REMAP`, C `HUMAN_DECISION_REQUIRED`; processing leftover dropped on D |
| `frequency_v2_q0258` | (none) | `boundary_firmness` | processing leftover dropped on B; remaining mass on unscored siblings |
| `frequency_v2_q0264` | (none) | `reassurance_need` | flagged B `HUMAN_DECISION_REQUIRED`; processing leftover dropped on A |
| `frequency_v2_q0271` | (none) | `initiative` | flagged D `HUMAN_DECISION_REQUIRED`; processing leftover dropped on A, B |
| `frequency_v2_q0282` | (none) | `boundary_firmness` | processing leftover dropped on B; remaining mass on unscored siblings |
| `frequency_v2_q0287` | (none) | `boundary_firmness` | flagged B `HUMAN_DECISION_REQUIRED`; processing leftover dropped on C |
| `frequency_v2_q0292` | (none) | `boundary_firmness` | processing leftover dropped on A, B; remaining mass on unscored siblings |
| `frequency_v2_q0295` | (none) | `reassurance_need` | flagged B `REWRITE_REQUIRED`, C `REWRITE_REQUIRED` |
| `frequency_v2_q0346` | (none) | `initiative` | flagged C `HUMAN_DECISION_REQUIRED`; processing leftover dropped on A, D |
| `frequency_v2_q0365` | (none) | `structure_preference` | processing leftover dropped on C; remaining mass on unscored siblings |
| `frequency_v2_q0370` | (none) | `initiative` | flagged D `HUMAN_DECISION_REQUIRED`; processing leftover dropped on C |
| `frequency_v2_q0377` | (none) | `boundary_firmness` | processing leftover dropped on A; remaining mass on unscored siblings |
| `frequency_v2_q0380` | (none) | `social_energy` | flagged A `CLEAR_REMAP` |
| `frequency_v2_q0383` | (none) | `boundary_firmness` | processing leftover dropped on A; remaining mass on unscored siblings |
| `frequency_v2_q0390` | (none) | `structure_preference` | flagged D `HUMAN_DECISION_REQUIRED`; processing leftover dropped on A |
| `frequency_v2_q0392` | (none) | `autonomy` | flagged A `HUMAN_DECISION_REQUIRED` |

Cards already in §A–C are not repeated. DROP-only primary items below show remaining sibling weights so the lead is inspectable.

### frequency_v2_q0047 — remaining mass after DROP

**QUESTION ID:** `frequency_v2_q0047`

**QUESTION TEXT:** Evde birlikte önemli bir işi yetiştirirken bilgisayar/internet aniden kilitlendi ve veriler kayboldu.

**CONTEXT:** unclassified

**PROPOSED LEAD:** `uncertainty_tolerance`

- `frequency_v2_q0047_a`: Hemen panik veya öfke yaşar, hissettiğim çaresizliği sesli şekilde dışa vururum.
  - current canonical: uncertainty_tolerance -1
  - leftover: `processing_style -2` → `DROP_WEIGHT` (not added)

- `frequency_v2_q0047_b`: Sıfır duygu ile anında çözüm moduna geçer, teknik destek arar, plan B'yi uygularım.
  - current canonical: initiative +2
  - leftover: `processing_style +2` → `DROP_WEIGHT` (not added)

- `frequency_v2_q0047_c`: Partnerimin ne kadar stres olduğuna bakar, o paniklediyse onu sakinleştirmeye odaklanırım.
  - current canonical: boundary_firmness -1, adaptability +2

- `frequency_v2_q0047_d`: Durumun absürtlük seviyesine güler, "olacağı varmış" deyip kahve yapmaya giderim.
  - current canonical: uncertainty_tolerance +2, structure_preference -2

**Remaining abs-mass:** `uncertainty_tolerance` 3, `initiative` 2, `adaptability` 2, `structure_preference` 2, `boundary_firmness` 1

**RISK IF ACCEPTED:** Assigning this lead without a human pass will treat leftover `processing_style` items as if they were always about the remaining 12D, even when the item was written as rational-vs-emotional coloring.

### frequency_v2_q0180 — remaining mass after DROP

**QUESTION ID:** `frequency_v2_q0180`

**QUESTION TEXT:** İkinizi de etkileyen ortak bir maddi kayıp (örn: yanlış bir yatırım veya yüksek bir trafik cezası) yaşandı.

**CONTEXT:** support

**PROPOSED LEAD:** `structure_preference`

- `frequency_v2_q0180_a`: Suçlunun kim olduğuna odaklanmadan hemen zararı nasıl kapatacağımızın matematiksel planını yaparım.
  - current canonical: structure_preference +2
  - leftover: `processing_style +2` → `DROP_WEIGHT` (not added)

- `frequency_v2_q0180_b`: Çok üzülür, moral bozukluğumu günlerce üzerimden atamam, onun beni teselli etmesini beklerim.
  - current canonical: reassurance_need +1
  - leftover: `processing_style -2` → `DROP_WEIGHT` (not added)

- `frequency_v2_q0180_c`: "Cana geleceğine mala gelsin" diyerek konuyu hızla kapatır, akışa devam ederim.
  - current canonical: uncertainty_tolerance +2, structure_preference -2

- `frequency_v2_q0180_d`: Partnerim eğer çok stres yaptıysa, kendi stresimi gizleyip sürekli onu telkin etmeye odaklanırım.
  - current canonical: boundary_firmness -1, adaptability +2

**Remaining abs-mass:** `structure_preference` 4, `uncertainty_tolerance` 2, `adaptability` 2, `reassurance_need` 1, `boundary_firmness` 1

**RISK IF ACCEPTED:** Assigning this lead without a human pass will treat leftover `processing_style` items as if they were always about the remaining 12D, even when the item was written as rational-vs-emotional coloring.

### frequency_v2_q0258 — remaining mass after DROP

**QUESTION ID:** `frequency_v2_q0258`

**QUESTION TEXT:** Çok severek okuduğun derin bir kitabı/makaleyi partnerinle paylaştın ama o "Çok sıkıcıymış" deyip kestirip attı.

**CONTEXT:** established

**PROPOSED LEAD:** `boundary_firmness`

- `frequency_v2_q0258_a`: Zevklerimizin farklı olmasını çok normal karşılar, konuyu bir daha açmam.
  - current canonical: autonomy +1, boundary_firmness +2

- `frequency_v2_q0258_b`: Anlaması için kitabın/makalenin ana fikrini farklı bir yolla ona açıklamaya çabalarım.
  - current canonical: initiative +1
  - leftover: `processing_style +1` → `DROP_WEIGHT` (not added)

- `frequency_v2_q0258_c`: İçten içe entelektüel bir kopukluk hissederim ve bu durum beni biraz soğutur.
  - current canonical: closeness_pace -1, reassurance_need +1

- `frequency_v2_q0258_d`: Ortak zevkimiz olan başka bir konuya geçerim, her şeyi birlikte sevmek zorunda değiliz.
  - current canonical: uncertainty_tolerance +2, adaptability +1

**Remaining abs-mass:** `boundary_firmness` 2, `uncertainty_tolerance` 2, `autonomy` 1, `initiative` 1, `reassurance_need` 1, `closeness_pace` 1, `adaptability` 1

**RISK IF ACCEPTED:** Assigning this lead without a human pass will treat leftover `processing_style` items as if they were always about the remaining 12D, even when the item was written as rational-vs-emotional coloring.

### frequency_v2_q0282 — remaining mass after DROP

**QUESTION ID:** `frequency_v2_q0282`

**QUESTION TEXT:** Partnerinin lüks sayılabilecek bir harcaması oldu (örn: pahalı bir çanta/saat), sen ise birikim yapmayı seven birisin.

**CONTEXT:** planning

**PROPOSED LEAD:** `boundary_firmness`

- `frequency_v2_q0282_a`: Kendi kazandığı paraysa hiçbir şey söylemem, onun bütçe yönetimi tamamen ona aittir.
  - current canonical: autonomy +2, boundary_firmness +2

- `frequency_v2_q0282_b`: Para konusundaki bu farklılığın gelecekte sorun yaratıp yaratmayacağını içten içe analiz etmeye başlarım.
  - current canonical: structure_preference +1
  - leftover: `processing_style +2` → `DROP_WEIGHT` (not added)

- `frequency_v2_q0282_c`: "Buna bu kadar para verilir mi?" diyerek şakayla karışık kendi fikrimi ve değer yargımı belli ederim.
  - current canonical: disclosure_pace +1, boundary_firmness +1

- `frequency_v2_q0282_d`: Onun aldığı keyfe odaklanırım, para harcamanın da hayatın bir zevki olduğunu düşünerek uyumlanırım.
  - current canonical: uncertainty_tolerance +1, adaptability +2

**Remaining abs-mass:** `boundary_firmness` 3, `autonomy` 2, `adaptability` 2, `structure_preference` 1, `disclosure_pace` 1, `uncertainty_tolerance` 1

**RISK IF ACCEPTED:** Assigning this lead without a human pass will treat leftover `processing_style` items as if they were always about the remaining 12D, even when the item was written as rational-vs-emotional coloring.

### frequency_v2_q0292 — remaining mass after DROP

**QUESTION ID:** `frequency_v2_q0292`

**QUESTION TEXT:** Partnerin elindeki kahveyi tamamen senin yeni bilgisayarının veya çok sevdiğin bir kıyafetinin üstüne döktü.

**CONTEXT:** support

**PROPOSED LEAD:** `boundary_firmness`

- `frequency_v2_q0292_a`: O anki refleksle bağırır, kızar, durumun yarattığı stresi tüm vücudumla dışa vururum.
  - current canonical: boundary_firmness +1
  - leftover: `processing_style -2` → `DROP_WEIGHT` (not added)

- `frequency_v2_q0292_b`: Hiçbir duygu belirtisi göstermeden sadece bezi kapıp temizlemeye ve hasar tespiti yapmaya odaklanırım.
  - current canonical: structure_preference +1
  - leftover: `processing_style +2` → `DROP_WEIGHT` (not added)

- `frequency_v2_q0292_c`: O çok panik olduysa, bilgisayardan çok onu sakinleştirmeye odaklanır, "Önemli değil" derim.
  - current canonical: reassurance_need -1, adaptability +2

- `frequency_v2_q0292_d`: Moralim çok bozulsa da, bilerek yapmadığı için kendimi sıkar, içime atar ve sessizleşirim.
  - current canonical: disclosure_pace -2, boundary_firmness -1

**Remaining abs-mass:** `boundary_firmness` 2, `adaptability` 2, `disclosure_pace` 2, `structure_preference` 1, `reassurance_need` 1

**RISK IF ACCEPTED:** Assigning this lead without a human pass will treat leftover `processing_style` items as if they were always about the remaining 12D, even when the item was written as rational-vs-emotional coloring.

### frequency_v2_q0365 — remaining mass after DROP

**QUESTION ID:** `frequency_v2_q0365`

**QUESTION TEXT:** İlişkiniz için çok önemli bir tarihi (yıldönümü) partnerin tamamen unuttu ve o güne normal bir gün gibi devam ediyor.

**CONTEXT:** conflict

**PROPOSED LEAD:** `structure_preference`

- `frequency_v2_q0365_a`: Akşama kadar hatırlar diye beklerim, hatırlamazsa çok kırılır ve tavır yaparım.
  - current canonical: reassurance_need +2, disclosure_pace -1

- `frequency_v2_q0365_b`: Hiç umursamam, özel gün kutlamaları veya takvimsel ritüeller benim için anlamsızdır.
  - current canonical: uncertainty_tolerance +2, structure_preference -2

- `frequency_v2_q0365_c`: Sabah ilk iş ben kutlar, ona unuttuğu için ufak bir şaka yapar, konuyu tatlıya bağlarım.
  - current canonical: initiative +2
  - leftover: `processing_style +1` → `DROP_WEIGHT` (not added)

- `frequency_v2_q0365_d`: "Bugün günlerden ne farkında mısın?" diyerek hemen yüzleşir ve ona sorumluluğunu hatırlatırım.
  - current canonical: boundary_firmness +1, structure_preference +2

**Remaining abs-mass:** `structure_preference` 4, `reassurance_need` 2, `uncertainty_tolerance` 2, `initiative` 2, `disclosure_pace` 1, `boundary_firmness` 1

**RISK IF ACCEPTED:** Assigning this lead without a human pass will treat leftover `processing_style` items as if they were always about the remaining 12D, even when the item was written as rational-vs-emotional coloring.

### frequency_v2_q0377 — remaining mass after DROP

**QUESTION ID:** `frequency_v2_q0377`

**QUESTION TEXT:** Çok lüks bir restoranda yemeğinizi yediniz, hesap geldi ve partnerin cüzdanını/kartını evde unuttuğunu fark etti.

**CONTEXT:** support

**PROPOSED LEAD:** `boundary_firmness`

- `frequency_v2_q0377_a`: "Yine mi dikkatsizlik!" diye ufak bir sitem eder, hesabı ben öderim ama dönüşte söylenirim.
  - current canonical: boundary_firmness +1
  - leftover: `processing_style -2` → `DROP_WEIGHT` (not added)

- `frequency_v2_q0377_b`: Güler geçerim, "Bugünlük benden olsun" diyerek hesabı öder ve geceye hiç bozmadan devam ederim.
  - current canonical: uncertainty_tolerance +2, adaptability +1

- `frequency_v2_q0377_c`: Sessizce hesabı öderim ama bunu yaparken kendimi kullanılmış/önemsenmemiş hissetme ihtimalim yüksektir.
  - current canonical: reassurance_need +2, disclosure_pace -2

- `frequency_v2_q0377_d`: Hesabı öderim ama "Yarı yarıya olacaktı, eve gidince atarsın" diyerek baştaki adalet/yapı planına sadık kalırım.
  - current canonical: boundary_firmness +1, structure_preference +2

**Remaining abs-mass:** `boundary_firmness` 2, `uncertainty_tolerance` 2, `reassurance_need` 2, `disclosure_pace` 2, `structure_preference` 2, `adaptability` 1

**RISK IF ACCEPTED:** Assigning this lead without a human pass will treat leftover `processing_style` items as if they were always about the remaining 12D, even when the item was written as rational-vs-emotional coloring.

### frequency_v2_q0383 — remaining mass after DROP

**QUESTION ID:** `frequency_v2_q0383`

**QUESTION TEXT:** Sen çok gerçekçi, bazen karamsar birisin. Partnerin ise her felakette "Evrene iyi mesaj yollayalım, her şey harika olacak" diyen biri.

**CONTEXT:** support

**PROPOSED LEAD:** `boundary_firmness`

- `frequency_v2_q0383_a`: Bu toksik pozitiflik beni çileden çıkarır, durumun vehametini ona kanıtlamaya çalışırım.
  - current canonical: boundary_firmness +2
  - leftover: `processing_style -1` → `DROP_WEIGHT` (not added)

- `frequency_v2_q0383_b`: Onun bu neşesi zamanla bana da bulaşır, olayları onun gözünden görmeye adapte olurum.
  - current canonical: uncertainty_tolerance +1, adaptability +2

- `frequency_v2_q0383_c`: Onu duymamazlıktan gelir, ben kendi rasyonel ve kötü senaryo planlarımı yapmaya devam ederim.
  - current canonical: autonomy +2, structure_preference +2

- `frequency_v2_q0383_d`: Onun yanında kendimi güvende hisseder, bana verdiği bu umut sayesinde sakinleşirim.
  - current canonical: closeness_pace +1, reassurance_need +2

**Remaining abs-mass:** `boundary_firmness` 2, `adaptability` 2, `autonomy` 2, `structure_preference` 2, `reassurance_need` 2, `uncertainty_tolerance` 1, `closeness_pace` 1

**RISK IF ACCEPTED:** Assigning this lead without a human pass will treat leftover `processing_style` items as if they were always about the remaining 12D, even when the item was written as rational-vs-emotional coloring.

## E. STEM REWRITE REQUIRED

Count: **4**. These four questions cannot be scored as respondent 12D behavior until the stem (and the matching options) are rewritten. Evidence-layer tags are still not assigned.

### frequency_v2_q0169

**QUESTION ID:** `frequency_v2_q0169`

**CONTEXT:** support

**ORIGINAL:**

Q: Hayatındaki işler hiç yolunda gitmiyor. Partnerinin sana yaklaşımı nasıl olmalı?

- `frequency_v2_q0169_a`: Beni sürekli aramalı, sormalı, "yanındayım" hissini kelimelerle bolca vermeli.
  - current canonical: contact_need +2, reassurance_need +2
- `frequency_v2_q0169_b`: Benim yerime pratik işlerimi (fatura ödemek, yemek yapmak) halledip omuzumdaki yükü almalı.
  - current canonical: closeness_pace +1
- `frequency_v2_q0169_c`: Ben konuyu açana kadar hiçbir şey sormamalı, alanıma saygı duyup beni darlamamalı.
  - current canonical: autonomy +2, boundary_firmness +2
- `frequency_v2_q0169_d`: Dikkatimi dağıtmak için beni dışarı çıkarmalı, eğlenceli ve kafamı boşaltacak planlar yapmalı.
  - current canonical: social_energy +1, adaptability +1

**PROPOSED REWRITE:**

Q: Hayatındaki işler hiç yolunda gitmiyor. Bu dönemde partnerinle nasıl durursun?

- A: Daha sık yazar veya arar, günü anlatır, yanında olmasını açıkça isterim.
  - proposed canonical: reassurance_need +2, contact_need +2
- B: Yemek, fatura gibi somut işleri paylaşmayı önerir, ondan bir iş kapmasını isterim.
  - proposed canonical: initiative +1, closeness_pace +1
- C: Konuyu ben açana kadar temasımı azaltır, kendi halime çekilirim.
  - proposed canonical: autonomy +2, boundary_firmness +2
- D: Kafamı dağıtacak bir plan öneririm; dışarı çıkmayı veya hafif bir şey yapmayı teklif ederim.
  - proposed canonical: adaptability +1, social_energy +1

**WHY THIS REWRITE IS BETTER:** Moves the item from desired care-language onto the respondent's contact, help-asking, space, and distraction behavior. All four remain ordinary, non-moral responses to a stacked-work week.

**ALTERNATIVE INTERPRETATION:** Drop the item from the selectable 12D pool instead of rewriting, if the scene cannot be made behavioral without becoming a care-language / feeling item.

**RISK IF ACCEPTED:** If the old stem is kept, pairing will treat wishes and inner states as if they were the person's 12D acts.

### frequency_v2_q0191

**QUESTION ID:** `frequency_v2_q0191`

**CONTEXT:** established

**ORIGINAL:**

Q: Bir ilişkide kendini en güvende hissettiğin an hangisidir?

- `frequency_v2_q0191_a`: "Seni seviyorum, iyi ki varsın" sözlerini sık sık duyduğum an.
  - current canonical: reassurance_need +2, disclosure_pace +1
- `frequency_v2_q0191_b`: Birlikte yan yana sessizce oturup, kelimelere ihtiyaç duymadan anlaştığımız an.
  - current canonical: closeness_pace +2
- `frequency_v2_q0191_c`: Kendi bağımsız hayatlarımızı sürdürüp, günün sonunda ortak bir evde buluştuğumuz o denge.
  - current canonical: autonomy +2, boundary_firmness +1
- `frequency_v2_q0191_d`: Banka hesabından tatil takvimine kadar geleceğimizin net ve planlı olduğunu bildiğim an.
  - current canonical: uncertainty_tolerance -2, structure_preference +2

**PROPOSED REWRITE:**

Q: Birlikte yürüttüğünüz günlük hayatta, ilişkinin oturduğunu en çok hangi davranışın gösterir?

- A: Gün içinde birkaç kez açıkça "yanındayım / iyi ki varsın" derim veya duymak isterim.
  - proposed canonical: reassurance_need +2, disclosure_pace +1
- B: Konuşmasak da yan yana oturup birlikte kalırız; sessiz vakit yeter.
  - proposed canonical: closeness_pace +2
- C: Gündüz herkes kendi işine bakar, akşam evde buluşuruz.
  - proposed canonical: autonomy +2, boundary_firmness +1
- D: Ortak takvimi ve para planını net tutarız; ne olacağı belli olsun isterim.
  - proposed canonical: structure_preference +2, uncertainty_tolerance −2

**WHY THIS REWRITE IS BETTER:** Replaces a safety-feeling prompt with four plausible ways of actually keeping a relationship settled: verbal check-ins, quiet shared presence, parallel days, or joint plans. No 'healthy/unhealthy' frame.

**ALTERNATIVE INTERPRETATION:** Drop the item from the selectable 12D pool instead of rewriting, if the scene cannot be made behavioral without becoming a care-language / feeling item.

**RISK IF ACCEPTED:** If the old stem is kept, pairing will treat wishes and inner states as if they were the person's 12D acts.

### frequency_v2_q0274

**QUESTION ID:** `frequency_v2_q0274`

**CONTEXT:** established

**ORIGINAL:**

Q: Birlikte kanepede otururken yarım saattir ikiniz de hiç konuşmadınız. İçinden ne geçer?

- `frequency_v2_q0274_a`: "Sıkıldı mı acaba?" veya "Bir sorun mu var?" diye düşünür, sessizliği kırma ihtiyacı hissederim.
  - current canonical: contact_need +1, reassurance_need +2
- `frequency_v2_q0274_b`: Birlikteyken yaşanan bu sessizliklerin dünyanın en huzurlu şeyi olduğunu düşünürüm.
  - current canonical: closeness_pace +2
- `frequency_v2_q0274_c`: Sessizliği hiç fark etmem bile, kendi elimdeki işe veya telefona tamamen dalmışımdır.
  - current canonical: autonomy +2, uncertainty_tolerance +1
- `frequency_v2_q0274_d`: Ortam fazla durgunlaştığı için müzik açar veya kalkıp başka bir işle meşgul olurum.
  - current canonical: social_energy +1, structure_preference -1

**PROPOSED REWRITE:**

Q: Birlikte kanepede otururken yarım saattir ikiniz de hiç konuşmadınız. Sen ne yaparsın?

- A: "Sıkıldın mı / bir şey mi var?" diye sorar, sessizliği bozarım.
  - proposed canonical: reassurance_need +2, contact_need +1
- B: Sessizce oturmaya devam ederim; konuşmaya gerek duymam.
  - proposed canonical: closeness_pace +2
- C: Kendi işime veya telefona dönerim; sessizliği bozmam.
  - proposed canonical: autonomy +2, uncertainty_tolerance +1
- D: Müzik açar veya kalkıp başka bir işle meşgul olurum.
  - proposed canonical: social_energy +1, structure_preference −1

**WHY THIS REWRITE IS BETTER:** The original scores inner commentary. The rewrite asks for an act in the same scene: break the silence, stay in it, drift to a phone, or change the activity. Option A is no longer rumination-only.

**ALTERNATIVE INTERPRETATION:** Drop the item from the selectable 12D pool instead of rewriting, if the scene cannot be made behavioral without becoming a care-language / feeling item.

**RISK IF ACCEPTED:** If the old stem is kept, pairing will treat wishes and inner states as if they were the person's 12D acts.

### frequency_v2_q0295

**QUESTION ID:** `frequency_v2_q0295`

**CONTEXT:** support

**ORIGINAL:**

Q: Sen günün stresiyle koltukta otururken sessizce ağlamaya başladın. Partnerin ne yapsa sana iyi gelir?

- `frequency_v2_q0295_a`: Hiç soru sormadan yanıma gelip bana sıkıca sarılması.
  - current canonical: contact_need +2, reassurance_need +2
- `frequency_v2_q0295_b`: Bir bardak su ve peçete getirip, "Anlatmak istersen buradayım" diyerek beni kendi halime bırakması.
  - current canonical: autonomy +2
- `frequency_v2_q0295_c`: "Ne oldu, neden ağlıyorsun, kim seni üzdü?" diyerek sorunu anında bulmaya ve çözmeye çalışması.
  - current canonical: initiative +2
- `frequency_v2_q0295_d`: Modumu değiştirmek için komik bir şey yapması veya sevdiğim bir filmi/müziği açması.
  - current canonical: uncertainty_tolerance +1, adaptability +1

**PROPOSED REWRITE:**

Q: Günün stresiyle sessizce ağlamaya başladın. Partnerin odaya girdi. Sen ne yaparsın?

- A: Soru sormasını beklemeden ona uzanır, sarılmasını isterim.
  - proposed canonical: reassurance_need +2, contact_need +2
- B: "Anlatmak istersem çağırırım" der, biraz kendi halime çekilirim.
  - proposed canonical: autonomy +2
- C: Ne olduğunu hemen anlatır, birlikte bir çıkış ararım.
  - proposed canonical: initiative +1, disclosure_pace +1
- D: Konuyu dağıtacak bir şey öneririm (kısa bir şaka, film, müzik).
  - proposed canonical: adaptability +1, uncertainty_tolerance +1

**WHY THIS REWRITE IS BETTER:** Stops scoring a preferred-partner-care menu as if it were the respondent's 12D. Each option is now an act: reach for contact, ask for space, narrate-and-solve, or shift the mood. No diagnosis of crying.

**ALTERNATIVE INTERPRETATION:** Drop the item from the selectable 12D pool instead of rewriting, if the scene cannot be made behavioral without becoming a care-language / feeling item.

**RISK IF ACCEPTED:** If the old stem is kept, pairing will treat wishes and inner states as if they were the person's 12D acts.

---

## Counts

- **CLEAR_REMAP:** 19
- **HUMAN_DECISION_REQUIRED:** 37
- **REWRITE_REQUIRED:** 9
- **PRIMARY_DIMENSION_CHANGE:** 30
- **STEM_REWRITE_REQUIRED:** 4

Normalized V2 JSON: **unchanged**
Frequency V1 / pubspec / routing / Firebase / Discover / matching / Persona / canonical_v1 / C2: **unchanged**

FREQUENCY V2 PHASE 1B HUMAN DECISION PACKET READY — NO DATA MODIFIED
