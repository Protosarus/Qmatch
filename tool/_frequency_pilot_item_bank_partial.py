# Auto-authored item bank — 50 Turkish Frequency pilot _spec() calls.

_spec(
    "frequency_tr_v1_depth_preference_004",
    "depth_preference",
    "Bir süredir mesajlaşıyorsunuz; ortam sakin. Konuşmayı nasıl sürdürmeyi tercih edersin?",
    [
        ("A", "Günün nasıl geçtiğinden öte, seni etkileyen düşüncelere geçmeyi teklif edersin.", {"depth_preference": 0.75, "communication_pace": 0.2}, {"evidence": 0.75, "extremity": 0.55}),
        ("B", "Hafif sohbet eder, uygun olduğunda biraz daha kişisel bir konuya yavaşça kayarsın.", {"depth_preference": 0.45, "stability": 0.2}, {"evidence": 0.6, "extremity": 0.4}),
        ("C", "Pratik konularda kalır, derinleşmeden akışı sürdürürsün.", {"depth_preference": -0.2, "spontaneity": 0.3}, {"evidence": 0.5, "extremity": 0.3}),
        ("D", "Kısa tutup sonra tekrar yazmayı planlarsın.", {"depth_preference": -0.6, "social_energy": 0.2}, {"evidence": 0.55, "extremity": 0.35}),
    ],
    "newly_authored",
    "sessizlikte derinlik vs hafiflik",
    "dört yanıt eşit savunulabilir",
    40,
)

_spec(
    "frequency_tr_v1_depth_preference_009",
    "depth_preference",
    "Haftalık rutinin yoğun; tanıştığın biriyle sohbet aralığı açılıyor. Tercihin ne olur?",
    [
        ("A", "Rutini bozup anlam taşıyan bir konuya geçmeyi önerirsin.", {"depth_preference": 0.75, "communication_pace": 0.2}, {"evidence": 0.75, "extremity": 0.55}),
        ("B", "Kısa ama içten bir check-in yapar, uygunsa biraz derinleşirsin.", {"depth_preference": 0.45, "stability": 0.2}, {"evidence": 0.6, "extremity": 0.4}),
        ("C", "Gündelik güncellemelerle yetinir, derin konuyu ertelersin.", {"depth_preference": -0.2, "spontaneity": 0.3}, {"evidence": 0.5, "extremity": 0.3}),
        ("D", "Mesajı minimumda tutar, rutine dönersin.", {"depth_preference": -0.6, "social_energy": 0.2}, {"evidence": 0.55, "extremity": 0.35}),
    ],
    "newly_authored",
    "rutin vs anlam arayışı",
    "kısa tutmak geçerli",
    40,
)

_spec(
    "frequency_tr_v1_communication_pace_003",
    "communication_pace",
    "Partnerin birkaç saat yazmadı; sen müsait değilsin ama merak ediyorsun. Ne yaparsın?",
    [
        ("A", "Kısa bir mesaj atıp akışın devam etmesini umarsın.", {"communication_pace": 0.75, "social_energy": 0.2}, {"evidence": 0.7, "extremity": 0.5}),
        ("B", "Gün sonunda toparlayıcı bir mesaj planlarsın.", {"communication_pace": 0.45, "depth_preference": 0.2}, {"evidence": 0.6, "extremity": 0.35}),
        ("C", "O yazana kadar bekler, acil değilse dokunmazsın.", {"communication_pace": -0.3, "stability": 0.3}, {"evidence": 0.55, "extremity": 0.3}),
        ("D", "Uzun sessizliğin normal olduğunu düşünüp mesaj atmazsın.", {"communication_pace": -0.6, "disclosure_pace": -0.2}, {"evidence": 0.65, "extremity": 0.45}),
    ],
    "newly_authored",
    "sessizlikte tempo",
    "beklemek ilgisizlik değil",
    38,
)

_spec(
    "frequency_tr_v1_communication_pace_008",
    "communication_pace",
    "Haftalık programın tekrarlı; mesajlaşma alışkanlığın oturmuş. Tercihin?",
    [
        ("A", "Gün içinde birkaç kısa check-in yapmayı sürdürürsün.", {"communication_pace": 0.75, "social_energy": 0.2}, {"evidence": 0.7, "extremity": 0.5}),
        ("B", "Sabah ve akşam olmak üzere düzenli ama seyrek temas kurarsın.", {"communication_pace": 0.45, "depth_preference": 0.2}, {"evidence": 0.6, "extremity": 0.35}),
        ("C", "Haftalık ritmine göre birkaç gün sessiz kalabilirsin.", {"communication_pace": -0.3, "stability": 0.3}, {"evidence": 0.55, "extremity": 0.3}),
        ("D", "Uzun aralıklar seni rahatsız etmez; o başlatana kadar beklersin.", {"communication_pace": -0.6, "disclosure_pace": -0.2}, {"evidence": 0.65, "extremity": 0.45}),
    ],
    "newly_authored",
    "rutin tempo",
    "seyrek tempo normal",
    40,
)

_spec(
    "frequency_tr_v1_social_energy_002",
    "social_energy",
    "Yakın çevrenle küçük bir buluşma planlanıyor; sen yorgunsun ama davetlisin. Tercihin?",
    [
        ("A", "Enerjini toparlayıp buluşmaya katılırsın.", {"social_energy": 0.75, "spontaneity": 0.2}, {"evidence": 0.75, "extremity": 0.55}),
        ("B", "Kısa süreli gelir, sonra ayrılmayı planlarsın.", {"social_energy": 0.45, "communication_pace": 0.2}, {"evidence": 0.6, "extremity": 0.4}),
        ("C", "Bu kez pas geçip dinlenmeyi seçersin.", {"social_energy": -0.3, "stability": 0.3}, {"evidence": 0.55, "extremity": 0.35}),
        ("D", "Kalabalıktan kaçınır, bire bir görüşmeyi ertelersin.", {"social_energy": -0.6, "depth_preference": -0.2}, {"evidence": 0.65, "extremity": 0.45}),
    ],
    "newly_authored",
    "grup vs dinlenme",
    "pas geçmek normal",
    38,
)

_spec(
    "frequency_tr_v1_social_energy_007",
    "social_energy",
    "Yoğun bir haftadan sonra partnerin sessizlik istiyor; sen dinlenmiş hissediyorsun. Ne yaparsın?",
    [
        ("A", "Onun ihtiyacına saygı duysan da hafif sosyal bir öneri sunarsın.", {"social_energy": 0.75, "spontaneity": 0.2}, {"evidence": 0.75, "extremity": 0.55}),
        ("B", "Kısa bir sesli mesaj atıp sonra alan bırakırsın.", {"social_energy": 0.45, "communication_pace": 0.2}, {"evidence": 0.6, "extremity": 0.4}),
        ("C", "Sessizliği kabul eder, kendi başına vakit geçirirsin.", {"social_energy": -0.3, "stability": 0.3}, {"evidence": 0.55, "extremity": 0.35}),
        ("D", "Tamamen çekilir, bir süre iletişimi minimumda tutarsın.", {"social_energy": -0.6, "depth_preference": -0.2}, {"evidence": 0.65, "extremity": 0.45}),
    ],
    "newly_authored",
    "recovery vs sosyallik",
    "sessizlik ihtiyacı geçerli",
    37,
)

_spec(
    "frequency_tr_v1_spontaneity_002",
    "spontaneity",
    "Ortak bir aktivite için plan yapılmıştı; gün içinde yeni bir fikir çıktı. Tercihin?",
    [
        ("A", "Planı esnetip yeni fikri hemen deneriz dersin.", {"spontaneity": 0.75, "social_energy": 0.2}, {"evidence": 0.75, "extremity": 0.55}),
        ("B", "Kısa bir değerlendirme sonrası yön değiştirirsin.", {"spontaneity": 0.45, "communication_pace": 0.2}, {"evidence": 0.6, "extremity": 0.4}),
        ("C", "Önceki plana sadık kalırsın.", {"spontaneity": -0.3, "stability": 0.3}, {"evidence": 0.55, "extremity": 0.35}),
        ("D", "Son dakika değişikliklerinden kaçınır, programı korursun.", {"spontaneity": -0.6, "depth_preference": -0.2}, {"evidence": 0.65, "extremity": 0.45}),
    ],
    "newly_authored",
    "plan esnetme",
    "plan sadakati olumlu",
    35,
)

_spec(
    "frequency_tr_v1_spontaneity_008",
    "spontaneity",
    "Haftalık rutinin sabit; biri aniden farklı bir etkinlik öneriyor. Ne yaparsın?",
    [
        ("A", "Rutini bırakıp spontane öneriyi kabul edersin.", {"spontaneity": 0.75, "social_energy": 0.2}, {"evidence": 0.75, "extremity": 0.55}),
        ("B", "Uygunsa küçük bir sapma yapmayı düşünürsün.", {"spontaneity": 0.45, "communication_pace": 0.2}, {"evidence": 0.6, "extremity": 0.4}),
        ("C", "Mevcut düzeni korumayı tercih edersin.", {"spontaneity": -0.3, "stability": 0.3}, {"evidence": 0.55, "extremity": 0.35}),
        ("D", "Önceden planlanmış olmayan teklifleri genelde reddedersin.", {"spontaneity": -0.6, "depth_preference": -0.2}, {"evidence": 0.65, "extremity": 0.45}),
    ],
    "newly_authored",
    "rutin vs novelty",
    "rutin koruma geçerli",
    37,
)

_spec(
    "frequency_tr_v1_stability_002",
    "stability",
    "Yeni tanıştığınız biriyle iletişim ritmi henüz oturmamış. Tercihin?",
    [
        ("A", "Haftalık tekrar eden bir görüşme/sohbet ritmi önerirsin.", {"stability": 0.75, "communication_pace": -0.2}, {"evidence": 0.75, "extremity": 0.55}),
        ("B", "Genel bir çerçeve kurar, detayları birlikte netleştirirsin.", {"stability": 0.45, "depth_preference": 0.2}, {"evidence": 0.6, "extremity": 0.4}),
        ("C", "Her hafta farklı tempoda ilerlemeye açık olursun.", {"stability": -0.3, "spontaneity": 0.3}, {"evidence": 0.55, "extremity": 0.35}),
        ("D", "Sabit plan yapmadan akışa bırakırsın.", {"stability": -0.6, "social_energy": 0.2}, {"evidence": 0.65, "extremity": 0.45}),
    ],
    "newly_authored",
    "ritim kurma",
    "akışa bırakmak geçerli",
    40,
)

_spec(
    "frequency_tr_v1_stability_006",
    "stability",
    "Partnerin bir süre sessiz kaldı; yeniden bağlanma fırsatı doğdu. Tercihin?",
    [
        ("A", "Önceki düzenli temas ritmini yeniden kurmayı teklif edersin.", {"stability": 0.75, "communication_pace": -0.2}, {"evidence": 0.75, "extremity": 0.55}),
        ("B", "Hafif ama öngörülebilir bir check-in düzeni önerirsin.", {"stability": 0.45, "depth_preference": 0.2}, {"evidence": 0.6, "extremity": 0.4}),
        ("C", "Bu seferlik esnek kalır, yeni bir tempo deneriz dersin.", {"stability": -0.3, "spontaneity": 0.3}, {"evidence": 0.55, "extremity": 0.35}),
        ("D", "Ritim kurmadan doğal akışa güvenirsin.", {"stability": -0.6, "social_energy": 0.2}, {"evidence": 0.65, "extremity": 0.45}),
    ],
    "newly_authored",
    "yeniden bağlanma ritmi",
    "esnek tempo normal",
    38,
)

_spec(
    "frequency_tr_v1_disclosure_pace_003",
    "disclosure_pace",
    "Yeni eşleşmede sohbet ilerliyor; kişisel bir konu gündeme geliyor. Ne yaparsın?",
    [
        ("A", "Kendi deneyiminden kısa ama açık bir örnek paylaşırsın.", {"disclosure_pace": 0.75, "depth_preference": 0.2}, {"evidence": 0.75, "extremity": 0.55}),
        ("B", "Konuyu açarsın ama detayları yavaş bırakırsın.", {"disclosure_pace": 0.45, "communication_pace": 0.2}, {"evidence": 0.6, "extremity": 0.4}),
        ("C", "Genel kalır, kişisel örnek vermezsin.", {"disclosure_pace": -0.3, "stability": 0.3}, {"evidence": 0.55, "extremity": 0.35}),
        ("D", "Konuyu değiştirir, daha tanıdık olmayı beklersin.", {"disclosure_pace": -0.6, "social_energy": -0.2}, {"evidence": 0.65, "extremity": 0.45}),
    ],
    "newly_authored",
    "erken kişisel konu",
    "yavaş açıklık gizlilik değil",
    36,
)

_spec(
    "frequency_tr_v1_disclosure_pace_007",
    "disclosure_pace",
    "Bir süredir mesajlaşıyorsunuz; ilişki beklentileri konuşuluyor. Tercihin?",
    [
        ("A", "Kendi beklentilerini açıkça ve erken paylaşırsın.", {"disclosure_pace": 0.75, "depth_preference": 0.2}, {"evidence": 0.75, "extremity": 0.55}),
        ("B", "Temel çerçeveyi verir, ayrıntıları kademeli açarsın.", {"disclosure_pace": 0.45, "communication_pace": 0.2}, {"evidence": 0.6, "extremity": 0.4}),
        ("C", "Yüzeysel kalır, somut paylaşımı ertelersin.", {"disclosure_pace": -0.3, "stability": 0.3}, {"evidence": 0.55, "extremity": 0.35}),
        ("D", "Kişisel beklentileri güven oluşana kadar saklarsın.", {"disclosure_pace": -0.6, "social_energy": -0.2}, {"evidence": 0.65, "extremity": 0.45}),
    ],
    "newly_authored",
    "beklenti paylaşımı",
    "ertelemek soğukluk değil",
    42,
)

_spec(
    "frequency_tr_v1_depth_preference_001",
    "depth_preference",
    "Yeni eşleşmede ilk mesajlaşmada ne tür bir ton seni daha rahat eder?",
    [
        ("A", "Hafif bir selamdan sonra merak ettiğin bir konuya geçmeyi denerim.", {"depth_preference": 0.6, "communication_pace": 0.2}, {"evidence": 0.65, "rationale": "Erken derinlik tercihi."}),
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
