# Frequency V2 Phase 1E — Primary human decision packet

Status: **proposal only**. Does not modify the V2 pool, weights, question text, evidence metadata, V1, pubspec, routing, Firebase, Discover, Persona, matching, `canonical_v1`, or C2.

Source: `tool/frequency_behavior_v2/out/frequency_behavior_v2_phase1d_primary_semantic_review.md`

KEEP items (328) are omitted. This packet is the 98-item human queue.

## Architecture rule (all items)

Desired final shape:

- `primary_dimension`: **one** canonical dominant dimension
- `secondary_dimensions`: zero or more supporting dimensions

Do **not** put two IDs in `primary_dimensions` merely because options carry more than one weight. Dual stored values (124 pool-wide) are usually primary+secondary stuffed into the same field.

`KEEP MULTI-PRIMARY` / `KEEP_AS_MULTI_PRIMARY` is reserved for the rare case where two axes are both designed into the stem and collapsing would lie. This packet uses that path **zero times**; mixed items are sent to **REWRITE** instead of dual-primary storage.

## Special review: `frequency_v2_q0037`

Do not automatically choose `boundary_firmness` or `uncertainty_tolerance`.

QUESTION ID
frequency_v2_q0037

QUESTION TEXT
Gece uyumak üzeresin, çok yorgunsun. Partnerin aniden ilişkinizle ilgili derin ve ciddi bir konuyu açtı.

A Uykumu böler, konu çözülene kadar saatlerce konuşurum. Çözmeden uyuyamam.
B "Bunu şimdi konuşmayalım, yarın sabah taze kafayla değerlendirelim" diyerek sınırı çekerim.
C Konuşmaya çalışırım ama yorgunluktan odaklanamadığım için sadece onu dinler, onaylar görünürüm.
D Uyumak istediğimi belirtir ama kırılmaması için ona sarılarak uykuya dalarım.

CANDIDATE A
boundary_firmness

CANDIDATE B
uncertainty_tolerance

WHAT BEHAVIOR A CAPTURES
Holding versus yielding a timing/energy limit: sleep now versus giving the night to their bid (B and D vs A and C).

WHAT BEHAVIOR B CAPTURES
Need for closure-now versus postponing an opened relational topic (A “çözmeden uyuyamam” vs B tomorrow).

RECOMMENDATION:
REWRITE

WHY
Do not auto-pick boundary_firmness or uncertainty_tolerance. Option A is written as cannot-leave-unresolved (closure). Option B is an explicit sleep-limit. Those are two designed axes in one item. Isolate one axis in a later rewrite; until then do not store both IDs as primary_dimensions.

IMPROVED STEM (options not rewritten yet)
Gece uyumak üzeresin ve çok yorgunsun. Partnerin ilişkinizle ilgili ciddi bir konuyu tam şimdi konuşmak istiyor. Bu saatte konuşma talebini nasıl karşılar ve uykunu nasıl yönetirsin?

CONFIDENCE
medium

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: `boundary_firmness`, `uncertainty_tolerance`
stored primary_dimensions count: 1 (boundary_firmness)
collapse dual stored primary to one dominant: no
Until rewrite, do not treat the existing single stored `boundary_firmness` as decided, and do not add `uncertainty_tolerance` as a second primary_dimension.

## 1. CHANGE (47)

### frequency_v2_q0009

QUESTION ID
frequency_v2_q0009

QUESTION TEXT
Henüz 3-4 haftadır görüştüğün kişi, seni en yakın arkadaş grubuyla bir akşam yemeğine davet etti. Yaklaşımın ne olur?

CURRENT PRIMARY
disclosure_pace

RECOMMENDED PRIMARY
closeness_pace

SECONDARY CANDIDATE
boundary_firmness

WHY CURRENT PRIMARY IS WEAKER
`disclosure_pace` is weaker because that construct (how openly/quickly inner states are shared versus held back) is not what the four options are mainly splitting. Meeting their closest friends at week 3–4 is tempo of life-merging, not how quickly inner states are told. A accelerates; B calls it too early.

WHY RECOMMENDED PRIMARY IS BETTER
`closeness_pace` is better because the option poles map to tempo/intensity of togetherness and intimacy (move close fast vs take it slow). Keep `boundary_firmness` as secondary, not a second primary.

CONFIDENCE:
high

DESIRED ARCHITECTURE
primary_dimension: `closeness_pace`
secondary_dimensions: `boundary_firmness`
stored primary_dimensions count: 1 (disclosure_pace)
collapse dual stored primary to one dominant: no

### frequency_v2_q0015

QUESTION ID
frequency_v2_q0015

QUESTION TEXT
Stresli bir anında partnerine gereksiz yere sert çıkıştın. 10 dakika sonra durumu fark ettin.

CURRENT PRIMARY
(empty / primary_review_pending)

RECOMMENDED PRIMARY
repair_style

SECONDARY CANDIDATE
none

WHY CURRENT PRIMARY IS WEAKER
There is no stored canonical primary (Phase 1C pending). The question still has a clear designed contrast; emptiness is not a reason to leave it unlabeled after human apply.

WHY RECOMMENDED PRIMARY IS BETTER
`repair_style` is better because the option poles map to how they re-engage after tension: immediate vs delayed vs withdrawn (not a moral score). No extra primary is required.

CONFIDENCE:
high

DESIRED ARCHITECTURE
primary_dimension: `repair_style`
secondary_dimensions: (none)
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no

### frequency_v2_q0020

QUESTION ID
frequency_v2_q0020

QUESTION TEXT
Partnerin bir şeye bariz şekilde canı sıkkın ama sana "bir şey yok, iyiyim" diyor.

CURRENT PRIMARY
boundary_firmness

RECOMMENDED PRIMARY
uncertainty_tolerance

SECONDARY CANDIDATE
autonomy

WHY CURRENT PRIMARY IS WEAKER
`boundary_firmness` is weaker because that construct (holding a limit/saying no versus yielding the line) is not what the four options are mainly splitting. They say they are fine while clearly upset. You are not holding your own limit; you decide whether to resolve unexplained coldness now or leave it unknown.

WHY RECOMMENDED PRIMARY IS BETTER
`uncertainty_tolerance` is better because the option poles map to comfort leaving things unresolved versus needing clarity/closure. Keep `autonomy` as secondary, not a second primary.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `uncertainty_tolerance`
secondary_dimensions: `autonomy`
stored primary_dimensions count: 1 (boundary_firmness)
collapse dual stored primary to one dominant: no

### frequency_v2_q0027

QUESTION ID
frequency_v2_q0027

QUESTION TEXT
Acil çözmen gereken zor bir problemin var, ama partnerin o gün çok kritik bir iş toplantısında.

CURRENT PRIMARY
reassurance_need

RECOMMENDED PRIMARY
autonomy

SECONDARY CANDIDATE
contact_need

WHY CURRENT PRIMARY IS WEAKER
`reassurance_need` is weaker because that construct (seeking confirmation the bond is OK versus not needing that check) is not what the four options are mainly splitting. Handle a crisis alone versus pulling a partner who is in a meeting. That is self-direction versus drawing them in, not a bond-OK check.

WHY RECOMMENDED PRIMARY IS BETTER
`autonomy` is better because the option poles map to independent space/self-direction versus merging. Keep `contact_need` as secondary, not a second primary.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `autonomy`
secondary_dimensions: `contact_need`
stored primary_dimensions count: 1 (reassurance_need)
collapse dual stored primary to one dominant: no

### frequency_v2_q0028

QUESTION ID
frequency_v2_q0028

QUESTION TEXT
Çok yakın arkadaş grubun, yeni partnerinle enerjilerinin uyuşmadığını hissettirdi.

CURRENT PRIMARY
social_energy

RECOMMENDED PRIMARY
boundary_firmness

SECONDARY CANDIDATE
autonomy

WHY CURRENT PRIMARY IS WEAKER
`social_energy` is weaker because that construct (external social/activity energy versus low-key/private) is not what the four options are mainly splitting. Friends dislike the partner: re-evaluate, split worlds, blend them, or defend the couple line. Existing social_energy does not match. Holding versus yielding the couple boundary is the stronger axis.

WHY RECOMMENDED PRIMARY IS BETTER
`boundary_firmness` is better because the option poles map to holding a limit/saying no versus yielding the line. Keep `autonomy` as secondary, not a second primary.

CONFIDENCE:
high

DESIRED ARCHITECTURE
primary_dimension: `boundary_firmness`
secondary_dimensions: `autonomy`
stored primary_dimensions count: 1 (social_energy)
collapse dual stored primary to one dominant: no

### frequency_v2_q0038

QUESTION ID
frequency_v2_q0038

QUESTION TEXT
Sen çok düzenlisin, partnerin ise daha "dağınık" bir düzene sahip. Nasıl ilerlersiniz?

CURRENT PRIMARY
structure_preference

RECOMMENDED PRIMARY
adaptability

SECONDARY CANDIDATE
autonomy

WHY CURRENT PRIMARY IS WEAKER
`structure_preference` is weaker because that construct (plans/schedules/predictable routines versus loose/unplanned) is not what the four options are mainly splitting. Tidy-versus-messy living is impose-my-way, relax standards, split territories, or meet in the middle. Household order is not plans/schedules; it is adjust versus keep your rhythm.

WHY RECOMMENDED PRIMARY IS BETTER
`adaptability` is better because the option poles map to adjusting own way to the partner/situation versus staying with own rhythm. Keep `autonomy` as secondary, not a second primary.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `adaptability`
secondary_dimensions: `autonomy`
stored primary_dimensions count: 1 (structure_preference)
collapse dual stored primary to one dominant: no

### frequency_v2_q0039

QUESTION ID
frequency_v2_q0039

QUESTION TEXT
İlişkiniz tamamen rayına oturdu, her gününüzün nasıl geçeceği belli, sıfır sürpriz var. Nasıl hissedersin?

CURRENT PRIMARY
uncertainty_tolerance

RECOMMENDED PRIMARY
structure_preference

SECONDARY CANDIDATE
none

WHY CURRENT PRIMARY IS WEAKER
`uncertainty_tolerance` is weaker because that construct (comfort leaving things unresolved versus needing clarity/closure) is not what the four options are mainly splitting. Zero-surprise settled days are comfort with predictable routine versus hunger for unplanned novelty. That is not comfort with unresolved ambiguity.

WHY RECOMMENDED PRIMARY IS BETTER
`structure_preference` is better because the option poles map to plans/schedules/predictable routines versus loose/unplanned. No extra primary is required.

CONFIDENCE:
high

DESIRED ARCHITECTURE
primary_dimension: `structure_preference`
secondary_dimensions: (none)
stored primary_dimensions count: 1 (uncertainty_tolerance)
collapse dual stored primary to one dominant: no

### frequency_v2_q0064

QUESTION ID
frequency_v2_q0064

QUESTION TEXT
Tartışma sonrası sessizlik oluştu.

CURRENT PRIMARY
initiative + repair_style

RECOMMENDED PRIMARY
repair_style

SECONDARY CANDIDATE
initiative

WHY CURRENT PRIMARY IS WEAKER
`initiative + repair_style` is weaker because that construct (who starts, plans, or proposes versus who waits) is not what the four options are mainly splitting. Post-argument silence is immediate re-entry, wait for them, a light “shall we talk,” or days in your own space. How repair is re-engaged is the contrast; who speaks first is secondary.

WHY RECOMMENDED PRIMARY IS BETTER
`repair_style` is better because the option poles map to how they re-engage after tension: immediate vs delayed vs withdrawn (not a moral score). Keep `initiative` as secondary, not a second primary.

CONFIDENCE:
high

DESIRED ARCHITECTURE
primary_dimension: `repair_style`
secondary_dimensions: `initiative`
stored primary_dimensions count: 2 (initiative, repair_style)
collapse dual stored primary to one dominant: yes

### frequency_v2_q0071

QUESTION ID
frequency_v2_q0071

QUESTION TEXT
İlk birkaç mesajlaşma sonrası karşı taraf “sen nasılsın, günün nasıl geçti” tarzı sorular sormuyor.

CURRENT PRIMARY
contact_need

RECOMMENDED PRIMARY
reassurance_need

SECONDARY CANDIDATE
contact_need

WHY CURRENT PRIMARY IS WEAKER
`contact_need` is weaker because that construct (how much contact/availability frequency is wanted (frequent vs sparse)) is not what the four options are mainly splitting. Missing “how are you / how was your day” is whether you need that care-check, not raw message count. Contact style is only the vehicle.

WHY RECOMMENDED PRIMARY IS BETTER
`reassurance_need` is better because the option poles map to seeking confirmation the bond is OK versus not needing that check. Keep `contact_need` as secondary, not a second primary.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `reassurance_need`
secondary_dimensions: `contact_need`
stored primary_dimensions count: 1 (contact_need)
collapse dual stored primary to one dominant: no

### frequency_v2_q0076

QUESTION ID
frequency_v2_q0076

QUESTION TEXT
Uzun bir ayrılıktan (iş seyahati, aile) sonra yeniden bir araya geliyorsunuz.

CURRENT PRIMARY
contact_need + closeness_pace

RECOMMENDED PRIMARY
closeness_pace

SECONDARY CANDIDATE
autonomy

WHY CURRENT PRIMARY IS WEAKER
`contact_need + closeness_pace` is weaker because that construct (how much contact/availability frequency is wanted (frequent vs sparse)) is not what the four options are mainly splitting. Post-absence reunion contrasts immediate intense togetherness versus slow re-entry versus first returning to one’s own routine. Intimacy tempo, not ordinary message-frequency.

WHY RECOMMENDED PRIMARY IS BETTER
`closeness_pace` is better because the option poles map to tempo/intensity of togetherness and intimacy (move close fast vs take it slow). Keep `autonomy` as secondary, not a second primary.

CONFIDENCE:
high

DESIRED ARCHITECTURE
primary_dimension: `closeness_pace`
secondary_dimensions: `autonomy`
stored primary_dimensions count: 2 (contact_need, closeness_pace)
collapse dual stored primary to one dominant: yes

### frequency_v2_q0134

QUESTION ID
frequency_v2_q0134

QUESTION TEXT
Bu kez daha sık iletişim isteyen taraf sensin; partnerin daha seyrek temas ediyor.

CURRENT PRIMARY
reassurance_need

RECOMMENDED PRIMARY
contact_need

SECONDARY CANDIDATE
initiative

WHY CURRENT PRIMARY IS WEAKER
`reassurance_need` is weaker because that construct (seeking confirmation the bond is OK versus not needing that check) is not what the four options are mainly splitting. You want more contact than they give: require a daily rhythm, fill your own life, initiate more, or reduce investment. Contact appetite under mismatch, not a bond-OK check.

WHY RECOMMENDED PRIMARY IS BETTER
`contact_need` is better because the option poles map to how much contact/availability frequency is wanted (frequent vs sparse). Keep `initiative` as secondary, not a second primary.

CONFIDENCE:
high

DESIRED ARCHITECTURE
primary_dimension: `contact_need`
secondary_dimensions: `initiative`
stored primary_dimensions count: 1 (reassurance_need)
collapse dual stored primary to one dominant: no

### frequency_v2_q0156

QUESTION ID
frequency_v2_q0156

QUESTION TEXT
İlişkinizin 6. ayındasınız. Partnerin seni aniden, çok sevdiği ailesiyle bir akşam yemeğine davet etti.

CURRENT PRIMARY
disclosure_pace

RECOMMENDED PRIMARY
closeness_pace

SECONDARY CANDIDATE
disclosure_pace

WHY CURRENT PRIMARY IS WEAKER
`disclosure_pace` is weaker because that construct (how openly/quickly inner states are shared versus held back) is not what the four options are mainly splitting. A month-6 family dinner is welcomed as deepening, felt as too early, attended quietly, or socially steered. Ready-versus-too-soon for a family milestone is closeness tempo.

WHY RECOMMENDED PRIMARY IS BETTER
`closeness_pace` is better because the option poles map to tempo/intensity of togetherness and intimacy (move close fast vs take it slow). Keep `disclosure_pace` as secondary, not a second primary.

CONFIDENCE:
high

DESIRED ARCHITECTURE
primary_dimension: `closeness_pace`
secondary_dimensions: `disclosure_pace`
stored primary_dimensions count: 1 (disclosure_pace)
collapse dual stored primary to one dominant: no

### frequency_v2_q0166

QUESTION ID
frequency_v2_q0166

QUESTION TEXT
Arabada uzun yoldasınız ve bir konu yüzünden sesler yükseldi, kavga çıktı. İdeal çözüm yöntemin nedir?

CURRENT PRIMARY
(empty / primary_review_pending)

RECOMMENDED PRIMARY
repair_style

SECONDARY CANDIDATE
none

WHY CURRENT PRIMARY IS WEAKER
There is no stored canonical primary (Phase 1C pending). The question still has a clear designed contrast; emptiness is not a reason to leave it unlabeled after human apply.

WHY RECOMMENDED PRIMARY IS BETTER
`repair_style` is better because the option poles map to how they re-engage after tension: immediate vs delayed vs withdrawn (not a moral score). No extra primary is required.

CONFIDENCE:
high

DESIRED ARCHITECTURE
primary_dimension: `repair_style`
secondary_dimensions: (none)
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no

### frequency_v2_q0186

QUESTION ID
frequency_v2_q0186

QUESTION TEXT
Büyük bir kavgada bağırdın, çağırdın. Ancak 10 dakika sonra aslında tamamen *senin haksız olduğunu* fark ettin.

CURRENT PRIMARY
(empty / primary_review_pending)

RECOMMENDED PRIMARY
repair_style

SECONDARY CANDIDATE
none

WHY CURRENT PRIMARY IS WEAKER
There is no stored canonical primary (Phase 1C pending). The question still has a clear designed contrast; emptiness is not a reason to leave it unlabeled after human apply.

WHY RECOMMENDED PRIMARY IS BETTER
`repair_style` is better because the option poles map to how they re-engage after tension: immediate vs delayed vs withdrawn (not a moral score). No extra primary is required.

CONFIDENCE:
high

DESIRED ARCHITECTURE
primary_dimension: `repair_style`
secondary_dimensions: (none)
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no

### frequency_v2_q0228

QUESTION ID
frequency_v2_q0228

QUESTION TEXT
Yeni biriyle mesajlaşırken o çok uzun ve detaylı yazıyor, siz daha kısa yazmayı seviyorsunuz.

CURRENT PRIMARY
contact_need + adaptability

RECOMMENDED PRIMARY
adaptability

SECONDARY CANDIDATE
disclosure_pace

WHY CURRENT PRIMARY IS WEAKER
`contact_need + adaptability` is weaker because that construct (how much contact/availability frequency is wanted (frequent vs sparse)) is not what the four options are mainly splitting. The split is long/detailed messages versus short ones, not frequent versus sparse contact. Matching their style versus keeping yours is adjust versus own rhythm.

WHY RECOMMENDED PRIMARY IS BETTER
`adaptability` is better because the option poles map to adjusting own way to the partner/situation versus staying with own rhythm. Keep `disclosure_pace` as secondary, not a second primary.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `adaptability`
secondary_dimensions: `disclosure_pace`
stored primary_dimensions count: 2 (contact_need, adaptability)
collapse dual stored primary to one dominant: yes

### frequency_v2_q0254

QUESTION ID
frequency_v2_q0254

QUESTION TEXT
Sen çok hastasın, ateşin var ve yatakta yatıyorsun. Partnerinden beklentin nedir?

CURRENT PRIMARY
reassurance_need

RECOMMENDED PRIMARY
contact_need

SECONDARY CANDIDATE
closeness_pace

WHY CURRENT PRIMARY IS WEAKER
`reassurance_need` is weaker because that construct (seeking confirmation the bond is OK versus not needing that check) is not what the four options are mainly splitting. Sick-day options are constant presence, drop-and-leave, nearby availability, or not asking for help. Wanted availability/proximity, not a check that the bond is OK.

WHY RECOMMENDED PRIMARY IS BETTER
`contact_need` is better because the option poles map to how much contact/availability frequency is wanted (frequent vs sparse). Keep `closeness_pace` as secondary, not a second primary.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `contact_need`
secondary_dimensions: `closeness_pace`
stored primary_dimensions count: 1 (reassurance_need)
collapse dual stored primary to one dominant: no

### frequency_v2_q0255

QUESTION ID
frequency_v2_q0255

QUESTION TEXT
Çok heves ettiğiniz bir etkinliğe (örn: konser/tiyatro) giderken berbat bir trafiğe yakalandınız ve yetişemeyeceğiniz kesinleşti.

CURRENT PRIMARY
uncertainty_tolerance

RECOMMENDED PRIMARY
adaptability

SECONDARY CANDIDATE
none

WHY CURRENT PRIMARY IS WEAKER
`uncertainty_tolerance` is weaker because that construct (comfort leaving things unresolved versus needing clarity/closure) is not what the four options are mainly splitting. Missing the event is already certain. Meltdown versus inventing a new plan versus following them versus going quiet is adjusting to a spoiled situation, not unresolved ambiguity.

WHY RECOMMENDED PRIMARY IS BETTER
`adaptability` is better because the option poles map to adjusting own way to the partner/situation versus staying with own rhythm. No extra primary is required.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `adaptability`
secondary_dimensions: (none)
stored primary_dimensions count: 1 (uncertainty_tolerance)
collapse dual stored primary to one dominant: no

### frequency_v2_q0258

QUESTION ID
frequency_v2_q0258

QUESTION TEXT
Çok severek okuduğun derin bir kitabı/makaleyi partnerinle paylaştın ama o "Çok sıkıcıymış" deyip kestirip attı.

CURRENT PRIMARY
(empty / primary_review_pending)

RECOMMENDED PRIMARY
autonomy

SECONDARY CANDIDATE
closeness_pace

WHY CURRENT PRIMARY IS WEAKER
There is no stored canonical primary (Phase 1C pending). The question still has a clear designed contrast; emptiness is not a reason to leave it unlabeled after human apply.

WHY RECOMMENDED PRIMARY IS BETTER
`autonomy` is better because the option poles map to independent space/self-direction versus merging. Keep `closeness_pace` as secondary, not a second primary.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `autonomy`
secondary_dimensions: `closeness_pace`
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no

### frequency_v2_q0261

QUESTION ID
frequency_v2_q0261

QUESTION TEXT
İkiniz arasında ufak bir yanlış anlaşılma oldu. Partnerin olayı sana uzun uzun, detaylıca ve kendini sürekli savunarak açıklamaya çalışıyor.

CURRENT PRIMARY
disclosure_pace

RECOMMENDED PRIMARY
repair_style

SECONDARY CANDIDATE
disclosure_pace

WHY CURRENT PRIMARY IS WEAKER
`disclosure_pace` is weaker because that construct (how openly/quickly inner states are shared versus held back) is not what the four options are mainly splitting. After a small misunderstanding they narrate at length. Cutting it off, staying in the listen, matching with your own account, or moving on is how you stay in or leave the repair talk.

WHY RECOMMENDED PRIMARY IS BETTER
`repair_style` is better because the option poles map to how they re-engage after tension: immediate vs delayed vs withdrawn (not a moral score). Keep `disclosure_pace` as secondary, not a second primary.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `repair_style`
secondary_dimensions: `disclosure_pace`
stored primary_dimensions count: 1 (disclosure_pace)
collapse dual stored primary to one dominant: no

### frequency_v2_q0264

QUESTION ID
frequency_v2_q0264

QUESTION TEXT
Kendi hayatınla ilgili çok kötü bir haber aldın. Partnerine bu haberi nasıl verirsin?

CURRENT PRIMARY
(empty / primary_review_pending)

RECOMMENDED PRIMARY
disclosure_pace

SECONDARY CANDIDATE
autonomy

WHY CURRENT PRIMARY IS WEAKER
There is no stored canonical primary (Phase 1C pending). The question still has a clear designed contrast; emptiness is not a reason to leave it unlabeled after human apply.

WHY RECOMMENDED PRIMARY IS BETTER
`disclosure_pace` is better because the option poles map to how openly/quickly inner states are shared versus held back. Keep `autonomy` as secondary, not a second primary.

CONFIDENCE:
high

DESIRED ARCHITECTURE
primary_dimension: `disclosure_pace`
secondary_dimensions: `autonomy`
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no

### frequency_v2_q0272

QUESTION ID
frequency_v2_q0272

QUESTION TEXT
Bir sohbet esnasında partnerin, içinde hiçbir romantik duygu barındırmayan ama eski sevgilisinin de olduğu nötr bir anıyı anlattı (örn: "Eski sevgilimle o filme gitmiştik").

CURRENT PRIMARY
uncertainty_tolerance

RECOMMENDED PRIMARY
reassurance_need

SECONDARY CANDIDATE
boundary_firmness

WHY CURRENT PRIMARY IS WEAKER
`uncertainty_tolerance` is weaker because that construct (comfort leaving things unresolved versus needing clarity/closure) is not what the four options are mainly splitting. A casual ex-in-the-story mention: stay easy, quietly cool, ban ex names, or treat it as honesty. The engine is whether that mention threatens the bond, not open ambiguity.

WHY RECOMMENDED PRIMARY IS BETTER
`reassurance_need` is better because the option poles map to seeking confirmation the bond is OK versus not needing that check. Keep `boundary_firmness` as secondary, not a second primary.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `reassurance_need`
secondary_dimensions: `boundary_firmness`
stored primary_dimensions count: 1 (uncertainty_tolerance)
collapse dual stored primary to one dominant: no

### frequency_v2_q0275

QUESTION ID
frequency_v2_q0275

QUESTION TEXT
Partnerin kendi alanında çok büyük ve bireysel bir başarı elde etti.

CURRENT PRIMARY
closeness_pace

RECOMMENDED PRIMARY
autonomy

SECONDARY CANDIDATE
closeness_pace

WHY CURRENT PRIMARY IS WEAKER
`closeness_pace` is weaker because that construct (tempo/intensity of togetherness and intimacy (move close fast vs take it slow)) is not what the four options are mainly splitting. Their individual win: claim it as “we did it,” congratulate and leave it theirs, throw a big celebration, or follow their preferred toast. We-merge versus honoring a separate achievement.

WHY RECOMMENDED PRIMARY IS BETTER
`autonomy` is better because the option poles map to independent space/self-direction versus merging. Keep `closeness_pace` as secondary, not a second primary.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `autonomy`
secondary_dimensions: `closeness_pace`
stored primary_dimensions count: 1 (closeness_pace)
collapse dual stored primary to one dominant: no

### frequency_v2_q0281

QUESTION ID
frequency_v2_q0281

QUESTION TEXT
Kalabalık bir ortamda, arkadaşlarınızın veya ailenin yanında fiziksel temas (sarılma, öpme) konusunda ne düşünürsün?

CURRENT PRIMARY
disclosure_pace

RECOMMENDED PRIMARY
closeness_pace

SECONDARY CANDIDATE
disclosure_pace

WHY CURRENT PRIMARY IS WEAKER
`disclosure_pace` is weaker because that construct (how openly/quickly inner states are shared versus held back) is not what the four options are mainly splitting. Public hug/kiss comfort versus hands-only, private-only affection, or matching only if they start is visible intimacy, not how fast you narrate inner states.

WHY RECOMMENDED PRIMARY IS BETTER
`closeness_pace` is better because the option poles map to tempo/intensity of togetherness and intimacy (move close fast vs take it slow). Keep `disclosure_pace` as secondary, not a second primary.

CONFIDENCE:
high

DESIRED ARCHITECTURE
primary_dimension: `closeness_pace`
secondary_dimensions: `disclosure_pace`
stored primary_dimensions count: 1 (disclosure_pace)
collapse dual stored primary to one dominant: no

### frequency_v2_q0282

QUESTION ID
frequency_v2_q0282

QUESTION TEXT
Partnerinin lüks sayılabilecek bir harcaması oldu (örn: pahalı bir çanta/saat), sen ise birikim yapmayı seven birisin.

CURRENT PRIMARY
(empty / primary_review_pending)

RECOMMENDED PRIMARY
autonomy

SECONDARY CANDIDATE
adaptability

WHY CURRENT PRIMARY IS WEAKER
There is no stored canonical primary (Phase 1C pending). The question still has a clear designed contrast; emptiness is not a reason to leave it unlabeled after human apply.

WHY RECOMMENDED PRIMARY IS BETTER
`autonomy` is better because the option poles map to independent space/self-direction versus merging. Keep `adaptability` as secondary, not a second primary.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `autonomy`
secondary_dimensions: `adaptability`
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no

### frequency_v2_q0284

QUESTION ID
frequency_v2_q0284

QUESTION TEXT
Partnerin aniden saçını çok farklı (ve senin hiç beğenmediğin) bir renge boyattı/kestirdi.

CURRENT PRIMARY
boundary_firmness

RECOMMENDED PRIMARY
disclosure_pace

SECONDARY CANDIDATE
autonomy

WHY CURRENT PRIMARY IS WEAKER
`boundary_firmness` is weaker because that construct (holding a limit/saying no versus yielding the line) is not what the four options are mainly splitting. The haircut already happened; there is no request to refuse. Fake praise, honest dislike, neutral support, or silent self-reminder is shown versus hidden reaction.

WHY RECOMMENDED PRIMARY IS BETTER
`disclosure_pace` is better because the option poles map to how openly/quickly inner states are shared versus held back. Keep `autonomy` as secondary, not a second primary.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `disclosure_pace`
secondary_dimensions: `autonomy`
stored primary_dimensions count: 1 (boundary_firmness)
collapse dual stored primary to one dominant: no

### frequency_v2_q0288

QUESTION ID
frequency_v2_q0288

QUESTION TEXT
Partnerin genel olarak çok kararsız biri. Nereye gidileceğini, ne yeneceğini sana bırakıyor.

CURRENT PRIMARY
structure_preference

RECOMMENDED PRIMARY
initiative

SECONDARY CANDIDATE
none

WHY CURRENT PRIMARY IS WEAKER
`structure_preference` is weaker because that construct (plans/schedules/predictable routines versus loose/unplanned) is not what the four options are mainly splitting. The stem is their indecisiveness leaving choices to you. Enjoying deciding, tiring of the load, neither deciding, or prompting them to choose is who starts versus who waits.

WHY RECOMMENDED PRIMARY IS BETTER
`initiative` is better because the option poles map to who starts, plans, or proposes versus who waits. No extra primary is required.

CONFIDENCE:
high

DESIRED ARCHITECTURE
primary_dimension: `initiative`
secondary_dimensions: (none)
stored primary_dimensions count: 1 (structure_preference)
collapse dual stored primary to one dominant: no

### frequency_v2_q0290

QUESTION ID
frequency_v2_q0290

QUESTION TEXT
Partnerin çok hasta ama inatla "Doktora gitmeyeceğim, bana bir şey olmaz" diyip işe gitmeye çalışıyor.

CURRENT PRIMARY
boundary_firmness

RECOMMENDED PRIMARY
autonomy

SECONDARY CANDIDATE
closeness_pace

WHY CURRENT PRIMARY IS WEAKER
`boundary_firmness` is weaker because that construct (holding a limit/saying no versus yielding the line) is not what the four options are mainly splitting. Override their health choice versus treat them as a self-directed adult. Clinging via all-day monitoring is closeness, not holding your own limit.

WHY RECOMMENDED PRIMARY IS BETTER
`autonomy` is better because the option poles map to independent space/self-direction versus merging. Keep `closeness_pace` as secondary, not a second primary.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `autonomy`
secondary_dimensions: `closeness_pace`
stored primary_dimensions count: 1 (boundary_firmness)
collapse dual stored primary to one dominant: no

### frequency_v2_q0294

QUESTION ID
frequency_v2_q0294

QUESTION TEXT
Uyurken senin tarafın hep sıcak, partnerinin tarafı hep serin olsun istiyor. Yataktaki denge nasıl sağlanır?

CURRENT PRIMARY
boundary_firmness

RECOMMENDED PRIMARY
autonomy

SECONDARY CANDIDATE
closeness_pace

WHY CURRENT PRIMARY IS WEAKER
`boundary_firmness` is weaker because that construct (holding a limit/saying no versus yielding the line) is not what the four options are mainly splitting. Separate duvets versus enduring one blanket to cuddle is independent sleep space versus merging, clearer than saying no versus yielding a verbal limit.

WHY RECOMMENDED PRIMARY IS BETTER
`autonomy` is better because the option poles map to independent space/self-direction versus merging. Keep `closeness_pace` as secondary, not a second primary.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `autonomy`
secondary_dimensions: `closeness_pace`
stored primary_dimensions count: 1 (boundary_firmness)
collapse dual stored primary to one dominant: no

### frequency_v2_q0298

QUESTION ID
frequency_v2_q0298

QUESTION TEXT
Aylardır planladığınız açık hava pikniği/festivali, sabah aniden bastıran şiddetli bir yağmurla tamamen iptal oldu.

CURRENT PRIMARY
uncertainty_tolerance

RECOMMENDED PRIMARY
adaptability

SECONDARY CANDIDATE
structure_preference

WHY CURRENT PRIMARY IS WEAKER
`uncertainty_tolerance` is weaker because that construct (comfort leaving things unresolved versus needing clarity/closure) is not what the four options are mainly splitting. The picnic is already cancelled, not left ambiguous. Ruminate versus invent a home festival versus switch to a home day is adjustment to a changed situation.

WHY RECOMMENDED PRIMARY IS BETTER
`adaptability` is better because the option poles map to adjusting own way to the partner/situation versus staying with own rhythm. Keep `structure_preference` as secondary, not a second primary.

CONFIDENCE:
high

DESIRED ARCHITECTURE
primary_dimension: `adaptability`
secondary_dimensions: `structure_preference`
stored primary_dimensions count: 1 (uncertainty_tolerance)
collapse dual stored primary to one dominant: no

### frequency_v2_q0317

QUESTION ID
frequency_v2_q0317

QUESTION TEXT
Bir tartışma sonrası partneriniz “biraz düşünmem lazım” deyip ortamdan ayrıldı.

CURRENT PRIMARY
autonomy + reassurance_need

RECOMMENDED PRIMARY
repair_style

SECONDARY CANDIDATE
autonomy

WHY CURRENT PRIMARY IS WEAKER
`autonomy + reassurance_need` is weaker because that construct (independent space/self-direction versus merging) is not what the four options are mainly splitting. After a fight they leave to think: grant space, ask how long, send a ping, or withdraw too. Pause-then-return versus reach-out versus shutdown, not everyday solo space.

WHY RECOMMENDED PRIMARY IS BETTER
`repair_style` is better because the option poles map to how they re-engage after tension: immediate vs delayed vs withdrawn (not a moral score). Keep `autonomy` as secondary, not a second primary.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `repair_style`
secondary_dimensions: `autonomy`
stored primary_dimensions count: 2 (autonomy, reassurance_need)
collapse dual stored primary to one dominant: yes

### frequency_v2_q0333

QUESTION ID
frequency_v2_q0333

QUESTION TEXT
Yeni biriyle mesajlaşırken o çok uzun yazıyor, siz daha kısa ve öz yazmayı seviyorsunuz.

CURRENT PRIMARY
contact_need + adaptability

RECOMMENDED PRIMARY
adaptability

SECONDARY CANDIDATE
contact_need

WHY CURRENT PRIMARY IS WEAKER
`contact_need + adaptability` is weaker because that construct (how much contact/availability frequency is wanted (frequent vs sparse)) is not what the four options are mainly splitting. The stem is long messages versus short, not frequent versus sparse. Match their length, keep your style, or name the mismatch is style adjustment.

WHY RECOMMENDED PRIMARY IS BETTER
`adaptability` is better because the option poles map to adjusting own way to the partner/situation versus staying with own rhythm. Keep `contact_need` as secondary, not a second primary.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `adaptability`
secondary_dimensions: `contact_need`
stored primary_dimensions count: 2 (contact_need, adaptability)
collapse dual stored primary to one dominant: yes

### frequency_v2_q0346

QUESTION ID
frequency_v2_q0346

QUESTION TEXT
Yabancı bir şehre tatile gittiniz. Partnerin navigasyon görevini üstlendi ama sizi tamamen yanlış bir yere götürüp kaybettirdi.

CURRENT PRIMARY
(empty / primary_review_pending)

RECOMMENDED PRIMARY
adaptability

SECONDARY CANDIDATE
initiative

WHY CURRENT PRIMARY IS WEAKER
There is no stored canonical primary (Phase 1C pending). The question still has a clear designed contrast; emptiness is not a reason to leave it unlabeled after human apply.

WHY RECOMMENDED PRIMARY IS BETTER
`adaptability` is better because the option poles map to adjusting own way to the partner/situation versus staying with own rhythm. Keep `initiative` as secondary, not a second primary.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `adaptability`
secondary_dimensions: `initiative`
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no

### frequency_v2_q0348

QUESTION ID
frequency_v2_q0348

QUESTION TEXT
Birlikte yaşadığınız dönemde, partnerin sana hiç danışmadan kendi birikiminden yakın bir arkadaşına yüklü bir borç verdi.

CURRENT PRIMARY
boundary_firmness

RECOMMENDED PRIMARY
autonomy

SECONDARY CANDIDATE
boundary_firmness

WHY CURRENT PRIMARY IS WEAKER
`boundary_firmness` is weaker because that construct (holding a limit/saying no versus yielding the line) is not what the four options are mainly splitting. A large loan from their savings with no consult. Their money their call versus hurt that a shared life was bypassed. Independent purse versus merged decision space.

WHY RECOMMENDED PRIMARY IS BETTER
`autonomy` is better because the option poles map to independent space/self-direction versus merging. Keep `boundary_firmness` as secondary, not a second primary.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `autonomy`
secondary_dimensions: `boundary_firmness`
stored primary_dimensions count: 1 (boundary_firmness)
collapse dual stored primary to one dominant: no

### frequency_v2_q0352

QUESTION ID
frequency_v2_q0352

QUESTION TEXT
Netflix/Spotify gibi ortak kullanılabilecek platformlarda kendi profillerinizi/şifrelerinizi birleştirmek sence nasıl bir fikirdir?

CURRENT PRIMARY
closeness_pace

RECOMMENDED PRIMARY
autonomy

SECONDARY CANDIDATE
closeness_pace

WHY CURRENT PRIMARY IS WEAKER
`closeness_pace` is weaker because that construct (tempo/intensity of togetherness and intimacy (move close fast vs take it slow)) is not what the four options are mainly splitting. Shared streaming logins: one merged profile versus keep your algorithm private. Independent digital space versus merging, not tempo of togetherness.

WHY RECOMMENDED PRIMARY IS BETTER
`autonomy` is better because the option poles map to independent space/self-direction versus merging. Keep `closeness_pace` as secondary, not a second primary.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `autonomy`
secondary_dimensions: `closeness_pace`
stored primary_dimensions count: 1 (closeness_pace)
collapse dual stored primary to one dominant: no

### frequency_v2_q0353

QUESTION ID
frequency_v2_q0353

QUESTION TEXT
Baş başa yemek yerken partnerinin telefonu masada ve ekranı yukarı bakıyor. Sürekli bildirimler yanıp sönüyor.

CURRENT PRIMARY
contact_need

RECOMMENDED PRIMARY
closeness_pace

SECONDARY CANDIDATE
contact_need

WHY CURRENT PRIMARY IS WEAKER
`contact_need` is weaker because that construct (how much contact/availability frequency is wanted (frequent vs sparse)) is not what the four options are mainly splitting. Phone face-up through a one-to-one dinner splits present togetherness, not message frequency. Protect the shared meal versus tolerate divided attention.

WHY RECOMMENDED PRIMARY IS BETTER
`closeness_pace` is better because the option poles map to tempo/intensity of togetherness and intimacy (move close fast vs take it slow). Keep `contact_need` as secondary, not a second primary.

CONFIDENCE:
high

DESIRED ARCHITECTURE
primary_dimension: `closeness_pace`
secondary_dimensions: `contact_need`
stored primary_dimensions count: 1 (contact_need)
collapse dual stored primary to one dominant: no

### frequency_v2_q0358

QUESTION ID
frequency_v2_q0358

QUESTION TEXT
Partnerin sosyal medyada çok tartışmalı ve senin hiç katılmadığın, hatta rahatsız olduğun bir politik/sosyal görüş paylaştı.

CURRENT PRIMARY
boundary_firmness

RECOMMENDED PRIMARY
autonomy

SECONDARY CANDIDATE
none

WHY CURRENT PRIMARY IS WEAKER
`boundary_firmness` is weaker because that construct (holding a limit/saying no versus yielding the line) is not what the four options are mainly splitting. Nobody is holding or yielding a personal limit. The contrast is intervening in their public stance versus treating their digital identity as theirs.

WHY RECOMMENDED PRIMARY IS BETTER
`autonomy` is better because the option poles map to independent space/self-direction versus merging. No extra primary is required.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `autonomy`
secondary_dimensions: (none)
stored primary_dimensions count: 1 (boundary_firmness)
collapse dual stored primary to one dominant: no

### frequency_v2_q0360

QUESTION ID
frequency_v2_q0360

QUESTION TEXT
Sadece kahve içmek için buluşacaktınız ama partnerin elinde büyük ve anlamlı bir hediye ile geldi. (Özel bir gün değil)

CURRENT PRIMARY
uncertainty_tolerance

RECOMMENDED PRIMARY
closeness_pace

SECONDARY CANDIDATE
adaptability

WHY CURRENT PRIMARY IS WEAKER
`uncertainty_tolerance` is weaker because that construct (comfort leaving things unresolved versus needing clarity/closure) is not what the four options are mainly splitting. An unplanned meaningful gift is not unresolved ambiguity. Welcoming the sudden intimacy versus holding distance is closeness intensification versus keeping the casual frame.

WHY RECOMMENDED PRIMARY IS BETTER
`closeness_pace` is better because the option poles map to tempo/intensity of togetherness and intimacy (move close fast vs take it slow). Keep `adaptability` as secondary, not a second primary.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `closeness_pace`
secondary_dimensions: `adaptability`
stored primary_dimensions count: 1 (uncertainty_tolerance)
collapse dual stored primary to one dominant: no

### frequency_v2_q0370

QUESTION ID
frequency_v2_q0370

QUESTION TEXT
Gece yarısı partnerinin telefonuna kayıtlı olmayan bir numaradan sadece "Uyudun mu?" mesajı geldi.

CURRENT PRIMARY
(empty / primary_review_pending)

RECOMMENDED PRIMARY
uncertainty_tolerance

SECONDARY CANDIDATE
reassurance_need

WHY CURRENT PRIMARY IS WEAKER
There is no stored canonical primary (Phase 1C pending). The question still has a clear designed contrast; emptiness is not a reason to leave it unlabeled after human apply.

WHY RECOMMENDED PRIMARY IS BETTER
`uncertainty_tolerance` is better because the option poles map to comfort leaving things unresolved versus needing clarity/closure. Keep `reassurance_need` as secondary, not a second primary.

CONFIDENCE:
high

DESIRED ARCHITECTURE
primary_dimension: `uncertainty_tolerance`
secondary_dimensions: `reassurance_need`
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no

### frequency_v2_q0372

QUESTION ID
frequency_v2_q0372

QUESTION TEXT
Partnerinin arkadaş grubunda, dedikoducu ve sürekli kriz yaratan toksik bir kişi var. Grup buluşmalarında ne yaparsın?

CURRENT PRIMARY
social_energy

RECOMMENDED PRIMARY
boundary_firmness

SECONDARY CANDIDATE
social_energy

WHY CURRENT PRIMARY IS WEAKER
`social_energy` is weaker because that construct (external social/activity energy versus low-key/private) is not what the four options are mainly splitting. The stem is a toxic group member, not general party energy. Refuse to attend, ice them, politely yield, or join the drama. Holding versus yielding a limit around that person.

WHY RECOMMENDED PRIMARY IS BETTER
`boundary_firmness` is better because the option poles map to holding a limit/saying no versus yielding the line. Keep `social_energy` as secondary, not a second primary.

CONFIDENCE:
high

DESIRED ARCHITECTURE
primary_dimension: `boundary_firmness`
secondary_dimensions: `social_energy`
stored primary_dimensions count: 1 (social_energy)
collapse dual stored primary to one dominant: no

### frequency_v2_q0373

QUESTION ID
frequency_v2_q0373

QUESTION TEXT
Beraber çok dramatik bir film izlerken partnerin hıçkırarak ağlamaya başladı.

CURRENT PRIMARY
reassurance_need

RECOMMENDED PRIMARY
adaptability

SECONDARY CANDIDATE
none

WHY CURRENT PRIMARY IS WEAKER
`reassurance_need` is weaker because that construct (seeking confirmation the bond is OK versus not needing that check) is not what the four options are mainly splitting. Partner sobbing at a film is not a bond-check. Matching their emotion, giving space, defusing, or staying in your cooler register is adjusting to their state versus keeping your rhythm.

WHY RECOMMENDED PRIMARY IS BETTER
`adaptability` is better because the option poles map to adjusting own way to the partner/situation versus staying with own rhythm. No extra primary is required.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `adaptability`
secondary_dimensions: (none)
stored primary_dimensions count: 1 (reassurance_need)
collapse dual stored primary to one dominant: no

### frequency_v2_q0375

QUESTION ID
frequency_v2_q0375

QUESTION TEXT
Partnerin sana "Birlikte bir kafe/girişim açalım, hem beraber çalışır hem kazanırız" fikriyle geldi.

CURRENT PRIMARY
initiative

RECOMMENDED PRIMARY
autonomy

SECONDARY CANDIDATE
structure_preference

WHY CURRENT PRIMARY IS WEAKER
`initiative` is weaker because that construct (who starts, plans, or proposes versus who waits) is not what the four options are mainly splitting. They already proposed the cafe. The contrast is fusing work and the relationship versus keeping domains separate. Initiative is not the question.

WHY RECOMMENDED PRIMARY IS BETTER
`autonomy` is better because the option poles map to independent space/self-direction versus merging. Keep `structure_preference` as secondary, not a second primary.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `autonomy`
secondary_dimensions: `structure_preference`
stored primary_dimensions count: 1 (initiative)
collapse dual stored primary to one dominant: no

### frequency_v2_q0382

QUESTION ID
frequency_v2_q0382

QUESTION TEXT
Kış ortasında evin kombisi bozuldu ve aniden çok yüklü (bir maaş kadar) bir tamir masrafı çıktı.

CURRENT PRIMARY
structure_preference

RECOMMENDED PRIMARY
initiative

SECONDARY CANDIDATE
none

WHY CURRENT PRIMARY IS WEAKER
`structure_preference` is weaker because that construct (plans/schedules/predictable routines versus loose/unplanned) is not what the four options are mainly splitting. A sudden boiler bill is not plans-versus-loose-routine. You take charge and fix it, ruminate, leave the solution to them, or delay. Who acts versus who waits.

WHY RECOMMENDED PRIMARY IS BETTER
`initiative` is better because the option poles map to who starts, plans, or proposes versus who waits. No extra primary is required.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `initiative`
secondary_dimensions: (none)
stored primary_dimensions count: 1 (structure_preference)
collapse dual stored primary to one dominant: no

### frequency_v2_q0383

QUESTION ID
frequency_v2_q0383

QUESTION TEXT
Sen çok gerçekçi, bazen karamsar birisin. Partnerin ise her felakette "Evrene iyi mesaj yollayalım, her şey harika olacak" diyen biri.

CURRENT PRIMARY
(empty / primary_review_pending)

RECOMMENDED PRIMARY
adaptability

SECONDARY CANDIDATE
autonomy

WHY CURRENT PRIMARY IS WEAKER
There is no stored canonical primary (Phase 1C pending). The question still has a clear designed contrast; emptiness is not a reason to leave it unlabeled after human apply.

WHY RECOMMENDED PRIMARY IS BETTER
`adaptability` is better because the option poles map to adjusting own way to the partner/situation versus staying with own rhythm. Keep `autonomy` as secondary, not a second primary.

CONFIDENCE:
high

DESIRED ARCHITECTURE
primary_dimension: `adaptability`
secondary_dimensions: `autonomy`
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no

### frequency_v2_q0390

QUESTION ID
frequency_v2_q0390

QUESTION TEXT
Sokakta yürürken veya kafedeyken ilişkinizle ilgili çok gergin bir tartışma alevlendi.

CURRENT PRIMARY
(empty / primary_review_pending)

RECOMMENDED PRIMARY
repair_style

SECONDARY CANDIDATE
social_energy

WHY CURRENT PRIMARY IS WEAKER
There is no stored canonical primary (Phase 1C pending). The question still has a clear designed contrast; emptiness is not a reason to leave it unlabeled after human apply.

WHY RECOMMENDED PRIMARY IS BETTER
`repair_style` is better because the option poles map to how they re-engage after tension: immediate vs delayed vs withdrawn (not a moral score). Keep `social_energy` as secondary, not a second primary.

CONFIDENCE:
high

DESIRED ARCHITECTURE
primary_dimension: `repair_style`
secondary_dimensions: `social_energy`
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no

### frequency_v2_q0393

QUESTION ID
frequency_v2_q0393

QUESTION TEXT
Şık giyindiniz, yürüyerek bir davete gidiyorsunuz. Birden sağanak yağmur bastırdı ve şemsiye yok.

CURRENT PRIMARY
uncertainty_tolerance

RECOMMENDED PRIMARY
adaptability

SECONDARY CANDIDATE
structure_preference

WHY CURRENT PRIMARY IS WEAKER
`uncertainty_tolerance` is weaker because that construct (comfort leaving things unresolved versus needing clarity/closure) is not what the four options are mainly splitting. A downpour is a broken plan, not an unresolved ambiguity. Meltdown versus enjoying the rain versus instant solve versus going home is adjusting to the situation.

WHY RECOMMENDED PRIMARY IS BETTER
`adaptability` is better because the option poles map to adjusting own way to the partner/situation versus staying with own rhythm. Keep `structure_preference` as secondary, not a second primary.

CONFIDENCE:
high

DESIRED ARCHITECTURE
primary_dimension: `adaptability`
secondary_dimensions: `structure_preference`
stored primary_dimensions count: 1 (uncertainty_tolerance)
collapse dual stored primary to one dominant: no

### frequency_v2_q0409

QUESTION ID
frequency_v2_q0409

QUESTION TEXT
Bir tartışma sonrası partneriniz “biraz yalnız kalmam lazım” dedi ve odasına çekildi.

CURRENT PRIMARY
autonomy + reassurance_need

RECOMMENDED PRIMARY
repair_style

SECONDARY CANDIDATE
autonomy

WHY CURRENT PRIMARY IS WEAKER
`autonomy + reassurance_need` is weaker because that construct (independent space/self-direction versus merging) is not what the four options are mainly splitting. This is after a fight, and they have already withdrawn. Grant the pause, ask how long, knock with “I am here,” or withdraw too. Post-rupture re-engagement pacing.

WHY RECOMMENDED PRIMARY IS BETTER
`repair_style` is better because the option poles map to how they re-engage after tension: immediate vs delayed vs withdrawn (not a moral score). Keep `autonomy` as secondary, not a second primary.

CONFIDENCE:
high

DESIRED ARCHITECTURE
primary_dimension: `repair_style`
secondary_dimensions: `autonomy`
stored primary_dimensions count: 2 (autonomy, reassurance_need)
collapse dual stored primary to one dominant: yes

### frequency_v2_q0426

QUESTION ID
frequency_v2_q0426

QUESTION TEXT
Yeni biriyle mesajlaşırken o çok uzun yazıyor, siz daha kısa yazmayı seviyorsunuz.

CURRENT PRIMARY
contact_need + adaptability

RECOMMENDED PRIMARY
adaptability

SECONDARY CANDIDATE
contact_need

WHY CURRENT PRIMARY IS WEAKER
`contact_need + adaptability` is weaker because that construct (how much contact/availability frequency is wanted (frequent vs sparse)) is not what the four options are mainly splitting. The stem is long messages versus short ones, not how often you are available. Matching their length versus keeping your style is style adjustment.

WHY RECOMMENDED PRIMARY IS BETTER
`adaptability` is better because the option poles map to adjusting own way to the partner/situation versus staying with own rhythm. Keep `contact_need` as secondary, not a second primary.

CONFIDENCE:
medium

DESIRED ARCHITECTURE
primary_dimension: `adaptability`
secondary_dimensions: `contact_need`
stored primary_dimensions count: 2 (contact_need, adaptability)
collapse dual stored primary to one dominant: yes

## 2. AMBIGUOUS (21)

CANDIDATE A is the Phase 1D recommended label. CANDIDATE B is the competing label. RECOMMENDATION A means: store A as the single `primary_dimension`, B as secondary if listed.

### frequency_v2_q0005

QUESTION ID
frequency_v2_q0005

QUESTION TEXT
Birlikte izlediğiniz bir filmdeki ahlaki bir ikilem üzerine tamamen zıt görüşlere sahipsiniz. Tartışma uzadı, ne yaparsın?

CANDIDATE A
uncertainty_tolerance

CANDIDATE B
boundary_firmness

WHAT BEHAVIOR A CAPTURES
comfort leaving things unresolved versus needing clarity/closure

WHAT BEHAVIOR B CAPTURES
holding a limit/saying no versus yielding the line

RECOMMENDATION:
A

WHY
Need-for-closure on a disagreement is the stronger designed pole (keep arguing vs let it stand). Yielding/holding a “limit” is weaker because a film-opinion clash is not a personal line.

DESIRED ARCHITECTURE
primary_dimension: `uncertainty_tolerance`
secondary_dimensions: `boundary_firmness`
stored primary_dimensions count: 1 (boundary_firmness)
collapse dual stored primary to one dominant: no

CONFIDENCE
medium

### frequency_v2_q0011

QUESTION ID
frequency_v2_q0011

QUESTION TEXT
Akşam şık bir restorana gitmek üzere hazırlandın ama partnerin son dakika arayıp "Çok yorgunum, evde film ve pizza yapsak uyar mı?" dedi.

CANDIDATE A
adaptability

CANDIDATE B
structure_preference

WHAT BEHAVIOR A CAPTURES
adjusting own way to the partner/situation versus staying with own rhythm

WHAT BEHAVIOR B CAPTURES
plans/schedules/predictable routines versus loose/unplanned

RECOMMENDATION:
A

WHY
The event is a last-minute change of their state. Dominant contrast is whether you reshuffle versus stay attached to the evening; plan-loyalty is real but supporting.

DESIRED ARCHITECTURE
primary_dimension: `adaptability`
secondary_dimensions: `structure_preference`
stored primary_dimensions count: 1 (structure_preference)
collapse dual stored primary to one dominant: no

CONFIDENCE
medium

### frequency_v2_q0021

QUESTION ID
frequency_v2_q0021

QUESTION TEXT
İnanılmaz yoğun ve insanlarla sürekli konuştuğun bir haftayı geride bıraktın. Deşarj olmak için neye ihtiyacın var?

CANDIDATE A
social_energy

CANDIDATE B
autonomy

WHAT BEHAVIOR A CAPTURES
external social/activity energy versus low-key/private

WHAT BEHAVIOR B CAPTURES
independent space/self-direction versus merging

RECOMMENDATION:
A

WHY
The stem is recharge after a people-heavy week. Out versus quiet is social-energy; excluding the partner is an autonomy flavor, not a second primary.

DESIRED ARCHITECTURE
primary_dimension: `social_energy`
secondary_dimensions: `autonomy`
stored primary_dimensions count: 1 (autonomy)
collapse dual stored primary to one dominant: no

CONFIDENCE
medium

### frequency_v2_q0026

QUESTION ID
frequency_v2_q0026

QUESTION TEXT
Temel bir inanç veya hayata bakış açısı konusunda partnerinle tamamen zıt olduğunuzu fark ettiniz.

CANDIDATE A
uncertainty_tolerance

CANDIDATE B
adaptability

WHAT BEHAVIOR A CAPTURES
comfort leaving things unresolved versus needing clarity/closure

WHAT BEHAVIOR B CAPTURES
adjusting own way to the partner/situation versus staying with own rhythm

RECOMMENDATION:
A

WHY
Hours toward common ground versus living with separate worldviews is closure versus live-with-difference. Attunement is a supporting adaptability flavor.

DESIRED ARCHITECTURE
primary_dimension: `uncertainty_tolerance`
secondary_dimensions: `adaptability`
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no

CONFIDENCE
medium

### frequency_v2_q0030

QUESTION ID
frequency_v2_q0030

QUESTION TEXT
Partnerinin geçmişiyle ilgili zarar verici olmayan ama senin yeni öğrendiğin önemli bir detayı (örn: eski mesleği) gizlediğini fark ettin.

CANDIDATE A
disclosure_pace

CANDIDATE B
uncertainty_tolerance

WHAT BEHAVIOR A CAPTURES
how openly/quickly inner states are shared versus held back

WHAT BEHAVIOR B CAPTURES
comfort leaving things unresolved versus needing clarity/closure

RECOMMENDATION:
A

WHY
The hidden-past detail is mainly how much openness you expect now versus later. Need to resolve concealment is supporting, not a second primary.

DESIRED ARCHITECTURE
primary_dimension: `disclosure_pace`
secondary_dimensions: `uncertainty_tolerance`
stored primary_dimensions count: 1 (disclosure_pace)
collapse dual stored primary to one dominant: no

CONFIDENCE
medium

### frequency_v2_q0033

QUESTION ID
frequency_v2_q0033

QUESTION TEXT
Bir ilişkide "Seni seviyorum" demek veya derin duyguları itiraf etmek sence nasıl bir süreçtir?

CANDIDATE A
closeness_pace

CANDIDATE B
disclosure_pace

WHAT BEHAVIOR A CAPTURES
tempo/intensity of togetherness and intimacy (move close fast vs take it slow)

WHAT BEHAVIOR B CAPTURES
how openly/quickly inner states are shared versus held back

RECOMMENDATION:
A

WHY
“I love you” timing is intimacy-tempo first. How fast the feeling is spoken is disclosure sitting on the same milestone, not a co-primary.

DESIRED ARCHITECTURE
primary_dimension: `closeness_pace`
secondary_dimensions: `disclosure_pace`
stored primary_dimensions count: 1 (closeness_pace)
collapse dual stored primary to one dominant: no

CONFIDENCE
medium

### frequency_v2_q0035

QUESTION ID
frequency_v2_q0035

QUESTION TEXT
Hayatında her şeyin üst üste geldiği, inanılmaz stresli bir dönemdesin. İlişkine nasıl yansır?

CANDIDATE A
disclosure_pace

CANDIDATE B
contact_need

WHAT BEHAVIOR A CAPTURES
how openly/quickly inner states are shared versus held back

WHAT BEHAVIOR B CAPTURES
how much contact/availability frequency is wanted (frequent vs sparse)

RECOMMENDATION:
A

WHY
Under stacked stress the A/B split is share-the-load versus go quiet. Contact volume changes because of that, so contact_need is secondary.

DESIRED ARCHITECTURE
primary_dimension: `disclosure_pace`
secondary_dimensions: `contact_need`
stored primary_dimensions count: 1 (contact_need)
collapse dual stored primary to one dominant: no

CONFIDENCE
medium

### frequency_v2_q0037

QUESTION ID
frequency_v2_q0037

QUESTION TEXT
Gece uyumak üzeresin, çok yorgunsun. Partnerin aniden ilişkinizle ilgili derin ve ciddi bir konuyu açtı.

CANDIDATE A
boundary_firmness

CANDIDATE B
uncertainty_tolerance

WHAT BEHAVIOR A CAPTURES
holding a limit/saying no versus yielding the line

WHAT BEHAVIOR B CAPTURES
comfort leaving things unresolved versus needing clarity/closure

RECOMMENDATION:
REWRITE

WHY
Do not auto-pick boundary_firmness or uncertainty_tolerance. Option A is written as cannot-leave-unresolved (closure). Option B is an explicit sleep-limit. Those are two designed axes in one item. Isolate one axis in a later rewrite; until then do not store both IDs as primary_dimensions.

IMPROVED STEM (options not rewritten yet)
Gece uyumak üzeresin ve çok yorgunsun. Partnerin ilişkinizle ilgili ciddi bir konuyu tam şimdi konuşmak istiyor. Bu saatte konuşma talebini nasıl karşılar ve uykunu nasıl yönetirsin?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: `boundary_firmness`, `uncertainty_tolerance`
stored primary_dimensions count: 1 (boundary_firmness)
collapse dual stored primary to one dominant: no
Do not keep two IDs in primary_dimensions while waiting for rewrite.

CONFIDENCE
medium

### frequency_v2_q0065

QUESTION ID
frequency_v2_q0065

QUESTION TEXT
Partnerin seninle ilgili bir sınırını (zaman, konu, davranış) ilk kez net ifade etti.

CANDIDATE A
adaptability

CANDIDATE B
boundary_firmness

WHAT BEHAVIOR A CAPTURES
adjusting own way to the partner/situation versus staying with own rhythm

WHAT BEHAVIOR B CAPTURES
holding a limit/saying no versus yielding the line

RECOMMENDATION:
A

WHY
They stated a limit about you. The main fork is whether you adjust to their constraint. Answering with your own limits is supporting boundary evidence. Collapse the stored dual list to one dominant.

DESIRED ARCHITECTURE
primary_dimension: `adaptability`
secondary_dimensions: `boundary_firmness`
stored primary_dimensions count: 2 (boundary_firmness, adaptability)
collapse dual stored primary to one dominant: yes

CONFIDENCE
medium

### frequency_v2_q0130

QUESTION ID
frequency_v2_q0130

QUESTION TEXT
Önemli bir konuda hayata bakışınızın belirgin biçimde farklı olduğunu fark ettiniz.

CANDIDATE A
uncertainty_tolerance

CANDIDATE B
autonomy

WHAT BEHAVIOR A CAPTURES
comfort leaving things unresolved versus needing clarity/closure

WHAT BEHAVIOR B CAPTURES
independent space/self-direction versus merging

RECOMMENDATION:
A

WHY
An outlook gap is not a crossed personal line. Working it through versus leaving views uncentered is uncertainty_tolerance; separate-worlds is supporting autonomy.

DESIRED ARCHITECTURE
primary_dimension: `uncertainty_tolerance`
secondary_dimensions: `autonomy`
stored primary_dimensions count: 1 (boundary_firmness)
collapse dual stored primary to one dominant: no

CONFIDENCE
medium

### frequency_v2_q0139

QUESTION ID
frequency_v2_q0139

QUESTION TEXT
İlişkinin ilk ayında partnerin sana beklediğinden çok daha pahalı bir hediye aldı.

CANDIDATE A
closeness_pace

CANDIDATE B
boundary_firmness

WHAT BEHAVIOR A CAPTURES
tempo/intensity of togetherness and intimacy (move close fast vs take it slow)

WHAT BEHAVIOR B CAPTURES
holding a limit/saying no versus yielding the line

RECOMMENDATION:
A

WHY
An extravagant first-month gift is too-fast investment first. Naming a gesture-scale limit is a supporting boundary flavor.

DESIRED ARCHITECTURE
primary_dimension: `closeness_pace`
secondary_dimensions: `boundary_firmness`
stored primary_dimensions count: 1 (boundary_firmness)
collapse dual stored primary to one dominant: no

CONFIDENCE
medium

### frequency_v2_q0163

QUESTION ID
frequency_v2_q0163

QUESTION TEXT
Sen iş yerinde berbat ve stresli bir gün geçirdin, partnerin ise harika haberler aldığı enerjik bir gün geçirdi. Akşam buluştunuz.

CANDIDATE A
adaptability

CANDIDATE B
disclosure_pace

WHAT BEHAVIOR A CAPTURES
adjusting own way to the partner/situation versus staying with own rhythm

WHAT BEHAVIOR B CAPTURES
how openly/quickly inner states are shared versus held back

RECOMMENDATION:
REWRITE

WHY
Current options mix energy-matching (adaptability) with whether you disclose the bad day. Isolate one axis; do not dual-primary from mixed options.

IMPROVED STEM (options not rewritten yet)
Sen berbat bir gün geçirdin, partnerin ise enerjik ve iyi haberli. Akşam buluştuğunuzda kendi gününün enerjisini mi korursun, yoksa onun moduna mı uyumlanırsın?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: `adaptability`, `disclosure_pace`
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no
Do not keep two IDs in primary_dimensions while waiting for rewrite.

CONFIDENCE
medium

### frequency_v2_q0274

QUESTION ID
frequency_v2_q0274

QUESTION TEXT
Birlikte kanepede otururken yarım saattir ikiniz de hiç konuşmadınız. Sen ne yaparsın?

CANDIDATE A
contact_need

CANDIDATE B
closeness_pace

WHAT BEHAVIOR A CAPTURES
how much contact/availability frequency is wanted (frequent vs sparse)

WHAT BEHAVIOR B CAPTURES
tempo/intensity of togetherness and intimacy (move close fast vs take it slow)

RECOMMENDATION:
A

WHY
Couch silence for 30 minutes is mainly whether you need talk/availability now. Comfortable quiet togetherness is a closeness flavor, not a second primary.

DESIRED ARCHITECTURE
primary_dimension: `contact_need`
secondary_dimensions: `closeness_pace`
stored primary_dimensions count: 1 (closeness_pace)
collapse dual stored primary to one dominant: no

CONFIDENCE
medium

### frequency_v2_q0286

QUESTION ID
frequency_v2_q0286

QUESTION TEXT
Partnerin seni en yakın (tek) arkadaşıyla tanıştırdı. Gece boyu kendi aralarındaki iç şakaları konuşup güldüler.

CANDIDATE A
reassurance_need

CANDIDATE B
social_energy

WHAT BEHAVIOR A CAPTURES
seeking confirmation the bond is OK versus not needing that check

WHAT BEHAVIOR B CAPTURES
external social/activity energy versus low-key/private

RECOMMENDATION:
A

WHY
Insider-joke exclusion is a bond-OK check. Joining their circle versus going to your phone is social-energy overlay, not co-primary.

DESIRED ARCHITECTURE
primary_dimension: `reassurance_need`
secondary_dimensions: `social_energy`
stored primary_dimensions count: 1 (social_energy)
collapse dual stored primary to one dominant: no

CONFIDENCE
medium

### frequency_v2_q0295

QUESTION ID
frequency_v2_q0295

QUESTION TEXT
Günün stresiyle sessizce ağlamaya başladın. Partnerin odaya girdi. Sen ne yaparsın?

CANDIDATE A
disclosure_pace

CANDIDATE B
autonomy

WHAT BEHAVIOR A CAPTURES
how openly/quickly inner states are shared versus held back

WHAT BEHAVIOR B CAPTURES
independent space/self-direction versus merging

RECOMMENDATION:
REWRITE

WHY
Reach-for-comfort, send-them-out, tell-immediately, and deflect mix reassurance, autonomy, and disclosure. Isolate disclosure_pace (or another single axis) rather than storing multiple primaries.

IMPROVED STEM (options not rewritten yet)
Günün stresiyle sessizce ağlamaya başladın. Partnerin odaya girdi. İçindekini ne kadar açık ve ne kadar çabuk paylaşırsın?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: `disclosure_pace`, `autonomy`
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no
Do not keep two IDs in primary_dimensions while waiting for rewrite.

CONFIDENCE
medium

### frequency_v2_q0356

QUESTION ID
frequency_v2_q0356

QUESTION TEXT
1 haftalık deniz tatilinizin daha 2. gününde sen çok fena güneş geçmesi/gıda zehirlenmesi yaşadın ve odadasın.

CANDIDATE A
autonomy

CANDIDATE B
adaptability

WHAT BEHAVIOR A CAPTURES
independent space/self-direction versus merging

WHAT BEHAVIOR B CAPTURES
adjusting own way to the partner/situation versus staying with own rhythm

RECOMMENDATION:
A

WHY
You are stuck in the room; they still have a vacation. Dominant fork is merge-into-your-illness versus let them keep their own day. Adjustment to the spoiled trip is supporting.

DESIRED ARCHITECTURE
primary_dimension: `autonomy`
secondary_dimensions: `adaptability`
stored primary_dimensions count: 1 (adaptability)
collapse dual stored primary to one dominant: no

CONFIDENCE
medium

### frequency_v2_q0363

QUESTION ID
frequency_v2_q0363

QUESTION TEXT
Baş başa bir mekanda otururken partnerin o an orada tesadüfen karşılaştığı ve senin hiç tanımadığın bir arkadaşını masanıza davet etti.

CANDIDATE A
boundary_firmness

CANDIDATE B
social_energy

WHAT BEHAVIOR A CAPTURES
holding a limit/saying no versus yielding the line

WHAT BEHAVIOR B CAPTURES
external social/activity energy versus low-key/private

RECOMMENDATION:
A

WHY
An uninvited stranger at a couple table is holding versus yielding couple-time. Enjoying new people is social-energy overlay.

DESIRED ARCHITECTURE
primary_dimension: `boundary_firmness`
secondary_dimensions: `social_energy`
stored primary_dimensions count: 1 (boundary_firmness)
collapse dual stored primary to one dominant: no

CONFIDENCE
medium

### frequency_v2_q0365

QUESTION ID
frequency_v2_q0365

QUESTION TEXT
İlişkiniz için çok önemli bir tarihi (yıldönümü) partnerin tamamen unuttu ve o güne normal bir gün gibi devam ediyor.

CANDIDATE A
reassurance_need

CANDIDATE B
structure_preference

WHAT BEHAVIOR A CAPTURES
seeking confirmation the bond is OK versus not needing that check

WHAT BEHAVIOR B CAPTURES
plans/schedules/predictable routines versus loose/unplanned

RECOMMENDATION:
REWRITE

WHY
Current options split bond-check (reassurance) from whether calendar rituals matter (structure). Isolate one; do not keep both as primary_dimensions.

IMPROVED STEM (options not rewritten yet)
Partnerin ilişkiniz için önemli bir tarihi unuttu. Bu sende bağın hâlâ önemsendiğine dair bir sinyal mi aratır, yoksa takvim ritüelleri senin için zaten önemsiz midir?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: `reassurance_need`, `structure_preference`
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no
Do not keep two IDs in primary_dimensions while waiting for rewrite.

CONFIDENCE
medium

### frequency_v2_q0377

QUESTION ID
frequency_v2_q0377

QUESTION TEXT
Çok lüks bir restoranda yemeğinizi yediniz, hesap geldi ve partnerin cüzdanını/kartını evde unuttuğunu fark etti.

CANDIDATE A
adaptability

CANDIDATE B
structure_preference

WHAT BEHAVIOR A CAPTURES
adjusting own way to the partner/situation versus staying with own rhythm

WHAT BEHAVIOR B CAPTURES
plans/schedules/predictable routines versus loose/unplanned

RECOMMENDATION:
A

WHY
Forgotten wallet after the meal is already a closed fact. Dominant fork is roll-with-it versus cling to the original split. Structure is supporting.

DESIRED ARCHITECTURE
primary_dimension: `adaptability`
secondary_dimensions: `structure_preference`
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no

CONFIDENCE
medium

### frequency_v2_q0392

QUESTION ID
frequency_v2_q0392

QUESTION TEXT
Partnerin "Artık diyeti ve sporu bırakıyorum, hayatı yaşayacağım" diyerek aylar süren disiplinini bir günde çöpe attı.

CANDIDATE A
autonomy

CANDIDATE B
adaptability

WHAT BEHAVIOR A CAPTURES
independent space/self-direction versus merging

WHAT BEHAVIOR B CAPTURES
adjusting own way to the partner/situation versus staying with own rhythm

RECOMMENDATION:
A

WHY
Their body/discipline choice is self-direction versus you pulling them back. Joining the pizza is adaptability overlay, not a second primary.

DESIRED ARCHITECTURE
primary_dimension: `autonomy`
secondary_dimensions: `adaptability`
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no

CONFIDENCE
medium

### frequency_v2_q0406

QUESTION ID
frequency_v2_q0406

QUESTION TEXT
Birlikte bir akşam evdesiniz. Partneriniz derin bir konu açmak istiyor, siz o akşam hafif vakit geçirmek istiyorsunuz.

CANDIDATE A
disclosure_pace

CANDIDATE B
boundary_firmness

WHAT BEHAVIOR A CAPTURES
how openly/quickly inner states are shared versus held back

WHAT BEHAVIOR B CAPTURES
holding a limit/saying no versus yielding the line

RECOMMENDATION:
REWRITE

WHY
Stored dual primary_dimensions already names both axes. That is two designed forks, not extra option-weight mass. Isolate one dominant in a rewrite rather than keeping two values in primary_dimensions.

IMPROVED STEM (options not rewritten yet)
Birlikte evdesiniz. Partnerin derin bir konu açmak istiyor; sen o akşam hafif kalmak istiyorsun. Bu gece iç dökme derinliğini mi, yoksa “bu gece olmaz” sınırını mı öncelersin?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: `disclosure_pace`, `boundary_firmness`
stored primary_dimensions count: 2 (boundary_firmness, disclosure_pace)
collapse dual stored primary to one dominant: no
Do not keep two IDs in primary_dimensions while waiting for rewrite.

CONFIDENCE
medium

## 3. WEAK_ITEM (30)

### frequency_v2_q0003

QUESTION ID
frequency_v2_q0003

QUESTION TEXT
Partnerin işten çok gergin ve morali bozuk döndü. Olayı anlatıyor. Senin ilk refleksin ne olur?

ALL FOUR OPTION TEXTS
A: Neden böyle olduğunu mantıklıca analiz edip ona çözüm yolları sunmak.
B: Haklılığına vurgu yapıp duygusal olarak yanında durduğumu hissettirmek.
C: Sakinleşmesi için ona biraz alan tanıyıp, iyi hissettiğinde konuyu açmasını beklemek.
D: Dikkatini dağıtacak, keyfini yerine getirecek başka bir etkinlik veya konuya geçmek.

WHY NO SINGLE PRIMARY FITS
Support-mode (solve/validate/space/distract) is not a 12D primary. Isolate autonomy-versus-reassurance, or drop later.

RECOMMEND:
REWRITE

IMPROVED STEM (options not rewritten yet)
Partnerin işten gergin döndü ve anlatıyor. Ona alan bırakıp kendi haline mi çekilirsin, yoksa yanında kalarak bağın yerinde olduğunu mu hissettirirsin?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: (none)
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no
Do not assign a dominant primary from option-weight mass. Do not keep dual primary_dimensions as a workaround.

### frequency_v2_q0008

QUESTION ID
frequency_v2_q0008

QUESTION TEXT
Partnerin, senin bir davranış tarzını oldukça net ve yapıcı bir şekilde eleştirdi. İlk tepkin genelde nasıl şekillenir?

ALL FOUR OPTION TEXTS
A: Savunmaya geçmeden önce kendi içimde bunu mantıklı bir şekilde tartmak için sessizleşirim.
B: O an üzüldüğümü veya bozulduğumu saklamam, duygumu anında belli ederim.
C: Eleştirideki haklı payını hemen kabul eder, durumu düzeltmek için esneklik gösteririm.
D: Kendi doğrumu ve neden öyle davrandığımı net bir argümanla açıklarım.

WHY NO SINGLE PRIMARY FITS
Silent process, flash emotion, yield, and self-defense sit on three dimensions. Isolate disclosure versus boundary.

RECOMMEND:
REWRITE

IMPROVED STEM (options not rewritten yet)
Partnerin davranışını yapıcı biçimde eleştirdi. O an içini mi açarsın, yoksa kendi doğrunu bir sınır gibi mi savunursun?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: (none)
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no
Do not assign a dominant primary from option-weight mass. Do not keep dual primary_dimensions as a workaround.

### frequency_v2_q0018

QUESTION ID
frequency_v2_q0018

QUESTION TEXT
Beklenmedik büyük bir ortak masraf (örn: aracın bozulması, evin bir masrafı) çıktı.

ALL FOUR OPTION TEXTS
A: Hızla bütçe analizi yapar, alternatifleri listeler, duygusal tepki vermeden çözerim.
B: Stresimi partnerimle paylaşır, bu zorlukta onun "hallederiz" desteğine ihtiyaç duyarım.
C: Akışına bırakırım, çok paniklemem, "bir şekilde çözülür" der geçerim.
D: Onun nasıl bir tepki verdiğine bakar, paniği o yaşıyorsa onu sakinleştiren taraf olurum.

WHY NO SINGLE PRIMARY FITS
Crisis coping mixes structure, reassurance, flow, and soothing. Isolate uncertainty_tolerance versus structure_preference.

RECOMMEND:
REWRITE

IMPROVED STEM (options not rewritten yet)
Beklenmedik büyük bir ortak masraf çıktı. Netleşmeden rahat mısın, yoksa hemen kalem kalem kapatma planı mı istersin?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: (none)
stored primary_dimensions count: 1 (uncertainty_tolerance)
collapse dual stored primary to one dominant: no
Do not assign a dominant primary from option-weight mass. Do not keep dual primary_dimensions as a workaround.

### frequency_v2_q0023

QUESTION ID
frequency_v2_q0023

QUESTION TEXT
Sevdiğini ve değer verdiğini genelde en net nasıl belli edersin?

ALL FOUR OPTION TEXTS
A: Sık sık "seni seviyorum" diyerek ve duygularımı açıkça kelimelere dökerek.
B: Onun için bir şeyler yaparak, hayatını kolaylaştıracak pratik çözümler sunarak.
C: Fiziksel olarak yakın durarak, elini tutarak, sarılarak.
D: Ona kendi alanını ve özgürlüğünü sonuna kadar tanıyarak, onu kısıtlamayarak.

WHY NO SINGLE PRIMARY FITS
Current options are expression channels (words/acts/touch/space), not closeness tempo. Rewrite the stem to a pace contrast.

RECOMMEND:
REWRITE

IMPROVED STEM (options not rewritten yet)
Yeni bir ilişkide sevgiyi ne kadar çabuk yoğunlaştırırsın: söz, temas ve birliktelik erken mi gelir, yoksa yavaş mı ilerlersin?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: (none)
stored primary_dimensions count: 1 (closeness_pace)
collapse dual stored primary to one dominant: no
Do not assign a dominant primary from option-weight mass. Do not keep dual primary_dimensions as a workaround.

### frequency_v2_q0029

QUESTION ID
frequency_v2_q0029

QUESTION TEXT
Partnerin basit bir unutkanlık yaptı (örn: senin için önemli bir evrakı almayı unuttu) ve bu sana zaman kaybettirdi.

ALL FOUR OPTION TEXTS
A: Sinirlendiğimi belli ederim ama sonrasında hemen affedici moda geçerim.
B: Olayı büyütmemek için hiçbir şey demem, durumu kendi başıma hızla telafi ederim.
C: Neden unuttuğunu anlamaya çalışır, bir daha olmaması için ona bir sistem/çözüm öneririm.
D: "Canın sağ olsun" der, sorunu umursamadan alternatif bir plan yaparım.

WHY NO SINGLE PRIMARY FITS
Flash-anger, swallow, system, shrug is irritation handling after a forgotten errand. Not a clean 12D selector item.

RECOMMEND:
DROP_FROM_SELECTABLE_POOL

DESIRED ARCHITECTURE
primary_dimension: none (drop from selectable pool)
secondary_dimensions: (none)
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no
May remain in the 426 archive; selector eligibility should not depend on an invented primary.

### frequency_v2_q0043

QUESTION ID
frequency_v2_q0043

QUESTION TEXT
Partnerin kariyeriyle ilgili çok riskli ve zor bir karar aşamasında ve sana danıştı.

ALL FOUR OPTION TEXTS
A: Artıları, eksileri masaya yatırır, en rasyonel kararı alması için analitik bir tablo çizerim.
B: "Senin içinden ne geçiyor? Seni ne mutlu edecek?" diyerek onun duygularına ayna tutarım.
C: "Ne karar verirsen ver, ben senin arkandayım" diyerek ona koşulsuz onay veririm.
D: Kendi fikrimi netçe söyler, benim tavsiyeme uymasını açıkça savunurum.

WHY NO SINGLE PRIMARY FITS
Counseling style (analyze/mirror/blanket/push) is not 12D. Isolate autonomy versus initiative.

RECOMMEND:
REWRITE

IMPROVED STEM (options not rewritten yet)
Partnerin riskli bir kariyer kararı için sana danıştı. Kararı onun alanında bırakır mısın, yoksa yönü sen mi çekersin?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: (none)
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no
Do not assign a dominant primary from option-weight mass. Do not keep dual primary_dimensions as a workaround.

### frequency_v2_q0047

QUESTION ID
frequency_v2_q0047

QUESTION TEXT
Evde birlikte önemli bir işi yetiştirirken bilgisayar/internet aniden kilitlendi ve veriler kayboldu.

ALL FOUR OPTION TEXTS
A: Hemen panik veya öfke yaşar, hissettiğim çaresizliği sesli şekilde dışa vururum.
B: Sıfır duygu ile anında çözüm moduna geçer, teknik destek arar, plan B'yi uygularım.
C: Partnerimin ne kadar stres olduğuna bakar, o paniklediyse onu sakinleştirmeye odaklanırım.
D: Durumun absürtlük seviyesine güler, "olacağı varmış" deyip kahve yapmaya giderim.

WHY NO SINGLE PRIMARY FITS
A crashed computer is technical-loss affect, not relational 12D. Do not force a primary from option-weight leftovers.

RECOMMEND:
DROP_FROM_SELECTABLE_POOL

DESIRED ARCHITECTURE
primary_dimension: none (drop from selectable pool)
secondary_dimensions: (none)
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no
May remain in the 426 archive; selector eligibility should not depend on an invented primary.

### frequency_v2_q0070

QUESTION ID
frequency_v2_q0070

QUESTION TEXT
Karşı taraf duygusal olarak yoğun bir dönemden geçiyor ve bunu seninle paylaşıyor.

ALL FOUR OPTION TEXTS
A: Dinlerim, yanında olurum, çözüm önermem.
B: Pratik önerilerle yardımcı olmaya çalışırım.
C: Kendi benzer deneyimlerimi anlatırım.
D: Biraz mesafe koyup toparlanmasını beklerim.

WHY NO SINGLE PRIMARY FITS
No couple rupture, so repair_style is the wrong construct. Isolate autonomy versus contact/reassurance.

RECOMMEND:
REWRITE

IMPROVED STEM (options not rewritten yet)
Partnerin zor bir dönemini paylaşıyor; aranızda bir kopuş yok. Yanında kalarak mı dinlersin, yoksa biraz mesafe koyup toparlanmasını mı beklersin?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: (none)
stored primary_dimensions count: 1 (repair_style)
collapse dual stored primary to one dominant: no
Do not assign a dominant primary from option-weight mass. Do not keep dual primary_dimensions as a workaround.

### frequency_v2_q0094

QUESTION ID
frequency_v2_q0094

QUESTION TEXT
Birlikte bir karar vermeniz gerekiyor (taşınma, büyük harcama, aile meselesi).

ALL FOUR OPTION TEXTS
A: Uzun uzun konuşuruz.
B: Pratik artı-eksi listesi yaparız.
C: Benim net tercihim varsa onu savunurum.
D: Onun tercihine yaklaşırım.

WHY NO SINGLE PRIMARY FITS
Decision process is not repair. Isolate initiative (who drives) or adaptability (who yields).

RECOMMEND:
REWRITE

IMPROVED STEM (options not rewritten yet)
Birlikte büyük bir karar vermeniz gerekiyor. Süreci sen mi yürütürsün, yoksa onun temposuna mı bırakırsın?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: (none)
stored primary_dimensions count: 2 (repair_style, adaptability)
collapse dual stored primary to one dominant: no
Do not assign a dominant primary from option-weight mass. Do not keep dual primary_dimensions as a workaround.

### frequency_v2_q0099

QUESTION ID
frequency_v2_q0099

QUESTION TEXT
İlişki bir süredir “idare ediyor” ama heyecan azalmış gibi.

ALL FOUR OPTION TEXTS
A: Konuşup ne yapılabileceğine bakarız.
B: Kabul eder, devam ederim.
C: Kendi hayatımı zenginleştiririm.
D: Mesafe koyup değerlendiririm.

WHY NO SINGLE PRIMARY FITS
Scattered strategies. Isolate initiative or closeness_pace; do not keep dual primary_dimensions as a substitute.

RECOMMEND:
REWRITE

IMPROVED STEM (options not rewritten yet)
İlişki bir süredir idare ediyor. Bağı yeniden yoğunlaştırmak için sen mi adım atarsın, yoksa mevcut mesafeyi mi korursun?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: (none)
stored primary_dimensions count: 2 (initiative, autonomy)
collapse dual stored primary to one dominant: no
Do not assign a dominant primary from option-weight mass. Do not keep dual primary_dimensions as a workaround.

### frequency_v2_q0113

QUESTION ID
frequency_v2_q0113

QUESTION TEXT
Partnerin “Bir saate birkaç arkadaş bize geliyor” dedi. Bundan daha önce haberin yoktu.

ALL FOUR OPTION TEXTS
A: Hemen moda girer, gelenlerle vakit geçirmekten keyif alırım.
B: Ağırlarım ama daha sonra önceden haber verilmesinin benim için önemli olduğunu söylerim.
C: O buluşmaya katılmak zorunda hissetmem; gerekirse kendi planımı yaparım.
D: İlk anda istemesem de onun planına uyum sağlarım.

WHY NO SINGLE PRIMARY FITS
Social energy, boundary, autonomy, and adaptability are all in the options. Isolate structure/notice versus boundary.

RECOMMEND:
REWRITE

IMPROVED STEM (options not rewritten yet)
Partnerin “bir saate arkadaşlar geliyor” dedi; önceden haberin yoktu. Plansız misafiri kabul mü edersin, yoksa haber-kuralı mı koyarsın?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: (none)
stored primary_dimensions count: 1 (boundary_firmness)
collapse dual stored primary to one dominant: no
Do not assign a dominant primary from option-weight mass. Do not keep dual primary_dimensions as a workaround.

### frequency_v2_q0127

QUESTION ID
frequency_v2_q0127

QUESTION TEXT
Partnerin kötü geçen bir iş gününü anlatıyor ve belirgin biçimde zorlanmış görünüyor.

ALL FOUR OPTION TEXTS
A: Önce hissettiklerini anlatmasına alan açarım; çözüm aramaya hemen geçmem.
B: Sorunu parçalayıp işe yarayabilecek seçenekleri birlikte düşünürüm.
C: “Şu an dinlememi mi, çözüm düşünmemizi mi istersin?” diye sorarım.
D: Biraz kafasını dağıtır, konuya daha sonra dönmeyi tercih ederim.

WHY NO SINGLE PRIMARY FITS
Support-after-their-stress is not repair. Needs a stem that isolates one approved dimension, or later drop.

RECOMMEND:
REWRITE

IMPROVED STEM (options not rewritten yet)
Partnerin kötü bir iş gününü anlatıyor. Onu dinleyip yanında mı durursun, yoksa pratik çözüme mi geçersin — ve bu 12D’de hangi tek ekseni ölçsün?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: (none)
stored primary_dimensions count: 1 (repair_style)
collapse dual stored primary to one dominant: no
Do not assign a dominant primary from option-weight mass. Do not keep dual primary_dimensions as a workaround.

### frequency_v2_q0128

QUESTION ID
frequency_v2_q0128

QUESTION TEXT
Partnerin kariyeriyle ilgili riskli bir karar için fikrini sordu.

ALL FOUR OPTION TEXTS
A: Artı-eksi çıkarıp olabildiğince analitik bakarım.
B: Önce hangi seçeneğin onda nasıl bir his yarattığını konuşurum.
C: Kararı onun vermesini ister, hangi yolu seçerse desteklerim.
D: Benim gördüğüm en iyi seçeneği net biçimde söylerim.

WHY NO SINGLE PRIMARY FITS
Duplicate of the q0043 advice-stance problem. Not who-starts. Do not keep two weak counseling items in the selectable pool.

RECOMMEND:
DROP_FROM_SELECTABLE_POOL

DESIRED ARCHITECTURE
primary_dimension: none (drop from selectable pool)
secondary_dimensions: (none)
stored primary_dimensions count: 1 (initiative)
collapse dual stored primary to one dominant: no
May remain in the 426 archive; selector eligibility should not depend on an invented primary.

### frequency_v2_q0135

QUESTION ID
frequency_v2_q0135

QUESTION TEXT
Değer verdiğini en doğal hangi biçimde gösterirsin?

ALL FOUR OPTION TEXTS
A: Duygumu sözle sık ve açık biçimde ifade ederek.
B: Onun işini kolaylaştıran şeyler yaparak.
C: Fiziksel yakınlık ve birlikte zamanla.
D: Ona kendi alanını ve özgürlüğünü vererek.

WHY NO SINGLE PRIMARY FITS
Duplicate construct of q0023 (expression channels). Drop from selectable pool; rewrite q0023 instead of keeping both.

RECOMMEND:
DROP_FROM_SELECTABLE_POOL

DESIRED ARCHITECTURE
primary_dimension: none (drop from selectable pool)
secondary_dimensions: (none)
stored primary_dimensions count: 1 (closeness_pace)
collapse dual stored primary to one dominant: no
May remain in the 426 archive; selector eligibility should not depend on an invented primary.

### frequency_v2_q0153

QUESTION ID
frequency_v2_q0153

QUESTION TEXT
Yeni tanıştığınız dönemde, mesajlaşmak yerine aniden, habersizce seni telefonla aradı.

ALL FOUR OPTION TEXTS
A: Çok sevinirim, sesini duymak ve anlık tepkiler almak mesajlaşmaktan çok daha samimidir.
B: Açarım ama habersiz aramalardan pek hoşlanmam, mesajla "müsait misin" denmesini tercih ederim.
C: O an işim yoksa açarım, işim varsa meşgule atar, sonra dönerim. Doğal karşılarım.
D: Eğer yazışmayı seviyorsam telefon konuşmasını kısa tutup tekrar mesaja dönmeye çalışırım.

WHY NO SINGLE PRIMARY FITS
Channel/interruption is not contact frequency. Rewrite toward wanted availability form, or drop later.

RECOMMEND:
REWRITE

IMPROVED STEM (options not rewritten yet)
Yeni tanıştığınız dönemde habersizce aradı. O anki sesli teması ister misin, yoksa yazışma ritmini mi korursun?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: (none)
stored primary_dimensions count: 1 (contact_need)
collapse dual stored primary to one dominant: no
Do not assign a dominant primary from option-weight mass. Do not keep dual primary_dimensions as a workaround.

### frequency_v2_q0180

QUESTION ID
frequency_v2_q0180

QUESTION TEXT
İkinizi de etkileyen ortak bir maddi kayıp (örn: yanlış bir yatırım veya yüksek bir trafik cezası) yaşandı.

ALL FOUR OPTION TEXTS
A: Suçlunun kim olduğuna odaklanmadan hemen zararı nasıl kapatacağımızın matematiksel planını yaparım.
B: Çok üzülür, moral bozukluğumu günlerce üzerimden atamam, onun beni teselli etmesini beklerim.
C: "Cana geleceğine mala gelsin" diyerek konuyu hızla kapatır, akışa devam ederim.
D: Partnerim eğer çok stres yaptıysa, kendi stresimi gizleyip sürekli onu telkin etmeye odaklanırım.

WHY NO SINGLE PRIMARY FITS
Coping mix. Isolate structure_preference versus uncertainty_tolerance.

RECOMMEND:
REWRITE

IMPROVED STEM (options not rewritten yet)
Ortak bir maddi kayıp oldu. Zararı hemen kalemleştirip kapatmak mı istersin, yoksa “bir şekilde çözülür” deyip belirsizlikte mi durursun?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: (none)
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no
Do not assign a dominant primary from option-weight mass. Do not keep dual primary_dimensions as a workaround.

### frequency_v2_q0183

QUESTION ID
frequency_v2_q0183

QUESTION TEXT
Sen ağlayarak veya çok sinirli bir şekilde bir derdini anlatırken, partnerin sürekli "Şöyle yapmalısın, şurayı ara" diye çözümler sunuyor.

ALL FOUR OPTION TEXTS
A: Bana akıl vermesi değil, sadece "çok haklısın, ne kadar üzücü" demesi gerektiği için sinirlenirim.
B: Onun beni önemseme şeklinin bu olduğunu anlar, verdiği tavsiyeleri mantık süzgecinden geçiririm.
C: "Lütfen sadece beni dinle" diyerek konuşmanın kurallarını net bir şekilde çizerim.
D: Onu susturmam, çözüm önerilerini hevesle dinleyip, haklı bulduklarımı uygulamaya başlarım.

WHY NO SINGLE PRIMARY FITS
Feel-versus-fix can be isolated as boundary_firmness (listen-only line) if the stem is rewritten that way.

RECOMMEND:
REWRITE

IMPROVED STEM (options not rewritten yet)
Derdini anlatırken partnerin sürekli çözüm öneriyor. “Sadece dinle” diye kural mı koyarsın, yoksa tavsiyeyi kabul mü edersin?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: (none)
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no
Do not assign a dominant primary from option-weight mass. Do not keep dual primary_dimensions as a workaround.

### frequency_v2_q0191

QUESTION ID
frequency_v2_q0191

QUESTION TEXT
İlişkiniz günlük rutine oturduğunda, bağı sürdürmek sana en doğal olarak nasıl gelir?

ALL FOUR OPTION TEXTS
A: Gün içinde birkaç kez açıkça "yanındayım / iyi ki varsın" der, sözel yakınlığı sürdürürüm.
B: Konuşmasak da yan yana vakit geçiririm; sessiz ortaklık bana yeter.
C: Gündüz herkes kendi işine bakar; akşam ortak zamanda buluşuruz.
D: Ortak takvimi ve para planını net tutarım; neyin ne zaman olacağını bilmek isterim.

WHY NO SINGLE PRIMARY FITS
Phase 1C rewrite still maps to four 12Ds. Isolate one maintenance axis (reassurance or closeness_pace). Do not keep four flavors as multi-primary.

RECOMMEND:
REWRITE

IMPROVED STEM (options not rewritten yet)
İlişki rutine bindiğinde bağı sürdürmek sana en doğal nasıl gelir: gün içinde açık sözel teyit mi, yoksa konuşmasanız da yan yana vakit mi?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: (none)
stored primary_dimensions count: 1 (reassurance_need)
collapse dual stored primary to one dominant: no
Do not assign a dominant primary from option-weight mass. Do not keep dual primary_dimensions as a workaround.

### frequency_v2_q0192

QUESTION ID
frequency_v2_q0192

QUESTION TEXT
Partnerin hiç beklemediğin bir anda, çok küçük bir sebepten dolayı sinirleri bozulup ağlamaya başladı.

ALL FOUR OPTION TEXTS
A: Hemen sarılır, onunla beraber duyguya girer, sakinleşene kadar fiziksel temas kurarım.
B: Sakin ve şefkatli kalır, "Buna bu kadar üzülmenin asıl sebebi ne?" diye sorarak kök sorunu anlamaya çalışırım.
C: Ağlama krizlerinde ne yapacağımı pek bilemem, paniklerim ve biraz mesafeli dururum.
D: Onu yalnız bırakır, rahatça ağlaması ve toparlanması için ona mahremiyet tanırım.

WHY NO SINGLE PRIMARY FITS
Soothing style. Isolate autonomy versus closeness/contact.

RECOMMEND:
REWRITE

IMPROVED STEM (options not rewritten yet)
Partnerin küçük bir sebeple ağlamaya başladı. Yanına yaklaşıp temas mı edersin, yoksa ağlaması için alan mı bırakırsın?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: (none)
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no
Do not assign a dominant primary from option-weight mass. Do not keep dual primary_dimensions as a workaround.

### frequency_v2_q0252

QUESTION ID
frequency_v2_q0252

QUESTION TEXT
Partnerin evdeyken senin için manevi değeri çok yüksek olan bir eşyayı (örn: eski bir vazo/kupa) yanlışlıkla kırdı.

ALL FOUR OPTION TEXTS
A: O anki refleksimle sinirlendiğimi belli ederim ama sonrasında toparlayıp affederim.
B: Çok üzülsem de onun kendini kötü hissetmemesi için "hiç önemli değil, canın sağ olsun" der konuyu tamamen kapatırım.
C: Neden dikkat etmediğini sorgular, içsel bir kızgınlık yaşar ama tartışmamak için sessiz kalırım.
D: Mantıklı bir şekilde "Olan oldu" der, sadece parçaları hızlıca temizlemeye odaklanırım.

WHY NO SINGLE PRIMARY FITS
Accident affect (broken sentimental object) is not a 12D selector contrast.

RECOMMEND:
DROP_FROM_SELECTABLE_POOL

DESIRED ARCHITECTURE
primary_dimension: none (drop from selectable pool)
secondary_dimensions: (none)
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no
May remain in the 426 archive; selector eligibility should not depend on an invented primary.

### frequency_v2_q0266

QUESTION ID
frequency_v2_q0266

QUESTION TEXT
Partnerin, o gün yapması gereken ve senin için de önemli olan basit bir evrak işini unuttu.

ALL FOUR OPTION TEXTS
A: Hayal kırıklığı yaşarım ve onun bu sorumsuzluğunu ciddi bir konuşmaya çeviririm.
B: Kızsam da "Tamam ben hallederim" diyerek işi ondan alır ve hızla kendim çözerim.
C: "Canın sağ olsun, yarın yaparsın" der geçerim, bu tür şeyleri büyütmem.
D: Kendisini kötü hissetmesin diye "Olur öyle, çok yoğundun zaten" diyerek onu teselli ederim.

WHY NO SINGLE PRIMARY FITS
Lecture/take-over/shrug/console is unreliability-affect. Can be isolated as boundary_firmness if rewritten; current structure_preference does not fit.

RECOMMEND:
REWRITE

IMPROVED STEM (options not rewritten yet)
Partnerin senin için önemli bir evrak işini unuttu. Bunu bir sınır ihlali gibi mi adlandırırsın, yoksa bir kez olur deyip geçer misin?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: (none)
stored primary_dimensions count: 1 (structure_preference)
collapse dual stored primary to one dominant: no
Do not assign a dominant primary from option-weight mass. Do not keep dual primary_dimensions as a workaround.

### frequency_v2_q0271

QUESTION ID
frequency_v2_q0271

QUESTION TEXT
Tatilde kiraladığınız otel odası fotoğraflardaki gibi çıkmadı, berbat durumda. Partnerin çok sinirlendi.

ALL FOUR OPTION TEXTS
A: Onun sinirine hak verir, ben de onunla birlikte otel yönetimine veya duruma öfkelenirim.
B: Onu sakinleştirip "Çözüm bulalım, başka otellere bakalım" diyerek anında kriz yöneticisi olurum.
C: "Bunda da bir hayır vardır, odayı sadece uyumak için kullanacağız" diyerek durumu önemsizleştiririm.
D: O sinirliyken uzak durur, sinirinin yatışmasını bekler, bu sırada kendi alternatiflerimi sessizce araştırırım.

WHY NO SINGLE PRIMARY FITS
Crisis/affect mix. Isolate adaptability versus matching their anger.

RECOMMEND:
REWRITE

IMPROVED STEM (options not rewritten yet)
Otel odası berbat çıktı ve partnerin sinirlendi. Sen durumu yeni bir plana mı çevirirsin, yoksa kendi ritminde bekleyip sönmesini mi beklersin?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: (none)
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no
Do not assign a dominant primary from option-weight mass. Do not keep dual primary_dimensions as a workaround.

### frequency_v2_q0287

QUESTION ID
frequency_v2_q0287

QUESTION TEXT
İkiniz de çok ilgili olduğunuz tarihi/siyasi bir konuda farklı uçlardasınız. Tartışma hararetlendi.

ALL FOUR OPTION TEXTS
A: Bu kadar zıt olduğumuz bir konuda tartışmayı hemen keserim, ilişkinin huzurunu fikirlere tercih ederim.
B: Saygı çerçevesinde kalarak, argümanlarımı makale ve kanıtlarla sunar, onu ikna etmeye çalışırım.
C: Onun düşüncelerini çok sert ve saçma bulursam, açıkça eleştirir ve geri adım atmam.
D: "Söylediklerin de bir bakış açısı tabii" diyerek entelektüel merakla onu deşerim ama kendi fikrimi savunmam.

WHY NO SINGLE PRIMARY FITS
Argument style. Isolate boundary_firmness versus repair/closure, not “debate skill.”

RECOMMEND:
REWRITE

IMPROVED STEM (options not rewritten yet)
Tarihi/siyasi bir konuda zıttınız ve tartışma hararetlendi. Fikrinde sınır gibi durur musun, yoksa ilişki huzuru için konuyu keser misin?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: (none)
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no
Do not assign a dominant primary from option-weight mass. Do not keep dual primary_dimensions as a workaround.

### frequency_v2_q0292

QUESTION ID
frequency_v2_q0292

QUESTION TEXT
Partnerin elindeki kahveyi tamamen senin yeni bilgisayarının veya çok sevdiğin bir kıyafetinin üstüne döktü.

ALL FOUR OPTION TEXTS
A: O anki refleksle bağırır, kızar, durumun yarattığı stresi tüm vücudumla dışa vururum.
B: Hiçbir duygu belirtisi göstermeden sadece bezi kapıp temizlemeye ve hasar tespiti yapmaya odaklanırım.
C: O çok panik olduysa, bilgisayardan çok onu sakinleştirmeye odaklanır, "Önemli değil" derim.
D: Moralim çok bozulsa da, bilerek yapmadığı için kendimi sıkar, içime atar ve sessizleşirim.

WHY NO SINGLE PRIMARY FITS
Spilled-coffee startle affect is not relational 12D.

RECOMMEND:
DROP_FROM_SELECTABLE_POOL

DESIRED ARCHITECTURE
primary_dimension: none (drop from selectable pool)
secondary_dimensions: (none)
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no
May remain in the 426 archive; selector eligibility should not depend on an invented primary.

### frequency_v2_q0301

QUESTION ID
frequency_v2_q0301

QUESTION TEXT
Partneriniz kötü bir gün geçirdiğini söylüyor ama detay vermiyor.

ALL FOUR OPTION TEXTS
A: “Anlatmak ister misin?” diye sorarım.
B: Yanında sessizce kalırım.
C: Kendi işime devam ederim, hazır olunca konuşur.
D: Pratik bir şeyler öneririm (yemek, yürüyüş vb.).

WHY NO SINGLE PRIMARY FITS
Not couple-rupture repair. Isolate uncertainty_tolerance or autonomy.

RECOMMEND:
REWRITE

IMPROVED STEM (options not rewritten yet)
Partnerin kötü bir gün geçirdiğini söylüyor ama detay vermiyor. Üstüne gidip anlatmasını mı istersin, yoksa anlatana kadar alan mı bırakırsın?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: (none)
stored primary_dimensions count: 2 (repair_style, contact_need)
collapse dual stored primary to one dominant: no
Do not assign a dominant primary from option-weight mass. Do not keep dual primary_dimensions as a workaround.

### frequency_v2_q0321

QUESTION ID
frequency_v2_q0321

QUESTION TEXT
Partneriniz sizin bir alışkanlığınızı (geç yatma, dağınık bırakma, sesli düşünme) sevimli bulduğunu söyledi. Siz o alışkanlığınızdan rahatsızsınız.

ALL FOUR OPTION TEXTS
A: Değiştirmeye çalışırım.
B: Olduğu gibi kabul ederim.
C: “Bence sorun” diye belirtirim.
D: Konuyu kapatırım.

WHY NO SINGLE PRIMARY FITS
Cute-versus-disliked habit. Isolate boundary_firmness; do not keep autonomy+boundary as two primaries.

RECOMMEND:
REWRITE

IMPROVED STEM (options not rewritten yet)
Partnerin rahatsız olduğun bir alışkanlığını sevimli buluyor. Bu alışkanlığı kendi sınırın gibi mi korursun, yoksa onun okumasına göre mi değiştirirsin?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: (none)
stored primary_dimensions count: 2 (autonomy, boundary_firmness)
collapse dual stored primary to one dominant: no
Do not assign a dominant primary from option-weight mass. Do not keep dual primary_dimensions as a workaround.

### frequency_v2_q0361

QUESTION ID
frequency_v2_q0361

QUESTION TEXT
Partnerin ani bir kararla işten çıkarıldı. Çok moralsiz ve ne yapacağını bilmiyor.

ALL FOUR OPTION TEXTS
A: İlk günlerde ona sadece duygusal bir sığınak olur, konuyu hiç açmadan onu şımartırım.
B: Hemen CV'sini güncellemesi için yardım teklif eder, ona iş ilanları atmaya başlarım.
C: Panik yapmam, bütçemizin bizi ne kadar idare edeceğini hesaplar, rasyonel bir yol haritası çizerim.
D: Onun bu belirsizlik halinden ben de çok etkilenir, kendi kaygılarımı gizlemekte zorlanırım.

WHY NO SINGLE PRIMARY FITS
Job-loss support is not reassurance_need as defined (bond-OK check). Isolate one caretaking vs planning axis only if it can be mapped cleanly; otherwise later drop.

RECOMMEND:
REWRITE

IMPROVED STEM (options not rewritten yet)
Partnerin işten çıkarıldı ve moralsiz. Yanında kalarak bağın yerinde olduğunu mu hissettirirsin, yoksa pratik plan mı kurarsın?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: (none)
stored primary_dimensions count: 1 (reassurance_need)
collapse dual stored primary to one dominant: no
Do not assign a dominant primary from option-weight mass. Do not keep dual primary_dimensions as a workaround.

### frequency_v2_q0380

QUESTION ID
frequency_v2_q0380

QUESTION TEXT
Bir partidesiniz ve partnerin içkiyi fazla kaçırdı, saçmalamaya ve dengesini kaybetmeye başladı.

ALL FOUR OPTION TEXTS
A: Hemen müdahale eder, koluna girer ve kimseye belli etmeden onu hızla eve götürürüm.
B: Çok utanırım ve ona kızarım. Onu köşeye çekip kendine gelmesi için sertçe uyarırım.
C: Eğlenmesine bakarım, ben de ona katılır geceyi onun gibi sarhoş ve çılgın geçiririm.
D: Onu bir arkadaşına emanet eder veya oturtur, ben partideki diğer insanlarla takılmaya devam ederim.

WHY NO SINGLE PRIMARY FITS
Drunk, unsteady partner mixes caretaking, shame, matching chaos, and staying social. Not one 12D; do not invent a primary from leftover weights.

RECOMMEND:
DROP_FROM_SELECTABLE_POOL

DESIRED ARCHITECTURE
primary_dimension: none (drop from selectable pool)
secondary_dimensions: (none)
stored primary_dimensions count: 0 (empty)
collapse dual stored primary to one dominant: no
May remain in the 426 archive; selector eligibility should not depend on an invented primary.

### frequency_v2_q0391

QUESTION ID
frequency_v2_q0391

QUESTION TEXT
Birlikte bir kafede otururken, senin eski sevgilinin çok yakın bir arkadaşı masanıza gelip selam verdi.

ALL FOUR OPTION TEXTS
A: Gerilirim, sadece "Merhaba" derim ve o gidene kadar partnerimle göz temasından kaçınırım.
B: Rahatça sohbet eder, hatta partnerimi de o kişiyle "İşte yeni erkek/kız arkadaşım" diye tanıştırırım.
C: Karşımdakine çok soğuk davranarak masadan bir an önce gitmesi için beden dilimi kullanırım.
D: Ortamın gerilmemesi için sadece partnerime odaklanır, gelen kişiye kısa cevaplar veririm.

WHY NO SINGLE PRIMARY FITS
Ex-adjacent awkwardness is not social_energy. Isolate reassurance_need.

RECOMMEND:
REWRITE

IMPROVED STEM (options not rewritten yet)
Eski sevgilinin yakını masanıza geldi. Bu sende bağın tehdit edildiği hissi uyandırır mı, yoksa nötr bir tesadüf mü kalır?

DESIRED ARCHITECTURE
primary_dimension: pending_rewrite
secondary_dimensions: (none)
stored primary_dimensions count: 1 (social_energy)
collapse dual stored primary to one dominant: no
Do not assign a dominant primary from option-weight mass. Do not keep dual primary_dimensions as a workaround.

### frequency_v2_q0405

QUESTION ID
frequency_v2_q0405

QUESTION TEXT
Partneriniz sizinle ilgili bir komplementi (dış görünüş, zekâ, karakter) abartılı bulduğunuz şekilde yapıyor.

ALL FOUR OPTION TEXTS
A: Teşekkür ederim, geçerim.
B: “Biraz abarttın” derim.
C: Ben de ona benzer bir şey söylerim.
D: Konuyu değiştiririm.

WHY NO SINGLE PRIMARY FITS
Receiving an over-the-top compliment is not a 12D primary. Dual stored disclosure+boundary is option-weight residue, not a designed dual axis.

RECOMMEND:
DROP_FROM_SELECTABLE_POOL

DESIRED ARCHITECTURE
primary_dimension: none (drop from selectable pool)
secondary_dimensions: (none)
stored primary_dimensions count: 2 (boundary_firmness, disclosure_pace)
collapse dual stored primary to one dominant: no
May remain in the 426 archive; selector eligibility should not depend on an invented primary.

## Counts

CHANGE = 47
AMBIGUOUS = 21
WEAK_ITEM = 30
TOTAL HUMAN REVIEW = 98

- proposed single-primary count: **63** (all 47 CHANGE + 16 AMBIGUOUS→A + 0 AMBIGUOUS→B)
- proposed multi-primary-required count: **0** (KEEP MULTI-PRIMARY / KEEP_AS_MULTI_PRIMARY unused; mixed items go to rewrite instead of dual primary_dimensions)
- proposed rewrite count: **27** (AMBIGUOUS REWRITE 5 + WEAK REWRITE 22)
- proposed drop count: **8**

AMBIGUOUS recommendation split: A 16, REWRITE 5
WEAK recommendation split: DROP_FROM_SELECTABLE_POOL 8, REWRITE 22

## Dual stored `primary_dimensions` (2 IDs) where this packet still recommends one dominant primary

Count: **8**

- `frequency_v2_q0064`: stored `initiative + repair_style` → proposed single primary `repair_style`
- `frequency_v2_q0076`: stored `contact_need + closeness_pace` → proposed single primary `closeness_pace`
- `frequency_v2_q0228`: stored `contact_need + adaptability` → proposed single primary `adaptability`
- `frequency_v2_q0317`: stored `autonomy + reassurance_need` → proposed single primary `repair_style`
- `frequency_v2_q0333`: stored `contact_need + adaptability` → proposed single primary `adaptability`
- `frequency_v2_q0409`: stored `autonomy + reassurance_need` → proposed single primary `repair_style`
- `frequency_v2_q0426`: stored `contact_need + adaptability` → proposed single primary `adaptability`
- `frequency_v2_q0065`: stored `boundary_firmness + adaptability` → proposed single primary `adaptability`

WEAK items that currently store two IDs but are **not** proposed as one-dominant (rewrite/drop instead):

- `frequency_v2_q0094`: stored `repair_style + adaptability` → REWRITE
- `frequency_v2_q0099`: stored `initiative + autonomy` → REWRITE
- `frequency_v2_q0301`: stored `repair_style + contact_need` → REWRITE
- `frequency_v2_q0321`: stored `autonomy + boundary_firmness` → REWRITE
- `frequency_v2_q0405`: stored `boundary_firmness + disclosure_pace` → DROP_FROM_SELECTABLE_POOL

AMBIGUOUS items that currently store two IDs and are sent to **REWRITE** rather than one dominant:

- `frequency_v2_q0406`: stored `boundary_firmness + disclosure_pace` → REWRITE

## Safety

- V2 JSON not modified
- Weights not modified
- Question text not modified (rewrite stems are proposals only)
- Evidence metadata not assigned
- V2 not activated; V1 / Firebase / live routing untouched
- No commit/push

FREQUENCY V2 PHASE 1E PRIMARY HUMAN DECISION PACKET READY — NO DATA MODIFIED
