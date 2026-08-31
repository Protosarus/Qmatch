# Frequency V2 EN Human Review — 051–100

**Status:** machine-generated triage — NOT human-reviewed
**Translation version:** `frequency_v2_en_semantic_v1`
**Items:** 50

---

## frequency_v2_q0051

- **primary_dimension:** `initiative`
- **semantic_cluster:** `initiative:early_dating`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Yeni tanıştığın biriyle birkaç gündür yazışıyorsunuz. Konuşma akıyor ama henüz buluşma teklifi gelmedi.

**EN:** You've been texting someone you recently met for a few days. The conversation flows, but no one has suggested meeting up yet.

### Options

#### `frequency_v2_q0051_a`
- **TR:** Birkaç gün daha beklerim, o önersin.
- **EN:** Wait a few more days and let them suggest it.
- **behavioral_weights:** `{"initiative": -2.0, "autonomy": 1.0, "uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0051_b`
- **TR:** Doğrudan “bu hafta sonu uygun musun?” diye sorarım.
- **EN:** Ask directly: "Are you free this weekend?"
- **behavioral_weights:** `{"initiative": 2.0, "contact_need": 1.0}`

#### `frequency_v2_q0051_c`
- **TR:** Hafif bir ipucu bırakırım, tepkiye göre ilerlerim.
- **EN:** I'd drop a subtle hint and see how they respond.
- **behavioral_weights:** `{"initiative": 1.0, "adaptability": 1.0}`

#### `frequency_v2_q0051_d`
- **TR:** Tempo yavaşsa ben de yavaşlarım, acele etmem.
- **EN:** If the pace is slow, I slow down too — I don't rush.
- **behavioral_weights:** `{"closeness_pace": -1.0, "uncertainty_tolerance": 1.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0052

- **primary_dimension:** `reassurance_need`
- **semantic_cluster:** `reassurance_need:early_dating`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Bir süredir görüştüğün kişi son iki gündür eskisi kadar sık yazmıyor.

**EN:** Someone you've been seeing hasn't been texting as often the last two days.

### Options

#### `frequency_v2_q0052_a`
- **TR:** “Bir şey mi oldu?” diye sorarım.
- **EN:** Ask "Did something happen?"
- **behavioral_weights:** `{"reassurance_need": 2.0, "contact_need": 1.0}`

#### `frequency_v2_q0052_b`
- **TR:** Ben de aynı tempoya geçerim, zorlamam.
- **EN:** Match their pace — I won't push.
- **behavioral_weights:** `{"autonomy": 2.0, "uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0052_c`
- **TR:** Normal hayatımda devam ederim, aklıma gelince yazarım.
- **EN:** Carry on with my normal life and text when they cross my mind.
- **behavioral_weights:** `{"autonomy": 1.0, "contact_need": -1.0}`

#### `frequency_v2_q0052_d`
- **TR:** Kısa bir “nasılsın” atıp durumu yoklarım.
- **EN:** Send a quick "how are you?" and gauge the situation.
- **behavioral_weights:** `{"initiative": 1.0, "reassurance_need": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0053

- **primary_dimension:** `disclosure_pace`
- **semantic_cluster:** `disclosure_pace:early_dating`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** İlk buluşmada sohbet derinleşiyor. Karşı taraf kişisel bir şeyler anlatmaya başlıyor.

**EN:** On a first date, the conversation gets deeper and they start sharing personal things.

### Options

#### `frequency_v2_q0053_a`
- **TR:** Ben de benzer derinlikte karşılık veririm.
- **EN:** I'd share something at a similar level of depth.
- **behavioral_weights:** `{"disclosure_pace": 2.0, "closeness_pace": 1.0}`

#### `frequency_v2_q0053_b`
- **TR:** Dinlerim ama kendimden o kadarını hemen paylaşmam.
- **EN:** Listen, but I wouldn't share that much about myself right away.
- **behavioral_weights:** `{"disclosure_pace": -1.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0053_c`
- **TR:** Konuyu biraz daha yüzeyde tutmaya çalışırım.
- **EN:** Try to keep things a bit more surface-level.
- **behavioral_weights:** `{"disclosure_pace": -2.0, "autonomy": 1.0}`

#### `frequency_v2_q0053_d`
- **TR:** Merak ederim, soru sorarak devam ettiririm ama kendi payım sınırlı kalır.
- **EN:** I'd stay curious and ask questions to keep it going, but keep what I share about myself limited.
- **behavioral_weights:** `{"disclosure_pace": 0.0, "initiative": 1.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0054

- **primary_dimension:** `uncertainty_tolerance`
- **semantic_cluster:** `uncertainty_tolerance:planning`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Hafta sonu için net bir plan yapmadınız. Cumartesi öğleden sonra hâlâ belirsiz.

**EN:** You didn't make a clear plan for the weekend. It's Saturday afternoon and you still haven't decided what to do.

### Options

#### `frequency_v2_q0054_a`
- **TR:** “Ne yapalım?” diye sorup netleştiririm.
- **EN:** Ask "What should we do?" and get it sorted.
- **behavioral_weights:** `{"structure_preference": 1.0, "initiative": 1.0, "uncertainty_tolerance": -1.0}`

#### `frequency_v2_q0054_b`
- **TR:** Kendi planımı yaparım, o ararsa katılırım.
- **EN:** Make my own plans — I'll join if they reach out.
- **behavioral_weights:** `{"autonomy": 2.0, "structure_preference": -1.0}`

#### `frequency_v2_q0054_c`
- **TR:** Spontane bir şeyler çıkar diye beklerim.
- **EN:** Wait for something spontaneous to come up.
- **behavioral_weights:** `{"uncertainty_tolerance": 2.0, "structure_preference": -1.0}`

#### `frequency_v2_q0054_d`
- **TR:** Birkaç seçenek öneririm, seçmesini isterim.
- **EN:** Suggest a few options and let them pick.
- **behavioral_weights:** `{"initiative": 1.0, "adaptability": 1.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0055

- **primary_dimension:** `social_energy`
- **semantic_cluster:** `social_energy:social`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Birlikte olduğunuzda karşı tarafın arkadaş grubuyla bir akşam planı çıkıyor.

**EN:** While you're together, a plan comes up to spend the evening with their group of friends.

### Options

#### `frequency_v2_q0055_a`
- **TR:** Katılırım, yeni insanlarla olmak bana iyi gelir.
- **EN:** I'd go — meeting new people energizes me.
- **behavioral_weights:** `{"social_energy": 2.0, "adaptability": 1.0}`

#### `frequency_v2_q0055_b`
- **TR:** “Bu sefer olmaz” derim, ikili zaman tercih ederim.
- **EN:** I'd say "not this time" — I'd rather spend time one-on-one.
- **behavioral_weights:** `{"social_energy": -2.0, "autonomy": 1.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0055_c`
- **TR:** Katılırım ama erken ayrılma seçeneğimi açık tutarım.
- **EN:** I'd go, but keep open the option of leaving early.
- **behavioral_weights:** `{"social_energy": 1.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0055_d`
- **TR:** “Sen git, ben kendi işime bakarım” derim.
- **EN:** Say "you go — I'll do my own thing."
- **behavioral_weights:** `{"autonomy": 2.0, "social_energy": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0056

- **primary_dimension:** `repair_style`
- **semantic_cluster:** `repair_style:conflict`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Tartışma çıktı. Konu netleşmedi ama gerginlik var.

**EN:** An argument broke out. The issue isn't resolved, but there's tension in the air.

### Options

#### `frequency_v2_q0056_a`
- **TR:** Duygularımızı konuşmadan rahat edemem.
- **EN:** I can't relax until we've talked through how we feel.
- **behavioral_weights:** `{"repair_style": 2.0, "reassurance_need": 1.0}`

#### `frequency_v2_q0056_b`
- **TR:** Pratik bir çözüm bulup konuyu kapatmayı tercih ederim.
- **EN:** I'd rather find a practical solution and move on.
- **behavioral_weights:** `{"repair_style": -2.0, "structure_preference": 1.0}`

#### `frequency_v2_q0056_c`
- **TR:** Bir süre sessiz kalıp sakinleşmesini beklerim.
- **EN:** Stay quiet awhile and wait for things to calm down.
- **behavioral_weights:** `{"uncertainty_tolerance": 1.0, "autonomy": 1.0}`

#### `frequency_v2_q0056_d`
- **TR:** “Şu an konuşmayalım, sonra döneriz” derim.
- **EN:** Say "let's not talk right now — we'll come back to it."
- **behavioral_weights:** `{"boundary_firmness": 1.0, "repair_style": 0.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0057

- **primary_dimension:** `reassurance_need`
- **semantic_cluster:** `reassurance_need:established`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Uzun zamandır görüştüğünüz bir ilişki. Karşı taraf bir süredir daha mesafeli.

**EN:** You're in a long-term relationship. They've been more distant for a while.

### Options

#### `frequency_v2_q0057_a`
- **TR:** Doğrudan “bir şey mi değişti?” diye sorarım.
- **EN:** Ask directly: "Has something changed?"
- **behavioral_weights:** `{"reassurance_need": 2.0, "initiative": 1.0}`

#### `frequency_v2_q0057_b`
- **TR:** Kendi alanımı genişletirim, o yaklaşırsa görürüm.
- **EN:** I'd give myself more space and see if they come closer.
- **behavioral_weights:** `{"autonomy": 2.0, "uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0057_c`
- **TR:** Daha fazla inisiyatif alıp yakınlaşmaya çalışırım.
- **EN:** Take more initiative and try to reconnect.
- **behavioral_weights:** `{"closeness_pace": 1.0, "initiative": 1.0}`

#### `frequency_v2_q0057_d`
- **TR:** Durumu kabullenir, kendi ritmime dönerim.
- **EN:** Accept it and return to my own rhythm.
- **behavioral_weights:** `{"autonomy": 1.0, "adaptability": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0058

- **primary_dimension:** `contact_need`
- **semantic_cluster:** `contact_need:early_dating`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Yeni bir eşleşme. İlk mesajlar karşılıklı ama tempo yavaş.

**EN:** You've just matched with someone. You're both messaging, but the pace is slow.

### Options

#### `frequency_v2_q0058_a`
- **TR:** Daha sık yazarak tempo yükseltmeye çalışırım.
- **EN:** Try to pick up the pace by texting more often.
- **behavioral_weights:** `{"contact_need": 2.0, "initiative": 1.0}`

#### `frequency_v2_q0058_b`
- **TR:** Onun temposuna uyum sağlarım.
- **EN:** I'd match their pace.
- **behavioral_weights:** `{"adaptability": 2.0, "contact_need": 0.0}`

#### `frequency_v2_q0058_c`
- **TR:** Birkaç gün ara verip sonra tekrar denerim.
- **EN:** I'd pause for a few days, then try again.
- **behavioral_weights:** `{"autonomy": 1.0, "uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0058_d`
- **TR:** Tempo böyleyse ilgimi kaybederim.
- **EN:** At this pace I start losing interest.
- **behavioral_weights:** `{"contact_need": 1.0, "uncertainty_tolerance": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0059

- **primary_dimension:** `social_energy`
- **semantic_cluster:** `social_energy:established`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Birlikte yaşadığınız bir dönemde partnerin arkadaşlarıyla uzun bir akşam yemeği planı var. Sen de davetlisin.

**EN:** While living together, your partner has a long dinner planned with friends. You're invited.

### Options

#### `frequency_v2_q0059_a`
- **TR:** Giderim, keyif alırım.
- **EN:** I'd go and enjoy it.
- **behavioral_weights:** `{"social_energy": 2.0}`

#### `frequency_v2_q0059_b`
- **TR:** “Bu sefer sen git” derim.
- **EN:** Say "you go this time."
- **behavioral_weights:** `{"autonomy": 2.0, "social_energy": -1.0}`

#### `frequency_v2_q0059_c`
- **TR:** Giderim ama belirli bir saatten sonra ayrılırım.
- **EN:** I'd go, but leave after a certain time.
- **behavioral_weights:** `{"boundary_firmness": 1.0, "social_energy": 1.0}`

#### `frequency_v2_q0059_d`
- **TR:** Alternatif bir ikili plan öneririm.
- **EN:** Suggest an alternative one-on-one plan.
- **behavioral_weights:** `{"initiative": 1.0, "structure_preference": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0060

- **primary_dimension:** `disclosure_pace`
- **semantic_cluster:** `disclosure_pace:early_dating`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Karşı taraf önemli bir kişisel konuyu (aile, geçmiş ilişki, korku) paylaştı.

**EN:** They shared something important and personal — family, a past relationship, a fear.

### Options

#### `frequency_v2_q0060_a`
- **TR:** Ben de benzer bir konuyu hemen açarım.
- **EN:** I'd open up about something similar right away.
- **behavioral_weights:** `{"disclosure_pace": 2.0}`

#### `frequency_v2_q0060_b`
- **TR:** Dinlerim, teşekkür ederim, kendi payımı daha sonra getiririm.
- **EN:** I'd listen, thank them for sharing, and share something of my own later.
- **behavioral_weights:** `{"disclosure_pace": -1.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0060_c`
- **TR:** Konuyu biraz daha açmasını isterim ama kendimden az bahsederim.
- **EN:** Ask them to open up more but say little about myself.
- **behavioral_weights:** `{"disclosure_pace": 0.0, "initiative": 1.0}`

#### `frequency_v2_q0060_d`
- **TR:** “Bunu paylaşman güzel” deyip konuyu yavaşça başka yere çekerim.
- **EN:** I'd say "I'm glad you shared that" and gently steer the conversation elsewhere.
- **behavioral_weights:** `{"disclosure_pace": -2.0, "autonomy": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0061

- **primary_dimension:** `structure_preference`
- **semantic_cluster:** `structure_preference:established`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Hafta içi akşamları genellikle ne yaparsınız net değil.

**EN:** You don't have a set routine for weekday evenings.

### Options

#### `frequency_v2_q0061_a`
- **TR:** Düzenli bir ritim oluşturmayı severim.
- **EN:** I like building a regular rhythm.
- **behavioral_weights:** `{"structure_preference": 2.0}`

#### `frequency_v2_q0061_b`
- **TR:** Her akşam farklı olsun isterim.
- **EN:** I want every evening to be different.
- **behavioral_weights:** `{"structure_preference": -2.0, "uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0061_c`
- **TR:** Bazen planlı, bazen boş bırakırım.
- **EN:** I'd plan some evenings and leave others open.
- **behavioral_weights:** `{"structure_preference": 0.0}`

#### `frequency_v2_q0061_d`
- **TR:** Karşı tarafın temposuna göre ayarlarım.
- **EN:** I adjust to their pace.
- **behavioral_weights:** `{"adaptability": 2.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0062

- **primary_dimension:** `adaptability`
- **semantic_cluster:** `adaptability:planning`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Bir planınız vardı. Son anda karşı taraf “bugün olmaz” dedi.

**EN:** You had plans. At the last minute they said "not today."

### Options

#### `frequency_v2_q0062_a`
- **TR:** Anlarım, yeni bir gün belirleriz.
- **EN:** I understand — we'll pick a new day.
- **behavioral_weights:** `{"adaptability": 2.0, "uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0062_b`
- **TR:** Biraz bozulurum, bunu belli ederim.
- **EN:** I'd be a little disappointed, and I'd let it show.
- **behavioral_weights:** `{"structure_preference": 1.0, "reassurance_need": 1.0}`

#### `frequency_v2_q0062_c`
- **TR:** “Tamam” derim ama bir dahaki sefere daha net plan isterim.
- **EN:** Say "okay" — but next time I want a clearer plan.
- **behavioral_weights:** `{"boundary_firmness": 1.0, "structure_preference": 1.0}`

#### `frequency_v2_q0062_d`
- **TR:** Kendi alternatif planıma geçerim, fazla üstünde durmam.
- **EN:** Switch to my own backup plan and don't dwell on it.
- **behavioral_weights:** `{"autonomy": 2.0, "adaptability": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0063

- **primary_dimension:** `uncertainty_tolerance`
- **semantic_cluster:** `uncertainty_tolerance:uncertainty`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** İlişki tanımlı değil. Birkaç aydır görüşüyorsunuz ama “ne olduğumuz” konuşulmadı.

**EN:** The relationship isn't defined. You've been seeing each other a few months but never talked about "what we are."

### Options

#### `frequency_v2_q0063_a`
- **TR:** Bir noktada netleştirmek isterim.
- **EN:** At some point, I'd want to clarify what we are.
- **behavioral_weights:** `{"uncertainty_tolerance": -2.0, "reassurance_need": 1.0}`

#### `frequency_v2_q0063_b`
- **TR:** Tanım olmadan da devam edebilirim.
- **EN:** I can keep going without a label.
- **behavioral_weights:** `{"uncertainty_tolerance": 2.0}`

#### `frequency_v2_q0063_c`
- **TR:** Duruma göre karar veririm, acele etmem.
- **EN:** Decide based on the situation — no rush.
- **behavioral_weights:** `{"uncertainty_tolerance": 1.0, "adaptability": 1.0}`

#### `frequency_v2_q0063_d`
- **TR:** Tanım yoksa yavaş yavaş geri çekilirim.
- **EN:** Without a label I slowly pull back.
- **behavioral_weights:** `{"uncertainty_tolerance": -1.0, "autonomy": 1.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0064

- **primary_dimension:** `repair_style`
- **semantic_cluster:** `repair_style:conflict`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Tartışma sonrası sessizlik oluştu.

**EN:** There's silence after an argument.

### Options

#### `frequency_v2_q0064_a`
- **TR:** İlk ben yazarım / konuşurum.
- **EN:** I'm the first to text or reach out.
- **behavioral_weights:** `{"initiative": 2.0, "repair_style": 1.0}`

#### `frequency_v2_q0064_b`
- **TR:** O yazana kadar beklerim.
- **EN:** I'd wait for them to reach out.
- **behavioral_weights:** `{"autonomy": 1.0, "uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0064_c`
- **TR:** Kısa bir “konuşalım mı?” atarım.
- **EN:** I'd send a quick "Want to talk?"
- **behavioral_weights:** `{"initiative": 1.0, "repair_style": 1.0}`

#### `frequency_v2_q0064_d`
- **TR:** Birkaç gün kendi alanımda kalırım.
- **EN:** Stay in my own space for a few days.
- **behavioral_weights:** `{"autonomy": 2.0, "repair_style": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0065

- **primary_dimension:** `adaptability`
- **semantic_cluster:** `adaptability:boundaries`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Partnerin seninle ilgili bir sınırını (zaman, konu, davranış) ilk kez net ifade etti.

**EN:** Your partner clearly expresses a boundary with you for the first time — about time, a topic, or a behavior.

### Options

#### `frequency_v2_q0065_a`
- **TR:** Hemen uyum sağlarım.
- **EN:** Adapt right away.
- **behavioral_weights:** `{"adaptability": 2.0}`

#### `frequency_v2_q0065_b`
- **TR:** Nedenini anlamaya çalışırım, sonra karar veririm.
- **EN:** Try to understand why, then decide.
- **behavioral_weights:** `{"initiative": 1.0, "disclosure_pace": 1.0}`

#### `frequency_v2_q0065_c`
- **TR:** Kendi sınırlarımı da hatırlatırım.
- **EN:** Remind them of my boundaries too.
- **behavioral_weights:** `{"boundary_firmness": 2.0}`

#### `frequency_v2_q0065_d`
- **TR:** Biraz zorlanırım ama saygı duyarım.
- **EN:** I'd find it a little difficult, but I'd respect it.
- **behavioral_weights:** `{"adaptability": 1.0, "boundary_firmness": 0.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0066

- **primary_dimension:** `social_energy`
- **semantic_cluster:** `social_energy:established`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Uzun bir günün ardından ikiniz de yorgunsunuz. Akşam nasıl geçsin?

**EN:** After a long day, you're both tired. How would you like to spend the evening?

### Options

#### `frequency_v2_q0066_a`
- **TR:** Birlikte sessizce evde kalmak isterim.
- **EN:** I'd like a quiet evening at home together.
- **behavioral_weights:** `{"social_energy": -1.0, "closeness_pace": 1.0}`

#### `frequency_v2_q0066_b`
- **TR:** Dışarı çıkıp biraz hava almak isterim.
- **EN:** I'd want to go out and get some air.
- **behavioral_weights:** `{"social_energy": 1.0}`

#### `frequency_v2_q0066_c`
- **TR:** Herkes kendi işine baksın, sonra birleşelim.
- **EN:** I'd rather we each do our own thing for a while, then reconnect.
- **behavioral_weights:** `{"autonomy": 2.0}`

#### `frequency_v2_q0066_d`
- **TR:** Kısa bir sohbet edip erken yatmak isterim.
- **EN:** I'd want a short chat and an early night.
- **behavioral_weights:** `{"structure_preference": 1.0, "contact_need": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0067

- **primary_dimension:** `closeness_pace`
- **semantic_cluster:** `closeness_pace:early_dating`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Yeni biriyle tanıştınız. İlk birkaç görüşmede fiziksel yakınlık konusu açılmadan ilerledi.

**EN:** You've started seeing someone new. The first few dates pass without the subject of physical closeness coming up.

### Options

#### `frequency_v2_q0067_a`
- **TR:** Tempo bana uyuyorsa beklerim.
- **EN:** If the pace suits me, I'll wait.
- **behavioral_weights:** `{"closeness_pace": -1.0, "uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0067_b`
- **TR:** Bir noktada ben açarım.
- **EN:** At some point I'll bring it up.
- **behavioral_weights:** `{"initiative": 2.0, "closeness_pace": 1.0}`

#### `frequency_v2_q0067_c`
- **TR:** Karşı tarafın işaretlerini beklerim.
- **EN:** Wait for their signals.
- **behavioral_weights:** `{"adaptability": 1.0, "initiative": -1.0}`

#### `frequency_v2_q0067_d`
- **TR:** Fiziksel yakınlık yavaşsa duygusal olarak da yavaşlarım.
- **EN:** If physical closeness is moving slowly, I'd slow down emotionally too.
- **behavioral_weights:** `{"closeness_pace": -1.0, "disclosure_pace": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0068

- **primary_dimension:** `reassurance_need`
- **semantic_cluster:** `reassurance_need:established`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Partnerin bir süredir iş/stres nedeniyle daha az zaman ayırıyor.

**EN:** Your partner has less time for you because of work or stress.

### Options

#### `frequency_v2_q0068_a`
- **TR:** “Bana da ihtiyaç duyuyorum” diye söylerim.
- **EN:** Say "I need you too."
- **behavioral_weights:** `{"reassurance_need": 2.0, "contact_need": 1.0}`

#### `frequency_v2_q0068_b`
- **TR:** Anlarım, destek olurum, kendi işime bakarım.
- **EN:** Understand, support them, and focus on my own stuff.
- **behavioral_weights:** `{"autonomy": 1.0, "adaptability": 1.0}`

#### `frequency_v2_q0068_c`
- **TR:** Alternatif kısa temaslar öneririm.
- **EN:** I'd suggest shorter ways to stay in touch.
- **behavioral_weights:** `{"initiative": 1.0, "contact_need": 1.0}`

#### `frequency_v2_q0068_d`
- **TR:** Mesafe artarsa ben de uzaklaşırım.
- **EN:** If distance grows, I pull back too.
- **behavioral_weights:** `{"autonomy": 2.0, "uncertainty_tolerance": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0069

- **primary_dimension:** `structure_preference`
- **semantic_cluster:** `structure_preference:planning`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Birlikte bir tatil planlıyorsunuz. Detaylar henüz net değil.

**EN:** You're planning a vacation together. The details aren't clear yet.

### Options

#### `frequency_v2_q0069_a`
- **TR:** Erken plan yapıp her şeyi netleştirmek isterim.
- **EN:** Plan early and nail everything down.
- **behavioral_weights:** `{"structure_preference": 2.0, "uncertainty_tolerance": -1.0}`

#### `frequency_v2_q0069_b`
- **TR:** Genel çerçeve yeter, detaylar yerinde çıksın.
- **EN:** A general outline is enough — details can emerge on the spot.
- **behavioral_weights:** `{"structure_preference": -2.0, "uncertainty_tolerance": 2.0}`

#### `frequency_v2_q0069_c`
- **TR:** Ben birkaç seçenek hazırlarım, o seçer.
- **EN:** Prepare a few options and let them choose.
- **behavioral_weights:** `{"initiative": 1.0, "structure_preference": 1.0}`

#### `frequency_v2_q0069_d`
- **TR:** Onun planına uyarım.
- **EN:** Go along with their plan.
- **behavioral_weights:** `{"adaptability": 2.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0070

- **primary_dimension:** `autonomy`
- **semantic_cluster:** `autonomy:unclassified`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Partnerin yoğun bir dönemden geçiyor ve bu akşam yanında olmanın iyi geleceğini söylüyor. Senin de önceden yaptığın kişisel planların var. Ne yaparsın?

**EN:** Your partner is going through a busy period and says being with them tonight would help. You already have personal plans. What do you do?

### Options

#### `frequency_v2_q0070_a`
- **TR:** Kendi planımı sürdürür, daha sonra görüşmek için ayrı bir zaman ayarlarım.
- **EN:** Keep my plans and schedule a separate time to meet.
- **behavioral_weights:** `{"autonomy": 2.0}`

#### `frequency_v2_q0070_b`
- **TR:** Planımın bir kısmını korur, bir kısmını onunla geçiririm.
- **EN:** Keep part of my plan and spend part of the evening with them.
- **behavioral_weights:** `{"autonomy": 1.0}`

#### `frequency_v2_q0070_c`
- **TR:** Planımın çoğunu değiştirip akşamın büyük bölümünde yanında kalırım.
- **EN:** Change most of my plan and stay with them most of the evening.
- **behavioral_weights:** `{"autonomy": -1.0}`

#### `frequency_v2_q0070_d`
- **TR:** Kendi planımı tamamen bırakıp akşamı onunla geçiririm.
- **EN:** Drop my plans entirely and spend the evening with them.
- **behavioral_weights:** `{"autonomy": -2.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0071

- **primary_dimension:** `reassurance_need`
- **semantic_cluster:** `reassurance_need:early_dating`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** İlk birkaç mesajlaşma sonrası karşı taraf “sen nasılsın, günün nasıl geçti” tarzı sorular sormuyor.

**EN:** After your first few exchanges, they don't ask things like "How are you?" or "How was your day?"

### Options

#### `frequency_v2_q0071_a`
- **TR:** Ben sorarım, karşılıklılık beklerim.
- **EN:** I ask — I expect reciprocity.
- **behavioral_weights:** `{"contact_need": 1.0, "initiative": 1.0, "reassurance_need": 1.0}`

#### `frequency_v2_q0071_b`
- **TR:** Önemli değil, başka şekilde ilerleriz.
- **EN:** It doesn't matter — we can connect in other ways.
- **behavioral_weights:** `{"uncertainty_tolerance": 1.0, "adaptability": 1.0}`

#### `frequency_v2_q0071_c`
- **TR:** Ben de sormayı bırakırım.
- **EN:** I stop asking too.
- **behavioral_weights:** `{"autonomy": 1.0, "contact_need": -1.0}`

#### `frequency_v2_q0071_d`
- **TR:** Bu tarz ilgisizlik ilgimi azaltır.
- **EN:** That kind of lack of interest makes me less interested too.
- **behavioral_weights:** `{"contact_need": 2.0, "uncertainty_tolerance": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0072

- **primary_dimension:** `autonomy`
- **semantic_cluster:** `autonomy:established`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Birlikte yaşadığınız dönemde her ikinizin de ayrı sosyal planları çakışıyor.

**EN:** While living together, you both have separate social plans scheduled for the same time.

### Options

#### `frequency_v2_q0072_a`
- **TR:** Önceliği ortak zamana veririm.
- **EN:** Prioritize shared time.
- **behavioral_weights:** `{"closeness_pace": 1.0, "structure_preference": 1.0}`

#### `frequency_v2_q0072_b`
- **TR:** Herkes kendi planına gider.
- **EN:** We'd each go ahead with our own plans.
- **behavioral_weights:** `{"autonomy": 2.0, "social_energy": 0.0}`

#### `frequency_v2_q0072_c`
- **TR:** Birini iptal edip diğerine uyarım.
- **EN:** I'd cancel one plan and go with the other.
- **behavioral_weights:** `{"adaptability": 2.0}`

#### `frequency_v2_q0072_d`
- **TR:** Önceden konuşup dengelemeye çalışırım.
- **EN:** Talk ahead of time and try to balance.
- **behavioral_weights:** `{"initiative": 1.0, "structure_preference": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0073

- **primary_dimension:** `boundary_firmness`
- **semantic_cluster:** `boundary_firmness:conflict`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Tartışma sırasında karşı taraf sesini yükseltti.

**EN:** During an argument they raised their voice.

### Options

#### `frequency_v2_q0073_a`
- **TR:** Ben de yükselirim, eşitlenirim.
- **EN:** I'd raise my voice too and match their level.
- **behavioral_weights:** `{"repair_style": 0.0, "boundary_firmness": -1.0}`

#### `frequency_v2_q0073_b`
- **TR:** Sakin kalıp “bu şekilde konuşmayalım” derim.
- **EN:** Stay calm: "Let's not talk like this."
- **behavioral_weights:** `{"boundary_firmness": 2.0, "repair_style": 1.0}`

#### `frequency_v2_q0073_c`
- **TR:** Ortamı terk ederim.
- **EN:** I'd step away from the situation.
- **behavioral_weights:** `{"boundary_firmness": 1.0, "autonomy": 1.0}`

#### `frequency_v2_q0073_d`
- **TR:** Konuyu başka zamana ertelerim.
- **EN:** Postpone the topic to another time.
- **behavioral_weights:** `{"uncertainty_tolerance": 1.0, "repair_style": -1.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0074

- **primary_dimension:** `uncertainty_tolerance`
- **semantic_cluster:** `uncertainty_tolerance:early_dating`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Yeni biriyle birkaç haftadır görüşüyorsunuz. Henüz “sevgili” demediniz.

**EN:** You've been seeing someone new for a few weeks. You haven't called it a relationship yet.

### Options

#### `frequency_v2_q0074_a`
- **TR:** Bir noktada netleştirmek isterim.
- **EN:** At some point, I'd want to clarify what we are.
- **behavioral_weights:** `{"uncertainty_tolerance": -2.0, "reassurance_need": 1.0}`

#### `frequency_v2_q0074_b`
- **TR:** Akışa bırakırım.
- **EN:** Go with the flow.
- **behavioral_weights:** `{"uncertainty_tolerance": 2.0}`

#### `frequency_v2_q0074_c`
- **TR:** Davranışlardan anlarım, kelimeye gerek yok.
- **EN:** I read it from their behavior — no need for words.
- **behavioral_weights:** `{"uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0074_d`
- **TR:** Netlik yoksa daha fazla ilerlemem.
- **EN:** Without clarity I won't go further.
- **behavioral_weights:** `{"uncertainty_tolerance": -1.0, "boundary_firmness": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0075

- **primary_dimension:** `adaptability`
- **semantic_cluster:** `adaptability:conflict`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Partnerin senin bir davranışını eleştirdi (örneğin zaman yönetimi, iletişim tarzı).

**EN:** Your partner criticized something about you — like time management or communication style.

### Options

#### `frequency_v2_q0075_a`
- **TR:** Hemen değiştirmeye çalışırım.
- **EN:** Try to change right away.
- **behavioral_weights:** `{"adaptability": 2.0}`

#### `frequency_v2_q0075_b`
- **TR:** Nedenini sorar, kendi açımdan anlatırım.
- **EN:** Ask why and explain my side.
- **behavioral_weights:** `{"disclosure_pace": 1.0, "initiative": 1.0}`

#### `frequency_v2_q0075_c`
- **TR:** Kabul ederim ama değiştirmem.
- **EN:** Acknowledge it but don't change.
- **behavioral_weights:** `{"boundary_firmness": 2.0, "autonomy": 1.0}`

#### `frequency_v2_q0075_d`
- **TR:** Karşılıklı eleştiri alanını açarım.
- **EN:** I'd make it a two-way conversation where we can both raise criticisms.
- **behavioral_weights:** `{"boundary_firmness": 1.0, "initiative": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0076

- **primary_dimension:** `closeness_pace`
- **semantic_cluster:** `closeness_pace:uncertainty`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Uzun bir ayrılıktan (iş seyahati, aile) sonra yeniden bir araya geliyorsunuz.

**EN:** You're reuniting after a long time apart because of work travel or family.

### Options

#### `frequency_v2_q0076_a`
- **TR:** Hemen yoğun temas ve yakınlık isterim.
- **EN:** I want intense contact and closeness right away.
- **behavioral_weights:** `{"contact_need": 2.0, "closeness_pace": 1.0}`

#### `frequency_v2_q0076_b`
- **TR:** Yavaş yavaş alışırız.
- **EN:** We ease back in gradually.
- **behavioral_weights:** `{"closeness_pace": -1.0, "adaptability": 1.0}`

#### `frequency_v2_q0076_c`
- **TR:** Herkes önce kendi düzenine dönsün.
- **EN:** Everyone settles into their own routine first.
- **behavioral_weights:** `{"autonomy": 2.0}`

#### `frequency_v2_q0076_d`
- **TR:** Planlı bir “yeniden başlama” akşamı ayarlarım.
- **EN:** I'd plan a deliberate evening for us to reconnect.
- **behavioral_weights:** `{"structure_preference": 1.0, "initiative": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0077

- **primary_dimension:** `contact_need`
- **semantic_cluster:** `contact_need:established`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Bir akşam ikiniz de evdesiniz. Televizyon / telefon / sessizlik.

**EN:** You're both home one evening. TV, phones, silence.

### Options

#### `frequency_v2_q0077_a`
- **TR:** Konuşmak isterim.
- **EN:** I want to talk.
- **behavioral_weights:** `{"contact_need": 2.0, "closeness_pace": 1.0}`

#### `frequency_v2_q0077_b`
- **TR:** Sessizlik de güzeldir.
- **EN:** Silence is fine too.
- **behavioral_weights:** `{"autonomy": 1.0, "uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0077_c`
- **TR:** Birlikte bir şey izleyelim diye öneririm.
- **EN:** Suggest watching something together.
- **behavioral_weights:** `{"initiative": 1.0, "social_energy": 0.0}`

#### `frequency_v2_q0077_d`
- **TR:** Kendi işime bakarım.
- **EN:** Do my own thing.
- **behavioral_weights:** `{"autonomy": 2.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0078

- **primary_dimension:** `initiative`
- **semantic_cluster:** `initiative:planning`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Karşı taraf bir konuda karar vermekte zorlanıyor (nerede yemek, ne zaman buluşma).

**EN:** They're struggling to decide something — where to eat, when to meet.

### Options

#### `frequency_v2_q0078_a`
- **TR:** Ben karar veririm.
- **EN:** I decide.
- **behavioral_weights:** `{"initiative": 2.0}`

#### `frequency_v2_q0078_b`
- **TR:** Sabırla beklerim.
- **EN:** Wait patiently.
- **behavioral_weights:** `{"uncertainty_tolerance": 1.0, "adaptability": 1.0}`

#### `frequency_v2_q0078_c`
- **TR:** Seçenek sunarım.
- **EN:** Offer options.
- **behavioral_weights:** `{"initiative": 1.0, "adaptability": 1.0}`

#### `frequency_v2_q0078_d`
- **TR:** “Sen karar ver” deyip çekilirim.
- **EN:** Say "you decide" and step back.
- **behavioral_weights:** `{"autonomy": 1.0, "initiative": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0079

- **primary_dimension:** `initiative`
- **semantic_cluster:** `initiative:established`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** İlişkide bir süredir “her şey yolunda mı?” hissi var ama konuşulmuyor.

**EN:** For a while, you've had a sense that something might be off in the relationship, but neither of you has talked about it.

### Options

#### `frequency_v2_q0079_a`
- **TR:** Ben açarım.
- **EN:** I bring it up.
- **behavioral_weights:** `{"initiative": 2.0, "reassurance_need": 1.0}`

#### `frequency_v2_q0079_b`
- **TR:** O açarsa konuşuruz.
- **EN:** If they bring it up, we'll talk.
- **behavioral_weights:** `{"autonomy": 1.0, "uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0079_c`
- **TR:** Davranışlardan anlamaya çalışırım.
- **EN:** Try to read it from their behavior.
- **behavioral_weights:** `{"uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0079_d`
- **TR:** Yok sayıp devam ederim.
- **EN:** Ignore it and carry on.
- **behavioral_weights:** `{"uncertainty_tolerance": 1.0, "repair_style": -1.0}`

### Machine triage flags

- `possible_unnatural_english`

---

## frequency_v2_q0080

- **primary_dimension:** `initiative`
- **semantic_cluster:** `initiative:early_dating`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Yeni biriyle ilk buluşma sonrası “nasıl geçti” değerlendirmesi.

**EN:** After a first date with someone new, you're at the "How did that go?" stage.

### Options

#### `frequency_v2_q0080_a`
- **TR:** Hemen yazarım, iyi geçtiğini söylerim.
- **EN:** Text right away and say it went well.
- **behavioral_weights:** `{"contact_need": 1.0, "initiative": 2.0}`

#### `frequency_v2_q0080_b`
- **TR:** Bir gün beklerim.
- **EN:** Wait a day.
- **behavioral_weights:** `{"uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0080_c`
- **TR:** O yazarsa cevap veririm.
- **EN:** Reply if they text first.
- **behavioral_weights:** `{"initiative": -1.0, "adaptability": 1.0}`

#### `frequency_v2_q0080_d`
- **TR:** Tempo ne olursa olsun kendi hızımda ilerlerim.
- **EN:** Whatever the pace, I move at my own speed.
- **behavioral_weights:** `{"autonomy": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0081

- **primary_dimension:** `closeness_pace`
- **semantic_cluster:** `closeness_pace:early_dating`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Partnerin ailesi / yakın çevresiyle tanışma konusu açıldı.

**EN:** Meeting your partner's family or close circle came up.

### Options

#### `frequency_v2_q0081_a`
- **TR:** Erken olmasını isterim.
- **EN:** I'd want it sooner rather than later.
- **behavioral_weights:** `{"closeness_pace": 2.0}`

#### `frequency_v2_q0081_b`
- **TR:** Zamanı gelince olur.
- **EN:** When the time comes.
- **behavioral_weights:** `{"uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0081_c`
- **TR:** Ben hazır olunca olur.
- **EN:** When I'm ready.
- **behavioral_weights:** `{"boundary_firmness": 1.0, "autonomy": 1.0}`

#### `frequency_v2_q0081_d`
- **TR:** Çok acele etmeden, doğal aksın.
- **EN:** Let it happen naturally — no rush.
- **behavioral_weights:** `{"closeness_pace": -1.0, "adaptability": 1.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0082

- **primary_dimension:** `uncertainty_tolerance`
- **semantic_cluster:** `uncertainty_tolerance:planning`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Bir planınız var. Sen hazırlanıyorsun, karşı taraf “belki iptal ederiz” havası yaratıyor.

**EN:** You have plans. You're getting ready, but they're giving you the impression they might cancel.

### Options

#### `frequency_v2_q0082_a`
- **TR:** Netleştiririm.
- **EN:** I'd get a clear answer.
- **behavioral_weights:** `{"structure_preference": 1.0, "initiative": 1.0, "uncertainty_tolerance": -1.0}`

#### `frequency_v2_q0082_b`
- **TR:** İptal olursa kendi planıma geçerim.
- **EN:** If it cancels, I switch to my own plan.
- **behavioral_weights:** `{"autonomy": 2.0, "uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0082_c`
- **TR:** “Karar ver” diye baskı yaparım.
- **EN:** I'd push them to make a decision.
- **behavioral_weights:** `{"structure_preference": 1.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0082_d`
- **TR:** Esnek kalırım.
- **EN:** Stay flexible.
- **behavioral_weights:** `{"adaptability": 2.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0083

- **primary_dimension:** `repair_style`
- **semantic_cluster:** `repair_style:conflict`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Tartışma bitti ama içerde bir şey kaldı.

**EN:** The argument is over, but you still feel something has been left unresolved.

### Options

#### `frequency_v2_q0083_a`
- **TR:** Tekrar açarım.
- **EN:** Bring it up again.
- **behavioral_weights:** `{"repair_style": 2.0, "initiative": 1.0}`

#### `frequency_v2_q0083_b`
- **TR:** Zamanla geçer.
- **EN:** Time will take care of it.
- **behavioral_weights:** `{"uncertainty_tolerance": 1.0, "repair_style": -1.0}`

#### `frequency_v2_q0083_c`
- **TR:** Başka bir yolla (mesaj, not) ifade ederim.
- **EN:** Express it another way — a message or a note.
- **behavioral_weights:** `{"initiative": 1.0, "disclosure_pace": 1.0}`

#### `frequency_v2_q0083_d`
- **TR:** Unutup ileri bakarım.
- **EN:** Forget it and move on.
- **behavioral_weights:** `{"repair_style": -2.0, "autonomy": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0084

- **primary_dimension:** `boundary_firmness`
- **semantic_cluster:** `boundary_firmness:established`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Karşı taraf senin kişisel alanına (odan, zamanın, hobin) fazla giriyor gibi hissediyorsun.

**EN:** You feel they're encroaching on your personal space — your room, your time, your hobby.

### Options

#### `frequency_v2_q0084_a`
- **TR:** Direkt söylerim.
- **EN:** Say it directly.
- **behavioral_weights:** `{"boundary_firmness": 2.0}`

#### `frequency_v2_q0084_b`
- **TR:** Dolaylı yollarla belli ederim.
- **EN:** I'd make it clear indirectly.
- **behavioral_weights:** `{"boundary_firmness": 1.0, "adaptability": 0.0}`

#### `frequency_v2_q0084_c`
- **TR:** Kendim uzaklaşırım.
- **EN:** I'd create some distance myself.
- **behavioral_weights:** `{"autonomy": 2.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0084_d`
- **TR:** Alışmaya çalışırım.
- **EN:** Try to get used to it.
- **behavioral_weights:** `{"adaptability": 1.0, "boundary_firmness": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0085

- **primary_dimension:** `adaptability`
- **semantic_cluster:** `adaptability:social`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Hafta sonu için ikiniz de farklı şeyler istiyorsunuz (biri evde kalmak, diğeri dışarı).

**EN:** For the weekend you want different things — one of you wants to stay in, the other wants to go out.

### Options

#### `frequency_v2_q0085_a`
- **TR:** Orta yol buluruz.
- **EN:** Find middle ground.
- **behavioral_weights:** `{"adaptability": 1.0, "initiative": 1.0}`

#### `frequency_v2_q0085_b`
- **TR:** Bu sefer ben uyum sağlarım.
- **EN:** This time I'll adapt.
- **behavioral_weights:** `{"adaptability": 2.0}`

#### `frequency_v2_q0085_c`
- **TR:** Bu sefer o uyum sağlasın.
- **EN:** This time they should adapt.
- **behavioral_weights:** `{"boundary_firmness": 1.0, "autonomy": 1.0}`

#### `frequency_v2_q0085_d`
- **TR:** Ayrı plan yaparız.
- **EN:** Make separate plans.
- **behavioral_weights:** `{"autonomy": 2.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0086

- **primary_dimension:** `disclosure_pace`
- **semantic_cluster:** `disclosure_pace:early_dating`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Yeni biriyle konuşurken geçmiş ilişkilerden bahsetme konusu geldi.

**EN:** You're talking to someone new and past relationships come up.

### Options

#### `frequency_v2_q0086_a`
- **TR:** Açıkça anlatırım.
- **EN:** Share openly.
- **behavioral_weights:** `{"disclosure_pace": 2.0}`

#### `frequency_v2_q0086_b`
- **TR:** Genel hatlarıyla değinirim.
- **EN:** Touch on it in general terms.
- **behavioral_weights:** `{"disclosure_pace": 1.0}`

#### `frequency_v2_q0086_c`
- **TR:** “Şimdilik gerek yok” derim.
- **EN:** I'd say, "We don't need to get into that yet."
- **behavioral_weights:** `{"boundary_firmness": 1.0, "disclosure_pace": -2.0}`

#### `frequency_v2_q0086_d`
- **TR:** O anlatırsa dinlerim, kendimden az bahsederim.
- **EN:** If they share, I listen and say little about myself.
- **behavioral_weights:** `{"disclosure_pace": -1.0, "adaptability": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0087

- **primary_dimension:** `uncertainty_tolerance`
- **semantic_cluster:** `uncertainty_tolerance:early_dating`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Bir süredir görüştüğün kişi “yoğunum” diyerek planları erteliyor.

**EN:** Someone you've been seeing keeps postponing plans, saying they're busy.

### Options

#### `frequency_v2_q0087_a`
- **TR:** Anlarım, beklerim.
- **EN:** I'd understand and wait.
- **behavioral_weights:** `{"uncertainty_tolerance": 2.0, "adaptability": 1.0}`

#### `frequency_v2_q0087_b`
- **TR:** Ne kadar süreceğini sorarım.
- **EN:** Ask how long it'll last.
- **behavioral_weights:** `{"reassurance_need": 1.0, "structure_preference": 1.0}`

#### `frequency_v2_q0087_c`
- **TR:** Alternatif kısa buluşmalar öneririm.
- **EN:** Suggest shorter meet-ups.
- **behavioral_weights:** `{"initiative": 1.0, "contact_need": 1.0}`

#### `frequency_v2_q0087_d`
- **TR:** Tempo böyleyse yavaşlarım.
- **EN:** If that's the pace, I'd slow down too.
- **behavioral_weights:** `{"autonomy": 1.0, "contact_need": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0088

- **primary_dimension:** `repair_style`
- **semantic_cluster:** `repair_style:established`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** İlişkide bir konuda sürekli aynı tip anlaşmazlık yaşıyorsunuz.

**EN:** In your relationship you keep hitting the same type of disagreement.

### Options

#### `frequency_v2_q0088_a`
- **TR:** Köklü konuşma isterim.
- **EN:** I want a deep talk about it.
- **behavioral_weights:** `{"repair_style": 2.0, "disclosure_pace": 1.0}`

#### `frequency_v2_q0088_b`
- **TR:** Her seferinde pratik çözüm buluruz.
- **EN:** Find a practical fix each time.
- **behavioral_weights:** `{"repair_style": -1.0, "structure_preference": 1.0}`

#### `frequency_v2_q0088_c`
- **TR:** Konuyu kapatıp devam ederiz.
- **EN:** Close the topic and move on.
- **behavioral_weights:** `{"repair_style": -2.0}`

#### `frequency_v2_q0088_d`
- **TR:** Bu konu benim için sınırdır derim.
- **EN:** Say this is a boundary for me.
- **behavioral_weights:** `{"boundary_firmness": 2.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0089

- **primary_dimension:** `disclosure_pace`
- **semantic_cluster:** `disclosure_pace:early_dating`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Karşı taraf seninle ilgili olumlu bir şey hissettiğini (beğeni, özlem, bağlılık) ifade etti.

**EN:** They tell you they feel something positive toward you — that they like you, miss you, or feel attached.

### Options

#### `frequency_v2_q0089_a`
- **TR:** Ben de hemen karşılık veririm.
- **EN:** I reciprocate right away.
- **behavioral_weights:** `{"disclosure_pace": 1.0, "closeness_pace": 1.0, "reassurance_need": 0.0}`

#### `frequency_v2_q0089_b`
- **TR:** Teşekkür eder, kendi tempomda ilerlerim.
- **EN:** I'd thank them and keep going at my own pace.
- **behavioral_weights:** `{"disclosure_pace": -1.0, "autonomy": 1.0}`

#### `frequency_v2_q0089_c`
- **TR:** Biraz şaşırır, sindiririm.
- **EN:** A bit surprised — I need to absorb it.
- **behavioral_weights:** `{"uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0089_d`
- **TR:** Aynı dili kullanmadan davranışla gösteriririm.
- **EN:** Show it through behavior without matching their words.
- **behavioral_weights:** `{"disclosure_pace": 0.0, "adaptability": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0090

- **primary_dimension:** `autonomy`
- **semantic_cluster:** `autonomy:established`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Bir akşam sen dışarıdasın, partner evde. Geç saatte “ne zaman gelirsin” diye soruyor.

**EN:** You're out and your partner is home. Late at night they ask "when will you be home?"

### Options

#### `frequency_v2_q0090_a`
- **TR:** Net saat veririm.
- **EN:** Give a specific time.
- **behavioral_weights:** `{"structure_preference": 1.0, "reassurance_need": -1.0}`

#### `frequency_v2_q0090_b`
- **TR:** “Birazdan” derim.
- **EN:** Say "soon."
- **behavioral_weights:** `{"uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0090_c`
- **TR:** “Rahat ol, geliyorum” derim.
- **EN:** Say "relax, I'm on my way."
- **behavioral_weights:** `{"adaptability": 1.0, "contact_need": 1.0}`

#### `frequency_v2_q0090_d`
- **TR:** Cevap vermeden devam ederim, sonra yazarım.
- **EN:** I'd carry on without replying and text back later.
- **behavioral_weights:** `{"autonomy": 2.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0091

- **primary_dimension:** `initiative`
- **semantic_cluster:** `initiative:early_dating`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Yeni biriyle birkaç görüşme yaptınız. Bir sonraki adım net değil.

**EN:** You've had a few dates with someone new. The next step isn't clear.

### Options

#### `frequency_v2_q0091_a`
- **TR:** Ben öneririm.
- **EN:** I suggest something.
- **behavioral_weights:** `{"initiative": 2.0}`

#### `frequency_v2_q0091_b`
- **TR:** O önersin diye beklerim.
- **EN:** Wait for them to suggest.
- **behavioral_weights:** `{"initiative": -2.0, "uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0091_c`
- **TR:** “Ne düşünüyorsun?” diye sorarım.
- **EN:** Ask "What are you thinking?"
- **behavioral_weights:** `{"initiative": 1.0, "reassurance_need": 1.0}`

#### `frequency_v2_q0091_d`
- **TR:** Tempo yavaşsa ben de yavaşlarım.
- **EN:** If the pace is slow, I slow down too.
- **behavioral_weights:** `{"closeness_pace": -1.0, "adaptability": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0092

- **primary_dimension:** `autonomy`
- **semantic_cluster:** `autonomy:social`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Partnerin senin bir hobine / arkadaş grubuna katılmak istemediğini söyledi.

**EN:** Your partner said they don't want to join your hobby or friend group.

### Options

#### `frequency_v2_q0092_a`
- **TR:** Anlarım, ayrı yaparız.
- **EN:** Understand — we'll do it separately.
- **behavioral_weights:** `{"autonomy": 1.0, "boundary_firmness": 0.0, "adaptability": 1.0}`

#### `frequency_v2_q0092_b`
- **TR:** Bir kez denemesini isterim.
- **EN:** Ask them to try once.
- **behavioral_weights:** `{"initiative": 1.0, "social_energy": 1.0}`

#### `frequency_v2_q0092_c`
- **TR:** Ben de onun bazı planlarına katılmam.
- **EN:** I skip some of their plans too.
- **behavioral_weights:** `{"boundary_firmness": 1.0, "autonomy": 1.0}`

#### `frequency_v2_q0092_d`
- **TR:** Bu konuda esnek olmasını beklerim.
- **EN:** I expect them to be flexible about this.
- **behavioral_weights:** `{"adaptability": -1.0, "boundary_firmness": -1.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0093

- **primary_dimension:** `uncertainty_tolerance`
- **semantic_cluster:** `uncertainty_tolerance:uncertainty`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Uzun bir sessizlik sonrası karşı taraf tekrar yazdı.

**EN:** After a long silence they texted again.

### Options

#### `frequency_v2_q0093_a`
- **TR:** Normal devam ederim.
- **EN:** I'd just carry on as normal.
- **behavioral_weights:** `{"uncertainty_tolerance": 2.0, "adaptability": 1.0}`

#### `frequency_v2_q0093_b`
- **TR:** “Neredeydin” diye sorarım.
- **EN:** Ask "Where were you?"
- **behavioral_weights:** `{"reassurance_need": 2.0}`

#### `frequency_v2_q0093_c`
- **TR:** Biraz mesafeli cevap veririm.
- **EN:** I'd reply a little more distantly.
- **behavioral_weights:** `{"autonomy": 1.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0093_d`
- **TR:** Sevinir, tempo yükseltirim.
- **EN:** I'd be happy to hear from them and pick up the pace.
- **behavioral_weights:** `{"contact_need": 1.0, "closeness_pace": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0094

- **primary_dimension:** `initiative`
- **semantic_cluster:** `initiative:established`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Taşınma, büyük bir harcama veya aileyle ilgili ortak bir kararın zamanı yaklaşıyor. İkiniz de henüz konuşmayı başlatmadınız. Ne yaparsın?

**EN:** A move, a big purchase, or a family decision is coming up. Neither of you has started the conversation yet. What do you do?

### Options

#### `frequency_v2_q0094_a`
- **TR:** Konuyu ben açar ve bir sonraki adımı netleştirmeye çalışırım.
- **EN:** I'd bring it up and try to clarify the next step.
- **behavioral_weights:** `{"initiative": 2.0}`

#### `frequency_v2_q0094_b`
- **TR:** İlk olarak bir zaman veya seçenek öneririm.
- **EN:** I'd start by suggesting a time or a concrete option.
- **behavioral_weights:** `{"initiative": 1.0}`

#### `frequency_v2_q0094_c`
- **TR:** Partnerim açarsa konuşmaya katılırım.
- **EN:** Join the conversation if my partner opens it.
- **behavioral_weights:** `{"initiative": -1.0}`

#### `frequency_v2_q0094_d`
- **TR:** Partnerim somut bir seçenek getirene kadar beklerim.
- **EN:** Wait until my partner brings a concrete option.
- **behavioral_weights:** `{"initiative": -2.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0095

- **primary_dimension:** `initiative`
- **semantic_cluster:** `initiative:unclassified`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Karşı taraf seninle ilgili bir şeyi (korku, kıskançlık, ihtiyaç) dolaylı yoldan belli ediyor.

**EN:** They're indirectly hinting at something involving you — a fear, jealousy, or a need.

### Options

#### `frequency_v2_q0095_a`
- **TR:** Direkt sorarım.
- **EN:** Ask directly.
- **behavioral_weights:** `{"initiative": 2.0, "reassurance_need": 1.0}`

#### `frequency_v2_q0095_b`
- **TR:** Anlarım, ona göre davranırım.
- **EN:** Understand and adjust my behavior.
- **behavioral_weights:** `{"adaptability": 1.0}`

#### `frequency_v2_q0095_c`
- **TR:** O netleşsin diye beklerim.
- **EN:** I'd wait for them to say it clearly.
- **behavioral_weights:** `{"uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0095_d`
- **TR:** Görmezden gelirim.
- **EN:** Ignore it.
- **behavioral_weights:** `{"autonomy": 1.0, "repair_style": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0096

- **primary_dimension:** `adaptability`
- **semantic_cluster:** `adaptability:early_dating`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** İlk aylarda karşı taraf çok planlı, sen daha spontanesin (veya tersi).

**EN:** In the early months, they're very plan-oriented and you're more spontaneous — or vice versa.

### Options

#### `frequency_v2_q0096_a`
- **TR:** Orta yol bulmaya çalışırım.
- **EN:** Try to find middle ground.
- **behavioral_weights:** `{"adaptability": 1.0, "initiative": 1.0}`

#### `frequency_v2_q0096_b`
- **TR:** Kendi tarzımı korurum.
- **EN:** Keep my style.
- **behavioral_weights:** `{"autonomy": 2.0}`

#### `frequency_v2_q0096_c`
- **TR:** Onun tarzına uyum sağlarım.
- **EN:** Adapt to their style.
- **behavioral_weights:** `{"adaptability": 2.0}`

#### `frequency_v2_q0096_d`
- **TR:** Bu farkın sorun yaratıp yaratmayacağını test ederim.
- **EN:** I'd see whether this difference actually causes problems.
- **behavioral_weights:** `{"uncertainty_tolerance": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0097

- **primary_dimension:** `repair_style`
- **semantic_cluster:** `repair_style:conflict`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Bir konuda özür dilemen gereken bir durum oluştu.

**EN:** A situation came up where you need to apologize.

### Options

#### `frequency_v2_q0097_a`
- **TR:** Hemen ve net özür dilerim.
- **EN:** Apologize immediately and clearly.
- **behavioral_weights:** `{"repair_style": 1.0, "initiative": 1.0}`

#### `frequency_v2_q0097_b`
- **TR:** Durumu açıklayıp özür eklerim.
- **EN:** I'd explain the situation and apologize as part of it.
- **behavioral_weights:** `{"disclosure_pace": 1.0, "repair_style": 1.0}`

#### `frequency_v2_q0097_c`
- **TR:** Davranışla telafi ederim.
- **EN:** Make it up through actions.
- **behavioral_weights:** `{"repair_style": 0.0, "adaptability": 1.0}`

#### `frequency_v2_q0097_d`
- **TR:** Zamanla unutulur diye beklerim.
- **EN:** I'd wait and assume it'll fade with time.
- **behavioral_weights:** `{"repair_style": -2.0, "uncertainty_tolerance": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0098

- **primary_dimension:** `social_energy`
- **semantic_cluster:** `social_energy:social`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Partnerin seninle aynı anda birden fazla sosyal planı var ve seni de dahil etmek istiyor.

**EN:** Your partner has several social plans happening around the same time and wants to include you.

### Options

#### `frequency_v2_q0098_a`
- **TR:** Katılırım.
- **EN:** I'll join.
- **behavioral_weights:** `{"social_energy": 2.0, "adaptability": 1.0}`

#### `frequency_v2_q0098_b`
- **TR:** Seçici olurum.
- **EN:** I'm selective.
- **behavioral_weights:** `{"social_energy": 0.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0098_c`
- **TR:** “Bu sefer olmaz” derim.
- **EN:** Say "not this time."
- **behavioral_weights:** `{"autonomy": 1.0, "social_energy": -1.0}`

#### `frequency_v2_q0098_d`
- **TR:** Kendi planımı öneririm.
- **EN:** Suggest my own plan.
- **behavioral_weights:** `{"initiative": 1.0, "autonomy": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0099

- **primary_dimension:** `initiative`
- **semantic_cluster:** `initiative:established`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** İlişkinin son haftalarda biraz otomatiğe bağlandığını fark ediyorsun; belirgin bir sorun yok ama tempo düşmüş. Ne yaparsın?

**EN:** You've noticed the relationship has felt a bit on autopilot lately — no big issue, but the pace has dropped. What do you do?

### Options

#### `frequency_v2_q0099_a`
- **TR:** Bunu ben açar, birlikte neyi değiştirebileceğimizi konuşmayı öneririm.
- **EN:** I bring it up and suggest talking about what we could change.
- **behavioral_weights:** `{"initiative": 2.0}`

#### `frequency_v2_q0099_b`
- **TR:** Konuyu büyütmeden yeni bir ortak plan öneririm.
- **EN:** Suggest a new shared plan without making it a big deal.
- **behavioral_weights:** `{"initiative": 1.0}`

#### `frequency_v2_q0099_c`
- **TR:** Bir süre daha gözler, kendiliğinden değişip değişmediğine bakarım.
- **EN:** I'd observe a while longer and see if things change on their own.
- **behavioral_weights:** `{"initiative": -1.0}`

#### `frequency_v2_q0099_d`
- **TR:** Partnerim gündeme getirmedikçe ben bir adım atmam.
- **EN:** I won't take a step unless my partner brings it up.
- **behavioral_weights:** `{"initiative": -2.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0100

- **primary_dimension:** `closeness_pace`
- **semantic_cluster:** `closeness_pace:early_dating`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Yeni biriyle tanışma aşamasındasın. Karşı taraf çok net, sen daha keşif aşamasındasın (veya tersi).

**EN:** You're getting to know someone new. They're very clear about what they want while you're still figuring things out — or vice versa.

### Options

#### `frequency_v2_q0100_a`
- **TR:** Netliğe yaklaşırım.
- **EN:** I'd move toward greater clarity.
- **behavioral_weights:** `{"adaptability": 1.0, "closeness_pace": 1.0}`

#### `frequency_v2_q0100_b`
- **TR:** Kendi tempomu korurum.
- **EN:** I'd keep my own pace.
- **behavioral_weights:** `{"autonomy": 2.0, "closeness_pace": -1.0}`

#### `frequency_v2_q0100_c`
- **TR:** Farkı konuşuruz.
- **EN:** Talk about the difference.
- **behavioral_weights:** `{"initiative": 1.0, "disclosure_pace": 1.0}`

#### `frequency_v2_q0100_d`
- **TR:** Tempo uyuşmazsa geri çekilirim.
- **EN:** If the pace doesn't match, I pull back.
- **behavioral_weights:** `{"boundary_firmness": 1.0, "uncertainty_tolerance": -1.0}`

### Machine triage flags

- `possible_intensity_drift`

---
