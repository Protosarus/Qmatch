#!/usr/bin/env python3
"""Apply Phase 3L-A1 EQ content rewrite to eq_set_001..010.

Read-only on all files except eq_sets.json text fields.
Preserves IDs, correctAnswer, difficulty, option order/count.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EQ_PATH = ROOT / "assets" / "data" / "assessment_sets" / "eq_sets.json"
SCENARIOS_PATH = ROOT / "scripts" / "eq_batch1_scenarios.json"

SECURE = [
    ("Reach out gently, share what you noticed, and ask what they need", "Fark ettiğini nazikçe söyleyip neye ihtiyaçları olduğunu sorarsın"),
    ("Send a warm check-in and invite them to share at their pace", "Sıcak bir mesajla hal hatır sorup kendi hızlarında anlatmalarını istersin"),
    ("Name what felt different and ask if now is a good time to talk", "Farklı hissettiren şeyi söyleyip konuşmak için uygun olup olmadığını sorarsın"),
    ("Suggest a quick clarity chat and stay open to their answer", "Kısa bir netleşme sohbeti önerir ve yanıtlarına açık kalırsın"),
    ("Acknowledge the tension and ask what pace would feel comfortable", "Gerginliği fark edip hangi temponun rahat olacağını sorarsın"),
    ("Validate their concern and explore a workable next step together", "Endişelerini anladığını belirtip birlikte uygulanabilir bir adım ararsın"),
    ("Mirror their news with warmth and ask a thoughtful follow-up", "Haberlerine sıcaklıkla karşılık verip düşünceli bir soru sorarsın"),
    ("Pause, listen fully, then respond with calm curiosity", "Durup tam dinler, sonra sakin bir merakla yanıt verirsin"),
    ("Thank them for honesty and ask what reassurance would actually help", "Dürüstlükleri için teşekkür edip hangi güvencenin işe yarayacağını sorarsın"),
    ("Offer flexibility and propose a simple plan you can both accept", "Esneklik sunar ve ikinizin de kabul edebileceği sade bir plan önerirsin"),
    ("Check whether timing is off and suggest revisiting when ready", "Zamanlamanın uygun olup olmadığını sorup hazır olunca dönmeyi önerirsin"),
    ("Stay steady, reflect what you heard, and ask one open question", "Sakin kalır, duyduğunu yansıtır ve açık uçlu bir soru sorarsın"),
    ("Confirm you want to understand and invite them to say more", "Anlamak istediğini belirtip biraz daha anlatmalarını istersin"),
    ("Propose a short call instead of guessing over text", "Yazışmada tahmin yürütmek yerine kısa bir arama önerirsin"),
    ("Recognize their stress and ask what support looks like for them", "Streslerini fark edip onlar için desteğin neye benzediğini sorarsın"),
    ("Agree to slow down and ask what would make this feel safer", "Temponu düşürmeyi kabul edip bunu daha güvenli hissettirecek şeyi sorarsın"),
    ("Share your read gently and ask if you got it right", "Yorumunu yumuşakça paylaşıp doğru anlayıp anlamadığını sorarsın"),
    ("Suggest a small repair step and see if they're open to it", "Küçük bir telafi adımı önerir ve açık olup olmadıklarını sorarsın"),
    ("Hold space, then ask what outcome they hope for", "Alan tanıyıp hangi sonucu umduklarını sorarsın"),
    ("Meet them where they are and co-create a lighter next move", "Bulundukları yere uyup birlikte daha hafif bir sonraki adım üretirsin"),
    ("Ask what felt unclear and offer to reset the plan calmly", "Neyin belirsiz kaldığını sorar ve planı sakince yeniden kurmayı önerirsin"),
    ("Respond with empathy first, logistics second", "Önce empatiyle karşılar, sonra pratik detaylara geçersin"),
    ("Name the pattern without blame and ask how to improve it", "Kalıbı suçlamadan söyler ve nasıl iyileştirebileceğinizi sorarsın"),
    ("Show you're listening and ask what would feel fair to both", "Dinlediğini hissettirir ve ikinize de adil olacak şeyi sorarsın"),
    ("Keep tone soft and ask if they want advice or just presence", "Yumuşak kalır ve tavsiye mi yoksa sadece yanında olmak mı istediklerini sorarsın"),
]

PASSIVE = [
    ("Say nothing and wait for them to restart the conversation", "Hiçbir şey söylemeden konuşmayı onların başlatmasını beklersin"),
    ("Pull back and hope the awkward phase passes on its own", "Geriye çekilip garip dönemin kendi kendine geçmesini beklersin"),
    ("Pretend you didn't notice and change the subject", "Fark etmemiş gibi yapıp konuyu değiştirirsin"),
    ("Stop making plans until they bring it up again", "Onlar tekrar açana kadar plan yapmaktan vazgeçersin"),
    ("Reply with one word so they get the hint", "Anlasınlar diye tek kelimelik yanıt verirsin"),
    ("Cancel your side of the plan without discussing it", "Konuşmadan kendi tarafındaki planı iptal edersin"),
    ("Go quiet for days to avoid an uncomfortable talk", "Rahatsız edici konuşmadan kaçınmak için günlerce susarsın"),
    ("Assume they'll figure it out and stay offline", "Kendi çözeceklerini varsayıp çevrim dışı kalırsın"),
    ("Keep score silently and act normal in public", "İçten içe not tutar ama dışarıda normal davranırsın"),
    ("Let the moment pass and never mention it again", "Anı geçirir ve bir daha asla açmazsın"),
    ("Avoid the invite so you don't have to deal with tension", "Gerginlikle uğraşmamak için daveti pas geçersin"),
    ("Wait until they apologize first, no matter how long", "Ne kadar sürerse sürsün önce onların özür dilemesini beklersin"),
    ("Mute the chat and focus on other people", "Sohbeti sessize alıp başkalarına yönelirsin"),
    ("Show up late on purpose to signal frustration", "Kırgınlığını göstermek için bilerek geç kalırsın"),
    ("Drop the topic and act busier than you are", "Konuyu bırakır ve olduğundan daha meşgul görünürsün"),
    ("Leave the message on read and post stories instead", "Mesajı okunmuş bırakıp hikâye paylaşırsın"),
    ("Agree in person but ignore follow-up texts", "Yüz yüzeyken kabul edip sonraki mesajları görmezden gelirsin"),
    ("Hope a mutual friend will smooth things over", "Ortak bir arkadaşın yumuşatmasını beklersin"),
    ("Delay responding until the plans expire", "Planlar düşene kadar yanıtlamayı ertelersin"),
    ("Step back entirely without explaining why", "Nedenini açıklamadan tamamen geri çekilirsin"),
    ("Keep interactions surface-level until they try harder", "Daha çok çabalarlar diye ilişkiyi yüzeysel tutarsın"),
    ("Avoid eye contact and keep answers minimal", "Göz temasından kaçınır ve yanıtları minimumda tutarsın"),
    ("Let them cancel again without saying how you feel", "Tekrar iptal etmelerine izin verir ama ne hissettiğini söylemezsin"),
    ("Wait for a perfect moment that never comes", "Hiç gelmeyen mükemmel anı beklersin"),
    ("Say \"it's fine\" and emotionally check out", "\"Tamam\" deyip duygusal olarak geri çekilirsin"),
]

OVERthink = [
    ("Send a long message analyzing what they might be feeling", "Ne hissediyor olabileceklerine dair uzun bir analiz mesajı atarsın"),
    ("Draft three versions of a reply before sending one", "Göndermeden önce üç farklı yanıt taslağı hazırlarsın"),
    ("Replay the thread and list every possible meaning", "Yazışmayı baştan okuyup her olası anlamı listelersin"),
    ("Ask five clarifying questions in one text block", "Tek mesajda beş netleştirici soru sorarsın"),
    ("Write a paragraph explaining your intentions in detail", "Niyetlerini ayrıntılı anlatan uzun bir paragraf yazarsın"),
    ("Speculate about their past relationships in your reply", "Yanıtında geçmiş ilişkileri hakkında tahmin yürütürsün"),
    ("Send a voice note monologue unpacking the situation", "Durumu uzun bir sesli notta tek başına çözersin"),
    ("Create a mental scorecard and reference it in text", "Zihinsel bir puan tablosu yapıp yazışmada buna gönderme yaparsın"),
    ("Over-explain why your tone was actually reasonable", "Tonunun aslında makul olduğunu aşırı uzun savunursun"),
    ("Quote old messages to prove your point", "Haklı olduğunu kanıtlamak için eski mesajları alıntılarsın"),
    ("Send a bulleted list of what they did wrong", "Yaptıkları hataların maddeli listesini gönderirsin"),
    ("Ask them to define every vague word they used", "Kullandıkları her belirsiz kelimeyi tanımlamalarını istersin"),
    ("Turn the chat into a debate about communication styles", "Sohbeti iletişim tarzları tartışmasına çevirirsin"),
    ("Research advice online and paste a summary to them", "İnternetten tavsiye arayıp özetini onlara yapıştırırsın"),
    ("Send a timeline of events from your perspective", "Kendi perspektifinden olay zaman çizelgesi gönderirsin"),
    ("Ask hypotheticals about ten future scenarios at once", "Aynı anda on farklı senaryo için \"ya şöyle olursa\" sorarsın"),
    ("Write like a therapist note instead of a partner text", "Partner mesajı yerine terapist notu gibi yazarsın"),
    ("Bring up old unrelated conflicts to add context", "Bağlam diye alakasız eski tartışmaları açarsın"),
    ("Send a poll with four interpretations of their mood", "Ruh hallerinin dört yorumu için anket gönderirsin"),
    ("Explain attachment theory before answering simply", "Basit yanıt vermeden önce bağlanma teorisini anlatırsın"),
    ("Type, delete, retype, then send something twice as long", "Yazıp silersin, tekrar yazarsın; iki kat uzun gönderirsin"),
    ("Ask them to rate your message on a scale of 1-10", "Mesajını 1-10 arası puanlamalarını istersin"),
    ("Send screenshots of similar situations from other chats", "Başka sohbetlerden benzer durumların ekran görüntüsünü atarsın"),
    ("Build a pros-and-cons list about the relationship mid-chat", "Sohbetin ortasında ilişki artı-eksi listesi çıkarırsın"),
    ("Respond with a formal email-style structure", "Resmi e-posta formatında yanıt verirsin"),
]

PUNITIVE = [
    ("Reply coldly to show you're unimpressed", "Hayal kırıklığını belli etmek için soğuk yanıt verirsin"),
    ("Point out what they're doing wrong in blunt terms", "Yanlış yaptıklarını doğrudan yüzlerine söylersin"),
    ("Match their distance to punish them silently", "Sessizce cezalandırmak için mesafeyi aynalayarak karşılık verirsin"),
    ("Say they should know better by now", "Artık daha iyi bilmesi gerektiğini söylersin"),
    ("Bring up their past mistakes to win the argument", "Tartışmayı kazanmak için eski hatalarını gündeme getirirsin"),
    ("Tell them talking about exes is off-limits forever", "Eski sevgili konuşmasının tamamen yasak olduğunu söylersin"),
    ("Withdraw warmth until they apologize first", "Önce özür dilemeleri için sıcaklığını geri çekersin"),
    ("Mock their concern to lighten it on your terms", "Endişelerini kendi şartlarınla küçümseyerek şaka yaparsın"),
    ("Give a sarcastic \"great job\" and stop engaging", "Alaycı bir \"aferin\" deyip iletişimi kesersin"),
    ("Threaten to end things if they don't comply", "Uymazlarsa bitireceğinle imalı tehdit edersin"),
    ("Publicly vent about them to mutual friends", "Ortak arkadaşlara onlar hakkında şikâyet edersin"),
    ("Use their vulnerability against them later", "Açtıkları zayıf noktayı sonra karşılarında kullanırsın"),
    ("Reply with one-word answers until they give in", "Pes edene kadar tek kelimelik yanıtlarla devam edersin"),
    ("Say you're done trying and mean it as leverage", "Denemekten vazgeçtiğini koz olarak söylersin"),
    ("Compare them unfavorably to someone else", "Onları başka biriyle olumsuz kıyaslersın"),
    ("Ignore their apology and keep punishing", "Özürlerini görmezden gelip cezalandırmaya devam edersin"),
    ("Tell them they're being dramatic on purpose", "Kasıtlı olarak abarttıklarını söylersin"),
    ("Refuse to discuss it and call them immature", "Konuşmayı reddedip olgunlaşmadıklarını söylersin"),
    ("Make them chase you for basic clarity", "Temel bir netlik için seni kovalamalarını beklersin"),
    ("Use guilt to make them feel selfish", "Bencillik hissettirmek için suçluluk yükü bindirirsin"),
    ("Say \"whatever\" and act like you don't care", "\"Neyse\" deyip umursamıyormuş gibi davranırsın"),
    ("Bring up how much you've done for them", "Onlar için ne kadar şey yaptığını hatırlatırsın"),
    ("Shut down future plans without discussion", "Tartışmadan gelecek planları kapatırsın"),
    ("Tell them they're lucky you stayed this long", "Bu kadar kaldığın için şanslı olduklarını söylersin"),
    ("Answer with passive-aggressive memes only", "Sadece pasif-agresif meme'lerle yanıt verirsin"),
]

IMPULSIVE = [
    ("Assume the worst and start pulling away fast", "En kötüsünü düşünüp hızla geri çekilmeye başlarsın"),
    ("Make backup plans with someone else right away", "Hemen başka biriyle yedek plan yaparsın"),
    ("Text that you're done and delete the thread", "Bittiğini yazıp sohbeti silersin"),
    ("Post something vague online aimed at them", "Onlara ima eden belirsiz bir şey paylaşırsın"),
    ("Confront them in public without warning", "Uyarmadan kalabalıkta yüzlerine vurursun"),
    ("Call five times until they pick up", "Açana kadar beş kez ararsın"),
    ("Book something solo and tell them too late", "Tek başına plan yapar ve çok geç söylersin"),
    ("Swipe on apps to prove you have options", "Seçeneklerin olduğunu kanıtlamak için uygulamalara dönersin"),
    ("Send a breakup-style message over a small issue", "Küçük bir konuda ayrılık mesajı gönderirsin"),
    ("Show up at their place unannounced", "Haber vermeden kapılarına gidersin"),
    ("Tell mutual friends your version immediately", "Hemen ortak arkadaşlara kendi versiyonunu anlatırsın"),
    ("Assume they're lying and accuse them directly", "Yalan söylediklerini varsayıp doğrudan suçlarsın"),
    ("Cancel everything and go offline for days", "Her şeyi iptal edip günlerce çevrim dışı kalırsın"),
    ("Reply with anger before hearing the full story", "Tüm hikâyeyi dinlemeden öfkeyle yanıt verirsin"),
    ("Make a big romantic gesture to force closeness", "Yakınlığı zorlamak için büyük bir jest yaparsın"),
    ("Threaten to expose the conversation", "Konuşmayı ifşa etmekle tehdit edersin"),
    ("Jump to defining the relationship in one message", "Tek mesajda ilişkiyi tanımlamaya atlarsın"),
    ("Spend money to prove a point about plans", "Plan konusunda haklı olduğunu kanıtlamak için para harcarsın"),
    ("Invite someone else to replace them quickly", "Yerlerine hızlıca başkasını davet edersin"),
    ("Send a voice note rant and regret it later", "Öfke dolu sesli not atar sonra pişman olursun"),
    ("Block them before they can explain", "Açıklamadan önce engellersin"),
    ("Assume silence means they're cheating", "Sessizliği aldatma olarak yorumlarsın"),
    ("Quit the shared plan and ghost the group chat", "Ortak plandan çekilip grup sohbetinde kaybolursun"),
    ("Make a dramatic ultimatum over text", "Yazışmada dramatik bir ultimatom verirsin"),
    ("Rebound socially the same night to cope", "Aynı gece başkalarıyla görüşerek başa çıkmaya çalışırsın"),
]

DEFENSIVE = [
    ("Take it personally and read it as rejection", "Kişisel algılar ve reddedilme olarak yorumlarsın"),
    ("Change the subject to protect yourself", "Kendini korumak için konuyu değiştirirsin"),
    ("Assume they're ashamed of you", "Senden utandıklarını varsayarsın"),
    ("Compare them to an ex to regain control", "Kontrolü geri almak için eski sevgilinle kıyaslarsın"),
    ("Get sarcastic because you feel exposed", "Savunmasız hissettiğin için alaycı olursun"),
    ("Shut down and say you don't care anyway", "Kapanır ve zaten umursamadığını söylersin"),
    ("Interpret honesty as an attack on you", "Dürüstlüğü sana saldırı olarak yorumlarsın"),
    ("Bring up your own pain to cancel theirs", "Onların acısını geçersiz kılmak için kendi acını öne çıkarırsın"),
    ("Assume they're comparing you to someone better", "Seni daha iyisiyle kıyasladıklarını düşünürsün"),
    ("Deflect with humor before listening", "Dinlemeden önce şakayla konuyu savuşturursun"),
    ("Say they're too sensitive and drop it", "Aşırı hassas olduklarını söyleyip konuyu kapatırsın"),
    ("Read silence as proof they lost interest", "Sessizliği ilginin bittiğinin kanıtı sayarsın"),
    ("Ask passive questions to trap them", "Onları köşeye sıkıştırmak için imalı sorular sorarsın"),
    ("Focus on being right instead of understood", "Anlaşılmak yerine haklı olmaya odaklanırsın"),
    ("Assume bad intent behind a small comment", "Küçük bir yorumun arkasında kötü niyet varsayarsın"),
    ("Withdraw affection to test if they'll chase", "Kovalayıp kovalamadıklarını test etmek için ilgini çekersin"),
    ("Mention how hard you try whenever challenged", "Sorgulandığında ne kadar çabaladığını hatırlatırsın"),
    ("Turn their concern into criticism of you", "Endişelerini kendine yönelik eleştiriye çevirirsın"),
    ("Say you'll leave before they can hurt you", "Seni incitmeden önce gideceğini söylersin"),
    ("Assume they're hiding something major", "Büyük bir şey sakladıklarını düşünürsün"),
    ("Replay worst-case scenarios and react to those", "En kötü senaryoları canlandırıp onlara tepki verirsin"),
    ("Dismiss their feelings because yours feel bigger", "Seninkiler daha büyük hissettirdiği için onların duygularını küçümsersin"),
    ("Ask why you're never enough in the moment", "O anda neden asla yeterli olmadığını sorarsın"),
    ("Use past hurt to avoid the current conversation", "Şimdiki konuşmadan kaçmak için eski yaraları kullanırsın"),
    ("Interpret boundaries as personal rejection", "Sınırları kişisel ret olarak yorumlarsın"),
]

PUSHY = [
    ("Press for an immediate yes or no answer", "Hemen evet ya da hayır cevabı zorlarsın"),
    ("Push to meet friends before they're ready", "Hazır olmadan arkadaşlarla tanışmayı zorlarsın"),
    ("Demand a firm date on the spot", "O anda kesin bir tarih talep edersin"),
    ("Insist on defining the relationship tonight", "Bu gece ilişkiyi tanımlamakta ısrar edersin"),
    ("Keep texting until they respond the way you want", "İstediğin gibi yanıtlayana kadar yazmaya devam edersin"),
    ("Show up to their plans to force a conversation", "Konuşmayı zorlamak için planlarına çıkarsın"),
    ("Ask them to choose you over other commitments now", "Şimdi seni diğer sorumluluklara tercih etmelerini istersin"),
    ("Push for a public label on social media", "Sosyal medyada açık bir tanım zorlarsın"),
    ("Schedule meetings with friends without asking", "Sormadan arkadaşlarla buluşmalar ayarlarsın"),
    ("Repeat the same invite until they agree", "Kabul edene kadar aynı daveti tekrarlarsın"),
    ("Corner them with \"we need to talk\" late at night", "Gece geç \"konuşmamız lazım\" diye sıkıştırırsın"),
    ("Demand they cancel other plans for you", "Senin için diğer planları iptal etmelerini istersin"),
    ("Push for intimacy faster than the pace allows", "Temponun izin verdiğinden hızlı yakınlık zorlarsın"),
    ("Insist on meeting family immediately", "Hemen aileyle tanışmayı ısrarla istersin"),
    ("Set ultimatums about commitment timelines", "Bağlılık takvimi için ultimatom koyarsın"),
    ("Keep calling after they ask for space", "Alan istedikten sonra aramaya devam edersın"),
    ("Push them to post about you online", "Senin hakkında paylaşım yapmalarını zorlarsın"),
    ("Demand detailed answers on the spot", "O anda ayrıntılı cevaplar talep edersin"),
    ("Try to lock every future weekend in one chat", "Tek sohbette tüm gelecek hafta sonlarını kilitlemeye çalışırsın"),
    ("Insist their friends will love you without consent", "Onay almadan arkadaşlarının seni seveceğini ısrarla söylersin"),
    ("Push a group intro during a tense moment", "Gergin bir anda grup tanıştırmasını zorlarsın"),
    ("Ask for exclusivity before trust is built", "Güven oluşmadan özel olmayı talep edersin"),
    ("Keep raising stakes when they hesitate", "Tereddüt ettikçe bahsi yükseltirsin"),
    ("Demand they choose a side in your conflict", "Çatışmanda taraf seçmelerini zorlarsın"),
    ("Schedule a hard talk without checking timing", "Zamanlamayı sormadan zor bir konuşma ayarlarsın"),
]

POOLS = {
    "secure": SECURE,
    "passive": PASSIVE,
    "overthink": OVERthink,
    "punitive": PUNITIVE,
    "impulsive": IMPULSIVE,
    "defensive": DEFENSIVE,
    "pushy": PUSHY,
}


def classify(opt: str) -> str:
    t = opt.lower()
    if any(
        k in t
        for k in [
            "check in kindly",
            "clarity window",
            "stay curious",
            "acknowledge the tension",
            "offer flexibility",
        ]
    ):
        return "secure"
    if any(
        k in t
        for k in [
            "wait silently",
            "pretend you didn",
            "cancel all social",
            "hope it resolves",
        ]
    ):
        return "passive"
    if "long analysis" in t:
        return "overthink"
    if any(
        k in t
        for k in [
            "teach them",
            "lecture them",
            "withdraw affection",
            "never to mention",
            "tell them never",
            "match short",
        ]
    ):
        return "punitive"
    if any(k in t for k in ["dating others immediately", "flaky"]):
        return "impulsive"
    if any(k in t for k in ["compare them to your ex", "ashamed of you"]):
        return "defensive"
    if any(k in t for k in ["push them to commit", "firm date this minute"]):
        return "pushy"
    return "secure"


def pick(pool: list[tuple[str, str]], idx: int) -> tuple[str, str]:
    return pool[idx % len(pool)]


def main() -> None:
    scenarios = {row["id"]: row for row in json.loads(SCENARIOS_PATH.read_text(encoding="utf-8"))}
    data = json.loads(EQ_PATH.read_text(encoding="utf-8"))
    q_counter = 0

    for s in data["sets"]:
        if not re.match(r"^eq_set_00[1-9]$|^eq_set_010$", s["id"]):
            continue
        for q in s["questions"]:
            qid = q["id"]
            if qid not in scenarios:
                raise KeyError(f"Missing scenario for {qid}")
            sc = scenarios[qid]
            q["question"]["en"] = sc["en"]
            q["question"]["tr"] = sc["tr"]

            styles = [classify(o["label"]["en"]) for o in q["options"]]
            for i, style in enumerate(styles):
                en, tr = pick(POOLS[style], q_counter + i)
                q["options"][i]["label"]["en"] = en
                q["options"][i]["label"]["tr"] = tr
            q_counter += 1

    EQ_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Rewrote batch 1: {q_counter} questions in eq_sets.json")


if __name__ == "__main__":
    main()
