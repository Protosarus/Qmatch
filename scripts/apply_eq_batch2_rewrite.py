#!/usr/bin/env python3
"""Apply Phase 3L-A2 EQ content rewrite to eq_set_011..020.

Changes only question.en/tr and option label en/tr.
Preserves IDs, correctAnswer, difficulty, option order/count.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EQ_PATH = ROOT / "assets" / "data" / "assessment_sets" / "eq_sets.json"
SCENARIOS_PATH = ROOT / "scripts" / "eq_batch2_scenarios.json"

SECURE = [
    ("Notice the dodge and offer to revisit when they're ready", "Kaçındıklarını fark edip hazır olduklarında dönmeyi önerirsin"),
    ("Reassure calmly and share what bandwidth you have today", "Sakin güvence verip bugün ne kadar alanın olduğunu söylersin"),
    ("Celebrate with them and ask a genuine follow-up", "Onlarla birlikte sevinip gerçek bir takip sorusu sorarsın"),
    ("Pause, let them finish, then share your part calmly", "Durup bitirmelerine izin verir, sonra kendi kısmını sakince anlatırsın"),
    ("Name what you felt and invite a clearer next step together", "Ne hissettiğini söyleyip birlikte daha net bir sonraki adım ararsın"),
    ("Stay warm, reflect what you heard, and ask one open question", "Sıcak kalır, duyduğunu yansıtır ve açık bir soru sorarsın"),
    ("Acknowledge their pace and ask what would feel fair", "Tempolarını kabul edip neyin adil geleceğini sorarsın"),
    ("Thank them for saying it and ask how to repair this well", "Söyledikleri için teşekkür edip bunu nasıl onarabileceğinizi sorarsın"),
    ("Check if timing is off before pushing for more detail", "Daha fazla detay istemeden önce zamanlamanın uygun olup olmadığını sorarsın"),
    ("Offer a short call so nothing gets lost over text", "Yazışmada kaybolmasın diye kısa bir arama önerirsin"),
    ("Validate their concern without rushing to fix it", "Hemen çözmeye koşmadan endişelerini doğrularsın"),
    ("Ask what support they want—advice or just presence", "Tavsiye mi yoksa sadece yanında olmak mı istediklerini sorarsın"),
    ("Share your read gently and ask if you got it right", "Yorumunu yumuşakça paylaşıp doğru anlayıp anlamadığını sorarsın"),
    ("Suggest a lighter plan while keeping the door open", "Kapıyı açık tutarak daha hafif bir plan önerirsin"),
    ("Hold steady and ask what would make this feel safer", "Sakin kalır ve bunu daha güvenli hissettirecek şeyi sorarsın"),
    ("Confirm you care and ask how they want to handle it", "Önemsediğini belirtip bunu nasıl ele almak istediklerini sorarsın"),
    ("Make room for their news before adding your own", "Kendi haberini eklemeden önce onların haberine alan açarsın"),
    ("Respond with curiosity instead of pressure", "Baskı yerine merakla karşılık verirsin"),
    ("Agree on a simple reset so expectations stay clear", "Beklentiler net kalsın diye sade bir yeniden başlangıç önerirsin"),
    ("Listen fully first, then decide the next step together", "Önce tam dinler, sonra sonraki adımı birlikte seçersin"),
    ("Name the pattern kindly and ask how to improve it", "Kalıbı nazikçe söyler ve nasıl iyileştirebileceğinizi sorarsın"),
    ("Show patience and invite them to share when ready", "Sabır gösterir ve hazır olunca anlatmalarını istersin"),
    ("Keep tone soft and ask what felt missing", "Yumuşak kalır ve neyin eksik hissettirdiğini sorarsın"),
    ("Offer flexibility without abandoning your needs", "Kendi ihtiyaçlarını bırakmadan esneklik sunarsın"),
    ("Meet them halfway and clarify one concrete next move", "Yarı yolda buluşur ve somut bir sonraki adımı netleştirirsin"),
]

PASSIVE = [
    ("Let it slide and say nothing about how you feel", "Nasıl hissettiğini söylemeden geçiştirirsin"),
    ("Go quiet and hope they notice on their own", "Susup kendilerinin fark etmesini beklersin"),
    ("Change the subject so the moment doesn't get heavier", "An daha ağırlaşmasın diye konuyu değiştirirsin"),
    ("Agree quickly just to end the tension", "Gerginliği bitirmek için hemen kabul edersin"),
    ("Ignore the follow-ups and stay busy elsewhere", "Takip mesajlarını yok sayıp başka yerde meşgul kalırsın"),
    ("Downplay it so nobody has to deal with feelings", "Kimse duygularla uğraşmasın diye küçümsersin"),
    ("Shut down and stop sharing for a while", "Bir süre kapanıp paylaşmayı bırakırsın"),
    ("Wait for them to bring it up again later", "Daha sonra onların açmasını beklersin"),
    ("Smile through it and keep things surface-level", "Gülümseyip ilişkiyi yüzeysel tutarsın"),
    ("Act fine in the group and process alone later", "Grupta iyi görünür, sonra yalnız başına düşünürsün"),
    ("Skip the plan without explaining why", "Nedenini açıklamadan planı pas geçersin"),
    ("Leave the chat and avoid the next check-in", "Sohbetten çıkar ve sonraki yazışmayı atlarısın"),
    ("Say \"no worries\" even when it bothers you", "Rahatsız olsa da \"sorun değil\" dersin"),
    ("Hope a mutual friend will smooth it over", "Ortak bir arkadaşın yumuşatmasını beklersin"),
    ("Stay polite but emotionally unavailable", "Kibar kalır ama duygusal olarak uzaklaşırsın"),
    ("Delay your reply until the topic fades", "Konu sönene kadar yanıtı ertelersin"),
    ("Pretend you didn't notice the shift", "Değişimi fark etmemiş gibi yaparsın"),
    ("Keep score silently without saying a word", "Tek kelime etmeden içten içe not tutarsın"),
    ("Avoid eye contact and keep answers short", "Göz temasından kaçınır ve kısa yanıt verirsin"),
    ("Let them set the whole tone while you withdraw", "Sen geri çekilirken tonu tamamen onlara bırakırsın"),
    ("Cancel quietly so you don't have to talk it through", "Konuşmamak için sessizce iptal edersin"),
    ("Stay online but never reopen the topic", "Çevrimiçi kalır ama konuyu bir daha açmazsın"),
    ("Accept the vague plan and lower your expectations", "Belirsiz planı kabul edip beklentini düşürürsün"),
    ("Nod along and save the discomfort for later", "Başını sallar, rahatsızlığı sonraya saklarsın"),
    ("Give minimal replies until they stop asking", "Sormayı bırakana kadar minimum yanıt verirsin"),
]

OVERTHINK = [
    ("Send a string of follow-up questions in one burst", "Tek seferde peş peşe netleştirici sorular gönderirsin"),
    ("Analyze every pause and reply with a long theory", "Her duraksamayı analiz edip uzun bir teori yazarsın"),
    ("Ask for a detailed timeline before responding simply", "Basit yanıt vermeden önce ayrıntılı zaman çizelgesi istersin"),
    ("Draft multiple replies and send the longest one", "Birkaç taslak yazıp en uzununu gönderirsin"),
    ("Quote older messages to prove a pattern", "Bir kalıbı kanıtlamak için eski mesajları alıntılarsın"),
    ("Turn the chat into a checklist of feelings", "Sohbeti duygu kontrol listesine çevirirsin"),
    ("Ask ten clarifying questions before listening fully", "Tam dinlemeden önce on netleştirici soru sorarsın"),
    ("Write a paragraph explaining all possible motives", "Tüm olası niyetleri anlatan uzun bir paragraf yazarsın"),
    ("Bring up unrelated past moments for \"context\"", "\"Bağlam\" diye alakasız geçmiş anları açarsın"),
    ("Send a voice-note monologue unpacking everything", "Her şeyi uzun bir sesli notta tek başına çözersin"),
    ("Request definitions for every vague word they used", "Kullandıkları her belirsiz kelimeyi tanımlamalarını istersin"),
    ("Map the conflict like a project brief", "Çatışmayı proje özeti gibi şemalandırırsın"),
    ("Ask them to rate the conversation from one to ten", "Konuşmayı birden ona puanlamalarını istersin"),
    ("Over-explain your intentions before hearing theirs", "Onlarınkini dinlemeden niyetlerini aşırı açıklarısın"),
    ("Create scenarios and ask which one is \"real\"", "Senaryolar üretip hangisinin \"gerçek\" olduğunu sorarsın"),
    ("Paste advice summaries into the chat", "Tavsiye özetlerini sohbete yapıştırırsın"),
    ("Demand exact wording for what they meant", "Ne demek istediklerinin birebir ifadesini istersin"),
    ("Replay the thread aloud and keep texting conclusions", "Yazışmayı sesli okuyup sonuçları mesajla yağdırırsın"),
    ("Ask them to confirm three interpretations at once", "Üç yorumu birden doğrulatmalarını istersin"),
    ("Write like a case study instead of a human reply", "İnsan gibi değil vaka çalışması gibi yanıt verirsin"),
    ("Push for immediate full disclosure in one sitting", "Tek oturuşta her şeyi açıklamalarını zorlarsın"),
    ("Send a bullet list of what felt unclear", "Belirsiz gelenlerin maddeli listesini atarsın"),
    ("Ask why before they finish the first sentence", "İlk cümleyi bitirmeden neden diye sorarsın"),
    ("Keep probing until the conversation feels like an interview", "Sohbet röportaja dönene kadar sorguya devam edersin"),
    ("Respond with a structured essay about the dynamic", "Dinamik hakkında yapılandırılmış bir deneme yazarsın"),
]

PUNITIVE = [
    ("Tell them to calm down and stop over-apologizing", "Sakinleşmelerini ve özür yağmurunu kesmelerini söylersin"),
    ("Tease them for caring too much in a sharp way", "Çok önemsedikleri için iğneleyici şekilde takılırsın"),
    ("Correct them sharply for cutting you off", "Sözünü kestiği için sertçe düzeltirsin"),
    ("Call out their flaw in blunt, public-facing language", "Kusurunu doğrudan ve sert bir dille yüzlerine vurursun"),
    ("Withdraw warmth until they \"earn\" it back", "\"Hak edene\" kadar sıcaklığını geri çekersin"),
    ("Use sarcasm to make them feel small", "Küçük hissetmeleri için alaycı olursun"),
    ("Say they should already know better", "Artık daha iyi bilmeleri gerektiğini söylersin"),
    ("Bring up old mistakes to win the moment", "Anı kazanmak için eski hatalarını gündeme getirirsin"),
    ("Reply coldly so they feel the cost", "Bedeli hissetsinler diye soğuk yanıt verirsin"),
    ("Tell them they're being dramatic on purpose", "Kasıtlı abarttıklarını söylersin"),
    ("Mock the apology instead of receiving it", "Özrü almak yerine alaya alırsın"),
    ("Shut the topic with a cutting one-liner", "Keskin bir cümleyle konuyu kapatırsın"),
    ("Compare them unfavorably to someone else", "Onları başka biriyle olumsuz kıyaslersın"),
    ("Make them chase basic kindness from you", "Senden temel bir nezaket için kovalamalarını sağlarsın"),
    ("Answer with \"whatever\" and stay punitive", "\"Neyse\" deyip cezalandırıcı kalırsın"),
    ("Escalate the tone to teach a lesson", "Ders vermek için tonu yükseltirsin"),
    ("Refuse repair until they fully admit fault", "Tam suç kabul edene kadar onarımı reddedersin"),
    ("Use guilt to force a quicker apology", "Daha hızlı özür için suçluluk yükü bindirirsin"),
    ("Dismiss their feelings as oversensitivity", "Duygularını aşırı hassasiyet diye geçiştirirsin"),
    ("Keep score out loud during the talk", "Konuşurken puan tablosunu açıkça tutarsın"),
    ("Threaten distance if they don't change tonight", "Bu gece değişmezlerse mesafe koyacağını ima edersin"),
    ("Interrupt them back with a sharper edge", "Daha keskin bir dille karşı kesersin"),
    ("Tell them to stop needing reassurance", "Güvence aramayı bırakmalarını söylersin"),
    ("Turn their vulnerability into a joke at their expense", "Kırılganlıklarını onların aleyhine şakaya çevirirsin"),
    ("Respond like a lecture instead of a conversation", "Sohbet yerine ders verir gibi yanıt verirsin"),
]

IMPULSIVE = [
    ("Match their anxiety with rapid-fire replies", "Kaygılarına peş peşe hızlı yanıtlarla karşılık verirsin"),
    ("Cut back in immediately to reclaim the floor", "Sözü geri almak için hemen araya girersin"),
    ("Assume the worst and pull away within minutes", "En kötüsünü düşünüp dakikalar içinde geri çekilirsin"),
    ("Send a dramatic message before hearing the full story", "Tüm hikâyeyi dinlemeden dramatik bir mesaj atarsın"),
    ("Flip to dating apps to \"balance the energy\"", "\"Enerjiyi dengelemek\" için flört uygulamalarına dönersin"),
    ("Call repeatedly until they pick up", "Açana kadar aramaya devam edersin"),
    ("Post a vague story aimed at them", "Onlara ima eden belirsiz bir hikâye atarsın"),
    ("Cancel everything and go offline in anger", "Öfkeyle her şeyi iptal edip çevrim dışı kalırsın"),
    ("Make a backup plan with someone else right away", "Hemen başka biriyle yedek plan yaparsın"),
    ("Demand an instant yes-or-no answer", "Anında evet-hayır cevabı zorlarsın"),
    ("Show up unannounced to force clarity", "Netlik zorlamak için haber vermeden çıkarsın"),
    ("Send a breakup-style text over a small miss", "Küçük bir aksilikte ayrılık gibi mesaj yazarsın"),
    ("Vent to mutual friends before talking to them", "Onlarla konuşmadan ortak arkadaşlara dert yanarsın"),
    ("Escalate with an ultimatum in the same chat", "Aynı sohbette ultimatomla yükseltirsin"),
    ("Buy a big gesture to force closeness back", "Yakınlığı zorlamak için büyük bir jest yaparsın"),
    ("Reply with anger, then regret it five minutes later", "Öfkeyle yanıtlar, beş dakika sonra pişman olursun"),
    ("Block them before they can explain", "Açıklamadan önce engellersin"),
    ("Jump to defining the relationship mid-conflict", "Çatışmanın ortasında ilişkiyi tanımlamaya atlarsın"),
    ("Invite someone else to replace the plan instantly", "Planın yerine anında başkasını davet edersin"),
    ("Send a voice rant and disappear", "Öfkeli sesli not atıp kaybolursun"),
    ("Assume silence means betrayal and accuse them", "Sessizliği ihanet sanıp suçlarsın"),
    ("Force a late-night hard talk without consent", "Onaysız gece geç zor bir konuşma açarsın"),
    ("Double-text ten times to close the gap", "Boşluğu kapatmak için on kez peş peşe yazarsın"),
    ("Quit the shared plan and ghost the group", "Ortak plandan çekilip grupta kaybolursun"),
    ("React first, listen later—if at all", "Önce tepki verir, dinlemeyi sonraya bırakırsın"),
]

DEFENSIVE = [
    ("Assume they're hiding something serious", "Ciddi bir şey sakladıklarını varsayarsın"),
    ("Make the moment about your own news instead", "Anı kendi haberine çevirirsin"),
    ("Take it as rejection and close off", "Ret gibi algılayıp kapanırsın"),
    ("Read their honesty as an attack on you", "Dürüstlüklerini sana saldırı sanırsın"),
    ("Deflect with humor before they finish", "Bitirmeden şakayla savuşturursun"),
    ("Bring up your own hurt to cancel theirs", "Onların incinmesini geçersiz kılmak için kendi yaranı öne çıkarırsın"),
    ("Assume they're comparing you to someone better", "Seni daha iyisiyle kıyasladıklarını düşünürsün"),
    ("Say they're too sensitive and drop it", "Aşırı hassas olduklarını söyleyip konuyu kapatırsın"),
    ("Interpret space as proof they lost interest", "Alan istemeyi ilginin bittiği kanıtı sayarsın"),
    ("Get sarcastic because you feel exposed", "Savunmasız hissettiğin için alaycı olursun"),
    ("Ask trap questions instead of listening", "Dinlemek yerine köşeye sıkıştıran sorular sorarsın"),
    ("Focus on being right more than being clear", "Netleşmekten çok haklı olmaya odaklanırsın"),
    ("Assume bad intent behind a small comment", "Küçük bir yorumun arkasında kötü niyet ararsın"),
    ("Withdraw affection to test if they'll chase", "Kovalayıp kovalamadıklarını test etmek için ilgini çekersin"),
    ("Mention how hard you try whenever challenged", "Sorgulandığında ne kadar çabaladığını hatırlatırsın"),
    ("Turn their concern into criticism of your character", "Endişelerini karakterine yönelik eleştiriye çevirirsin"),
    ("Say you'll leave before they can hurt you", "Seni incitmeden önce gideceğini söylersin"),
    ("Replay worst-case stories and react to those", "En kötü senaryoları canlandırıp onlara tepki verirsin"),
    ("Dismiss their feelings because yours feel bigger", "Seninkiler daha büyük geldiği için onlarınkini küçümsersin"),
    ("Ask why you're never enough in the moment", "O anda neden asla yeterli olmadığını sorarsın"),
    ("Use past hurt to avoid the current talk", "Şimdiki konuşmadan kaçmak için eski yaraları kullanırsın"),
    ("Treat their boundary like personal rejection", "Sınırlarını kişisel ret gibi yaşarsın"),
    ("Change the subject to protect your ego", "Egonu korumak için konuyu değiştirirsin"),
    ("Assume they're ashamed of being with you", "Seninle birlikte olmaktan utandıklarını varsayarsın"),
    ("Compare them to an ex to regain control", "Kontrolü geri almak için eski sevgilinle kıyaslarsın"),
]

PUSHY = [
    ("Push harder until they explain everything tonight", "Bu gece her şeyi anlatana kadar baskıyı artırırsın"),
    ("Demand a firm answer before the conversation ends", "Konuşma bitmeden kesin cevap zorlarsın"),
    ("Insist on defining things immediately", "Hemen her şeyi tanımlamakta ısrar edersin"),
    ("Keep pressing after they ask for time", "Zaman istedikten sonra baskılamaya devam edersin"),
    ("Force a public label before trust is ready", "Güven hazır olmadan açık bir tanım zorlarsın"),
    ("Corner them with \"we need to talk\" right now", "Hemen \"konuşmamız lazım\" diye sıkıştırırsın"),
    ("Push for a meet-the-friends plan on the spot", "O anda arkadaşlarla tanışma planını zorlarsın"),
    ("Repeat the same question until they give in", "Pes edene kadar aynı soruyu tekrarlarsın"),
    ("Demand they cancel other plans for you tonight", "Bu gece diğer planları senin için iptal etmelerini istersin"),
    ("Escalate commitment talk during a fragile moment", "Kırılgan bir anda bağlılık konuşmasını yükseltirsin"),
    ("Insist they choose sides in your conflict", "Çatışmanda taraf seçmelerini zorlarsın"),
    ("Keep calling after they asked for space", "Alan istedikten sonra aramaya devam edersin"),
    ("Push intimacy faster than the pace allows", "Temponun izin verdiğinden hızlı yakınlık zorlarsın"),
    ("Lock every weekend in one intense chat", "Tek yoğun sohbette tüm hafta sonlarını kilitlemeye çalışırsın"),
    ("Ask for exclusivity mid-argument", "Tartışmanın ortasında özel olmayı talep edersin"),
    ("Show up to their plans to force a conversation", "Konuşmayı zorlamak için planlarına çıkarsın"),
    ("Demand detailed answers on the spot", "O anda ayrıntılı cevaplar istersin"),
    ("Raise the stakes whenever they hesitate", "Tereddüt ettikçe bahsi yükseltirsin"),
    ("Insist on meeting family immediately", "Hemen aileyle tanışmayı ısrarla istersin"),
    ("Force a hard talk without checking timing", "Zamanlamayı sormadan zor konuşma açarsın"),
    ("Push them to post about you online tonight", "Bu gece senin hakkında paylaşım yapmalarını zorlarsın"),
    ("Keep inviting until refusal feels impossible", "Reddetmek imkânsız hissettirene kadar davet edersin"),
    ("Demand they prove care with immediate action", "İlgiyi hemen eylemle kanıtlamalarını istersin"),
    ("Turn every soft no into a negotiation", "Her yumuşak hayırı pazarlığa çevirirsin"),
    ("Pressure them to reopen a closed topic now", "Kapanmış konuyu şimdi açmaları için baskı yaparsın"),
]

POOLS = {
    "secure": SECURE,
    "passive": PASSIVE,
    "overthink": OVERTHINK,
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
            "acknowledge the dodge",
            "reassure proportionately",
            "mirror enthusiasm",
            "pause and invite",
        ]
    ):
        return "secure"
    if "push harder until" in t:
        return "pushy"
    if "hiding something serious" in t or "make it about your own news" in t:
        return "defensive"
    if "ten follow-up" in t:
        return "overthink"
    if "match anxiety" in t or "interrupt back" in t:
        return "impulsive"
    if any(
        k in t
        for k in [
            "ignore the extra",
            "downplay so",
            "shut down and stop",
        ]
    ):
        return "passive"
    if any(
        k in t
        for k in [
            "calm down and stop apologizing",
            "tease them for caring",
            "correct them sharply",
        ]
    ):
        return "punitive"
    raise ValueError(f"Unclassified option: {opt}")


def pick(pool: list[tuple[str, str]], idx: int) -> tuple[str, str]:
    return pool[idx % len(pool)]


def main() -> None:
    scenarios = {
        row["id"]: row for row in json.loads(SCENARIOS_PATH.read_text(encoding="utf-8"))
    }
    data = json.loads(EQ_PATH.read_text(encoding="utf-8"))
    q_counter = 0

    for s in data["sets"]:
        if not re.match(r"^eq_set_01[1-9]$|^eq_set_020$", s["id"]):
            continue
        for q in s["questions"]:
            qid = q["id"]
            if qid not in scenarios:
                raise KeyError(f"Missing scenario for {qid}")
            sc = scenarios[qid]
            q["question"]["en"] = sc["en"]
            q["question"]["tr"] = sc["tr"]

            styles = [classify(o["label"]["en"]) for o in q["options"]]
            if styles[q["correctAnswer"]] != "secure":
                raise AssertionError(
                    f"{qid}: correctAnswer {q['correctAnswer']} is not secure ({styles})"
                )
            for i, style in enumerate(styles):
                en, tr = pick(POOLS[style], q_counter * 4 + i)
                q["options"][i]["label"]["en"] = en
                q["options"][i]["label"]["tr"] = tr
            q_counter += 1

    EQ_PATH.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Rewrote batch 2: {q_counter} questions in eq_sets.json")


if __name__ == "__main__":
    main()
