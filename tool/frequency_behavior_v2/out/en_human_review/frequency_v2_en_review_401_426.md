# Frequency V2 EN Human Review — 401–426

**Status:** machine-generated triage — NOT human-reviewed
**Translation version:** `frequency_v2_en_semantic_v1`
**Items:** 26

---

## frequency_v2_q0401

- **primary_dimension:** `contact_need`
- **semantic_cluster:** `contact_need:established`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Uzun bir iş gününün ardından partneriniz “bugün hiç konuşmadık” diye yakınıyor.

**EN:** After a long workday, your partner complains that you didn't talk at all today.

### Options

#### `frequency_v2_q0401_a`
- **TR:** Hemen sohbete başlarım.
- **EN:** I start chatting right away.
- **behavioral_weights:** `{"contact_need": 1.0, "adaptability": 1.0}`

#### `frequency_v2_q0401_b`
- **TR:** “Yorgunum, yarın konuşuruz” derim.
- **EN:** I say, "I'm tired—we'll talk tomorrow."
- **behavioral_weights:** `{"boundary_firmness": 1.0, "autonomy": 1.0}`

#### `frequency_v2_q0401_c`
- **TR:** Kısa bir özet geçip kendi işime dönerim.
- **EN:** I give a quick recap and go back to my own thing.
- **behavioral_weights:** `{"autonomy": 1.0, "contact_need": 0.0}`

#### `frequency_v2_q0401_d`
- **TR:** Yanında sessizce vakit geçirmeyi öneririm.
- **EN:** I suggest spending quiet time together.
- **behavioral_weights:** `{"contact_need": 1.0, "closeness_pace": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0402

- **primary_dimension:** `closeness_pace`
- **semantic_cluster:** `closeness_pace:early_dating`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Yeni biriyle birkaç haftadır görüşüyorsunuz. O sizi sosyal medyada etiketlemek veya çift fotoğrafı paylaşmak istiyor.

**EN:** You've been seeing someone new for a few weeks. They want to tag you on social media or share a couple photo.

### Options

#### `frequency_v2_q0402_a`
- **TR:** Kabul ederim.
- **EN:** I agree.
- **behavioral_weights:** `{"closeness_pace": 1.0, "adaptability": 1.0}`

#### `frequency_v2_q0402_b`
- **TR:** “Henüz değil” derim.
- **EN:** I say, "Not yet."
- **behavioral_weights:** `{"boundary_firmness": 2.0, "closeness_pace": -1.0}`

#### `frequency_v2_q0402_c`
- **TR:** Sadece özelde kalmasını tercih ederim.
- **EN:** I prefer to keep things private.
- **behavioral_weights:** `{"autonomy": 1.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0402_d`
- **TR:** Tempo hızlanırsa paylaşımları sınırlarım.
- **EN:** If the pace picks up, I limit what gets shared.
- **behavioral_weights:** `{"autonomy": 1.0, "uncertainty_tolerance": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0403

- **primary_dimension:** `boundary_firmness`
- **semantic_cluster:** `boundary_firmness:established`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Partneriniz sizin bir aile meselenize (anne-baba, kardeş) müdahale etmeye veya fikir vermeye başladı.

**EN:** Your partner started getting involved in—or offering opinions on—a family matter of yours (parents, siblings).

### Options

#### `frequency_v2_q0403_a`
- **TR:** Dinlerim, değerlendiririm.
- **EN:** I listen and consider it.
- **behavioral_weights:** `{"adaptability": 1.0, "disclosure_pace": 1.0}`

#### `frequency_v2_q0403_b`
- **TR:** “Bu konuya karışma” derim.
- **EN:** I say, "Stay out of this."
- **behavioral_weights:** `{"boundary_firmness": 2.0, "autonomy": 1.0}`

#### `frequency_v2_q0403_c`
- **TR:** Kendi sınırımı nazikçe çizerim.
- **EN:** I gently set my boundary.
- **behavioral_weights:** `{"boundary_firmness": 1.0, "initiative": 1.0}`

#### `frequency_v2_q0403_d`
- **TR:** Konuyu tamamen kapatırım.
- **EN:** I shut the topic down completely.
- **behavioral_weights:** `{"autonomy": 1.0, "disclosure_pace": -1.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0404

- **primary_dimension:** `uncertainty_tolerance`
- **semantic_cluster:** `uncertainty_tolerance:planning`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Bir planınız vardı. Partneriniz “belki başka bir şey yaparız, karar veremedim” diye belirsiz bırakıyor.

**EN:** You had a plan. Your partner is leaving it vague: "Maybe we'll do something else—I can't decide."

### Options

#### `frequency_v2_q0404_a`
- **TR:** Netleştirmesini isterim.
- **EN:** I ask them to clarify.
- **behavioral_weights:** `{"structure_preference": 1.0, "initiative": 1.0, "uncertainty_tolerance": -1.0}`

#### `frequency_v2_q0404_b`
- **TR:** Esnek kalırım.
- **EN:** I stay flexible.
- **behavioral_weights:** `{"uncertainty_tolerance": 2.0, "adaptability": 1.0}`

#### `frequency_v2_q0404_c`
- **TR:** Kendi alternatifimi hazırlarım.
- **EN:** I prepare my own alternative.
- **behavioral_weights:** `{"autonomy": 2.0}`

#### `frequency_v2_q0404_d`
- **TR:** “Karar verelim artık” derim.
- **EN:** I say, "Let's decide already."
- **behavioral_weights:** `{"structure_preference": 1.0, "boundary_firmness": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0405

- **primary_dimension:** `boundary_firmness, disclosure_pace`
- **semantic_cluster:** `boundary_firmness:early_dating`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Partneriniz sizinle ilgili bir komplementi (dış görünüş, zekâ, karakter) abartılı bulduğunuz şekilde yapıyor.

**EN:** Your partner gives you a compliment—about your looks, intelligence, or character—in a way you find over the top.

### Options

#### `frequency_v2_q0405_a`
- **TR:** Teşekkür ederim, geçerim.
- **EN:** I thank them and move on.
- **behavioral_weights:** `{"adaptability": 1.0}`

#### `frequency_v2_q0405_b`
- **TR:** “Biraz abarttın” derim.
- **EN:** I say, "That's a bit much."
- **behavioral_weights:** `{"boundary_firmness": 1.0, "disclosure_pace": 1.0}`

#### `frequency_v2_q0405_c`
- **TR:** Ben de ona benzer bir şey söylerim.
- **EN:** I say something similar back to them.
- **behavioral_weights:** `{"disclosure_pace": 1.0, "initiative": 1.0}`

#### `frequency_v2_q0405_d`
- **TR:** Konuyu değiştiririm.
- **EN:** I change the subject.
- **behavioral_weights:** `{"autonomy": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0406

- **primary_dimension:** `boundary_firmness`
- **semantic_cluster:** `boundary_firmness:established`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Birlikte sakin bir akşam geçirmek istiyorsun. Partnerin tam o sırada ağır ve uzun bir ilişki konusu açmak istiyor. Ne yaparsın?

**EN:** You want a calm evening together. Your partner wants to open a heavy, long relationship topic right then. What do you do?

### Options

#### `frequency_v2_q0406_a`
- **TR:** Bu akşam girmemeyi ve başka bir zaman konuşmayı net biçimde öneririm.
- **EN:** I clearly suggest not going there tonight and talking another time.
- **behavioral_weights:** `{"boundary_firmness": 2.0}`

#### `frequency_v2_q0406_b`
- **TR:** Kısa süre dinler, sonra konuşmayı başka zamana bırakmak istediğimi söylerim.
- **EN:** I listen briefly, then say I'd rather pick it up later.
- **behavioral_weights:** `{"boundary_firmness": 1.0}`

#### `frequency_v2_q0406_c`
- **TR:** Hafif kalmak istediğimi söylerim ama konu sürerse eşlik ederim.
- **EN:** I say I'd prefer to keep things light but stay with it if the conversation continues.
- **behavioral_weights:** `{"boundary_firmness": -1.0}`

#### `frequency_v2_q0406_d`
- **TR:** Kendi akşam tercihimden vazgeçip konuşmaya tamamen geçerim.
- **EN:** I give up my evening preference and fully engage in the talk.
- **behavioral_weights:** `{"boundary_firmness": -2.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0407

- **primary_dimension:** `closeness_pace`
- **semantic_cluster:** `closeness_pace:early_dating`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Yeni biriyle tanışıyorsunuz. O her mesajda veya buluşmada “seni özledim” gibi ifadeler kullanıyor.

**EN:** You're getting to know someone new. They use phrases like "I miss you" in every message or meetup.

### Options

#### `frequency_v2_q0407_a`
- **TR:** Ben de benzer şekilde karşılık veririm.
- **EN:** I respond in a similar way.
- **behavioral_weights:** `{"closeness_pace": 2.0, "contact_need": 1.0}`

#### `frequency_v2_q0407_b`
- **TR:** Nazikçe kendi tempomu korurum.
- **EN:** I gently keep my own pace.
- **behavioral_weights:** `{"autonomy": 1.0, "closeness_pace": 0.0}`

#### `frequency_v2_q0407_c`
- **TR:** “Biraz yavaş gidelim” derim.
- **EN:** I say, "Let's take this slower."
- **behavioral_weights:** `{"boundary_firmness": 2.0, "closeness_pace": -1.0}`

#### `frequency_v2_q0407_d`
- **TR:** Yoğunluk artarsa geri çekilirim.
- **EN:** If it gets too intense, I pull back.
- **behavioral_weights:** `{"autonomy": 1.0, "uncertainty_tolerance": -1.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0408

- **primary_dimension:** `boundary_firmness`
- **semantic_cluster:** `boundary_firmness:established`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Partneriniz sizin bir kararınızı (iş değişikliği, şehir değiştirme, hobiniz) sürekli sorguluyor.

**EN:** Your partner keeps questioning a decision of yours—a job change, moving cities, or a hobby.

### Options

#### `frequency_v2_q0408_a`
- **TR:** Açıklama yaparım.
- **EN:** I explain myself.
- **behavioral_weights:** `{"disclosure_pace": 1.0, "initiative": 1.0}`

#### `frequency_v2_q0408_b`
- **TR:** “Bu benim kararım” derim.
- **EN:** I say, "That's my decision."
- **behavioral_weights:** `{"boundary_firmness": 2.0, "autonomy": 1.0}`

#### `frequency_v2_q0408_c`
- **TR:** Onun görüşünü de dinlerim.
- **EN:** I listen to their view too.
- **behavioral_weights:** `{"adaptability": 1.0, "disclosure_pace": 1.0}`

#### `frequency_v2_q0408_d`
- **TR:** Konuyu kapatırım.
- **EN:** I shut the topic down.
- **behavioral_weights:** `{"autonomy": 1.0, "repair_style": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0409

- **primary_dimension:** `repair_style`
- **semantic_cluster:** `repair_style:conflict`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Bir tartışmadan sonra partnerin yalnız kalmak istedi ve odasına çekildi. Bir süre sonra tekrar ortak alana çıktı ama konu hâlâ kapanmadı. Ne yaparsın?

**EN:** After an argument, your partner wanted to be alone and went to their room. After a while they came back to the shared space, but the issue still isn't resolved. What do you do?

### Options

#### `frequency_v2_q0409_a`
- **TR:** Uygun bir anda konuyu ben açıp arayı toparlamayı teklif ederim.
- **EN:** When the moment feels right, I bring it up and offer to repair things.
- **behavioral_weights:** `{"repair_style": 2.0}`

#### `frequency_v2_q0409_b`
- **TR:** Biraz normalleşmesini bekler, aynı gün içinde konuşmayı öneririm.
- **EN:** I wait for things to normalize a bit, then suggest talking the same day.
- **behavioral_weights:** `{"repair_style": 1.0}`

#### `frequency_v2_q0409_c`
- **TR:** O gün tekrar açmam; ertesi gün sakin bir zamanda geri dönerim.
- **EN:** I don't reopen it that day; I come back to it calmly the next day.
- **behavioral_weights:** `{"repair_style": -1.0}`

#### `frequency_v2_q0409_d`
- **TR:** O kendisi gündeme getirmezse ben de konuyu yeniden açmam.
- **EN:** If they don't bring it up, I won't either.
- **behavioral_weights:** `{"repair_style": -2.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0410

- **primary_dimension:** `closeness_pace`
- **semantic_cluster:** `closeness_pace:early_dating`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Yeni biriyle birkaç kez görüştünüz. O, gelecek hafta sonunun büyük bölümünü birlikte geçirmeyi öneriyor. Ne yaparsın?

**EN:** You've met someone new a few times. They're suggesting spending most of the coming weekend together. What do you do?

### Options

#### `frequency_v2_q0410_a`
- **TR:** Memnuniyetle kabul eder, iki günü de birlikte planlarım.
- **EN:** I happily agree and plan both days together.
- **behavioral_weights:** `{"closeness_pace": 2.0}`

#### `frequency_v2_q0410_b`
- **TR:** Bir günün büyük bölümünü birlikte geçirip kalan zamanı ayrı tutmayı öneririm.
- **EN:** I suggest spending most of one day together and keeping the rest separate.
- **behavioral_weights:** `{"closeness_pace": 1.0}`

#### `frequency_v2_q0410_c`
- **TR:** Daha kısa bir buluşma önerir, tempoyu biraz daha yavaş tutarım.
- **EN:** I suggest a shorter meetup and keep the pace a bit slower.
- **behavioral_weights:** `{"closeness_pace": -1.0}`

#### `frequency_v2_q0410_d`
- **TR:** Şimdilik bütün hafta sonunu birlikte geçirmek yerine ayrı ayrı görüşmeye devam etmeyi tercih ederim.
- **EN:** I'd rather keep meeting separately for now than spend the whole weekend together.
- **behavioral_weights:** `{"closeness_pace": -2.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0411

- **primary_dimension:** `initiative`
- **semantic_cluster:** `initiative:planning`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Partneriniz sizinle aynı anda hem evde kalmak hem dışarı çıkmak istiyor ve karar veremiyor.

**EN:** Your partner wants to both stay in and go out at the same time, and can't decide.

### Options

#### `frequency_v2_q0411_a`
- **TR:** Ben karar veririm.
- **EN:** I make the decision.
- **behavioral_weights:** `{"initiative": 2.0}`

#### `frequency_v2_q0411_b`
- **TR:** Sabırla beklerim.
- **EN:** I wait patiently.
- **behavioral_weights:** `{"uncertainty_tolerance": 1.0, "adaptability": 1.0}`

#### `frequency_v2_q0411_c`
- **TR:** Seçenek sunarım.
- **EN:** I offer options.
- **behavioral_weights:** `{"initiative": 1.0, "adaptability": 1.0}`

#### `frequency_v2_q0411_d`
- **TR:** “Sen karar ver” derim.
- **EN:** I say, "You decide."
- **behavioral_weights:** `{"initiative": -1.0, "autonomy": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0412

- **primary_dimension:** `structure_preference`
- **semantic_cluster:** `structure_preference:planning`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Birlikte bir yolculuk planlıyorsunuz. Partneriniz her detayı önceden netleştirmek istiyor.

**EN:** You're planning a trip together. Your partner wants every detail nailed down in advance.

### Options

#### `frequency_v2_q0412_a`
- **TR:** Onun istediği gibi planlarız.
- **EN:** We plan it their way.
- **behavioral_weights:** `{"adaptability": 2.0, "structure_preference": 1.0}`

#### `frequency_v2_q0412_b`
- **TR:** Genel çerçeve yeter derim.
- **EN:** I say a general outline is enough.
- **behavioral_weights:** `{"structure_preference": -2.0, "uncertainty_tolerance": 2.0}`

#### `frequency_v2_q0412_c`
- **TR:** Orta yol buluruz.
- **EN:** We find a middle ground.
- **behavioral_weights:** `{"initiative": 1.0, "adaptability": 1.0}`

#### `frequency_v2_q0412_d`
- **TR:** “Sen planla, ben uyarım” derim.
- **EN:** I say, "You plan it—I'll go along."
- **behavioral_weights:** `{"adaptability": 1.0, "autonomy": -1.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0413

- **primary_dimension:** `boundary_firmness`
- **semantic_cluster:** `boundary_firmness:social`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Partneriniz sizin bir arkadaşınızla olan yakınlığınızdan rahatsız olduğunu ima ediyor.

**EN:** Your partner implies they're uncomfortable with how close you are to a friend.

### Options

#### `frequency_v2_q0413_a`
- **TR:** Mesafeyi ayarlarım.
- **EN:** I adjust the distance.
- **behavioral_weights:** `{"adaptability": 2.0}`

#### `frequency_v2_q0413_b`
- **TR:** “Bu benim arkadaşım” derim.
- **EN:** I say, "That's my friend."
- **behavioral_weights:** `{"boundary_firmness": 2.0, "autonomy": 1.0}`

#### `frequency_v2_q0413_c`
- **TR:** Üçünüzü bir araya getirmeyi öneririm.
- **EN:** I suggest getting the three of you together.
- **behavioral_weights:** `{"initiative": 1.0, "social_energy": 1.0}`

#### `frequency_v2_q0413_d`
- **TR:** Konuyu kapatırım.
- **EN:** I shut the topic down.
- **behavioral_weights:** `{"autonomy": 1.0, "repair_style": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0414

- **primary_dimension:** `disclosure_pace`
- **semantic_cluster:** `disclosure_pace:early_dating`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Yeni biriyle konuşurken o çok hızlı derin konulara (aile, geçmiş yaralar, korkular) giriyor.

**EN:** While talking to someone new, they move into deep topics very quickly—family, past wounds, fears.

### Options

#### `frequency_v2_q0414_a`
- **TR:** Ben de açılırım.
- **EN:** I open up too.
- **behavioral_weights:** `{"disclosure_pace": 2.0, "closeness_pace": 1.0}`

#### `frequency_v2_q0414_b`
- **TR:** Dinlerim ama kendimden az bahsederim.
- **EN:** I listen but share little about myself.
- **behavioral_weights:** `{"disclosure_pace": -1.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0414_c`
- **TR:** “Biraz yavaş gidelim” derim.
- **EN:** I say, "Let's take this slower."
- **behavioral_weights:** `{"boundary_firmness": 2.0, "closeness_pace": -1.0}`

#### `frequency_v2_q0414_d`
- **TR:** Konuyu hafifletmeye çalışırım.
- **EN:** I try to lighten the topic.
- **behavioral_weights:** `{"disclosure_pace": -1.0, "adaptability": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0415

- **primary_dimension:** `reassurance_need`
- **semantic_cluster:** `reassurance_need:established`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Partneriniz sizin bir başarınızı duyunca beklediğinizden daha az tepki verdi.

**EN:** When your partner hears about something you achieved, they react less enthusiastically than you expected.

### Options

#### `frequency_v2_q0415_a`
- **TR:** Umursamam.
- **EN:** I don't let it bother me.
- **behavioral_weights:** `{"uncertainty_tolerance": 1.0, "autonomy": 1.0}`

#### `frequency_v2_q0415_b`
- **TR:** “Biraz daha sevinmeni beklerdim” derim.
- **EN:** I say, "I was hoping you'd be a little more excited."
- **behavioral_weights:** `{"reassurance_need": 1.0, "disclosure_pace": 1.0}`

#### `frequency_v2_q0415_c`
- **TR:** Kendi kendime kutlarım.
- **EN:** I celebrate on my own.
- **behavioral_weights:** `{"autonomy": 2.0}`

#### `frequency_v2_q0415_d`
- **TR:** Sonra tekrar açarım.
- **EN:** I bring it up again later.
- **behavioral_weights:** `{"initiative": 1.0, "reassurance_need": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0416

- **primary_dimension:** `closeness_pace`
- **semantic_cluster:** `closeness_pace:early_dating`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Yeni biriyle birkaç haftadır görüşüyorsunuz. O “ciddi düşünüyorum” dedi.

**EN:** You've been seeing someone new for a few weeks. They said, "I'm thinking seriously about this."

### Options

#### `frequency_v2_q0416_a`
- **TR:** “Ben de” derim.
- **EN:** I say, "Me too."
- **behavioral_weights:** `{"adaptability": 1.0, "closeness_pace": 1.0}`

#### `frequency_v2_q0416_b`
- **TR:** “Henüz orada değilim” derim.
- **EN:** I say, "I'm not there yet."
- **behavioral_weights:** `{"boundary_firmness": 2.0, "disclosure_pace": 1.0}`

#### `frequency_v2_q0416_c`
- **TR:** “Bakalım” derim.
- **EN:** I say, "We'll see."
- **behavioral_weights:** `{"uncertainty_tolerance": 2.0}`

#### `frequency_v2_q0416_d`
- **TR:** Tempo hızlanırsa geri adım atarım.
- **EN:** If the pace speeds up, I step back.
- **behavioral_weights:** `{"autonomy": 1.0, "closeness_pace": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0417

- **primary_dimension:** `social_energy`
- **semantic_cluster:** `social_energy:social`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Birlikte bir etkinliğe gittiniz. Partneriniz çok sosyal, siz daha geri plandasınız.

**EN:** You went to an event together. Your partner is very social; you're more in the background.

### Options

#### `frequency_v2_q0417_a`
- **TR:** Onun temposuna uyum sağlarım.
- **EN:** I match their pace.
- **behavioral_weights:** `{"adaptability": 2.0, "social_energy": 1.0}`

#### `frequency_v2_q0417_b`
- **TR:** Kendi tempomda kalırım.
- **EN:** I stay at my own pace.
- **behavioral_weights:** `{"autonomy": 1.0, "social_energy": -1.0}`

#### `frequency_v2_q0417_c`
- **TR:** Bir süre sonra ayrılmayı öneririm.
- **EN:** After a while, I suggest splitting off.
- **behavioral_weights:** `{"boundary_firmness": 1.0, "initiative": 1.0}`

#### `frequency_v2_q0417_d`
- **TR:** “Sen eğlen, ben kenarda olurum” derim.
- **EN:** I say, "You have fun—I'll hang back."
- **behavioral_weights:** `{"autonomy": 2.0, "social_energy": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0418

- **primary_dimension:** `disclosure_pace`
- **semantic_cluster:** `disclosure_pace:early_dating`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Partneriniz sizin bir sırrınızı (sağlık, aile, geçmiş) öğrendi ve “neden söylemedin?” diye sordu.

**EN:** Your partner found out a secret of yours—health, family, or your past—and asked, "Why didn't you tell me?"

### Options

#### `frequency_v2_q0418_a`
- **TR:** Açıklama yaparım.
- **EN:** I explain.
- **behavioral_weights:** `{"disclosure_pace": 1.0, "initiative": 1.0}`

#### `frequency_v2_q0418_b`
- **TR:** “Hazır değildim” derim.
- **EN:** I say, "I wasn't ready."
- **behavioral_weights:** `{"disclosure_pace": 1.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0418_c`
- **TR:** “Şimdi öğrendin, yeter” derim.
- **EN:** I say, "You know now—that's enough."
- **behavioral_weights:** `{"boundary_firmness": 2.0}`

#### `frequency_v2_q0418_d`
- **TR:** Konuyu kapatırım.
- **EN:** I shut the topic down.
- **behavioral_weights:** `{"autonomy": 1.0, "disclosure_pace": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0419

- **primary_dimension:** `closeness_pace`
- **semantic_cluster:** `closeness_pace:early_dating`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Yeni biriyle tanışıyorsunuz. O çok dokunsal, siz daha mesafelisiniz.

**EN:** You're getting to know someone new. They're very touchy; you prefer more distance.

### Options

#### `frequency_v2_q0419_a`
- **TR:** Alışmaya çalışırım.
- **EN:** I try to get used to it.
- **behavioral_weights:** `{"adaptability": 2.0, "closeness_pace": 1.0}`

#### `frequency_v2_q0419_b`
- **TR:** Nazikçe mesafemi korurum.
- **EN:** I gently keep my distance.
- **behavioral_weights:** `{"boundary_firmness": 1.0, "autonomy": 1.0}`

#### `frequency_v2_q0419_c`
- **TR:** “Ben biraz yavaşım” derim.
- **EN:** I say, "I'm a little slow with that."
- **behavioral_weights:** `{"boundary_firmness": 2.0, "disclosure_pace": 1.0}`

#### `frequency_v2_q0419_d`
- **TR:** Tempo uymuyorsa geri çekilirim.
- **EN:** If the pace doesn't fit, I pull back.
- **behavioral_weights:** `{"autonomy": 1.0, "closeness_pace": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0420

- **primary_dimension:** `initiative`
- **semantic_cluster:** `initiative:unclassified`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Partneriniz sizinle ilgili bir konuyu (duygu, ihtiyaç) dolaylı yoldan anlatıyor.

**EN:** Your partner is talking about something related to you—a feeling or a need—in an indirect way.

### Options

#### `frequency_v2_q0420_a`
- **TR:** Direkt sorarım.
- **EN:** I ask directly.
- **behavioral_weights:** `{"initiative": 2.0, "reassurance_need": 1.0}`

#### `frequency_v2_q0420_b`
- **TR:** Anlarım, ona göre davranırım.
- **EN:** I pick up on it and respond accordingly.
- **behavioral_weights:** `{"adaptability": 1.0}`

#### `frequency_v2_q0420_c`
- **TR:** O netleşsin diye beklerim.
- **EN:** I wait for them to be clearer.
- **behavioral_weights:** `{"uncertainty_tolerance": 1.0}`

#### `frequency_v2_q0420_d`
- **TR:** Görmezden gelirim.
- **EN:** I ignore it.
- **behavioral_weights:** `{"autonomy": 1.0, "repair_style": -1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0421

- **primary_dimension:** `boundary_firmness`
- **semantic_cluster:** `boundary_firmness:established`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Partneriniz sizin bir kararınızı (saç, kıyafet, hobiniz) beğenmediğini söyledi.

**EN:** Your partner said they don't like a choice of yours—your hair, clothes, or a hobby.

### Options

#### `frequency_v2_q0421_a`
- **TR:** Değiştirmeyi düşünürüm.
- **EN:** I consider changing it.
- **behavioral_weights:** `{"adaptability": 2.0}`

#### `frequency_v2_q0421_b`
- **TR:** “Bu benim seçimim” derim.
- **EN:** I say, "That's my choice."
- **behavioral_weights:** `{"boundary_firmness": 2.0, "autonomy": 1.0}`

#### `frequency_v2_q0421_c`
- **TR:** Nedenini sorarım.
- **EN:** I ask why.
- **behavioral_weights:** `{"initiative": 1.0, "disclosure_pace": 1.0}`

#### `frequency_v2_q0421_d`
- **TR:** Umursamam.
- **EN:** I don't care.
- **behavioral_weights:** `{"autonomy": 1.0, "boundary_firmness": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0422

- **primary_dimension:** `closeness_pace`
- **semantic_cluster:** `closeness_pace:early_dating`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Yeni biriyle birkaç görüşme yaptınız. O “seni arkadaşlarıma anlatıyorum” dedi.

**EN:** After a few dates with someone new, they said, "I've been telling my friends about you."

### Options

#### `frequency_v2_q0422_a`
- **TR:** Ben de anlatmaya başlarım.
- **EN:** I start telling mine too.
- **behavioral_weights:** `{"closeness_pace": 1.0, "adaptability": 1.0}`

#### `frequency_v2_q0422_b`
- **TR:** “Biraz erken” derim.
- **EN:** I say, "That's a bit early."
- **behavioral_weights:** `{"boundary_firmness": 1.0, "closeness_pace": -1.0}`

#### `frequency_v2_q0422_c`
- **TR:** Dinlerim, kendimden bahsetmem.
- **EN:** I listen but don't share about myself.
- **behavioral_weights:** `{"autonomy": 1.0, "disclosure_pace": -1.0}`

#### `frequency_v2_q0422_d`
- **TR:** Tempo hızlanırsa yavaşlarım.
- **EN:** If the pace picks up, I slow down.
- **behavioral_weights:** `{"autonomy": 1.0, "uncertainty_tolerance": -1.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0423

- **primary_dimension:** `social_energy`
- **semantic_cluster:** `social_energy:established`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Partneriniz sizinle aynı anda birden fazla sosyal plan peşinde ve sizi de dahil etmek istiyor.

**EN:** Your partner is juggling several social plans at once and wants to include you in all of them.

### Options

#### `frequency_v2_q0423_a`
- **TR:** Katılırım.
- **EN:** I join in.
- **behavioral_weights:** `{"social_energy": 2.0, "adaptability": 1.0}`

#### `frequency_v2_q0423_b`
- **TR:** Seçici olurum.
- **EN:** I'm selective about which ones I go to.
- **behavioral_weights:** `{"boundary_firmness": 1.0, "social_energy": 0.0}`

#### `frequency_v2_q0423_c`
- **TR:** “Bu sefer olmaz” derim.
- **EN:** I say, "Not this time."
- **behavioral_weights:** `{"autonomy": 1.0, "social_energy": -1.0}`

#### `frequency_v2_q0423_d`
- **TR:** Kendi planımı öneririm.
- **EN:** I suggest my own plan instead.
- **behavioral_weights:** `{"initiative": 1.0, "autonomy": 1.0}`

### Machine triage flags

- _(none)_

---

## frequency_v2_q0424

- **primary_dimension:** `boundary_firmness`
- **semantic_cluster:** `boundary_firmness:established`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Partneriniz sizin bir alışkanlığınızı (telefon, geç kalma, dağınıklık) sürekli dile getiriyor.

**EN:** Your partner keeps bringing up a habit of yours—phone use, running late, messiness.

### Options

#### `frequency_v2_q0424_a`
- **TR:** Değiştirmeye çalışırım.
- **EN:** I try to change it.
- **behavioral_weights:** `{"adaptability": 2.0}`

#### `frequency_v2_q0424_b`
- **TR:** “Bu benim tarzım” derim.
- **EN:** I say, "That's just how I am."
- **behavioral_weights:** `{"boundary_firmness": 2.0, "autonomy": 1.0}`

#### `frequency_v2_q0424_c`
- **TR:** Karşılıklı olarak onun da bir şeyini söylerim.
- **EN:** I point out something of theirs in return.
- **behavioral_weights:** `{"initiative": 1.0, "boundary_firmness": 1.0}`

#### `frequency_v2_q0424_d`
- **TR:** Konuyu kapatmasını isterim.
- **EN:** I ask them to drop it.
- **behavioral_weights:** `{"boundary_firmness": 1.0, "repair_style": -1.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0425

- **primary_dimension:** `repair_style`
- **semantic_cluster:** `repair_style:conflict`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Bir konuda partneriniz haklı olduğunu düşünüyor ve geri adım atmıyor.

**EN:** On an issue, your partner thinks they're right and won't back down.

### Options

#### `frequency_v2_q0425_a`
- **TR:** Orta yol ararım.
- **EN:** I look for a middle ground.
- **behavioral_weights:** `{"adaptability": 1.0, "repair_style": 1.0}`

#### `frequency_v2_q0425_b`
- **TR:** Kendi görüşümde ısrar ederim.
- **EN:** I stand firm on my view.
- **behavioral_weights:** `{"boundary_firmness": 2.0, "initiative": 1.0}`

#### `frequency_v2_q0425_c`
- **TR:** Konuyu kapatırım.
- **EN:** I shut the topic down.
- **behavioral_weights:** `{"repair_style": -1.0, "autonomy": 1.0}`

#### `frequency_v2_q0425_d`
- **TR:** Daha fazla soru sorarak anlamaya çalışırım.
- **EN:** I ask more questions to understand.
- **behavioral_weights:** `{"repair_style": 1.0, "disclosure_pace": 1.0}`

### Machine triage flags

- `possible_intensity_drift`

---

## frequency_v2_q0426

- **primary_dimension:** `contact_need, adaptability`
- **semantic_cluster:** `contact_need:early_dating`
- **translation_review_status:** `PENDING_HUMAN_REVIEW`

### Stems

**TR:** Yeni biriyle mesajlaşırken o çok uzun yazıyor, siz daha kısa yazmayı seviyorsunuz.

**EN:** While texting someone new, they write long messages and you prefer shorter ones.

### Options

#### `frequency_v2_q0426_a`
- **TR:** Ben de uzun yazmaya başlarım.
- **EN:** I start writing longer messages too.
- **behavioral_weights:** `{"adaptability": 2.0, "contact_need": 1.0}`

#### `frequency_v2_q0426_b`
- **TR:** Kendi tarzımda devam ederim.
- **EN:** I stick to my own style.
- **behavioral_weights:** `{"autonomy": 1.0}`

#### `frequency_v2_q0426_c`
- **TR:** “Ben biraz kısa yazarım” diye belirtirim.
- **EN:** I say, "I tend to write shorter."
- **behavioral_weights:** `{"boundary_firmness": 1.0}`

#### `frequency_v2_q0426_d`
- **TR:** Tempo uymuyorsa sıklığı azaltırım.
- **EN:** If the pace doesn't fit, I text less often.
- **behavioral_weights:** `{"autonomy": 1.0, "contact_need": -1.0}`

### Machine triage flags

- _(none)_

---
