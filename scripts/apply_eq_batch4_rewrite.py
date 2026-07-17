#!/usr/bin/env python3
"""Apply Phase 3L-A4 EQ content rewrite to eq_set_031..040.

Changes only question.en/tr and option label en/tr.
Preserves IDs, correctAnswer, difficulty, option order/count.
Option pools emphasize plausible, distinct response styles
(not cartoonishly bad distractors).
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EQ_PATH = ROOT / "assets" / "data" / "assessment_sets" / "eq_sets.json"
SCENARIOS_PATH = ROOT / "scripts" / "eq_batch4_scenarios.json"

# Emotionally mature without therapy-speak / moralizing
SECURE = [
    ("State your limit calmly and offer a workable alternative", "Sınırını sakince söyleyip uygulanabilir bir alternatif önerirsin"),
    ("Share what you appreciate and ask what would help them feel steadier", "Neyi değerli bulduğunu söyleyip neyin onları daha dengede tutacağını sorarsın"),
    ("Name the pressure and ask what version of the plan feels realistic", "Baskıyı adlandırıp planın hangi hâlinin gerçekçi geleceğini sorarsın"),
    ("Clarify what you meant and invite their read without defending first", "Ne demek istediğini netleştirip önce savunmadan onların yorumunu dinlersin"),
    ("Name what felt off and ask how to reset without blame", "Ters gelen şeyi söyleyip suçlamadan nasıl toparlanabileceğinizi sorarsın"),
    ("Stay grounded and ask one clear question about what they need", "Dengede kalıp neye ihtiyaç duyduklarını tek net soruyla sorarsın"),
    ("Own your part briefly, then ask how they experienced it", "Kendi payını kısa üstlenip onların nasıl yaşadığını sorarsın"),
    ("Suggest a pause that protects both of you, then revisit", "İkinizi de koruyan bir ara önerip sonra konuya dönersin"),
    ("Reflect what you heard and confirm the next small step together", "Duyduğunu yansıtıp birlikte küçük bir sonraki adımı netleştirirsin"),
    ("Keep your tone even and ask what would feel fair right now", "Tonunu dengeli tutup şu anda neyin adil geleceğini sorarsın"),
    ("Make room for their feeling before solving anything", "Her şeyi çözmeden önce duygularına alan açarsın"),
    ("Ask for clarity once, then give them space to answer", "Bir kez netlik ister, sonra yanıtlamaları için alan bırakırsın"),
    ("Hold your boundary and stay kind about the timing", "Sınırını korur ve zamanlama konusunda nazik kalırsın"),
    ("Check your assumption out loud before reacting", "Tepki vermeden önce varsayımını açıkça kontrol edersin"),
    ("Invite honesty and stay open to an answer you may not like", "Dürüstlüğe davet eder ve hoşuna gitmeyebilecek bir yanıta açık kalırsın"),
    ("Separate the issue from their worth and talk about the pattern", "Konuyu kişiliklerinden ayırıp kalıbı konuşursun"),
    ("Offer warmth without dropping what you need", "İhtiyacını bırakmadan sıcaklık gösterirsin"),
    ("Ask whether now is a good time, then share your concern briefly", "Şimdi uygun mu diye sorup endişeni kısa paylaşırsın"),
    ("Notice the gap between words and actions, then ask about it calmly", "Sözlerle davranışlar arasındaki boşluğu fark edip sakince sorarsın"),
    ("Propose a simpler plan that still respects both of you", "İkinize de saygı duyan daha sade bir plan önerirsin"),
    ("Name the disappointment and ask what repair looks like", "Hayal kırıklığını adlandırıp onarımın neye benzediğini sorarsın"),
    ("Keep the conversation private and focused on impact", "Konuşmayı özel tutup etkiye odaklanırsın"),
    ("Slow the moment down and ask what they meant", "Anı yavaşlatıp ne demek istediklerini sorarsın"),
    ("Share your capacity honestly and stay connected", "Kapasiteni dürüstçe paylaşır ve bağlantıda kalırsın"),
    ("Name the mismatch gently and look for a middle path", "Uyumsuzluğu yumuşakça söyler ve orta yolu ararsın"),
]

# Believable avoidant / people-pleasing withdrawal
PASSIVE = [
    ("Agree for now and sit with quiet resentment later", "Şimdilik kabul edip kırgınlığı sonraya bırakırsın"),
    ("Let it go and hope compliments will smooth it over", "Bırakır ve iltifatların düzelteceğini umarsın"),
    ("Avoid the topic and keep things light", "Konuyu kaçınır ve her şeyi hafif tutarsın"),
    ("Pull back for a few days without saying why", "Nedenini söylemeden birkaç gün geri çekilirsin"),
    ("Say it's fine even though it isn't", "Olmasa da tamam dersin"),
    ("Change the subject so nobody has to feel awkward", "Kimse rahatsız olmasın diye konuyu değiştirirsin"),
    ("Stay polite and emotionally unavailable", "Kibar kalır ama duygusal olarak uzaklaşırsın"),
    ("Wait for them to notice without bringing it up", "Açmadan onların fark etmesini beklersin"),
    ("Minimize your own needs to keep the peace", "Barışı korumak için kendi ihtiyaçlarını küçülürsün"),
    ("Give short answers until the moment passes", "An geçene kadar kısa yanıt verirsin"),
    ("Act busy so you don't have to respond fully", "Tam yanıt vermemek için meşgul görünürsün"),
    ("Smile through it and process alone later", "Gülümseyip sonra yalnız başına düşünürsün"),
    ("Accept the unclear plan and lower your expectations", "Belirsiz planı kabul edip beklentini düşürürsün"),
    ("Skip saying how it landed to avoid tension", "Gerginlik olmasın diye nasıl geldiğini söylemezsin"),
    ("Leave the chat and hope it resets itself", "Sohbetten çıkıp kendiliğinden düzelmesini beklersin"),
    ("Stay offline until the feeling cools", "His sönene kadar çevrim dışı kalırsın"),
    ("Nod along and save the real talk for never", "Başını sallar ve gerçek konuşmayı erteleyip unutursun"),
    ("Keep score silently without asking for change", "Değişim istemeden içten içe puan tutarsın"),
    ("Pretend you didn't notice the shift", "Değişimi fark etmemiş gibi yaparsın"),
    ("Offer a soft yes you don't mean", "İstemediğin yumuşak bir evet verirsin"),
    ("Avoid clarifying questions to stay comfortable", "Rahat kalmak için netleştirici sorulardan kaçınırsın"),
    ("Let them set the whole tone while you withdraw", "Sen geri çekilirken tonu tamamen onlara bırakırsın"),
    ("Stay agreeable and feel unseen afterward", "Uysal kalır ve sonra görülmediğini hissedersin"),
    ("Hope a better mood tomorrow will fix it", "Yarınki daha iyi ruh hâlinin düzelteceğini umarsın"),
    ("Choose silence over a short honest sentence", "Kısa dürüst bir cümle yerine sessizliği seçersin"),
]

# Believable impulsive escalation (not villainous)
IMPULSIVE = [
    ("Cancel your whole evening in a sharp reaction", "Sert bir tepkiyle tüm akşamını iptal edersin"),
    ("Take it personally and escalate the tone quickly", "Kişisel algılayıp tonu hızla yükseltirsin"),
    ("Escalate publicly before talking one-to-one", "Bire bir konuşmadan herkese açık şekilde yükseltirsin"),
    ("Send several intense messages before they can answer", "Yanıtlamadan peş peşe yoğun mesajlar atarsın"),
    ("Flip the conversation into an ultimatum", "Konuşmayı ultimatomla çevirirsin"),
    ("Walk away mid-talk and leave things hanging", "Konuşmanın ortasında uzaklaşıp her şeyi askıda bırakırsın"),
    ("Reply from anger and sort it out later—if at all", "Öfkeyle yanıtlar, düzeltmeyi sonraya bırakırsın"),
    ("Make a backup plan with someone else right away", "Hemen başka biriyle yedek plan yaparsın"),
    ("Demand an instant yes-or-no before listening fully", "Tam dinlemeden anında evet-hayır istersin"),
    ("Bring other people into it while emotions are high", "Duygular yüksekken başkalarını işin içine katarsın"),
    ("Post something vague that is clearly about them", "Açıkça onlarla ilgili belirsiz bir şey paylaşırsın"),
    ("Push for a hard talk at the worst possible time", "En kötü zamanda zor bir konuşmayı zorlarsın"),
    ("Match intensity with even more intensity", "Yoğunluğa daha fazla yoğunlukla karşılık verirsin"),
    ("Threaten distance before clarifying what happened", "Ne olduğunu netleştirmeden mesafe tehdidi yaparsın"),
    ("Over-correct with a dramatic gesture", "Dramatik bir jestle aşırı telafi edersin"),
    ("Call repeatedly until they pick up", "Açana kadar aramaya devam edersin"),
    ("Quit the plan abruptly without a reset", "Yeniden ayarlamadan planı aniden bırakırsın"),
    ("Assume the worst and act on that story", "En kötüyü varsayıp o hikâyeye göre hareket edersin"),
    ("Fire back with a pointed joke in the group", "Grupta iğneli bir şakayla karşılık verirsin"),
    ("Turn a small miss into a relationship test", "Küçük bir aksiliği ilişki testine çevirirsin"),
    ("Send a voice note rant before cooling off", "Sakinleşmeden önce öfkeli sesli not atarsın"),
    ("Force a public explanation in the moment", "O anda herkese açık bir açıklama zorlarsın"),
    ("Double down instead of slowing the moment", "Anı yavaşlatmak yerine üzerine gidersin"),
    ("Rewrite the night around proving a point", "Geceyi bir noktayı kanıtlamaya çevirirsin"),
    ("React first and leave little room for nuance", "Önce tepki verir ve nüansa az alan bırakırsın"),
]

# Believable defensive interpretation
DEFENSIVE = [
    ("Compare them to someone who \"handles it better\"", "Bunu \"daha iyi karşılayan\" biriyle kıyaslarsın"),
    ("Hear concern as an attack on your character", "Endişeyi karakterine saldırı gibi duyarsın"),
    ("Assume they're ashamed of being with you", "Seninle birlikte olmaktan utandıklarını varsayarsın"),
    ("Make it about your own insecurity right away", "Hemen kendi güvensizliğine çevirirsin"),
    ("Deflect with sarcasm before hearing them out", "Dinlemeden önce alayla savuşturursun"),
    ("Treat a fair ask as proof they don't trust you", "Adil bir isteği sana güvenmediklerinin kanıtı sayarsın"),
    ("Bring up your effort to cancel their feeling", "Onların duygusunu geçersiz kılmak için kendi emeğini öne çıkarırsın"),
    ("Read their need for space as rejection", "Alan ihtiyaçlarını ret gibi yorumlarsın"),
    ("Say they're too sensitive and close the topic", "Aşırı hassas olduklarını söyleyip konuyu kapatırsın"),
    ("Focus on being right more than being clear", "Netleşmekten çok haklı olmaya odaklanırsın"),
    ("Assume bad intent behind a small comment", "Küçük bir yorumun arkasında kötü niyet ararsın"),
    ("Turn their feedback into a critique of your worth", "Geri bildirimlerini değerine yönelik eleştiriye çevirirsin"),
    ("Ask why you're never enough in the moment", "O anda neden asla yeterli olmadığını sorarsın"),
    ("Protect your ego by changing the subject", "Egonu korumak için konuyu değiştirirsin"),
    ("Interpret honesty as them pulling away", "Dürüstlüğü uzaklaşma olarak yorumlarsın"),
    ("Keep score of past hurts while they talk", "Onlar konuşurken geçmiş kırgınlıkları sayarsın"),
    ("Act unbothered while feeling deeply threatened", "Derinden tehdit hissederken umursamaz görünürsün"),
    ("Frame their boundary as a personal slight", "Sınırlarını kişisel hakaret gibi yaşarsın"),
    ("Assume they're comparing you to someone else", "Seni başka biriyle kıyasladıklarını düşünürsün"),
    ("Get sharp because you feel exposed", "Savunmasız hissettiğin için sertleşirsin"),
    ("Deny the impact before considering it", "Düşünmeden önce etkiyi inkâr edersin"),
    ("Say \"that's not what I meant\" and stop listening", "\"Öyle demek istemedim\" deyip dinlemeyi bırakırsın"),
    ("Treat curiosity as control", "Merakı kontrol gibi algılarsın"),
    ("Hear a request for clarity as criticism", "Netlik isteğini eleştiri gibi duyarsın"),
    ("Withdraw affection to regain a sense of control", "Kontrol hissini geri almak için ilgini çekersin"),
]

# Believable punitive / control-seeking (not cartoon villain)
PUNITIVE = [
    ("Use guilt to get them to change their plans", "Planlarını değiştirmeleri için suçluluk yükü bindirirsin"),
    ("Tell them they're overreacting and shut it down", "Aşırı tepki verdiklerini söyleyip konuyu kapatırsın"),
    ("Insist they owe you the original plan anyway", "Orijinal plana borçlu olduklarını ısrarla söylersin"),
    ("Match their tone with sarcasm until they drop it", "Bırakana kadar aynı tona alayla karşılık verirsin"),
    ("Withhold warmth until they \"make it right\" your way", "Senin istediğin gibi \"düzeltene\" kadar sıcaklığını kesersin"),
    ("Call out their flaw in a sharp, public way", "Kusurlarını herkesin önünde sertçe yüzlerine vurursun"),
    ("Make them chase basic kindness from you", "Senden temel bir nezaket için kovalamalarını sağlarsın"),
    ("Reply coldly to teach them not to ask again", "Bir daha sormasınlar diye soğuk yanıt verirsin"),
    ("Keep bringing up past misses to win the moment", "Anı kazanmak için eski aksilikleri gündeme getirirsin"),
    ("Punish inconsistency by going colder yourself", "Tutarsızlığı kendin daha soğuk davranarak cezalandırırsın"),
    ("Tell them to toughen up instead of listening", "Dinlemek yerine daha dayanıklı olmalarını söylersin"),
    ("Use silence as leverage after they open up", "Açıldıktan sonra sessizliği koz olarak kullanırsın"),
    ("Correct them harshly for needing reassurance", "Güvence ihtiyaçları için sertçe düzeltirsin"),
    ("Turn the talk into a lecture about how they should act", "Konuşmayı nasıl davranmaları gerektiğine dair derse çevirirsin"),
    ("Hold the apology hostage until they fully fold", "Tamamen boyun eğene kadar özrü rehin alırsın"),
    ("Mock the insecurity lightly so they stop sharing", "Paylaşmayı bırakmaları için güvensizliği hafifçe alaya alırsın"),
    ("Demand they prove care before you'll engage", "İlgilenmeden önce ilgiyi kanıtlamalarını istersin"),
    ("Raise the stakes whenever they hesitate", "Tereddüt ettikçe bahsi yükseltirsin"),
    ("Answer with \"whatever\" and stay closed", "\"Neyse\" deyip kapalı kalırsın"),
    ("Make the repair conditional on them being \"easier\"", "Onarımı \"daha kolay\" olmaları şartına bağlarsın"),
    ("Keep them guessing as a way to regain power", "Gücü geri almak için onları belirsizlikte bırakırsın"),
    ("Shame the ask instead of negotiating it", "Pazarlık etmek yerine isteği utandırarak karşılarısın"),
    ("Bring other people in to pressure them", "Baskı için başkalarını devreye sokarsın"),
    ("Refuse softness until they drop the topic", "Konuyu bırakana kadar yumuşaklığı reddedersin"),
    ("Respond like they failed a test you never explained", "Hiç açıklamadığın bir testte başarısız olmuş gibi karşılık verirsin"),
]

POOLS = {
    "secure": SECURE,
    "passive": PASSIVE,
    "impulsive": IMPULSIVE,
    "defensive": DEFENSIVE,
    "punitive": PUNITIVE,
}


def classify(opt: str) -> str:
    t = opt.lower()
    if any(
        k in t
        for k in [
            "name your limit kindly",
            "affirm what you appreciate",
            "validate pressure",
            "clarify intent calmly",
        ]
    ):
        return "secure"
    if any(
        k in t
        for k in [
            "say yes anyway and resent",
            "ignore because compliments",
            "ignore the money",
            "cold-shoulder",
        ]
    ):
        return "passive"
    if any(
        k in t
        for k in [
            "cancel everything dramatically",
            "take their stress personally",
            "screenshot and escalate",
        ]
    ):
        return "impulsive"
    if "compare them to someone confident" in t:
        return "defensive"
    if any(
        k in t
        for k in [
            "guilt them into changing",
            "they're being dramatic",
            "insist they owe you",
            "mirror sarcasm",
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
        if not re.match(r"^eq_set_03[1-9]$|^eq_set_040$", s["id"]):
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
                # length soft-check
                if len(tr) > 85 or len(en) > 80:
                    # prefer shorter alternate from later in pool
                    for offset in range(1, len(POOLS[style])):
                        en2, tr2 = pick(POOLS[style], q_counter * 4 + i + offset)
                        if len(tr2) <= 85 and len(en2) <= 80:
                            en, tr = en2, tr2
                            break
                q["options"][i]["label"]["en"] = en
                q["options"][i]["label"]["tr"] = tr
            q_counter += 1

    EQ_PATH.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Rewrote batch 4: {q_counter} questions in eq_sets.json")


if __name__ == "__main__":
    main()
