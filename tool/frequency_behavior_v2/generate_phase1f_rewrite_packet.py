#!/usr/bin/env python3
"""Proposal-only Phase 1F rewrite packet. Does not modify live draft text/weights."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
POOL_PATH = Path(__file__).resolve().parent / "out" / "frequency_behavior_pool_tr_v2_draft1.json"
OUT_PATH = Path(__file__).resolve().parent / "out" / "frequency_behavior_v2_phase1f_rewrite_packet.md"

# Proposal-only. Not applied to the dormant draft pool.
PROPOSALS = {
    "frequency_v2_q0037": {
        "why": "Mevcut A seçeneği 'çözmeden uyuyamam' kapanış/onarım ihtiyacını, B ise uyku/zaman sınırını ölçüyor. İnsan kararı: tek eksen; uyku-sınırı ile kapanış ihtiyacını birincil olarak birleştirmeyin.",
        "primary": "boundary_firmness",
        "secondary": [],
        "stem": "Gece uyumak üzeresin ve çok yorgunsun. Partnerin ilişkinizle ilgili derin bir konuyu şimdi konuşmak istiyor. Sen ne yaparsın?",
        "options": [
            ("A", "Bu gece konuşmayalım, sabah taze kafayla devam edelim derim.", {"boundary_firmness": 2}),
            ("B", "Kısa bir süre dinlerim; sonra uykuya geçmek istediğimi söylerim.", {"boundary_firmness": 1}),
            ("C", "Yorgunsam da bir süre konuşur, sonra uyumayı öneririm.", {"boundary_firmness": -1}),
            ("D", "Konuyu bu gece sürdürmek için uykuyu ertelerim.", {"boundary_firmness": -2}),
        ],
        "contrast": "Dört seçenek, yorgun gecede derin konuşmaya koyulan sınırın netliğinden esnekliğine uzanır. Kapanış ihtiyacı, onarım temposu veya 'çözmeden duramam' dili yok.",
        "sd": "Sınır koymak bazı yanıtlarda daha olgun görünebilir; gece boyunca dinlemek de ilgili görünür. Bu paket kanıt katmanı sayısı atamaz.",
    },
    "frequency_v2_q0163": {
        "why": "Seçenekler enerji uyumu, açıklama sırası, erken kalkma ve otonomiyi aynı anda ölçüyor. Tek birincil eksen yok.",
        "primary": "adaptability",
        "secondary": ["social_energy"],
        "stem": "Sen yorucu bir gün geçirdin; partnerin enerjik ve iyi haberli. Akşam buluştunuz. Sen ne yaparsın?",
        "options": [
            ("A", "Kendi yorgunluğumu bir kenara bırakıp onun temposuna yaklaşırım.", {"adaptability": 2}),
            ("B", "Kısaca yorgun olduğumu söyler, ortak orta bir tempo ararım.", {"adaptability": 1}),
            ("C", "Yanında kalırım ama kendi düşük tempomda otururum.", {"adaptability": -1, "social_energy": -1}),
            ("D", "Bu akşamı kısa tutar, kendi halime çekilirim.", {"adaptability": -2}),
        ],
        "contrast": "Eksen, partnerin enerjisine uyum ile kendi tempo koruma arasındadır. Kim önce gününü anlatır diye ayrı bir açıklama testi yok.",
        "sd": "Uyumlanan seçenek ilgili, erken ayrılan seçenek bencil görünebilir. Davranış temposu ölçülür; erdem skoru yok.",
    },
    "frequency_v2_q0295": {
        "why": "Phase 1C metni hâlâ sarılma/güvence, otonomi, hemen anlatma ve konuyu dağıtmayı aynı maddede karıştırıyor. İnsan kısıtı: tek davranış ekseni.",
        "primary": "disclosure_pace",
        "secondary": [],
        "stem": "Günün stresiyle sessizce ağlamaya başladın. Partnerin odaya girdi. Ne olduğunu ne kadar çabuk paylaşırsın?",
        "options": [
            ("A", "Ne olduğunu hemen anlatırım.", {"disclosure_pace": 2}),
            ("B", "Kısa bir özet veririm; ayrıntıyı biraz sonra açarım.", {"disclosure_pace": 1}),
            ("C", "Şimdilik zamana ihtiyacım var, biraz sonra konuşuruz derim.", {"disclosure_pace": -1}),
            ("D", "O an nedenini söylemem; kendi halime çekilirim.", {"disclosure_pace": -2}),
        ],
        "contrast": "Dört seçenek yalnızca ne kadar çabuk açıldığını ayırır. Sarılma isteği, şaka ile kaçış veya çözüm arama yok.",
        "sd": "Hemen anlatmak samimi, tutmak mesafeli görünebilir. Bu, açıklama temposudur; dürüstlük etiketi değildir.",
    },
    "frequency_v2_q0365": {
        "why": "Unutulan yıldönümü maddesi kırılma/tavır, ritüel anlamsızlığı, şaka ve yüzleştirmeyi karıştırıyor. Güvence arama tek eksen olarak durmuyor.",
        "primary": "reassurance_need",
        "secondary": [],
        "stem": "İlişkiniz için önemli bir tarihi partnerin unuttu ve güne sıradan devam ediyor. Sen ne yaparsın?",
        "options": [
            ("A", "Günün önemini kendim hatırlatır, birlikte işaretlemek isteyip istemediğini sorarım.", {"reassurance_need": 2}),
            ("B", "Kısa bir hatırlatma yaparım; abartmadan geçerim.", {"reassurance_need": 1}),
            ("C", "Günü kendim geçiririm; o getirmezse açmam.", {"reassurance_need": -1}),
            ("D", "Sıradan bir gün gibi devam ederim, kontrol etmem.", {"reassurance_need": -2}),
        ],
        "contrast": "Eksen, günün hâlâ paylaşılan bir işaret olup olmadığını yoklamak ile yoklamamak arasındadır. Tavır, ahlak veya 'kutlama saçma' karikatürü yok.",
        "sd": "Hatırlatmak olgun, umursamamak soğukkanlı görünebilir. Sayısal sosyal-beğenirlik yok.",
    },
    "frequency_v2_q0406": {
        "why": "Derin konuşmaya geçmek, hafif tutmak, kısa dinlemek ve kendi aktiviteyi önermek dört ayrı eksen. Bu geceki sınır tek başına durmuyor.",
        "primary": "boundary_firmness",
        "secondary": [],
        "stem": "Birlikte evdesiniz. Partnerin derin bir konu açmak istiyor; sen bu akşam hafif vakit geçirmek istiyorsun. Sen ne yaparsın?",
        "options": [
            ("A", "Bu akşam hafif kalalım, derin konuyu başka zamana bırakalım derim.", {"boundary_firmness": 2}),
            ("B", "Kısa dinlerim; sonra hafif moda dönmek istediğimi söylerim.", {"boundary_firmness": 1}),
            ("C", "Bir süre derin konuşmaya eşlik ederim.", {"boundary_firmness": -1}),
            ("D", "Bu akşamki tercihimden vazgeçip derin konuşmaya geçerim.", {"boundary_firmness": -2}),
        ],
        "contrast": "Dört seçenek bu akşamki derin-konuşma sınırının netliğidir. Açıklama derinliği ayrı birincil değildir.",
        "sd": "Sınır koymak olgun, eşlik etmek ilgili görünebilir. İkisi de makul akşam tercihidir.",
    },
    "frequency_v2_q0039": {
        "why": "Kök 'nasıl hissedersin?' diye soruyor. İnsan kararı: gözlemlenebilir davranış; aday eksen structure_preference.",
        "primary": "structure_preference",
        "secondary": [],
        "stem": "İlişkinizde günler öngörülebilir hale geldi; sürpriz yok. Sen ne yaparsın?",
        "options": [
            ("A", "Aynı günlük düzeni korurum; planı bozmam.", {"structure_preference": 2}),
            ("B", "Düzeni sürdürür, küçük ve planlı bir değişiklik eklerim.", {"structure_preference": 1}),
            ("C", "Arada plansız bir çıkış veya değişiklik yaparım.", {"structure_preference": -1}),
            ("D", "Rutini sık sık bozar, anlık değişikliklere yer açarım.", {"structure_preference": -2}),
        ],
        "contrast": "Düzeni koruma ile plansız bozma arasında tek yapı ekseni. His, huzur/sıkılma etiketleri yok.",
        "sd": "Düzenli seçenek olgun, değişim arayan seçenek canlı görünebilir. Tercih temposudur.",
    },
    "frequency_v2_q0254": {
        "why": "Kök partnerden beklenti soruyor. İnsan kararı: yanıtlayan tarafındaki davranış; hasta gününde temas.",
        "primary": "contact_need",
        "secondary": [],
        "stem": "Ateşin var ve yataktasın. Partnerin evde. Sen ne yaparsın?",
        "options": [
            ("A", "Yanımda oturmasını veya yakın durmasını isterim.", {"contact_need": 2}),
            ("B", "Ara sıra bakmasını isterim; çoğunu dinlenerek geçiririm.", {"contact_need": 1}),
            ("C", "Çoğunu kendim idare ederim; gerekirse seslenirim.", {"contact_need": -1}),
            ("D", "İyileşene kadar teması düşük tutar, yalnız kalmayı tercih ederim.", {"contact_need": -2}),
        ],
        "contrast": "Hasta gününde ne kadar yakın temas istediğin. Partnerin 'ne yapmalı' menüsü değil.",
        "sd": "Yanında istemek şefkat ihtiyacı, yalnız kalmak güçlü görünme baskısı taşıyabilir.",
    },
    "frequency_v2_q0281": {
        "why": "Kök 'ne düşünürsün' diye soruyor. İnsan kararı: kalabalıkta somut yakınlık davranışı.",
        "primary": "closeness_pace",
        "secondary": [],
        "stem": "Kalabalık bir ortamda, arkadaşların veya ailen yanında partnerinle fiziksel yakınlık nasıl olur?",
        "options": [
            ("A", "Doğalsa sarılır veya öperim.", {"closeness_pace": 2}),
            ("B", "El tutmak gibi küçük bir temas yeter.", {"closeness_pace": 1}),
            ("C", "Yakın dururum ama dokunmayı az tutarım.", {"closeness_pace": -1}),
            ("D", "Fiziksel yakınlığı sonraya, ikiniz kalana bırakırım.", {"closeness_pace": -2}),
        ],
        "contrast": "Kamusal ortamda yakınlık temposu. 'Sevgimi saklamam' veya uygunsuzluk ahlakı yok.",
        "sd": "Açık temas özgüvenli, ertelemek saygılı görünebilir. İkisi de olağan tercihtir.",
    },
    "frequency_v2_q0353": {
        "why": "Yemekte telefon, yakınlık temposuna temiz denk gelmiyor. İnsan kararı: tek açık eksen; burada masa sınırı.",
        "primary": "boundary_firmness",
        "secondary": [],
        "stem": "Baş başa yemekte partnerinin telefonu masada, ekran açık, bildirimler geliyor. Sen ne yaparsın?",
        "options": [
            ("A", "Yemek boyunca telefonu kaldırmasını veya kapatmasını isterim.", {"boundary_firmness": 2}),
            ("B", "Ekranı kapatmasını bir kez söylerim.", {"boundary_firmness": 1}),
            ("C", "Bu sefer bir şey demem.", {"boundary_firmness": -1}),
            ("D", "Sınır koyamam; yemeğe telefonla devam ederiz.", {"boundary_firmness": -2}),
        ],
        "contrast": "Ortak yemekte ekran için sınır koyup koymama. Merak, kendi telefonunu çıkarma veya dijital saygı söylemi yok.",
        "sd": "Telefon kaldırtmak ilgili, susmak uyumlu görünebilir.",
    },
    "frequency_v2_q0372": {
        "why": "Mevcut kök 'toksik' yüklü. Senaryoyu nötr tut; tanı/ahlak yok.",
        "primary": "boundary_firmness",
        "secondary": ["social_energy"],
        "stem": "Partnerinin arkadaş grubunda sık sık gerilim çıkaran biri var. Grup buluşmasında sen ne yaparsın?",
        "options": [
            ("A", "O kişi varsa bu sefer katılmamayı tercih ederim.", {"boundary_firmness": 2}),
            ("B", "Giderim ama o kişiyle mesafeli dururum.", {"boundary_firmness": 1, "social_energy": -1}),
            ("C", "Karşılaşırsam kısa ve nazik kalırım.", {"boundary_firmness": -1}),
            ("D", "Gruba her zamanki gibi katılırım, o kişiyi ayırmam.", {"boundary_firmness": -2}),
        ],
        "contrast": "Gerilim üreten birine mesafe koyma netliği. Dedikodu, kriz oyunu veya toksisite dili yok.",
        "sd": "Katılmamak sınır koyan, herkese açık olmak olgun görünebilir.",
    },
    "frequency_v2_q0383": {
        "why": "Karamsar/toksik pozitiflik karikatürü var. Uyumu atamadan önce nötr yeniden yaz.",
        "primary": "adaptability",
        "secondary": [],
        "stem": "Zor bir durumda sen olası sorunlara göre plan yapıyorsun; partnerin işlerin yoluna gireceğine odaklanıyor. Sen ne yaparsın?",
        "options": [
            ("A", "Onun bakışına yaklaşır, planı gevşetirim.", {"adaptability": 2}),
            ("B", "Biraz planımı korur, biraz onun temposuna yaklaşırım.", {"adaptability": 1}),
            ("C", "Kendi planıma devam ederim; tartışmam.", {"adaptability": -1}),
            ("D", "Kendi yaklaşımımı sürdürür, uydurmam.", {"adaptability": -2}),
        ],
        "contrast": "Farklı bakışta uyum ile kendi yöntemi koruma. Felaket, evren mesajı, toksik pozitiflik yok.",
        "sd": "Uyumlanan seçenek esnek, kendi planını tutan seçenek inatçı görünebilir.",
    },
    "frequency_v2_q0008": {
        "why": "Yapıcı eleştiriye tepki açıklama hızı, savunma, esneklik ve argümanı karıştırıyor.",
        "primary": "disclosure_pace",
        "secondary": [],
        "stem": "Partnerin bir davranışını yapıcı biçimde eleştirdi. Tepkini ne kadar çabuk açarsın?",
        "options": [
            ("A", "Etkilendiğimi hemen söylerim.", {"disclosure_pace": 2}),
            ("B", "Kısa bir tepki veririm; ayrıntıyı biraz sonra açarım.", {"disclosure_pace": 1}),
            ("C", "Önce sessiz kalır, toparlanınca dönerim.", {"disclosure_pace": -1}),
            ("D", "O an içimde tutar, sonra açar mıyım bakmam.", {"disclosure_pace": -2}),
        ],
        "contrast": "Eleştiri anında tepkiyi paylaşma temposu. Haklıyı kabul / savunma ayrı eksen değil.",
        "sd": "Hemen açmak samimi, tutmak olgun özdenetim görünebilir.",
    },
    "frequency_v2_q0018": {
        "why": "Beklenmedik masraf maddesi plan, güvence, akış ve partneri sakinleştirmeyi karıştırıyor.",
        "primary": "uncertainty_tolerance",
        "secondary": ["structure_preference"],
        "stem": "Beklenmedik ortak bir masraf çıktı; henüz net bir çözüm yok. Sen ne yaparsın?",
        "options": [
            ("A", "Bir süre belirsiz bırakır, yoluna gireceğini varsayarım.", {"uncertainty_tolerance": 2}),
            ("B", "Kaba bir sonraki adım yeter; ayrıntıyı beklerim.", {"uncertainty_tolerance": 1}),
            ("C", "Bu akşam seçenekleri konuşmak isterim.", {"uncertainty_tolerance": -1, "structure_preference": 1}),
            ("D", "Rakamları ve planı hemen netleştirmek isterim.", {"uncertainty_tolerance": -2, "structure_preference": 2}),
        ],
        "contrast": "Çözülmemiş masrafla durabilme. Kim sakinleştirir veya kimin suçu yok.",
        "sd": "Hemen plan isteyen düzenli, bekleyen sakin görünebilir.",
    },
    "frequency_v2_q0043": {
        "why": "Kariyer kararı maddesi analitik tablo, duygu aynası, koşulsuz onay ve tavsiyeyi dayatmayı menüleştiriyor.",
        "primary": "autonomy",
        "secondary": [],
        "stem": "Partnerin riskli bir kariyer kararı için sana danıştı. Sen ne yaparsın?",
        "options": [
            ("A", "Kararı onda bırakır, yönlendirmem.", {"autonomy": 2}),
            ("B", "Soru sorarım; seçimi onun yapmasını isterim.", {"autonomy": 1}),
            ("C", "Kendi tercihimı bir girdi olarak söylerim.", {"autonomy": -1}),
            ("D", "Bence doğru yolu savunur, ona yaklaşmasını isterim.", {"autonomy": -2}),
        ],
        "contrast": "Kararı onda bırakma ile kendi yolunu dayatma. Koşulsuz onay ahlakı yok.",
        "sd": "Kararı bırakmak saygılı, net tavsiye ilgili görünebilir.",
    },
    "frequency_v2_q0070": {
        "why": "Yoğun dönemde dinleme, çözüm, kendi hikaye ve mesafe dört ayrı destek stili; otonomi tek eksen değil.",
        "primary": "autonomy",
        "secondary": [],
        "stem": "Partnerin yoğun bir dönemden geçtiğini seninle paylaşıyor. Kendi alanını nasıl tutarsın?",
        "options": [
            ("A", "Kendi akşam planımı sürdürürüm; beni bulabilir.", {"autonomy": 2}),
            ("B", "Yakında olurum ama kendi işime de devam ederim.", {"autonomy": 1}),
            ("C", "Planımı kısar, yanında kalırım.", {"autonomy": -1}),
            ("D", "Kendi işimi bırakıp o akşam onunla kalırım.", {"autonomy": -2}),
        ],
        "contrast": "Onun yoğunluğunda kendi alanını koruma. Terapi/dinle-çözme menüsü değil.",
        "sd": "Yanında kalmak ilgili, alan tutmak mesafeli görünebilir.",
    },
    "frequency_v2_q0094": {
        "why": "Ortak karar maddesi uzun konuşma, liste, savunma ve uyumu karıştırıyor; inisiyatif net değil.",
        "primary": "initiative",
        "secondary": [],
        "stem": "Taşınma, büyük harcama veya aile gibi ortak bir karar gerekiyor. Süreci kim başlatır?",
        "options": [
            ("A", "Konuyu ben açar, bir sonraki adıma taşırım.", {"initiative": 2}),
            ("B", "Bir seçenek veya zaman öneririm.", {"initiative": 1}),
            ("C", "O başlatınca katılırım.", {"initiative": -1}),
            ("D", "O bir tercih getirene kadar beklerim.", {"initiative": -2}),
        ],
        "contrast": "Karar sürecini başlatma. Uzun konuşma vs liste ayrı birincil değil.",
        "sd": "Başlatmak lider, beklemek uyumlu görünebilir.",
    },
    "frequency_v2_q0099": {
        "why": "Heyecan azalınca konuşma, kabul, kendi hayatı ve mesafe menüsü; inisiyatif tek başına durmuyor.",
        "primary": "initiative",
        "secondary": [],
        "stem": "İlişki bir süredir idare ediyor, tempo düşmüş gibi. Sen ne yaparsın?",
        "options": [
            ("A", "Ne değiştirebileceğimizi ben açarım.", {"initiative": 2}),
            ("B", "Küçük bir ortak plan öneririm.", {"initiative": 1}),
            ("C", "Şimdilik aynı devam ederim.", {"initiative": -1}),
            ("D", "O getirmezse ben açmam.", {"initiative": -2}),
        ],
        "contrast": "Düşen tempoda ilk adımı atma. İlişkiyi bitirme veya değerlendirme tehdidi yok.",
        "sd": "Açmak ilgili, bekleyen sakin görünebilir.",
    },
    "frequency_v2_q0113": {
        "why": "Habersiz misafir maddesi sosyal enerji, sınır, otonomi ve uyumu karıştırıyor. Yapı/haber tercihi tek değil.",
        "primary": "structure_preference",
        "secondary": [],
        "stem": "Partnerin 'bir saate birkaç arkadaş geliyor' dedi; önceden haber yoktu. Sen ne yaparsın?",
        "options": [
            ("A", "Bu akşamki planımı korur, bu sefer katılmamayı tercih ederim.", {"structure_preference": 2}),
            ("B", "Kısa uğrar, sonra kendi planıma dönerim.", {"structure_preference": 1}),
            ("C", "Planımı kaydırır, bu gelişi karşılarım.", {"structure_preference": -1}),
            ("D", "Kendi planımı bırakır, geceyi gelenlere göre değiştiririm.", {"structure_preference": -2}),
        ],
        "contrast": "Son dakika plan değişikliğine ne kadar yapıştığın. Misafir düşmanlığı yok.",
        "sd": "Planı korumak kuralcı, uyum esnek görünebilir.",
    },
    "frequency_v2_q0180": {
        "why": "Maddi kayıp maddesi plan, teselli bekleme, akış ve partneri yatıştırmayı karıştırıyor.",
        "primary": "structure_preference",
        "secondary": [],
        "stem": "İkinizi de etkileyen ortak bir maddi kayıp oldu. Sen ne yaparsın?",
        "options": [
            ("A", "Zararı nasıl kapatacağımızın adımlarını hemen yazarım.", {"structure_preference": 2}),
            ("B", "Bu hafta için bir sonraki adımı netleştiririm.", {"structure_preference": 1}),
            ("C", "Birkaç gün bekler, sonra planlarız.", {"structure_preference": -1}),
            ("D", "Plan yapmadan günlük düzene dönerim.", {"structure_preference": -2}),
        ],
        "contrast": "Kayıptan sonra plan kurma. Suçlu arama veya teselli menüsü yok.",
        "sd": "Plan yapan sorumlu, bekleyen sakin görünebilir.",
    },
    "frequency_v2_q0183": {
        "why": "Derken çözüm önerisi maddesi güvence, uyum, kural çizme ve önerileri uygulamayı karıştırıyor.",
        "primary": "boundary_firmness",
        "secondary": [],
        "stem": "Bir derdini anlatırken partnerin sürekli çözüm öneriyor. Sen ne yaparsın?",
        "options": [
            ("A", "Şimdi çözüm değil dinleme istediğimi söyleyip öneriyi durdururum.", {"boundary_firmness": 2}),
            ("B", "Önce dinlemesini, öneriyi sonraya bırakmasını isterim.", {"boundary_firmness": 1}),
            ("C", "Önerileri kesmem; işime yarayanı alırım.", {"boundary_firmness": -1}),
            ("D", "Tercih söylemeden önerileri dinlerim.", {"boundary_firmness": -2}),
        ],
        "contrast": "Tavsiye akışına sınır koyma. 'Sadece doğrula' ahlakı yok.",
        "sd": "Sınır koymak olgun iletişim, öneriyi dinlemek uysal görünebilir.",
    },
    "frequency_v2_q0192": {
        "why": "Ani ağlama maddesi kaynaşma, kök neden sorma, panik ve mahremiyeti karıştırıyor.",
        "primary": "autonomy",
        "secondary": [],
        "stem": "Partnerin küçük bir sebeple beklenmedik biçimde ağlamaya başladı. Sen ne yaparsın?",
        "options": [
            ("A", "Toparlanması için ona alan bırakırım.", {"autonomy": 2}),
            ("B", "Yakında dururum; üstüne gitmem.", {"autonomy": 1}),
            ("C", "Yanında otururum, geçene kadar kalırım.", {"autonomy": -1}),
            ("D", "Yanından ayrılmam, yakın durmaya devam ederim.", {"autonomy": -2}),
        ],
        "contrast": "Ani duyguda alan bırakma ile yakın kalma. Panik veya tanı yok.",
        "sd": "Sarılmak şefkatli, alan vermek saygılı görünebilir.",
    },
    "frequency_v2_q0266": {
        "why": "Unutulan evrak maddesi hayal kırıklığı konuşması, işi kapma, geçiştirme ve teselliyi karıştırıyor.",
        "primary": "boundary_firmness",
        "secondary": [],
        "stem": "Partnerin, senin için de önemli olan basit bir işi unuttu. Sen ne yaparsın?",
        "options": [
            ("A", "Bunun benim için önemli olduğunu söyler, ne zaman tamamlanacağını netleştiririm.", {"boundary_firmness": 2}),
            ("B", "Bir kez hatırlatır, sonrası ona bırakırım.", {"boundary_firmness": 1}),
            ("C", "Bu sefer işi ben alırım.", {"boundary_firmness": -1}),
            ("D", "Üstüne gitmem, geçerim.", {"boundary_firmness": -2}),
        ],
        "contrast": "Kaçırılan işi sınır olarak adlandırma. Sorumsuzluk etiketi yok.",
        "sd": "Netleştirmek yetişkin, geçmek kolay görünebilir.",
    },
    "frequency_v2_q0271": {
        "why": "Otel odası maddesi öfkeye katılma, kriz yönetimi, önemsizleştirme ve uzak durmayı karıştırıyor.",
        "primary": "adaptability",
        "secondary": [],
        "stem": "Tatilde oda beklediğiniz gibi çıkmadı. Partnerin sinirlendi. Sen ne yaparsın?",
        "options": [
            ("A", "Onun tepkisine yaklaşır, birlikte şikayet ederim.", {"adaptability": 2}),
            ("B", "Biraz eşlik eder, sonra pratik bir çıkış ararım.", {"adaptability": 1}),
            ("C", "Kendi sakin tempomu korurum; o konuşsun.", {"adaptability": -1}),
            ("D", "Tepkisini eşlemeden durur, yatışmasını beklerim.", {"adaptability": -2}),
        ],
        "contrast": "Partnerin tepki temposuna uyum. Kahraman kriz yöneticisi veya 'hayır vardır' nutku yok.",
        "sd": "Birlikte sinirlenmek dayanışma, sakin kalmak olgun görünebilir.",
    },
    "frequency_v2_q0287": {
        "why": "Hararetli görüş ayrılığı maddesi tartışmayı kesme, ikna, sert eleştiri ve fikir savunmamayı karıştırıyor.",
        "primary": "boundary_firmness",
        "secondary": [],
        "stem": "İkinizin de önemsediği bir konuda tartışma hararetlendi. Sen ne yaparsın?",
        "options": [
            ("A", "Bu turu burada keselim derim.", {"boundary_firmness": 2}),
            ("B", "Kısa kalırsa devam eder, uzarsa durdururum.", {"boundary_firmness": 1}),
            ("C", "Anlaşmazlığı bir süre daha sürdürürüm.", {"boundary_firmness": -1}),
            ("D", "Bitene kadar kendi görüşümü taşırım.", {"boundary_firmness": -2}),
        ],
        "contrast": "Hararet yükselince tartışmaya sınır. Saçma/sert yargı veya ilişki barışı ahlakı yok.",
        "sd": "Kesmek olgun, sürdürmek dürüst görünebilir.",
    },
    "frequency_v2_q0301": {
        "why": "Kötü gün / detay yok maddesi sorma, sessiz kalma, işine dönme ve pratik öneriyi karıştırıyor.",
        "primary": "autonomy",
        "secondary": [],
        "stem": "Partnerin kötü bir gün geçirdiğini söylüyor, ayrıntı vermiyor. Sen ne yaparsın?",
        "options": [
            ("A", "Kendi işime devam ederim; o açınca dinlerim.", {"autonomy": 2}),
            ("B", "Yakında olurum, tekrar sormam.", {"autonomy": 1}),
            ("C", "Anlatmak isterse dinleyeceğimi bir kez söylerim.", {"autonomy": -1}),
            ("D", "Ne olduğunu anlamaya çalışır, konuyu açarım.", {"autonomy": -2}),
        ],
        "contrast": "Hikayeyi çekmeden kendi alanını tutma. Yemek/yürüyüş tamiri yok.",
        "sd": "Sormak ilgili, bırakmak saygılı görünebilir.",
    },
    "frequency_v2_q0391": {
        "why": "Eski yakınının arkadaşı maddesi gerilme, tanıştırma, soğuk beden dili ve kısa cevabı karıştırıyor.",
        "primary": "reassurance_need",
        "secondary": [],
        "stem": "Kafede eski bir ilişkinin yakını masanıza gelip selam verdi, gitti. Sen ne yaparsın?",
        "options": [
            ("A", "Partnerine bunun sende bir iz bırakıp bırakmadığını sorarım.", {"reassurance_need": 2}),
            ("B", "Kısaca tuhaf geldiğini söyler, bırakırım.", {"reassurance_need": 1}),
            ("C", "Tarihe devam ederim; konuyu açmam.", {"reassurance_need": -1}),
            ("D", "Sıradan bir karşılaşma gibi geçer, dönmem.", {"reassurance_need": -2}),
        ],
        "contrast": "Beklenmedik eski-bağ temasından sonra güvence arayıp aramama. Göz kaçırma veya soğuk savaş yok.",
        "sd": "Sormak kıskanç, geçmek olgun görünebilir. Kıskançlık tanısı yok.",
    },
}


def fmt_weights(w: dict) -> str:
    parts = []
    for k in sorted(w):
        v = w[k]
        sign = "+" if v > 0 else ""
        parts.append(f"`{k}` {sign}{v}")
    return ", ".join(parts)


def main() -> None:
    pool = json.loads(POOL_PATH.read_text(encoding="utf-8"))
    by = {it["item_id"]: it for it in pool["items"]}
    missing = [i for i in PROPOSALS if i not in by]
    if missing:
        raise SystemExit(f"missing items: {missing}")
    if len(PROPOSALS) != 26:
        raise SystemExit(f"expected 26 proposals, got {len(PROPOSALS)}")

    lines = [
        "# Frequency V2 Phase 1F — Rewrite packet (proposal only)",
        "",
        "Status: **not applied** to the dormant draft pool. Live stems, options, option IDs, and 12D weights are unchanged.",
        "Human approval is required before any rewrite enters the selectable V2 pool.",
        "",
        "Authority: `docs/qmatch_frequency_v2_phase1e_final_human_primary_decisions.txt`",
        "",
        "Rules used here:",
        "- respondent behavior, not what the partner should do",
        "- concrete situational behavior",
        "- exactly one designed primary axis",
        "- four plausible options; no obviously virtuous / awful pair",
        "- no diagnosis, morality, toxicity, attachment, lie/truth labels",
        "- no loaded or caricature language",
        "- useful real-world scenario preserved when possible",
        "- no construct outside the approved 12D",
        "- secondary weights sparse",
        "- authored weights only ±1 / ±2",
        "- no evidence-layer numeric values",
        "",
        "Do not copy these texts into the live draft until a human approves them.",
        "",
    ]

    for iid, spec in PROPOSALS.items():
        it = by[iid]
        letters = "ABCD"
        orig_opts = []
        for i, o in enumerate(it["options"]):
            orig_opts.append(
                f"- **{letters[i]}.** {o['text']}\n  - current weights: `{json.dumps(o['behavioral_weights'], ensure_ascii=False)}`"
            )
        secs = spec["secondary"]
        sec_txt = ", ".join(f"`{s}`" for s in secs) if secs else "_none_"
        prop_opts = []
        for letter, text, w in spec["options"]:
            if set(w.values()) - {-2, -1, 1, 2}:
                raise SystemExit(f"non ±1/±2 weight in {iid} {letter}: {w}")
            if spec["primary"] not in w:
                raise SystemExit(f"{iid} {letter} missing primary weight")
            extra = set(w) - {spec["primary"]} - set(secs)
            if extra:
                raise SystemExit(f"{iid} {letter} extra dims {extra}")
            prop_opts.append(f"- **{letter}.** {text}\n  - proposed weights: {fmt_weights(w)}")
        lines.extend(
            [
                f"## {iid}",
                "",
                "### ORIGINAL STEM",
                "",
                it["prompt"],
                "",
                "### ORIGINAL OPTIONS",
                "",
                *orig_opts,
                "",
                "### WHY REWRITE IS REQUIRED",
                "",
                spec["why"],
                "",
                "### TARGET PRIMARY DIMENSION",
                "",
                f"`{spec['primary']}`",
                "",
                "### OPTIONAL SECONDARY DIMENSIONS",
                "",
                sec_txt,
                "",
                "### PROPOSED NEW STEM",
                "",
                spec["stem"],
                "",
                "### PROPOSED A/B/C/D OPTIONS",
                "",
                *prop_opts,
                "",
                "### WHY THE FOUR OPTIONS FORM ONE COHERENT BEHAVIORAL CONTRAST",
                "",
                spec["contrast"],
                "",
                "### SOCIAL-DESIRABILITY WARNING",
                "",
                spec["sd"]
                + " No numeric `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` is assigned in this phase.",
                "",
                "---",
                "",
            ]
        )

    lines.extend(
        [
            "## Safety",
            "",
            "- Live draft question text and option weights were **not** modified by this packet.",
            "- Archive IDs remain 426 / 1704.",
            "- V2 remains `runtime_selectable=false`.",
            "- No evidence-layer numbers.",
            "",
            "FREQUENCY V2 PHASE 1F FINAL PRIMARY DECISIONS APPLIED — 26 REWRITES AWAIT HUMAN APPROVAL — V2 STILL DORMANT",
            "",
        ]
    )
    OUT_PATH.write_text("\n".join(lines), encoding="utf-8")
    print("wrote", OUT_PATH, "items", len(PROPOSALS))


if __name__ == "__main__":
    main()
