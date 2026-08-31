# Frequency V2 EN Human Review — 101–150

**Status:** machine-generated triage — NOT human-reviewed
**Translation version:** `frequency_v2_en_semantic_v1`
**Items:** 50

---

## frequency_v2_q0101

- **primary_dimension:** `initiative`
- **semantic_cluster:** `initiative:early_dating`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** İkinci buluşma güzel geçti. Ertesi gün öğlene kadar karşı taraftan mesaj gelmedi. Sana en yakın davranış hangisi?

**EN:** The second date went well. By noon the next day, you still haven't heard from them. Which behavior is closest to yours?

### Options

#### `frequency_v2_q0101_a`
- **TR:** Dünden küçük bir detayı kullanıp sohbeti ben açarım.
- **EN:** I use a small detail from yesterday to start the conversation myself.
- **behavioral_weights:** `{"initiative": 2.0, "contact_need": 1.0}`

#### `frequency_v2_q0101_b`
- **TR:** İlk adımı onun atmasını beklerim; günümü normal sürdürürüm.
- **EN:** I wait for them to make the first move and carry on with my day as usual.
- **behavioral_weights:** `{"initiative": -2.0, "uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0101_c`
- **TR:** “Dün güzeldi” gibi kısa ve net bir mesaj gönderirim.
- **EN:** I send a short, clear message like "Yesterday was great."
- **behavioral_weights:** `{"initiative": 1.0, "disclosure_pace": 1.0}`

#### `frequency_v2_q0101_d`
- **TR:** Birkaç gün kendi akışımda kalırım; yeniden temas doğal gelişsin isterim.
- **EN:** I'd keep to my own routine for a few days and let contact resume naturally.
- **behavioral_weights:** `{"autonomy": 1.0, "closeness_pace": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0102

- **primary_dimension:** `reassurance_need`
- **semantic_cluster:** `reassurance_need:early_dating`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Bir süredir görüştüğün kişi son iki gündür önceye göre belirgin biçimde daha az yazıyor. Genelde ne yaparsın?

**EN:** Someone you've been seeing has been texting noticeably less over the past two days. What do you usually do?

### Options

#### `frequency_v2_q0102_a`
- **TR:** Değişikliği fark ettiğimi söyleyip bir şey olup olmadığını sorarım.
- **EN:** I say I noticed the change and ask if something is going on.
- **behavioral_weights:** `{"reassurance_need": 2.0, "initiative": 1.0}`

#### `frequency_v2_q0102_b`
- **TR:** Onun temposuna geçerim; bir süre nasıl ilerlediğine bakarım.
- **EN:** I match their pace and see how it plays out for a while.
- **behavioral_weights:** `{"adaptability": 2.0, "uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0102_c`
- **TR:** Kendi iletişim ritmimi değiştirmem; aklıma geldiğinde yazarım.
- **EN:** I don't change my own communication rhythm; I text when I think of them.
- **behavioral_weights:** `{"autonomy": 1.0, "contact_need": -1.0}`

#### `frequency_v2_q0102_d`
- **TR:** Uzun sohbet yerine kısa bir görüşme veya buluşma öneririm.
- **EN:** I suggest a short call or meetup instead of a long text thread.
- **behavioral_weights:** `{"contact_need": 1.0, "structure_preference": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0103

- **primary_dimension:** `disclosure_pace`
- **semantic_cluster:** `disclosure_pace:early_dating`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** İlk buluşmalardan birinde sohbet beklenmedik biçimde kişisel bir yere geldi ve karşı taraf kendinden özel bir şey anlattı.

**EN:** On one of your first dates, the conversation unexpectedly turned personal and they shared something private about themselves.

### Options

#### `frequency_v2_q0103_a`
- **TR:** Ben de benzer derinlikte bir şey paylaşırım.
- **EN:** I share something at a similar level of depth.
- **behavioral_weights:** `{"disclosure_pace": 2.0, "closeness_pace": 1.0}`

#### `frequency_v2_q0103_b`
- **TR:** Dikkatle dinlerim ama kendi özel tarafımı daha sonraya bırakırım.
- **EN:** I listen carefully, but save sharing equally personal things about myself for later.
- **behavioral_weights:** `{"disclosure_pace": -1.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0103_c`
- **TR:** Merak ettiğim şeyi sorarım; kendimle ilgili kısmı sınırlı tutarım.
- **EN:** I ask about what I'm curious about, but keep what I share about myself limited.
- **behavioral_weights:** `{"disclosure_pace": -1.0, "initiative": 1.0}`

#### `frequency_v2_q0103_d`
- **TR:** Konuşmanın biraz daha hafif bir yere dönmesini tercih ederim.
- **EN:** I prefer steering the conversation back to something lighter.
- **behavioral_weights:** `{"disclosure_pace": -2.0, "autonomy": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0104

- **primary_dimension:** `uncertainty_tolerance`
- **semantic_cluster:** `uncertainty_tolerance:uncertainty`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Yaklaşık iki aydır düzenli görüşüyorsunuz ama ilişkinin ne olduğu hiç konuşulmadı.

**EN:** You've been seeing each other regularly for about two months, but you've never talked about what the relationship is.

### Options

#### `frequency_v2_q0104_a`
- **TR:** Bir noktada konuyu ben açıp nereye gittiğimizi netleştirmek isterim.
- **EN:** At some point, I'd bring it up and try to clarify where we're headed.
- **behavioral_weights:** `{"uncertainty_tolerance": -2.0, "reassurance_need": 1.0, "initiative": 1.0}`

#### `frequency_v2_q0104_b`
- **TR:** Davranışlarımız uyumluysa isim koymadan da rahat devam ederim.
- **EN:** If our behavior feels aligned, I'm fine continuing without putting a label on it.
- **behavioral_weights:** `{"uncertainty_tolerance": 2.0, "reassurance_need": -1.0}`

#### `frequency_v2_q0104_c`
- **TR:** Kendim için bir süre sınırı koyar, o zamana kadar akışı gözlerim.
- **EN:** I give myself a time frame and watch how things unfold until then.
- **behavioral_weights:** `{"structure_preference": 1.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0104_d`
- **TR:** Netlik oluşmazsa yatırımımı biraz azaltır, kendi hayatıma daha çok dönerim.
- **EN:** If clarity doesn't emerge, I pull back a little and focus more on my own life.
- **behavioral_weights:** `{"autonomy": 2.0, "boundary_firmness": 1.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0105

- **primary_dimension:** `initiative`
- **semantic_cluster:** `initiative:planning`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Cumartesi öğlen oldu ve gün için hâlâ ortak bir planınız yok.

**EN:** It's noon on Saturday and you still don't have a plan for the day together.

### Options

#### `frequency_v2_q0105_a`
- **TR:** İki-üç seçenek hazırlayıp birini seçelim derim.
- **EN:** I come up with two or three options and suggest we pick one.
- **behavioral_weights:** `{"initiative": 2.0, "structure_preference": 1.0}`

#### `frequency_v2_q0105_b`
- **TR:** Günü boş bırakırım; bir şey çıkarsa çıkar.
- **EN:** I leave the day open; if something comes up, it comes up.
- **behavioral_weights:** `{"uncertainty_tolerance": 2.0, "structure_preference": -1.0}`

#### `frequency_v2_q0105_c`
- **TR:** Kendi planımı yapar, isterse bana katılmasını söylerim.
- **EN:** I make my own plan and tell them they're welcome to join.
- **behavioral_weights:** `{"autonomy": 2.0, "initiative": 1.0}`

#### `frequency_v2_q0105_d`
- **TR:** Bu kez onun ne yapmak istediğine göre ilerlerim.
- **EN:** This time I go with whatever they feel like doing.
- **behavioral_weights:** `{"adaptability": 2.0, "initiative": -1.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0106

- **primary_dimension:** `closeness_pace`
- **semantic_cluster:** `closeness_pace:early_dating`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Üç haftadır görüştüğün kişi seni yakın arkadaş grubuyla bir akşama davet etti.

**EN:** Someone you've been seeing for three weeks invites you to spend an evening with their close friends.

### Options

#### `frequency_v2_q0106_a`
- **TR:** Memnuniyetle giderim; çevresini erken tanımak hoşuma gider.
- **EN:** I'd be happy to go; I like meeting the people close to them early on.
- **behavioral_weights:** `{"closeness_pace": 2.0, "social_energy": 1.0}`

#### `frequency_v2_q0106_b`
- **TR:** Giderim ama akşamın tamamını orada geçirmek zorunda hissetmem.
- **EN:** I go, but I don't feel I have to stay the whole evening.
- **behavioral_weights:** `{"boundary_firmness": 1.0, "social_energy": 1.0}`

#### `frequency_v2_q0106_c`
- **TR:** Biraz erken gelir; önce ikimizin birbirini daha iyi tanımasını tercih ederim.
- **EN:** It feels a bit early; I'd rather we get to know each other better first.
- **behavioral_weights:** `{"closeness_pace": -2.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0106_d`
- **TR:** Kalabalık yerine birkaç kişiyle daha küçük bir buluşma öneririm.
- **EN:** I'd suggest a smaller get-together with just a few people instead of a crowd.
- **behavioral_weights:** `{"social_energy": -1.0, "initiative": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0107

- **primary_dimension:** `autonomy`
- **semantic_cluster:** `autonomy:established`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Birlikte geçirmeyi düşündüğün hafta sonu için partnerin “Bu hafta sonu biraz yalnız kalmaya ihtiyacım var” dedi.

**EN:** You were thinking of spending the weekend together, but your partner says, "I need some alone time this weekend."

### Options

#### `frequency_v2_q0107_a`
- **TR:** Kendi planlarımı yaparım; bu alanı doğal karşılarım.
- **EN:** I'd make my own plans; needing that space feels natural to me.
- **behavioral_weights:** `{"autonomy": 2.0, "reassurance_need": -1.0}`

#### `frequency_v2_q0107_b`
- **TR:** Alan tanırım ama gün içinde küçük bir temasımızın olmasını isterim.
- **EN:** I give them space but I'd like a small check-in during the day.
- **behavioral_weights:** `{"contact_need": 1.0, "adaptability": 1.0}`

#### `frequency_v2_q0107_c`
- **TR:** Aramızda bir sorun olup olmadığını netleştirmek isterim.
- **EN:** I want to clarify whether something is wrong between us.
- **behavioral_weights:** `{"reassurance_need": 2.0, "uncertainty_tolerance": -1.0}`

#### `frequency_v2_q0107_d`
- **TR:** İsterse aynı evde/ortamda herkesin kendi halinde olabileceği bir seçenek sunarım.
- **EN:** If they wanted, I'd suggest being in the same place while each of us does our own thing.
- **behavioral_weights:** `{"closeness_pace": 1.0, "autonomy": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0108

- **primary_dimension:** `contact_need`
- **semantic_cluster:** `contact_need:established`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** İkinizin de çok yoğun olduğu bir iş gününde iletişim nasıl aksın istersin?

**EN:** On a busy workday when you're both swamped, how would you want communication to go?

### Options

#### `frequency_v2_q0108_a`
- **TR:** Gün içinde çok az konuşup akşam uzun konuşmak bana yeter.
- **EN:** Minimal contact during the day and a longer talk in the evening works for me.
- **behavioral_weights:** `{"contact_need": -2.0, "autonomy": 1.0}`

#### `frequency_v2_q0108_b`
- **TR:** Fırsat buldukça kısa mesajlarla gün içinde bağda kalmayı severim.
- **EN:** I like staying connected with short messages whenever there's a chance.
- **behavioral_weights:** `{"contact_need": 2.0}`

#### `frequency_v2_q0108_c`
- **TR:** Öğle arası veya akşamüstü belli bir saatte kısa bir görüşme iyi olur.
- **EN:** A brief check-in at lunch or a set time in the late afternoon would be good.
- **behavioral_weights:** `{"structure_preference": 1.0, "contact_need": 1.0}`

#### `frequency_v2_q0108_d`
- **TR:** O gün onun temposu nasılsa ben de ona göre giderim.
- **EN:** I go with whatever pace they're on that day.
- **behavioral_weights:** `{"adaptability": 2.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0109

- **primary_dimension:** `uncertainty_tolerance`
- **semantic_cluster:** `uncertainty_tolerance:uncertainty`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Gün ortasında “Akşam seninle bir konu konuşmam lazım” mesajı geldi ve ardından karşı taraf meşgul oldu.

**EN:** You get a midday message: "I need to talk to you about something tonight," and then they get busy.

### Options

#### `frequency_v2_q0109_a`
- **TR:** Konunun neyle ilgili olduğuna dair kısa bir ipucu isterim.
- **EN:** I ask for a quick hint about what it's about.
- **behavioral_weights:** `{"reassurance_need": 2.0, "uncertainty_tolerance": -2.0}`

#### `frequency_v2_q0109_b`
- **TR:** Merak etsem de akşama kadar konuyu zihnimde beklemeye alabilirim.
- **EN:** I'm curious, but I can set it aside in my mind until tonight.
- **behavioral_weights:** `{"uncertainty_tolerance": 2.0, "autonomy": 1.0}`

#### `frequency_v2_q0109_c`
- **TR:** Aklımdan birkaç olasılık geçiririm ama mesaj atmam.
- **EN:** A few possibilities cross my mind, but I don't message them.
- **behavioral_weights:** `{"reassurance_need": 1.0, "initiative": -1.0}`

#### `frequency_v2_q0109_d`
- **TR:** Akşam konuşabilmek için zamanımı ayarlar, o zamana kadar rutinime devam ederim.
- **EN:** I clear time for tonight and carry on with my routine until then.
- **behavioral_weights:** `{"structure_preference": 1.0, "uncertainty_tolerance": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0110

- **primary_dimension:** `closeness_pace`
- **semantic_cluster:** `closeness_pace:early_dating`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Karşı taraf beklediğinden erken bir aşamada sana özlediğini ve senden çok hoşlandığını açıkça söyledi.

**EN:** At an earlier stage than you expected, they openly tell you they miss you and really like you.

### Options

#### `frequency_v2_q0110_a`
- **TR:** Ben de aynı şekilde hissediyorsam hemen karşılık veririm.
- **EN:** If I feel the same, I say so right away.
- **behavioral_weights:** `{"disclosure_pace": 1.0, "closeness_pace": 2.0}`

#### `frequency_v2_q0110_b`
- **TR:** Hoşuma gider ama kendi hızımda ilerlemeyi sürdürürüm.
- **EN:** It feels good, but I keep moving at my own pace.
- **behavioral_weights:** `{"closeness_pace": -1.0, "autonomy": 1.0}`

#### `frequency_v2_q0110_c`
- **TR:** Benzer duyguyu daha çok davranışlarımla göstermeyi tercih ederim.
- **EN:** I prefer showing similar feelings more through actions.
- **behavioral_weights:** `{"disclosure_pace": -1.0, "adaptability": 1.0}`

#### `frequency_v2_q0110_d`
- **TR:** Bu sözlerin onun için ne anlama geldiğini merak edip biraz konuşurum.
- **EN:** I'd be curious what those words mean to them and talk about it a little.
- **behavioral_weights:** `{"initiative": 1.0, "reassurance_need": 1.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0111

- **primary_dimension:** `structure_preference`
- **semantic_cluster:** `structure_preference:established`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Boş bir gününüz var. Partnerin “Hiç plan yapmayalım, o an ne istersek onu yaparız” dedi.

**EN:** You have a free day. Your partner says, "Let's not make any plans — we'll do whatever we feel like in the moment."

### Options

#### `frequency_v2_q0111_a`
- **TR:** Bu bana çok iyi gelir; günü tamamen açık bırakırım.
- **EN:** That feels great to me; I'd leave the whole day open.
- **behavioral_weights:** `{"structure_preference": -2.0, "uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0111_b`
- **TR:** En azından kabaca ne yapacağımızı bilmek isterim.
- **EN:** I'd at least want a rough idea of what we'll do.
- **behavioral_weights:** `{"structure_preference": 2.0}`

#### `frequency_v2_q0111_c`
- **TR:** Önce kendi birkaç işimi halleder, sonra birlikte akışa katılırım.
- **EN:** I'd take care of a few things on my own first, then join them and go with the flow.
- **behavioral_weights:** `{"autonomy": 2.0, "structure_preference": -1.0}`

#### `frequency_v2_q0111_d`
- **TR:** O gün onun enerjisine göre hareket etmek bana uyar.
- **EN:** I'm happy to go with whatever they're in the mood for that day.
- **behavioral_weights:** `{"adaptability": 2.0, "initiative": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0112

- **primary_dimension:** `structure_preference`
- **semantic_cluster:** `structure_preference:planning`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Akşam için yaptığınız plan son anda iptal oldu.

**EN:** The plan you made for tonight fell through at the last minute.

### Options

#### `frequency_v2_q0112_a`
- **TR:** Yeni bir gün belirler, sonra kendi akşamıma geçerim.
- **EN:** I'd pick another day, then get on with my evening.
- **behavioral_weights:** `{"adaptability": 1.0, "autonomy": 1.0}`

#### `frequency_v2_q0112_b`
- **TR:** Bozulduğumu saklamam; planların kolay değişmemesi benim için önemlidir.
- **EN:** I don't hide that I'm upset; it's important to me that plans don't change easily.
- **behavioral_weights:** `{"structure_preference": 2.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0112_c`
- **TR:** Tamam derim ama hemen yeni ve net bir tarih konuşmayı tercih ederim.
- **EN:** I'd be okay with it, but I'd want to agree on a new date right away.
- **behavioral_weights:** `{"structure_preference": 1.0, "uncertainty_tolerance": -1.0}`

#### `frequency_v2_q0112_d`
- **TR:** Fazla büyütmem; bir sonraki planı onun başlatmasını beklerim.
- **EN:** I wouldn't make a big deal of it; I'd wait for them to make the next plan.
- **behavioral_weights:** `{"uncertainty_tolerance": 1.0, "initiative": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0113

- **primary_dimension:** `structure_preference`
- **semantic_cluster:** `structure_preference:social`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Akşam için kendi planını yapmışsın. Partnerin bir saat kala birkaç arkadaşın eve geleceğini söylüyor. Ne yaparsın?

**EN:** You already had your own plans for the evening. An hour before, your partner says a few friends are coming over. What do you do?

### Options

#### `frequency_v2_q0113_a`
- **TR:** Kendi planımı korur, bu kez buluşmaya katılmam.
- **EN:** I'd stick with my own plan and not join them this time.
- **behavioral_weights:** `{"structure_preference": 2.0}`

#### `frequency_v2_q0113_b`
- **TR:** Kısa süre eşlik eder, sonra önceden yaptığım plana dönerim.
- **EN:** I'd join them briefly, then go back to what I'd planned.
- **behavioral_weights:** `{"structure_preference": 1.0}`

#### `frequency_v2_q0113_c`
- **TR:** Planımın çoğunu değiştirip misafirlere göre akşamı yeniden düzenlerim.
- **EN:** I'd change most of my plans and reorganize my evening around the guests.
- **behavioral_weights:** `{"structure_preference": -1.0}`

#### `frequency_v2_q0113_d`
- **TR:** Önceki planımı tamamen bırakır, akşamı geliştiği gibi sürdürürüm.
- **EN:** I drop my previous plan entirely and go with however the evening unfolds.
- **behavioral_weights:** `{"structure_preference": -2.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0114

- **primary_dimension:** `structure_preference`
- **semantic_cluster:** `structure_preference:planning`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Birlikte birkaç günlük bir tatil planlıyorsunuz.

**EN:** You're planning a trip of a few days together.

### Options

#### `frequency_v2_q0114_a`
- **TR:** Ulaşım, kalacak yer ve önemli durakların önceden belli olmasını isterim.
- **EN:** I want transport, lodging, and key stops decided ahead of time.
- **behavioral_weights:** `{"structure_preference": 2.0, "initiative": 1.0}`

#### `frequency_v2_q0114_b`
- **TR:** Ana çerçeve belli olsun; günlerin çoğu orada şekillensin isterim.
- **EN:** I'd want the overall framework set, but let most of the days take shape once we're there.
- **behavioral_weights:** `{"structure_preference": -1.0, "uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0114_c`
- **TR:** Birkaç alternatif çıkarır, son seçimleri birlikte yapmayı severim.
- **EN:** I like laying out a few options and making final picks together.
- **behavioral_weights:** `{"initiative": 1.0, "adaptability": 1.0}`

#### `frequency_v2_q0114_d`
- **TR:** Planlamayı partnerim yapmayı seviyorsa büyük ölçüde ona bırakırım.
- **EN:** If my partner enjoys planning, I largely leave it to them.
- **behavioral_weights:** `{"initiative": -1.0, "adaptability": 2.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0115

- **primary_dimension:** `adaptability`
- **semantic_cluster:** `adaptability:established`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Uzun süre birlikte kalmaya başladınız. Sen erkencisin, partnerin gece kuşu.

**EN:** You've started spending long stretches of time together. You're an early bird; your partner is a night owl.

### Options

#### `frequency_v2_q0115_a`
- **TR:** İkimiz de kendi saatimizi koruruz; ortak olmak için uyku düzenimi değiştirmem.
- **EN:** We each keep our own schedule; I wouldn't change my sleep pattern just to sync up.
- **behavioral_weights:** `{"autonomy": 2.0, "adaptability": -2.0}`

#### `frequency_v2_q0115_b`
- **TR:** Bazı günler benim, bazı günler onun ritmine yaklaşacağımız bir denge kurarım.
- **EN:** We find a balance where some days follow my rhythm, some follow theirs.
- **behavioral_weights:** `{"adaptability": 2.0, "structure_preference": 1.0}`

#### `frequency_v2_q0115_c`
- **TR:** Birlikte daha fazla zaman geçirmek için kendi saatimi belirgin biçimde esnetirim.
- **EN:** I'd adjust my schedule quite a bit so we can spend more time together.
- **behavioral_weights:** `{"adaptability": 2.0, "closeness_pace": 1.0}`

#### `frequency_v2_q0115_d`
- **TR:** Saatlerimizi koruruz ama uyumadan/uyanınca ortak küçük bir ritüel oluştururuz.
- **EN:** We'd keep our own schedules, but create a small shared ritual before bed or after waking up.
- **behavioral_weights:** `{"boundary_firmness": 1.0, "contact_need": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0116

- **primary_dimension:** `autonomy`
- **semantic_cluster:** `autonomy:boundaries`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Yıllardır tek başına yaptığın ve sana iyi gelen bir hobine partnerin de katılmak istedi.

**EN:** Your partner wants to join a hobby you've enjoyed doing on your own for years.

### Options

#### `frequency_v2_q0116_a`
- **TR:** Memnun olurum; bu alanı tamamen paylaşmak bağımızı güçlendirebilir.
- **EN:** I'd be happy about it; fully sharing this part of my life could strengthen our bond.
- **behavioral_weights:** `{"autonomy": -2.0, "closeness_pace": 2.0}`

#### `frequency_v2_q0116_b`
- **TR:** Bazı zamanlar birlikte, bazı zamanlar tek başıma yapmayı öneririm.
- **EN:** I suggest doing it together sometimes and on my own other times.
- **behavioral_weights:** `{"boundary_firmness": 1.0, "adaptability": 1.0}`

#### `frequency_v2_q0116_c`
- **TR:** Bu hobinin kişisel alanım olarak kalmasını açıkça tercih ederim.
- **EN:** I'd clearly say I'd prefer to keep this hobby as my personal space.
- **behavioral_weights:** `{"autonomy": 2.0, "boundary_firmness": 2.0}`

#### `frequency_v2_q0116_d`
- **TR:** Birkaç kez birlikte dener, nasıl hissettirdiğine göre karar veririm.
- **EN:** We try it together a few times and decide based on how it feels.
- **behavioral_weights:** `{"uncertainty_tolerance": 1.0, "adaptability": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0117

- **primary_dimension:** `autonomy`
- **semantic_cluster:** `autonomy:established`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** İnsanlarla çok yoğun geçen bir ayın ardından nihayet tamamen boş bir pazar günün var.

**EN:** After a month packed with social interaction, you finally have a completely free Sunday.

### Options

#### `frequency_v2_q0117_a`
- **TR:** Günün büyük bölümünü tek başıma geçirmek isterim.
- **EN:** I want to spend most of the day alone.
- **behavioral_weights:** `{"autonomy": 2.0, "social_energy": -2.0}`

#### `frequency_v2_q0117_b`
- **TR:** Partnerimle evde sakin, baş başa bir gün isterim.
- **EN:** I want a quiet, one-on-one day at home with my partner.
- **behavioral_weights:** `{"closeness_pace": 1.0, "social_energy": -1.0}`

#### `frequency_v2_q0117_c`
- **TR:** Partner ve yakın arkadaşlarla dışarı çıkmak bana daha iyi gelir.
- **EN:** Going out with my partner and close friends would feel better to me.
- **behavioral_weights:** `{"social_energy": 2.0, "autonomy": -1.0}`

#### `frequency_v2_q0117_d`
- **TR:** Günün bir kısmını yalnız, kalanını partnerimle geçirmek en iyisi olur.
- **EN:** Ideally, I'd spend part of the day alone and the rest with my partner.
- **behavioral_weights:** `{"autonomy": 1.0, "structure_preference": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0118

- **primary_dimension:** `social_energy`
- **semantic_cluster:** `social_energy:unclassified`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Senin için önemli bir başarıyı kutlayacaksın. Hangisi sana daha doğal gelir?

**EN:** You're celebrating an achievement that matters to you. Which feels most natural?

### Options

#### `frequency_v2_q0118_a`
- **TR:** Partner ve yakın arkadaşlarla kalabalık bir kutlama.
- **EN:** A big celebration with my partner and close friends.
- **behavioral_weights:** `{"social_energy": 2.0}`

#### `frequency_v2_q0118_b`
- **TR:** Sadece partnerimle özel bir akşam.
- **EN:** A private evening with just my partner.
- **behavioral_weights:** `{"social_energy": -1.0, "closeness_pace": 2.0}`

#### `frequency_v2_q0118_c`
- **TR:** Çok küçük, sakin bir kutlama ya da evde dinlenmek.
- **EN:** A very small, low-key celebration or relaxing at home.
- **behavioral_weights:** `{"social_energy": -2.0, "autonomy": 1.0}`

#### `frequency_v2_q0118_d`
- **TR:** Önceden belirlemem; o gün moduma göre gelişsin.
- **EN:** I don't decide ahead of time; I see how I feel that day.
- **behavioral_weights:** `{"structure_preference": -2.0, "uncertainty_tolerance": 1.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0119

- **primary_dimension:** `autonomy`
- **semantic_cluster:** `autonomy:social`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Partnerin senin çok sevdiğin bir arkadaş grubuna veya hobi ortamına katılmak istemiyor.

**EN:** Your partner doesn't want to join you when you spend time with a friend group or do a hobby you really love.

### Options

#### `frequency_v2_q0119_a`
- **TR:** Sorun etmem; o alan bana ait kalabilir.
- **EN:** That's fine; that space can stay mine.
- **behavioral_weights:** `{"autonomy": 2.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0119_b`
- **TR:** Bir kez denemesini isterim; belki düşündüğünden farklı hisseder.
- **EN:** I'd ask them to try it once; they might feel differently than they expect.
- **behavioral_weights:** `{"initiative": 1.0, "social_energy": 1.0}`

#### `frequency_v2_q0119_c`
- **TR:** Onun rahatlığı için o ortama daha seyrek gitmeye başlayabilirim.
- **EN:** I might spend less time in that setting to make them more comfortable.
- **behavioral_weights:** `{"adaptability": 2.0, "boundary_firmness": -1.0}`

#### `frequency_v2_q0119_d`
- **TR:** İkimizin de isteyeceği yeni bir ortak alan yaratmaya çalışırım.
- **EN:** I'd try to find something new that we'd both enjoy doing together.
- **behavioral_weights:** `{"initiative": 1.0, "closeness_pace": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0120

- **primary_dimension:** `adaptability`
- **semantic_cluster:** `adaptability:planning`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Bir yıllık ilişkide partnerin işi nedeniyle iki yıl başka bir şehirde yaşaması gerekebileceğini söyledi.

**EN:** In a one-year relationship, your partner says they may need to live in another city for two years because of work.

### Options

#### `frequency_v2_q0120_a`
- **TR:** Kendi düzenimi korur, ilişkiyi uzaktan sürdürmeyi denerim.
- **EN:** I'd keep my own routine and try to make long distance work.
- **behavioral_weights:** `{"autonomy": 2.0, "adaptability": -2.0}`

#### `frequency_v2_q0120_b`
- **TR:** Koşullar uygunsa onunla gitmeye ciddi biçimde açık olurum.
- **EN:** If the circumstances made sense, I'd be genuinely open to moving with them.
- **behavioral_weights:** `{"adaptability": 2.0, "closeness_pace": 1.0}`

#### `frequency_v2_q0120_c`
- **TR:** Kariyer, para ve günlük hayatı ayrıntılı değerlendirip sonra karar veririm.
- **EN:** I weigh career, money, and daily life in detail before deciding.
- **behavioral_weights:** `{"structure_preference": 2.0, "uncertainty_tolerance": -1.0}`

#### `frequency_v2_q0120_d`
- **TR:** Tam taşınmak yerine sık ziyaret gibi bir orta yol ararım.
- **EN:** I look for a middle path like frequent visits rather than a full move.
- **behavioral_weights:** `{"boundary_firmness": 1.0, "structure_preference": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0121

- **primary_dimension:** `boundary_firmness`
- **semantic_cluster:** `boundary_firmness:conflict`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Partnerin, sende onu zorlayan bir davranışı sakin ama net biçimde söyledi.

**EN:** Your partner calmly but clearly told you about a behavior of yours that bothers them.

### Options

#### `frequency_v2_q0121_a`
- **TR:** Somut örnekler ister, önce neyi kastettiğini anlamaya çalışırım.
- **EN:** I ask for concrete examples and try to understand what they mean first.
- **behavioral_weights:** `{"initiative": 1.0, "repair_style": 1.0}`

#### `frequency_v2_q0121_b`
- **TR:** Hemen cevap vermek yerine biraz düşünüp sonra geri dönerim.
- **EN:** Rather than answer right away, I think it over and come back later.
- **behavioral_weights:** `{"autonomy": 1.0, "repair_style": -1.0}`

#### `frequency_v2_q0121_c`
- **TR:** Kendi nedenlerimi de açık biçimde anlatırım; hemen değişeceğime söz vermem.
- **EN:** I explain my side clearly too; I don't promise to change immediately.
- **behavioral_weights:** `{"boundary_firmness": 2.0, "autonomy": 1.0}`

#### `frequency_v2_q0121_d`
- **TR:** Bir süre farklı davranmayı deneyip ikimize nasıl geldiğine bakarım.
- **EN:** I try acting differently for a while and see how it feels for both of us.
- **behavioral_weights:** `{"adaptability": 2.0, "uncertainty_tolerance": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0122

- **primary_dimension:** `repair_style`
- **semantic_cluster:** `repair_style:conflict`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Tartışma sırasında karşı tarafın sesi belirgin biçimde yükseldi.

**EN:** During an argument, they noticeably raise their voice.

### Options

#### `frequency_v2_q0122_a`
- **TR:** Ben de daha güçlü ve net bir tonda konuşmaya devam ederim.
- **EN:** I'd keep speaking in a firmer, clearer tone too.
- **behavioral_weights:** `{"boundary_firmness": 1.0, "repair_style": 1.0}`

#### `frequency_v2_q0122_b`
- **TR:** Konuşmayı durdurur, daha sakin bir zamanda devam etmeyi isterim.
- **EN:** I pause the conversation and ask to continue when things are calmer.
- **behavioral_weights:** `{"boundary_firmness": 2.0, "repair_style": -2.0}`

#### `frequency_v2_q0122_c`
- **TR:** Konu açık kalmasın diye o anda çözmeye devam etmeyi tercih ederim.
- **EN:** I'd rather keep working through it right then so the issue isn't left unresolved.
- **behavioral_weights:** `{"repair_style": 2.0, "reassurance_need": 1.0}`

#### `frequency_v2_q0122_d`
- **TR:** Bir süre fiziksel olarak uzaklaşıp kendi kendime sakinleşirim.
- **EN:** I step away physically for a bit and calm down on my own.
- **behavioral_weights:** `{"autonomy": 2.0, "repair_style": -2.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0123

- **primary_dimension:** `repair_style`
- **semantic_cluster:** `repair_style:support`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Stresli bir anında partnerine gereksiz sert çıktığını on dakika sonra fark ettin.

**EN:** Ten minutes later, you realize you snapped at your partner unnecessarily during a stressful moment.

### Options

#### `frequency_v2_q0123_a`
- **TR:** Hemen özür diler, ne olduğunu açıkça konuşurum.
- **EN:** I apologize right away and talk openly about what happened.
- **behavioral_weights:** `{"repair_style": 2.0, "disclosure_pace": 1.0}`

#### `frequency_v2_q0123_b`
- **TR:** Önce küçük bir jestle havayı yumuşatır, konuşmayı biraz sonraya bırakırım.
- **EN:** I soften the mood with a small gesture first and talk about it a little later.
- **behavioral_weights:** `{"adaptability": 1.0, "repair_style": -1.0}`

#### `frequency_v2_q0123_c`
- **TR:** Neden o halde olduğumu açıklayıp olayın bağlamını anlatırım.
- **EN:** I explain why I was in that state and give context to what happened.
- **behavioral_weights:** `{"disclosure_pace": 1.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0123_d`
- **TR:** İkimiz de tamamen sakinleşene kadar biraz beklerim.
- **EN:** I wait until we're both fully calm.
- **behavioral_weights:** `{"autonomy": 1.0, "repair_style": -2.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0124

- **primary_dimension:** `repair_style`
- **semantic_cluster:** `repair_style:established`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Aynı konu birkaç kez benzer biçimde tartışmaya dönüyor.

**EN:** The same topic keeps turning into similar arguments.

### Options

#### `frequency_v2_q0124_a`
- **TR:** Bu döngünün altında ne olduğunu uzun uzun konuşmak isterim.
- **EN:** I want a long talk about what's driving this cycle.
- **behavioral_weights:** `{"repair_style": 2.0, "disclosure_pace": 1.0}`

#### `frequency_v2_q0124_b`
- **TR:** Tekrar çıkmaması için net bir kural veya pratik sistem kurmayı tercih ederim.
- **EN:** I'd rather set a clear rule or practical system so it doesn't repeat.
- **behavioral_weights:** `{"repair_style": -1.0, "structure_preference": 2.0}`

#### `frequency_v2_q0124_c`
- **TR:** Bu farkın tamamen çözülemeyebileceğini kabul edip yönetmeye çalışırım.
- **EN:** I accept it may not be fully solvable and try to manage it.
- **behavioral_weights:** `{"uncertainty_tolerance": 2.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0124_d`
- **TR:** Benim için ne kadar temel bir uyumsuzluk olduğunu değerlendiririm.
- **EN:** I'd assess how fundamental this incompatibility is for me.
- **behavioral_weights:** `{"boundary_firmness": 2.0, "autonomy": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0125

- **primary_dimension:** `repair_style`
- **semantic_cluster:** `repair_style:conflict`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Tartışma bitti ama senin içinde hâlâ kapanmamış bir şey var.

**EN:** The argument is over, but something still feels unresolved for you.

### Options

#### `frequency_v2_q0125_a`
- **TR:** Aynı gün yeniden açarım; içimde kalması beni daha çok rahatsız eder.
- **EN:** I'd bring it up again the same day; letting it sit unresolved bothers me more.
- **behavioral_weights:** `{"repair_style": 2.0, "reassurance_need": 1.0}`

#### `frequency_v2_q0125_b`
- **TR:** Ertesi gün sakin bir zamanda konuşmak için zaman belirlerim.
- **EN:** I'd set a time to talk calmly the next day.
- **behavioral_weights:** `{"structure_preference": 1.0, "repair_style": 1.0}`

#### `frequency_v2_q0125_c`
- **TR:** Günlük davranışlarımız normale dönerse ayrıca konuşmadan da geçebilirim.
- **EN:** If things go back to normal between us, I can let it go without another conversation.
- **behavioral_weights:** `{"repair_style": -2.0, "adaptability": 1.0}`

#### `frequency_v2_q0125_d`
- **TR:** Karşı taraf yeniden açarsa konuşurum; ben başlatmam.
- **EN:** I'll talk if they bring it up again; I won't start it.
- **behavioral_weights:** `{"initiative": -1.0, "repair_style": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0126

- **primary_dimension:** `reassurance_need`
- **semantic_cluster:** `reassurance_need:uncertainty`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Partnerinin canının sıkkın olduğu belli ama “Bir şey yok, iyiyim” diyor.

**EN:** It's clear your partner is upset, but they say, "Nothing's wrong, I'm fine."

### Options

#### `frequency_v2_q0126_a`
- **TR:** Bir kez anlatmak isteyip istemediğini sorar, sonra alan bırakırım.
- **EN:** I ask once if they want to talk, then give them space.
- **behavioral_weights:** `{"boundary_firmness": 1.0, "autonomy": 1.0}`

#### `frequency_v2_q0126_b`
- **TR:** Konuşmaya zorlamam ama fiziksel/duygusal olarak yakın kalırım.
- **EN:** I don't push them to talk, but I stay physically or emotionally close.
- **behavioral_weights:** `{"closeness_pace": 1.0, "contact_need": 1.0}`

#### `frequency_v2_q0126_c`
- **TR:** O açana kadar rutinimi normal sürdürürüm.
- **EN:** I carry on with my routine until they open up.
- **behavioral_weights:** `{"uncertainty_tolerance": 2.0, "repair_style": -1.0}`

#### `frequency_v2_q0126_d`
- **TR:** Aramızda kapalı bir konu kalması beni rahatsız ettiği için biraz daha yoklarım.
- **EN:** Having an unspoken issue between us bothers me, so I'd check in a little more.
- **behavioral_weights:** `{"reassurance_need": 2.0, "repair_style": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0127

- **primary_dimension:** `repair_style`
- **semantic_cluster:** `repair_style:support`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Partnerin kötü geçen bir iş gününü anlatıyor ve belirgin biçimde zorlanmış görünüyor.

**EN:** Your partner is describing a rough day at work and clearly struggling.

### Options

#### `frequency_v2_q0127_a`
- **TR:** Önce hissettiklerini anlatmasına alan açarım; çözüm aramaya hemen geçmem.
- **EN:** I give them room to talk about how they feel before jumping to solutions.
- **behavioral_weights:** `{"repair_style": 2.0, "disclosure_pace": 1.0}`

#### `frequency_v2_q0127_b`
- **TR:** Sorunu parçalayıp işe yarayabilecek seçenekleri birlikte düşünürüm.
- **EN:** I'd break the problem down and think through possible solutions together.
- **behavioral_weights:** `{"repair_style": -2.0, "structure_preference": 1.0}`

#### `frequency_v2_q0127_c`
- **TR:** “Şu an dinlememi mi, çözüm düşünmemizi mi istersin?” diye sorarım.
- **EN:** I ask, "Do you want me to listen, or help think through solutions?"
- **behavioral_weights:** `{"adaptability": 2.0, "initiative": 1.0}`

#### `frequency_v2_q0127_d`
- **TR:** Biraz kafasını dağıtır, konuya daha sonra dönmeyi tercih ederim.
- **EN:** I help them take their mind off it and come back to the topic later.
- **behavioral_weights:** `{"repair_style": -1.0, "uncertainty_tolerance": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0128

- **primary_dimension:** `initiative`
- **semantic_cluster:** `initiative:support`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Partnerin kariyeriyle ilgili riskli bir karar için fikrini sordu.

**EN:** Your partner asked for your take on a risky career decision.

### Options

#### `frequency_v2_q0128_a`
- **TR:** Artı-eksi çıkarıp olabildiğince analitik bakarım.
- **EN:** I look at pros and cons as analytically as I can.
- **behavioral_weights:** `{"structure_preference": 1.0, "repair_style": -1.0}`

#### `frequency_v2_q0128_b`
- **TR:** Önce hangi seçeneğin onda nasıl bir his yarattığını konuşurum.
- **EN:** I talk first about how each option feels to them.
- **behavioral_weights:** `{"repair_style": 1.0, "disclosure_pace": 1.0}`

#### `frequency_v2_q0128_c`
- **TR:** Kararı onun vermesini ister, hangi yolu seçerse desteklerim.
- **EN:** I want them to decide and I'll support whichever path they choose.
- **behavioral_weights:** `{"adaptability": 1.0, "initiative": -1.0}`

#### `frequency_v2_q0128_d`
- **TR:** Benim gördüğüm en iyi seçeneği net biçimde söylerim.
- **EN:** I tell them clearly which option I think is best.
- **behavioral_weights:** `{"initiative": 2.0, "boundary_firmness": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0129

- **primary_dimension:** `repair_style`
- **semantic_cluster:** `repair_style:conflict`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Partnerin senin için önemli bir işi unuttu ve bu sana zaman kaybettirdi.

**EN:** Your partner forgot to do something important for you, and it cost you time.

### Options

#### `frequency_v2_q0129_a`
- **TR:** Etkisini o anda açıkça söylerim.
- **EN:** I say plainly how it affected me in the moment.
- **behavioral_weights:** `{"boundary_firmness": 1.0, "repair_style": 1.0}`

#### `frequency_v2_q0129_b`
- **TR:** Önce sorunu çözer, daha sakin bir anda konuşurum.
- **EN:** I fix the problem first and talk when things are calmer.
- **behavioral_weights:** `{"repair_style": -1.0, "structure_preference": 1.0}`

#### `frequency_v2_q0129_c`
- **TR:** Bir daha olmaması için birlikte hatırlatma/sistem kurmayı öneririm.
- **EN:** I suggest setting up reminders or a system together so it doesn't happen again.
- **behavioral_weights:** `{"structure_preference": 2.0, "repair_style": -1.0}`

#### `frequency_v2_q0129_d`
- **TR:** Tek seferlikse fazla büyütmeden alternatifimi bulurum.
- **EN:** If it's a one-off, I don't make a big deal of it and find my own workaround.
- **behavioral_weights:** `{"uncertainty_tolerance": 1.0, "repair_style": -2.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0130

- **primary_dimension:** `uncertainty_tolerance`
- **semantic_cluster:** `uncertainty_tolerance:conflict`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Önemli bir konuda hayata bakışınızın belirgin biçimde farklı olduğunu fark ettiniz.

**EN:** You realize that you see an important issue in life very differently.

### Options

#### `frequency_v2_q0130_a`
- **TR:** Farkın nereden geldiğini uzun uzun konuşmak isterim.
- **EN:** I want a long talk about where the difference comes from.
- **behavioral_weights:** `{"disclosure_pace": 1.0, "repair_style": 1.0}`

#### `frequency_v2_q0130_b`
- **TR:** Herkesin kendi görüşünü koruyabileceği ayrı bir alan bırakırım.
- **EN:** I leave room for each of us to keep our own view.
- **behavioral_weights:** `{"autonomy": 2.0, "boundary_firmness": 2.0}`

#### `frequency_v2_q0130_c`
- **TR:** Bu konuyu ilişkinin merkezine taşımadan birlikte yaşayabileceğimizi düşünürüm.
- **EN:** I think we can live with it without putting it at the center of the relationship.
- **behavioral_weights:** `{"uncertainty_tolerance": 1.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0130_d`
- **TR:** Farkın günlük kararlarımızı gerçekten etkileyip etkilemeyeceğine bakarım.
- **EN:** I look at whether the difference actually affects our day-to-day decisions.
- **behavioral_weights:** `{"structure_preference": 1.0, "initiative": 1.0}`

### Machine triage flags

- `possible_unnatural_english`

---

## frequency_v2_q0131

- **primary_dimension:** `autonomy`
- **semantic_cluster:** `autonomy:boundaries`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Uzun süreli ilişkide telefon ve dijital alan konusunda hangisi sana daha yakın?

**EN:** In a long-term relationship, which view on phones and digital privacy feels closest to you?

### Options

#### `frequency_v2_q0131_a`
- **TR:** Şifreleri bilmek sorun değildir ama birbirimizin cihazını kontrol etme ihtiyacı duymayız.
- **EN:** Knowing each other's passwords is fine, but we don't feel a need to check each other's devices.
- **behavioral_weights:** `{"autonomy": -1.0, "uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0131_b`
- **TR:** Şifreler kişisel alandır; paylaşmamayı tercih ederim.
- **EN:** Passwords are part of my personal space; I'd rather not share them.
- **behavioral_weights:** `{"autonomy": 2.0, "boundary_firmness": 2.0}`

#### `frequency_v2_q0131_c`
- **TR:** Gerektiğinde anlık paylaşırız; bunu genel bir kurala dönüştürmem.
- **EN:** We share when needed in the moment; I don't turn that into a standing rule.
- **behavioral_weights:** `{"boundary_firmness": 1.0, "adaptability": 1.0}`

#### `frequency_v2_q0131_d`
- **TR:** Dijital alanın büyük ölçüde açık olması bana daha rahat hissettirir.
- **EN:** I feel more comfortable when our digital lives are mostly open to each other.
- **behavioral_weights:** `{"closeness_pace": 1.0, "reassurance_need": 2.0}`

### Machine triage flags

- `possible_unnatural_english`

---

## frequency_v2_q0132

- **primary_dimension:** `reassurance_need`
- **semantic_cluster:** `reassurance_need:uncertainty`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Partnerinin eski bir flörtüyle sosyal medyada yeniden etkileşime girdiğini fark ettin; ortada açık bir sorun yok.

**EN:** You notice your partner interacting again on social media with someone they used to date; there's no obvious problem.

### Options

#### `frequency_v2_q0132_a`
- **TR:** Bağlamı merak ettiğimi söyleyip doğrudan sorarım.
- **EN:** I say I'm curious about the context and ask directly.
- **behavioral_weights:** `{"reassurance_need": 1.0, "initiative": 1.0}`

#### `frequency_v2_q0132_b`
- **TR:** Tek bir işarete anlam yüklemem; tekrar eden bir durum olup olmadığına bakarım.
- **EN:** I don't read too much into one signal; I watch whether it keeps happening.
- **behavioral_weights:** `{"uncertainty_tolerance": 2.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0132_c`
- **TR:** Dijital etkileşimi özel bir mesele saymam; üzerinde durmam.
- **EN:** I don't treat digital interaction as a special issue; I don't dwell on it.
- **behavioral_weights:** `{"autonomy": 2.0, "reassurance_need": -1.0}`

#### `frequency_v2_q0132_d`
- **TR:** Benim için dijital sınırın nerede olduğunu düşünüp daha sonra bu konuyu konuşurum.
- **EN:** I'd think about where my boundaries are around online interactions and talk about it later.
- **behavioral_weights:** `{"boundary_firmness": 2.0, "structure_preference": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0133

- **primary_dimension:** `adaptability`
- **semantic_cluster:** `adaptability:unclassified`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Partnerin senden daha sık iletişim kurmak istediğini açıkça söyledi.

**EN:** Your partner clearly said they want to communicate more often than you do.

### Options

#### `frequency_v2_q0133_a`
- **TR:** Temasımı belirgin biçimde artırırım; onun ritmine yaklaşmayı denerim.
- **EN:** I noticeably increase contact and try to match their rhythm.
- **behavioral_weights:** `{"adaptability": 2.0, "contact_need": 1.0}`

#### `frequency_v2_q0133_b`
- **TR:** İkimize de uyacak belirli bir ritim konuşmayı tercih ederim.
- **EN:** I'd rather agree on a specific rhythm that works for both of us.
- **behavioral_weights:** `{"structure_preference": 1.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0133_c`
- **TR:** Kendi doğal iletişim ritmimi büyük ölçüde korurum.
- **EN:** I largely keep my natural communication rhythm.
- **behavioral_weights:** `{"autonomy": 2.0, "adaptability": -2.0}`

#### `frequency_v2_q0133_d`
- **TR:** Daha çok onun başlatmasına izin verir, müsait oldukça karşılık veririm.
- **EN:** I let them initiate more and respond when I'm available.
- **behavioral_weights:** `{"initiative": -1.0, "adaptability": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0134

- **primary_dimension:** `contact_need`
- **semantic_cluster:** `contact_need:unclassified`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Bu kez daha sık iletişim isteyen taraf sensin; partnerin daha seyrek temas ediyor.

**EN:** This time you're the one who wants more contact; your partner reaches out less often.

### Options

#### `frequency_v2_q0134_a`
- **TR:** Gün içinde en azından küçük bir ortak temas ritmi isterim.
- **EN:** I'd want at least a small, regular point of contact during the day.
- **behavioral_weights:** `{"reassurance_need": 2.0, "structure_preference": 1.0}`

#### `frequency_v2_q0134_b`
- **TR:** Kendi hayatımı daha fazla doldurur, aradaki farkla yaşamayı denerim.
- **EN:** I'd focus more on my own life and try to live with the difference.
- **behavioral_weights:** `{"autonomy": 2.0, "uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0134_c`
- **TR:** İletişim ihtiyacım olduğunda daha çok ben başlatırım.
- **EN:** I initiate more when I need contact.
- **behavioral_weights:** `{"initiative": 2.0, "contact_need": 1.0}`

#### `frequency_v2_q0134_d`
- **TR:** Temponun sürekli tek taraflı kaldığını hissedersem yatırımımı azaltırım.
- **EN:** If it keeps feeling one-sided, I'd reduce how much I invest in the relationship.
- **behavioral_weights:** `{"boundary_firmness": 2.0, "contact_need": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0135

- **primary_dimension:** `closeness_pace`
- **semantic_cluster:** `closeness_pace:established`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Değer verdiğini en doğal hangi biçimde gösterirsin?

**EN:** How do you most naturally show someone they matter to you?

### Options

#### `frequency_v2_q0135_a`
- **TR:** Duygumu sözle sık ve açık biçimde ifade ederek.
- **EN:** By saying how I feel often and openly.
- **behavioral_weights:** `{"disclosure_pace": 2.0, "contact_need": 1.0}`

#### `frequency_v2_q0135_b`
- **TR:** Onun işini kolaylaştıran şeyler yaparak.
- **EN:** By doing things that make their life easier.
- **behavioral_weights:** `{"initiative": 1.0, "adaptability": 1.0}`

#### `frequency_v2_q0135_c`
- **TR:** Fiziksel yakınlık ve birlikte zamanla.
- **EN:** Through physical closeness and time together.
- **behavioral_weights:** `{"closeness_pace": 2.0, "contact_need": 1.0}`

#### `frequency_v2_q0135_d`
- **TR:** Ona kendi alanını ve özgürlüğünü vererek.
- **EN:** By giving them space and freedom of their own.
- **behavioral_weights:** `{"autonomy": 2.0, "boundary_firmness": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0136

- **primary_dimension:** `disclosure_pace`
- **semantic_cluster:** `disclosure_pace:early_dating`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Geçmişindeki önemli bir pişmanlığı yeni bir partnerle ne zaman paylaşmak sana daha doğal gelir?

**EN:** When would it feel most natural to share a major regret from your past with a new partner?

### Options

#### `frequency_v2_q0136_a`
- **TR:** Güven oluştuğunu hissettiğim erken bir aşamada.
- **EN:** At an early stage, once I feel trust building.
- **behavioral_weights:** `{"disclosure_pace": 2.0, "closeness_pace": 1.0}`

#### `frequency_v2_q0136_b`
- **TR:** O da benzer derinlikte bir şey paylaştığında.
- **EN:** When they share something at a similar depth.
- **behavioral_weights:** `{"disclosure_pace": 1.0, "initiative": -1.0}`

#### `frequency_v2_q0136_c`
- **TR:** İlişki iyice oturduktan sonra.
- **EN:** After the relationship feels well established.
- **behavioral_weights:** `{"disclosure_pace": -2.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0136_d`
- **TR:** Bugünkü ilişkiyi etkilemiyorsa ancak konu doğal olarak gelirse.
- **EN:** Only if it comes up naturally and doesn't affect the current relationship.
- **behavioral_weights:** `{"disclosure_pace": -2.0, "autonomy": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0137

- **primary_dimension:** `disclosure_pace`
- **semantic_cluster:** `disclosure_pace:unclassified`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Henüz erken aşamada olduğunuz biri sana oldukça özel ve ağır bir şey anlattı.

**EN:** Someone you're still in the early stages with tells you something very personal and heavy.

### Options

#### `frequency_v2_q0137_a`
- **TR:** Ben de kendimden benzer derinlikte bir şey paylaşırım.
- **EN:** I share something at a similar depth about myself.
- **behavioral_weights:** `{"disclosure_pace": 2.0, "closeness_pace": 1.0}`

#### `frequency_v2_q0137_b`
- **TR:** Dinlerim ve yanında olurum ama kendi açılma hızımı değiştirmem.
- **EN:** I'd listen and stay present, but keep my own pace of opening up.
- **behavioral_weights:** `{"disclosure_pace": -1.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0137_c`
- **TR:** Konuşmanın temposunu biraz yavaşlatmayı tercih ederim.
- **EN:** I prefer slowing the conversation down a bit.
- **behavioral_weights:** `{"closeness_pace": -2.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0137_d`
- **TR:** Daha çok onun anlattığının ne ifade ettiğini anlamaya çalışırım.
- **EN:** I'd focus more on understanding what it means to them.
- **behavioral_weights:** `{"initiative": 1.0, "disclosure_pace": 0.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0138

- **primary_dimension:** `closeness_pace`
- **semantic_cluster:** `closeness_pace:early_dating`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Aile/yakın çevreyle tanışma konusu açıldı.

**EN:** The topic of meeting each other's family or close circle came up.

### Options

#### `frequency_v2_q0138_a`
- **TR:** Erken tanışmak beni rahatsız etmez; ilişkiyi daha gerçek hissettirir.
- **EN:** Meeting early doesn't bother me; it makes the relationship feel more real.
- **behavioral_weights:** `{"closeness_pace": 2.0, "social_energy": 1.0}`

#### `frequency_v2_q0138_b`
- **TR:** İlişkinin yönü biraz netleşince daha anlamlı gelir.
- **EN:** It feels more meaningful once the direction of the relationship is clearer.
- **behavioral_weights:** `{"structure_preference": 1.0, "uncertainty_tolerance": -1.0}`

#### `frequency_v2_q0138_c`
- **TR:** Ben hazır hissetmeden böyle bir adım atmak istemem.
- **EN:** I don't want to take that step until I feel ready.
- **behavioral_weights:** `{"boundary_firmness": 2.0, "autonomy": 1.0}`

#### `frequency_v2_q0138_d`
- **TR:** Zamanlamayı daha çok karşı tarafın hayatındaki doğal akışa bırakırım.
- **EN:** I'd mostly let the timing follow how things naturally unfold in their life.
- **behavioral_weights:** `{"adaptability": 1.0, "initiative": -1.0}`

### Machine triage flags

- `possible_unnatural_english`

---

## frequency_v2_q0139

- **primary_dimension:** `closeness_pace`
- **semantic_cluster:** `closeness_pace:early_dating`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** İlişkinin ilk ayında partnerin sana beklediğinden çok daha pahalı bir hediye aldı.

**EN:** In the first month of the relationship, your partner gave you a gift much more expensive than you expected.

### Options

#### `frequency_v2_q0139_a`
- **TR:** Jest hoşuma gider; ben de ileride benzer ölçüde karşılık vermek isterim.
- **EN:** I appreciate the gesture; I'd want to reciprocate at a similar level later.
- **behavioral_weights:** `{"closeness_pace": 1.0, "initiative": 1.0}`

#### `frequency_v2_q0139_b`
- **TR:** Kabul ederim ama bu hızın bende yarattığı rahatsızlığı söylerim.
- **EN:** I'd accept it, but say that moving this fast makes me uncomfortable.
- **behavioral_weights:** `{"boundary_firmness": 2.0, "closeness_pace": -1.0}`

#### `frequency_v2_q0139_c`
- **TR:** Bundan sonra daha küçük jestlerde anlaşmayı teklif ederim.
- **EN:** I suggest agreeing on smaller gestures from here on.
- **behavioral_weights:** `{"structure_preference": 1.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0139_d`
- **TR:** Hediye üzerinden ilişkinin anlamını fazla okumam; anın tadını çıkarırım.
- **EN:** I don't read too much into what the gift says about the relationship; I'd enjoy the moment.
- **behavioral_weights:** `{"uncertainty_tolerance": 2.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0140

- **primary_dimension:** `structure_preference`
- **semantic_cluster:** `structure_preference:unclassified`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Partnerin son haftalarda ortak planları birkaç kez son anda değiştirdi.

**EN:** Over recent weeks, your partner changed shared plans at the last minute several times.

### Options

#### `frequency_v2_q0140_a`
- **TR:** Planların daha güvenilir olması gerektiğini açıkça söylerim.
- **EN:** I say plainly that plans need to be more reliable.
- **behavioral_weights:** `{"structure_preference": 2.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0140_b`
- **TR:** Dönemsel bir şeyse esnek kalırım.
- **EN:** If it seems temporary, I stay flexible.
- **behavioral_weights:** `{"adaptability": 2.0, "uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0140_c`
- **TR:** Ortak planlara daha az bağlanıp kendi alternatiflerimi hazır tutarım.
- **EN:** I rely less on shared plans and keep my own alternatives ready.
- **behavioral_weights:** `{"autonomy": 2.0, "structure_preference": 1.0}`

#### `frequency_v2_q0140_d`
- **TR:** Neden bu kadar değiştiğini anlamaya çalışır, sorunun kaynağını konuşurum.
- **EN:** I try to understand why things keep shifting and talk about the root cause.
- **behavioral_weights:** `{"initiative": 1.0, "reassurance_need": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0141

- **primary_dimension:** `contact_need`
- **semantic_cluster:** `contact_need:unclassified`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Partnerin bir haftalığına yoğun ve saat farkı olan bir iş seyahatine gitti.

**EN:** Your partner goes on a busy week-long work trip in a different time zone.

### Options

#### `frequency_v2_q0141_a`
- **TR:** Günün başı/sonu gibi küçük ama düzenli temaslar bana yeter.
- **EN:** Small, regular check-ins at the start or end of the day are enough for me.
- **behavioral_weights:** `{"structure_preference": 1.0, "contact_need": 1.0}`

#### `frequency_v2_q0141_b`
- **TR:** Gün içinde fırsat buldukça fotoğraf ve küçük anlar paylaşmayı severim.
- **EN:** I like sharing photos and small moments whenever there's a chance during the day.
- **behavioral_weights:** `{"contact_need": 2.0, "closeness_pace": 1.0}`

#### `frequency_v2_q0141_c`
- **TR:** Ne kadar iletişim kuracağımızı büyük ölçüde onun yoğunluğuna bırakırım.
- **EN:** I'd mostly let their workload determine how much we communicate.
- **behavioral_weights:** `{"adaptability": 2.0, "initiative": -1.0}`

#### `frequency_v2_q0141_d`
- **TR:** O hafta daha bağımsız yaşar, döndüğünde uzun uzun bağ kurmayı tercih ederim.
- **EN:** I'd focus more on my own life that week and reconnect more deeply when they're back.
- **behavioral_weights:** `{"autonomy": 2.0, "contact_need": -2.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0142

- **primary_dimension:** `contact_need`
- **semantic_cluster:** `contact_need:established`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** İkiniz de evdesiniz ve uzun süredir herkes kendi işiyle meşgul; ortam sessiz.

**EN:** You're both home and have been busy with your own things for a while; the place is quiet.

### Options

#### `frequency_v2_q0142_a`
- **TR:** Bir noktada sohbet başlatmak isterim.
- **EN:** At some point I want to start a conversation.
- **behavioral_weights:** `{"contact_need": 2.0, "initiative": 1.0}`

#### `frequency_v2_q0142_b`
- **TR:** Aynı ortamda sessiz olmak da bana yakınlık gibi gelir.
- **EN:** Being quiet in the same space already feels like closeness to me.
- **behavioral_weights:** `{"closeness_pace": 1.0, "uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0142_c`
- **TR:** Ayrı odalarda kendi işlerimize devam etmek bana gayet doğal gelir.
- **EN:** Being in separate rooms and getting on with our own things feels completely natural to me.
- **behavioral_weights:** `{"autonomy": 2.0, "contact_need": -1.0}`

#### `frequency_v2_q0142_d`
- **TR:** Birlikte yapacağımız küçük bir şey öneririm.
- **EN:** I suggest something small we can do together.
- **behavioral_weights:** `{"initiative": 1.0, "closeness_pace": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0143

- **primary_dimension:** `boundary_firmness`
- **semantic_cluster:** `boundary_firmness:social`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Çok yakın arkadaşların yeni partnerinle enerjilerinin uyuşmadığını söylüyor.

**EN:** Close friends say your new partner's energy doesn't match theirs.

### Options

#### `frequency_v2_q0143_a`
- **TR:** Ne gördüklerini dinler, kendi değerlendirmeme dahil ederim.
- **EN:** I'd listen to what they're noticing and factor it into my own judgment.
- **behavioral_weights:** `{"social_energy": 1.0, "boundary_firmness": -1.0}`

#### `frequency_v2_q0143_b`
- **TR:** Arkadaş ve ilişki dünyalarını ayrı tutup ikisini de sürdürürüm.
- **EN:** I'd keep my friendships and relationship separate and continue both.
- **behavioral_weights:** `{"autonomy": 2.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0143_c`
- **TR:** Birkaç daha iyi ortak ortam yaratıp birbirlerini farklı koşullarda görmelerini isterim.
- **EN:** I'd create a few more shared situations where they can spend time together under different circumstances.
- **behavioral_weights:** `{"initiative": 2.0, "social_energy": 1.0}`

#### `frequency_v2_q0143_d`
- **TR:** İlişkimle ilgili son kararın bana ait olduğunu netleştiririm.
- **EN:** I make clear the final call about my relationship is mine.
- **behavioral_weights:** `{"boundary_firmness": 2.0, "autonomy": 1.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0144

- **primary_dimension:** `structure_preference`
- **semantic_cluster:** `structure_preference:support`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Beklenmedik büyük bir ortak masraf çıktı.

**EN:** An unexpected large shared expense came up.

### Options

#### `frequency_v2_q0144_a`
- **TR:** Bütçe çıkarır, seçenekleri ve sorumlulukları netleştiririm.
- **EN:** I map out a budget, options, and who handles what.
- **behavioral_weights:** `{"structure_preference": 2.0, "initiative": 1.0}`

#### `frequency_v2_q0144_b`
- **TR:** Önce ikimizin de stresini konuşmak, sonra çözüme geçmek isterim.
- **EN:** I want to talk through both our stress first, then move to solutions.
- **behavioral_weights:** `{"repair_style": 1.0, "reassurance_need": 1.0}`

#### `frequency_v2_q0144_c`
- **TR:** Fazla paniklemem; çözüm adım adım ortaya çıkar diye düşünürüm.
- **EN:** I don't panic; I assume the steps will become clear as we go.
- **behavioral_weights:** `{"uncertainty_tolerance": 2.0, "structure_preference": -1.0}`

#### `frequency_v2_q0144_d`
- **TR:** Masrafın hangi kısmını kimin üstleneceğini hızlıca bölüşmeyi tercih ederim.
- **EN:** I prefer quickly splitting who covers which part of the cost.
- **behavioral_weights:** `{"boundary_firmness": 1.0, "structure_preference": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0145

- **primary_dimension:** `repair_style`
- **semantic_cluster:** `repair_style:support`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Partnerin senin önem verdiğin bir tarihi unuttu.

**EN:** Your partner forgot a date that matters to you.

### Options

#### `frequency_v2_q0145_a`
- **TR:** Bunun bende yarattığı duyguyu açıkça söylerim.
- **EN:** I say plainly how it made me feel.
- **behavioral_weights:** `{"repair_style": 2.0, "reassurance_need": 1.0}`

#### `frequency_v2_q0145_b`
- **TR:** Bir daha unutulmaması için ortak bir hatırlatma sistemi kurmayı öneririm.
- **EN:** I suggest a shared reminder system so it doesn't happen again.
- **behavioral_weights:** `{"structure_preference": 2.0, "repair_style": -1.0}`

#### `frequency_v2_q0145_c`
- **TR:** İlişkinin geri kalanı iyiyse tek bir tarihe fazla anlam yüklemem.
- **EN:** If the rest of the relationship is good, I don't attach too much meaning to one date.
- **behavioral_weights:** `{"uncertainty_tolerance": 2.0, "repair_style": -1.0}`

#### `frequency_v2_q0145_d`
- **TR:** Biraz geri çekilir, onun durumu fark edip nasıl telafi edeceğine bakarım.
- **EN:** I pull back a little and see whether they notice and how they'll make it up.
- **behavioral_weights:** `{"reassurance_need": 1.0, "repair_style": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0146

- **primary_dimension:** `structure_preference`
- **semantic_cluster:** `structure_preference:established`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** İlişkiniz oldukça oturdu; haftaların nasıl geçeceği aşağı yukarı belli.

**EN:** Your relationship feels pretty settled; you roughly know how weeks will go.

### Options

#### `frequency_v2_q0146_a`
- **TR:** Bu düzen bana huzur verir; sürpriz aramam.
- **EN:** That rhythm gives me peace; I don't look for surprises.
- **behavioral_weights:** `{"structure_preference": 2.0, "uncertainty_tolerance": -1.0}`

#### `frequency_v2_q0146_b`
- **TR:** Arada bir bilinçli olarak plansızlık veya yeni deneyim yaratırım.
- **EN:** Now and then I deliberately create spontaneity or a new experience.
- **behavioral_weights:** `{"structure_preference": -2.0, "initiative": 1.0}`

#### `frequency_v2_q0146_c`
- **TR:** İlişkinin ritmi sabit kalabilir; yeniliği kendi hobilerimde ararım.
- **EN:** The relationship rhythm can stay steady; I look for novelty in my own hobbies.
- **behavioral_weights:** `{"autonomy": 2.0, "adaptability": -1.0}`

#### `frequency_v2_q0146_d`
- **TR:** Bazı dönemler rutin, bazı dönemler daha hareketli olmasını severim.
- **EN:** I like some periods to be routine and others to be more active.
- **behavioral_weights:** `{"adaptability": 1.0, "structure_preference": 0.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0147

- **primary_dimension:** `reassurance_need`
- **semantic_cluster:** `reassurance_need:boundaries`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Partnerin “Biraz daha kişisel alana ihtiyacım var” dedi.

**EN:** Your partner said, "I need a bit more personal space."

### Options

#### `frequency_v2_q0147_a`
- **TR:** Bunun tam olarak ne anlama geldiğini konuşmak isterim.
- **EN:** I want to talk about exactly what that means.
- **behavioral_weights:** `{"reassurance_need": 2.0, "uncertainty_tolerance": -1.0, "initiative": 1.0}`

#### `frequency_v2_q0147_b`
- **TR:** Çok ayrıntı istemeden alanı veririm.
- **EN:** I give them space without needing every detail.
- **behavioral_weights:** `{"autonomy": 2.0, "uncertainty_tolerance": 2.0}`

#### `frequency_v2_q0147_c`
- **TR:** Alan verirken bağlantının tamamen kopmaması için küçük bir ritim belirlemek isterim.
- **EN:** I'd give them space, but want a small routine of contact so we don't completely disconnect.
- **behavioral_weights:** `{"contact_need": 1.0, "structure_preference": 1.0}`

#### `frequency_v2_q0147_d`
- **TR:** Ben de kendi alanımı genişletir ve ilişkinin yeni ritmini gözlerim.
- **EN:** I'd give myself more space too and see how the relationship settles into a new rhythm.
- **behavioral_weights:** `{"autonomy": 2.0, "boundary_firmness": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0148

- **primary_dimension:** `adaptability`
- **semantic_cluster:** `adaptability:boundaries`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Partnerin bu kez “Biraz daha fazla birlikte zaman ve yakınlık istiyorum” dedi.

**EN:** This time your partner said, "I want more time together and more closeness."

### Options

#### `frequency_v2_q0148_a`
- **TR:** Ortak zamanı belirgin biçimde artırmayı denerim.
- **EN:** I'd try spending noticeably more time together.
- **behavioral_weights:** `{"adaptability": 2.0, "closeness_pace": 1.0}`

#### `frequency_v2_q0148_b`
- **TR:** Onun için “daha yakın” olmanın somut olarak ne demek olduğunu sorarım.
- **EN:** I'd ask what "more closeness" actually means to them in practice.
- **behavioral_weights:** `{"initiative": 1.0, "reassurance_need": 1.0}`

#### `frequency_v2_q0148_c`
- **TR:** Ne kadarını verebileceğimi açıkça söyler, kendi alanımı da korurum.
- **EN:** I say clearly how much I can give and keep my own space too.
- **behavioral_weights:** `{"boundary_firmness": 2.0, "autonomy": 1.0}`

#### `frequency_v2_q0148_d`
- **TR:** Düzenli bir ortak zaman yaratıp geri kalan zamanı ayrı bırakmayı tercih ederim.
- **EN:** I prefer setting regular shared time and leaving the rest separate.
- **behavioral_weights:** `{"structure_preference": 1.0, "closeness_pace": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0149

- **primary_dimension:** `structure_preference`
- **semantic_cluster:** `structure_preference:planning`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** İlişkide önündeki beş yılı düşünmek sana hangisine daha yakın gelir?

**EN:** When you think about the next five years of the relationship, which feels closest?

### Options

#### `frequency_v2_q0149_a`
- **TR:** Büyük başlıkların ve yaklaşık zamanlamanın birlikte konuşulması bana iyi gelir.
- **EN:** Talking through the big milestones and rough timing together feels good to me.
- **behavioral_weights:** `{"structure_preference": 2.0, "closeness_pace": 1.0}`

#### `frequency_v2_q0149_b`
- **TR:** Genel yönü bilmek yeter; ayrıntıları şimdiden belirlemek istemem.
- **EN:** Knowing the general direction is enough; I don't want details locked in now.
- **behavioral_weights:** `{"structure_preference": -1.0, "uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0149_c`
- **TR:** Önce kendi kariyer ve yaşam planımı net tutarım; ilişki onunla birlikte şekillenir.
- **EN:** I'd keep my own career and life plans clear first, and let the relationship take shape alongside them.
- **behavioral_weights:** `{"autonomy": 2.0, "closeness_pace": -1.0}`

#### `frequency_v2_q0149_d`
- **TR:** Çok ileri bakmadan ilişkinin kendiliğinden nereye gittiğini görmeyi tercih ederim.
- **EN:** I prefer seeing where it goes without looking too far ahead.
- **behavioral_weights:** `{"uncertainty_tolerance": 2.0, "structure_preference": -2.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0150

- **primary_dimension:** `closeness_pace`
- **semantic_cluster:** `closeness_pace:early_dating`
- **translation_review_status:** `REVIEWED`

### Stems

**TR:** Yeni görüştüğün kişi ilişki konusunda senden belirgin biçimde daha hızlı ve net ilerliyor.

**EN:** Someone new you're seeing is moving noticeably faster and is much clearer about what they want from the relationship than you are.

### Options

#### `frequency_v2_q0150_a`
- **TR:** Aradaki farkı azaltmak için biraz daha hızlı ilerlemeyi denerim.
- **EN:** I try moving a bit faster to close the gap.
- **behavioral_weights:** `{"adaptability": 2.0, "closeness_pace": 1.0}`

#### `frequency_v2_q0150_b`
- **TR:** Kendi tempomu açıkça söyler ve onu korurum.
- **EN:** I state my pace clearly and stick to it.
- **behavioral_weights:** `{"boundary_firmness": 2.0, "autonomy": 1.0}`

#### `frequency_v2_q0150_c`
- **TR:** Farkı konuşup ikimizin de rahat edeceği bir tempo ararım.
- **EN:** I'd talk about the difference and look for a pace that feels comfortable for both of us.
- **behavioral_weights:** `{"initiative": 1.0, "disclosure_pace": 1.0}`

#### `frequency_v2_q0150_d`
- **TR:** Tempo farkı sürekli hissediliyorsa biraz geri çekilirim.
- **EN:** If the difference in pace keeps being noticeable, I'd pull back a little.
- **behavioral_weights:** `{"boundary_firmness": 1.0, "closeness_pace": -1.0}`

### Machine triage flags

- `possible_intensity_drift`

---
