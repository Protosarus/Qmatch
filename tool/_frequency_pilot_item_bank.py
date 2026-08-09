# Turkish Frequency pilot item bank — 50 _spec() calls.

_spec(
    "frequency_tr_v1_communication_pace_001",
    "communication_pace",
    "Yeni eşleşmede ilk günlerde mesajlaşma sıklığı konusunda tercihin?",
    [
        ("A", "Gün içinde birkaç kısa mesajla teması canlı tutarım.", {"communication_pace": 0.75, "social_energy": 0.2}, {"evidence": 0.7, "rationale": "Yüksek erken tempo."}),
        ("B", "Sabah-akşam olmak üzere düzenli ama ölçülü yazarım.", {"communication_pace": 0.45, "depth_preference": 0.2}, {"evidence": 0.6, "rationale": "Orta tempo."}),
        ("C", "Karşı taraf yazana kadar genelde beklerim.", {"communication_pace": -0.3, "stability": 0.3}, {"evidence": 0.55, "rationale": "Pasif tempo."}),
        ("D", "Sadece uygun olduğumda kısa yanıt veririm.", {"communication_pace": -0.6, "disclosure_pace": -0.2}, {"evidence": 0.65, "rationale": "Düşük tempo tercihi."}),
    ],
    "newly_authored",
    "erken tempo vs mesafe",
    "seyrek yazmak ilgisiz değil",
    34,
)

_spec(
    "frequency_tr_v1_communication_pace_002",
    "communication_pace",
    "İlişki ilerledi; uzun vadeli mesajlaşma ritmi konusunda tercihin?",
    [
        ("A", "Gün içinde düzenli kısa temas kurmayı sürdürürüm.", {"communication_pace": 0.75, "stability": 0.2}, {"evidence": 0.7, "rationale": "Sürekli ritim."}),
        ("B", "Haftalık yoğunluğa göre esnek ama öngörülebilir kalırım.", {"communication_pace": 0.45, "depth_preference": 0.2}, {"evidence": 0.6, "rationale": "Dengeli ritim."}),
        ("C", "Birkaç gün sessiz kalabilir, sonra toparlarım.", {"communication_pace": -0.3, "spontaneity": 0.3}, {"evidence": 0.55, "rationale": "Aralıklı tempo."}),
        ("D", "Uzun sessizlikler beni rahatsız etmez.", {"communication_pace": -0.6, "stability": 0.2}, {"evidence": 0.65, "rationale": "Düşük tempo konforu."}),
    ],
    "newly_authored",
    "sürekli temas vs aralık",
    "sessizlik normal olabilir",
    42,
)

_spec(
    "frequency_tr_v1_communication_pace_003",
    "communication_pace",
    "Partnerin birkaç saat yazmadı; sen müsait değilsin ama merak ediyorsun. Ne yaparsın?",
    [
        ("A", "Kısa bir mesaj atıp akışın devam etmesini umarsın.", {"communication_pace": 0.75, "social_energy": 0.2}, {"evidence": 0.7, "extremity": 0.5, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("B", "Gün sonunda toparlayıcı bir mesaj planlarsın.", {"communication_pace": 0.45, "depth_preference": 0.2}, {"evidence": 0.6, "extremity": 0.35, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("C", "O yazana kadar bekler, acil değilse dokunmazsın.", {"communication_pace": -0.3, "stability": 0.3}, {"evidence": 0.55, "extremity": 0.3, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("D", "Uzun sessizliğin normal olduğunu düşünüp mesaj atmazsın.", {"communication_pace": -0.6, "disclosure_pace": -0.2}, {"evidence": 0.65, "extremity": 0.45, "rationale": "Ters çift davranışsal anahtarlama."}),
    ],
    "newly_authored",
    "sessizlikte tempo",
    "beklemek ilgisizlik değil",
    38,
)

_spec(
    "frequency_tr_v1_communication_pace_004",
    "communication_pace",
    "Birlikte yeni bir aktivite planlıyorsunuz; mesajla koordinasyon tarzın?",
    [
        ("A", "Sık mesajlaşıp anlık güncellemeler paylaşırım.", {"communication_pace": 0.75, "social_energy": 0.2}, {"evidence": 0.7, "rationale": "Koordinasyonda yüksek tempo."}),
        ("B", "Birkaç net mesajla planı oturtur, gerektiğinde yazarım.", {"communication_pace": 0.45, "stability": 0.2}, {"evidence": 0.6, "rationale": "Ölçülü koordinasyon."}),
        ("C", "Plan netleşince mesajlaşmayı azaltırım.", {"communication_pace": -0.3, "depth_preference": 0.2}, {"evidence": 0.55, "rationale": "Minimal iletişim."}),
        ("D", "Telefon yerine yüz yüze konuşmayı tercih ederim.", {"communication_pace": -0.6, "social_energy": -0.2}, {"evidence": 0.65, "rationale": "Düşük dijital tempo."}),
    ],
    "newly_authored",
    "anlık koordinasyon vs seyrek",
    "seyrek mesaj plan bozmaz",
    38,
)

_spec(
    "frequency_tr_v1_communication_pace_005",
    "communication_pace",
    "Uzun süredir tanışıyorsunuz; günlük iletişim alışkanlığın nasıl?",
    [
        ("A", "Her gün en az bir kez mutlaka yazışırız.", {"communication_pace": 0.75, "stability": 0.2}, {"evidence": 0.7, "rationale": "Günlük ritim.", "sdr": "moderate"}),
        ("B", "Hafta içi düzenli, hafta sonu daha seyrek olabilir.", {"communication_pace": 0.45, "depth_preference": 0.2}, {"evidence": 0.6, "rationale": "Esnek düzen."}),
        ("C", "İhtiyaç oldukça yazarım, sabit ritim aramam.", {"communication_pace": -0.3, "spontaneity": 0.3}, {"evidence": 0.55, "rationale": "İhtiyaç odaklı tempo."}),
        ("D", "Uzun aralıklar beni endişelendirmez.", {"communication_pace": -0.6, "disclosure_pace": -0.2}, {"evidence": 0.65, "rationale": "Düşük tempo toleransı yüksek."}),
    ],
    "newly_authored",
    "günlük temas vs ihtiyaç",
    "seyrek tempo güvensizlik değil",
    40,
)

_spec(
    "frequency_tr_v1_communication_pace_006",
    "communication_pace",
    "Grup ortamında tanıştığın biriyle bire bir devam edeceksin; mesaj temposu?",
    [
        ("A", "Ayrıldıktan sonra aynı gün birkaç mesaj atarım.", {"communication_pace": 0.75, "social_energy": 0.2}, {"evidence": 0.7, "rationale": "Hızlı bire bir geçiş."}),
        ("B", "Ertesi gün kısa bir mesajla devam ederim.", {"communication_pace": 0.45, "depth_preference": 0.2}, {"evidence": 0.6, "rationale": "Ölçülü takip."}),
        ("C", "O yazana kadar genelde beklerim.", {"communication_pace": -0.3, "stability": 0.3}, {"evidence": 0.55, "rationale": "Pasif tempo."}),
        ("D", "Bir süre sessiz kalıp doğal fırsat beklerim.", {"communication_pace": -0.6, "social_energy": -0.2}, {"evidence": 0.65, "rationale": "Düşük bire bir tempo."}),
    ],
    "newly_authored",
    "bire bir tempo vs bekleme",
    "beklemek ilgisiz değil",
    36,
)

_spec(
    "frequency_tr_v1_communication_pace_007",
    "communication_pace",
    "Cuma akşamı planı netleşmedi; son dakikada mesaj trafiği nasıl olsun?",
    [
        ("A", "Sık mesajlaşıp hızlıca karar vermeye çalışırım.", {"communication_pace": 0.75, "spontaneity": 0.2}, {"evidence": 0.7, "rationale": "Son dakika yüksek tempo."}),
        ("B", "Birkaç net mesajla seçenekleri daraltırım.", {"communication_pace": 0.45, "stability": 0.2}, {"evidence": 0.6, "rationale": "Ölçülü koordinasyon."}),
        ("C", "Karar verilene kadar sessiz kalırım.", {"communication_pace": -0.3, "depth_preference": 0.2}, {"evidence": 0.55, "rationale": "Pasif bekleme."}),
        ("D", "Plan belirsizse mesajlaşmayı minimumda tutarım.", {"communication_pace": -0.6, "stability": 0.2}, {"evidence": 0.65, "rationale": "Düşük belirsizlik temposu."}),
    ],
    "newly_authored",
    "son dakika koordinasyon",
    "az mesaj sabırsızlık değil",
    35,
)

_spec(
    "frequency_tr_v1_communication_pace_008",
    "communication_pace",
    "Haftalık programın tekrarlı; mesajlaşma alışkanlığın oturmuş. Tercihin?",
    [
        ("A", "Gün içinde birkaç kısa check-in yapmayı sürdürürsün.", {"communication_pace": 0.75, "social_energy": 0.2}, {"evidence": 0.7, "extremity": 0.5, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("B", "Sabah ve akşam olmak üzere düzenli ama seyrek temas kurarsın.", {"communication_pace": 0.45, "depth_preference": 0.2}, {"evidence": 0.6, "extremity": 0.35, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("C", "Haftalık ritmine göre birkaç gün sessiz kalabilirsin.", {"communication_pace": -0.3, "stability": 0.3}, {"evidence": 0.55, "extremity": 0.3, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("D", "Uzun aralıklar seni rahatsız etmez; o başlatana kadar beklersin.", {"communication_pace": -0.6, "disclosure_pace": -0.2}, {"evidence": 0.65, "extremity": 0.45, "rationale": "Ters çift davranışsal anahtarlama."}),
    ],
    "newly_authored",
    "rutin tempo",
    "seyrek tempo normal",
    40,
)

_spec(
    "frequency_tr_v1_communication_pace_009",
    "communication_pace",
    "Sohbet yüzeysel konulardan kişisel bir alana kayıyor; mesaj tempon?",
    [
        ("A", "Konu derinleştikçe daha sık yazışmaya devam ederim.", {"communication_pace": 0.75, "depth_preference": 0.2}, {"evidence": 0.7, "rationale": "Derinlikte tempo artışı."}),
        ("B", "Tempoyu korur, biraz daha düşünerek yanıtlarım.", {"communication_pace": 0.45, "disclosure_pace": 0.2}, {"evidence": 0.6, "rationale": "Dengeli tempo."}),
        ("C", "Derin konularda mesajları seyrekleştiririm.", {"communication_pace": -0.3, "stability": 0.3}, {"evidence": 0.55, "rationale": "Derinlikte yavaşlama."}),
        ("D", "Konu ağırlaşınca yazmayı keser, sonra devam ederim.", {"communication_pace": -0.6, "depth_preference": -0.2}, {"evidence": 0.65, "rationale": "Düşük derinlik temposu."}),
    ],
    "newly_authored",
    "derinlikte tempo",
    "yavaşlamak kaçınma değil",
    41,
)

_spec(
    "frequency_tr_v1_depth_preference_001",
    "depth_preference",
    "Yeni eşleşmede ilk mesajlaşmada ne tür bir ton seni daha rahat eder?",
    [
        ("A", "Hafif bir selamdan sonra merak ettiğin bir konuya geçmeyi denerim.", {"depth_preference": 0.6, "communication_pace": 0.2}, {"evidence": 0.65, "rationale": "Erken derinlik tercihi.", "sdr": "moderate"}),
        ("B", "Gündelik bir soru sorar, karşılıklı cevaba göre derinleşirim.", {"depth_preference": 0.3, "disclosure_pace": 0.2}, {"evidence": 0.55, "rationale": "Kademeli derinlik."}),
        ("C", "Esprili ve yüzeysel bir giriş yaparım.", {"depth_preference": -0.3, "social_energy": 0.2}, {"evidence": 0.5, "rationale": "Hafif ton tercihi."}),
        ("D", "Kısa tutar, uygun zamanı beklerim.", {"depth_preference": -0.45, "communication_pace": -0.2}, {"evidence": 0.6, "rationale": "Düşük erken derinlik."}),
    ],
    "newly_authored",
    "erken derinlik vs hafif giriş",
    "dört ton da savunulabilir",
    35,
)

_spec(
    "frequency_tr_v1_depth_preference_002",
    "depth_preference",
    "Sohbet günlük işlerde takılı kaldı; sen konuyu nasıl yönlendirirsin?",
    [
        ("A", "Bu konudan neden önemli olduğuna dair bir soru sorarım.", {"depth_preference": 0.75, "communication_pace": 0.2}, {"evidence": 0.7, "rationale": "Aktif derinleştirme."}),
        ("B", "Biraz daha detay ister, hâlâ pratik kalırım.", {"depth_preference": 0.45, "stability": 0.2}, {"evidence": 0.6, "rationale": "Orta derinlik."}),
        ("C", "Gündemi korur, konu değiştirmem.", {"depth_preference": -0.2, "spontaneity": -0.2}, {"evidence": 0.5, "rationale": "Pratik odak."}),
        ("D", "Sohbeti kısa keserim.", {"depth_preference": -0.6, "social_energy": -0.2}, {"evidence": 0.55, "rationale": "Düşük derinlik tercihi."}),
    ],
    "newly_authored",
    "anlam arayışı vs pratik akış",
    "tek doğru ton yok",
    40,
)

_spec(
    "frequency_tr_v1_depth_preference_003",
    "depth_preference",
    "Partnerin sürekli kısa cevaplar veriyor; sen nasıl devam edersin?",
    [
        ("A", "Açık uçlu bir soru sorarak konuyu derinleştiririm.", {"depth_preference": 0.75, "communication_pace": 0.2}, {"evidence": 0.7, "rationale": "Derinlik girişimi."}),
        ("B", "Tempoyu korur, bir kez daha farklı bir açı denerim.", {"depth_preference": 0.45, "disclosure_pace": 0.2}, {"evidence": 0.6, "rationale": "Ilımlı derinlik."}),
        ("C", "Onun temposuna uyarım, kısa kalırım.", {"depth_preference": -0.3, "stability": 0.2}, {"evidence": 0.55, "rationale": "Uyum odaklı hafiflik."}),
        ("D", "Konuyu bırakır, başka zaman konuşuruz derim.", {"depth_preference": -0.6, "communication_pace": -0.2}, {"evidence": 0.65, "rationale": "Derinlikten kaçınma."}),
    ],
    "newly_authored",
    "derinleştirme vs uyum",
    "kısa cevap ilgisiz okunmaz",
    42,
)

_spec(
    "frequency_tr_v1_depth_preference_004",
    "depth_preference",
    "Bir süredir mesajlaşıyorsunuz; ortam sakin. Konuşmayı nasıl sürdürmeyi tercih edersin?",
    [
        ("A", "Günün nasıl geçtiğinden öte, seni etkileyen düşüncelere geçmeyi teklif edersin.", {"depth_preference": 0.75, "communication_pace": 0.2}, {"evidence": 0.7, "extremity": 0.55, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("B", "Hafif sohbet eder, uygun olduğunda biraz daha kişisel bir konuya yavaşça kayarsın.", {"depth_preference": 0.45, "stability": 0.2}, {"evidence": 0.6, "extremity": 0.4, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("C", "Pratik konularda kalır, derinleşmeden akışı sürdürürsün.", {"depth_preference": -0.2, "spontaneity": 0.3}, {"evidence": 0.5, "extremity": 0.3, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("D", "Kısa tutup sonra tekrar yazmayı planlarsın.", {"depth_preference": -0.6, "social_energy": 0.2}, {"evidence": 0.55, "extremity": 0.35, "rationale": "Ters çift davranışsal anahtarlama."}),
    ],
    "newly_authored",
    "sessizlikte derinlik vs hafiflik",
    "dört yanıt eşit savunulabilir",
    40,
)

_spec(
    "frequency_tr_v1_depth_preference_005",
    "depth_preference",
    "Grup sohbetinde bire bir tanışma fırsatı doğdu; konu seçimin ne olur?",
    [
        ("A", "Ortak bir değer veya motivasyon hakkında soru sorarım.", {"depth_preference": 0.6, "social_energy": 0.2}, {"evidence": 0.65, "rationale": "Grup içi derinlik."}),
        ("B", "Hobiler üzerinden hafif ama kişisel bir bağ kurarım.", {"depth_preference": 0.3, "disclosure_pace": 0.2}, {"evidence": 0.55, "rationale": "Orta düzey."}),
        ("C", "Grup temasını koruyarak genel konuşurum.", {"depth_preference": -0.3, "social_energy": 0.3}, {"evidence": 0.5, "rationale": "Grup odaklı hafiflik."}),
        ("D", "Bire bir ayrılmadan grup akışında kalırım.", {"depth_preference": -0.45, "stability": 0.2}, {"evidence": 0.6, "rationale": "Düşük bire bir derinlik."}),
    ],
    "newly_authored",
    "bire bir derinlik vs grup akışı",
    "grup bire bir ikisi geçerli",
    38,
)

_spec(
    "frequency_tr_v1_depth_preference_006",
    "depth_preference",
    "Uzun süredir mesajlaşıyorsunuz; haftalık check-in zamanı. Tercihin?",
    [
        ("A", "Bu hafta seni en çok etkileyen şeyi paylaşmayı teklif ederim.", {"depth_preference": 0.75, "disclosure_pace": 0.2}, {"evidence": 0.7, "rationale": "Ritüel derinlik."}),
        ("B", "Önemli olayları özetler, gerekirse biraz açarım.", {"depth_preference": 0.45, "communication_pace": 0.2}, {"evidence": 0.6, "rationale": "Dengeli check-in."}),
        ("C", "Kısa bir nasılsın yeterli derim.", {"depth_preference": -0.3, "stability": 0.2}, {"evidence": 0.55, "rationale": "Minimal derinlik."}),
        ("D", "Check-in atlayıp spontane yazarım.", {"depth_preference": -0.45, "spontaneity": 0.3}, {"evidence": 0.5, "rationale": "Yapısız iletişim."}),
    ],
    "newly_authored",
    "ritüel derinlik vs kısa güncelleme",
    "check-in zorunlu değil",
    40,
)

_spec(
    "frequency_tr_v1_depth_preference_007",
    "depth_preference",
    "Birlikte yeni bir aktivite deneyeceksiniz; sohbet tarafında tercihin?",
    [
        ("A", "Aktivite sırasında deneyimlerin anlamını konuşmayı severim.", {"depth_preference": 0.6, "spontaneity": 0.2}, {"evidence": 0.65, "rationale": "Aktivite+derinlik."}),
        ("B", "Ara ara hislerini sorar, çoğunlukla aktiviteye odaklanırım.", {"depth_preference": 0.3, "social_energy": 0.2}, {"evidence": 0.55, "rationale": "Dengeli."}),
        ("C", "Aktiviteye odaklanır, sohbeti hafif tutarım.", {"depth_preference": -0.3, "stability": 0.2}, {"evidence": 0.5, "rationale": "Pratik odak."}),
        ("D", "Sessizce birlikte yapmayı tercih ederim.", {"depth_preference": -0.45, "communication_pace": -0.2}, {"evidence": 0.6, "rationale": "Minimal sözel derinlik."}),
    ],
    "newly_authored",
    "aktivite anlamı vs sade eğlence",
    "sessizlik soğuk sayılmaz",
    36,
)

_spec(
    "frequency_tr_v1_depth_preference_008",
    "depth_preference",
    "Güven oluşmaya başladı; kişisel bir konu açılıyor. Konuşma derinliği tercihin?",
    [
        ("A", "Konunun kökenine inmeyi ve bağlantılarını keşfetmeyi isterim.", {"depth_preference": 0.75, "disclosure_pace": 0.2}, {"evidence": 0.7, "rationale": "Yüksek derinlik."}),
        ("B", "Ortada kalır, somut bir örnekle devam ederim.", {"depth_preference": 0.45, "disclosure_pace": 0.3}, {"evidence": 0.6, "rationale": "Ilımlı derinlik."}),
        ("C", "Konuyu pratik sonuçlara bağlarım.", {"depth_preference": -0.2, "stability": 0.2}, {"evidence": 0.5, "rationale": "Pratik çerçeve."}),
        ("D", "Konuyu kapatıp daha sonra konuşuruz derim.", {"depth_preference": -0.6, "disclosure_pace": -0.2}, {"evidence": 0.55, "rationale": "Erken derinlikten kaçınma."}),
    ],
    "newly_authored",
    "keşif vs pratik sınır",
    "açıklık hızı dürüstlük değil",
    44,
)

_spec(
    "frequency_tr_v1_depth_preference_009",
    "depth_preference",
    "Haftalık rutinin yoğun; tanıştığın biriyle sohbet aralığı açılıyor. Tercihin ne olur?",
    [
        ("A", "Rutini bozup anlam taşıyan bir konuya geçmeyi önerirsin.", {"depth_preference": 0.75, "communication_pace": 0.2}, {"evidence": 0.7, "extremity": 0.55, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("B", "Kısa ama içten bir check-in yapar, uygunsa biraz derinleşirsin.", {"depth_preference": 0.45, "stability": 0.2}, {"evidence": 0.6, "extremity": 0.4, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("C", "Gündelik güncellemelerle yetinir, derin konuyu ertelersin.", {"depth_preference": -0.2, "spontaneity": 0.3}, {"evidence": 0.5, "extremity": 0.3, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("D", "Mesajı minimumda tutar, rutine dönersin.", {"depth_preference": -0.6, "social_energy": 0.2}, {"evidence": 0.55, "extremity": 0.35, "rationale": "Ters çift davranışsal anahtarlama."}),
    ],
    "newly_authored",
    "rutin vs anlam arayışı",
    "kısa tutmak geçerli",
    40,
)

_spec(
    "frequency_tr_v1_disclosure_pace_001",
    "disclosure_pace",
    "Yeni eşleşmede kişisel bilgi paylaşımı konusunda tercihin?",
    [
        ("A", "Erken dönemde bile temel beklentilerimi açıkça paylaşırım.", {"disclosure_pace": 0.75, "depth_preference": 0.2}, {"evidence": 0.7, "rationale": "Erken açıklık.", "sdr": "moderate"}),
        ("B", "Yavaş yavaş, karşılıklı güven oluştukça açarım.", {"disclosure_pace": 0.45, "communication_pace": 0.2}, {"evidence": 0.6, "rationale": "Kademeli açıklık."}),
        ("C", "Genel kalır, kişisel detay vermem.", {"disclosure_pace": -0.3, "stability": 0.3}, {"evidence": 0.55, "rationale": "Yavaş açıklık."}),
        ("D", "Güven oluşana kadar kişisel konuları açmam.", {"disclosure_pace": -0.6, "social_energy": -0.2}, {"evidence": 0.65, "rationale": "Düşük erken açıklık."}),
    ],
    "newly_authored",
    "erken açıklık vs güven",
    "yavaş açıklık gizlilik değil",
    36,
)

_spec(
    "frequency_tr_v1_disclosure_pace_002",
    "disclosure_pace",
    "Güven oluşmaya başladı; geçmiş ilişkilerden bahsediliyor. Tercihin?",
    [
        ("A", "Kendi deneyimlerimi açıkça ve erken paylaşırım.", {"disclosure_pace": 0.75, "depth_preference": 0.2}, {"evidence": 0.7, "rationale": "Erken paylaşım."}),
        ("B", "Temel çerçeveyi verir, ayrıntıları kademeli açarım.", {"disclosure_pace": 0.45, "communication_pace": 0.2}, {"evidence": 0.6, "rationale": "Ilımlı açıklık."}),
        ("C", "Genel kalır, somut örnek vermem.", {"disclosure_pace": -0.3, "stability": 0.3}, {"evidence": 0.55, "rationale": "Yavaş açıklık."}),
        ("D", "Kişisel geçmişi güven tam oluşana kadar saklarım.", {"disclosure_pace": -0.6, "social_energy": -0.2}, {"evidence": 0.65, "rationale": "Düşük erken paylaşım."}),
    ],
    "newly_authored",
    "geçmiş paylaşımı",
    "ertelemek soğukluk değil",
    40,
)

_spec(
    "frequency_tr_v1_disclosure_pace_003",
    "disclosure_pace",
    "Yeni eşleşmede sohbet ilerliyor; kişisel bir konu gündeme geliyor. Ne yaparsın?",
    [
        ("A", "Kendi deneyiminden kısa ama açık bir örnek paylaşırsın.", {"disclosure_pace": 0.75, "depth_preference": 0.2}, {"evidence": 0.7, "extremity": 0.55, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("B", "Konuyu açarsın ama detayları yavaş bırakırsın.", {"disclosure_pace": 0.45, "communication_pace": 0.2}, {"evidence": 0.6, "extremity": 0.4, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("C", "Genel kalır, kişisel örnek vermezsin.", {"disclosure_pace": -0.3, "stability": 0.3}, {"evidence": 0.55, "extremity": 0.35, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("D", "Konuyu değiştirir, daha tanıdık olmayı beklersin.", {"disclosure_pace": -0.6, "social_energy": -0.2}, {"evidence": 0.65, "extremity": 0.45, "rationale": "Ters çift davranışsal anahtarlama."}),
    ],
    "newly_authored",
    "erken kişisel konu",
    "yavaş açıklık gizlilik değil",
    36,
)

_spec(
    "frequency_tr_v1_disclosure_pace_004",
    "disclosure_pace",
    "Güven artıyor; aile veya yakın çevre hakkında konu açılıyor. Ne yaparsın?",
    [
        ("A", "Kendi aile/çevre deneyimlerimi açıkça paylaşırım.", {"disclosure_pace": 0.75, "social_energy": 0.2}, {"evidence": 0.7, "rationale": "Yüksek açıklık."}),
        ("B", "Genel bir çerçeve verir, detayları yavaş bırakırım.", {"disclosure_pace": 0.45, "depth_preference": 0.2}, {"evidence": 0.6, "rationale": "Ilımlı paylaşım."}),
        ("C", "Konuyu yüzeysel tutar, kişisel detay vermem.", {"disclosure_pace": -0.3, "stability": 0.3}, {"evidence": 0.55, "rationale": "Yavaş açıklık."}),
        ("D", "Bu konuları daha tanıdık olunca açmayı tercih ederim.", {"disclosure_pace": -0.6, "communication_pace": -0.2}, {"evidence": 0.65, "rationale": "Düşük erken paylaşım."}),
    ],
    "newly_authored",
    "aile paylaşımı",
    "ertelemek güvensiz değil",
    42,
)

_spec(
    "frequency_tr_v1_disclosure_pace_005",
    "disclosure_pace",
    "Partnerin bir süre sessiz kaldı; yeniden bağlanırken kişisel paylaşım?",
    [
        ("A", "Kendi durumumu açıkça paylaşarak sohbeti yeniden açarım.", {"disclosure_pace": 0.75, "social_energy": 0.2}, {"evidence": 0.7, "rationale": "Açık yeniden bağlanma."}),
        ("B", "Hafif bir kişisel not paylaşır, tempoyu ölçerim.", {"disclosure_pace": 0.45, "communication_pace": 0.2}, {"evidence": 0.6, "rationale": "Ilımlı açıklık."}),
        ("C", "Genel bir selamla devam eder, kişisel detay vermem.", {"disclosure_pace": -0.3, "stability": 0.3}, {"evidence": 0.55, "rationale": "Yavaş açıklık."}),
        ("D", "Sessizlik sonrası kişisel konuları ertelerim.", {"disclosure_pace": -0.6, "depth_preference": -0.2}, {"evidence": 0.65, "rationale": "Düşük erken paylaşım."}),
    ],
    "newly_authored",
    "sessizlik sonrası açıklık",
    "ertelemek mesafe değil",
    38,
)

_spec(
    "frequency_tr_v1_disclosure_pace_006",
    "disclosure_pace",
    "Grup ortamında tanıştığın biriyle bire bir devam edeceksin; kişisel paylaşım?",
    [
        ("A", "Bire bir geçişte temel beklentilerimi erken paylaşırım.", {"disclosure_pace": 0.75, "depth_preference": 0.2}, {"evidence": 0.7, "rationale": "Erken bire bir açıklık."}),
        ("B", "Hafif kişisel bilgi paylaşır, tempoyu ölçerim.", {"disclosure_pace": 0.45, "social_energy": 0.2}, {"evidence": 0.6, "rationale": "Ilımlı paylaşım."}),
        ("C", "Genel konularda kalır, kişisel detay vermem.", {"disclosure_pace": -0.3, "stability": 0.3}, {"evidence": 0.55, "rationale": "Yavaş açıklık."}),
        ("D", "Bire bir olsa da kişisel konuları ertelerim.", {"disclosure_pace": -0.6, "communication_pace": -0.2}, {"evidence": 0.65, "rationale": "Düşük erken paylaşım."}),
    ],
    "newly_authored",
    "bire bir açıklık",
    "ertelemek utangaçlık değil",
    37,
)

_spec(
    "frequency_tr_v1_disclosure_pace_007",
    "disclosure_pace",
    "Bir süredir mesajlaşıyorsunuz; ilişki beklentileri konuşuluyor. Tercihin?",
    [
        ("A", "Kendi beklentilerini açıkça ve erken paylaşırsın.", {"disclosure_pace": 0.75, "depth_preference": 0.2}, {"evidence": 0.7, "extremity": 0.55, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("B", "Temel çerçeveyi verir, ayrıntıları kademeli açarsın.", {"disclosure_pace": 0.45, "communication_pace": 0.2}, {"evidence": 0.6, "extremity": 0.4, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("C", "Yüzeysel kalır, somut paylaşımı ertelersin.", {"disclosure_pace": -0.3, "stability": 0.3}, {"evidence": 0.55, "extremity": 0.35, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("D", "Kişisel beklentileri güven oluşana kadar saklarsın.", {"disclosure_pace": -0.6, "social_energy": -0.2}, {"evidence": 0.65, "extremity": 0.45, "rationale": "Ters çift davranışsal anahtarlama."}),
    ],
    "newly_authored",
    "beklenti paylaşımı",
    "ertelemek soğukluk değil",
    42,
)

_spec(
    "frequency_tr_v1_disclosure_pace_008",
    "disclosure_pace",
    "Güven oluştu; gelecek planları ve beklentiler konuşuluyor. Tercihin?",
    [
        ("A", "Kendi beklentilerimi açıkça ve somut paylaşırım.", {"disclosure_pace": 0.75, "communication_pace": 0.2}, {"evidence": 0.7, "rationale": "Yüksek açıklık."}),
        ("B", "Temel çerçeveyi verir, ayrıntıları kademeli açarım.", {"disclosure_pace": 0.45, "depth_preference": 0.2}, {"evidence": 0.6, "rationale": "Ilımlı paylaşım."}),
        ("C", "Genel kalır, somut beklenti paylaşmam.", {"disclosure_pace": -0.3, "stability": 0.3}, {"evidence": 0.55, "rationale": "Yavaş açıklık."}),
        ("D", "Gelecek planlarını daha netleşince paylaşırım.", {"disclosure_pace": -0.6, "social_energy": -0.2}, {"evidence": 0.65, "rationale": "Düşük erken paylaşım."}),
    ],
    "newly_authored",
    "beklenti açıklığı",
    "ertelemek belirsizlik değil",
    43,
)

_spec(
    "frequency_tr_v1_social_energy_001",
    "social_energy",
    "Hafta sonu arkadaşların küçük bir buluşma organize ediyor; tercihin?",
    [
        ("A", "Enerjik hissediyorsam tüm buluşmaya katılırım.", {"social_energy": 0.75, "spontaneity": 0.2}, {"evidence": 0.7, "rationale": "Yüksek sosyal katılım."}),
        ("B", "Kısa süre gelir, keyifli kısmı yakalarım.", {"social_energy": 0.45, "communication_pace": 0.2}, {"evidence": 0.6, "rationale": "Sınırlı katılım."}),
        ("C", "Bu hafta pas geçip dinlenmeyi tercih ederim.", {"social_energy": -0.3, "stability": 0.3}, {"evidence": 0.55, "rationale": "Enerji koruma."}),
        ("D", "Kalabalık ortam yerine bire bir plan öneririm.", {"social_energy": -0.6, "depth_preference": 0.2}, {"evidence": 0.65, "rationale": "Düşük grup enerjisi."}),
    ],
    "newly_authored",
    "grup katılım vs dinlenme",
    "pas geçmek normal",
    38,
)

_spec(
    "frequency_tr_v1_social_energy_002",
    "social_energy",
    "Yakın çevrenle küçük bir buluşma planlanıyor; sen yorgunsun ama davetlisin. Tercihin?",
    [
        ("A", "Enerjini toparlayıp buluşmaya katılırsın.", {"social_energy": 0.75, "spontaneity": 0.2}, {"evidence": 0.7, "extremity": 0.55, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("B", "Kısa süreli gelir, sonra ayrılmayı planlarsın.", {"social_energy": 0.45, "communication_pace": 0.2}, {"evidence": 0.6, "extremity": 0.4, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("C", "Bu kez pas geçip dinlenmeyi seçersin.", {"social_energy": -0.3, "stability": 0.3}, {"evidence": 0.55, "extremity": 0.35, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("D", "Kalabalıktan kaçınır, bire bir görüşmeyi ertelersin.", {"social_energy": -0.6, "depth_preference": -0.2}, {"evidence": 0.65, "extremity": 0.45, "rationale": "Ters çift davranışsal anahtarlama."}),
    ],
    "newly_authored",
    "grup vs dinlenme",
    "pas geçmek normal",
    38,
)

_spec(
    "frequency_tr_v1_social_energy_003",
    "social_energy",
    "Arkadaş grubun yeni bir mekâna gitmeyi teklif ediyor; sen?",
    [
        ("A", "Hemen katılır, yeni ortamı keşfetmekten keyif alırım.", {"social_energy": 0.75, "spontaneity": 0.2}, {"evidence": 0.7, "rationale": "Yüksek keşif enerjisi."}),
        ("B", "Giderim ama erken ayrılmayı planlayabilirim.", {"social_energy": 0.45, "communication_pace": 0.2}, {"evidence": 0.6, "rationale": "Sınırlı sosyallik."}),
        ("C", "Evde kalmayı tercih ederim.", {"social_energy": -0.3, "stability": 0.3}, {"evidence": 0.55, "rationale": "Düşük dışarı enerjisi."}),
        ("D", "Kalabalık mekân yerine sakin bir alternatif öneririm.", {"social_energy": -0.6, "depth_preference": -0.2}, {"evidence": 0.65, "rationale": "Düşük kalabalık toleransı."}),
    ],
    "newly_authored",
    "yeni mekân vs evde kalma",
    "evde kalmak antisosyal değil",
    37,
)

_spec(
    "frequency_tr_v1_social_energy_004",
    "social_energy",
    "Birlikte yeni bir aktivite deneyeceksiniz; ortam kalabalık olabilir. Tercihin?",
    [
        ("A", "Kalabalık ortamda birlikte vakit geçirmekten keyif alırım.", {"social_energy": 0.75, "spontaneity": 0.2}, {"evidence": 0.7, "rationale": "Kalabalıkta yüksek enerji."}),
        ("B", "Katılırım ama daha sakin bir köşede vakit geçirmeyi tercih ederim.", {"social_energy": 0.45, "depth_preference": 0.2}, {"evidence": 0.6, "rationale": "Ilımlı katılım."}),
        ("C", "Kalabalık yerine daha tenha bir alternatif ararım.", {"social_energy": -0.3, "stability": 0.3}, {"evidence": 0.55, "rationale": "Sakin ortam tercihi."}),
        ("D", "Kalabalık ortamda yalnız kalmayı veya erken ayrılmayı tercih ederim.", {"social_energy": -0.6, "communication_pace": -0.2}, {"evidence": 0.65, "rationale": "Düşük kalabalık enerjisi."}),
    ],
    "newly_authored",
    "kalabalık aktivite vs sakin",
    "sakin tercih geçerli",
    36,
)

_spec(
    "frequency_tr_v1_social_energy_005",
    "social_energy",
    "Yeni eşleşmede buluşma teklifi geldi; ortam seçimi konusunda tercihin?",
    [
        ("A", "Canlı bir kafe veya kalabalık bir mekân öneririm.", {"social_energy": 0.75, "communication_pace": 0.2}, {"evidence": 0.7, "rationale": "Canlı ortam tercihi.", "sdr": "moderate"}),
        ("B", "Orta tempolu, rahat bir mekân öneririm.", {"social_energy": 0.45, "depth_preference": 0.2}, {"evidence": 0.6, "rationale": "Dengeli ortam."}),
        ("C", "Sessiz bir yürüyüş veya park tercih ederim.", {"social_energy": -0.3, "stability": 0.3}, {"evidence": 0.55, "rationale": "Sakin buluşma."}),
        ("D", "Evde veya tenha bir yerde görüşmeyi tercih ederim.", {"social_energy": -0.6, "disclosure_pace": 0.2}, {"evidence": 0.65, "rationale": "Düşük dışarı enerjisi."}),
    ],
    "newly_authored",
    "canlı mekân vs sakin",
    "sakin buluşma ilgisiz değil",
    35,
)

_spec(
    "frequency_tr_v1_social_energy_006",
    "social_energy",
    "Arkadaşlarınla hafta sonu planı var; enerji durumun orta. Ne yaparsın?",
    [
        ("A", "Planın tamamına katılıp enerjimi toparlamaya çalışırım.", {"social_energy": 0.75, "communication_pace": 0.2}, {"evidence": 0.7, "rationale": "Tam katılım."}),
        ("B", "Planın bir kısmına katılır, sonra ayrılırım.", {"social_energy": 0.45, "stability": 0.2}, {"evidence": 0.6, "rationale": "Kısmi katılım."}),
        ("C", "Bu sefer pas geçer, kendime zaman ayırırım.", {"social_energy": -0.3, "spontaneity": 0.3}, {"evidence": 0.55, "rationale": "Enerji koruma."}),
        ("D", "Grup yerine bire bir görüşmeyi teklif ederim.", {"social_energy": -0.6, "depth_preference": 0.2}, {"evidence": 0.65, "rationale": "Düşük grup tercihi."}),
    ],
    "newly_authored",
    "tam katılım vs sınır",
    "pas geçmek normal",
    38,
)

_spec(
    "frequency_tr_v1_social_energy_007",
    "social_energy",
    "Yoğun bir haftadan sonra partnerin sessizlik istiyor; sen dinlenmiş hissediyorsun. Ne yaparsın?",
    [
        ("A", "Onun ihtiyacına saygı duysan da hafif sosyal bir öneri sunarsın.", {"social_energy": 0.75, "spontaneity": 0.2}, {"evidence": 0.7, "extremity": 0.55, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("B", "Kısa bir sesli mesaj atıp sonra alan bırakırsın.", {"social_energy": 0.45, "communication_pace": 0.2}, {"evidence": 0.6, "extremity": 0.4, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("C", "Sessizliği kabul eder, kendi başına vakit geçirirsin.", {"social_energy": -0.3, "stability": 0.3}, {"evidence": 0.55, "extremity": 0.35, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("D", "Tamamen çekilir, bir süre iletişimi minimumda tutarsın.", {"social_energy": -0.6, "depth_preference": -0.2}, {"evidence": 0.65, "extremity": 0.45, "rationale": "Ters çift davranışsal anahtarlama."}),
    ],
    "newly_authored",
    "recovery vs sosyallik",
    "sessizlik ihtiyacı geçerli",
    37,
)

_spec(
    "frequency_tr_v1_social_energy_008",
    "social_energy",
    "Sohbet derinleşirken ortamda başka insanlar da var; tercihin?",
    [
        ("A", "Ortam kalabalık olsa da sohbete devam ederim.", {"social_energy": 0.75, "depth_preference": 0.2}, {"evidence": 0.7, "rationale": "Kalabalıkta derin sohbet."}),
        ("B", "Biraz daha sessiz bir köşeye geçmeyi öneririm.", {"social_energy": 0.45, "communication_pace": 0.2}, {"evidence": 0.6, "rationale": "Orta düzey uyum."}),
        ("C", "Derin konuyu daha uygun bir zamana ertelerim.", {"social_energy": -0.3, "stability": 0.3}, {"evidence": 0.55, "rationale": "Ortam uyumu."}),
        ("D", "Kalabalık ortamda kişisel konuşmaktan kaçınırım.", {"social_energy": -0.6, "disclosure_pace": -0.2}, {"evidence": 0.65, "rationale": "Düşük kamusal enerji."}),
    ],
    "newly_authored",
    "kalabalıkta derinlik",
    "ertelemek utangaçlık değil",
    40,
)

_spec(
    "frequency_tr_v1_spontaneity_001",
    "spontaneity",
    "Cuma akşamı için plan yok; biri aniden buluşma teklif ediyor. Tercihin?",
    [
        ("A", "Hemen kabul eder, planı o an oluştururum.", {"spontaneity": 0.75, "social_energy": 0.2}, {"evidence": 0.7, "rationale": "Yüksek spontaneite."}),
        ("B", "Kısa düşünüp uygunsa evet derim.", {"spontaneity": 0.45, "communication_pace": 0.2}, {"evidence": 0.6, "rationale": "Ilımlı esneklik."}),
        ("C", "Önceden plan yapmayı tercih eder, ertelerim.", {"spontaneity": -0.3, "stability": 0.3}, {"evidence": 0.55, "rationale": "Plan odaklı."}),
        ("D", "Ani teklifleri genelde reddederim.", {"spontaneity": -0.6, "depth_preference": -0.2}, {"evidence": 0.65, "rationale": "Düşük spontaneite."}),
    ],
    "newly_authored",
    "ani plan vs önceden plan",
    "reddetmek soğuk değil",
    34,
)

_spec(
    "frequency_tr_v1_spontaneity_002",
    "spontaneity",
    "Ortak bir aktivite için plan yapılmıştı; gün içinde yeni bir fikir çıktı. Tercihin?",
    [
        ("A", "Planı esnetip yeni fikri hemen deneriz dersin.", {"spontaneity": 0.75, "social_energy": 0.2}, {"evidence": 0.7, "extremity": 0.55, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("B", "Kısa bir değerlendirme sonrası yön değiştirirsin.", {"spontaneity": 0.45, "communication_pace": 0.2}, {"evidence": 0.6, "extremity": 0.4, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("C", "Önceki plana sadık kalırsın.", {"spontaneity": -0.3, "stability": 0.3}, {"evidence": 0.55, "extremity": 0.35, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("D", "Son dakika değişikliklerinden kaçınır, programı korursun.", {"spontaneity": -0.6, "depth_preference": -0.2}, {"evidence": 0.65, "extremity": 0.45, "rationale": "Ters çift davranışsal anahtarlama."}),
    ],
    "newly_authored",
    "plan esnetme",
    "plan sadakati olumlu",
    35,
)

_spec(
    "frequency_tr_v1_spontaneity_003",
    "spontaneity",
    "Hafta sonu için net plan yok; arkadaşın farklı bir aktivite öneriyor. Ne yaparsın?",
    [
        ("A", "Hemen yeni plana geçer, denemekten keyif alırım.", {"spontaneity": 0.75, "social_energy": 0.2}, {"evidence": 0.7, "rationale": "Esnek plan değişimi."}),
        ("B", "Kısa değerlendirme sonrası uygunsa kabul ederim.", {"spontaneity": 0.45, "stability": 0.2}, {"evidence": 0.6, "rationale": "Ilımlı esneklik."}),
        ("C", "Mevcut düşünceme sadık kalırım.", {"spontaneity": -0.3, "depth_preference": 0.2}, {"evidence": 0.55, "rationale": "Plan sadakati."}),
        ("D", "Son dakika değişikliklerinden kaçınırım.", {"spontaneity": -0.6, "communication_pace": -0.2}, {"evidence": 0.65, "rationale": "Düşük spontaneite."}),
    ],
    "newly_authored",
    "plan değişimi vs sadakat",
    "sadakat katılık değil",
    37,
)

_spec(
    "frequency_tr_v1_spontaneity_004",
    "spontaneity",
    "Grup buluşmasında biri farklı bir aktiviteye geçmeyi öneriyor. Tercihin?",
    [
        ("A", "Hemen yeni öneriyi deneriz derim.", {"spontaneity": 0.75, "social_energy": 0.2}, {"evidence": 0.7, "rationale": "Grup içi esneklik."}),
        ("B", "Kısa tartışma sonrası uygunsa değiştiririz.", {"spontaneity": 0.45, "communication_pace": 0.2}, {"evidence": 0.6, "rationale": "Ilımlı uyum."}),
        ("C", "Başlangıç planına sadık kalırım.", {"spontaneity": -0.3, "stability": 0.3}, {"evidence": 0.55, "rationale": "Plan koruma."}),
        ("D", "Grup içi ani değişikliklerden kaçınırım.", {"spontaneity": -0.6, "social_energy": -0.2}, {"evidence": 0.65, "rationale": "Düşük grup spontaneitesi."}),
    ],
    "newly_authored",
    "grup esnekliği vs plan",
    "plan korumak geçerli",
    36,
)

_spec(
    "frequency_tr_v1_spontaneity_005",
    "spontaneity",
    "Birlikte aktivite yaparken yeni bir fikir çıkıyor; tercihin?",
    [
        ("A", "Hemen yeni fikri dener, rotayı değiştiririz.", {"spontaneity": 0.75, "social_energy": 0.2}, {"evidence": 0.7, "rationale": "Anlık yön değişimi."}),
        ("B", "Kısa değerlendirme sonrası uygunsa deneriz.", {"spontaneity": 0.45, "stability": 0.2}, {"evidence": 0.6, "rationale": "Ilımlı esneklik."}),
        ("C", "Başladığımız plana devam ederim.", {"spontaneity": -0.3, "depth_preference": 0.2}, {"evidence": 0.55, "rationale": "Plan sadakati."}),
        ("D", "Aktivite ortasında plan değiştirmekten kaçınırım.", {"spontaneity": -0.6, "communication_pace": -0.2}, {"evidence": 0.65, "rationale": "Düşük spontaneite."}),
    ],
    "newly_authored",
    "aktivite esnekliği",
    "plan sadakati olumlu",
    35,
)

_spec(
    "frequency_tr_v1_spontaneity_006",
    "spontaneity",
    "Hafta içi akşam planı net; biri son dakika farklı bir şey öneriyor. Ne yaparsın?",
    [
        ("A", "Planı bırakıp yeni öneriyi kabul ederim.", {"spontaneity": 0.75, "social_energy": 0.2}, {"evidence": 0.7, "rationale": "Son dakika esneklik."}),
        ("B", "Uygunsa küçük bir değişiklik yapabilirim.", {"spontaneity": 0.45, "communication_pace": 0.2}, {"evidence": 0.6, "rationale": "Sınırlı esneklik."}),
        ("C", "Önceden kararlaştırılan plana sadık kalırım.", {"spontaneity": -0.3, "stability": 0.3}, {"evidence": 0.55, "rationale": "Plan koruma."}),
        ("D", "Son dakika değişikliklerini genelde reddederim.", {"spontaneity": -0.6, "depth_preference": -0.2}, {"evidence": 0.65, "rationale": "Düşük spontaneite."}),
    ],
    "newly_authored",
    "son dakika değişim",
    "reddetmek katı değil",
    38,
)

_spec(
    "frequency_tr_v1_spontaneity_007",
    "spontaneity",
    "Yeni eşleşmede biri aniden farklı bir buluşma saati öneriyor. Tercihin?",
    [
        ("A", "Hemen uyum sağlar, yeni saati kabul ederim.", {"spontaneity": 0.75, "social_energy": 0.2}, {"evidence": 0.7, "rationale": "Esnek buluşma.", "sdr": "moderate"}),
        ("B", "Müsaitlik durumuma göre kısa sürede yanıt veririm.", {"spontaneity": 0.45, "communication_pace": 0.2}, {"evidence": 0.6, "rationale": "Ilımlı uyum."}),
        ("C", "Önceden belirlenen saate sadık kalmayı tercih ederim.", {"spontaneity": -0.3, "stability": 0.3}, {"evidence": 0.55, "rationale": "Plan sadakati."}),
        ("D", "Ani saat değişikliklerinden kaçınırım.", {"spontaneity": -0.6, "disclosure_pace": -0.2}, {"evidence": 0.65, "rationale": "Düşük spontaneite."}),
    ],
    "newly_authored",
    "ani saat değişimi",
    "sadık kalmak katı değil",
    34,
)

_spec(
    "frequency_tr_v1_spontaneity_008",
    "spontaneity",
    "Haftalık rutinin sabit; biri aniden farklı bir etkinlik öneriyor. Ne yaparsın?",
    [
        ("A", "Rutini bırakıp spontane öneriyi kabul edersin.", {"spontaneity": 0.75, "social_energy": 0.2}, {"evidence": 0.7, "extremity": 0.55, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("B", "Uygunsa küçük bir sapma yapmayı düşünürsün.", {"spontaneity": 0.45, "communication_pace": 0.2}, {"evidence": 0.6, "extremity": 0.4, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("C", "Mevcut düzeni korumayı tercih edersin.", {"spontaneity": -0.3, "stability": 0.3}, {"evidence": 0.55, "extremity": 0.35, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("D", "Önceden planlanmış olmayan teklifleri genelde reddedersin.", {"spontaneity": -0.6, "depth_preference": -0.2}, {"evidence": 0.65, "extremity": 0.45, "rationale": "Ters çift davranışsal anahtarlama."}),
    ],
    "newly_authored",
    "rutin vs novelty",
    "rutin koruma geçerli",
    37,
)

_spec(
    "frequency_tr_v1_stability_001",
    "stability",
    "Yeni tanıştığın biriyle haftalık görüşme alışkanlığı kurmak konusunda tercihin?",
    [
        ("A", "Her hafta aynı gün/saat için düzenli bir ritim öneririm.", {"stability": 0.75, "communication_pace": -0.2}, {"evidence": 0.7, "rationale": "Yüksek rutin tercihi."}),
        ("B", "Genel bir çerçeve kurar, detayları birlikte netleştiririm.", {"stability": 0.45, "depth_preference": 0.2}, {"evidence": 0.6, "rationale": "Ilımlı yapı."}),
        ("C", "Her hafta farklı tempoda ilerlemeye açık olurum.", {"stability": -0.3, "spontaneity": 0.3}, {"evidence": 0.55, "rationale": "Esnek ritim."}),
        ("D", "Sabit plan yapmadan akışa bırakırım.", {"stability": -0.6, "social_energy": 0.2}, {"evidence": 0.65, "rationale": "Düşük rutin tercihi."}),
    ],
    "newly_authored",
    "haftalık ritim vs akış",
    "akışa bırakmak geçerli",
    40,
)

_spec(
    "frequency_tr_v1_stability_002",
    "stability",
    "Yeni tanıştığınız biriyle iletişim ritmi henüz oturmamış. Tercihin?",
    [
        ("A", "Haftalık tekrar eden bir görüşme/sohbet ritmi önerirsin.", {"stability": 0.75, "communication_pace": -0.2}, {"evidence": 0.7, "extremity": 0.55, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("B", "Genel bir çerçeve kurar, detayları birlikte netleştirirsin.", {"stability": 0.45, "depth_preference": 0.2}, {"evidence": 0.6, "extremity": 0.4, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("C", "Her hafta farklı tempoda ilerlemeye açık olursun.", {"stability": -0.3, "spontaneity": 0.3}, {"evidence": 0.55, "extremity": 0.35, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("D", "Sabit plan yapmadan akışa bırakırsın.", {"stability": -0.6, "social_energy": 0.2}, {"evidence": 0.65, "extremity": 0.45, "rationale": "Ters çift davranışsal anahtarlama."}),
    ],
    "newly_authored",
    "ritim kurma",
    "akışa bırakmak geçerli",
    40,
)

_spec(
    "frequency_tr_v1_stability_003",
    "stability",
    "Hafta sonu planı birkaç kez değişti; sen nasıl yaklaşırsın?",
    [
        ("A", "Net bir plan çerçevesi önerir, değişiklikleri sınırlarım.", {"stability": 0.75, "spontaneity": -0.2}, {"evidence": 0.7, "rationale": "Plan stabilitesi."}),
        ("B", "Esnek kalır ama ana çerçeveyi korumaya çalışırım.", {"stability": 0.45, "communication_pace": 0.2}, {"evidence": 0.6, "rationale": "Ilımlı stabilite."}),
        ("C", "Değişikliklere uyum sağlar, yeni plana geçerim.", {"stability": -0.3, "spontaneity": 0.3}, {"evidence": 0.55, "rationale": "Esnek uyum."}),
        ("D", "Sürekli değişen planlardan kaçınır, netleşene kadar beklersin.", {"stability": -0.6, "depth_preference": -0.2}, {"evidence": 0.65, "rationale": "Düşük belirsizlik toleransı."}),
    ],
    "newly_authored",
    "plan stabilitesi vs esneklik",
    "esneklik kaos değil",
    39,
)

_spec(
    "frequency_tr_v1_stability_004",
    "stability",
    "Günlük rutinin oturmuş; tanıştığın biri farklı bir tempo öneriyor. Tercihin?",
    [
        ("A", "Mevcut rutinimi korur, küçük uyumlar dışında değiştirmem.", {"stability": 0.75, "communication_pace": -0.2}, {"evidence": 0.7, "rationale": "Rutin koruma."}),
        ("B", "Rutinime uygun küçük ayarlamalar yapabilirim.", {"stability": 0.45, "depth_preference": 0.2}, {"evidence": 0.6, "rationale": "Ilımlı adaptasyon."}),
        ("C", "Tempo değişikliğine açık olur, denemeye razıyım.", {"stability": -0.3, "spontaneity": 0.3}, {"evidence": 0.55, "rationale": "Esnek rutin."}),
        ("D", "Rutinimi bozmak yerine kendi tempomda devam ederim.", {"stability": -0.6, "social_energy": 0.2}, {"evidence": 0.65, "rationale": "Düşük rutin esnekliği."}),
    ],
    "newly_authored",
    "rutin koruma vs adaptasyon",
    "kendi tempoda devam geçerli",
    41,
)

_spec(
    "frequency_tr_v1_stability_005",
    "stability",
    "Uzun vadede iletişim ritminiz oturdu; beklenmedik bir değişiklik geldi. Ne yaparsın?",
    [
        ("A", "Mümkün olan en kısa sürede önceki ritme dönmeye çalışırım.", {"stability": 0.75, "communication_pace": -0.2}, {"evidence": 0.7, "rationale": "Ritim restorasyonu."}),
        ("B", "Yeni koşullara göre güncellenmiş bir ritim öneririm.", {"stability": 0.45, "depth_preference": 0.2}, {"evidence": 0.6, "rationale": "Ilımlı adaptasyon."}),
        ("C", "Değişikliği kabul eder, yeni tempoya uyum sağlarım.", {"stability": -0.3, "spontaneity": 0.3}, {"evidence": 0.55, "rationale": "Esnek uyum."}),
        ("D", "Sabit ritim aramadan doğal akışa bırakırım.", {"stability": -0.6, "disclosure_pace": -0.2}, {"evidence": 0.65, "rationale": "Düşük ritim ihtiyacı."}),
    ],
    "newly_authored",
    "ritim restorasyonu vs akış",
    "akışa bırakmak geçerli",
    42,
)

_spec(
    "frequency_tr_v1_stability_006",
    "stability",
    "Partnerin bir süre sessiz kaldı; yeniden bağlanma fırsatı doğdu. Tercihin?",
    [
        ("A", "Önceki düzenli temas ritmini yeniden kurmayı teklif edersin.", {"stability": 0.75, "communication_pace": -0.2}, {"evidence": 0.7, "extremity": 0.55, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("B", "Hafif ama öngörülebilir bir check-in düzeni önerirsin.", {"stability": 0.45, "depth_preference": 0.2}, {"evidence": 0.6, "extremity": 0.4, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("C", "Bu seferlik esnek kalır, yeni bir tempo deneriz dersin.", {"stability": -0.3, "spontaneity": 0.3}, {"evidence": 0.55, "extremity": 0.35, "rationale": "Ters çift davranışsal anahtarlama."}),
        ("D", "Ritim kurmadan doğal akışa güvenirsin.", {"stability": -0.6, "social_energy": 0.2}, {"evidence": 0.65, "extremity": 0.45, "rationale": "Ters çift davranışsal anahtarlama."}),
    ],
    "newly_authored",
    "yeniden bağlanma ritmi",
    "esnek tempo normal",
    38,
)

_spec(
    "frequency_tr_v1_stability_007",
    "stability",
    "Grup buluşması sonrası haftalık rutinin bozuldu; tercihin?",
    [
        ("A", "Ertesi gün rutinime dönmeye özen gösteririm.", {"stability": 0.75, "communication_pace": -0.2}, {"evidence": 0.7, "rationale": "Hızlı rutin restorasyonu."}),
        ("B", "Bir gün esneyip sonra rutine dönerim.", {"stability": 0.45, "social_energy": 0.2}, {"evidence": 0.6, "rationale": "Ilımlı toparlanma."}),
        ("C", "Rutin bozulmuşsa bir süre esnek kalırım.", {"stability": -0.3, "spontaneity": 0.3}, {"evidence": 0.55, "rationale": "Esnek recovery."}),
        ("D", "Rutin zorunluluğu hissetmem, akışa bırakırım.", {"stability": -0.6, "depth_preference": -0.2}, {"evidence": 0.65, "rationale": "Düşük rutin bağımlılığı."}),
    ],
    "newly_authored",
    "rutin restorasyonu",
    "esnek kalma geçerli",
    38,
)

_spec(
    "frequency_tr_v1_stability_008",
    "stability",
    "Sohbet derinleşirken iletişim ritminiz değişiyor; tercihin?",
    [
        ("A", "Derinleşse de önceki düzenli temas ritmini korumaya çalışırım.", {"stability": 0.75, "depth_preference": 0.2}, {"evidence": 0.7, "rationale": "Derinlikte ritim koruma."}),
        ("B", "Ritmi hafif ayarlar ama genel çerçeveyi sürdürürüm.", {"stability": 0.45, "communication_pace": 0.2}, {"evidence": 0.6, "rationale": "Ilımlı adaptasyon."}),
        ("C", "Derin konularda ritmi doğal akışa bırakırım.", {"stability": -0.3, "disclosure_pace": 0.3}, {"evidence": 0.55, "rationale": "Esnek ritim."}),
        ("D", "Sabit ritim aramadan konuya göre tempoyu değiştiririm.", {"stability": -0.6, "spontaneity": 0.2}, {"evidence": 0.65, "rationale": "Düşük ritim ihtiyacı."}),
    ],
    "newly_authored",
    "derinlikte ritim",
    "doğal akış geçerli",
    41,
)
