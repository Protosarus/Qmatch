# Frequency V2 — semantic primary-dimension review

Phase 1C did **not** auto-set `primary_dimensions` from absolute-weight mass.
The 30 Phase 1B packet leads were **not** applied.

Rule:

1. Keep a clearly valid existing 12D `primary_dimensions` value.
2. If primary is missing (empty), mark `primary_review_pending` in developer review metadata.
3. Selector eligibility must not depend on an invented primary.

**Pending count:** 29

## Pending items

### `frequency_v2_q0003`

- Prompt: Partnerin işten çok gergin ve morali bozuk döndü. Olayı anlatıyor. Senin ilk refleksin ne olur?
- Source primary raw: ['processing_style']
- Source secondary raw: ['reassurance_need']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): initiative abs=1, reassurance_need abs=1, autonomy abs=1, adaptability abs=1, uncertainty_tolerance abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0008`

- Prompt: Partnerin, senin bir davranış tarzını oldukça net ve yapıcı bir şekilde eleştirdi. İlk tepkin genelde nasıl şekillenir?
- Source primary raw: ['processing_style']
- Source secondary raw: ['boundary_style']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): boundary_firmness abs=4, disclosure_pace abs=2, adaptability abs=2, autonomy abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0015`

- Prompt: Stresli bir anında partnerine gereksiz yere sert çıkıştın. 10 dakika sonra durumu fark ettin.
- Source primary raw: ['processing_style']
- Source secondary raw: ['reassurance_need']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): repair_style abs=4, reassurance_need abs=1, boundary_firmness abs=1, uncertainty_tolerance abs=1, disclosure_pace abs=1, autonomy abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0026`

- Prompt: Temel bir inanç veya hayata bakış açısı konusunda partnerinle tamamen zıt olduğunuzu fark ettiniz.
- Source primary raw: ['processing_style']
- Source secondary raw: ['boundary_style']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): boundary_firmness abs=4, adaptability abs=2, initiative abs=1, autonomy abs=1, disclosure_pace abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0029`

- Prompt: Partnerin basit bir unutkanlık yaptı (örn: senin için önemli bir evrakı almayı unuttu) ve bu sana zaman kaybettirdi.
- Source primary raw: ['processing_style']
- Source secondary raw: ['rhythm_adaptation']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): uncertainty_tolerance abs=3, adaptability abs=3, repair_style abs=1, boundary_firmness abs=1, structure_preference abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0043`

- Prompt: Partnerin kariyeriyle ilgili çok riskli ve zor bir karar aşamasında ve sana danıştı.
- Source primary raw: ['processing_style']
- Source secondary raw: ['initiative_tendency']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): initiative abs=3, boundary_firmness abs=2, structure_preference abs=1, closeness_pace abs=1, reassurance_need abs=1, adaptability abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0047`

- Prompt: Evde birlikte önemli bir işi yetiştirirken bilgisayar/internet aniden kilitlendi ve veriler kayboldu.
- Source primary raw: ['conflict_approach']
- Source secondary raw: ['initiative_tendency']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): uncertainty_tolerance abs=3, initiative abs=2, adaptability abs=2, structure_preference abs=2, boundary_firmness abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0163`

- Prompt: Sen iş yerinde berbat ve stresli bir gün geçirdin, partnerin ise harika haberler aldığı enerjik bir gün geçirdi. Akşam buluştunuz.
- Source primary raw: ['processing_style']
- Source secondary raw: ['rhythm_adaptation']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): disclosure_pace abs=5, adaptability abs=2, autonomy abs=2, boundary_firmness abs=1, social_energy abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0166`

- Prompt: Arabada uzun yoldasınız ve bir konu yüzünden sesler yükseldi, kavga çıktı. İdeal çözüm yöntemin nedir?
- Source primary raw: ['processing_style']
- Source secondary raw: ['closeness_pace']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): repair_style abs=4, boundary_firmness abs=4, autonomy abs=2, adaptability abs=2, closeness_pace abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0180`

- Prompt: İkinizi de etkileyen ortak bir maddi kayıp (örn: yanlış bir yatırım veya yüksek bir trafik cezası) yaşandı.
- Source primary raw: ['processing_style']
- Source secondary raw: ['structure_preference']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): structure_preference abs=4, uncertainty_tolerance abs=2, adaptability abs=2, reassurance_need abs=1, boundary_firmness abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0183`

- Prompt: Sen ağlayarak veya çok sinirli bir şekilde bir derdini anlatırken, partnerin sürekli "Şöyle yapmalısın, şurayı ara" diye çözümler sunuyor.
- Source primary raw: ['processing_style']
- Source secondary raw: ['boundary_style']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): adaptability abs=2, boundary_firmness abs=2, reassurance_need abs=1, disclosure_pace abs=1, initiative abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0186`

- Prompt: Büyük bir kavgada bağırdın, çağırdın. Ancak 10 dakika sonra aslında tamamen *senin haksız olduğunu* fark ettin.
- Source primary raw: ['processing_style']
- Source secondary raw: ['boundary_style']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): boundary_firmness abs=4, repair_style abs=3, disclosure_pace abs=2, uncertainty_tolerance abs=1, closeness_pace abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0192`

- Prompt: Partnerin hiç beklemediğin bir anda, çok küçük bir sebepten dolayı sinirleri bozulup ağlamaya başladı.
- Source primary raw: ['processing_style']
- Source secondary raw: ['closeness_pace']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): closeness_pace abs=4, autonomy abs=3, uncertainty_tolerance abs=2, initiative abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0252`

- Prompt: Partnerin evdeyken senin için manevi değeri çok yüksek olan bir eşyayı (örn: eski bir vazo/kupa) yanlışlıkla kırdı.
- Source primary raw: ['processing_style']
- Source secondary raw: ['boundary_style']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): disclosure_pace abs=2, repair_style abs=2, boundary_firmness abs=2, adaptability abs=2, uncertainty_tolerance abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0258`

- Prompt: Çok severek okuduğun derin bir kitabı/makaleyi partnerinle paylaştın ama o "Çok sıkıcıymış" deyip kestirip attı.
- Source primary raw: ['processing_style']
- Source secondary raw: ['closeness_pace']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): boundary_firmness abs=2, uncertainty_tolerance abs=2, autonomy abs=1, initiative abs=1, reassurance_need abs=1, closeness_pace abs=1, adaptability abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0264`

- Prompt: Kendi hayatınla ilgili çok kötü bir haber aldın. Partnerine bu haberi nasıl verirsin?
- Source primary raw: ['processing_style']
- Source secondary raw: ['reassurance_need']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): disclosure_pace abs=4, reassurance_need abs=3, autonomy abs=2, boundary_firmness abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0271`

- Prompt: Tatilde kiraladığınız otel odası fotoğraflardaki gibi çıkmadı, berbat durumda. Partnerin çok sinirlendi.
- Source primary raw: ['processing_style']
- Source secondary raw: ['uncertainty_tolerance']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): initiative abs=3, uncertainty_tolerance abs=2, structure_preference abs=2, adaptability abs=1, autonomy abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0282`

- Prompt: Partnerinin lüks sayılabilecek bir harcaması oldu (örn: pahalı bir çanta/saat), sen ise birikim yapmayı seven birisin.
- Source primary raw: ['processing_style']
- Source secondary raw: ['structure_preference']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): boundary_firmness abs=3, autonomy abs=2, adaptability abs=2, structure_preference abs=1, disclosure_pace abs=1, uncertainty_tolerance abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0287`

- Prompt: İkiniz de çok ilgili olduğunuz tarihi/siyasi bir konuda farklı uçlardasınız. Tartışma hararetlendi.
- Source primary raw: ['processing_style']
- Source secondary raw: ['boundary_style']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): boundary_firmness abs=3, adaptability abs=2, initiative abs=1, disclosure_pace abs=1, uncertainty_tolerance abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0292`

- Prompt: Partnerin elindeki kahveyi tamamen senin yeni bilgisayarının veya çok sevdiğin bir kıyafetinin üstüne döktü.
- Source primary raw: ['processing_style']
- Source secondary raw: ['reassurance_need']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): boundary_firmness abs=2, adaptability abs=2, disclosure_pace abs=2, structure_preference abs=1, reassurance_need abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0295`

- Prompt: Günün stresiyle sessizce ağlamaya başladın. Partnerin odaya girdi. Sen ne yaparsın?
- Source primary raw: ['processing_style']
- Source secondary raw: ['reassurance_need']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): contact_need abs=2, reassurance_need abs=2, autonomy abs=2, initiative abs=1, disclosure_pace abs=1, uncertainty_tolerance abs=1, adaptability abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0346`

- Prompt: Yabancı bir şehre tatile gittiniz. Partnerin navigasyon görevini üstlendi ama sizi tamamen yanlış bir yere götürüp kaybettirdi.
- Source primary raw: ['processing_style']
- Source secondary raw: ['uncertainty_tolerance']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): initiative abs=3, uncertainty_tolerance abs=2, adaptability abs=1, disclosure_pace abs=1, autonomy abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0365`

- Prompt: İlişkiniz için çok önemli bir tarihi (yıldönümü) partnerin tamamen unuttu ve o güne normal bir gün gibi devam ediyor.
- Source primary raw: ['processing_style']
- Source secondary raw: ['structure_preference']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): structure_preference abs=4, reassurance_need abs=2, uncertainty_tolerance abs=2, initiative abs=2, disclosure_pace abs=1, boundary_firmness abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0370`

- Prompt: Gece yarısı partnerinin telefonuna kayıtlı olmayan bir numaradan sadece "Uyudun mu?" mesajı geldi.
- Source primary raw: ['processing_style']
- Source secondary raw: ['uncertainty_tolerance']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): uncertainty_tolerance abs=4, initiative abs=2, reassurance_need abs=1, autonomy abs=1, disclosure_pace abs=1, boundary_firmness abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0377`

- Prompt: Çok lüks bir restoranda yemeğinizi yediniz, hesap geldi ve partnerin cüzdanını/kartını evde unuttuğunu fark etti.
- Source primary raw: ['processing_style']
- Source secondary raw: ['structure_preference']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): boundary_firmness abs=2, uncertainty_tolerance abs=2, reassurance_need abs=2, disclosure_pace abs=2, structure_preference abs=2, adaptability abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0380`

- Prompt: Bir partidesiniz ve partnerin içkiyi fazla kaçırdı, saçmalamaya ve dengesini kaybetmeye başladı.
- Source primary raw: ['processing_style']
- Source secondary raw: ['social_energy']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): social_energy abs=3, initiative abs=2, boundary_firmness abs=2, adaptability abs=2, autonomy abs=2, disclosure_pace abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0383`

- Prompt: Sen çok gerçekçi, bazen karamsar birisin. Partnerin ise her felakette "Evrene iyi mesaj yollayalım, her şey harika olacak" diyen biri.
- Source primary raw: ['processing_style']
- Source secondary raw: ['reassurance_need']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): boundary_firmness abs=2, adaptability abs=2, autonomy abs=2, structure_preference abs=2, reassurance_need abs=2, uncertainty_tolerance abs=1, closeness_pace abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0390`

- Prompt: Sokakta yürürken veya kafedeyken ilişkinizle ilgili çok gergin bir tartışma alevlendi.
- Source primary raw: ['processing_style']
- Source secondary raw: ['social_energy']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): social_energy abs=3, structure_preference abs=2, disclosure_pace abs=1, boundary_firmness abs=1, adaptability abs=1, repair_style abs=1
- Status: `primary_review_pending`

### `frequency_v2_q0392`

- Prompt: Partnerin "Artık diyeti ve sporu bırakıyorum, hayatı yaşayacağım" diyerek aylar süren disiplinini bir günde çöpe attı.
- Source primary raw: ['processing_style']
- Source secondary raw: ['structure_preference']
- Current pool primary: (empty)
- Option 12D abs-mass (review hint only, **not assigned**): initiative abs=3, autonomy abs=2, structure_preference abs=2, adaptability abs=2, uncertainty_tolerance abs=2, closeness_pace abs=1, boundary_firmness abs=1
- Status: `primary_review_pending`

## Not pending

All other items kept their existing canonical 12D primary (including items that gained new option-level dimensions such as `repair_style`). Those new option weights do not rewrite item primary in this phase.

Selector: items with empty primary or `primary_review_pending=true` are excluded from production-like 50-draws. That is a missing-primary gate, not a guessed-primary assignment.
