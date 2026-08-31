# Frequency V2 Phase 1D — Primary semantic review

Status: **proposal only**. This file does not modify the V2 pool, option text, option weights, evidence metadata, Frequency V1, pubspec, live routing, Firebase, Discover, Persona, matching, `canonical_v1`, or C2.

Authority question: *What is the central behavioral contrast this QUESTION is designed to reveal?*

Primaries were **not** derived from absolute weight mass, option-count, largest numeric weight, or “keep the old label because it exists.”

Allowed primaries only: `contact_need`, `closeness_pace`, `initiative`, `autonomy`, `reassurance_need`, `uncertainty_tolerance`, `disclosure_pace`, `boundary_firmness`, `repair_style`, `social_energy`, `structure_preference`, `adaptability`.

`repair_style` is a bipolar repair-engagement direction, not a moral or health score.

## Method

- Reviewed all **426** stems and four option texts each.
- **KEEP**: existing canonical primary is semantically strong.
- **CHANGE**: another canonical primary is clearly more representative.
- **AMBIGUOUS**: two dimensions are genuinely central; human review required.
- **WEAK_ITEM**: the question does not cleanly measure any single 12D primary (later rewrite/drop).
- Empty Phase 1C primaries cannot be KEEP.
- Secondary option flavors do not automatically become primary.
- `frequency_v2_q0037` is reviewed explicitly below; its existing `boundary_firmness` is not assumed correct.
- Pool storage: **273** items have one `primary_dimensions` entry, **124** have two, **29** are empty. This review proposes **exactly one** recommended primary. Dual listing is not automatically AMBIGUOUS; it is usually primary+secondary stuffed into the same field. Dual-listed CHANGE rows below show the full current list.

## Explicit review: `frequency_v2_q0037`

### frequency_v2_q0037

QUESTION ID
frequency_v2_q0037

QUESTION TEXT
Gece uyumak üzeresin, çok yorgunsun. Partnerin aniden ilişkinizle ilgili derin ve ciddi bir konuyu açtı.

CURRENT PRIMARY:
boundary_firmness

RECOMMENDED PRIMARY:
boundary_firmness

SECONDARY CANDIDATE:
uncertainty_tolerance

CLASSIFICATION:
AMBIGUOUS

REASON:
You are exhausted and they open a deep topic now. A cannot sleep until it is resolved; B postpones and names a sleep limit; C yields without real engagement; D protects sleep while cushioning them. Holding the tiredness line and needing closure-now are both designed, so the existing boundary_firmness label is not uniquely correct.

CONFIDENCE:
medium

The stem is a timing/energy limit (sleep versus a sudden deep talk). Option A is written as cannot-leave-unresolved, which is closure/repair engagement. Option B is an explicit postpone-limit. Because both axes are designed, this is **AMBIGUOUS**, not an automatic KEEP.

## CHANGE

### frequency_v2_q0009

QUESTION ID
frequency_v2_q0009

QUESTION TEXT
Henüz 3-4 haftadır görüştüğün kişi, seni en yakın arkadaş grubuyla bir akşam yemeğine davet etti. Yaklaşımın ne olur?

CURRENT PRIMARY:
disclosure_pace

RECOMMENDED PRIMARY:
closeness_pace

SECONDARY CANDIDATE:
boundary_firmness

CLASSIFICATION:
CHANGE

REASON:
Meeting their closest friends at week 3–4 is tempo of life-merging, not how quickly inner states are told. A accelerates; B calls it too early.

CONFIDENCE:
high

### frequency_v2_q0015

QUESTION ID
frequency_v2_q0015

QUESTION TEXT
Stresli bir anında partnerine gereksiz yere sert çıkıştın. 10 dakika sonra durumu fark ettin.

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
repair_style

SECONDARY CANDIDATE:
none

CLASSIFICATION:
CHANGE

REASON:
After you snapped, options are immediate emotional apology, a constructive talk, a light ice-break, or pause-then-return. That is re-engagement after rupture.

CONFIDENCE:
high

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0020

QUESTION ID
frequency_v2_q0020

QUESTION TEXT
Partnerin bir şeye bariz şekilde canı sıkkın ama sana "bir şey yok, iyiyim" diyor.

CURRENT PRIMARY:
boundary_firmness

RECOMMENDED PRIMARY:
uncertainty_tolerance

SECONDARY CANDIDATE:
autonomy

CLASSIFICATION:
CHANGE

REASON:
They say they are fine while clearly upset. You are not holding your own limit; you decide whether to resolve unexplained coldness now or leave it unknown.

CONFIDENCE:
medium

### frequency_v2_q0027

QUESTION ID
frequency_v2_q0027

QUESTION TEXT
Acil çözmen gereken zor bir problemin var, ama partnerin o gün çok kritik bir iş toplantısında.

CURRENT PRIMARY:
reassurance_need

RECOMMENDED PRIMARY:
autonomy

SECONDARY CANDIDATE:
contact_need

CLASSIFICATION:
CHANGE

REASON:
Handle a crisis alone versus pulling a partner who is in a meeting. That is self-direction versus drawing them in, not a bond-OK check.

CONFIDENCE:
medium

### frequency_v2_q0028

QUESTION ID
frequency_v2_q0028

QUESTION TEXT
Çok yakın arkadaş grubun, yeni partnerinle enerjilerinin uyuşmadığını hissettirdi.

CURRENT PRIMARY:
social_energy

RECOMMENDED PRIMARY:
boundary_firmness

SECONDARY CANDIDATE:
autonomy

CLASSIFICATION:
CHANGE

REASON:
Friends dislike the partner: re-evaluate, split worlds, blend them, or defend the couple line. Existing social_energy does not match. Holding versus yielding the couple boundary is the stronger axis.

CONFIDENCE:
high

### frequency_v2_q0038

QUESTION ID
frequency_v2_q0038

QUESTION TEXT
Sen çok düzenlisin, partnerin ise daha "dağınık" bir düzene sahip. Nasıl ilerlersiniz?

CURRENT PRIMARY:
structure_preference

RECOMMENDED PRIMARY:
adaptability

SECONDARY CANDIDATE:
autonomy

CLASSIFICATION:
CHANGE

REASON:
Tidy-versus-messy living is impose-my-way, relax standards, split territories, or meet in the middle. Household order is not plans/schedules; it is adjust versus keep your rhythm.

CONFIDENCE:
medium

### frequency_v2_q0039

QUESTION ID
frequency_v2_q0039

QUESTION TEXT
İlişkiniz tamamen rayına oturdu, her gününüzün nasıl geçeceği belli, sıfır sürpriz var. Nasıl hissedersin?

CURRENT PRIMARY:
uncertainty_tolerance

RECOMMENDED PRIMARY:
structure_preference

SECONDARY CANDIDATE:
none

CLASSIFICATION:
CHANGE

REASON:
Zero-surprise settled days are comfort with predictable routine versus hunger for unplanned novelty. That is not comfort with unresolved ambiguity.

CONFIDENCE:
high

### frequency_v2_q0064

QUESTION ID
frequency_v2_q0064

QUESTION TEXT
Tartışma sonrası sessizlik oluştu.

CURRENT PRIMARY:
initiative + repair_style

RECOMMENDED PRIMARY:
repair_style

SECONDARY CANDIDATE:
initiative

CLASSIFICATION:
CHANGE

REASON:
Post-argument silence is immediate re-entry, wait for them, a light “shall we talk,” or days in your own space. How repair is re-engaged is the contrast; who speaks first is secondary.

CONFIDENCE:
high

### frequency_v2_q0071

QUESTION ID
frequency_v2_q0071

QUESTION TEXT
İlk birkaç mesajlaşma sonrası karşı taraf “sen nasılsın, günün nasıl geçti” tarzı sorular sormuyor.

CURRENT PRIMARY:
contact_need

RECOMMENDED PRIMARY:
reassurance_need

SECONDARY CANDIDATE:
contact_need

CLASSIFICATION:
CHANGE

REASON:
Missing “how are you / how was your day” is whether you need that care-check, not raw message count. Contact style is only the vehicle.

CONFIDENCE:
medium

### frequency_v2_q0076

QUESTION ID
frequency_v2_q0076

QUESTION TEXT
Uzun bir ayrılıktan (iş seyahati, aile) sonra yeniden bir araya geliyorsunuz.

CURRENT PRIMARY:
contact_need + closeness_pace

RECOMMENDED PRIMARY:
closeness_pace

SECONDARY CANDIDATE:
autonomy

CLASSIFICATION:
CHANGE

REASON:
Post-absence reunion contrasts immediate intense togetherness versus slow re-entry versus first returning to one’s own routine. Intimacy tempo, not ordinary message-frequency.

CONFIDENCE:
high

### frequency_v2_q0134

QUESTION ID
frequency_v2_q0134

QUESTION TEXT
Bu kez daha sık iletişim isteyen taraf sensin; partnerin daha seyrek temas ediyor.

CURRENT PRIMARY:
reassurance_need

RECOMMENDED PRIMARY:
contact_need

SECONDARY CANDIDATE:
initiative

CLASSIFICATION:
CHANGE

REASON:
You want more contact than they give: require a daily rhythm, fill your own life, initiate more, or reduce investment. Contact appetite under mismatch, not a bond-OK check.

CONFIDENCE:
high

### frequency_v2_q0156

QUESTION ID
frequency_v2_q0156

QUESTION TEXT
İlişkinizin 6. ayındasınız. Partnerin seni aniden, çok sevdiği ailesiyle bir akşam yemeğine davet etti.

CURRENT PRIMARY:
disclosure_pace

RECOMMENDED PRIMARY:
closeness_pace

SECONDARY CANDIDATE:
disclosure_pace

CLASSIFICATION:
CHANGE

REASON:
A month-6 family dinner is welcomed as deepening, felt as too early, attended quietly, or socially steered. Ready-versus-too-soon for a family milestone is closeness tempo.

CONFIDENCE:
high

### frequency_v2_q0166

QUESTION ID
frequency_v2_q0166

QUESTION TEXT
Arabada uzun yoldasınız ve bir konu yüzünden sesler yükseldi, kavga çıktı. İdeal çözüm yöntemin nedir?

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
repair_style

SECONDARY CANDIDATE:
none

CLASSIFICATION:
CHANGE

REASON:
A car fight contrasts talk-until-resolved, an hour of silence, close-it-by-yielding, and keep arguing. That is immediate repair versus pause versus withdraw versus stay in the fight.

CONFIDENCE:
high

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0186

QUESTION ID
frequency_v2_q0186

QUESTION TEXT
Büyük bir kavgada bağırdın, çağırdın. Ancak 10 dakika sonra aslında tamamen *senin haksız olduğunu* fark ettin.

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
repair_style

SECONDARY CANDIDATE:
none

CLASSIFICATION:
CHANGE

REASON:
After you yelled and then saw you were wrong: wait for it to be forgotten, apologize at once, soften with acts, or apologize while also putting their fault on the table. Withdrawn versus immediate versus mild versus mixed repair.

CONFIDENCE:
high

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0228

QUESTION ID
frequency_v2_q0228

QUESTION TEXT
Yeni biriyle mesajlaşırken o çok uzun ve detaylı yazıyor, siz daha kısa yazmayı seviyorsunuz.

CURRENT PRIMARY:
contact_need + adaptability

RECOMMENDED PRIMARY:
adaptability

SECONDARY CANDIDATE:
disclosure_pace

CLASSIFICATION:
CHANGE

REASON:
The split is long/detailed messages versus short ones, not frequent versus sparse contact. Matching their style versus keeping yours is adjust versus own rhythm.

CONFIDENCE:
medium

### frequency_v2_q0254

QUESTION ID
frequency_v2_q0254

QUESTION TEXT
Sen çok hastasın, ateşin var ve yatakta yatıyorsun. Partnerinden beklentin nedir?

CURRENT PRIMARY:
reassurance_need

RECOMMENDED PRIMARY:
contact_need

SECONDARY CANDIDATE:
closeness_pace

CLASSIFICATION:
CHANGE

REASON:
Sick-day options are constant presence, drop-and-leave, nearby availability, or not asking for help. Wanted availability/proximity, not a check that the bond is OK.

CONFIDENCE:
medium

### frequency_v2_q0255

QUESTION ID
frequency_v2_q0255

QUESTION TEXT
Çok heves ettiğiniz bir etkinliğe (örn: konser/tiyatro) giderken berbat bir trafiğe yakalandınız ve yetişemeyeceğiniz kesinleşti.

CURRENT PRIMARY:
uncertainty_tolerance

RECOMMENDED PRIMARY:
adaptability

SECONDARY CANDIDATE:
none

CLASSIFICATION:
CHANGE

REASON:
Missing the event is already certain. Meltdown versus inventing a new plan versus following them versus going quiet is adjusting to a spoiled situation, not unresolved ambiguity.

CONFIDENCE:
medium

### frequency_v2_q0258

QUESTION ID
frequency_v2_q0258

QUESTION TEXT
Çok severek okuduğun derin bir kitabı/makaleyi partnerinle paylaştın ama o "Çok sıkıcıymış" deyip kestirip attı.

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
autonomy

SECONDARY CANDIDATE:
closeness_pace

CLASSIFICATION:
CHANGE

REASON:
They dismiss a book you love. Accepting separate taste, pushing them to get it, cooling off, or switching to common ground is independent inner world versus needing a shared one.

CONFIDENCE:
medium

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0261

QUESTION ID
frequency_v2_q0261

QUESTION TEXT
İkiniz arasında ufak bir yanlış anlaşılma oldu. Partnerin olayı sana uzun uzun, detaylıca ve kendini sürekli savunarak açıklamaya çalışıyor.

CURRENT PRIMARY:
disclosure_pace

RECOMMENDED PRIMARY:
repair_style

SECONDARY CANDIDATE:
disclosure_pace

CLASSIFICATION:
CHANGE

REASON:
After a small misunderstanding they narrate at length. Cutting it off, staying in the listen, matching with your own account, or moving on is how you stay in or leave the repair talk.

CONFIDENCE:
medium

### frequency_v2_q0264

QUESTION ID
frequency_v2_q0264

QUESTION TEXT
Kendi hayatınla ilgili çok kötü bir haber aldın. Partnerine bu haberi nasıl verirsin?

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
disclosure_pace

SECONDARY CANDIDATE:
autonomy

CLASSIFICATION:
CHANGE

REASON:
How you deliver bad personal news: immediate raw call, process first then report the outcome, soften it, or wait for them to read your face. Openness/speed of inner-life sharing is the designed contrast.

CONFIDENCE:
high

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0272

QUESTION ID
frequency_v2_q0272

QUESTION TEXT
Bir sohbet esnasında partnerin, içinde hiçbir romantik duygu barındırmayan ama eski sevgilisinin de olduğu nötr bir anıyı anlattı (örn: "Eski sevgilimle o filme gitmiştik").

CURRENT PRIMARY:
uncertainty_tolerance

RECOMMENDED PRIMARY:
reassurance_need

SECONDARY CANDIDATE:
boundary_firmness

CLASSIFICATION:
CHANGE

REASON:
A casual ex-in-the-story mention: stay easy, quietly cool, ban ex names, or treat it as honesty. The engine is whether that mention threatens the bond, not open ambiguity.

CONFIDENCE:
medium

### frequency_v2_q0275

QUESTION ID
frequency_v2_q0275

QUESTION TEXT
Partnerin kendi alanında çok büyük ve bireysel bir başarı elde etti.

CURRENT PRIMARY:
closeness_pace

RECOMMENDED PRIMARY:
autonomy

SECONDARY CANDIDATE:
closeness_pace

CLASSIFICATION:
CHANGE

REASON:
Their individual win: claim it as “we did it,” congratulate and leave it theirs, throw a big celebration, or follow their preferred toast. We-merge versus honoring a separate achievement.

CONFIDENCE:
medium

### frequency_v2_q0281

QUESTION ID
frequency_v2_q0281

QUESTION TEXT
Kalabalık bir ortamda, arkadaşlarınızın veya ailenin yanında fiziksel temas (sarılma, öpme) konusunda ne düşünürsün?

CURRENT PRIMARY:
disclosure_pace

RECOMMENDED PRIMARY:
closeness_pace

SECONDARY CANDIDATE:
disclosure_pace

CLASSIFICATION:
CHANGE

REASON:
Public hug/kiss comfort versus hands-only, private-only affection, or matching only if they start is visible intimacy, not how fast you narrate inner states.

CONFIDENCE:
high

### frequency_v2_q0282

QUESTION ID
frequency_v2_q0282

QUESTION TEXT
Partnerinin lüks sayılabilecek bir harcaması oldu (örn: pahalı bir çanta/saat), sen ise birikim yapmayı seven birisin.

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
autonomy

SECONDARY CANDIDATE:
adaptability

CLASSIFICATION:
CHANGE

REASON:
Their luxury buy versus your saver style: their money is theirs, you ruminate about future clash, you needle it, or you attune. Independent financial space versus being pulled into their spend.

CONFIDENCE:
medium

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0284

QUESTION ID
frequency_v2_q0284

QUESTION TEXT
Partnerin aniden saçını çok farklı (ve senin hiç beğenmediğin) bir renge boyattı/kestirdi.

CURRENT PRIMARY:
boundary_firmness

RECOMMENDED PRIMARY:
disclosure_pace

SECONDARY CANDIDATE:
autonomy

CLASSIFICATION:
CHANGE

REASON:
The haircut already happened; there is no request to refuse. Fake praise, honest dislike, neutral support, or silent self-reminder is shown versus hidden reaction.

CONFIDENCE:
medium

### frequency_v2_q0288

QUESTION ID
frequency_v2_q0288

QUESTION TEXT
Partnerin genel olarak çok kararsız biri. Nereye gidileceğini, ne yeneceğini sana bırakıyor.

CURRENT PRIMARY:
structure_preference

RECOMMENDED PRIMARY:
initiative

SECONDARY CANDIDATE:
none

CLASSIFICATION:
CHANGE

REASON:
The stem is their indecisiveness leaving choices to you. Enjoying deciding, tiring of the load, neither deciding, or prompting them to choose is who starts versus who waits.

CONFIDENCE:
high

### frequency_v2_q0290

QUESTION ID
frequency_v2_q0290

QUESTION TEXT
Partnerin çok hasta ama inatla "Doktora gitmeyeceğim, bana bir şey olmaz" diyip işe gitmeye çalışıyor.

CURRENT PRIMARY:
boundary_firmness

RECOMMENDED PRIMARY:
autonomy

SECONDARY CANDIDATE:
closeness_pace

CLASSIFICATION:
CHANGE

REASON:
Override their health choice versus treat them as a self-directed adult. Clinging via all-day monitoring is closeness, not holding your own limit.

CONFIDENCE:
medium

### frequency_v2_q0294

QUESTION ID
frequency_v2_q0294

QUESTION TEXT
Uyurken senin tarafın hep sıcak, partnerinin tarafı hep serin olsun istiyor. Yataktaki denge nasıl sağlanır?

CURRENT PRIMARY:
boundary_firmness

RECOMMENDED PRIMARY:
autonomy

SECONDARY CANDIDATE:
closeness_pace

CLASSIFICATION:
CHANGE

REASON:
Separate duvets versus enduring one blanket to cuddle is independent sleep space versus merging, clearer than saying no versus yielding a verbal limit.

CONFIDENCE:
medium

### frequency_v2_q0298

QUESTION ID
frequency_v2_q0298

QUESTION TEXT
Aylardır planladığınız açık hava pikniği/festivali, sabah aniden bastıran şiddetli bir yağmurla tamamen iptal oldu.

CURRENT PRIMARY:
uncertainty_tolerance

RECOMMENDED PRIMARY:
adaptability

SECONDARY CANDIDATE:
structure_preference

CLASSIFICATION:
CHANGE

REASON:
The picnic is already cancelled, not left ambiguous. Ruminate versus invent a home festival versus switch to a home day is adjustment to a changed situation.

CONFIDENCE:
high

### frequency_v2_q0317

QUESTION ID
frequency_v2_q0317

QUESTION TEXT
Bir tartışma sonrası partneriniz “biraz düşünmem lazım” deyip ortamdan ayrıldı.

CURRENT PRIMARY:
autonomy + reassurance_need

RECOMMENDED PRIMARY:
repair_style

SECONDARY CANDIDATE:
autonomy

CLASSIFICATION:
CHANGE

REASON:
After a fight they leave to think: grant space, ask how long, send a ping, or withdraw too. Pause-then-return versus reach-out versus shutdown, not everyday solo space.

CONFIDENCE:
medium

### frequency_v2_q0333

QUESTION ID
frequency_v2_q0333

QUESTION TEXT
Yeni biriyle mesajlaşırken o çok uzun yazıyor, siz daha kısa ve öz yazmayı seviyorsunuz.

CURRENT PRIMARY:
contact_need + adaptability

RECOMMENDED PRIMARY:
adaptability

SECONDARY CANDIDATE:
contact_need

CLASSIFICATION:
CHANGE

REASON:
The stem is long messages versus short, not frequent versus sparse. Match their length, keep your style, or name the mismatch is style adjustment.

CONFIDENCE:
medium

### frequency_v2_q0346

QUESTION ID
frequency_v2_q0346

QUESTION TEXT
Yabancı bir şehre tatile gittiniz. Partnerin navigasyon görevini üstlendi ama sizi tamamen yanlış bir yere götürüp kaybettirdi.

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
adaptability

SECONDARY CANDIDATE:
initiative

CLASSIFICATION:
CHANGE

REASON:
Already lost by their navigation: blame and take over, reframe as adventure, quietly steer, or pause then solve. Adjusting to the mishap versus forcing the path back is the stem.

CONFIDENCE:
medium

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0348

QUESTION ID
frequency_v2_q0348

QUESTION TEXT
Birlikte yaşadığınız dönemde, partnerin sana hiç danışmadan kendi birikiminden yakın bir arkadaşına yüklü bir borç verdi.

CURRENT PRIMARY:
boundary_firmness

RECOMMENDED PRIMARY:
autonomy

SECONDARY CANDIDATE:
boundary_firmness

CLASSIFICATION:
CHANGE

REASON:
A large loan from their savings with no consult. Their money their call versus hurt that a shared life was bypassed. Independent purse versus merged decision space.

CONFIDENCE:
medium

### frequency_v2_q0352

QUESTION ID
frequency_v2_q0352

QUESTION TEXT
Netflix/Spotify gibi ortak kullanılabilecek platformlarda kendi profillerinizi/şifrelerinizi birleştirmek sence nasıl bir fikirdir?

CURRENT PRIMARY:
closeness_pace

RECOMMENDED PRIMARY:
autonomy

SECONDARY CANDIDATE:
closeness_pace

CLASSIFICATION:
CHANGE

REASON:
Shared streaming logins: one merged profile versus keep your algorithm private. Independent digital space versus merging, not tempo of togetherness.

CONFIDENCE:
medium

### frequency_v2_q0353

QUESTION ID
frequency_v2_q0353

QUESTION TEXT
Baş başa yemek yerken partnerinin telefonu masada ve ekranı yukarı bakıyor. Sürekli bildirimler yanıp sönüyor.

CURRENT PRIMARY:
contact_need

RECOMMENDED PRIMARY:
closeness_pace

SECONDARY CANDIDATE:
contact_need

CLASSIFICATION:
CHANGE

REASON:
Phone face-up through a one-to-one dinner splits present togetherness, not message frequency. Protect the shared meal versus tolerate divided attention.

CONFIDENCE:
high

### frequency_v2_q0358

QUESTION ID
frequency_v2_q0358

QUESTION TEXT
Partnerin sosyal medyada çok tartışmalı ve senin hiç katılmadığın, hatta rahatsız olduğun bir politik/sosyal görüş paylaştı.

CURRENT PRIMARY:
boundary_firmness

RECOMMENDED PRIMARY:
autonomy

SECONDARY CANDIDATE:
none

CLASSIFICATION:
CHANGE

REASON:
Nobody is holding or yielding a personal limit. The contrast is intervening in their public stance versus treating their digital identity as theirs.

CONFIDENCE:
medium

### frequency_v2_q0360

QUESTION ID
frequency_v2_q0360

QUESTION TEXT
Sadece kahve içmek için buluşacaktınız ama partnerin elinde büyük ve anlamlı bir hediye ile geldi. (Özel bir gün değil)

CURRENT PRIMARY:
uncertainty_tolerance

RECOMMENDED PRIMARY:
closeness_pace

SECONDARY CANDIDATE:
adaptability

CLASSIFICATION:
CHANGE

REASON:
An unplanned meaningful gift is not unresolved ambiguity. Welcoming the sudden intimacy versus holding distance is closeness intensification versus keeping the casual frame.

CONFIDENCE:
medium

### frequency_v2_q0370

QUESTION ID
frequency_v2_q0370

QUESTION TEXT
Gece yarısı partnerinin telefonuna kayıtlı olmayan bir numaradan sadece "Uyudun mu?" mesajı geldi.

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
uncertainty_tolerance

SECONDARY CANDIDATE:
reassurance_need

CLASSIFICATION:
CHANGE

REASON:
An unknown midnight “are you asleep?” text is an ambiguous signal. Demand an explanation, assume a wrong number, watch and wait, or covertly investigate. Need-to-resolve versus leave-it is the contrast.

CONFIDENCE:
high

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0372

QUESTION ID
frequency_v2_q0372

QUESTION TEXT
Partnerinin arkadaş grubunda, dedikoducu ve sürekli kriz yaratan toksik bir kişi var. Grup buluşmalarında ne yaparsın?

CURRENT PRIMARY:
social_energy

RECOMMENDED PRIMARY:
boundary_firmness

SECONDARY CANDIDATE:
social_energy

CLASSIFICATION:
CHANGE

REASON:
The stem is a toxic group member, not general party energy. Refuse to attend, ice them, politely yield, or join the drama. Holding versus yielding a limit around that person.

CONFIDENCE:
high

### frequency_v2_q0373

QUESTION ID
frequency_v2_q0373

QUESTION TEXT
Beraber çok dramatik bir film izlerken partnerin hıçkırarak ağlamaya başladı.

CURRENT PRIMARY:
reassurance_need

RECOMMENDED PRIMARY:
adaptability

SECONDARY CANDIDATE:
none

CLASSIFICATION:
CHANGE

REASON:
Partner sobbing at a film is not a bond-check. Matching their emotion, giving space, defusing, or staying in your cooler register is adjusting to their state versus keeping your rhythm.

CONFIDENCE:
medium

### frequency_v2_q0375

QUESTION ID
frequency_v2_q0375

QUESTION TEXT
Partnerin sana "Birlikte bir kafe/girişim açalım, hem beraber çalışır hem kazanırız" fikriyle geldi.

CURRENT PRIMARY:
initiative

RECOMMENDED PRIMARY:
autonomy

SECONDARY CANDIDATE:
structure_preference

CLASSIFICATION:
CHANGE

REASON:
They already proposed the cafe. The contrast is fusing work and the relationship versus keeping domains separate. Initiative is not the question.

CONFIDENCE:
medium

### frequency_v2_q0382

QUESTION ID
frequency_v2_q0382

QUESTION TEXT
Kış ortasında evin kombisi bozuldu ve aniden çok yüklü (bir maaş kadar) bir tamir masrafı çıktı.

CURRENT PRIMARY:
structure_preference

RECOMMENDED PRIMARY:
initiative

SECONDARY CANDIDATE:
none

CLASSIFICATION:
CHANGE

REASON:
A sudden boiler bill is not plans-versus-loose-routine. You take charge and fix it, ruminate, leave the solution to them, or delay. Who acts versus who waits.

CONFIDENCE:
medium

### frequency_v2_q0383

QUESTION ID
frequency_v2_q0383

QUESTION TEXT
Sen çok gerçekçi, bazen karamsar birisin. Partnerin ise her felakette "Evrene iyi mesaj yollayalım, her şey harika olacak" diyen biri.

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
adaptability

SECONDARY CANDIDATE:
autonomy

CLASSIFICATION:
CHANGE

REASON:
Pessimist versus “send good energy”: absorb their frame, keep your own worst-case plans, try to pull them to gravity, or take comfort from their hope. Adjusting to their worldview versus staying in your rhythm.

CONFIDENCE:
high

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0390

QUESTION ID
frequency_v2_q0390

QUESTION TEXT
Sokakta yürürken veya kafedeyken ilişkinizle ilgili çok gergin bir tartışma alevlendi.

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
repair_style

SECONDARY CANDIDATE:
social_energy

CLASSIFICATION:
CHANGE

REASON:
A fight ignites in public: continue now (loud or whispered), cut it and return at home, or fold immediately. Resolve-now versus pause-then-return versus withdraw is repair_style. Setting is secondary.

CONFIDENCE:
high

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0393

QUESTION ID
frequency_v2_q0393

QUESTION TEXT
Şık giyindiniz, yürüyerek bir davete gidiyorsunuz. Birden sağanak yağmur bastırdı ve şemsiye yok.

CURRENT PRIMARY:
uncertainty_tolerance

RECOMMENDED PRIMARY:
adaptability

SECONDARY CANDIDATE:
structure_preference

CLASSIFICATION:
CHANGE

REASON:
A downpour is a broken plan, not an unresolved ambiguity. Meltdown versus enjoying the rain versus instant solve versus going home is adjusting to the situation.

CONFIDENCE:
high

### frequency_v2_q0409

QUESTION ID
frequency_v2_q0409

QUESTION TEXT
Bir tartışma sonrası partneriniz “biraz yalnız kalmam lazım” dedi ve odasına çekildi.

CURRENT PRIMARY:
autonomy + reassurance_need

RECOMMENDED PRIMARY:
repair_style

SECONDARY CANDIDATE:
autonomy

CLASSIFICATION:
CHANGE

REASON:
This is after a fight, and they have already withdrawn. Grant the pause, ask how long, knock with “I am here,” or withdraw too. Post-rupture re-engagement pacing.

CONFIDENCE:
high

### frequency_v2_q0426

QUESTION ID
frequency_v2_q0426

QUESTION TEXT
Yeni biriyle mesajlaşırken o çok uzun yazıyor, siz daha kısa yazmayı seviyorsunuz.

CURRENT PRIMARY:
contact_need + adaptability

RECOMMENDED PRIMARY:
adaptability

SECONDARY CANDIDATE:
contact_need

CLASSIFICATION:
CHANGE

REASON:
The stem is long messages versus short ones, not how often you are available. Matching their length versus keeping your style is style adjustment.

CONFIDENCE:
medium

## AMBIGUOUS

### frequency_v2_q0005

QUESTION ID
frequency_v2_q0005

QUESTION TEXT
Birlikte izlediğiniz bir filmdeki ahlaki bir ikilem üzerine tamamen zıt görüşlere sahipsiniz. Tartışma uzadı, ne yaparsın?

CURRENT PRIMARY:
boundary_firmness

RECOMMENDED PRIMARY:
uncertainty_tolerance

SECONDARY CANDIDATE:
boundary_firmness

CLASSIFICATION:
AMBIGUOUS

REASON:
A film-opinion clash: keep working the disagreement versus let the difference stand versus joke-close versus validate their feeling. Need-for-closure and hold-versus-yield are both central; a movie debate is not clearly a personal limit.

CONFIDENCE:
medium

### frequency_v2_q0011

QUESTION ID
frequency_v2_q0011

QUESTION TEXT
Akşam şık bir restorana gitmek üzere hazırlandın ama partnerin son dakika arayıp "Çok yorgunum, evde film ve pizza yapsak uyar mı?" dedi.

CURRENT PRIMARY:
structure_preference

RECOMMENDED PRIMARY:
adaptability

SECONDARY CANDIDATE:
structure_preference

CLASSIFICATION:
AMBIGUOUS

REASON:
A last-minute scrap of a set restaurant plan is both plan-loyalty and adjusting to their tiredness. Neither dimension is only decorative.

CONFIDENCE:
medium

### frequency_v2_q0021

QUESTION ID
frequency_v2_q0021

QUESTION TEXT
İnanılmaz yoğun ve insanlarla sürekli konuştuğun bir haftayı geride bıraktın. Deşarj olmak için neye ihtiyacın var?

CURRENT PRIMARY:
autonomy

RECOMMENDED PRIMARY:
social_energy

SECONDARY CANDIDATE:
autonomy

CLASSIFICATION:
AMBIGUOUS

REASON:
Recharge after a people-heavy week is social-battery (out versus quiet). A also excludes the partner, so solo space versus together-quiet is equally central.

CONFIDENCE:
medium

### frequency_v2_q0026

QUESTION ID
frequency_v2_q0026

QUESTION TEXT
Temel bir inanç veya hayata bakış açısı konusunda partnerinle tamamen zıt olduğunuzu fark ettiniz.

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
uncertainty_tolerance

SECONDARY CANDIDATE:
adaptability

CLASSIFICATION:
AMBIGUOUS

REASON:
Working hours toward common ground versus living with separate worldviews is closure-versus-live-with-it. Checking whether you can attune is equally adaptability.

CONFIDENCE:
medium

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0030

QUESTION ID
frequency_v2_q0030

QUESTION TEXT
Partnerinin geçmişiyle ilgili zarar verici olmayan ama senin yeni öğrendiğin önemli bir detayı (örn: eski mesleği) gizlediğini fark ettin.

CURRENT PRIMARY:
disclosure_pace

RECOMMENDED PRIMARY:
disclosure_pace

SECONDARY CANDIDATE:
uncertainty_tolerance

CLASSIFICATION:
AMBIGUOUS

REASON:
They hid a non-harmful past detail. Demanding why versus accepting tell-when-ready is both expected openness tempo and need to resolve concealment.

CONFIDENCE:
medium

### frequency_v2_q0033

QUESTION ID
frequency_v2_q0033

QUESTION TEXT
Bir ilişkide "Seni seviyorum" demek veya derin duyguları itiraf etmek sence nasıl bir süreçtir?

CURRENT PRIMARY:
closeness_pace

RECOMMENDED PRIMARY:
closeness_pace

SECONDARY CANDIDATE:
disclosure_pace

CLASSIFICATION:
AMBIGUOUS

REASON:
First-feeling “I love you” versus waiting for trust is intimacy tempo and how fast an inner feeling is spoken. Both are genuinely central.

CONFIDENCE:
medium

### frequency_v2_q0035

QUESTION ID
frequency_v2_q0035

QUESTION TEXT
Hayatında her şeyin üst üste geldiği, inanılmaz stresli bir dönemdesin. İlişkine nasıl yansır?

CURRENT PRIMARY:
contact_need

RECOMMENDED PRIMARY:
disclosure_pace

SECONDARY CANDIDATE:
contact_need

CLASSIFICATION:
AMBIGUOUS

REASON:
Under stacked stress, A talks and leans; B goes quiet and distant. Sharing inner load and changing contact are both in the stem.

CONFIDENCE:
medium

### frequency_v2_q0037

QUESTION ID
frequency_v2_q0037

QUESTION TEXT
Gece uyumak üzeresin, çok yorgunsun. Partnerin aniden ilişkinizle ilgili derin ve ciddi bir konuyu açtı.

CURRENT PRIMARY:
boundary_firmness

RECOMMENDED PRIMARY:
boundary_firmness

SECONDARY CANDIDATE:
uncertainty_tolerance

CLASSIFICATION:
AMBIGUOUS

REASON:
You are exhausted and they open a deep topic now. A cannot sleep until it is resolved; B postpones and names a sleep limit; C yields without real engagement; D protects sleep while cushioning them. Holding the tiredness line and needing closure-now are both designed, so the existing boundary_firmness label is not uniquely correct.

CONFIDENCE:
medium

### frequency_v2_q0065

QUESTION ID
frequency_v2_q0065

QUESTION TEXT
Partnerin seninle ilgili bir sınırını (zaman, konu, davranış) ilk kez net ifade etti.

CURRENT PRIMARY:
boundary_firmness + adaptability

RECOMMENDED PRIMARY:
adaptability

SECONDARY CANDIDATE:
boundary_firmness

CLASSIFICATION:
AMBIGUOUS

REASON:
They stated a limit about you. Adjusting/respecting it versus answering with your own limits are both central.

CONFIDENCE:
medium

### frequency_v2_q0130

QUESTION ID
frequency_v2_q0130

QUESTION TEXT
Önemli bir konuda hayata bakışınızın belirgin biçimde farklı olduğunu fark ettiniz.

CURRENT PRIMARY:
boundary_firmness

RECOMMENDED PRIMARY:
uncertainty_tolerance

SECONDARY CANDIDATE:
autonomy

CLASSIFICATION:
AMBIGUOUS

REASON:
A serious outlook gap is not someone crossing a personal limit. Working the difference through versus leaving separate views uncentered; both uncertainty_tolerance and autonomy are central.

CONFIDENCE:
medium

### frequency_v2_q0139

QUESTION ID
frequency_v2_q0139

QUESTION TEXT
İlişkinin ilk ayında partnerin sana beklediğinden çok daha pahalı bir hediye aldı.

CURRENT PRIMARY:
boundary_firmness

RECOMMENDED PRIMARY:
closeness_pace

SECONDARY CANDIDATE:
boundary_firmness

CLASSIFICATION:
AMBIGUOUS

REASON:
A too-expensive first-month gift is both too-fast romantic investment and a possible limit on gesture scale. Both are genuinely in the options.

CONFIDENCE:
medium

### frequency_v2_q0163

QUESTION ID
frequency_v2_q0163

QUESTION TEXT
Sen iş yerinde berbat ve stresli bir gün geçirdin, partnerin ise harika haberler aldığı enerjik bir gün geçirdi. Akşam buluştunuz.

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
adaptability

SECONDARY CANDIDATE:
disclosure_pace

CLASSIFICATION:
AMBIGUOUS

REASON:
A mismatched-energy evening is hide-and-match them versus unload your bad day versus name both versus leave early. Energy-matching and whether you share the hard day are both central.

CONFIDENCE:
medium

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0274

QUESTION ID
frequency_v2_q0274

QUESTION TEXT
Birlikte kanepede otururken yarım saattir ikiniz de hiç konuşmadınız. Sen ne yaparsın?

CURRENT PRIMARY:
closeness_pace

RECOMMENDED PRIMARY:
contact_need

SECONDARY CANDIDATE:
closeness_pace

CLASSIFICATION:
AMBIGUOUS

REASON:
Thirty minutes of couch silence: check if something is wrong, stay quietly together, drift to your phone, or get up. Needed talk versus comfortable quiet togetherness are both central.

CONFIDENCE:
medium

### frequency_v2_q0286

QUESTION ID
frequency_v2_q0286

QUESTION TEXT
Partnerin seni en yakın (tek) arkadaşıyla tanıştırdı. Gece boyu kendi aralarındaki iç şakaları konuşup güldüler.

CURRENT PRIMARY:
social_energy

RECOMMENDED PRIMARY:
reassurance_need

SECONDARY CANDIDATE:
social_energy

CLASSIFICATION:
AMBIGUOUS

REASON:
Insider-joke exclusion probes whether the couple bond still feels secure. Join-the-circle versus phone-check is also social energy, so both are central.

CONFIDENCE:
medium

### frequency_v2_q0295

QUESTION ID
frequency_v2_q0295

QUESTION TEXT
Günün stresiyle sessizce ağlamaya başladın. Partnerin odaya girdi. Sen ne yaparsın?

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
disclosure_pace

SECONDARY CANDIDATE:
autonomy

CLASSIFICATION:
AMBIGUOUS

REASON:
Crying when they walk in: reach for comfort, send them out, tell it immediately, or deflect. Sharing the inner state, seeking contact, and holding space are all written in; disclosure is the strongest but not unique.

CONFIDENCE:
medium

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0356

QUESTION ID
frequency_v2_q0356

QUESTION TEXT
1 haftalık deniz tatilinizin daha 2. gününde sen çok fena güneş geçmesi/gıda zehirlenmesi yaşadın ve odadasın.

CURRENT PRIMARY:
adaptability

RECOMMENDED PRIMARY:
autonomy

SECONDARY CANDIDATE:
adaptability

CLASSIFICATION:
AMBIGUOUS

REASON:
Releasing the partner to their own vacation versus pulling them into the room versus periodic check-ins is space-versus-merge as much as adjusting to a disrupted trip.

CONFIDENCE:
medium

### frequency_v2_q0363

QUESTION ID
frequency_v2_q0363

QUESTION TEXT
Baş başa bir mekanda otururken partnerin o an orada tesadüfen karşılaştığı ve senin hiç tanımadığın bir arkadaşını masanıza davet etti.

CURRENT PRIMARY:
boundary_firmness

RECOMMENDED PRIMARY:
boundary_firmness

SECONDARY CANDIDATE:
social_energy

CLASSIFICATION:
AMBIGUOUS

REASON:
Drawing a line around couple time versus accepting an invited stranger is boundary_firmness, but loving new people versus protecting a private date is equally social_energy.

CONFIDENCE:
medium

### frequency_v2_q0365

QUESTION ID
frequency_v2_q0365

QUESTION TEXT
İlişkiniz için çok önemli bir tarihi (yıldönümü) partnerin tamamen unuttu ve o güne normal bir gün gibi devam ediyor.

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
reassurance_need

SECONDARY CANDIDATE:
structure_preference

CLASSIFICATION:
AMBIGUOUS

REASON:
A forgotten anniversary can be “did you show the bond still matters” (wait-and-hurt versus confront) or “do calendar rituals matter” (meaningless versus I honor the date). Neither dimension owns it alone.

CONFIDENCE:
medium

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0377

QUESTION ID
frequency_v2_q0377

QUESTION TEXT
Çok lüks bir restoranda yemeğinizi yediniz, hesap geldi ve partnerin cüzdanını/kartını evde unuttuğunu fark etti.

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
adaptability

SECONDARY CANDIDATE:
structure_preference

CLASSIFICATION:
AMBIGUOUS

REASON:
A forgotten wallet pits rolling with the night versus sticking to the original split versus resenting the slip. Adapt-to-the-mishap and hold-the-fairness-plan are both central.

CONFIDENCE:
medium

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0392

QUESTION ID
frequency_v2_q0392

QUESTION TEXT
Partnerin "Artık diyeti ve sporu bırakıyorum, hayatı yaşayacağım" diyerek aylar süren disiplinini bir günde çöpe attı.

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
autonomy

SECONDARY CANDIDATE:
adaptability

CLASSIFICATION:
AMBIGUOUS

REASON:
Dumping a long diet/sport regime is their body and self-direction versus you pushing them back versus you joining the pizza. Autonomy and adaptability are both written into the options.

CONFIDENCE:
medium

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0406

QUESTION ID
frequency_v2_q0406

QUESTION TEXT
Birlikte bir akşam evdesiniz. Partneriniz derin bir konu açmak istiyor, siz o akşam hafif vakit geçirmek istiyorsunuz.

CURRENT PRIMARY:
boundary_firmness + disclosure_pace

RECOMMENDED PRIMARY:
disclosure_pace

SECONDARY CANDIDATE:
boundary_firmness

CLASSIFICATION:
AMBIGUOUS

REASON:
They want a deep talk; you wanted a light night. Disclosure depth tonight and saying no to their bid are both genuinely central.

CONFIDENCE:
medium

## WEAK_ITEM

### frequency_v2_q0003

QUESTION ID
frequency_v2_q0003

QUESTION TEXT
Partnerin işten çok gergin ve morali bozuk döndü. Olayı anlatıyor. Senin ilk refleksin ne olur?

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
none

CLASSIFICATION:
WEAK_ITEM

REASON:
First reflex to a distressed partner splits solve / validate / give space / distract. That is support-mode, not one 12D contrast.

CONFIDENCE:
high

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0008

QUESTION ID
frequency_v2_q0008

QUESTION TEXT
Partnerin, senin bir davranış tarzını oldukça net ve yapıcı bir şekilde eleştirdi. İlk tepkin genelde nasıl şekillenir?

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
none

CLASSIFICATION:
WEAK_ITEM

REASON:
Reaction to constructive criticism splits silent processing, immediate emotion, yielding, and self-defense. Those sit on disclosure, adaptability, and boundary at once.

CONFIDENCE:
high

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0018

QUESTION ID
frequency_v2_q0018

QUESTION TEXT
Beklenmedik büyük bir ortak masraf (örn: aracın bozulması, evin bir masrafı) çıktı.

CURRENT PRIMARY:
uncertainty_tolerance

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
reassurance_need

CLASSIFICATION:
WEAK_ITEM

REASON:
A sudden shared bill mixes analytical solving, needing “we’ll handle it,” going with the flow, and soothing them. Crisis coping is not a clean ambiguity item.

CONFIDENCE:
medium

### frequency_v2_q0023

QUESTION ID
frequency_v2_q0023

QUESTION TEXT
Sevdiğini ve değer verdiğini genelde en net nasıl belli edersin?

CURRENT PRIMARY:
closeness_pace

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
none

CLASSIFICATION:
WEAK_ITEM

REASON:
Words, practical help, touch, or granting freedom are expression channels, not tempo of getting close. No single 12D is the designed contrast.

CONFIDENCE:
high

### frequency_v2_q0029

QUESTION ID
frequency_v2_q0029

QUESTION TEXT
Partnerin basit bir unutkanlık yaptı (örn: senin için önemli bir evrakı almayı unuttu) ve bu sana zaman kaybettirdi.

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
none

CLASSIFICATION:
WEAK_ITEM

REASON:
A forgotten errand mixes flash-anger-then-forgive, swallow-and-fix, install a system, and shrug. Irritation handling is not a clean repair, boundary, or adaptability item.

CONFIDENCE:
high

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0043

QUESTION ID
frequency_v2_q0043

QUESTION TEXT
Partnerin kariyeriyle ilgili çok riskli ve zor bir karar aşamasında ve sana danıştı.

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
none

CLASSIFICATION:
WEAK_ITEM

REASON:
Advice stance on their career risk (analyze, mirror, blanket support, push your view) is counseling style, not a single 12D axis.

CONFIDENCE:
high

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0047

QUESTION ID
frequency_v2_q0047

QUESTION TEXT
Evde birlikte önemli bir işi yetiştirirken bilgisayar/internet aniden kilitlendi ve veriler kayboldu.

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
none

CLASSIFICATION:
WEAK_ITEM

REASON:
A crashed computer draws panic, stone-cold plan B, soothe-the-partner, or laugh-it-off. Shared technical loss is not relational repair or one 12D primary.

CONFIDENCE:
high

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0070

QUESTION ID
frequency_v2_q0070

QUESTION TEXT
Karşı taraf duygusal olarak yoğun bir dönemden geçiyor ve bunu seninle paylaşıyor.

CURRENT PRIMARY:
repair_style

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
none

CLASSIFICATION:
WEAK_ITEM

REASON:
They are sharing a hard period; there is no rupture between you. Listen, advise, self-disclose, or step back is support style. repair_style does not apply.

CONFIDENCE:
high

### frequency_v2_q0094

QUESTION ID
frequency_v2_q0094

QUESTION TEXT
Birlikte bir karar vermeniz gerekiyor (taşınma, büyük harcama, aile meselesi).

CURRENT PRIMARY:
repair_style + adaptability

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
none

CLASSIFICATION:
WEAK_ITEM

REASON:
A joint life decision with no rupture contrasts long talk, a plus-minus list, defending your pick, or yielding. Decision process is not repair and does not map to one 12D.

CONFIDENCE:
high

### frequency_v2_q0099

QUESTION ID
frequency_v2_q0099

QUESTION TEXT
İlişki bir süredir “idare ediyor” ama heyecan azalmış gibi.

CURRENT PRIMARY:
initiative + autonomy

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
none

CLASSIFICATION:
WEAK_ITEM

REASON:
A flattened “getting by” relationship scatters into talking it through, accepting, enriching your own life, or stepping back. Different strategies, not a single who-starts contrast.

CONFIDENCE:
medium

### frequency_v2_q0113

QUESTION ID
frequency_v2_q0113

QUESTION TEXT
Partnerin “Bir saate birkaç arkadaş bize geliyor” dedi. Bundan daha önce haberin yoktu.

CURRENT PRIMARY:
boundary_firmness

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
none

CLASSIFICATION:
WEAK_ITEM

REASON:
Unannounced friends in an hour splits enjoying guests, naming a notice rule, making your own plan, or going along. Social energy, boundary, autonomy, and adaptability are all central.

CONFIDENCE:
medium

### frequency_v2_q0127

QUESTION ID
frequency_v2_q0127

QUESTION TEXT
Partnerin kötü geçen bir iş gününü anlatıyor ve belirgin biçimde zorlanmış görünüyor.

CURRENT PRIMARY:
repair_style

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
none

CLASSIFICATION:
WEAK_ITEM

REASON:
They recount a hard workday: listen, problem-solve, ask which they want, or distract. Support after their stress, not how you re-engage a couple rupture.

CONFIDENCE:
high

### frequency_v2_q0128

QUESTION ID
frequency_v2_q0128

QUESTION TEXT
Partnerin kariyeriyle ilgili riskli bir karar için fikrini sordu.

CURRENT PRIMARY:
initiative

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
none

CLASSIFICATION:
WEAK_ITEM

REASON:
They already asked your view on a career risk: analyze, explore feelings, defer, or recommend. Advice stance is not who starts or plans.

CONFIDENCE:
high

### frequency_v2_q0135

QUESTION ID
frequency_v2_q0135

QUESTION TEXT
Değer verdiğini en doğal hangi biçimde gösterirsin?

CURRENT PRIMARY:
closeness_pace

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
none

CLASSIFICATION:
WEAK_ITEM

REASON:
How you show you value them splits words, practical help, physical time, or giving space. Expression channels, not fast-versus-slow closeness tempo.

CONFIDENCE:
high

### frequency_v2_q0153

QUESTION ID
frequency_v2_q0153

QUESTION TEXT
Yeni tanıştığınız dönemde, mesajlaşmak yerine aniden, habersizce seni telefonla aradı.

CURRENT PRIMARY:
contact_need

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
contact_need

CLASSIFICATION:
WEAK_ITEM

REASON:
A surprise call versus text is channel and interruption preference, not frequent-versus-sparse contact.

CONFIDENCE:
medium

### frequency_v2_q0180

QUESTION ID
frequency_v2_q0180

QUESTION TEXT
İkinizi de etkileyen ortak bir maddi kayıp (örn: yanlış bir yatırım veya yüksek bir trafik cezası) yaşandı.

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
structure_preference

CLASSIFICATION:
WEAK_ITEM

REASON:
A shared money loss mixes math-planning, rumination-for-comfort, shrug, and hiding your stress to soothe them. Coping is not one primary.

CONFIDENCE:
medium

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0183

QUESTION ID
frequency_v2_q0183

QUESTION TEXT
Sen ağlayarak veya çok sinirli bir şekilde bir derdini anlatırken, partnerin sürekli "Şöyle yapmalısın, şurayı ara" diye çözümler sunuyor.

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
boundary_firmness

CLASSIFICATION:
WEAK_ITEM

REASON:
Wanting empathy versus accepting advice versus setting a listen-only rule is support-mode preference, not a clean 12D construct. The listen-rule is only a boundary flavor.

CONFIDENCE:
medium

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0191

QUESTION ID
frequency_v2_q0191

QUESTION TEXT
İlişkiniz günlük rutine oturduğunda, bağı sürdürmek sana en doğal olarak nasıl gelir?

CURRENT PRIMARY:
reassurance_need

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
reassurance_need

CLASSIFICATION:
WEAK_ITEM

REASON:
Bond-maintenance in routine is daily verbal affirmation, silent side-by-side time, daytime apart and evening together, or a clear calendar/money plan. Those map to four different 12Ds.

CONFIDENCE:
medium

### frequency_v2_q0192

QUESTION ID
frequency_v2_q0192

QUESTION TEXT
Partnerin hiç beklemediğin bir anda, çok küçük bir sebepten dolayı sinirleri bozulup ağlamaya başladı.

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
closeness_pace

CLASSIFICATION:
WEAK_ITEM

REASON:
Sudden tears over a small trigger are met with merged hugging, root-cause questions, panicked distance, or privacy to cry. Soothing style is not a single 12D primary.

CONFIDENCE:
medium

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0252

QUESTION ID
frequency_v2_q0252

QUESTION TEXT
Partnerin evdeyken senin için manevi değeri çok yüksek olan bir eşyayı (örn: eski bir vazo/kupa) yanlışlıkla kırdı.

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
none

CLASSIFICATION:
WEAK_ITEM

REASON:
They break a sentimental object: flash anger then forgive, people-please close, silent stew, or practical cleanup. Accident affect is not one 12D axis.

CONFIDENCE:
high

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0266

QUESTION ID
frequency_v2_q0266

QUESTION TEXT
Partnerin, o gün yapması gereken ve senin için de önemli olan basit bir evrak işini unuttu.

CURRENT PRIMARY:
structure_preference

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
boundary_firmness

CLASSIFICATION:
WEAK_ITEM

REASON:
A forgotten paperwork task mixes a lecture about irresponsibility, taking it over, shrugging, and consoling them. Reaction to unreliability is not plans-versus-loose structure.

CONFIDENCE:
medium

### frequency_v2_q0271

QUESTION ID
frequency_v2_q0271

QUESTION TEXT
Tatilde kiraladığınız otel odası fotoğraflardaki gibi çıkmadı, berbat durumda. Partnerin çok sinirlendi.

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
adaptability

CLASSIFICATION:
WEAK_ITEM

REASON:
A ruined hotel plus their anger mixes joining the rage, instant crisis-managing, minimizing, and waiting it out. Crisis/affect style, not one 12D primary.

CONFIDENCE:
medium

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0287

QUESTION ID
frequency_v2_q0287

QUESTION TEXT
İkiniz de çok ilgili olduğunuz tarihi/siyasi bir konuda farklı uçlardasınız. Tartışma hararetlendi.

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
boundary_firmness

CLASSIFICATION:
WEAK_ITEM

REASON:
A heated political debate mixes cutting it for peace, persuading with evidence, harsh holding of views, and curiosity without advocacy. Argument style is not one clean 12D primary.

CONFIDENCE:
medium

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0292

QUESTION ID
frequency_v2_q0292

QUESTION TEXT
Partnerin elindeki kahveyi tamamen senin yeni bilgisayarının veya çok sevdiğin bir kıyafetinin üstüne döktü.

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
none

CLASSIFICATION:
WEAK_ITEM

REASON:
Spilled coffee on a valued object: yell, stone-faced cleanup, soothe them, or swallow it. Emotional reactivity after an accident, not a single 12D contrast.

CONFIDENCE:
high

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0301

QUESTION ID
frequency_v2_q0301

QUESTION TEXT
Partneriniz kötü bir gün geçirdiğini söylüyor ama detay vermiyor.

CURRENT PRIMARY:
repair_style + contact_need

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
autonomy

CLASSIFICATION:
WEAK_ITEM

REASON:
A bad day with no details is support style (ask, sit, leave them, offer a walk), not couple-rupture repair.

CONFIDENCE:
medium

### frequency_v2_q0321

QUESTION ID
frequency_v2_q0321

QUESTION TEXT
Partneriniz sizin bir alışkanlığınızı (geç yatma, dağınık bırakma, sesli düşünme) sevimli bulduğunu söyledi. Siz o alışkanlığınızdan rahatsızsınız.

CURRENT PRIMARY:
autonomy + boundary_firmness

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
disclosure_pace

CLASSIFICATION:
WEAK_ITEM

REASON:
They find a habit cute that you dislike. Change it, accept it, call it a problem, or drop the topic does not isolate one relationship dimension.

CONFIDENCE:
medium

### frequency_v2_q0361

QUESTION ID
frequency_v2_q0361

QUESTION TEXT
Partnerin ani bir kararla işten çıkarıldı. Çok moralsiz ve ne yapacağını bilmiyor.

CURRENT PRIMARY:
reassurance_need

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
none

CLASSIFICATION:
WEAK_ITEM

REASON:
Support after a job loss (emotional shelter versus fix-it versus budget plan versus catching their anxiety) does not seek confirmation that the bond is OK and does not isolate one 12D.

CONFIDENCE:
medium

### frequency_v2_q0380

QUESTION ID
frequency_v2_q0380

QUESTION TEXT
Bir partidesiniz ve partnerin içkiyi fazla kaçırdı, saçmalamaya ve dengesini kaybetmeye başladı.

CURRENT PRIMARY:
(empty / primary_review_pending)

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
none

CLASSIFICATION:
WEAK_ITEM

REASON:
A drunk, unsteady partner mixes caretaking, public embarrassment, matching the chaos, and leaving them to stay social. Initiative, social_energy, adaptability, and boundary all appear.

CONFIDENCE:
medium

PENDING PRIMARY FLAG: yes (Phase 1C empty primary)

### frequency_v2_q0391

QUESTION ID
frequency_v2_q0391

QUESTION TEXT
Birlikte bir kafede otururken, senin eski sevgilinin çok yakın bir arkadaşı masanıza gelip selam verdi.

CURRENT PRIMARY:
social_energy

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
none

CLASSIFICATION:
WEAK_ITEM

REASON:
An ex’s close friend approaching the table is leftover-relationship awkwardness, not general social-versus-private energy.

CONFIDENCE:
medium

### frequency_v2_q0405

QUESTION ID
frequency_v2_q0405

QUESTION TEXT
Partneriniz sizinle ilgili bir komplementi (dış görünüş, zekâ, karakter) abartılı bulduğunuz şekilde yapıyor.

CURRENT PRIMARY:
boundary_firmness + disclosure_pace

RECOMMENDED PRIMARY:
none

SECONDARY CANDIDATE:
none

CLASSIFICATION:
WEAK_ITEM

REASON:
An over-the-top compliment is not holding a limit. Thanks, “you exaggerated,” reciprocate, or change the subject is compliment-receiving, not a 12D primary.

CONFIDENCE:
high

## KEEP (compact)

Existing primary judged semantically strong. Listed by current/recommended primary. Full stem/option text is in the dormant draft pool; not reprinted here.

### contact_need (17)

frequency_v2_q0010, frequency_v2_q0041, frequency_v2_q0058, frequency_v2_q0077, frequency_v2_q0108, frequency_v2_q0141, frequency_v2_q0142, frequency_v2_q0169, frequency_v2_q0178, frequency_v2_q0187, frequency_v2_q0204, frequency_v2_q0205, frequency_v2_q0259, frequency_v2_q0279, frequency_v2_q0302, frequency_v2_q0386, frequency_v2_q0401

### closeness_pace (33)

frequency_v2_q0042, frequency_v2_q0067, frequency_v2_q0081, frequency_v2_q0100, frequency_v2_q0106, frequency_v2_q0110, frequency_v2_q0138, frequency_v2_q0150, frequency_v2_q0160, frequency_v2_q0181, frequency_v2_q0202, frequency_v2_q0210, frequency_v2_q0213, frequency_v2_q0220, frequency_v2_q0232, frequency_v2_q0236, frequency_v2_q0241, frequency_v2_q0244, frequency_v2_q0248, frequency_v2_q0305, frequency_v2_q0308, frequency_v2_q0316, frequency_v2_q0322, frequency_v2_q0325, frequency_v2_q0339, frequency_v2_q0395, frequency_v2_q0398, frequency_v2_q0402, frequency_v2_q0407, frequency_v2_q0410, frequency_v2_q0416, frequency_v2_q0419, frequency_v2_q0422

### initiative (25)

frequency_v2_q0001, frequency_v2_q0014, frequency_v2_q0040, frequency_v2_q0051, frequency_v2_q0078, frequency_v2_q0079, frequency_v2_q0080, frequency_v2_q0091, frequency_v2_q0095, frequency_v2_q0101, frequency_v2_q0105, frequency_v2_q0154, frequency_v2_q0196, frequency_v2_q0218, frequency_v2_q0226, frequency_v2_q0247, frequency_v2_q0250, frequency_v2_q0312, frequency_v2_q0314, frequency_v2_q0318, frequency_v2_q0326, frequency_v2_q0336, frequency_v2_q0359, frequency_v2_q0411, frequency_v2_q0420

### autonomy (41)

frequency_v2_q0007, frequency_v2_q0012, frequency_v2_q0034, frequency_v2_q0044, frequency_v2_q0072, frequency_v2_q0090, frequency_v2_q0092, frequency_v2_q0107, frequency_v2_q0116, frequency_v2_q0117, frequency_v2_q0119, frequency_v2_q0131, frequency_v2_q0155, frequency_v2_q0161, frequency_v2_q0165, frequency_v2_q0179, frequency_v2_q0184, frequency_v2_q0197, frequency_v2_q0201, frequency_v2_q0207, frequency_v2_q0208, frequency_v2_q0216, frequency_v2_q0219, frequency_v2_q0224, frequency_v2_q0231, frequency_v2_q0253, frequency_v2_q0269, frequency_v2_q0291, frequency_v2_q0297, frequency_v2_q0300, frequency_v2_q0303, frequency_v2_q0304, frequency_v2_q0328, frequency_v2_q0334, frequency_v2_q0345, frequency_v2_q0367, frequency_v2_q0368, frequency_v2_q0369, frequency_v2_q0376, frequency_v2_q0378, frequency_v2_q0379

### reassurance_need (21)

frequency_v2_q0036, frequency_v2_q0049, frequency_v2_q0052, frequency_v2_q0057, frequency_v2_q0068, frequency_v2_q0102, frequency_v2_q0126, frequency_v2_q0132, frequency_v2_q0147, frequency_v2_q0162, frequency_v2_q0167, frequency_v2_q0171, frequency_v2_q0270, frequency_v2_q0283, frequency_v2_q0289, frequency_v2_q0315, frequency_v2_q0343, frequency_v2_q0347, frequency_v2_q0350, frequency_v2_q0387, frequency_v2_q0415

### uncertainty_tolerance (20)

frequency_v2_q0006, frequency_v2_q0025, frequency_v2_q0046, frequency_v2_q0054, frequency_v2_q0063, frequency_v2_q0074, frequency_v2_q0082, frequency_v2_q0087, frequency_v2_q0093, frequency_v2_q0104, frequency_v2_q0109, frequency_v2_q0152, frequency_v2_q0164, frequency_v2_q0173, frequency_v2_q0190, frequency_v2_q0195, frequency_v2_q0267, frequency_v2_q0323, frequency_v2_q0337, frequency_v2_q0404

### disclosure_pace (29)

frequency_v2_q0013, frequency_v2_q0053, frequency_v2_q0060, frequency_v2_q0086, frequency_v2_q0089, frequency_v2_q0103, frequency_v2_q0136, frequency_v2_q0137, frequency_v2_q0157, frequency_v2_q0177, frequency_v2_q0193, frequency_v2_q0199, frequency_v2_q0215, frequency_v2_q0225, frequency_v2_q0230, frequency_v2_q0239, frequency_v2_q0240, frequency_v2_q0256, frequency_v2_q0262, frequency_v2_q0276, frequency_v2_q0293, frequency_v2_q0319, frequency_v2_q0327, frequency_v2_q0330, frequency_v2_q0341, frequency_v2_q0354, frequency_v2_q0385, frequency_v2_q0414, frequency_v2_q0418

### boundary_firmness (43)

frequency_v2_q0016, frequency_v2_q0024, frequency_v2_q0073, frequency_v2_q0084, frequency_v2_q0121, frequency_v2_q0143, frequency_v2_q0158, frequency_v2_q0170, frequency_v2_q0174, frequency_v2_q0185, frequency_v2_q0200, frequency_v2_q0203, frequency_v2_q0206, frequency_v2_q0209, frequency_v2_q0221, frequency_v2_q0222, frequency_v2_q0233, frequency_v2_q0235, frequency_v2_q0238, frequency_v2_q0245, frequency_v2_q0260, frequency_v2_q0263, frequency_v2_q0278, frequency_v2_q0296, frequency_v2_q0311, frequency_v2_q0313, frequency_v2_q0338, frequency_v2_q0340, frequency_v2_q0344, frequency_v2_q0351, frequency_v2_q0364, frequency_v2_q0371, frequency_v2_q0374, frequency_v2_q0381, frequency_v2_q0389, frequency_v2_q0394, frequency_v2_q0396, frequency_v2_q0400, frequency_v2_q0403, frequency_v2_q0408, frequency_v2_q0413, frequency_v2_q0421, frequency_v2_q0424

### repair_style (19)

frequency_v2_q0056, frequency_v2_q0083, frequency_v2_q0088, frequency_v2_q0097, frequency_v2_q0122, frequency_v2_q0123, frequency_v2_q0124, frequency_v2_q0125, frequency_v2_q0129, frequency_v2_q0145, frequency_v2_q0212, frequency_v2_q0229, frequency_v2_q0242, frequency_v2_q0249, frequency_v2_q0306, frequency_v2_q0310, frequency_v2_q0331, frequency_v2_q0399, frequency_v2_q0425

### social_energy (22)

frequency_v2_q0004, frequency_v2_q0017, frequency_v2_q0055, frequency_v2_q0059, frequency_v2_q0066, frequency_v2_q0098, frequency_v2_q0118, frequency_v2_q0175, frequency_v2_q0188, frequency_v2_q0194, frequency_v2_q0214, frequency_v2_q0234, frequency_v2_q0243, frequency_v2_q0257, frequency_v2_q0265, frequency_v2_q0280, frequency_v2_q0299, frequency_v2_q0307, frequency_v2_q0320, frequency_v2_q0397, frequency_v2_q0417, frequency_v2_q0423

### structure_preference (33)

frequency_v2_q0002, frequency_v2_q0019, frequency_v2_q0022, frequency_v2_q0032, frequency_v2_q0045, frequency_v2_q0050, frequency_v2_q0061, frequency_v2_q0069, frequency_v2_q0111, frequency_v2_q0112, frequency_v2_q0114, frequency_v2_q0140, frequency_v2_q0144, frequency_v2_q0146, frequency_v2_q0149, frequency_v2_q0151, frequency_v2_q0159, frequency_v2_q0172, frequency_v2_q0182, frequency_v2_q0189, frequency_v2_q0211, frequency_v2_q0217, frequency_v2_q0251, frequency_v2_q0273, frequency_v2_q0277, frequency_v2_q0285, frequency_v2_q0309, frequency_v2_q0349, frequency_v2_q0355, frequency_v2_q0366, frequency_v2_q0384, frequency_v2_q0388, frequency_v2_q0412

### adaptability (25)

frequency_v2_q0031, frequency_v2_q0048, frequency_v2_q0062, frequency_v2_q0075, frequency_v2_q0085, frequency_v2_q0096, frequency_v2_q0115, frequency_v2_q0120, frequency_v2_q0133, frequency_v2_q0148, frequency_v2_q0168, frequency_v2_q0176, frequency_v2_q0198, frequency_v2_q0223, frequency_v2_q0227, frequency_v2_q0237, frequency_v2_q0246, frequency_v2_q0268, frequency_v2_q0324, frequency_v2_q0329, frequency_v2_q0332, frequency_v2_q0335, frequency_v2_q0342, frequency_v2_q0357, frequency_v2_q0362


## Dual-listed current primaries

124 questions currently store **two** IDs in `primary_dimensions`. This proposal still names one recommended primary. Dual listing is a later apply-phase collapse, not automatic AMBIGUOUS, unless the item is classified AMBIGUOUS on semantic grounds.

## Summary counts

- total reviewed: **426**
- KEEP count: **328**
- CHANGE count: **47**
- AMBIGUOUS count: **21**
- WEAK_ITEM count: **30**
- current pending-primary count: **29**
- pending questions receiving a confident recommendation (CHANGE, confidence high or medium): **10**
  - high only: 7 (`frequency_v2_q0015`, `frequency_v2_q0166`, `frequency_v2_q0186`, `frequency_v2_q0264`, `frequency_v2_q0370`, `frequency_v2_q0383`, `frequency_v2_q0390`)
  - high+medium: `frequency_v2_q0015`, `frequency_v2_q0166`, `frequency_v2_q0186`, `frequency_v2_q0258`, `frequency_v2_q0264`, `frequency_v2_q0282`, `frequency_v2_q0346`, `frequency_v2_q0370`, `frequency_v2_q0383`, `frequency_v2_q0390`

Pending-29 class split: AMBIGUOUS 6, CHANGE 10, WEAK_ITEM 13

## Recommended-primary distribution (KEEP + CHANGE + AMBIGUOUS; WEAK_ITEM with `none` excluded)

Scored items: **396**. Pool mean if even: **33.0**.

| dimension | recommended n | vs even mean |
|---|---:|---:|
| `contact_need` | 20 | -13.0 |
| `closeness_pace` | 41 | +8.0 |
| `initiative` | 27 | -6.0 |
| `autonomy` | 53 | +20.0 |
| `reassurance_need` | 25 | -8.0 |
| `uncertainty_tolerance` | 25 | -8.0 |
| `disclosure_pace` | 35 | +2.0 |
| `boundary_firmness` | 47 | +14.0 |
| `repair_style` | 27 | -6.0 |
| `social_energy` | 23 | -10.0 |
| `structure_preference` | 34 | +1.0 |
| `adaptability` | 39 | +6.0 |

### Overrepresented (recommended n ≥ mean+8)

`closeness_pace` (41), `autonomy` (53), `boundary_firmness` (47)

### Underrepresented (recommended n ≤ mean−8)

`contact_need` (20), `reassurance_need` (25), `uncertainty_tolerance` (25), `social_energy` (23)

Current (pre-proposal) **first-listed** primaries, for comparison — 29 empty, 124 dual-listed not double-counted here:

`boundary_firmness` 58, `autonomy` 45, `closeness_pace` 39, `structure_preference` 38, `disclosure_pace` 34, `EMPTY` 29, `initiative` 29, `reassurance_need` 27, `uncertainty_tolerance` 27, `adaptability` 26, `social_energy` 26, `contact_need` 25, `repair_style` 23

`boundary_firmness` and `autonomy` remain the largest recommended masses. `repair_style` is still scarce as a first-listed label (23) even though several pending conflict items and a few stale initiative/autonomy labels are proposed as repair. `contact_need` and `social_energy` stay relatively thin as true designed contrasts. `initiative` is scarce as a true who-starts contrast.

## Questions whose existing primary should change

- `frequency_v2_q0009`: `disclosure_pace` → `closeness_pace` (high)
- `frequency_v2_q0015`: `EMPTY` → `repair_style` (high)
- `frequency_v2_q0020`: `boundary_firmness` → `uncertainty_tolerance` (medium)
- `frequency_v2_q0027`: `reassurance_need` → `autonomy` (medium)
- `frequency_v2_q0028`: `social_energy` → `boundary_firmness` (high)
- `frequency_v2_q0038`: `structure_preference` → `adaptability` (medium)
- `frequency_v2_q0039`: `uncertainty_tolerance` → `structure_preference` (high)
- `frequency_v2_q0064`: `initiative + repair_style` → `repair_style` (high)
- `frequency_v2_q0071`: `contact_need` → `reassurance_need` (medium)
- `frequency_v2_q0076`: `contact_need + closeness_pace` → `closeness_pace` (high)
- `frequency_v2_q0134`: `reassurance_need` → `contact_need` (high)
- `frequency_v2_q0156`: `disclosure_pace` → `closeness_pace` (high)
- `frequency_v2_q0166`: `EMPTY` → `repair_style` (high)
- `frequency_v2_q0186`: `EMPTY` → `repair_style` (high)
- `frequency_v2_q0228`: `contact_need + adaptability` → `adaptability` (medium)
- `frequency_v2_q0254`: `reassurance_need` → `contact_need` (medium)
- `frequency_v2_q0255`: `uncertainty_tolerance` → `adaptability` (medium)
- `frequency_v2_q0258`: `EMPTY` → `autonomy` (medium)
- `frequency_v2_q0261`: `disclosure_pace` → `repair_style` (medium)
- `frequency_v2_q0264`: `EMPTY` → `disclosure_pace` (high)
- `frequency_v2_q0272`: `uncertainty_tolerance` → `reassurance_need` (medium)
- `frequency_v2_q0275`: `closeness_pace` → `autonomy` (medium)
- `frequency_v2_q0281`: `disclosure_pace` → `closeness_pace` (high)
- `frequency_v2_q0282`: `EMPTY` → `autonomy` (medium)
- `frequency_v2_q0284`: `boundary_firmness` → `disclosure_pace` (medium)
- `frequency_v2_q0288`: `structure_preference` → `initiative` (high)
- `frequency_v2_q0290`: `boundary_firmness` → `autonomy` (medium)
- `frequency_v2_q0294`: `boundary_firmness` → `autonomy` (medium)
- `frequency_v2_q0298`: `uncertainty_tolerance` → `adaptability` (high)
- `frequency_v2_q0317`: `autonomy + reassurance_need` → `repair_style` (medium)
- `frequency_v2_q0333`: `contact_need + adaptability` → `adaptability` (medium)
- `frequency_v2_q0346`: `EMPTY` → `adaptability` (medium)
- `frequency_v2_q0348`: `boundary_firmness` → `autonomy` (medium)
- `frequency_v2_q0352`: `closeness_pace` → `autonomy` (medium)
- `frequency_v2_q0353`: `contact_need` → `closeness_pace` (high)
- `frequency_v2_q0358`: `boundary_firmness` → `autonomy` (medium)
- `frequency_v2_q0360`: `uncertainty_tolerance` → `closeness_pace` (medium)
- `frequency_v2_q0370`: `EMPTY` → `uncertainty_tolerance` (high)
- `frequency_v2_q0372`: `social_energy` → `boundary_firmness` (high)
- `frequency_v2_q0373`: `reassurance_need` → `adaptability` (medium)
- `frequency_v2_q0375`: `initiative` → `autonomy` (medium)
- `frequency_v2_q0382`: `structure_preference` → `initiative` (medium)
- `frequency_v2_q0383`: `EMPTY` → `adaptability` (high)
- `frequency_v2_q0390`: `EMPTY` → `repair_style` (high)
- `frequency_v2_q0393`: `uncertainty_tolerance` → `adaptability` (high)
- `frequency_v2_q0409`: `autonomy + reassurance_need` → `repair_style` (high)
- `frequency_v2_q0426`: `contact_need + adaptability` → `adaptability` (medium)

## List requiring human decision

AMBIGUOUS + WEAK_ITEM. Do not auto-apply these.

### AMBIGUOUS

- `frequency_v2_q0005`None: `boundary_firmness` vs recommended `uncertainty_tolerance` / secondary `boundary_firmness` (medium)
- `frequency_v2_q0011`None: `structure_preference` vs recommended `adaptability` / secondary `structure_preference` (medium)
- `frequency_v2_q0021`None: `autonomy` vs recommended `social_energy` / secondary `autonomy` (medium)
- `frequency_v2_q0026` [pending-primary]: `EMPTY` vs recommended `uncertainty_tolerance` / secondary `adaptability` (medium)
- `frequency_v2_q0030`None: `disclosure_pace` vs recommended `disclosure_pace` / secondary `uncertainty_tolerance` (medium)
- `frequency_v2_q0033`None: `closeness_pace` vs recommended `closeness_pace` / secondary `disclosure_pace` (medium)
- `frequency_v2_q0035`None: `contact_need` vs recommended `disclosure_pace` / secondary `contact_need` (medium)
- `frequency_v2_q0037`None: `boundary_firmness` vs recommended `boundary_firmness` / secondary `uncertainty_tolerance` (medium)
- `frequency_v2_q0065`None: `boundary_firmness + adaptability` vs recommended `adaptability` / secondary `boundary_firmness` (medium)
- `frequency_v2_q0130`None: `boundary_firmness` vs recommended `uncertainty_tolerance` / secondary `autonomy` (medium)
- `frequency_v2_q0139`None: `boundary_firmness` vs recommended `closeness_pace` / secondary `boundary_firmness` (medium)
- `frequency_v2_q0163` [pending-primary]: `EMPTY` vs recommended `adaptability` / secondary `disclosure_pace` (medium)
- `frequency_v2_q0274`None: `closeness_pace` vs recommended `contact_need` / secondary `closeness_pace` (medium)
- `frequency_v2_q0286`None: `social_energy` vs recommended `reassurance_need` / secondary `social_energy` (medium)
- `frequency_v2_q0295` [pending-primary]: `EMPTY` vs recommended `disclosure_pace` / secondary `autonomy` (medium)
- `frequency_v2_q0356`None: `adaptability` vs recommended `autonomy` / secondary `adaptability` (medium)
- `frequency_v2_q0363`None: `boundary_firmness` vs recommended `boundary_firmness` / secondary `social_energy` (medium)
- `frequency_v2_q0365` [pending-primary]: `EMPTY` vs recommended `reassurance_need` / secondary `structure_preference` (medium)
- `frequency_v2_q0377` [pending-primary]: `EMPTY` vs recommended `adaptability` / secondary `structure_preference` (medium)
- `frequency_v2_q0392` [pending-primary]: `EMPTY` vs recommended `autonomy` / secondary `adaptability` (medium)
- `frequency_v2_q0406`None: `boundary_firmness + disclosure_pace` vs recommended `disclosure_pace` / secondary `boundary_firmness` (medium)

### WEAK_ITEM

- `frequency_v2_q0003` [pending-primary]: current `EMPTY` (high)
- `frequency_v2_q0008` [pending-primary]: current `EMPTY` (high)
- `frequency_v2_q0018`None: current `uncertainty_tolerance` (medium)
- `frequency_v2_q0023`None: current `closeness_pace` (high)
- `frequency_v2_q0029` [pending-primary]: current `EMPTY` (high)
- `frequency_v2_q0043` [pending-primary]: current `EMPTY` (high)
- `frequency_v2_q0047` [pending-primary]: current `EMPTY` (high)
- `frequency_v2_q0070`None: current `repair_style` (high)
- `frequency_v2_q0094`None: current `repair_style + adaptability` (high)
- `frequency_v2_q0099`None: current `initiative + autonomy` (medium)
- `frequency_v2_q0113`None: current `boundary_firmness` (medium)
- `frequency_v2_q0127`None: current `repair_style` (high)
- `frequency_v2_q0128`None: current `initiative` (high)
- `frequency_v2_q0135`None: current `closeness_pace` (high)
- `frequency_v2_q0153`None: current `contact_need` (medium)
- `frequency_v2_q0180` [pending-primary]: current `EMPTY` (medium)
- `frequency_v2_q0183` [pending-primary]: current `EMPTY` (medium)
- `frequency_v2_q0191`None: current `reassurance_need` (medium)
- `frequency_v2_q0192` [pending-primary]: current `EMPTY` (medium)
- `frequency_v2_q0252` [pending-primary]: current `EMPTY` (high)
- `frequency_v2_q0266`None: current `structure_preference` (medium)
- `frequency_v2_q0271` [pending-primary]: current `EMPTY` (medium)
- `frequency_v2_q0287` [pending-primary]: current `EMPTY` (medium)
- `frequency_v2_q0292` [pending-primary]: current `EMPTY` (high)
- `frequency_v2_q0301`None: current `repair_style + contact_need` (medium)
- `frequency_v2_q0321`None: current `autonomy + boundary_firmness` (medium)
- `frequency_v2_q0361`None: current `reassurance_need` (medium)
- `frequency_v2_q0380` [pending-primary]: current `EMPTY` (medium)
- `frequency_v2_q0391`None: current `social_energy` (medium)
- `frequency_v2_q0405`None: current `boundary_firmness + disclosure_pace` (high)

## Safety

- V2 pool JSON not modified
- Question/option text not modified
- Option weights not modified
- Evidence metadata not assigned
- V1 / pubspec / live routing / Firebase / Discover / Persona / matching / canonical_v1 / C2 not modified
- No 12D→6D map
- No commit/push

FREQUENCY V2 PHASE 1D PRIMARY SEMANTIC REVIEW READY — NO DATA MODIFIED
