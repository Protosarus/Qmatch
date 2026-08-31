# Frequency V2 Phase 1F — Rewrite packet (proposal only)

Status: **not applied** to the dormant draft pool. Live stems, options, option IDs, and 12D weights are unchanged.
Human approval is required before any rewrite enters the selectable V2 pool.

Authority: `docs/qmatch_frequency_v2_phase1e_final_human_primary_decisions.txt`

Rules used here:
- respondent behavior, not what the partner should do
- concrete situational behavior
- exactly one designed primary axis
- four plausible options; no obviously virtuous / awful pair
- no diagnosis, morality, toxicity, attachment, lie/truth labels
- no loaded or caricature language
- useful real-world scenario preserved when possible
- no construct outside the approved 12D
- secondary weights sparse
- authored weights only ±1 / ±2
- no evidence-layer numeric values

Do not copy these texts into the live draft until a human approves them.

## frequency_v2_q0037

### ORIGINAL STEM

Gece uyumak üzeresin, çok yorgunsun. Partnerin aniden ilişkinizle ilgili derin ve ciddi bir konuyu açtı.

### ORIGINAL OPTIONS

- **A.** Uykumu böler, konu çözülene kadar saatlerce konuşurum. Çözmeden uyuyamam.
  - current weights: `{"closeness_pace": 1.0, "repair_style": 2.0}`
- **B.** "Bunu şimdi konuşmayalım, yarın sabah taze kafayla değerlendirelim" diyerek sınırı çekerim.
  - current weights: `{"boundary_firmness": 2.0, "repair_style": -1.0}`
- **C.** Konuşmaya çalışırım ama yorgunluktan odaklanamadığım için sadece onu dinler, onaylar görünürüm.
  - current weights: `{"boundary_firmness": -1.0, "adaptability": 1.0}`
- **D.** Uyumak istediğimi belirtir ama kırılmaması için ona sarılarak uykuya dalarım.
  - current weights: `{"reassurance_need": 1.0, "autonomy": -1.0}`

### WHY REWRITE IS REQUIRED

Mevcut A seçeneği 'çözmeden uyuyamam' kapanış/onarım ihtiyacını, B ise uyku/zaman sınırını ölçüyor. İnsan kararı: tek eksen; uyku-sınırı ile kapanış ihtiyacını birincil olarak birleştirmeyin.

### TARGET PRIMARY DIMENSION

`boundary_firmness`

### OPTIONAL SECONDARY DIMENSIONS

_none_

### PROPOSED NEW STEM

Gece uyumak üzeresin ve çok yorgunsun. Partnerin ilişkinizle ilgili derin bir konuyu şimdi konuşmak istiyor. Sen ne yaparsın?

### PROPOSED A/B/C/D OPTIONS

- **A.** Bu gece konuşmayalım, sabah taze kafayla devam edelim derim.
  - proposed weights: `boundary_firmness` +2
- **B.** Kısa bir süre dinlerim; sonra uykuya geçmek istediğimi söylerim.
  - proposed weights: `boundary_firmness` +1
- **C.** Yorgunsam da bir süre konuşur, sonra uyumayı öneririm.
  - proposed weights: `boundary_firmness` -1
- **D.** Konuyu bu gece sürdürmek için uykuyu ertelerim.
  - proposed weights: `boundary_firmness` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Dört seçenek, yorgun gecede derin konuşmaya koyulan sınırın netliğinden esnekliğine uzanır. Kapanış ihtiyacı, onarım temposu veya 'çözmeden duramam' dili yok.

### SOCIAL-DESIRABILITY WARNING

Sınır koymak bazı yanıtlarda daha olgun görünebilir; gece boyunca dinlemek de ilgili görünür. Bu paket kanıt katmanı sayısı atamaz. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## frequency_v2_q0163

### ORIGINAL STEM

Sen iş yerinde berbat ve stresli bir gün geçirdin, partnerin ise harika haberler aldığı enerjik bir gün geçirdi. Akşam buluştunuz.

### ORIGINAL OPTIONS

- **A.** Onun sevincini bölmemek için kendi stresimi içime atar, onun enerjisine uyumlanmaya çalışırım.
  - current weights: `{"adaptability": 2.0, "disclosure_pace": -2.0}`
- **B.** Önce kendi kötü günümü uzun uzun anlatıp deşarj olurum, sonra onun sevincini dinlerim.
  - current weights: `{"disclosure_pace": 2.0}`
- **C.** "Bugün benim için çok zordu ama senin adına çok sevindim" der, orta bir enerji seviyesi bulurum.
  - current weights: `{"boundary_firmness": 1.0, "disclosure_pace": 1.0}`
- **D.** Kendi modum çok düşükse erken kalkmayı ve ikimizin de gününü heba etmemeyi tercih ederim.
  - current weights: `{"autonomy": 2.0, "social_energy": -1.0}`

### WHY REWRITE IS REQUIRED

Seçenekler enerji uyumu, açıklama sırası, erken kalkma ve otonomiyi aynı anda ölçüyor. Tek birincil eksen yok.

### TARGET PRIMARY DIMENSION

`adaptability`

### OPTIONAL SECONDARY DIMENSIONS

`social_energy`

### PROPOSED NEW STEM

Sen yorucu bir gün geçirdin; partnerin enerjik ve iyi haberli. Akşam buluştunuz. Sen ne yaparsın?

### PROPOSED A/B/C/D OPTIONS

- **A.** Kendi yorgunluğumu bir kenara bırakıp onun temposuna yaklaşırım.
  - proposed weights: `adaptability` +2
- **B.** Kısaca yorgun olduğumu söyler, ortak orta bir tempo ararım.
  - proposed weights: `adaptability` +1
- **C.** Yanında kalırım ama kendi düşük tempomda otururum.
  - proposed weights: `adaptability` -1, `social_energy` -1
- **D.** Bu akşamı kısa tutar, kendi halime çekilirim.
  - proposed weights: `adaptability` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Eksen, partnerin enerjisine uyum ile kendi tempo koruma arasındadır. Kim önce gününü anlatır diye ayrı bir açıklama testi yok.

### SOCIAL-DESIRABILITY WARNING

Uyumlanan seçenek ilgili, erken ayrılan seçenek bencil görünebilir. Davranış temposu ölçülür; erdem skoru yok. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## frequency_v2_q0295

### ORIGINAL STEM

Günün stresiyle sessizce ağlamaya başladın. Partnerin odaya girdi. Sen ne yaparsın?

### ORIGINAL OPTIONS

- **A.** Soru sormasını beklemeden ona uzanır, sarılmasını isterim.
  - current weights: `{"contact_need": 2.0, "reassurance_need": 2.0}`
- **B.** "Anlatmak istersem çağırırım" der, biraz kendi halime çekilirim.
  - current weights: `{"autonomy": 2.0}`
- **C.** Ne olduğunu hemen anlatır, birlikte bir çıkış ararım.
  - current weights: `{"initiative": 1.0, "disclosure_pace": 1.0}`
- **D.** Konuyu dağıtacak bir şey öneririm; kısa bir şaka, film veya müzik açmayı teklif ederim.
  - current weights: `{"uncertainty_tolerance": 1.0, "adaptability": 1.0}`

### WHY REWRITE IS REQUIRED

Phase 1C metni hâlâ sarılma/güvence, otonomi, hemen anlatma ve konuyu dağıtmayı aynı maddede karıştırıyor. İnsan kısıtı: tek davranış ekseni.

### TARGET PRIMARY DIMENSION

`disclosure_pace`

### OPTIONAL SECONDARY DIMENSIONS

_none_

### PROPOSED NEW STEM

Günün stresiyle sessizce ağlamaya başladın. Partnerin odaya girdi. Ne olduğunu ne kadar çabuk paylaşırsın?

### PROPOSED A/B/C/D OPTIONS

- **A.** Ne olduğunu hemen anlatırım.
  - proposed weights: `disclosure_pace` +2
- **B.** Kısa bir özet veririm; ayrıntıyı biraz sonra açarım.
  - proposed weights: `disclosure_pace` +1
- **C.** Şimdilik zamana ihtiyacım var, biraz sonra konuşuruz derim.
  - proposed weights: `disclosure_pace` -1
- **D.** O an nedenini söylemem; kendi halime çekilirim.
  - proposed weights: `disclosure_pace` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Dört seçenek yalnızca ne kadar çabuk açıldığını ayırır. Sarılma isteği, şaka ile kaçış veya çözüm arama yok.

### SOCIAL-DESIRABILITY WARNING

Hemen anlatmak samimi, tutmak mesafeli görünebilir. Bu, açıklama temposudur; dürüstlük etiketi değildir. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## frequency_v2_q0365

### ORIGINAL STEM

İlişkiniz için çok önemli bir tarihi (yıldönümü) partnerin tamamen unuttu ve o güne normal bir gün gibi devam ediyor.

### ORIGINAL OPTIONS

- **A.** Akşama kadar hatırlar diye beklerim, hatırlamazsa çok kırılır ve tavır yaparım.
  - current weights: `{"reassurance_need": 2.0, "disclosure_pace": -1.0}`
- **B.** Hiç umursamam, özel gün kutlamaları veya takvimsel ritüeller benim için anlamsızdır.
  - current weights: `{"uncertainty_tolerance": 2.0, "structure_preference": -2.0}`
- **C.** Sabah ilk iş ben kutlar, ona unuttuğu için ufak bir şaka yapar, konuyu tatlıya bağlarım.
  - current weights: `{"initiative": 2.0}`
- **D.** "Bugün günlerden ne farkında mısın?" diyerek hemen yüzleşir ve ona sorumluluğunu hatırlatırım.
  - current weights: `{"boundary_firmness": 1.0, "structure_preference": 2.0}`

### WHY REWRITE IS REQUIRED

Unutulan yıldönümü maddesi kırılma/tavır, ritüel anlamsızlığı, şaka ve yüzleştirmeyi karıştırıyor. Güvence arama tek eksen olarak durmuyor.

### TARGET PRIMARY DIMENSION

`reassurance_need`

### OPTIONAL SECONDARY DIMENSIONS

_none_

### PROPOSED NEW STEM

İlişkiniz için önemli bir tarihi partnerin unuttu ve güne sıradan devam ediyor. Sen ne yaparsın?

### PROPOSED A/B/C/D OPTIONS

- **A.** Günün önemini kendim hatırlatır, birlikte işaretlemek isteyip istemediğini sorarım.
  - proposed weights: `reassurance_need` +2
- **B.** Kısa bir hatırlatma yaparım; abartmadan geçerim.
  - proposed weights: `reassurance_need` +1
- **C.** Günü kendim geçiririm; o getirmezse açmam.
  - proposed weights: `reassurance_need` -1
- **D.** Sıradan bir gün gibi devam ederim, kontrol etmem.
  - proposed weights: `reassurance_need` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Eksen, günün hâlâ paylaşılan bir işaret olup olmadığını yoklamak ile yoklamamak arasındadır. Tavır, ahlak veya 'kutlama saçma' karikatürü yok.

### SOCIAL-DESIRABILITY WARNING

Hatırlatmak olgun, umursamamak soğukkanlı görünebilir. Sayısal sosyal-beğenirlik yok. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## frequency_v2_q0406

### ORIGINAL STEM

Birlikte bir akşam evdesiniz. Partneriniz derin bir konu açmak istiyor, siz o akşam hafif vakit geçirmek istiyorsunuz.

### ORIGINAL OPTIONS

- **A.** Derin konuşmaya geçerim.
  - current weights: `{"adaptability": 1.0, "disclosure_pace": 1.0}`
- **B.** “Bugün hafif konuşalım” derim.
  - current weights: `{"boundary_firmness": 2.0}`
- **C.** Kısa dinleyip konuyu severim.
  - current weights: `{"adaptability": 1.0, "boundary_firmness": 1.0}`
- **D.** Kendi istediğim aktiviteyi öneririm.
  - current weights: `{"initiative": 1.0, "autonomy": 1.0}`

### WHY REWRITE IS REQUIRED

Derin konuşmaya geçmek, hafif tutmak, kısa dinlemek ve kendi aktiviteyi önermek dört ayrı eksen. Bu geceki sınır tek başına durmuyor.

### TARGET PRIMARY DIMENSION

`boundary_firmness`

### OPTIONAL SECONDARY DIMENSIONS

_none_

### PROPOSED NEW STEM

Birlikte evdesiniz. Partnerin derin bir konu açmak istiyor; sen bu akşam hafif vakit geçirmek istiyorsun. Sen ne yaparsın?

### PROPOSED A/B/C/D OPTIONS

- **A.** Bu akşam hafif kalalım, derin konuyu başka zamana bırakalım derim.
  - proposed weights: `boundary_firmness` +2
- **B.** Kısa dinlerim; sonra hafif moda dönmek istediğimi söylerim.
  - proposed weights: `boundary_firmness` +1
- **C.** Bir süre derin konuşmaya eşlik ederim.
  - proposed weights: `boundary_firmness` -1
- **D.** Bu akşamki tercihimden vazgeçip derin konuşmaya geçerim.
  - proposed weights: `boundary_firmness` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Dört seçenek bu akşamki derin-konuşma sınırının netliğidir. Açıklama derinliği ayrı birincil değildir.

### SOCIAL-DESIRABILITY WARNING

Sınır koymak olgun, eşlik etmek ilgili görünebilir. İkisi de makul akşam tercihidir. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## frequency_v2_q0039

### ORIGINAL STEM

İlişkiniz tamamen rayına oturdu, her gününüzün nasıl geçeceği belli, sıfır sürpriz var. Nasıl hissedersin?

### ORIGINAL OPTIONS

- **A.** Bu tam olarak aradığım "huzur" tanımıdır. Öngörülebilirlik beni güvende hissettirir.
  - current weights: `{"structure_preference": 2.0, "uncertainty_tolerance": -2.0}`
- **B.** Sıkılmaya başlarım. Arada bir anlık sürprizler, programsız maceralar yaratma ihtiyacı duyarım.
  - current weights: `{"uncertainty_tolerance": 2.0, "structure_preference": -2.0}`
- **C.** Rutin güzeldir ama heyecanı artırmak için yeni ortak hobiler veya eğitimler bulmaya çalışırım.
  - current weights: `{"initiative": 2.0, "social_energy": 1.0}`
- **D.** Benim için fark etmez, hayatımın diğer alanlarındaki heyecan (iş/hobiler) bana yeter.
  - current weights: `{"autonomy": 2.0, "adaptability": -1.0}`

### WHY REWRITE IS REQUIRED

Kök 'nasıl hissedersin?' diye soruyor. İnsan kararı: gözlemlenebilir davranış; aday eksen structure_preference.

### TARGET PRIMARY DIMENSION

`structure_preference`

### OPTIONAL SECONDARY DIMENSIONS

_none_

### PROPOSED NEW STEM

İlişkinizde günler öngörülebilir hale geldi; sürpriz yok. Sen ne yaparsın?

### PROPOSED A/B/C/D OPTIONS

- **A.** Aynı günlük düzeni korurum; planı bozmam.
  - proposed weights: `structure_preference` +2
- **B.** Düzeni sürdürür, küçük ve planlı bir değişiklik eklerim.
  - proposed weights: `structure_preference` +1
- **C.** Arada plansız bir çıkış veya değişiklik yaparım.
  - proposed weights: `structure_preference` -1
- **D.** Rutini sık sık bozar, anlık değişikliklere yer açarım.
  - proposed weights: `structure_preference` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Düzeni koruma ile plansız bozma arasında tek yapı ekseni. His, huzur/sıkılma etiketleri yok.

### SOCIAL-DESIRABILITY WARNING

Düzenli seçenek olgun, değişim arayan seçenek canlı görünebilir. Tercih temposudur. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## frequency_v2_q0254

### ORIGINAL STEM

Sen çok hastasın, ateşin var ve yatakta yatıyorsun. Partnerinden beklentin nedir?

### ORIGINAL OPTIONS

- **A.** Sürekli yanımda olması, saçımı okşaması, şefkat göstermesi beni çok hızlı iyileştirir.
  - current weights: `{"reassurance_need": 2.0, "closeness_pace": 2.0}`
- **B.** Bana sadece yemeğimi/ilacımı vermesi yeterli, sonrasında beni yalnız bırakmasını ve uyumayı tercih ederim.
  - current weights: `{"autonomy": 2.0, "reassurance_need": -2.0}`
- **C.** Yan odada kendi işine bakmasını ama sesimi duyabileceği kadar yakınımda olmasını isterim.
  - current weights: `{"boundary_firmness": 1.0, "autonomy": 1.0}`
- **D.** Hastayken kendimi zayıf göstermeyi sevmem, mümkün olduğunca ondan yardım istememeye çalışırım.
  - current weights: `{"disclosure_pace": -2.0, "boundary_firmness": 2.0}`

### WHY REWRITE IS REQUIRED

Kök partnerden beklenti soruyor. İnsan kararı: yanıtlayan tarafındaki davranış; hasta gününde temas.

### TARGET PRIMARY DIMENSION

`contact_need`

### OPTIONAL SECONDARY DIMENSIONS

_none_

### PROPOSED NEW STEM

Ateşin var ve yataktasın. Partnerin evde. Sen ne yaparsın?

### PROPOSED A/B/C/D OPTIONS

- **A.** Yanımda oturmasını veya yakın durmasını isterim.
  - proposed weights: `contact_need` +2
- **B.** Ara sıra bakmasını isterim; çoğunu dinlenerek geçiririm.
  - proposed weights: `contact_need` +1
- **C.** Çoğunu kendim idare ederim; gerekirse seslenirim.
  - proposed weights: `contact_need` -1
- **D.** İyileşene kadar teması düşük tutar, yalnız kalmayı tercih ederim.
  - proposed weights: `contact_need` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Hasta gününde ne kadar yakın temas istediğin. Partnerin 'ne yapmalı' menüsü değil.

### SOCIAL-DESIRABILITY WARNING

Yanında istemek şefkat ihtiyacı, yalnız kalmak güçlü görünme baskısı taşıyabilir. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## frequency_v2_q0281

### ORIGINAL STEM

Kalabalık bir ortamda, arkadaşlarınızın veya ailenin yanında fiziksel temas (sarılma, öpme) konusunda ne düşünürsün?

### ORIGINAL OPTIONS

- **A.** İçimden geliyorsa yaparım, başkalarının ne düşündüğü umurumda olmaz, sevgimi saklamam.
  - current weights: `{"disclosure_pace": 2.0, "closeness_pace": 2.0}`
- **B.** El ele tutuşmak gibi ufak temaslar okeydir ama aşırı yakınlığı başkalarının yanında uygunsuz bulurum.
  - current weights: `{"boundary_firmness": 1.0, "disclosure_pace": -1.0}`
- **C.** Genelde mesafeli dururum, sevgi gösterilerinin tamamen kapalı kapılar ardında, özel kalmasını tercih ederim.
  - current weights: `{"autonomy": 1.0, "disclosure_pace": -2.0}`
- **D.** Partnerim başlatırsa ona uyum sağlarım ama kendim inisiyatif alıp ulu orta romantizm yapmam.
  - current weights: `{"initiative": -1.0, "adaptability": 1.0}`

### WHY REWRITE IS REQUIRED

Kök 'ne düşünürsün' diye soruyor. İnsan kararı: kalabalıkta somut yakınlık davranışı.

### TARGET PRIMARY DIMENSION

`closeness_pace`

### OPTIONAL SECONDARY DIMENSIONS

_none_

### PROPOSED NEW STEM

Kalabalık bir ortamda, arkadaşların veya ailen yanında partnerinle fiziksel yakınlık nasıl olur?

### PROPOSED A/B/C/D OPTIONS

- **A.** Doğalsa sarılır veya öperim.
  - proposed weights: `closeness_pace` +2
- **B.** El tutmak gibi küçük bir temas yeter.
  - proposed weights: `closeness_pace` +1
- **C.** Yakın dururum ama dokunmayı az tutarım.
  - proposed weights: `closeness_pace` -1
- **D.** Fiziksel yakınlığı sonraya, ikiniz kalana bırakırım.
  - proposed weights: `closeness_pace` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Kamusal ortamda yakınlık temposu. 'Sevgimi saklamam' veya uygunsuzluk ahlakı yok.

### SOCIAL-DESIRABILITY WARNING

Açık temas özgüvenli, ertelemek saygılı görünebilir. İkisi de olağan tercihtir. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## frequency_v2_q0353

### ORIGINAL STEM

Baş başa yemek yerken partnerinin telefonu masada ve ekranı yukarı bakıyor. Sürekli bildirimler yanıp sönüyor.

### ORIGINAL OPTIONS

- **A.** O anki bağımızı kopardığı için rahatsız olur, telefonu ters çevirmesini veya kaldırmasını rica ederim.
  - current weights: `{"contact_need": 2.0, "boundary_firmness": 1.0}`
- **B.** Gözüm ister istemez ekrana kayar, kimden mesaj geldiğini merak etsem de bir şey demem.
  - current weights: `{"reassurance_need": 2.0}`
- **C.** Hiç umursamam, o an önemli bir şey okuyorsa beklerim, herkesin dijital dünyasına saygım vardır.
  - current weights: `{"autonomy": 2.0, "uncertainty_tolerance": 2.0}`
- **D.** Ben de fırsat bilip kendi telefonumu çıkarır, masada iki kişinin de kendi halinde takıldığı bir mola yaratırım.
  - current weights: `{"adaptability": 1.0, "social_energy": -1.0}`

### WHY REWRITE IS REQUIRED

Yemekte telefon, yakınlık temposuna temiz denk gelmiyor. İnsan kararı: tek açık eksen; burada masa sınırı.

### TARGET PRIMARY DIMENSION

`boundary_firmness`

### OPTIONAL SECONDARY DIMENSIONS

_none_

### PROPOSED NEW STEM

Baş başa yemekte partnerinin telefonu masada, ekran açık, bildirimler geliyor. Sen ne yaparsın?

### PROPOSED A/B/C/D OPTIONS

- **A.** Yemek boyunca telefonu kaldırmasını veya kapatmasını isterim.
  - proposed weights: `boundary_firmness` +2
- **B.** Ekranı kapatmasını bir kez söylerim.
  - proposed weights: `boundary_firmness` +1
- **C.** Bu sefer bir şey demem.
  - proposed weights: `boundary_firmness` -1
- **D.** Sınır koyamam; yemeğe telefonla devam ederiz.
  - proposed weights: `boundary_firmness` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Ortak yemekte ekran için sınır koyup koymama. Merak, kendi telefonunu çıkarma veya dijital saygı söylemi yok.

### SOCIAL-DESIRABILITY WARNING

Telefon kaldırtmak ilgili, susmak uyumlu görünebilir. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## frequency_v2_q0372

### ORIGINAL STEM

Partnerinin arkadaş grubunda, dedikoducu ve sürekli kriz yaratan toksik bir kişi var. Grup buluşmalarında ne yaparsın?

### ORIGINAL OPTIONS

- **A.** Partnerime "O varsa ben gelmiyorum" diyerek o ortama girmeyi tamamen reddederim.
  - current weights: `{"boundary_firmness": 2.0, "autonomy": 2.0}`
- **B.** Buluşmalara katılırım ama o kişiyle arama buz gibi bir mesafe koyar, sadece diğerleriyle konuşurum.
  - current weights: `{"social_energy": -1.0, "boundary_firmness": 1.0}`
- **C.** Partnerimin hatırı için o kişiyle bile nezaketen sohbet eder, ortamın havasını bozmamaya çalışırım.
  - current weights: `{"adaptability": 2.0, "social_energy": 1.0}`
- **D.** O kişinin yarattığı krizlere/sohbetlere ben de dahil olur, gruptaki dinamiği oyun gibi izlerim.
  - current weights: `{"social_energy": 2.0, "uncertainty_tolerance": 1.0}`

### WHY REWRITE IS REQUIRED

Mevcut kök 'toksik' yüklü. Senaryoyu nötr tut; tanı/ahlak yok.

### TARGET PRIMARY DIMENSION

`boundary_firmness`

### OPTIONAL SECONDARY DIMENSIONS

`social_energy`

### PROPOSED NEW STEM

Partnerinin arkadaş grubunda sık sık gerilim çıkaran biri var. Grup buluşmasında sen ne yaparsın?

### PROPOSED A/B/C/D OPTIONS

- **A.** O kişi varsa bu sefer katılmamayı tercih ederim.
  - proposed weights: `boundary_firmness` +2
- **B.** Giderim ama o kişiyle mesafeli dururum.
  - proposed weights: `boundary_firmness` +1, `social_energy` -1
- **C.** Karşılaşırsam kısa ve nazik kalırım.
  - proposed weights: `boundary_firmness` -1
- **D.** Gruba her zamanki gibi katılırım, o kişiyi ayırmam.
  - proposed weights: `boundary_firmness` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Gerilim üreten birine mesafe koyma netliği. Dedikodu, kriz oyunu veya toksisite dili yok.

### SOCIAL-DESIRABILITY WARNING

Katılmamak sınır koyan, herkese açık olmak olgun görünebilir. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## frequency_v2_q0383

### ORIGINAL STEM

Sen çok gerçekçi, bazen karamsar birisin. Partnerin ise her felakette "Evrene iyi mesaj yollayalım, her şey harika olacak" diyen biri.

### ORIGINAL OPTIONS

- **A.** Bu toksik pozitiflik beni çileden çıkarır, durumun vehametini ona kanıtlamaya çalışırım.
  - current weights: `{"boundary_firmness": 2.0}`
- **B.** Onun bu neşesi zamanla bana da bulaşır, olayları onun gözünden görmeye adapte olurum.
  - current weights: `{"adaptability": 2.0, "uncertainty_tolerance": 1.0}`
- **C.** Onu duymamazlıktan gelir, ben kendi rasyonel ve kötü senaryo planlarımı yapmaya devam ederim.
  - current weights: `{"autonomy": 2.0, "structure_preference": 2.0}`
- **D.** Onun yanında kendimi güvende hisseder, bana verdiği bu umut sayesinde sakinleşirim.
  - current weights: `{"reassurance_need": 2.0, "closeness_pace": 1.0}`

### WHY REWRITE IS REQUIRED

Karamsar/toksik pozitiflik karikatürü var. Uyumu atamadan önce nötr yeniden yaz.

### TARGET PRIMARY DIMENSION

`adaptability`

### OPTIONAL SECONDARY DIMENSIONS

_none_

### PROPOSED NEW STEM

Zor bir durumda sen olası sorunlara göre plan yapıyorsun; partnerin işlerin yoluna gireceğine odaklanıyor. Sen ne yaparsın?

### PROPOSED A/B/C/D OPTIONS

- **A.** Onun bakışına yaklaşır, planı gevşetirim.
  - proposed weights: `adaptability` +2
- **B.** Biraz planımı korur, biraz onun temposuna yaklaşırım.
  - proposed weights: `adaptability` +1
- **C.** Kendi planıma devam ederim; tartışmam.
  - proposed weights: `adaptability` -1
- **D.** Kendi yaklaşımımı sürdürür, uydurmam.
  - proposed weights: `adaptability` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Farklı bakışta uyum ile kendi yöntemi koruma. Felaket, evren mesajı, toksik pozitiflik yok.

### SOCIAL-DESIRABILITY WARNING

Uyumlanan seçenek esnek, kendi planını tutan seçenek inatçı görünebilir. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## frequency_v2_q0008

### ORIGINAL STEM

Partnerin, senin bir davranış tarzını oldukça net ve yapıcı bir şekilde eleştirdi. İlk tepkin genelde nasıl şekillenir?

### ORIGINAL OPTIONS

- **A.** Savunmaya geçmeden önce kendi içimde bunu mantıklı bir şekilde tartmak için sessizleşirim.
  - current weights: `{"disclosure_pace": -1.0}`
- **B.** O an üzüldüğümü veya bozulduğumu saklamam, duygumu anında belli ederim.
  - current weights: `{"disclosure_pace": 1.0}`
- **C.** Eleştirideki haklı payını hemen kabul eder, durumu düzeltmek için esneklik gösteririm.
  - current weights: `{"boundary_firmness": -2.0, "adaptability": 2.0}`
- **D.** Kendi doğrumu ve neden öyle davrandığımı net bir argümanla açıklarım.
  - current weights: `{"boundary_firmness": 2.0, "autonomy": 1.0}`

### WHY REWRITE IS REQUIRED

Yapıcı eleştiriye tepki açıklama hızı, savunma, esneklik ve argümanı karıştırıyor.

### TARGET PRIMARY DIMENSION

`disclosure_pace`

### OPTIONAL SECONDARY DIMENSIONS

_none_

### PROPOSED NEW STEM

Partnerin bir davranışını yapıcı biçimde eleştirdi. Tepkini ne kadar çabuk açarsın?

### PROPOSED A/B/C/D OPTIONS

- **A.** Etkilendiğimi hemen söylerim.
  - proposed weights: `disclosure_pace` +2
- **B.** Kısa bir tepki veririm; ayrıntıyı biraz sonra açarım.
  - proposed weights: `disclosure_pace` +1
- **C.** Önce sessiz kalır, toparlanınca dönerim.
  - proposed weights: `disclosure_pace` -1
- **D.** O an içimde tutar, sonra açar mıyım bakmam.
  - proposed weights: `disclosure_pace` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Eleştiri anında tepkiyi paylaşma temposu. Haklıyı kabul / savunma ayrı eksen değil.

### SOCIAL-DESIRABILITY WARNING

Hemen açmak samimi, tutmak olgun özdenetim görünebilir. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## frequency_v2_q0018

### ORIGINAL STEM

Beklenmedik büyük bir ortak masraf (örn: aracın bozulması, evin bir masrafı) çıktı.

### ORIGINAL OPTIONS

- **A.** Hızla bütçe analizi yapar, alternatifleri listeler, duygusal tepki vermeden çözerim.
  - current weights: `{"structure_preference": 1.0}`
- **B.** Stresimi partnerimle paylaşır, bu zorlukta onun "hallederiz" desteğine ihtiyaç duyarım.
  - current weights: `{"reassurance_need": 2.0}`
- **C.** Akışına bırakırım, çok paniklemem, "bir şekilde çözülür" der geçerim.
  - current weights: `{"uncertainty_tolerance": 2.0, "structure_preference": -2.0}`
- **D.** Onun nasıl bir tepki verdiğine bakar, paniği o yaşıyorsa onu sakinleştiren taraf olurum.
  - current weights: `{"adaptability": 2.0, "autonomy": -1.0}`

### WHY REWRITE IS REQUIRED

Beklenmedik masraf maddesi plan, güvence, akış ve partneri sakinleştirmeyi karıştırıyor.

### TARGET PRIMARY DIMENSION

`uncertainty_tolerance`

### OPTIONAL SECONDARY DIMENSIONS

`structure_preference`

### PROPOSED NEW STEM

Beklenmedik ortak bir masraf çıktı; henüz net bir çözüm yok. Sen ne yaparsın?

### PROPOSED A/B/C/D OPTIONS

- **A.** Bir süre belirsiz bırakır, yoluna gireceğini varsayarım.
  - proposed weights: `uncertainty_tolerance` +2
- **B.** Kaba bir sonraki adım yeter; ayrıntıyı beklerim.
  - proposed weights: `uncertainty_tolerance` +1
- **C.** Bu akşam seçenekleri konuşmak isterim.
  - proposed weights: `structure_preference` +1, `uncertainty_tolerance` -1
- **D.** Rakamları ve planı hemen netleştirmek isterim.
  - proposed weights: `structure_preference` +2, `uncertainty_tolerance` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Çözülmemiş masrafla durabilme. Kim sakinleştirir veya kimin suçu yok.

### SOCIAL-DESIRABILITY WARNING

Hemen plan isteyen düzenli, bekleyen sakin görünebilir. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## frequency_v2_q0043

### ORIGINAL STEM

Partnerin kariyeriyle ilgili çok riskli ve zor bir karar aşamasında ve sana danıştı.

### ORIGINAL OPTIONS

- **A.** Artıları, eksileri masaya yatırır, en rasyonel kararı alması için analitik bir tablo çizerim.
  - current weights: `{"initiative": 1.0, "structure_preference": 1.0}`
- **B.** "Senin içinden ne geçiyor? Seni ne mutlu edecek?" diyerek onun duygularına ayna tutarım.
  - current weights: `{"closeness_pace": 1.0}`
- **C.** "Ne karar verirsen ver, ben senin arkandayım" diyerek ona koşulsuz onay veririm.
  - current weights: `{"reassurance_need": -1.0, "adaptability": 1.0}`
- **D.** Kendi fikrimi netçe söyler, benim tavsiyeme uymasını açıkça savunurum.
  - current weights: `{"boundary_firmness": 2.0, "initiative": 2.0}`

### WHY REWRITE IS REQUIRED

Kariyer kararı maddesi analitik tablo, duygu aynası, koşulsuz onay ve tavsiyeyi dayatmayı menüleştiriyor.

### TARGET PRIMARY DIMENSION

`autonomy`

### OPTIONAL SECONDARY DIMENSIONS

_none_

### PROPOSED NEW STEM

Partnerin riskli bir kariyer kararı için sana danıştı. Sen ne yaparsın?

### PROPOSED A/B/C/D OPTIONS

- **A.** Kararı onda bırakır, yönlendirmem.
  - proposed weights: `autonomy` +2
- **B.** Soru sorarım; seçimi onun yapmasını isterim.
  - proposed weights: `autonomy` +1
- **C.** Kendi tercihimı bir girdi olarak söylerim.
  - proposed weights: `autonomy` -1
- **D.** Bence doğru yolu savunur, ona yaklaşmasını isterim.
  - proposed weights: `autonomy` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Kararı onda bırakma ile kendi yolunu dayatma. Koşulsuz onay ahlakı yok.

### SOCIAL-DESIRABILITY WARNING

Kararı bırakmak saygılı, net tavsiye ilgili görünebilir. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## frequency_v2_q0070

### ORIGINAL STEM

Karşı taraf duygusal olarak yoğun bir dönemden geçiyor ve bunu seninle paylaşıyor.

### ORIGINAL OPTIONS

- **A.** Dinlerim, yanında olurum, çözüm önermem.
  - current weights: `{"repair_style": 1.0, "adaptability": 1.0}`
- **B.** Pratik önerilerle yardımcı olmaya çalışırım.
  - current weights: `{"repair_style": -1.0}`
- **C.** Kendi benzer deneyimlerimi anlatırım.
  - current weights: `{"disclosure_pace": 1.0}`
- **D.** Biraz mesafe koyup toparlanmasını beklerim.
  - current weights: `{"autonomy": 2.0, "boundary_firmness": 1.0}`

### WHY REWRITE IS REQUIRED

Yoğun dönemde dinleme, çözüm, kendi hikaye ve mesafe dört ayrı destek stili; otonomi tek eksen değil.

### TARGET PRIMARY DIMENSION

`autonomy`

### OPTIONAL SECONDARY DIMENSIONS

_none_

### PROPOSED NEW STEM

Partnerin yoğun bir dönemden geçtiğini seninle paylaşıyor. Kendi alanını nasıl tutarsın?

### PROPOSED A/B/C/D OPTIONS

- **A.** Kendi akşam planımı sürdürürüm; beni bulabilir.
  - proposed weights: `autonomy` +2
- **B.** Yakında olurum ama kendi işime de devam ederim.
  - proposed weights: `autonomy` +1
- **C.** Planımı kısar, yanında kalırım.
  - proposed weights: `autonomy` -1
- **D.** Kendi işimi bırakıp o akşam onunla kalırım.
  - proposed weights: `autonomy` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Onun yoğunluğunda kendi alanını koruma. Terapi/dinle-çözme menüsü değil.

### SOCIAL-DESIRABILITY WARNING

Yanında kalmak ilgili, alan tutmak mesafeli görünebilir. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## frequency_v2_q0094

### ORIGINAL STEM

Birlikte bir karar vermeniz gerekiyor (taşınma, büyük harcama, aile meselesi).

### ORIGINAL OPTIONS

- **A.** Uzun uzun konuşuruz.
  - current weights: `{"repair_style": 1.0, "disclosure_pace": 1.0}`
- **B.** Pratik artı-eksi listesi yaparız.
  - current weights: `{"structure_preference": 1.0, "repair_style": -1.0}`
- **C.** Benim net tercihim varsa onu savunurum.
  - current weights: `{"boundary_firmness": 1.0, "initiative": 1.0}`
- **D.** Onun tercihine yaklaşırım.
  - current weights: `{"adaptability": 2.0}`

### WHY REWRITE IS REQUIRED

Ortak karar maddesi uzun konuşma, liste, savunma ve uyumu karıştırıyor; inisiyatif net değil.

### TARGET PRIMARY DIMENSION

`initiative`

### OPTIONAL SECONDARY DIMENSIONS

_none_

### PROPOSED NEW STEM

Taşınma, büyük harcama veya aile gibi ortak bir karar gerekiyor. Süreci kim başlatır?

### PROPOSED A/B/C/D OPTIONS

- **A.** Konuyu ben açar, bir sonraki adıma taşırım.
  - proposed weights: `initiative` +2
- **B.** Bir seçenek veya zaman öneririm.
  - proposed weights: `initiative` +1
- **C.** O başlatınca katılırım.
  - proposed weights: `initiative` -1
- **D.** O bir tercih getirene kadar beklerim.
  - proposed weights: `initiative` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Karar sürecini başlatma. Uzun konuşma vs liste ayrı birincil değil.

### SOCIAL-DESIRABILITY WARNING

Başlatmak lider, beklemek uyumlu görünebilir. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## frequency_v2_q0099

### ORIGINAL STEM

İlişki bir süredir “idare ediyor” ama heyecan azalmış gibi.

### ORIGINAL OPTIONS

- **A.** Konuşup ne yapılabileceğine bakarız.
  - current weights: `{"initiative": 2.0, "repair_style": 1.0}`
- **B.** Kabul eder, devam ederim.
  - current weights: `{"uncertainty_tolerance": 1.0, "adaptability": 1.0}`
- **C.** Kendi hayatımı zenginleştiririm.
  - current weights: `{"autonomy": 2.0}`
- **D.** Mesafe koyup değerlendiririm.
  - current weights: `{"autonomy": 1.0, "boundary_firmness": 1.0}`

### WHY REWRITE IS REQUIRED

Heyecan azalınca konuşma, kabul, kendi hayatı ve mesafe menüsü; inisiyatif tek başına durmuyor.

### TARGET PRIMARY DIMENSION

`initiative`

### OPTIONAL SECONDARY DIMENSIONS

_none_

### PROPOSED NEW STEM

İlişki bir süredir idare ediyor, tempo düşmüş gibi. Sen ne yaparsın?

### PROPOSED A/B/C/D OPTIONS

- **A.** Ne değiştirebileceğimizi ben açarım.
  - proposed weights: `initiative` +2
- **B.** Küçük bir ortak plan öneririm.
  - proposed weights: `initiative` +1
- **C.** Şimdilik aynı devam ederim.
  - proposed weights: `initiative` -1
- **D.** O getirmezse ben açmam.
  - proposed weights: `initiative` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Düşen tempoda ilk adımı atma. İlişkiyi bitirme veya değerlendirme tehdidi yok.

### SOCIAL-DESIRABILITY WARNING

Açmak ilgili, bekleyen sakin görünebilir. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## frequency_v2_q0113

### ORIGINAL STEM

Partnerin “Bir saate birkaç arkadaş bize geliyor” dedi. Bundan daha önce haberin yoktu.

### ORIGINAL OPTIONS

- **A.** Hemen moda girer, gelenlerle vakit geçirmekten keyif alırım.
  - current weights: `{"social_energy": 2.0, "structure_preference": -1.0}`
- **B.** Ağırlarım ama daha sonra önceden haber verilmesinin benim için önemli olduğunu söylerim.
  - current weights: `{"boundary_firmness": 2.0, "structure_preference": 1.0}`
- **C.** O buluşmaya katılmak zorunda hissetmem; gerekirse kendi planımı yaparım.
  - current weights: `{"autonomy": 2.0, "boundary_firmness": 1.0}`
- **D.** İlk anda istemesem de onun planına uyum sağlarım.
  - current weights: `{"adaptability": 2.0, "boundary_firmness": -1.0}`

### WHY REWRITE IS REQUIRED

Habersiz misafir maddesi sosyal enerji, sınır, otonomi ve uyumu karıştırıyor. Yapı/haber tercihi tek değil.

### TARGET PRIMARY DIMENSION

`structure_preference`

### OPTIONAL SECONDARY DIMENSIONS

_none_

### PROPOSED NEW STEM

Partnerin 'bir saate birkaç arkadaş geliyor' dedi; önceden haber yoktu. Sen ne yaparsın?

### PROPOSED A/B/C/D OPTIONS

- **A.** Bu akşamki planımı korur, bu sefer katılmamayı tercih ederim.
  - proposed weights: `structure_preference` +2
- **B.** Kısa uğrar, sonra kendi planıma dönerim.
  - proposed weights: `structure_preference` +1
- **C.** Planımı kaydırır, bu gelişi karşılarım.
  - proposed weights: `structure_preference` -1
- **D.** Kendi planımı bırakır, geceyi gelenlere göre değiştiririm.
  - proposed weights: `structure_preference` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Son dakika plan değişikliğine ne kadar yapıştığın. Misafir düşmanlığı yok.

### SOCIAL-DESIRABILITY WARNING

Planı korumak kuralcı, uyum esnek görünebilir. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## frequency_v2_q0180

### ORIGINAL STEM

İkinizi de etkileyen ortak bir maddi kayıp (örn: yanlış bir yatırım veya yüksek bir trafik cezası) yaşandı.

### ORIGINAL OPTIONS

- **A.** Suçlunun kim olduğuna odaklanmadan hemen zararı nasıl kapatacağımızın matematiksel planını yaparım.
  - current weights: `{"structure_preference": 2.0}`
- **B.** Çok üzülür, moral bozukluğumu günlerce üzerimden atamam, onun beni teselli etmesini beklerim.
  - current weights: `{"reassurance_need": 1.0}`
- **C.** "Cana geleceğine mala gelsin" diyerek konuyu hızla kapatır, akışa devam ederim.
  - current weights: `{"uncertainty_tolerance": 2.0, "structure_preference": -2.0}`
- **D.** Partnerim eğer çok stres yaptıysa, kendi stresimi gizleyip sürekli onu telkin etmeye odaklanırım.
  - current weights: `{"adaptability": 2.0, "boundary_firmness": -1.0}`

### WHY REWRITE IS REQUIRED

Maddi kayıp maddesi plan, teselli bekleme, akış ve partneri yatıştırmayı karıştırıyor.

### TARGET PRIMARY DIMENSION

`structure_preference`

### OPTIONAL SECONDARY DIMENSIONS

_none_

### PROPOSED NEW STEM

İkinizi de etkileyen ortak bir maddi kayıp oldu. Sen ne yaparsın?

### PROPOSED A/B/C/D OPTIONS

- **A.** Zararı nasıl kapatacağımızın adımlarını hemen yazarım.
  - proposed weights: `structure_preference` +2
- **B.** Bu hafta için bir sonraki adımı netleştiririm.
  - proposed weights: `structure_preference` +1
- **C.** Birkaç gün bekler, sonra planlarız.
  - proposed weights: `structure_preference` -1
- **D.** Plan yapmadan günlük düzene dönerim.
  - proposed weights: `structure_preference` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Kayıptan sonra plan kurma. Suçlu arama veya teselli menüsü yok.

### SOCIAL-DESIRABILITY WARNING

Plan yapan sorumlu, bekleyen sakin görünebilir. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## frequency_v2_q0183

### ORIGINAL STEM

Sen ağlayarak veya çok sinirli bir şekilde bir derdini anlatırken, partnerin sürekli "Şöyle yapmalısın, şurayı ara" diye çözümler sunuyor.

### ORIGINAL OPTIONS

- **A.** Bana akıl vermesi değil, sadece "çok haklısın, ne kadar üzücü" demesi gerektiği için sinirlenirim.
  - current weights: `{"reassurance_need": 1.0}`
- **B.** Onun beni önemseme şeklinin bu olduğunu anlar, verdiği tavsiyeleri mantık süzgecinden geçiririm.
  - current weights: `{"adaptability": 1.0}`
- **C.** "Lütfen sadece beni dinle" diyerek konuşmanın kurallarını net bir şekilde çizerim.
  - current weights: `{"boundary_firmness": 2.0, "disclosure_pace": 1.0}`
- **D.** Onu susturmam, çözüm önerilerini hevesle dinleyip, haklı bulduklarımı uygulamaya başlarım.
  - current weights: `{"adaptability": 1.0, "initiative": -1.0}`

### WHY REWRITE IS REQUIRED

Derken çözüm önerisi maddesi güvence, uyum, kural çizme ve önerileri uygulamayı karıştırıyor.

### TARGET PRIMARY DIMENSION

`boundary_firmness`

### OPTIONAL SECONDARY DIMENSIONS

_none_

### PROPOSED NEW STEM

Bir derdini anlatırken partnerin sürekli çözüm öneriyor. Sen ne yaparsın?

### PROPOSED A/B/C/D OPTIONS

- **A.** Şimdi çözüm değil dinleme istediğimi söyleyip öneriyi durdururum.
  - proposed weights: `boundary_firmness` +2
- **B.** Önce dinlemesini, öneriyi sonraya bırakmasını isterim.
  - proposed weights: `boundary_firmness` +1
- **C.** Önerileri kesmem; işime yarayanı alırım.
  - proposed weights: `boundary_firmness` -1
- **D.** Tercih söylemeden önerileri dinlerim.
  - proposed weights: `boundary_firmness` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Tavsiye akışına sınır koyma. 'Sadece doğrula' ahlakı yok.

### SOCIAL-DESIRABILITY WARNING

Sınır koymak olgun iletişim, öneriyi dinlemek uysal görünebilir. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## frequency_v2_q0192

### ORIGINAL STEM

Partnerin hiç beklemediğin bir anda, çok küçük bir sebepten dolayı sinirleri bozulup ağlamaya başladı.

### ORIGINAL OPTIONS

- **A.** Hemen sarılır, onunla beraber duyguya girer, sakinleşene kadar fiziksel temas kurarım.
  - current weights: `{"closeness_pace": 2.0}`
- **B.** Sakin ve şefkatli kalır, "Buna bu kadar üzülmenin asıl sebebi ne?" diye sorarak kök sorunu anlamaya çalışırım.
  - current weights: `{"initiative": 1.0}`
- **C.** Ağlama krizlerinde ne yapacağımı pek bilemem, paniklerim ve biraz mesafeli dururum.
  - current weights: `{"uncertainty_tolerance": -2.0, "autonomy": 1.0}`
- **D.** Onu yalnız bırakır, rahatça ağlaması ve toparlanması için ona mahremiyet tanırım.
  - current weights: `{"autonomy": 2.0, "closeness_pace": -2.0}`

### WHY REWRITE IS REQUIRED

Ani ağlama maddesi kaynaşma, kök neden sorma, panik ve mahremiyeti karıştırıyor.

### TARGET PRIMARY DIMENSION

`autonomy`

### OPTIONAL SECONDARY DIMENSIONS

_none_

### PROPOSED NEW STEM

Partnerin küçük bir sebeple beklenmedik biçimde ağlamaya başladı. Sen ne yaparsın?

### PROPOSED A/B/C/D OPTIONS

- **A.** Toparlanması için ona alan bırakırım.
  - proposed weights: `autonomy` +2
- **B.** Yakında dururum; üstüne gitmem.
  - proposed weights: `autonomy` +1
- **C.** Yanında otururum, geçene kadar kalırım.
  - proposed weights: `autonomy` -1
- **D.** Yanından ayrılmam, yakın durmaya devam ederim.
  - proposed weights: `autonomy` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Ani duyguda alan bırakma ile yakın kalma. Panik veya tanı yok.

### SOCIAL-DESIRABILITY WARNING

Sarılmak şefkatli, alan vermek saygılı görünebilir. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## frequency_v2_q0266

### ORIGINAL STEM

Partnerin, o gün yapması gereken ve senin için de önemli olan basit bir evrak işini unuttu.

### ORIGINAL OPTIONS

- **A.** Hayal kırıklığı yaşarım ve onun bu sorumsuzluğunu ciddi bir konuşmaya çeviririm.
  - current weights: `{"structure_preference": 2.0, "boundary_firmness": 1.0}`
- **B.** Kızsam da "Tamam ben hallederim" diyerek işi ondan alır ve hızla kendim çözerim.
  - current weights: `{"initiative": 2.0}`
- **C.** "Canın sağ olsun, yarın yaparsın" der geçerim, bu tür şeyleri büyütmem.
  - current weights: `{"uncertainty_tolerance": 2.0, "structure_preference": -2.0}`
- **D.** Kendisini kötü hissetmesin diye "Olur öyle, çok yoğundun zaten" diyerek onu teselli ederim.
  - current weights: `{"adaptability": 2.0}`

### WHY REWRITE IS REQUIRED

Unutulan evrak maddesi hayal kırıklığı konuşması, işi kapma, geçiştirme ve teselliyi karıştırıyor.

### TARGET PRIMARY DIMENSION

`boundary_firmness`

### OPTIONAL SECONDARY DIMENSIONS

_none_

### PROPOSED NEW STEM

Partnerin, senin için de önemli olan basit bir işi unuttu. Sen ne yaparsın?

### PROPOSED A/B/C/D OPTIONS

- **A.** Bunun benim için önemli olduğunu söyler, ne zaman tamamlanacağını netleştiririm.
  - proposed weights: `boundary_firmness` +2
- **B.** Bir kez hatırlatır, sonrası ona bırakırım.
  - proposed weights: `boundary_firmness` +1
- **C.** Bu sefer işi ben alırım.
  - proposed weights: `boundary_firmness` -1
- **D.** Üstüne gitmem, geçerim.
  - proposed weights: `boundary_firmness` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Kaçırılan işi sınır olarak adlandırma. Sorumsuzluk etiketi yok.

### SOCIAL-DESIRABILITY WARNING

Netleştirmek yetişkin, geçmek kolay görünebilir. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## frequency_v2_q0271

### ORIGINAL STEM

Tatilde kiraladığınız otel odası fotoğraflardaki gibi çıkmadı, berbat durumda. Partnerin çok sinirlendi.

### ORIGINAL OPTIONS

- **A.** Onun sinirine hak verir, ben de onunla birlikte otel yönetimine veya duruma öfkelenirim.
  - current weights: `{"adaptability": 1.0}`
- **B.** Onu sakinleştirip "Çözüm bulalım, başka otellere bakalım" diyerek anında kriz yöneticisi olurum.
  - current weights: `{"initiative": 2.0}`
- **C.** "Bunda da bir hayır vardır, odayı sadece uyumak için kullanacağız" diyerek durumu önemsizleştiririm.
  - current weights: `{"uncertainty_tolerance": 2.0, "structure_preference": -2.0}`
- **D.** O sinirliyken uzak durur, sinirinin yatışmasını bekler, bu sırada kendi alternatiflerimi sessizce araştırırım.
  - current weights: `{"initiative": 1.0, "autonomy": 1.0}`

### WHY REWRITE IS REQUIRED

Otel odası maddesi öfkeye katılma, kriz yönetimi, önemsizleştirme ve uzak durmayı karıştırıyor.

### TARGET PRIMARY DIMENSION

`adaptability`

### OPTIONAL SECONDARY DIMENSIONS

_none_

### PROPOSED NEW STEM

Tatilde oda beklediğiniz gibi çıkmadı. Partnerin sinirlendi. Sen ne yaparsın?

### PROPOSED A/B/C/D OPTIONS

- **A.** Onun tepkisine yaklaşır, birlikte şikayet ederim.
  - proposed weights: `adaptability` +2
- **B.** Biraz eşlik eder, sonra pratik bir çıkış ararım.
  - proposed weights: `adaptability` +1
- **C.** Kendi sakin tempomu korurum; o konuşsun.
  - proposed weights: `adaptability` -1
- **D.** Tepkisini eşlemeden durur, yatışmasını beklerim.
  - proposed weights: `adaptability` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Partnerin tepki temposuna uyum. Kahraman kriz yöneticisi veya 'hayır vardır' nutku yok.

### SOCIAL-DESIRABILITY WARNING

Birlikte sinirlenmek dayanışma, sakin kalmak olgun görünebilir. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## frequency_v2_q0287

### ORIGINAL STEM

İkiniz de çok ilgili olduğunuz tarihi/siyasi bir konuda farklı uçlardasınız. Tartışma hararetlendi.

### ORIGINAL OPTIONS

- **A.** Bu kadar zıt olduğumuz bir konuda tartışmayı hemen keserim, ilişkinin huzurunu fikirlere tercih ederim.
  - current weights: `{"adaptability": 2.0, "boundary_firmness": -1.0}`
- **B.** Saygı çerçevesinde kalarak, argümanlarımı makale ve kanıtlarla sunar, onu ikna etmeye çalışırım.
  - current weights: `{"initiative": 1.0}`
- **C.** Onun düşüncelerini çok sert ve saçma bulursam, açıkça eleştirir ve geri adım atmam.
  - current weights: `{"boundary_firmness": 2.0}`
- **D.** "Söylediklerin de bir bakış açısı tabii" diyerek entelektüel merakla onu deşerim ama kendi fikrimi savunmam.
  - current weights: `{"disclosure_pace": -1.0, "uncertainty_tolerance": 1.0}`

### WHY REWRITE IS REQUIRED

Hararetli görüş ayrılığı maddesi tartışmayı kesme, ikna, sert eleştiri ve fikir savunmamayı karıştırıyor.

### TARGET PRIMARY DIMENSION

`boundary_firmness`

### OPTIONAL SECONDARY DIMENSIONS

_none_

### PROPOSED NEW STEM

İkinizin de önemsediği bir konuda tartışma hararetlendi. Sen ne yaparsın?

### PROPOSED A/B/C/D OPTIONS

- **A.** Bu turu burada keselim derim.
  - proposed weights: `boundary_firmness` +2
- **B.** Kısa kalırsa devam eder, uzarsa durdururum.
  - proposed weights: `boundary_firmness` +1
- **C.** Anlaşmazlığı bir süre daha sürdürürüm.
  - proposed weights: `boundary_firmness` -1
- **D.** Bitene kadar kendi görüşümü taşırım.
  - proposed weights: `boundary_firmness` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Hararet yükselince tartışmaya sınır. Saçma/sert yargı veya ilişki barışı ahlakı yok.

### SOCIAL-DESIRABILITY WARNING

Kesmek olgun, sürdürmek dürüst görünebilir. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## frequency_v2_q0301

### ORIGINAL STEM

Partneriniz kötü bir gün geçirdiğini söylüyor ama detay vermiyor.

### ORIGINAL OPTIONS

- **A.** “Anlatmak ister misin?” diye sorarım.
  - current weights: `{"initiative": 1.0, "contact_need": 1.0, "repair_style": 1.0}`
- **B.** Yanında sessizce kalırım.
  - current weights: `{"contact_need": 1.0, "adaptability": 1.0}`
- **C.** Kendi işime devam ederim, hazır olunca konuşur.
  - current weights: `{"autonomy": 2.0, "uncertainty_tolerance": 1.0}`
- **D.** Pratik bir şeyler öneririm (yemek, yürüyüş vb.).
  - current weights: `{"repair_style": -1.0, "initiative": 1.0}`

### WHY REWRITE IS REQUIRED

Kötü gün / detay yok maddesi sorma, sessiz kalma, işine dönme ve pratik öneriyi karıştırıyor.

### TARGET PRIMARY DIMENSION

`autonomy`

### OPTIONAL SECONDARY DIMENSIONS

_none_

### PROPOSED NEW STEM

Partnerin kötü bir gün geçirdiğini söylüyor, ayrıntı vermiyor. Sen ne yaparsın?

### PROPOSED A/B/C/D OPTIONS

- **A.** Kendi işime devam ederim; o açınca dinlerim.
  - proposed weights: `autonomy` +2
- **B.** Yakında olurum, tekrar sormam.
  - proposed weights: `autonomy` +1
- **C.** Anlatmak isterse dinleyeceğimi bir kez söylerim.
  - proposed weights: `autonomy` -1
- **D.** Ne olduğunu anlamaya çalışır, konuyu açarım.
  - proposed weights: `autonomy` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Hikayeyi çekmeden kendi alanını tutma. Yemek/yürüyüş tamiri yok.

### SOCIAL-DESIRABILITY WARNING

Sormak ilgili, bırakmak saygılı görünebilir. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## frequency_v2_q0391

### ORIGINAL STEM

Birlikte bir kafede otururken, senin eski sevgilinin çok yakın bir arkadaşı masanıza gelip selam verdi.

### ORIGINAL OPTIONS

- **A.** Gerilirim, sadece "Merhaba" derim ve o gidene kadar partnerimle göz temasından kaçınırım.
  - current weights: `{"uncertainty_tolerance": -2.0}`
- **B.** Rahatça sohbet eder, hatta partnerimi de o kişiyle "İşte yeni erkek/kız arkadaşım" diye tanıştırırım.
  - current weights: `{"social_energy": 2.0, "uncertainty_tolerance": 2.0}`
- **C.** Karşımdakine çok soğuk davranarak masadan bir an önce gitmesi için beden dilimi kullanırım.
  - current weights: `{"boundary_firmness": 2.0, "disclosure_pace": -1.0}`
- **D.** Ortamın gerilmemesi için sadece partnerime odaklanır, gelen kişiye kısa cevaplar veririm.
  - current weights: `{"adaptability": 1.0, "reassurance_need": 1.0}`

### WHY REWRITE IS REQUIRED

Eski yakınının arkadaşı maddesi gerilme, tanıştırma, soğuk beden dili ve kısa cevabı karıştırıyor.

### TARGET PRIMARY DIMENSION

`reassurance_need`

### OPTIONAL SECONDARY DIMENSIONS

_none_

### PROPOSED NEW STEM

Kafede eski bir ilişkinin yakını masanıza gelip selam verdi, gitti. Sen ne yaparsın?

### PROPOSED A/B/C/D OPTIONS

- **A.** Partnerine bunun sende bir iz bırakıp bırakmadığını sorarım.
  - proposed weights: `reassurance_need` +2
- **B.** Kısaca tuhaf geldiğini söyler, bırakırım.
  - proposed weights: `reassurance_need` +1
- **C.** Tarihe devam ederim; konuyu açmam.
  - proposed weights: `reassurance_need` -1
- **D.** Sıradan bir karşılaşma gibi geçer, dönmem.
  - proposed weights: `reassurance_need` -2

### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST

Beklenmedik eski-bağ temasından sonra güvence arayıp aramama. Göz kaçırma veya soğuk savaş yok.

### SOCIAL-DESIRABILITY WARNING

Sormak kıskanç, geçmek olgun görünebilir. Kıskançlık tanısı yok. No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.

---

## Safety

- Live draft question text and option weights were **not** modified by this packet.
- Archive IDs remain 426 / 1704.
- V2 remains `runtime_selectable=false`.
- No evidence-layer numbers.

FREQUENCY V2 PHASE 1F FINAL PRIMARY DECISIONS APPLIED — 26 REWRITES AWAIT HUMAN APPROVAL — V2 STILL DORMANT
