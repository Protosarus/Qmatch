# Frequency V2 Phase 2D — Human evidence decision packet

Status: **packet only**. No scores applied. Proposal JSON unchanged.
Dormant pool `evidence_meta` remains `pending` / null.
V2 remains `runtime_selectable=false`. Bank-wide rescoring was not done.

Source pool fingerprint SHA-256: `d03b2d8c77843d72baf072219c2c0dcae07a0d093dd1bf8c5268f0ef4ca6d56d`
Phase 2B proposal SHA-256 (unchanged): `b77ea92995ddf22684878b188435f01933f3d001631e32daa7431313dff3ef92`
Phase 2C triage SHA-256 (unchanged): `512233106717c6059b3639bac736fd809171c39fb404260115cdb5ee6dfc63cc`

Scope:

- 29 `REAL_REVIEW_REQUIRED` questions from Phase 2C
- 10 sampled ±1 options with `diagnostic_value` ≤ 0.25 judged as possible cue/magnitude leakage

Priors remain uncalibrated. High social desirability is not falsehood.
Do not treat reassurance as weak, boundary as healthy, autonomy as mature,
or repair engagement as the correct answer.

## 1. Twenty-nine REAL_REVIEW_REQUIRED questions

### `frequency_v2_q0002`

- **Primary dimension:** `structure_preference`
- **Triage reason codes:** `SD_DOMINANCE`, `SELF_PRESENTATION_HEAVY`
- **Phase 2B quality:** MEDIUM
- **Question text:** Cumartesi sabahı uyandın, gün için hiçbir planınız yok. Partnerin "Bugün kafamıza göre takılalım, anlık karar veririz" dedi. Ne hissedersin?

**A.** `frequency_v2_q0002_a`
- text: Harika, en sevdiğim şey anın tadını çıkarmaktır.
- behavioral_weights: `{"structure_preference": -2.0, "adaptability": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.25, diagnostic_value=0.50, ambiguity=0.25

**B.** `frequency_v2_q0002_b`
- text: Biraz gerilirim, günün heba olmaması için en azından bir taslak olmasını tercih ederim.
- behavioral_weights: `{"structure_preference": 2.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.25, diagnostic_value=1.00, ambiguity=0.25

**C.** `frequency_v2_q0002_c`
- text: Uygunum ama kendi yapmam gereken birkaç işi halledip ona sonradan katılırım.
- behavioral_weights: `{"autonomy": 2.0, "structure_preference": -1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.25, diagnostic_value=0.50, ambiguity=0.75

**D.** `frequency_v2_q0002_d`
- text: Bana uyar, onun enerjisi neye yönelikse ona eşlik etmekten keyif alırım.
- behavioral_weights: `{"adaptability": 2.0, "initiative": -1.0}`
- proposed evidence: social_desirability=1.00, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.75, diagnostic_value=0.25, ambiguity=0.25

**ISSUE ANALYSIS**

Option D ('eşlik etmekten keyif alırım') is an ideal-self / people-pleasing script with a large social-desirability gap versus A–C. It is also off the named structure_preference axis. A–C still form a readable structure contrast (flow / need a draft / do own work then join).

**RECOMMENDATION:** `ADJUST_EVIDENCE_ONLY`

Proposed evidence adjustments (fields that should change only):

- `frequency_v2_q0002_d` `obviousness`: 0.50 → 0.75 — The wording is easy to read as the approved 'good partner' answer.

---

### `frequency_v2_q0015`

- **Primary dimension:** `repair_style`
- **Triage reason codes:** `SD_DOMINANCE`, `SELF_PRESENTATION_HEAVY`
- **Phase 2B quality:** MEDIUM
- **Question text:** Stresli bir anında partnerine gereksiz yere sert çıkıştın. 10 dakika sonra durumu fark ettin.

**A.** `frequency_v2_q0015_a`
- text: Hemen yanına gidip sarılarak, duygusal bir şekilde özür dilerim.
- behavioral_weights: `{"reassurance_need": 1.0, "repair_style": 2.0}`
- proposed evidence: social_desirability=1.00, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.75, diagnostic_value=0.75, ambiguity=0.50

**B.** `frequency_v2_q0015_b`
- text: Stresimin kaynağını rasyonel bir dille açıklayarak durumu telafi edecek bir konuşma yaparım.
- behavioral_weights: `{"boundary_firmness": 1.0, "repair_style": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25

**C.** `frequency_v2_q0015_c`
- text: Olayı çok büyütmeden, normal bir şey söyleyerek (örn. "çay içer misin?") buzları eritirim.
- behavioral_weights: `{"uncertainty_tolerance": 1.0, "disclosure_pace": -1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25

**D.** `frequency_v2_q0015_d`
- text: Bir süre daha kendi alanımda kalır, ikimizin de tamamen sakinleştiğinden emin olunca konuyu açarım.
- behavioral_weights: `{"autonomy": 1.0, "repair_style": -1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.50

**ISSUE ANALYSIS**

Option A is socially attractive (immediate hug + apology). That is a wording advantage, not proof that repair engagement is 'correct'. Proposed scores already mark A high on social_desirability and self_presentation_risk. The four repair-pacing readings remain usable.

**RECOMMENDATION:** `KEEP_SCORES`

---

### `frequency_v2_q0020`

- **Primary dimension:** `uncertainty_tolerance`
- **Triage reason codes:** `PRIMARY_AXIS_CONFUSION`, `LOW_DIAGNOSTIC_CONTRAST`
- **Phase 2B quality:** LOW
- **Question text:** Partnerin bir şeye bariz şekilde canı sıkkın ama sana "bir şey yok, iyiyim" diyor.

**A.** `frequency_v2_q0020_a`
- text: "Bana anlatabilirsin" diye ısrar eder, aradaki o soğukluğu hemen kırmak isterim.
- behavioral_weights: `{"reassurance_need": 2.0, "boundary_firmness": -1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25

**B.** `frequency_v2_q0020_b`
- text: Gerçekten anlatmak isteyene kadar bekler, tamamen kendi alanına saygı gösteririm.
- behavioral_weights: `{"autonomy": 1.0, "boundary_firmness": 2.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.50

**C.** `frequency_v2_q0020_c`
- text: O anlatmayana kadar ben de günlük rutinimde hiçbir şey yokmuş gibi davranmaya devam ederim.
- behavioral_weights: `{"contact_need": -1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25

**D.** `frequency_v2_q0020_d`
- text: Konuşmaya zorlamam ama fiziksel bir temasla (sarılarak) yanında olduğumu hissettiririm.
- behavioral_weights: `{"closeness_pace": 1.0, "disclosure_pace": -1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.00, ambiguity=0.75

**ISSUE ANALYSIS**

Named primary is uncertainty_tolerance, but no option carries that weight. The four reactions (insist / wait / ignore / hug) are interpretable as contact, boundary, and closeness behaviors. Evidence scoring cannot attach an uncertainty-tolerance signal that the options do not instantiate.

**RECOMMENDATION:** `REWRITE_REQUIRED`

Evidence scoring alone cannot fix this. Do not rewrite in Phase 2D.

---

### `frequency_v2_q0026`

- **Primary dimension:** `uncertainty_tolerance`
- **Triage reason codes:** `PRIMARY_AXIS_CONFUSION`, `LOW_DIAGNOSTIC_CONTRAST`
- **Phase 2B quality:** LOW
- **Question text:** Temel bir inanç veya hayata bakış açısı konusunda partnerinle tamamen zıt olduğunuzu fark ettiniz.

**A.** `frequency_v2_q0026_a`
- text: Bu konuyu derinlemesine, belki saatlerce tartışarak ortak bir zemin bulmaya çalışırım.
- behavioral_weights: `{"initiative": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25

**B.** `frequency_v2_q0026_b`
- text: Herkesin kendi gerçeği olduğunu kabul eder, konuyu ilişkimizin merkezinden uzak tutarım.
- behavioral_weights: `{"boundary_firmness": 2.0, "autonomy": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25

**C.** `frequency_v2_q0026_c`
- text: Fikirlerini değiştirmeye çalışmam ama onun bakış açısını entelektüel bir merakla deşerim.
- behavioral_weights: `{"disclosure_pace": -1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.75

**D.** `frequency_v2_q0026_d`
- text: Bu zıtlığı bir zenginlik olarak görür, onun düşünce yapısına uyumlanabilip uyumlanamayacağıma bakarım.
- behavioral_weights: `{"adaptability": 2.0, "boundary_firmness": -2.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25

**ISSUE ANALYSIS**

Value-disagreement scene is readable, but options map to initiative, boundary/autonomy, disclosure, and adaptability — none to the named uncertainty_tolerance primary. Scoring cannot relabel the axis.

**RECOMMENDATION:** `REWRITE_REQUIRED`

Evidence scoring alone cannot fix this. Do not rewrite in Phase 2D.

---

### `frequency_v2_q0030`

- **Primary dimension:** `uncertainty_tolerance`
- **Triage reason codes:** `PRIMARY_AXIS_CONFUSION`, `LOW_DIAGNOSTIC_CONTRAST`
- **Phase 2B quality:** LOW
- **Question text:** Partnerinin geçmişiyle ilgili zarar verici olmayan ama senin yeni öğrendiğin önemli bir detayı (örn: eski mesleği) gizlediğini fark ettin.

**A.** `frequency_v2_q0030_a`
- text: "Benden bunu neden sakladın?" diyerek dürüstlük ve güven ekseninde sert bir konuşma yaparım.
- behavioral_weights: `{"disclosure_pace": 2.0, "boundary_firmness": 2.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25

**B.** `frequency_v2_q0030_b`
- text: Herkesin hazır hissettiği zaman anlatma hakkı olduğunu düşünür, pek üstünde durmam.
- behavioral_weights: `{"disclosure_pace": -2.0, "autonomy": 1.0}`
- proposed evidence: social_desirability=0.25, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.25

**C.** `frequency_v2_q0030_c`
- text: Neden saklama ihtiyacı duyduğunu anlamak için yargılamadan dinlemeye odaklanırım.
- behavioral_weights: `{"adaptability": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.50

**D.** `frequency_v2_q0030_d`
- text: İçten içe kırılırım ama konuyu açmasını onun inisiyatifine bırakırım.
- behavioral_weights: `{"reassurance_need": 1.0, "initiative": -1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.75

**ISSUE ANALYSIS**

Hidden-past-detail stem could be uncertainty or disclosure, but current options are authored on disclosure, adaptability, and reassurance. None carry uncertainty_tolerance. Evidence priors cannot create that primary.

**RECOMMENDATION:** `REWRITE_REQUIRED`

Evidence scoring alone cannot fix this. Do not rewrite in Phase 2D.

---

### `frequency_v2_q0035`

- **Primary dimension:** `disclosure_pace`
- **Triage reason codes:** `PRIMARY_AXIS_CONFUSION`, `LOW_DIAGNOSTIC_CONTRAST`
- **Phase 2B quality:** LOW
- **Question text:** Hayatında her şeyin üst üste geldiği, inanılmaz stresli bir dönemdesin. İlişkine nasıl yansır?

**A.** `frequency_v2_q0035_a`
- text: Stresimi partnerimle sürekli konuşarak, onun desteğine daha çok yaslanarak atlatırım.
- behavioral_weights: `{"contact_need": 2.0, "reassurance_need": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25

**B.** `frequency_v2_q0035_b`
- text: Kendi içime kapanır, sorunları çözene kadar biraz mesafeli ve sessiz kalırım.
- behavioral_weights: `{"autonomy": 2.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.00, ambiguity=0.25

**C.** `frequency_v2_q0035_c`
- text: Günlük rutinimize hiçbir şey yokmuş gibi devam etmeye, ilişkiyi bir kaçış alanı olarak görmeye çalışırım.
- behavioral_weights: `{"uncertainty_tolerance": 1.0, "structure_preference": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.00, ambiguity=0.25

**D.** `frequency_v2_q0035_d`
- text: Stresim onu da etkilemesin diye aşırı dikkatli davranır, kendi ihtiyaçlarımı geri plana atarım.
- behavioral_weights: `{"boundary_firmness": -2.0, "adaptability": 2.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25

**ISSUE ANALYSIS**

Stress-spillover stem is multidimensional. Options are contact/reassurance, autonomy, structure/uncertainty, and self-sacrifice — none carry disclosure_pace. Scoring cannot recover a disclosure contrast.

**RECOMMENDATION:** `REWRITE_REQUIRED`

Evidence scoring alone cannot fix this. Do not rewrite in Phase 2D.

---

### `frequency_v2_q0049`

- **Primary dimension:** `reassurance_need`
- **Triage reason codes:** `SD_DOMINANCE`, `OBVIOUS_TEST_ANSWER`, `SELF_PRESENTATION_HEAVY`
- **Phase 2B quality:** LOW
- **Question text:** Partnerinin sosyal medyada eski bir flörtünün fotoğraflarını beğendiğini gördün. Bu sende nasıl bir içsel tepki yaratır?

**A.** `frequency_v2_q0049_a`
- text: Ciddi bir özgüven/güven sarsıntısı yaşar, konuyu hemen, biraz da suçlayıcı bir tonda açarım.
- behavioral_weights: `{"reassurance_need": 2.0, "boundary_firmness": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25

**B.** `frequency_v2_q0049_b`
- text: Üstünde durmam. Dijital hareketleri yakından takip eden veya kıskançlık yapan biri değilimdir.
- behavioral_weights: `{"reassurance_need": -2.0, "autonomy": 1.0}`
- proposed evidence: social_desirability=0.25, obviousness=0.25, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25

**C.** `frequency_v2_q0049_c`
- text: Rahatsız olurum ama olayı büyütmemek için kendimi tutar, dolaylı yoldan tavır yapabilirim.
- behavioral_weights: `{"disclosure_pace": -1.0}`
- proposed evidence: social_desirability=0.00, obviousness=0.25, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.75

**D.** `frequency_v2_q0049_d`
- text: Bunu açık bir iletişim fırsatı görüp, rahatsızlığımı suçlamadan ama net bir şekilde ifade ederim.
- behavioral_weights: `{"boundary_firmness": 1.0, "disclosure_pace": 1.0}`
- proposed evidence: social_desirability=0.75, obviousness=1.00, behavioral_plausibility=0.75, self_presentation_risk=0.75, diagnostic_value=0.50, ambiguity=0.75

**ISSUE ANALYSIS**

A and B already span reassurance_need. D is a textbook 'healthy communication' script (iletişim fırsatı / suçlamadan / net) and is off-primary. B also contains an identity claim ('kıskançlık yapan biri değilimdir') whose social-desirability prior is too low.

**RECOMMENDATION:** `ADJUST_EVIDENCE_ONLY`

Proposed evidence adjustments (fields that should change only):

- `frequency_v2_q0049_b` `social_desirability`: 0.25 → 0.75 — The wording presents a composed, non-jealous identity relative to A/C.
- `frequency_v2_q0049_b` `self_presentation_risk`: 0.50 → 0.75 — Easy to select mainly to look unjealous; not a lie score.
- `frequency_v2_q0049_d` `diagnostic_value`: 0.50 → 0.25 — If chosen sincerely it signals communication style, not reassurance_need.

---

### `frequency_v2_q0081`

- **Primary dimension:** `closeness_pace`
- **Triage reason codes:** `CULTURAL_DEPENDENCE`
- **Phase 2B quality:** LOW
- **Question text:** Partnerin ailesi / yakın çevresiyle tanışma konusu açıldı.

**A.** `frequency_v2_q0081_a`
- text: Erken olmasını isterim.
- behavioral_weights: `{"closeness_pace": 2.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.25, self_presentation_risk=0.25, diagnostic_value=0.50, ambiguity=0.50

**B.** `frequency_v2_q0081_b`
- text: Zamanı gelince olur.
- behavioral_weights: `{"uncertainty_tolerance": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.25, self_presentation_risk=0.25, diagnostic_value=0.25, ambiguity=0.50

**C.** `frequency_v2_q0081_c`
- text: Ben hazır olunca olur.
- behavioral_weights: `{"boundary_firmness": 1.0, "autonomy": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.25, self_presentation_risk=0.25, diagnostic_value=0.25, ambiguity=0.50

**D.** `frequency_v2_q0081_d`
- text: Çok acele etmeden, doğal aksın.
- behavioral_weights: `{"closeness_pace": -1.0, "adaptability": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=1.00, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.25

**ISSUE ANALYSIS**

Meeting family/close circle is culturally loaded, but the four answers (early / when the time comes / when I am ready / let it flow) still form a closeness_pace contrast. Short wording made Phase 2B mark A–C as implausible; they are ordinary brief reactions, not caricatures.

**RECOMMENDATION:** `ADJUST_EVIDENCE_ONLY`

Proposed evidence adjustments (fields that should change only):

- `frequency_v2_q0081_a` `behavioral_plausibility`: 0.25 → 0.75 — Brief but ordinary 'I want it early' reaction.
- `frequency_v2_q0081_b` `behavioral_plausibility`: 0.25 → 0.75 — Brief but ordinary wait-for-timing reaction.
- `frequency_v2_q0081_c` `behavioral_plausibility`: 0.25 → 0.75 — Brief but ordinary self-readiness boundary.

---

### `frequency_v2_q0097`

- **Primary dimension:** `repair_style`
- **Triage reason codes:** `SD_DOMINANCE`, `SELF_PRESENTATION_HEAVY`
- **Phase 2B quality:** LOW
- **Question text:** Bir konuda özür dilemen gereken bir durum oluştu.

**A.** `frequency_v2_q0097_a`
- text: Hemen ve net özür dilerim.
- behavioral_weights: `{"repair_style": 1.0, "initiative": 1.0}`
- proposed evidence: social_desirability=0.75, obviousness=0.50, behavioral_plausibility=0.25, self_presentation_risk=0.75, diagnostic_value=0.75, ambiguity=0.75

**B.** `frequency_v2_q0097_b`
- text: Durumu açıklayıp özür eklerim.
- behavioral_weights: `{"disclosure_pace": 1.0, "repair_style": 1.0}`
- proposed evidence: social_desirability=0.75, obviousness=0.50, behavioral_plausibility=1.00, self_presentation_risk=0.50, diagnostic_value=1.00, ambiguity=0.25

**C.** `frequency_v2_q0097_c`
- text: Davranışla telafi ederim.
- behavioral_weights: `{"repair_style": 0.0, "adaptability": 1.0}`
- proposed evidence: social_desirability=0.25, obviousness=0.25, behavioral_plausibility=0.25, self_presentation_risk=0.25, diagnostic_value=0.25, ambiguity=0.50

**D.** `frequency_v2_q0097_d`
- text: Zamanla unutulur diye beklerim.
- behavioral_weights: `{"repair_style": -2.0, "uncertainty_tolerance": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=1.00, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25

**ISSUE ANALYSIS**

A/B are socially attractive apology scripts; that is already partly scored. A is a stub, so Phase 2B set low plausibility and high ambiguity. The text 'Hemen ve net özür dilerim' is a clear, ordinary immediate-repair pole.

**RECOMMENDATION:** `ADJUST_EVIDENCE_ONLY`

Proposed evidence adjustments (fields that should change only):

- `frequency_v2_q0097_a` `behavioral_plausibility`: 0.25 → 0.75 — Short, but a realistic immediate apology.
- `frequency_v2_q0097_a` `ambiguity`: 0.75 → 0.25 — One clear repair-pacing reading, not mixed motives.

---

### `frequency_v2_q0107`

- **Primary dimension:** `autonomy`
- **Triage reason codes:** `HIGH_AMBIGUITY`
- **Phase 2B quality:** LOW
- **Question text:** Birlikte geçirmeyi düşündüğün hafta sonu için partnerin “Bu hafta sonu biraz yalnız kalmaya ihtiyacım var” dedi.

**A.** `frequency_v2_q0107_a`
- text: Kendi planlarımı yaparım; bu alanı doğal karşılarım.
- behavioral_weights: `{"autonomy": 2.0, "reassurance_need": -1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=1.00, ambiguity=0.25

**B.** `frequency_v2_q0107_b`
- text: Alan tanırım ama gün içinde küçük bir temasımızın olmasını isterim.
- behavioral_weights: `{"contact_need": 1.0, "adaptability": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=1.00

**C.** `frequency_v2_q0107_c`
- text: Aramızda bir sorun olup olmadığını netleştirmek isterim.
- behavioral_weights: `{"reassurance_need": 2.0, "uncertainty_tolerance": -1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.00, ambiguity=0.25

**D.** `frequency_v2_q0107_d`
- text: İsterse aynı evde/ortamda herkesin kendi halinde olabileceği bir seçenek sunarım.
- behavioral_weights: `{"closeness_pace": 1.0, "autonomy": -1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.25

**ISSUE ANALYSIS**

Option B mixes space with a small contact request ('ama … küçük bir temas'). That is one mixed-motive reading, not two incompatible interpretations. ambiguity=1.00 is a Phase 2B conjunction overflag.

**RECOMMENDATION:** `ADJUST_EVIDENCE_ONLY`

Proposed evidence adjustments (fields that should change only):

- `frequency_v2_q0107_b` `ambiguity`: 1.00 → 0.50 — Readable mixed space-plus-contact request, not uninterpretable.

---

### `frequency_v2_q0123`

- **Primary dimension:** `repair_style`
- **Triage reason codes:** `SD_DOMINANCE`, `OBVIOUS_TEST_ANSWER`, `SELF_PRESENTATION_HEAVY`
- **Phase 2B quality:** LOW
- **Question text:** Stresli bir anında partnerine gereksiz sert çıktığını on dakika sonra fark ettin.

**A.** `frequency_v2_q0123_a`
- text: Hemen özür diler, ne olduğunu açıkça konuşurum.
- behavioral_weights: `{"repair_style": 2.0, "disclosure_pace": 1.0}`
- proposed evidence: social_desirability=1.00, obviousness=0.75, behavioral_plausibility=0.75, self_presentation_risk=0.75, diagnostic_value=0.75, ambiguity=0.25

**B.** `frequency_v2_q0123_b`
- text: Önce küçük bir jestle havayı yumuşatır, konuşmayı biraz sonraya bırakırım.
- behavioral_weights: `{"adaptability": 1.0, "repair_style": -1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.25

**C.** `frequency_v2_q0123_c`
- text: Neden o halde olduğumu açıklayıp olayın bağlamını anlatırım.
- behavioral_weights: `{"disclosure_pace": 1.0, "boundary_firmness": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.75, self_presentation_risk=0.25, diagnostic_value=0.25, ambiguity=0.50

**D.** `frequency_v2_q0123_d`
- text: İkimiz de tamamen sakinleşene kadar biraz beklerim.
- behavioral_weights: `{"autonomy": 1.0, "repair_style": -2.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.75, self_presentation_risk=0.25, diagnostic_value=0.25, ambiguity=0.25

**ISSUE ANALYSIS**

Near-duplicate of q0015. Option A is the obvious immediate-apology script; proposed scores already raise social_desirability, obviousness, and self_presentation_risk. Do not treat high repair engagement as the correct answer.

**RECOMMENDATION:** `KEEP_SCORES`

---

### `frequency_v2_q0152`

- **Primary dimension:** `uncertainty_tolerance`
- **Triage reason codes:** `HIGH_AMBIGUITY`
- **Phase 2B quality:** LOW
- **Question text:** Flört dönemindesiniz. Partnerinin, eski sevgilisiyle sosyal medyada hala takipleştiğini fark ettin. İlk tepkin genelde ne olur?

**A.** `frequency_v2_q0152_a`
- text: Umursamam, geçmiş geçmişte kalmıştır ve herkesin kendi dijital alanıdır.
- behavioral_weights: `{"uncertainty_tolerance": 2.0, "autonomy": 1.0}`
- proposed evidence: social_desirability=0.00, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25

**B.** `frequency_v2_q0152_b`
- text: Biraz kafama takılır, güvenimi tazelemek için bana karşı olan ilgisini daha yakından gözlemlerim.
- behavioral_weights: `{"reassurance_need": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.50

**C.** `frequency_v2_q0152_c`
- text: Açıkça "Eski ilişkinle hala arkadaş mısınız?" diye sorup kafamdaki belirsizliği hemen netleştiririm.
- behavioral_weights: `{"uncertainty_tolerance": -2.0, "initiative": 1.0}`
- proposed evidence: social_desirability=0.75, obviousness=0.75, behavioral_plausibility=0.75, self_presentation_risk=0.75, diagnostic_value=1.00, ambiguity=0.25

**D.** `frequency_v2_q0152_d`
- text: Rahatsız olurum ama bunu dile getirmek yerine onun zamanla kendiliğinden silmesini beklerim.
- behavioral_weights: `{"boundary_firmness": -1.0, "disclosure_pace": -1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=1.00

**ISSUE ANALYSIS**

Option D (discomfort without asking; wait for them to unfollow) was scored ambiguity=1.00. It is a single delayed/indirect reading, not two opposite meanings. C is more test-transparent ('açıkça … netleştiririm') and already marked high on social_desirability/obviousness.

**RECOMMENDATION:** `ADJUST_EVIDENCE_ONLY`

Proposed evidence adjustments (fields that should change only):

- `frequency_v2_q0152_d` `ambiguity`: 1.00 → 0.50 — Discomfort-plus-silence is one interpretation.

---

### `frequency_v2_q0156`

- **Primary dimension:** `closeness_pace`
- **Triage reason codes:** `CULTURAL_DEPENDENCE`
- **Phase 2B quality:** LOW
- **Question text:** İlişkinizin 6. ayındasınız. Partnerin seni aniden, çok sevdiği ailesiyle bir akşam yemeğine davet etti.

**A.** `frequency_v2_q0156_a`
- text: Çok mutlu olurum, onun köklerini ve ailesini tanımak bağımızı çok daha derinleştirir.
- behavioral_weights: `{"closeness_pace": 2.0, "social_energy": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.25

**B.** `frequency_v2_q0156_b`
- text: Giderim ama aile işlerine bu kadar erken girmek bende ufak bir baskı yaratır.
- behavioral_weights: `{"disclosure_pace": -1.0, "autonomy": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.75

**C.** `frequency_v2_q0156_c`
- text: Memnuniyetle katılırım ancak gece boyunca kendimden çok bahsetmez, onları gözlemlerim.
- behavioral_weights: `{"disclosure_pace": -2.0, "social_energy": -1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.50

**D.** `frequency_v2_q0156_d`
- text: Ortamı yumuşatmak ve iyi bir izlenim bırakmak için sohbeti ben yönlendirir, espriler yaparım.
- behavioral_weights: `{"initiative": 2.0, "social_energy": 2.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25

**ISSUE ANALYSIS**

Family-dinner timing is culturally loaded. A still carries closeness_pace; B–D drift into disclosure/social_energy/initiative and already have lower diagnostic_value. Keep the priors; do not treat family-meeting enthusiasm as healthier closeness.

**RECOMMENDATION:** `KEEP_SCORES`

---

### `frequency_v2_q0159`

- **Primary dimension:** `structure_preference`
- **Triage reason codes:** `SD_DOMINANCE`, `CULTURAL_DEPENDENCE`
- **Phase 2B quality:** LOW
- **Question text:** İlk birkaç buluşmada hesap ödeme dinamiklerinin nasıl olması seni en rahat hissettirir?

**A.** `frequency_v2_q0159_a`
- text: Alman usulü. Kim ne yediyse veya yarı yarıya tam olarak bölünmesi en adilidir.
- behavioral_weights: `{"structure_preference": 2.0, "boundary_firmness": 1.0}`
- proposed evidence: social_desirability=0.75, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.25

**B.** `frequency_v2_q0159_b`
- text: Bir sefer ben ödüyorsam, bir sonrakinde tamamen onun ödemesi daha organik bir akıştır.
- behavioral_weights: `{"structure_preference": -1.0, "closeness_pace": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25

**C.** `frequency_v2_q0159_c`
- text: Hesabı kimin ödediğine pek takılmam, o an içimden gelirse öder geçerim, hesap tutmam.
- behavioral_weights: `{"uncertainty_tolerance": 2.0, "structure_preference": -2.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.25

**D.** `frequency_v2_q0159_d`
- text: Benim ödememe hiç izin vermezse bunu sahiplenici bulur ve hoşuma gider.
- behavioral_weights: `{"reassurance_need": 2.0, "initiative": -1.0}`
- proposed evidence: social_desirability=0.25, obviousness=0.50, behavioral_plausibility=0.50, self_presentation_risk=0.50, diagnostic_value=0.00, ambiguity=0.50

**ISSUE ANALYSIS**

Bill-splitting ('Alman usulü', 'en adilidir', provider-script D) is culturally dependent. The four options still contrast structure vs rotation vs not tracking vs being paid for. Proposed SD on A and low DV on D already reflect that. Keep scores; interpret later with locale caution.

**RECOMMENDATION:** `KEEP_SCORES`

---

### `frequency_v2_q0176`

- **Primary dimension:** `adaptability`
- **Triage reason codes:** `HIGH_AMBIGUITY`
- **Phase 2B quality:** LOW
- **Question text:** Partnerin bir belgesel izledi ve o günden sonra tamamen vegan/çok sıkı bir diyete geçmeye karar verdi.

**A.** `frequency_v2_q0176_a`
- text: Eve zararlı hiçbir şeyin girmemesi kuralına ben de uyar, ona eşlik etmek için diyetimi değiştiririm.
- behavioral_weights: `{"adaptability": 2.0, "boundary_firmness": -2.0}`
- proposed evidence: social_desirability=0.75, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=1.00, ambiguity=0.25

**B.** `frequency_v2_q0176_b`
- text: Kararına saygı duyarım ama ben kendi yediğimden taviz vermem, evde iki farklı menü pişer.
- behavioral_weights: `{"boundary_firmness": 2.0, "autonomy": 2.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=1.00

**C.** `frequency_v2_q0176_c`
- text: Dışarıda yemek yiyeceğimiz zamanlarda bu durumun planlarımızı ne kadar kısıtlayacağını dert ederim.
- behavioral_weights: `{"structure_preference": 1.0, "uncertainty_tolerance": -1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25

**D.** `frequency_v2_q0176_d`
- text: Ne kadar sürdürebileceğini görmek için önce uzaktan izler, sonra duruma göre şekil alırım.
- behavioral_weights: `{"disclosure_pace": -1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25

**ISSUE ANALYSIS**

Option B (respect the diet, keep my own food, two menus) is the clearest autonomy/boundary pole in the set. ambiguity=1.00 is an 'ama' overflag, not two rival meanings.

**RECOMMENDATION:** `ADJUST_EVIDENCE_ONLY`

Proposed evidence adjustments (fields that should change only):

- `frequency_v2_q0176_b` `ambiguity`: 1.00 → 0.25 — One clear two-menu / non-merging reading.

---

### `frequency_v2_q0186`

- **Primary dimension:** `repair_style`
- **Triage reason codes:** `OBVIOUS_TEST_ANSWER`, `SELF_PRESENTATION_HEAVY`
- **Phase 2B quality:** LOW
- **Question text:** Büyük bir kavgada bağırdın, çağırdın. Ancak 10 dakika sonra aslında tamamen *senin haksız olduğunu* fark ettin.

**A.** `frequency_v2_q0186_a`
- text: Utanır, bir süre sessiz kalıp zamanın geçmesini ve olayın unutulmasını beklerim.
- behavioral_weights: `{"disclosure_pace": -2.0, "boundary_firmness": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.50

**B.** `frequency_v2_q0186_b`
- text: Anında yanına gider, gurur yapmadan "Ben yanlış anlamışım, çok özür dilerim" derim.
- behavioral_weights: `{"boundary_firmness": -1.0, "repair_style": 2.0}`
- proposed evidence: social_desirability=0.75, obviousness=0.75, behavioral_plausibility=0.50, self_presentation_risk=0.75, diagnostic_value=0.75, ambiguity=0.25

**C.** `frequency_v2_q0186_c`
- text: Konuyu direkt açmak yerine ona kahve yapmak, sevdiği bir şeyi getirmek gibi eylemlerle durumu yumuşatırım.
- behavioral_weights: `{"uncertainty_tolerance": 1.0, "closeness_pace": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25

**D.** `frequency_v2_q0186_d`
- text: Haklı olduğu tarafları kabul etsem de, benim o tepkiyi vermeme neden olan "onun" hatasını da masaya sürerim.
- behavioral_weights: `{"boundary_firmness": 2.0, "repair_style": -1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=1.00, ambiguity=0.25

**ISSUE ANALYSIS**

The stem states the respondent was completely wrong, which moralizes the scene. B ('gurur yapmadan … özür') is the obvious approved repair. Proposed scores already mark it high on social_desirability, obviousness, and self_presentation_risk. Immediate apology is not scored as more 'healthy'.

**RECOMMENDATION:** `KEEP_SCORES`

---

### `frequency_v2_q0197`

- **Primary dimension:** `autonomy`
- **Triage reason codes:** `CULTURAL_DEPENDENCE`
- **Phase 2B quality:** LOW
- **Question text:** Gelecekte evlilik veya ciddi bir beraberlikte maddi hesapların nasıl olmasını beklersin?

**A.** `frequency_v2_q0197_a`
- text: Tek bir ortak hesap olmalı, senin/benim param kavramı tamamen ortadan kalkmalıdır.
- behavioral_weights: `{"closeness_pace": 2.0, "autonomy": -2.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.25

**B.** `frequency_v2_q0197_b`
- text: Ortak ev giderleri için bir havuz olmalı ama herkesin maaşı ve şahsi tasarrufu kendi hesabında kalmalıdır.
- behavioral_weights: `{"autonomy": 2.0, "structure_preference": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.75

**C.** `frequency_v2_q0197_c`
- text: Para işleriyle ben ilgilenmek isterim, fatura ve bütçe planlamasını ben yönetirsem içim rahat eder.
- behavioral_weights: `{"initiative": 2.0, "structure_preference": 2.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.00, ambiguity=0.25

**D.** `frequency_v2_q0197_d`
- text: Önceden kesin kurallar koymam, duruma, kazanca ve ihtiyaca göre doğal bir denge bulunur.
- behavioral_weights: `{"uncertainty_tolerance": 2.0, "structure_preference": -2.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25

**ISSUE ANALYSIS**

Money-pooling norms vary by culture. A vs B still instantiate a usable autonomy contrast (fully merged money vs pooled bills plus separate savings). C/D are off-primary and already low diagnostic. Keep priors.

**RECOMMENDATION:** `KEEP_SCORES`

---

### `frequency_v2_q0203`

- **Primary dimension:** `boundary_firmness`
- **Triage reason codes:** `HIGH_AMBIGUITY`
- **Phase 2B quality:** LOW
- **Question text:** Partneriniz sizi kendi yakın arkadaş grubuyla tanıştırmak istiyor. Siz henüz hazır hissetmiyorsunuz.

**A.** `frequency_v2_q0203_a`
- text: “Biraz daha zaman isteyebilir miyim?” derim.
- behavioral_weights: `{"boundary_firmness": 1.0, "adaptability": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=1.00, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25

**B.** `frequency_v2_q0203_b`
- text: Giderim ama kısa tutarım.
- behavioral_weights: `{"social_energy": 1.0, "adaptability": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.25, self_presentation_risk=0.25, diagnostic_value=0.00, ambiguity=1.00

**C.** `frequency_v2_q0203_c`
- text: “Şu an olmaz” diye net söylerim.
- behavioral_weights: `{"boundary_firmness": 2.0, "autonomy": 1.0}`
- proposed evidence: social_desirability=0.75, obviousness=0.75, behavioral_plausibility=1.00, self_presentation_risk=0.75, diagnostic_value=1.00, ambiguity=0.25

**D.** `frequency_v2_q0203_d`
- text: Onun için zorlarım kendimi.
- behavioral_weights: `{"adaptability": 2.0, "autonomy": -1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.25, self_presentation_risk=0.25, diagnostic_value=0.00, ambiguity=0.50

**ISSUE ANALYSIS**

B ('Giderim ama kısa tutarım') is a clear milder boundary, not ambiguity=1.00. Short wording also under-scored plausibility. C is the obvious firm no and already has high obviousness — leave that.

**RECOMMENDATION:** `ADJUST_EVIDENCE_ONLY`

Proposed evidence adjustments (fields that should change only):

- `frequency_v2_q0203_b` `ambiguity`: 1.00 → 0.50 — Attend-but-limit-time is one mixed but readable boundary.
- `frequency_v2_q0203_b` `behavioral_plausibility`: 0.25 → 0.75 — Ordinary real-world compromise, not a stub caricature.
- `frequency_v2_q0203_b` `diagnostic_value`: 0.00 → 0.50 — Sincere selection gives a milder on-axis boundary signal versus C.
- `frequency_v2_q0203_d` `behavioral_plausibility`: 0.25 → 0.75 — Brief but realistic self-push to attend.

---

### `frequency_v2_q0208`

- **Primary dimension:** `autonomy`
- **Triage reason codes:** `CULTURAL_DEPENDENCE`
- **Phase 2B quality:** LOW
- **Question text:** Birlikte bir akşam yemeğine gittiniz. Hesap geldiğinde partneriniz “ben bakayım” diyor.

**A.** `frequency_v2_q0208_a`
- text: Paylaşmayı öneririm.
- behavioral_weights: `{"initiative": 1.0, "structure_preference": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.25, self_presentation_risk=0.25, diagnostic_value=0.00, ambiguity=0.50

**B.** `frequency_v2_q0208_b`
- text: Kabul ederim.
- behavioral_weights: `{"adaptability": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.25, self_presentation_risk=0.25, diagnostic_value=0.25, ambiguity=0.50

**C.** `frequency_v2_q0208_c`
- text: “Bu sefer sen, sonra ben” derim.
- behavioral_weights: `{"structure_preference": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=1.00, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25

**D.** `frequency_v2_q0208_d`
- text: Her zaman ayrı ödemeyi tercih ederim.
- behavioral_weights: `{"autonomy": 2.0, "boundary_firmness": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=1.00, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.25

**ISSUE ANALYSIS**

Who-pays is culturally loaded, but the four answers (split / accept / rotate / always separate) are interpretable. A/B plausibility 0.25 is stub leakage. Primary is autonomy; D is the strongest on-axis option.

**RECOMMENDATION:** `ADJUST_EVIDENCE_ONLY`

Proposed evidence adjustments (fields that should change only):

- `frequency_v2_q0208_a` `behavioral_plausibility`: 0.25 → 0.75 — Ordinary split suggestion.
- `frequency_v2_q0208_b` `behavioral_plausibility`: 0.25 → 0.75 — Ordinary acceptance of being paid for.
- `frequency_v2_q0208_a` `diagnostic_value`: 0.00 → 0.50 — Proposing to share is a usable milder autonomy/structure signal.

---

### `frequency_v2_q0213`

- **Primary dimension:** `closeness_pace`
- **Triage reason codes:** `CULTURAL_DEPENDENCE`
- **Phase 2B quality:** LOW
- **Question text:** Partneriniz sizi ailesiyle tanıştırmayı teklif ediyor. Siz henüz ilişkiyi o kadar ilerletmiş hissetmiyorsunuz.

**A.** `frequency_v2_q0213_a`
- text: “Biraz erken” derim.
- behavioral_weights: `{"closeness_pace": -1.0, "boundary_firmness": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.50, self_presentation_risk=0.25, diagnostic_value=0.50, ambiguity=0.50

**B.** `frequency_v2_q0213_b`
- text: Kabul ederim.
- behavioral_weights: `{"closeness_pace": 1.0, "adaptability": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.25, self_presentation_risk=0.25, diagnostic_value=0.50, ambiguity=0.50

**C.** `frequency_v2_q0213_c`
- text: “Önce ikimiz netleşelim” derim.
- behavioral_weights: `{"reassurance_need": 1.0, "structure_preference": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.75, behavioral_plausibility=1.00, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25

**D.** `frequency_v2_q0213_d`
- text: Ertelemeyi öneririm.
- behavioral_weights: `{"uncertainty_tolerance": 1.0, "boundary_firmness": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.50, self_presentation_risk=0.25, diagnostic_value=0.25, ambiguity=0.50

**ISSUE ANALYSIS**

Family introduction is culturally loaded, and A ('Biraz erken') vs D ('Ertelemeyi öneririm') are functionally near-duplicates of slowing the pace. Evidence scoring cannot create contrast between those two options.

**RECOMMENDATION:** `REWRITE_REQUIRED`

Evidence scoring alone cannot fix this. Do not rewrite in Phase 2D.

---

### `frequency_v2_q0227`

- **Primary dimension:** `adaptability`
- **Triage reason codes:** `CULTURAL_DEPENDENCE`
- **Phase 2B quality:** LOW
- **Question text:** Partneriniz sizi kendi ailesinin bir özel gününe (doğum günü, bayram) davet ediyor. Siz o gün başka bir plan yapmıştınız.

**A.** `frequency_v2_q0227_a`
- text: Planımı bozar, giderim.
- behavioral_weights: `{"adaptability": 2.0, "social_energy": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.25, self_presentation_risk=0.25, diagnostic_value=0.75, ambiguity=0.50

**B.** `frequency_v2_q0227_b`
- text: “Bu sefer olmaz” derim.
- behavioral_weights: `{"boundary_firmness": 1.0, "autonomy": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.25, self_presentation_risk=0.25, diagnostic_value=0.00, ambiguity=0.50

**C.** `frequency_v2_q0227_c`
- text: Kısa uğrayıp çıkarım.
- behavioral_weights: `{"adaptability": 1.0, "boundary_firmness": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.25, self_presentation_risk=0.25, diagnostic_value=0.50, ambiguity=0.50

**D.** `frequency_v2_q0227_d`
- text: Alternatif bir zaman öneririm.
- behavioral_weights: `{"initiative": 1.0, "structure_preference": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=1.00, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25

**ISSUE ANALYSIS**

Family/bayram invitation vs an existing plan is culturally loaded, but A–D still contrast adaptability (drop plan / decline / short visit / reschedule). Stub plausibility 0.25 on A–C is not deserved.

**RECOMMENDATION:** `ADJUST_EVIDENCE_ONLY`

Proposed evidence adjustments (fields that should change only):

- `frequency_v2_q0227_a` `behavioral_plausibility`: 0.25 → 0.75 — Canceling one's plan to attend is ordinary, not artificial.
- `frequency_v2_q0227_b` `behavioral_plausibility`: 0.25 → 0.75 — Declining this time is an ordinary boundary.
- `frequency_v2_q0227_c` `behavioral_plausibility`: 0.25 → 0.75 — A short appearance is a realistic compromise.
- `frequency_v2_q0227_b` `diagnostic_value`: 0.00 → 0.50 — Clear non-adapting pole versus A; 0.00 was cue leakage.

---

### `frequency_v2_q0278`

- **Primary dimension:** `boundary_firmness`
- **Triage reason codes:** `SD_DOMINANCE`, `OBVIOUS_TEST_ANSWER`, `SELF_PRESENTATION_HEAVY`
- **Phase 2B quality:** LOW
- **Question text:** Kendi kariyerin/ailenle ilgili bir konuyu anlatırken partnerin sürekli ne yapman gerektiği konusunda sana akıl veriyor.

**A.** `frequency_v2_q0278_a`
- text: Fikirlerini dikkate alır, objektif bir göz olduğu için söylediklerini faydalı bulurum.
- behavioral_weights: `{"adaptability": 1.0}`
- proposed evidence: social_desirability=1.00, obviousness=0.75, behavioral_plausibility=0.75, self_presentation_risk=1.00, diagnostic_value=0.25, ambiguity=0.25

**B.** `frequency_v2_q0278_b`
- text: "Sadece dinlemeni istemiştim, tavsiye istemedim" diyerek net bir şekilde sınırımı çizerim.
- behavioral_weights: `{"boundary_firmness": 2.0, "autonomy": 1.0}`
- proposed evidence: social_desirability=0.75, obviousness=1.00, behavioral_plausibility=0.75, self_presentation_risk=1.00, diagnostic_value=1.00, ambiguity=0.25

**C.** `frequency_v2_q0278_c`
- text: Tavsiyelerine uyuyormuş gibi görünür ama sonunda yine tamamen kendi bildiğimi okurum.
- behavioral_weights: `{"autonomy": 2.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.75, self_presentation_risk=0.25, diagnostic_value=0.25, ambiguity=0.75

**D.** `frequency_v2_q0278_d`
- text: Eleştirildiğimi hisseder ve savunmaya geçerek onun tavsiyelerinin neden işe yaramayacağını tartışırım.
- behavioral_weights: `{"boundary_firmness": 1.0, "reassurance_need": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.75, self_presentation_risk=0.25, diagnostic_value=0.50, ambiguity=0.25

**ISSUE ANALYSIS**

A (grateful for 'objective' advice) and B (textbook 'just listen' boundary) are both socially coded. Proposed scores already put A at SD/SPR 1.00 and B at obviousness 1.00. Keep those priors; do not treat B as the mature answer.

**RECOMMENDATION:** `KEEP_SCORES`

---

### `frequency_v2_q0317`

- **Primary dimension:** `repair_style`
- **Triage reason codes:** `PRIMARY_AXIS_CONFUSION`, `LOW_DIAGNOSTIC_CONTRAST`
- **Phase 2B quality:** LOW
- **Question text:** Bir tartışma sonrası partneriniz “biraz düşünmem lazım” deyip ortamdan ayrıldı.

**A.** `frequency_v2_q0317_a`
- text: Alan tanırım.
- behavioral_weights: `{"autonomy": 1.0, "adaptability": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.25, self_presentation_risk=0.25, diagnostic_value=0.25, ambiguity=0.50

**B.** `frequency_v2_q0317_b`
- text: Ne kadar süreceğini sorarım.
- behavioral_weights: `{"reassurance_need": 1.0, "structure_preference": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=1.00, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25

**C.** `frequency_v2_q0317_c`
- text: Kısa bir mesaj atarım.
- behavioral_weights: `{"contact_need": 1.0, "initiative": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.25, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.50

**D.** `frequency_v2_q0317_d`
- text: Ben de kendi alanıma çekilirim.
- behavioral_weights: `{"autonomy": 2.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=1.00, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25

**ISSUE ANALYSIS**

After a fight, partner asks for space. Options (give space / ask how long / text / withdraw too) are interpretable, but none carry repair_style. Evidence scoring cannot measure repair engagement from autonomy/contact weights.

**RECOMMENDATION:** `REWRITE_REQUIRED`

Evidence scoring alone cannot fix this. Do not rewrite in Phase 2D.

---

### `frequency_v2_q0332`

- **Primary dimension:** `adaptability`
- **Triage reason codes:** `CULTURAL_DEPENDENCE`
- **Phase 2B quality:** LOW
- **Question text:** Partneriniz sizi kendi ailesinin bir özel gününe davet etti. Siz o gün başka bir taahhüt vermiştiniz.

**A.** `frequency_v2_q0332_a`
- text: Planımı bozar, giderim.
- behavioral_weights: `{"adaptability": 2.0, "social_energy": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.25, self_presentation_risk=0.25, diagnostic_value=0.75, ambiguity=0.50

**B.** `frequency_v2_q0332_b`
- text: “Bu sefer olmaz” derim.
- behavioral_weights: `{"boundary_firmness": 1.0, "autonomy": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.25, self_presentation_risk=0.25, diagnostic_value=0.00, ambiguity=0.50

**C.** `frequency_v2_q0332_c`
- text: Kısa uğrayıp çıkarım.
- behavioral_weights: `{"adaptability": 1.0, "boundary_firmness": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.25, self_presentation_risk=0.25, diagnostic_value=0.50, ambiguity=0.50

**D.** `frequency_v2_q0332_d`
- text: Alternatif bir zaman öneririm.
- behavioral_weights: `{"initiative": 1.0, "structure_preference": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=1.00, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25

**ISSUE ANALYSIS**

Near-duplicate scenario of q0227 (family event vs existing commitment). Same adaptability contrast; same stub-plausibility overflag. Cultural loading is real but does not make the four choices unreadable.

**RECOMMENDATION:** `ADJUST_EVIDENCE_ONLY`

Proposed evidence adjustments (fields that should change only):

- `frequency_v2_q0332_a` `behavioral_plausibility`: 0.25 → 0.75 — Ordinary plan-drop to attend.
- `frequency_v2_q0332_b` `behavioral_plausibility`: 0.25 → 0.75 — Ordinary decline.
- `frequency_v2_q0332_c` `behavioral_plausibility`: 0.25 → 0.75 — Ordinary short visit.
- `frequency_v2_q0332_b` `diagnostic_value`: 0.00 → 0.50 — Clear non-adapting pole versus A.

---

### `frequency_v2_q0375`

- **Primary dimension:** `autonomy`
- **Triage reason codes:** `LOW_PLAUSIBILITY`
- **Phase 2B quality:** LOW
- **Question text:** Partnerin sana "Birlikte bir kafe/girişim açalım, hem beraber çalışır hem kazanırız" fikriyle geldi.

**A.** `frequency_v2_q0375_a`
- text: Fikre bayılırım, ilişkimizi profesyonel bir üretime dönüştürmek beni çok heyecanlandırır.
- behavioral_weights: `{"closeness_pace": 2.0, "uncertainty_tolerance": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25

**B.** `frequency_v2_q0375_b`
- text: Kesinlikle reddederim. İlişkiyle iş hayatının birbirine karışması bence her zaman felaketle sonuçlanır.
- behavioral_weights: `{"boundary_firmness": 2.0, "autonomy": 2.0}`
- proposed evidence: social_desirability=0.25, obviousness=0.50, behavioral_plausibility=0.50, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25

**C.** `frequency_v2_q0375_c`
- text: "Riskleri, iş planını, görev dağılımını kağıda dökelim, ona göre karar verelim" diyerek süreci analitikleştiririm.
- behavioral_weights: `{"structure_preference": 2.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.00, ambiguity=0.25

**D.** `frequency_v2_q0375_d`
- text: "Sen kur, ben sana dışarıdan destek olurum" diyerek inisiyatifi ona bırakır ama bağımı koparmam.
- behavioral_weights: `{"autonomy": 1.0, "initiative": -1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.75

**ISSUE ANALYSIS**

Option B uses hyperbolic 'her zaman felaketle sonuçlanır', so Phase 2C marked low plausibility. It is a strong but realistic refuse-to-mix-work-and-relationship stance, not a cartoon. C is off-primary (structure) with DV 0.00 — leave that.

**RECOMMENDATION:** `ADJUST_EVIDENCE_ONLY`

Proposed evidence adjustments (fields that should change only):

- `frequency_v2_q0375_b` `behavioral_plausibility`: 0.50 → 0.75 — Forceful wording, but a believable hard no on mixing business and the relationship.

---

### `frequency_v2_q0377`

- **Primary dimension:** `adaptability`
- **Triage reason codes:** `CULTURAL_DEPENDENCE`
- **Phase 2B quality:** LOW
- **Question text:** Çok lüks bir restoranda yemeğinizi yediniz, hesap geldi ve partnerin cüzdanını/kartını evde unuttuğunu fark etti.

**A.** `frequency_v2_q0377_a`
- text: "Yine mi dikkatsizlik!" diye ufak bir sitem eder, hesabı ben öderim ama dönüşte söylenirim.
- behavioral_weights: `{"boundary_firmness": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.75

**B.** `frequency_v2_q0377_b`
- text: Güler geçerim, "Bugünlük benden olsun" diyerek hesabı öder ve geceye hiç bozmadan devam ederim.
- behavioral_weights: `{"uncertainty_tolerance": 2.0, "adaptability": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.75, ambiguity=0.25

**C.** `frequency_v2_q0377_c`
- text: Sessizce hesabı öderim ama bunu yaparken kendimi kullanılmış/önemsenmemiş hissetme ihtimalim yüksektir.
- behavioral_weights: `{"reassurance_need": 2.0, "disclosure_pace": -2.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.75

**D.** `frequency_v2_q0377_d`
- text: Hesabı öderim ama "Yarı yarıya olacaktı, eve gidince atarsın" diyerek baştaki adalet/yapı planına sadık kalırım.
- behavioral_weights: `{"structure_preference": 2.0, "boundary_firmness": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.75

**ISSUE ANALYSIS**

Forgotten wallet at a luxury restaurant is culturally loaded (who pays, fairness, being 'used'). Named primary is adaptability, but only B carries a small adaptability weight; others are boundary, reassurance, and structure. Scoring cannot turn a money-fairness scene into an adaptability item.

**RECOMMENDATION:** `REWRITE_REQUIRED`

Evidence scoring alone cannot fix this. Do not rewrite in Phase 2D.

---

### `frequency_v2_q0393`

- **Primary dimension:** `adaptability`
- **Triage reason codes:** `PRIMARY_AXIS_CONFUSION`, `LOW_DIAGNOSTIC_CONTRAST`
- **Phase 2B quality:** LOW
- **Question text:** Şık giyindiniz, yürüyerek bir davete gidiyorsunuz. Birden sağanak yağmur bastırdı ve şemsiye yok.

**A.** `frequency_v2_q0393_a`
- text: Sinir krizi geçiririm, saçım/başım bozuldu diye tüm geceyi partnerime zehir edebilirim.
- behavioral_weights: `{"uncertainty_tolerance": -2.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25

**B.** `frequency_v2_q0393_b`
- text: Gülmeye başlarım, partnerimin elinden tutup sırılsıklam olana kadar yağmurda koşarım.
- behavioral_weights: `{"uncertainty_tolerance": 2.0, "closeness_pace": 2.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25

**C.** `frequency_v2_q0393_c`
- text: Anında bir saçak altı bulur, en yakın mağazadan şemsiye almak veya taksi çağırmak için fırlarım.
- behavioral_weights: `{"initiative": 2.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25

**D.** `frequency_v2_q0393_d`
- text: "Geri dönelim, üstümüzü değiştirip bir daha çıkarız" diyerek planı pratik şekilde baştan kurarım.
- behavioral_weights: `{"structure_preference": 2.0, "boundary_firmness": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.25, ambiguity=0.25

**ISSUE ANALYSIS**

Rain-on-the-way-to-an-event is a strong adaptability scene in the text, but weights sit on uncertainty, closeness, initiative, and structure — none on adaptability. All four diagnostic_value=0.25 because they are off-primary. Evidence scoring cannot re-author the axis.

**RECOMMENDATION:** `REWRITE_REQUIRED`

Evidence scoring alone cannot fix this. Do not rewrite in Phase 2D.

---

### `frequency_v2_q0409`

- **Primary dimension:** `repair_style`
- **Triage reason codes:** `PRIMARY_AXIS_CONFUSION`, `LOW_DIAGNOSTIC_CONTRAST`
- **Phase 2B quality:** LOW
- **Question text:** Bir tartışma sonrası partneriniz “biraz yalnız kalmam lazım” dedi ve odasına çekildi.

**A.** `frequency_v2_q0409_a`
- text: Alan tanırım.
- behavioral_weights: `{"autonomy": 1.0, "adaptability": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.25, self_presentation_risk=0.25, diagnostic_value=0.25, ambiguity=0.50

**B.** `frequency_v2_q0409_b`
- text: Ne kadar süreceğini sorarım.
- behavioral_weights: `{"reassurance_need": 1.0, "structure_preference": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25

**C.** `frequency_v2_q0409_c`
- text: Kapıdan kısa bir “yanındayım” derim.
- behavioral_weights: `{"contact_need": 1.0, "initiative": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25

**D.** `frequency_v2_q0409_d`
- text: Ben de kendi alanıma çekilirim.
- behavioral_weights: `{"autonomy": 2.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.50, behavioral_plausibility=0.75, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25

**ISSUE ANALYSIS**

Partner withdraws after a fight. Options are space / ask duration / 'I'm here' / withdraw too. Readable behaviors, but none carry repair_style. Same class as q0317. Scoring cannot supply the missing primary.

**RECOMMENDATION:** `REWRITE_REQUIRED`

Evidence scoring alone cannot fix this. Do not rewrite in Phase 2D.

---

### `frequency_v2_q0410`

- **Primary dimension:** `closeness_pace`
- **Triage reason codes:** `CULTURAL_DEPENDENCE`
- **Phase 2B quality:** LOW
- **Question text:** Yeni biriyle birkaç görüşme yaptınız. O sizi kendi ailesiyle tanıştırmayı teklif ediyor.

**A.** `frequency_v2_q0410_a`
- text: Kabul ederim.
- behavioral_weights: `{"closeness_pace": 1.0, "adaptability": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.25, self_presentation_risk=0.25, diagnostic_value=0.50, ambiguity=0.50

**B.** `frequency_v2_q0410_b`
- text: “Biraz erken” derim.
- behavioral_weights: `{"boundary_firmness": 1.0, "closeness_pace": -1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.50, self_presentation_risk=0.25, diagnostic_value=0.50, ambiguity=0.50

**C.** `frequency_v2_q0410_c`
- text: “Önce ikimiz netleşelim” derim.
- behavioral_weights: `{"reassurance_need": 1.0, "structure_preference": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.75, behavioral_plausibility=1.00, self_presentation_risk=0.50, diagnostic_value=0.50, ambiguity=0.25

**D.** `frequency_v2_q0410_d`
- text: Ertelemeyi öneririm.
- behavioral_weights: `{"uncertainty_tolerance": 1.0, "boundary_firmness": 1.0}`
- proposed evidence: social_desirability=0.50, obviousness=0.25, behavioral_plausibility=0.50, self_presentation_risk=0.25, diagnostic_value=0.25, ambiguity=0.50

**ISSUE ANALYSIS**

Early family introduction is culturally loaded. A ('Kabul ederim') is a stub; B/D both slow the pace ('biraz erken' / 'Ertelemeyi öneririm') with little semantic contrast. Scoring cannot separate those slowing options.

**RECOMMENDATION:** `REWRITE_REQUIRED`

Evidence scoring alone cannot fix this. Do not rewrite in Phase 2D.

---

## 2. Ten suspect ±1 low-diagnostic_value options

These are the Phase 2C sample rows with `diagnostic_value` ≤ 0.25 and judgment `WEIGHT_MAGNITUDE_OR_CUE_LEAKAGE`. ±2 is not assumed to be more diagnostic than ±1. Judge the option text.

### `frequency_v2_q0001_c`

- question_id: `frequency_v2_q0001`
- option_text: Dünkü buluşmanın keyifli olduğunu belirten net, kısa bir mesaj atarım.
- primary_dimension: `initiative`
- primary_weight: +1
- current diagnostic_value: 0.25
- ambiguity: 0.25
- behavioral_plausibility: 0.75
- behavioral_weights: `{"initiative": 1.0, "disclosure_pace": 1.0}`

**Classification:** `DV_TOO_LOW`

**Revised diagnostic_value:** 0.25 → 0.75

A short, specific first-contact message is a clear milder initiative pole versus waiting (B) or steering with a joke (A). Low DV is cue/magnitude leakage, not weak text.

---

### `frequency_v2_q0006_c`

- question_id: `frequency_v2_q0006`
- option_text: Benzer hissettiğimizi eylemlerinden görüyorsam konuşulmaması beni rahatsız etmez.
- primary_dimension: `uncertainty_tolerance`
- primary_weight: +1
- current diagnostic_value: 0.25
- ambiguity: 0.25
- behavioral_plausibility: 0.75
- behavioral_weights: `{"reassurance_need": -1.0, "uncertainty_tolerance": 1.0}`

**Classification:** `DV_TOO_LOW`

**Revised diagnostic_value:** 0.25 → 0.50

Tolerating an unlabeled relationship if actions already match is a distinct +1 uncertainty reading versus needing a talk (A) or waiting for them to open (D).

---

### `frequency_v2_q0018_b`

- question_id: `frequency_v2_q0018`
- option_text: Sadece ilk adımı kabaca belirler, geri kalanını netleşince düşünürüm.
- primary_dimension: `uncertainty_tolerance`
- primary_weight: +1
- current diagnostic_value: 0.25
- ambiguity: 0.25
- behavioral_plausibility: 0.75
- behavioral_weights: `{"uncertainty_tolerance": 1.0}`

**Classification:** `DV_TOO_LOW`

**Revised diagnostic_value:** 0.25 → 0.75

Lock only the first step and leave the rest is the textbook milder uncertainty pole between leaving the topic open (+2) and needing same-day numbers (−2).

---

### `frequency_v2_q0062_d`

- question_id: `frequency_v2_q0062`
- option_text: Kendi alternatif planıma geçerim, fazla üstünde durmam.
- primary_dimension: `adaptability`
- primary_weight: +1
- current diagnostic_value: 0.25
- ambiguity: 0.25
- behavioral_plausibility: 0.75
- behavioral_weights: `{"autonomy": 2.0, "adaptability": 1.0}`

**Classification:** `DV_JUSTIFIED`

Text is mostly switching to a solo plan (autonomy +2). It does not adapt the shared plan, so diagnostic_value 0.25 for adaptability is fair.

---

### `frequency_v2_q0082_b`

- question_id: `frequency_v2_q0082`
- option_text: İptal olursa kendi planıma geçerim.
- primary_dimension: `uncertainty_tolerance`
- primary_weight: +1
- current diagnostic_value: 0.25
- ambiguity: 0.25
- behavioral_plausibility: 1.00
- behavioral_weights: `{"autonomy": 2.0, "uncertainty_tolerance": 1.0}`

**Classification:** `DV_TOO_LOW`

**Revised diagnostic_value:** 0.25 → 0.50

Keeping a backup if the maybe-cancel happens is a real +1 uncertainty reading versus pinning it down now (A). Residual autonomy mix keeps it at 0.50, not 0.75.

---

### `frequency_v2_q0101_c`

- question_id: `frequency_v2_q0101`
- option_text: “Dün güzeldi” gibi kısa ve net bir mesaj gönderirim.
- primary_dimension: `initiative`
- primary_weight: +1
- current diagnostic_value: 0.25
- ambiguity: 0.25
- behavioral_plausibility: 0.75
- behavioral_weights: `{"initiative": 1.0, "disclosure_pace": 1.0}`

**Classification:** `DV_TOO_LOW`

**Revised diagnostic_value:** 0.25 → 0.75

Same pattern as q0001 C: a short 'dün güzeldi' ping is a clear milder initiative act, not a weak signal.

---

### `frequency_v2_q0105_c`

- question_id: `frequency_v2_q0105`
- option_text: Kendi planımı yapar, isterse bana katılmasını söylerim.
- primary_dimension: `initiative`
- primary_weight: +1
- current diagnostic_value: 0.25
- ambiguity: 0.50
- behavioral_plausibility: 0.75
- behavioral_weights: `{"autonomy": 2.0, "initiative": 1.0}`

**Classification:** `DV_TOO_LOW`

**Revised diagnostic_value:** 0.25 → 0.50

Making my own plan and inviting them is a readable initiative move versus offering couple-options (A) or following them (D). Autonomy is co-present, so 0.50 not 0.75.

---

### `frequency_v2_q0129_c`

- question_id: `frequency_v2_q0129`
- option_text: Bir daha olmaması için birlikte hatırlatma/sistem kurmayı öneririm.
- primary_dimension: `repair_style`
- primary_weight: -1
- current diagnostic_value: 0.25
- ambiguity: 0.25
- behavioral_plausibility: 0.75
- behavioral_weights: `{"structure_preference": 2.0, "repair_style": -1.0}`

**Classification:** `DV_JUSTIFIED`

A shared reminder system is structure_preference, not delayed repair. Low diagnostic_value on repair_style matches the text.

---

### `frequency_v2_q0133_d`

- question_id: `frequency_v2_q0133`
- option_text: Daha çok onun başlatmasına izin verir, müsait oldukça karşılık veririm.
- primary_dimension: `adaptability`
- primary_weight: +1
- current diagnostic_value: 0.25
- ambiguity: 0.25
- behavioral_plausibility: 0.75
- behavioral_weights: `{"initiative": -1.0, "adaptability": 1.0}`

**Classification:** `DV_JUSTIFIED`

Leaving initiation to them is mostly initiative −1. It does not increase contact toward the partner's request, so low adaptability diagnostic_value is fair.

---

### `frequency_v2_q0145_b`

- question_id: `frequency_v2_q0145`
- option_text: Bir daha unutulmaması için ortak bir hatırlatma sistemi kurmayı öneririm.
- primary_dimension: `repair_style`
- primary_weight: -1
- current diagnostic_value: 0.25
- ambiguity: 0.25
- behavioral_plausibility: 0.75
- behavioral_weights: `{"structure_preference": 2.0, "repair_style": -1.0}`

**Classification:** `DV_JUSTIFIED`

Same as q0129 C: a reminder system is a structural fix, not a repair-pacing signal. Keep 0.25.

---

## Counts

Question recommendations:

- `KEEP_SCORES`: **7**
- `ADJUST_EVIDENCE_ONLY`: **12**
- `REWRITE_REQUIRED`: **10**
- `DROP_FROM_SELECTABLE`: **0**

±1 diagnostic_value sample:

- `DV_JUSTIFIED`: **4**
- `DV_TOO_LOW`: **6**

## Safety

- Phase 2B proposal JSON not modified
- Phase 2C triage not modified
- Dormant pool not modified
- Question/option text not modified
- Behavioral weights not modified
- DROP options not scored
- V2 remains dormant
- No V1 / Firebase / matching / Persona / Discover / C2 change

FREQUENCY V2 PHASE 2D HUMAN EVIDENCE DECISION PACKET READY — NO VALUES APPLIED
