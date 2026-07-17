#!/usr/bin/env python3
"""Phase 3N-A2 — targeted light polish for EQ + Frequency (text only)."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EQ_PATH = ROOT / "assets" / "data" / "assessment_sets" / "eq_sets.json"
FREQ_PATH = ROOT / "assets" / "data" / "assessment_sets" / "frequency_sets.json"

# --- Caricature distractors (EN + matching TR) ---
CARICATURE = {
    "Withdraw affection to test if they'll chase": (
        "Pull back and wait to see if they notice",
        "Geri çekilip fark edip etmeyeceklerini beklersin",
    ),
    "Withdraw affection to regain a sense of control": (
        "Get colder than you mean to, just to feel steadier",
        "Daha dengede hissetmek için istediğinden daha soğuk davranırsın",
    ),
}

# --- Winning options by question id (EN, TR) — scenario-specific ---
WINNERS: dict[str, tuple[str, str]] = {
    # design: Acknowledge the tension…
    "eq_set_003_q07": (
        "Say last-minute confirms unsettle you, and ask how to plan better",
        "Son dakika onayın seni gerdiğini söyleyip daha iyi nasıl planlayacağınızı sorarsın",
    ),
    "eq_set_003_q08": (
        "Say late dinner confirms stress you, and ask how timing can improve",
        "Geç akşam onayının seni gerdiğini söyleyip zamanlamayı nasıl düzelteceğinizi sorarsın",
    ),
    "eq_set_003_q09": (
        "Say follow-up confirms feel shaky, and ask what planning works for you both",
        "Takiple gelen onayın güvensiz geldiğini söyleyip nasıl planlamak istediğinizi sorarsın",
    ),
    "eq_set_003_q10": (
        "Say Saturday confirms feel late, and ask how to lock plans earlier",
        "Cumartesi onayının geç kaldığını söyleyip planları daha erken netleştirmek istersin",
    ),
    # design: Acknowledge their pace…
    "eq_set_013_q01": (
        "Stay calm and ask how they see where things stand between you",
        "Sakin kalıp aranızdaki durumu nasıl gördüklerini sorarsın",
    ),
    "eq_set_016_q02": (
        "Celebrate with them first, then ask how they want to mark the news",
        "Önce onlarla sevinir, sonra haberi nasıl kutlamak istediklerini sorarsın",
    ),
    "eq_set_019_q03": (
        "Ask them to let you finish, then welcome their ideas",
        "Önce sözünü bitirmene izin vermelerini ister, sonra fikirlerine yer açarsın",
    ),
    "eq_set_019_q10": (
        "Ask for a turn to finish your thought before they respond",
        "Onlar yanıt vermeden önce düşünceni bitirmek için sıra istersin",
    ),
    "eq_set_023_q01": (
        "Say you're open to talk, and suggest a time that works for both of you",
        "Konuşmaya açık olduğunu söyleyip ikiniz için uygun bir zaman önerirsin",
    ),
    "eq_set_026_q02": (
        "Say the lateness landed for you, and ask how to handle timing better",
        "Gecikmenin sana dokunduğunu söyleyip zamanlamayı nasıl daha iyi yöneteceğinizi sorarsın",
    ),
    "eq_set_029_q03": (
        "Pause and ask if now is a good moment, or if you should continue later",
        "Durup şimdi uygun bir an mı, yoksa sonra mı devam etmeniz gerektiğini sorarsın",
    ),
    "eq_set_029_q10": (
        "Ask them to name their worry while you also share what you need",
        "Endişelerini netleştirmelerini isterken sen de neye ihtiyacın olduğunu paylaşırsın",
    ),
    # moralizing wins
    "eq_set_031_q01": (
        "Tell them the warm message meant a lot, and ask if a slower next day helps",
        "Sıcak mesajın iyi geldiğini söyler; ertesi gün daha yavaş tempo ister misin diye sorarsın",
    ),
    "eq_set_034_q02": (
        "Remind them you're wiped tonight, and suggest another time that still feels close",
        "Bu gece bitkin olduğunu hatırlatır ve yine yakın hissettirecek başka bir zaman önerirsin",
    ),
    "eq_set_037_q03": (
        "Gently note their tone sounds off, and invite more if they want to share",
        "Tonlarının tuhaf geldiğini belirtir; isterlerse daha fazla anlatmalarına yer verirsin",
    ),
    "eq_set_037_q10": (
        "Invite them to share what's bothering them when they're ready, without pressing hard",
        "Hazır olduklarında neyin rahatsız ettiğini paylaşmaları için alan açar, baskı kurmazsın",
    ),
}

# Question EN micro-fixes (abstract word collision)
Q_EN: dict[str, str] = {
    "eq_set_024_q05": "Someone new freezes in group settings and later blames the atmosphere. What would you be most likely to do?",
    "eq_set_049_q10": "A mismatch in texting pace starts to create tension. What would you be most likely to do?",
}

# Question TR: şey + biri targeted replacements (full string replace)
Q_TR: dict[str, str] = {
    # vague_sey (concrete nouns; leave natural "hiçbir şey" / "Her şey" idioms)
    "eq_set_001_q06": "Kişisel bir anını paylaştın; görüştüğün kişi yanıtta konuyu değiştiriyor. Nasıl karşılık verirsin?",
    "eq_set_012_q10": "Daha kişisel bir anını paylaşınca sosyal çevrenden tanıdığın kişi geri çekiliyor. İlk tepkin ne olur?",
    "eq_set_019_q01": "Kırılgan bir konuyu anlatırken sözünü kesiyorlar. Nasıl yaklaşırsın?",
    "eq_set_023_q03": "Kırılgan bir konuyu paylaşınca eşleşmen susuyor. İlk tepkin ne olur?",
    "eq_set_029_q03": "Partnerin sen kişisel bir anını anlatırken başka işle uğraşıyor. Hangi yaklaşım sana daha yakın?",
    "eq_set_041_q04": "Dürüst bir yakınlık istediklerini söylerken yakalanması zor kalıyorlar. Nasıl yaklaşırsın?",
    "eq_set_042_q02": "Sert bir yorumdan sonra onarılacak bir konu yokmuş gibi davranıyorlar. Ne yaparsın?",
    "eq_set_042_q08": "Tartışmadan sonra bir konu çözülmeden yakınlık istiyorlar. Nasıl yaklaşırsın?",
    "eq_set_050_q05": "Senden rahatlama isterken karşılığında az emek veriyorlar. Nasıl yaklaşırsın?",
    # biri → more specific labels (natural Turkish)
    "eq_set_004_q07": "Hobi grubundan tanıdığın kişi yarınki buluşmayı akşam geç saate kadar onaylamıyor. Ne yaparsın?",
    "eq_set_005_q04": "Senden daha sessiz bir kişi film gecesini biletler bitmek üzereyken onaylıyor. Nasıl yaklaşırsın?",
    "eq_set_007_q01": "Hobi grubundan tanıdığın kişi toplu buluşma hikâyesinde eski sevgilisini anıyor. Nasıl karşılık verirsin?",
    "eq_set_007_q04": "Henüz tanımlamadığın kişi derin sohbette eski sevgilisini anıyor. İlk hamlen ne?",
    "eq_set_007_q06": "Sık seyahat eden kişi bavul açarken eski sevgilisini anıyor. Nasıl karşılık verirsin?",
    "eq_set_007_q09": "Senden daha sessiz bir kişi sen anı paylaştıktan sonra eski sevgilisinden bahsediyor. Nasıl yönetirsin?",
    "eq_set_009_q08": "Hobi grubundan tanıdığın kişi karışık sosyal buluşmaya huzursuz yaklaşıyor. Nasıl karşılık verirsin?",
    "eq_set_010_q03": "Sık seyahat eden kişi kısa ziyarette arkadaşlarınla tanışmaktan gergin. Nasıl yaklaşırsın?",
    "eq_set_010_q06": "Senden daha sessiz bir kişi konuşkan arkadaş grubunla tanışmaktan huzursuz. Nasıl karşılık verirsin?",
    "eq_set_011_q10": "Yeni tanıştığın kişi her dürüst konuşmayı şakaya bağlıyor. Bunu nasıl ele alırsın?",
    "eq_set_014_q06": "Yeni tanıştığın kişi sert tonu için özür diliyor ama senin nasıl hissettiğini sormuyor. Hangi yaklaşım sana daha yakın?",
    "eq_set_015_q07": "Yeni tanıştığın kişi müsaitim deyip günlerce kayboluyor. Ne yaparsın?",
    "eq_set_016_q06": "Yeni tanıştığın kişi aileyle ilgili bir dönüm noktasını heyecanlı ama gergin paylaşıyor. İlk tepkin ne olur?",
    "eq_set_017_q06": "Yeni tanıştığın kişi hakkında paylaşım yapman için baskı kuruyor. Hangi yaklaşım sana daha yakın?",
    "eq_set_017_q10": "Yakın olduğun kişi geçen hafta net koyduğun sınırı yok sayıyor. Bunu nasıl ele alırsın?",
    "eq_set_018_q06": "Yeni tanıştığın kişi dürüstlüğünün sert geldiğini söylüyor. Bunu nasıl ele alırsın?",
    "eq_set_019_q06": "Yeni tanıştığın kişi sen açılırken telefonuna bakıyor. İlk tepkin ne olur?",
    "eq_set_019_q10": "Yakın olduğun kişi araya girip ne diyeceğini bildiğini söylüyor. Hangi yaklaşım sana daha yakın?",
    "eq_set_020_q07": "Yeni tanıştığın kişi sessiz kaldıktan sonra \"istikrarda kötüyüm\" diyor. Nasıl karşılık verirsin?",
    "eq_set_021_q05": "Yeni tanıştığın kişi özel olup olmadığını her sorduğunda \"bakarız\" diyor. Ne yaparsın?",
    "eq_set_022_q06": "Yeni tanıştığın kişi nasıl geldiğini sormadan \"öyle demek istemedim\" diyor. İlk tepkin ne olur?",
    "eq_set_022_q09": "Yakın olduğun kişi neyin daha iyi olacağını söylemeden düzeleceğini vaat ediyor. Ne yaparsın?",
    "eq_set_023_q05": "Yeni tanıştığın kişi hızlı yaklaştırıp bir gecede alan istiyor. Bunu nasıl ele alırsın?",
    "eq_set_024_q05": "Yeni tanıştığın kişi grupta donup sonra ortamı suçluyor. Konuyu nasıl açarsın?",
    "eq_set_024_q08": "Yakın olduğun kişi başkalarıyla konuşurken görünmez hissettiğini söylüyor. Nasıl yaklaşırsın?",
    "eq_set_025_q06": "Yeni tanıştığın kişi yine kendi planı için arkadaş geceni iptal ettirmek istiyor. Bunu nasıl ele alırsın?",
    "eq_set_025_q10": "Yakın olduğun kişi sormadan senin hakkında özel detay paylaşıyor. Nasıl karşılık verirsin?",
    "eq_set_026_q05": "Yeni tanıştığın kişi küçük bir aksilikten sonra iletişim tarzını eleştiriyor. Hangi yaklaşım sana daha yakın?",
    "eq_set_027_q05": "Yeni tanıştığın kişi kendinden az paylaşırken yakınlık istiyor. İlk tepkin ne olur?",
    "eq_set_027_q08": "Yakın olduğun kişi önemsediğini söyleyip önemli anda ulaşılamıyor. Ne yaparsın?",
    "eq_set_028_q05": "Yeni tanıştığın kişi sohbet tonunun ekran görüntüsünü arkadaşlarına gösteriyor. Ne yaparsın?",
    "eq_set_028_q08": "Yakın olduğun kişi seni iğneli hissettiren bir gönderide etiketliyor. Nasıl karşılık verirsin?",
    "eq_set_029_q05": "Yeni tanıştığın kişi kimin önce yazdığını puanlıyor. Nasıl karşılık verirsin?",
    "eq_set_030_q05": "Yeni tanıştığın kişi tek buluşmadan sonra \"güvenlik için\" konumuna erişim istiyor. Bunu nasıl ele alırsın?",
    "eq_set_030_q06": "İş yerinde hoşlandığın kişi flört hayatın hakkında yorum yapıyor. Ne yaparsın?",
    "eq_set_030_q08": "Yakın olduğun kişi anlaşmazlıktan sonra sessizliği koz olarak kullanıyor. Konuyu nasıl açarsın?",
    "eq_set_031_q05": "Yeni tanıştığın kişi derin bağ kurup sonra hiçbir şey değişmemiş gibi sıradan davranıyor. Ne yaparsın?",
    "eq_set_032_q05": "Yeni tanıştığın kişi tek cümleyle özür dileyip ruh halinin hemen düzelmesini istiyor. Nasıl karşılık verirsin?",
    "eq_set_032_q09": "Yakın olduğun kişi uzaklaştıktan sonra dönüp yeniden tam erişim bekliyor. Ne yaparsın?",
    "eq_set_033_q05": "Yeni tanıştığın kişi zararsız bir grup fotoğrafından sonra kimlerle olduğunu soruyor. Nasıl yaklaşırsın?",
    "eq_set_033_q08": "Yakın olduğun kişi internette gördükleriyle verdiğin ilgiyi kıyaslıyor. Hangi tepki sana daha yakın?",
    "eq_set_034_q06": "Yeni tanıştığın kişi sunduğundan fazla günlük yazışma bekliyor. Nasıl karşılık verirsin?",
    "eq_set_034_q10": "Yakın olduğun kişi hazır olmadan daha erken tanıştırman için baskı yapıyor. Ne yaparsın?",
    "eq_set_035_q05": "Yeni tanıştığın kişi patlamalar halinde ilgili olup günlerce tutarsızlaşıyor. Bunu nasıl ele alırsın?",
    "eq_set_036_q05": "Yeni tanıştığın kişi sohbetin ortasında yazışma tarzını eleştiriyor. Konuyu nasıl açarsın?",
    "eq_set_036_q08": "Yakın olduğun kişi netleştirirken savunmacı göründüğünü söylüyor. İlk tepkin ne olur?",
    "eq_set_037_q05": "Yeni tanıştığın kişi sohbeti eğlenceli tutup gerçek hiçbir konudan kaçınıyor. İlk tepkin ne olur?",
    "eq_set_037_q08": "Yakın olduğun kişi nasılsın diye sorunca kısa yanıtlar veriyor. Ne yaparsın?",
    "eq_set_038_q05": "Yeni tanıştığın kişi geç gelip şakayla geçiştiriyor. Ne yaparsın?",
    "eq_set_038_q08": "Yakın olduğun kişi geri bildirim verince dinlemeden savunmak istiyorsun. Nasıl karşılık verirsin?",
    "eq_set_039_q05": "Yeni tanıştığın kişi birkaç saatte bir güvence istiyor. Nasıl karşılık verirsin?",
    "eq_set_040_q05": "Yeni tanıştığın kişi ilgilerini çok erken ve fazla kusursuz yansıtıyor. Nasıl yaklaşırsın?",
    "eq_set_040_q08": "Yakın olduğun kişi gerginlikten sonra meşguliyeti kalkan gibi kullanıyor. Hangi tepki sana daha yakın?",
}

# Frequency TR only — soften formal_passive endings
FREQ_TR: dict[str, str] = {
    "frequency_set_027_q12": '"Yarın konuşuruz" takibi rahatlatır. Sessiz günler uzaklaşmak demek değil.',
    "frequency_set_029_q10": "Hayal kırıklığı küçümseme olmadan söylenebilir. Her duyguyu hemen anlatmam şart değil.",
    "frequency_set_031_q10": "Duyguların kaba taslağını cilalamadan da paylaşabilirim. Her duyguyu hemen anlatmam şart değil; bağlam önemli.",
    "frequency_set_033_q11": "Yanıtlar anlık olmasa da derin mesaj dizileri yakın hissettirebilir. Sessiz günler uzaklaştığım anlamına gelmez.",
    "frequency_set_035_q10": "İletişimimin nasıl karşılandığına dair geri bildirim sorun değil. Her duyguyu hemen kelimelere dökmek şart değil.",
    "frequency_set_036_q10": "Sevgi dillerini esnek öğrenmek katı puanlamadan daha yararlı. Her duyguyu hemen anlatmam şart değil; bağlam önemli.",
    "frequency_set_038_q11": "Bunalma anında sohbeti duraklatmak ikimiz için de sağlıklıdır. Sessiz günler uzaklaştığım anlamına gelmez.",
    "frequency_set_040_q10": "Zor konuşmalarda nezaket sonucu değiştirdiği için ton önemli. Her duyguyu hemen kelimelere dökmek şart değil.",
    "frequency_set_041_q10": "Şaka altındaki duygusal işaretler yine dikkatimi çeker. Her duyguyu hemen anlatmam şart değil; bağlam önemli.",
    "frequency_set_043_q11": "Mesaj sınırlarını nazikçe söylemek benden saygılı bir yanıt alır. Sessiz günler uzaklaştığım anlamına gelmez.",
    "frequency_set_045_q10": "Donup kalmak yerine yanlış anlamaları yeniden ele alabilirim. Her duyguyu hemen kelimelere dökmek şart değil.",
    "frequency_set_046_q10": "Nazikçe paylaşılan güvensizlik özenli yanıt alır. Her duyguyu hemen anlatmam şart değil; bağlam önemli.",
    "frequency_set_048_q11": "Sıradan haftalarda da süren karşılıklı merak önemli. Sessiz günler uzaklaştığım anlamına gelmez.",
    "frequency_set_050_q10": "Kelimeler kusursuz olmasa da duygular kabaca adlandırılabilir. Her duyguyu hemen kelimelere dökmek şart değil.",
}


def polish_eq(data: dict) -> dict[str, int]:
    stats = {
        "questions_touched": 0,
        "caricature_opts": 0,
        "winner_opts": 0,
        "q_en": 0,
        "q_tr": 0,
    }
    touched: set[str] = set()

    for s in data["sets"]:
        for q in s["questions"]:
            qid = q["id"]
            changed = False

            if qid in Q_EN:
                q["question"]["en"] = Q_EN[qid]
                stats["q_en"] += 1
                changed = True

            if qid in Q_TR:
                q["question"]["tr"] = Q_TR[qid]
                stats["q_tr"] += 1
                changed = True

            if qid in WINNERS:
                idx = q["correctAnswer"]
                en, tr = WINNERS[qid]
                q["options"][idx]["label"]["en"] = en
                q["options"][idx]["label"]["tr"] = tr
                stats["winner_opts"] += 1
                changed = True

            for opt in q.get("options") or []:
                en = opt["label"]["en"]
                if en in CARICATURE:
                    nen, ntr = CARICATURE[en]
                    opt["label"]["en"] = nen
                    opt["label"]["tr"] = ntr
                    stats["caricature_opts"] += 1
                    changed = True

            if changed:
                touched.add(qid)

    stats["questions_touched"] = len(touched)
    return stats


def polish_freq(data: dict) -> dict[str, int]:
    n = 0
    for s in data["sets"]:
        for q in s["questions"]:
            qid = q["id"]
            if qid in FREQ_TR:
                q["question"]["tr"] = FREQ_TR[qid]
                n += 1
    return {"questions_touched": n}


def main() -> None:
    eq = json.loads(EQ_PATH.read_text(encoding="utf-8"))
    freq = json.loads(FREQ_PATH.read_text(encoding="utf-8"))

    eq_stats = polish_eq(eq)
    freq_stats = polish_freq(freq)

    EQ_PATH.write_text(json.dumps(eq, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    FREQ_PATH.write_text(json.dumps(freq, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    print("EQ polish:", eq_stats)
    print("Frequency polish:", freq_stats)


if __name__ == "__main__":
    main()
