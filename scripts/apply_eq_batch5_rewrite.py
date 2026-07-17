#!/usr/bin/env python3
"""Apply Phase 3L-A5 EQ content rewrite to eq_set_041..050.

Changes only question.en/tr and option label en/tr.
Preserves IDs, correctAnswer, difficulty, option order/count.
Option pools emphasize plausible, distinct response styles
and avoid audit-flagged secure phrasing (acknowledge, stay curious,
ask what would help, name what you noticed) and caricature distractors
(withdraw affection, teach them a lesson).
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EQ_PATH = ROOT / "assets" / "data" / "assessment_sets" / "eq_sets.json"
SCENARIOS_PATH = ROOT / "scripts" / "eq_batch5_scenarios.json"

# Emotionally mature, human, not therapy-template
SECURE = [
    ("Say what felt uneven and ask how they see it", "Ters gelen şeyi söyleyip onların nasıl gördüğünü sorarsın"),
    ("Keep your tone soft and state what you need next", "Tonunu yumuşak tutup bundan sonra neye ihtiyacın olduğunu söylersin"),
    ("Give them room, then suggest one concrete follow-up", "Alan bırakıp somut bir takip önerirsin"),
    ("Own your reaction briefly and invite their side", "Tepkini kısa sahiplenip onların tarafını dinlersin"),
    ("Hold the boundary kindly and stay open to timing", "Sınırı nazikçe korur, zamanlamaya açık kalırsın"),
    ("Slow down and check the story you're telling yourself", "Yavaşlayıp kendine anlattığın hikâyeyi kontrol edersin"),
    ("Share impact without turning it into a verdict", "Yargıya çevirmeden etkiyi paylaşırsın"),
    ("Ask one clear question, then wait for a real answer", "Tek net soru sorar, gerçek yanıt için beklersin"),
    ("Offer a simpler pace that still feels connected", "Bağlı hissedecek daha sade bir tempo önerirsin"),
    ("Stay steady and name the mismatch without blame", "Dengede kalıp uyumsuzluğu suçlamadan söylersin"),
    ("Make space for their feeling before problem-solving", "Çözüme atlamadan duygularına alan açarsın"),
    ("Keep it private and talk about what would feel fair", "Konuyu özel tutup neyin adil geleceğini konuşursun"),
    ("Separate the moment from their worth, then reset", "Anı değerlerinden ayırıp yeniden ayarlarsınız"),
    ("Be honest about capacity and keep the door open", "Kapasiten hakkında dürüst olup kapıyı açık bırakırsın"),
    ("Invite a reset without forcing an instant fix", "Anında çözüm dayatmadan toparlanmaya davet edersin"),
    ("Reflect what you heard, then confirm a small next step", "Duyduğunu yansıtıp küçük bir sonraki adımı netleştirirsin"),
    ("Stay warm while being clear about your limit", "Sınırında net kalırken sıcaklığını korursun"),
    ("Ask if now is okay, then share your concern briefly", "Şimdi uygun mu diye sorup endişeni kısa paylaşırsın"),
    ("Choose clarity over guessing and say so simply", "Tahmin yerine netliği seçip bunu sade söylersin"),
    ("Protect the connection and still tell the truth", "Bağlantıyı korurken gerçeği yine de söylersin"),
    ("Suggest a pause that helps both of you return calmer", "İkinizin de sakin döneceği bir ara önerirsin"),
    ("Keep score out of it and talk about the pattern once", "Puan tutmadan kalıbı bir kez konuşursun"),
    ("Meet them halfway on timing, not on self-respect", "Zamanlamada ortayı bulursun, özsaygıda değil"),
    ("Ask about intent without dropping what you need", "İhtiyacını bırakmadan niyeti sorarsın"),
    ("Lead with care, then ask what repair looks like", "Önce özen gösterir, onarımın neye benzediğini sorarsın"),
]

# Control-seeking / demand proof
CONTROL = [
    ("Push for total access so you can feel safer", "Daha güvende hissetmek için tam erişim dayatırsın"),
    ("Ask for proof before you'll keep engaging", "İlgilenmeden önce kanıt istersin"),
    ("Demand constant updates to quiet your worry", "Endişeni yatıştırmak için sürekli güncelleme istersin"),
    ("Turn reassurance into a checklist they must pass", "Güvenceyi geçmeleri gereken bir listeye çevirirsin"),
    ("Monitor their activity instead of asking directly", "Doğrudan sormak yerine hareketlerini izlersin"),
    ("Require a full explanation before you soften", "Yumuşamadan önce tam açıklama şart koşarsın"),
    ("Make trust conditional on total transparency now", "Güveni şimdi tam şeffaflığa bağlarsın"),
    ("Insist on seeing messages to settle your mind", "İçini rahatlatmak için mesajları görmekte ısrar edersin"),
    ("Ask them to report plans in advance every time", "Her seferinde planları önceden bildirmelerini istersin"),
    ("Use questions like a cross-examination", "Soruları sorgu gibi kullanırsın"),
    ("Hold connection until they prove loyalty first", "Önce sadakat kanıtlayana kadar bağı askıda tutarsın"),
    ("Push for passwords disguised as \"just honesty\"", "\"Dürüstlük\" diye şifre baskısı yaparsın"),
    ("Need real-time location to feel okay", "Tamam hissetmek için anlık konum istersin"),
    ("Treat ambiguity as something you must police", "Belirsizliği denetlemen gereken bir şey gibi görürsün"),
    ("Ask mutual friends to confirm their story", "Hikâyelerini doğrulatmak için ortak arkadaşlara sorarsın"),
    ("Make every soft answer feel like not enough", "Her yumuşak yanıtı yetersiz hissettirirsin"),
    ("Escalate from curiosity into surveillance", "Meraktan gözetime yükseltirsin"),
    ("Require a public gesture to feel secure", "Güvende hissetmek için herkese açık bir jest istersin"),
    ("Frame control as care and push harder", "Kontrolü özen diye sunup daha çok baskılarsın"),
    ("Keep digging until they feel cornered", "Köşeye sıkışana kadar kazmaya devam edersin"),
    ("Refuse calm talk until you get total certainty", "Tam kesinliğe ulaşmadan sakin konuşmayı reddedersin"),
    ("Ask them to cut contacts to prove seriousness", "Ciddiyeti kanıtlamak için bağları kesmelerini istersin"),
    ("Need screenshots before you'll move on", "Geçmeden önce ekran görüntüsü istersin"),
    ("Turn one worry into a full loyalty audit", "Tek endişeyi tam bir sadakat denetimine çevirirsin"),
    ("Stay unsettled until they hand over control", "Kontrolü bırakana kadar rahatsız kalırsın"),
]

# Impulsive escalation
IMPULSIVE = [
    ("Hit back publicly before talking privately", "Özel konuşmadan herkese açık karşılık verirsin"),
    ("Match the moment with a louder reaction", "Ana daha yüksek sesli bir tepkiyle karşılık verirsin"),
    ("Send a string of intense messages at once", "Bir anda peş peşe yoğun mesajlar atarsın"),
    ("Flip it into an ultimatum on the spot", "Orada hemen ultimatomla çevirirsin"),
    ("Walk out mid-conversation to make a point", "Noktayı koymak için konuşmanın ortasında çıkarsın"),
    ("Post something vague aimed at them", "Onlara yönelik belirsiz bir şey paylaşırsın"),
    ("Raise the stakes before you understand them", "Anlamadan bahsi yükseltirsin"),
    ("Cancel everything in a sharp snap decision", "Sert bir kararla her şeyi iptal edersin"),
    ("Invite others into the conflict immediately", "Çatışmaya hemen başkalarını katarsın"),
    ("One-up the moment instead of slowing it", "Yavaşlatmak yerine anı bastırarak geçersin"),
    ("Turn competition into the whole night", "Rekabeti tüm gecenin konusu yaparsın"),
    ("Show up unannounced to force a reset", "Sıfırlamayı zorlamak için habersiz gelirsin"),
    ("Reply from heat and sort nuance later", "Öfkeyle yanıtlar, nüansı sonraya bırakırsın"),
    ("Make a dramatic gesture to regain control", "Kontrolü almak için dramatik bir jest yaparsın"),
    ("Push for a hard talk at the worst time", "En kötü zamanda zor konuşmayı zorlarsın"),
    ("Assume the worst and act on it instantly", "En kötüyü varsayıp hemen ona göre hareket edersin"),
    ("Fire a pointed joke into the group chat", "Grup sohbetine iğneli bir şaka atarsın"),
    ("Quit the plan abruptly with no reset", "Yeniden ayarlamadan planı aniden bırakırsın"),
    ("Double down when things get uncomfortable", "İşler rahatsız olunca üzerine gidersin"),
    ("Call repeatedly until they pick up", "Açana kadar aramaya devam edersin"),
    ("Turn a small miss into a loyalty test", "Küçük aksiliği sadakat testine çevirirsin"),
    ("Escalate tone to win the exchange", "Alışverişi kazanmak için tonu yükseltirsin"),
    ("Rewrite the night around proving a point", "Geceyi bir noktayı kanıtlamaya çevirirsin"),
    ("React first and leave little room to hear them", "Önce tepki verir, dinlemeye az alan bırakırsın"),
    ("Compete harder the next chance you get", "Bir sonraki fırsatta daha sert rekabet edersin"),
]

# Defensive interpretation
DEFENSIVE = [
    ("Assume the worst motive without asking", "Sormadan en kötü niyeti varsayarsın"),
    ("Hear concern as an attack on your character", "Endişeyi karakterine saldırı gibi duyarsın"),
    ("Decide they're hiding something and shut down", "Bir şey sakladıklarına karar verip kapanırsın"),
    ("Make it about your insecurity right away", "Hemen kendi güvensizliğine çevirirsin"),
    ("Treat a fair question as proof of distrust", "Adil soruyu güvensizlik kanıtı sayarsın"),
    ("Skip the talk and fill in a darker story", "Konuşmayı atlayıp daha karanlık bir hikâye uydurursun"),
    ("Say they're too sensitive and close it", "Aşırı hassas olduklarını söyleyip kapatırsın"),
    ("Focus on being right more than being clear", "Netleşmekten çok haklı olmaya odaklanırsın"),
    ("Read their need for space as rejection", "Alan ihtiyaçlarını ret gibi yorumlarsın"),
    ("Bring up your effort to cancel their feeling", "Duygularını silmek için kendi emeğini öne çıkarırsın"),
    ("Assume comparison even when none was named", "Adı geçmese de kıyaslandığını varsayarsın"),
    ("Get sharp because you feel exposed", "Savunmasız hissettiğin için sertleşirsin"),
    ("Deny the impact before considering it", "Düşünmeden önce etkiyi inkâr edersin"),
    ("Act unbothered while feeling deeply threatened", "Derinden tehdit hissederken umursamaz görünürsün"),
    ("Frame their boundary as a personal slight", "Sınırlarını kişisel hakaret gibi yaşarsın"),
    ("Interpret honesty as them pulling away", "Dürüstlüğü uzaklaşma olarak yorumlarsın"),
    ("Keep score of past hurts while they talk", "Onlar konuşurken geçmiş kırgınlıkları sayarsın"),
    ("Protect your ego by changing the subject", "Egonu korumak için konuyu değiştirirsin"),
    ("Hear a request for clarity as criticism", "Netlik isteğini eleştiri gibi duyarsın"),
    ("Say \"that's not what I meant\" and stop listening", "\"Öyle demek istemedim\" deyip dinlemeyi bırakırsın"),
    ("Treat curiosity as control", "Merakı kontrol gibi algılarsın"),
    ("Assume they're ashamed of being with you", "Seninle birlikte olmaktan utandıklarını varsayarsın"),
    ("Turn feedback into a verdict on your worth", "Geri bildirimi değerine dair hükme çevirirsin"),
    ("Decide the relationship is failing mid-sentence", "Cümlenin ortasında ilişkinin bittiğine karar verirsin"),
    ("Default to \"they're cheating\" without dialogue", "Diyalog olmadan \"aldatıyorlar\"a kayarsın"),
]

# Anxious chase / over-reassurance
ANXIOUS = [
    ("Chase reassurance until the moment feels empty", "An boşalana kadar güvence peşinde koşarsın"),
    ("Over-explain yourself in a long message thread", "Uzun bir mesaj zincirinde kendini fazla açıklarsın"),
    ("Ask the same question in three different ways", "Aynı soruyu üç farklı şekilde sorarsın"),
    ("Seek comfort harder when they need distance", "Onlar mesafe isterken daha çok teselli ararsın"),
    ("Send follow-ups before they've had time to answer", "Yanıtlamaya vakit bulmadan takip mesajı atarsın"),
    ("Offer extra care to buy back certainty", "Kesinliği geri almak için fazla özen gösterirsin"),
    ("Apologize for things that aren't yours to fix", "Senin düzeltmen gerekmeyen şeyler için özür dilersin"),
    ("Keep checking if they're still okay with you", "Hâlâ senden memnunlar mı diye yoklamaya devam edersin"),
    ("Fill silence with anxious humor and oversharing", "Sessizliği kaygılı şaka ve fazla paylaşımla doldurursun"),
    ("Ask friends to decode what the silence means", "Sessizliğin ne demek olduğunu arkadaşlara çözdürürsün"),
    ("Agree to anything if it keeps them close tonight", "Bu gece yakın tutacaksa her şeye razı olursun"),
    ("Turn one delayed reply into a spiral of texts", "Geciken bir yanıtı mesaj sarmalına çevirirsin"),
    ("Need an immediate emotional reset from them", "Onlardan anında duygusal toparlanma beklersin"),
    ("Trade your boundary for a little warmth", "Biraz sıcaklık için sınırını takas edersin"),
    ("Replay the chat looking for hidden meaning", "Gizli anlam aramak için sohbeti tekrar tekrar okursun"),
    ("Ask for a promise that calms you for an hour", "Seni bir saatliğine sakinleştiren bir söz istersin"),
    ("Offer more of yourself hoping they'll match it", "Onlar da eşleşsin diye daha fazla verirsin"),
    ("Stay available 24/7 so they won't drift", "Uzaklaşmasınlar diye her an müsait kalırsın"),
    ("Fish for compliments after feeling unsure", "Emin olamayınca iltifat avlarsın"),
    ("Convert worry into rapid problem-solving talk", "Endişeyi hızlı sorun çözme konuşmasına çevirirsin"),
    ("Need them to regulate you before you can rest", "Dinlenmeden önce onlar seni dengelemiş olsun istersin"),
    ("Say you're fine while pushing for more contact", "İyiyim deyip daha fazla iletişim için baskılarsın"),
    ("Soft-pedal your needs, then feel unseen", "İhtiyaçlarını yumuşatıp sonra görülmediğini hissedersin"),
    ("Keep the chat alive at any emotional cost", "Duygusal bedeli ne olursa olsun sohbeti canlı tutarsın"),
    ("Ask for certainty they can't honestly give yet", "Henüz dürüstçe veremeyecekleri kesinliği istersin"),
]

# Punitive / icy control
PUNITIVE = [
    ("Go cold to make them feel the cost", "Bedeli hissettirmek için soğuklaşırsın"),
    ("Answer with \"whatever\" and shut down", "\"Neyse\" deyip kapanırsın"),
    ("Withhold warmth until they do it your way", "Senin istediğin gibi yapana kadar sıcaklığını kesersin"),
    ("Use silence as leverage after they open up", "Açıldıktan sonra sessizliği koz olarak kullanırsın"),
    ("Punish distance by becoming unreachable", "Mesafeyi ulaşılamaz olarak cezalandırırsın"),
    ("Keep bringing up past misses to win now", "Şimdi kazanmak için eski aksilikleri gündeme getirirsin"),
    ("Make them chase basic kindness from you", "Senden temel nezaket için kovalamalarını sağlarsın"),
    ("Reply curtly to teach them not to ask again", "Bir daha sormasınlar diye kısa ve sert yanıt verirsin"),
    ("Raise the stakes whenever they hesitate", "Tereddüt ettikçe bahsi yükseltirsin"),
    ("Shame the ask instead of negotiating it", "Pazarlık etmek yerine isteği utandırarak karşılarısın"),
    ("Hold the apology hostage until they fold", "Boyun eğene kadar özrü rehin alırsın"),
    ("Mock the insecurity lightly so they stop", "Durmaları için güvensizliği hafifçe alaya alırsın"),
    ("Respond like they failed a secret test", "Gizli bir testte başarısız olmuş gibi karşılık verirsin"),
    ("Refuse softness until they drop the topic", "Konuyu bırakana kadar yumuşaklığı reddedersin"),
    ("Keep them guessing to regain a sense of power", "Gücü geri almak için onları belirsizlikte bırakırsın"),
    ("Match \"I'm fine\" with an even colder vibe", "\"İyiyim\"e daha soğuk bir hava ile karşılık verirsin"),
    ("Turn repair into a lecture about how they should be", "Onarımı nasıl olmaları gerektiğine dair derse çevirirsin"),
    ("Make kindness conditional on them being easier", "Nezaketi \"daha kolay\" olmaları şartına bağlarsın"),
    ("Bring others in to pressure the outcome", "Sonucu baskılamak için başkalarını dahil edersin"),
    ("Stay closed after they try to reconnect", "Yeniden bağlanmaya çalışınca kapalı kalırsın"),
    ("Score the night as a win/lose contest", "Geceyi kazanma/kaybetme yarışına çevirirsin"),
    ("Answer care with indifference on purpose", "Özeni bilerek kayıtsızlıkla karşılarısın"),
    ("Use guilt to get the plan you wanted", "İstediğin plan için suçluluk yükü bindirirsin"),
    ("Correct them harshly for needing reassurance", "Güvence ihtiyaçları için sertçe düzeltirsin"),
    ("Make the next day colder without explanation", "Açıklama olmadan ertesi günü daha soğuk tutarsın"),
]

# Evidence-listing / overthink pressure
OVERTHINK = [
    ("List every detail until they concede your read", "Senin okumana boyun eğene kadar her ayrıntıyı sıralarsın"),
    ("Build a case instead of asking one open question", "Tek açık soru sormak yerine dosya hazırlarsın"),
    ("Stack examples until the talk feels like a trial", "Konuşma mahkemeye dönene kadar örnek yığarsın"),
    ("Over-analyze tone, timing, and word choice aloud", "Ton, zamanlama ve kelime seçimini sesli aşırı analiz edersin"),
    ("Bring receipts into a moment that needs softness", "Yumuşaklık gereken ana kanıtları getirirsin"),
    ("Narrate their patterns before they can respond", "Yanıtlamadan önce kalıplarını anlatırsın"),
    ("Turn curiosity into a closing argument", "Merakı kapanış konuşmasına çevirirsin"),
    ("Keep collecting proof while skipping repair", "Onarımı atlayıp kanıt toplamaya devam edersin"),
    ("Make them defend against your full theory", "Tam teorine karşı savunma yaptırırsın"),
    ("Quote old chats to win the current feeling", "Şimdiki duyguyu kazanmak için eski sohbetleri alıntılarsın"),
    ("Ask rapid-fire questions that leave no air", "Nefes bırakmayan peş peşe sorular sorarsın"),
    ("Present your conclusion as already settled", "Sonucunu çoktan kesinleşmiş gibi sunarsın"),
    ("Map motives they never stated", "Hiç söylemedikleri niyetleri haritalarsın"),
    ("Force a debate when a check-in would do", "Yoklama yeterken tartışma zorlarsın"),
    ("Keep score of inconsistencies in real time", "Tutarsızlıkları anında puanlarsın"),
    ("Need a perfect explanation before you soften", "Yumuşamadan önce kusursuz açıklama beklersin"),
    ("Talk yourself into certainty, then push it on them", "Kendini kesinliğe ikna edip onu onlara dayatırsın"),
    ("Treat ambiguity like a puzzle you must solve tonight", "Belirsizliği bu gece çözmen gereken bulmaca gibi görürsün"),
    ("Interrupt to add more evidence mid-sentence", "Cümlenin ortasında kanıt eklemek için söz kesersin"),
    ("Make the conversation about being right", "Konuşmayı haklı olmak üzerine kurarsın"),
    ("Demand they admit your interpretation first", "Önce senin yorumunu kabul etmelerini istersin"),
    ("Over-prepare your points and miss their feeling", "Noktalarına aşırı hazırlanıp duygularını kaçırırsın"),
    ("Convert hurt into a forensic review", "Kırgınlığı adli bir incelemeye çevirirsin"),
    ("Keep circling details instead of naming your need", "İhtiyacını söylemek yerine ayrıntılarda dönersin"),
    ("Push for a verdict when you really want comfort", "Aslında teselli isterken hüküm dayatırsın"),
]

# Pushy force-admit
PUSHY = [
    ("Force them to admit they're upset right now", "Şu anda üzgün olduklarını itiraf ettirirsin"),
    ("Corner them into a yes-or-no before listening", "Dinlemeden evet-hayır köşesine sıkıştırırsın"),
    ("Pressure a confession instead of inviting honesty", "Dürüstlüğe davet yerine itiraf baskısı yaparsın"),
    ("Refuse to move on until they name your read", "Senin okumanı söyleyene kadar ilerlemeyi reddedersin"),
    ("Push for emotional disclosure on your timeline", "Duygusal açılmayı senin takvimine göre zorlarsın"),
    ("Treat hesitation as guilt and press harder", "Tereddüdü suçluluk sayıp daha baskılarsın"),
    ("Demand they \"just say it\" in the middle of stress", "Stresin ortasında \"sadece söyle\" diye dayatırsın"),
    ("Make the room tense until they crack open", "Açılana kadar ortamı gergin tutarsın"),
    ("Skip consent and dig for what they feel", "İzni atlayıp ne hissettiklerini deşersin"),
    ("Insist on a deep talk when they asked for space", "Alan istediklerinde derin konuşmada ısrar edersin"),
    ("Keep probing after they said they're not ready", "Hazır değilim dedikten sonra yoklamaya devam edersin"),
    ("Turn \"later\" into an argument about avoidance", "\"Sonra\"yı kaçınma tartışmasına çevirirsin"),
    ("Require emotional labor before you'll calm down", "Sakinleşmeden önce duygusal emek şart koşarsın"),
    ("Push for labels to settle your nerves tonight", "Bu gece sinirlerini yatıştırmak için etiket dayatırsın"),
    ("Make silence feel unsafe until they talk", "Konuşana kadar sessizliği güvensiz hissettirirsin"),
    ("Ask for feelings as proof, not connection", "Bağlantı için değil kanıt için duygu istersin"),
    ("Refuse softness until they confirm your story", "Hikâyeni doğrulayana kadar yumuşaklığı reddedersin"),
    ("Interrogate the \"I'm fine\" until it breaks", "\"İyiyim\"i kırılana kadar sorgularsın"),
    ("Crow them into clarity instead of inviting it", "Netliği davet etmek yerine sıkıştırarak alırsın"),
    ("Set a deadline for emotional honesty", "Duygusal dürüstlüğe süre koyarsın"),
    ("Treat privacy as obstruction and push through", "Mahremiyeti engel sayıp zorla geçersin"),
    ("Need them to perform openness on cue", "Açıklığı komutla sergilemelerini beklersin"),
    ("Keep asking until the answer matches your fear", "Yanıt korkuna uyana kadar sormaya devam edersin"),
    ("Force a resolution before either of you is ready", "İkiniz de hazır değilken çözüm dayatırsın"),
    ("Make admission the price of staying close tonight", "Bu gece yakın kalmanın bedelini itiraf yaparsın"),
]

POOLS = {
    "secure": SECURE,
    "control": CONTROL,
    "impulsive": IMPULSIVE,
    "defensive": DEFENSIVE,
    "anxious": ANXIOUS,
    "punitive": PUNITIVE,
    "overthink": OVERTHINK,
    "pushy": PUSHY,
}


def classify(opt: str) -> str:
    t = opt.lower()
    if any(
        k in t
        for k in [
            "acknowledge discomfort",
            "support space and schedule",
            "name the pattern lightly",
            "name what you observe gently",
        ]
    ):
        return "secure"
    if "demand passwords" in t:
        return "control"
    if any(
        k in t
        for k in [
            "retaliate by liking",
            "show up uninvited",
            "one-up them harder",
            "escalate into a competition",
        ]
    ):
        return "impulsive"
    if "assume cheating" in t:
        return "defensive"
    if "chase them for constant reassurance" in t:
        return "anxious"
    if any(
        k in t
        for k in [
            "punish withdrawal with silence",
            "withdraw affection to win",
            "mirror their 'fine'",
            'mirror their "fine"',
        ]
    ):
        return "punitive"
    if "list evidence until they concede" in t:
        return "overthink"
    if "force them to admit" in t:
        return "pushy"
    raise ValueError(f"Unclassified option: {opt}")


def pick(pool: list[tuple[str, str]], idx: int) -> tuple[str, str]:
    return pool[idx % len(pool)]


_BANNED_SECURE = re.compile(
    r"acknowledge|stay curious|check in kindly|ask what would help|name what you noticed",
    re.I,
)
_BANNED_DISTRACTOR = re.compile(
    r"withdraw affection|teach them a lesson|lecture them",
    re.I,
)


def main() -> None:
    scenarios = {
        row["id"]: row for row in json.loads(SCENARIOS_PATH.read_text(encoding="utf-8"))
    }
    data = json.loads(EQ_PATH.read_text(encoding="utf-8"))
    q_counter = 0

    for s in data["sets"]:
        if not re.match(r"^eq_set_04[1-9]$|^eq_set_050$", s["id"]):
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
                if len(tr) > 85 or len(en) > 80 or (
                    style == "secure" and _BANNED_SECURE.search(en)
                ) or (style != "secure" and _BANNED_DISTRACTOR.search(en)):
                    for offset in range(1, len(POOLS[style])):
                        en2, tr2 = pick(POOLS[style], q_counter * 4 + i + offset)
                        if len(tr2) <= 85 and len(en2) <= 80:
                            if style == "secure" and _BANNED_SECURE.search(en2):
                                continue
                            if style != "secure" and _BANNED_DISTRACTOR.search(en2):
                                continue
                            en, tr = en2, tr2
                            break
                if style == "secure" and _BANNED_SECURE.search(en):
                    raise AssertionError(f"{qid}: banned secure phrasing: {en}")
                if style != "secure" and _BANNED_DISTRACTOR.search(en):
                    raise AssertionError(f"{qid}: banned distractor phrasing: {en}")
                # avoid "stay curious" substring even in "Stay curious about intent..."
                # Wait - I have "Stay curious about intent" in SECURE - that triggers design audit!
                q["options"][i]["label"]["en"] = en
                q["options"][i]["label"]["tr"] = tr
            q_counter += 1

    EQ_PATH.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Rewrote batch 5: {q_counter} questions in eq_sets.json")


if __name__ == "__main__":
    main()
