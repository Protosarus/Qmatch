"""Turkish Frequency pilot item specs — imported by generate_frequency_pilot_tr_v1.py only."""

from __future__ import annotations

# Shared option delta templates for behavioral reverse pairs (identical vectors per option letter).
REV_DELTA_TEMPLATES: dict[str, list[dict[str, dict[str, float]]]] = {
    "frequency_tr_v1_rev_01": [
        [
            {"depth_preference": 0.75, "communication_pace": 0.20},
            {"depth_preference": 0.45, "stability": 0.20},
            {"depth_preference": -0.20, "spontaneity": 0.30},
            {"depth_preference": -0.60, "social_energy": 0.20},
        ],
        [
            {"depth_preference": 0.75, "communication_pace": 0.20},
            {"depth_preference": 0.45, "stability": 0.20},
            {"depth_preference": -0.20, "spontaneity": 0.30},
            {"depth_preference": -0.60, "social_energy": 0.20},
        ],
    ],
    "frequency_tr_v1_rev_02": [
        [
            {"communication_pace": 0.75, "social_energy": 0.20},
            {"communication_pace": 0.45, "depth_preference": 0.20},
            {"communication_pace": -0.30, "stability": 0.30},
            {"communication_pace": -0.60, "disclosure_pace": -0.20},
        ],
        [
            {"communication_pace": 0.75, "social_energy": 0.20},
            {"communication_pace": 0.45, "depth_preference": 0.20},
            {"communication_pace": -0.30, "stability": 0.30},
            {"communication_pace": -0.60, "disclosure_pace": -0.20},
        ],
    ],
    "frequency_tr_v1_rev_03": [
        [
            {"social_energy": 0.75, "spontaneity": 0.20},
            {"social_energy": 0.45, "communication_pace": 0.20},
            {"social_energy": -0.30, "stability": 0.30},
            {"social_energy": -0.60, "depth_preference": -0.20},
        ],
        [
            {"social_energy": 0.75, "spontaneity": 0.20},
            {"social_energy": 0.45, "communication_pace": 0.20},
            {"social_energy": -0.30, "stability": 0.30},
            {"social_energy": -0.60, "depth_preference": -0.20},
        ],
    ],
    "frequency_tr_v1_rev_04": [
        [
            {"spontaneity": 0.75, "social_energy": 0.20},
            {"spontaneity": 0.45, "communication_pace": 0.20},
            {"spontaneity": -0.30, "stability": 0.30},
            {"spontaneity": -0.60, "depth_preference": -0.20},
        ],
        [
            {"spontaneity": 0.75, "social_energy": 0.20},
            {"spontaneity": 0.45, "communication_pace": 0.20},
            {"spontaneity": -0.30, "stability": 0.30},
            {"spontaneity": -0.60, "depth_preference": -0.20},
        ],
    ],
    "frequency_tr_v1_rev_05": [
        [
            {"stability": 0.75, "communication_pace": -0.20},
            {"stability": 0.45, "depth_preference": 0.20},
            {"stability": -0.30, "spontaneity": 0.30},
            {"stability": -0.60, "social_energy": 0.20},
        ],
        [
            {"stability": 0.75, "communication_pace": -0.20},
            {"stability": 0.45, "depth_preference": 0.20},
            {"stability": -0.30, "spontaneity": 0.30},
            {"stability": -0.60, "social_energy": 0.20},
        ],
    ],
    "frequency_tr_v1_rev_06": [
        [
            {"disclosure_pace": 0.75, "depth_preference": 0.20},
            {"disclosure_pace": 0.45, "communication_pace": 0.20},
            {"disclosure_pace": -0.30, "stability": 0.30},
            {"disclosure_pace": -0.60, "social_energy": -0.20},
        ],
        [
            {"disclosure_pace": 0.75, "depth_preference": 0.20},
            {"disclosure_pace": 0.45, "communication_pace": 0.20},
            {"disclosure_pace": -0.30, "stability": 0.30},
            {"disclosure_pace": -0.60, "social_energy": -0.20},
        ],
    ],
}

REV_TEXTS: dict[str, list[tuple[str, list[tuple[str, str, dict]]]]] = {
    "frequency_tr_v1_rev_01": [
        (
            "frequency_tr_v1_depth_preference_004",
            "Bir süredir mesajlaşıyorsunuz; ortam sakin. Konuşmayı nasıl sürdürmeyi tercih edersin?",
            [
                ("A", "Günün nasıl geçtiğinden öte, seni etkileyen düşüncelere geçmeyi teklif edersin.", {"evidence": 0.75, "extremity": 0.55}),
                ("B", "Hafif sohbet eder, uygun olduğunda biraz daha kişisel bir konuya yavaşça kayarsın.", {"evidence": 0.60, "extremity": 0.40}),
                ("C", "Pratik konularda kalır, derinleşmeden akışı sürdürürsün.", {"evidence": 0.50, "extremity": 0.30}),
                ("D", "Kısa tutup sonra tekrar yazmayı planlarsın.", {"evidence": 0.55, "extremity": 0.35}),
            ],
        ),
        (
            "frequency_tr_v1_depth_preference_009",
            "Haftalık rutinin yoğun; tanıştığın biriyle sohbet aralığı açılıyor. Tercihin ne olur?",
            [
                ("A", "Rutini bozup anlam taşıyan bir konuya geçmeyi önerirsin.", {"evidence": 0.75, "extremity": 0.55}),
                ("B", "Kısa ama içten bir check-in yapar, uygunsa biraz derinleşirsin.", {"evidence": 0.60, "extremity": 0.40}),
                ("C", "Gündelik güncellemelerle yetinir, derin konuyu ertelersin.", {"evidence": 0.50, "extremity": 0.30}),
                ("D", "Mesajı minimumda tutar, rutine dönersin.", {"evidence": 0.55, "extremity": 0.35}),
            ],
        ),
    ],
    "frequency_tr_v1_rev_02": [
        (
            "frequency_tr_v1_communication_pace_003",
            "Partnerin birkaç saat yazmadı; sen müsait değilsin ama merak ediyorsun. Ne yaparsın?",
            [
                ("A", "Kısa bir mesaj atıp akışın devam etmesini umarsın.", {"evidence": 0.70, "extremity": 0.50}),
                ("B", "Gün sonunda toparlayıcı bir mesaj planlarsın.", {"evidence": 0.60, "extremity": 0.35}),
                ("C", "O yazana kadar bekler, acil değilse dokunmazsın.", {"evidence": 0.55, "extremity": 0.30}),
                ("D", "Uzun sessizliğin normal olduğunu düşünüp mesaj atmazsın.", {"evidence": 0.65, "extremity": 0.45}),
            ],
        ),
        (
            "frequency_tr_v1_communication_pace_008",
            "Haftalık programın tekrarlı; mesajlaşma alışkanlığın oturmuş. Tercihin?",
            [
                ("A", "Gün içinde birkaç kısa check-in yapmayı sürdürürsün.", {"evidence": 0.70, "extremity": 0.50}),
                ("B", "Sabah ve akşam olmak üzere düzenli ama seyrek temas kurarsın.", {"evidence": 0.60, "extremity": 0.35}),
                ("C", "Haftalık ritmine göre birkaç gün sessiz kalabilirsin.", {"evidence": 0.55, "extremity": 0.30}),
                ("D", "Uzun aralıklar seni rahatsız etmez; o başlatana kadar beklersin.", {"evidence": 0.65, "extremity": 0.45}),
            ],
        ),
    ],
    "frequency_tr_v1_rev_03": [
        (
            "frequency_tr_v1_social_energy_002",
            "Yakın çevrenle küçük bir buluşma planlanıyor; sen yorgunsun ama davetlisin. Tercihin?",
            [
                ("A", "Enerjini toparlayıp buluşmaya katılırsın.", {"evidence": 0.75, "extremity": 0.55}),
                ("B", "Kısa süreli gelir, sonra ayrılmayı planlarsın.", {"evidence": 0.60, "extremity": 0.40}),
                ("C", "Bu kez pas geçip dinlenmeyi seçersin.", {"evidence": 0.55, "extremity": 0.35}),
                ("D", "Kalabalıktan kaçınır, bire bir görüşmeyi ertelersin.", {"evidence": 0.65, "extremity": 0.45}),
            ],
        ),
        (
            "frequency_tr_v1_social_energy_007",
            "Yoğun bir haftadan sonra partnerin sessizlik istiyor; sen dinlenmiş hissediyorsun. Ne yaparsın?",
            [
                ("A", "Onun ihtiyacına saygı duysan da hafif sosyal bir öneri sunarsın.", {"evidence": 0.75, "extremity": 0.55}),
                ("B", "Kısa bir sesli mesaj atıp sonra alan bırakırsın.", {"evidence": 0.60, "extremity": 0.40}),
                ("C", "Sessizliği kabul eder, kendi başına vakit geçirirsin.", {"evidence": 0.55, "extremity": 0.35}),
                ("D", "Tamamen çekilir, bir süre iletişimi minimumda tutarsın.", {"evidence": 0.65, "extremity": 0.45}),
            ],
        ),
    ],
    "frequency_tr_v1_rev_04": [
        (
            "frequency_tr_v1_spontaneity_002",
            "Ortak bir aktivite için plan yapılmıştı; gün içinde yeni bir fikir çıktı. Tercihin?",
            [
                ("A", "Planı esnetip yeni fikri hemen deneriz dersin.", {"evidence": 0.75, "extremity": 0.55}),
                ("B", "Kısa bir değerlendirme sonrası yön değiştirirsin.", {"evidence": 0.60, "extremity": 0.40}),
                ("C", "Önceki plana sadık kalırsın.", {"evidence": 0.55, "extremity": 0.35}),
                ("D", "Son dakika değişikliklerinden kaçınır, programı korursun.", {"evidence": 0.65, "extremity": 0.45}),
            ],
        ),
        (
            "frequency_tr_v1_spontaneity_008",
            "Haftalık rutinin sabit; biri aniden farklı bir etkinlik öneriyor. Ne yaparsın?",
            [
                ("A", "Rutini bırakıp spontane öneriyi kabul edersin.", {"evidence": 0.75, "extremity": 0.55}),
                ("B", "Uygunsa küçük bir sapma yapmayı düşünürsün.", {"evidence": 0.60, "extremity": 0.40}),
                ("C", "Mevcut düzeni korumayı tercih edersin.", {"evidence": 0.55, "extremity": 0.35}),
                ("D", "Önceden planlanmış olmayan teklifleri genelde reddedersin.", {"evidence": 0.65, "extremity": 0.45}),
            ],
        ),
    ],
    "frequency_tr_v1_rev_05": [
        (
            "frequency_tr_v1_stability_002",
            "Yeni tanıştığınız biriyle iletişim ritmi henüz oturmamış. Tercihin?",
            [
                ("A", "Haftalık tekrar eden bir görüşme/sohbet ritmi önerirsin.", {"evidence": 0.75, "extremity": 0.55}),
                ("B", "Genel bir çerçeve kurar, detayları birlikte netleştirirsin.", {"evidence": 0.60, "extremity": 0.40}),
                ("C", "Her hafta farklı tempoda ilerlemeye açık olursun.", {"evidence": 0.55, "extremity": 0.35}),
                ("D", "Sabit plan yapmadan akışa bırakırsın.", {"evidence": 0.65, "extremity": 0.45}),
            ],
        ),
        (
            "frequency_tr_v1_stability_006",
            "Partnerin bir süre sessiz kaldı; yeniden bağlanma fırsatı doğdu. Tercihin?",
            [
                ("A", "Önceki düzenli temas ritmini yeniden kurmayı teklif edersin.", {"evidence": 0.75, "extremity": 0.55}),
                ("B", "Hafif ama öngörülebilir bir check-in düzeni önerirsin.", {"evidence": 0.60, "extremity": 0.40}),
                ("C", "Bu seferlik esnek kalır, yeni bir tempo deneriz dersin.", {"evidence": 0.55, "extremity": 0.35}),
                ("D", "Ritim kurmadan doğal akışa güvenirsin.", {"evidence": 0.65, "extremity": 0.45}),
            ],
        ),
    ],
    "frequency_tr_v1_rev_06": [
        (
            "frequency_tr_v1_disclosure_pace_003",
            "Yeni eşleşmede sohbet ilerliyor; kişisel bir konu gündeme geliyor. Ne yaparsın?",
            [
                ("A", "Kendi deneyiminden kısa ama açık bir örnek paylaşırsın.", {"evidence": 0.75, "extremity": 0.55}),
                ("B", "Konuyu açarsın ama detayları yavaş bırakırsın.", {"evidence": 0.60, "extremity": 0.40}),
                ("C", "Genel kalır, kişisel örnek vermezsin.", {"evidence": 0.55, "extremity": 0.35}),
                ("D", "Konuyu değiştirir, daha tanıdık olmayı beklersin.", {"evidence": 0.65, "extremity": 0.45}),
            ],
        ),
        (
            "frequency_tr_v1_disclosure_pace_007",
            "Bir süredir mesajlaşıyorsunuz; ilişki beklentileri konuşuluyor. Tercihin?",
            [
                ("A", "Kendi beklentilerini açıkça ve erken paylaşırsın.", {"evidence": 0.75, "extremity": 0.55}),
                ("B", "Temel çerçeveyi verir, ayrıntıları kademeli açarsın.", {"evidence": 0.60, "extremity": 0.40}),
                ("C", "Yüzeysel kalır, somut paylaşımı ertelersin.", {"evidence": 0.55, "extremity": 0.35}),
                ("D", "Kişisel beklentileri güven oluşana kadar saklarsın.", {"evidence": 0.65, "extremity": 0.45}),
            ],
        ),
    ],
}

STANDALONE_ITEMS: list[dict] = []  # populated by generator merge script
