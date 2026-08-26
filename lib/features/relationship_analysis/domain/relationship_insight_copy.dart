import 'relationship_insight_engine.dart';

class RelationshipInsightCopy {
  const RelationshipInsightCopy({
    required this.titleTr,
    required this.bodyTr,
    required this.titleEn,
    required this.bodyEn,
  });

  final String titleTr;
  final String bodyTr;
  final String titleEn;
  final String bodyEn;
}

class RelationshipInsightCopyResolver {
  const RelationshipInsightCopyResolver();

  RelationshipInsightCopy resolve(RelationshipInsight insight) {
    final key = '${insight.firstBand.name}_${insight.secondBand.name}';

    switch (insight.family) {
      case RelationshipInsightFamily.closenessAutonomy:
        return _closenessAutonomy[key]!;
      case RelationshipInsightFamily.reassuranceTrust:
        return _reassuranceTrust[key]!;
      case RelationshipInsightFamily.commitmentPace:
        return _commitmentPace[key]!;
      case RelationshipInsightFamily.affectionPlayfulness:
        return _affectionPlayfulness[key]!;
    }
  }

  static const _closenessAutonomy = <String, RelationshipInsightCopy>{
    'high_high': RelationshipInsightCopy(
      titleTr: 'Yakınlık ve özgürlük birlikte önemli',
      bodyTr:
          'Güçlü bir bağ kurmayı önemsiyor görünüyorsun; aynı zamanda ilişkide kişisel alanın ve bireyselliğin korunmasını da istiyorsun.',
      titleEn: 'Closeness and freedom both matter',
      bodyEn:
          'You seem to value a strong emotional bond while also wanting personal space and individuality to remain intact.',
    ),
    'high_balanced': RelationshipInsightCopy(
      titleTr: 'Yakınlığa doğal olarak yöneliyorsun',
      bodyTr:
          'Duygusal bağ senin için belirgin biçimde önemli görünüyor. Kişisel alan konusunda ise duruma ve ilişkiye göre esnek davranabiliyorsun.',
      titleEn: 'You naturally lean toward closeness',
      bodyEn:
          'Emotional connection appears especially important to you, while your need for personal space seems more flexible depending on the relationship.',
    ),
    'high_low': RelationshipInsightCopy(
      titleTr: 'Birliktelik hissi senin için güçlü',
      bodyTr:
          'İlişkide yakınlık ve ortaklık duygusuna güçlü biçimde değer veriyor, uzun süreli mesafeden çok birlikte hareket etmeyi tercih ediyor görünüyorsun.',
      titleEn: 'A strong sense of togetherness matters',
      bodyEn:
          'You appear to place strong value on closeness and shared connection, preferring togetherness over extended emotional distance.',
    ),
    'balanced_high': RelationshipInsightCopy(
      titleTr: 'Kişisel alanın belirgin bir önemi var',
      bodyTr:
          'Yakınlığa açık olmakla birlikte, ilişkinin bireyselliğini sınırlandırmamasını özellikle önemsiyor görünüyorsun.',
      titleEn: 'Personal space has clear importance',
      bodyEn:
          'You seem open to closeness while placing particular importance on a relationship leaving room for individuality.',
    ),
    'balanced_balanced': RelationshipInsightCopy(
      titleTr: 'Yakınlık ve alan arasında esneksin',
      bodyTr:
          'Ne sürekli yakınlık ne de sürekli mesafe tek başına baskın görünüyor. İlişkinin koşullarına göre denge kurmaya yatkın olabilirsin.',
      titleEn: 'You are flexible between closeness and space',
      bodyEn:
          'Neither constant closeness nor constant distance appears dominant. You may prefer adjusting the balance to the relationship and situation.',
    ),
    'balanced_low': RelationshipInsightCopy(
      titleTr: 'Birlikte hareket etmeye açıksın',
      bodyTr:
          'Yakınlık ihtiyacın duruma göre değişebilir; ancak ilişkide fazla ayrışmak yerine ortak bir ritim kurmaya daha açık görünüyorsun.',
      titleEn: 'You are open to a shared rhythm',
      bodyEn:
          'Your need for closeness may vary, but you appear more comfortable building a shared rhythm than maintaining strong separation.',
    ),
    'low_high': RelationshipInsightCopy(
      titleTr: 'Bağ kurarken alanını korumak istiyorsun',
      bodyTr:
          'İlişkiye önem versen bile sürekli yakınlık aramıyor, kendi alanının ve bağımsızlığının korunmasına daha fazla değer veriyor görünüyorsun.',
      titleEn: 'You want space within connection',
      bodyEn:
          'Even when a relationship matters to you, you do not seem to require constant closeness and place greater value on preserving independence.',
    ),
    'low_balanced': RelationshipInsightCopy(
      titleTr: 'Yakınlık konusunda seçicisin',
      bodyTr:
          'Sürekli yoğun bir bağ ihtiyacı göstermiyor, yakınlığın doğal biçimde ve baskı oluşmadan gelişmesini tercih ediyor olabilirsin.',
      titleEn: 'You are selective about closeness',
      bodyEn:
          'You do not appear to seek constant emotional intensity and may prefer closeness to develop naturally without pressure.',
    ),
    'low_low': RelationshipInsightCopy(
      titleTr: 'İlişkide yoğunluk aramak zorunda değilsin',
      bodyTr:
          'Hem sürekli yakınlık hem de güçlü bağımsızlık ihtiyacı şu anda belirgin görünmüyor; daha sade ve duruma göre şekillenen bir ilişki ritmi sana uygun olabilir.',
      titleEn: 'You may not need relationship intensity',
      bodyEn:
          'Neither constant closeness nor strong independence currently stands out, suggesting you may be comfortable with a simpler, situational relationship rhythm.',
    ),
  };

  static const _reassuranceTrust = <String, RelationshipInsightCopy>{
    'high_high': RelationshipInsightCopy(
      titleTr: 'Güven kadar açık güvence de önemli',
      bodyTr:
          'Karşındaki kişiye güvenebilirsin; yine de ilgi, açıklık ve ilişkinin iyi gittiğini gösteren işaretler senin için değerli görünüyor.',
      titleEn: 'Trust and reassurance both matter',
      bodyEn:
          'You may be able to trust your partner while still valuing clear signs of care, openness, and confirmation that the relationship is going well.',
    ),
    'high_balanced': RelationshipInsightCopy(
      titleTr: 'Belirsizlik yerine açıklığı tercih ediyorsun',
      bodyTr:
          'İlişkide nerede durduğunu bilmek ve karşılıklı ilgiyi hissedebilmek sana güven verebilir.',
      titleEn: 'You prefer clarity over uncertainty',
      bodyEn:
          'Knowing where you stand and being able to feel mutual interest may give you a stronger sense of security in a relationship.',
    ),
    'high_low': RelationshipInsightCopy(
      titleTr: 'Güven sözlerden çok doğrulanmak isteyebilir',
      bodyTr:
          'İlişkide güven senin için otomatik oluşmayabilir. Tutarlılık, açıklık ve karşı tarafın davranışları güven duygunu güçlendirebilir.',
      titleEn: 'Trust may need to be demonstrated',
      bodyEn:
          'Trust may not form automatically for you. Consistency, openness, and the other person’s actions may strengthen your sense of security.',
    ),
    'balanced_high': RelationshipInsightCopy(
      titleTr: 'Güvene alan bırakabiliyorsun',
      bodyTr:
          'Sürekli güvence aramadan karşı tarafa güvenmeye yatkın görünüyorsun; yine de iletişim tamamen önemsiz değil.',
      titleEn: 'You can give trust some room',
      bodyEn:
          'You appear able to trust another person without requiring constant reassurance, while still valuing communication when it matters.',
    ),
    'balanced_balanced': RelationshipInsightCopy(
      titleTr: 'Güven konusunda dengeli ilerliyorsun',
      bodyTr:
          'Ne sürekli doğrulama ihtiyacı ne de koşulsuz güven baskın görünüyor. Davranışlara ve ilişkinin gelişimine göre karar veriyor olabilirsin.',
      titleEn: 'You take a balanced approach to trust',
      bodyEn:
          'Neither constant reassurance nor unconditional trust appears dominant. You may judge trust through behavior and how the relationship develops.',
    ),
    'balanced_low': RelationshipInsightCopy(
      titleTr: 'Güvenin zamanla oluşmasını tercih edebilirsin',
      bodyTr:
          'Yoğun güvence ihtiyacı göstermesen de güven konusunda temkinli olabilir, karşı tarafı zaman içinde tanımayı tercih edebilirsin.',
      titleEn: 'You may prefer trust to build over time',
      bodyEn:
          'Even without a strong need for reassurance, you may be cautious about trust and prefer getting to know someone over time.',
    ),
    'low_high': RelationshipInsightCopy(
      titleTr: 'Güvende hissetmek için sürekli onaya ihtiyaç duymuyorsun',
      bodyTr:
          'Karşı tarafa güvenebildiğinde ilişkinin sürekli doğrulanmasına ihtiyaç duymadan rahat ilerleyebiliyor görünüyorsun.',
      titleEn: 'You may not need constant confirmation',
      bodyEn:
          'Once you trust someone, you appear comfortable letting the relationship progress without needing frequent confirmation.',
    ),
    'low_balanced': RelationshipInsightCopy(
      titleTr: 'Duygusal güvence konusunda bağımsızsın',
      bodyTr:
          'Karşı tarafın ilgisini sürekli kanıtlamasına ihtiyaç duymuyor, ilişkinin doğal akışına daha fazla alan bırakıyor olabilirsin.',
      titleEn: 'You are relatively independent about reassurance',
      bodyEn:
          'You may not need the other person to continually prove their interest and can leave more room for the relationship to unfold naturally.',
    ),
    'low_low': RelationshipInsightCopy(
      titleTr: 'Güveni kolay varsaymıyor ama sürekli de sorgulamıyorsun',
      bodyTr:
          'Ne yoğun güvence ihtiyacı ne de hızlı güven eğilimi belirgin. İnsanları kendi davranışları üzerinden değerlendirmeyi tercih ediyor olabilirsin.',
      titleEn: 'You neither assume nor constantly question trust',
      bodyEn:
          'Neither a strong need for reassurance nor quick trust stands out. You may prefer judging people primarily through their behavior.',
    ),
  };

  static const _commitmentPace = <String, RelationshipInsightCopy>{
    'high_high': RelationshipInsightCopy(
      titleTr: 'Ciddi bir bağ oluştuğunda hızlı ilerleyebilirsin',
      bodyTr:
          'İlişkide bağlılığa değer veriyor ve doğru kişiyi bulduğunu hissettiğinde ilişkinin ilerlemesinden çekinmiyor görünüyorsun.',
      titleEn: 'You may move confidently when commitment feels right',
      bodyEn:
          'You value commitment and appear comfortable allowing a relationship to progress when you feel you have found the right person.',
    ),
    'high_balanced': RelationshipInsightCopy(
      titleTr: 'Bağlılık önemli, tempo ise koşullara bağlı',
      bodyTr:
          'Uzun vadeli bir bağ senin için anlamlı görünüyor; ancak ilişkinin ne kadar hızlı ilerlemesi gerektiğini doğal gelişimine bırakabiliyorsun.',
      titleEn: 'Commitment matters more than speed',
      bodyEn:
          'A long-term bond appears meaningful to you, while the speed of the relationship can depend on how naturally it develops.',
    ),
    'high_low': RelationshipInsightCopy(
      titleTr: 'Ciddiyeti aceleye tercih ediyorsun',
      bodyTr:
          'Bağlılığa güçlü değer verirken ilişkinin adım adım ve sağlam biçimde ilerlemesini tercih ediyor görünüyorsun.',
      titleEn: 'You prefer commitment without rushing',
      bodyEn:
          'You appear to value commitment strongly while preferring the relationship to develop gradually and on solid ground.',
    ),
    'balanced_high': RelationshipInsightCopy(
      titleTr: 'Akış hızlandığında buna uyum sağlayabiliyorsun',
      bodyTr:
          'Bağlılık konusunda baştan kesin bir beklenti taşımadan, güçlü bir bağlantı oluştuğunda ilişkinin hızlı ilerlemesine açık olabilirsin.',
      titleEn: 'You can adapt when a connection moves quickly',
      bodyEn:
          'Without requiring commitment from the start, you may be open to a relationship progressing quickly when the connection feels strong.',
    ),
    'balanced_balanced': RelationshipInsightCopy(
      titleTr: 'İlişkinin kendi hızını bulmasını tercih ediyorsun',
      bodyTr:
          'Ne bağlılık ne de tempo konusunda katı bir çizgi baskın görünüyor. İlişkinin nasıl geliştiğine göre hareket edebilirsin.',
      titleEn: 'You prefer the relationship to find its own pace',
      bodyEn:
          'Neither commitment nor pace appears rigidly defined for you. You may prefer responding to how the relationship actually develops.',
    ),
    'balanced_low': RelationshipInsightCopy(
      titleTr: 'İlişkide zamana alan tanıyorsun',
      bodyTr:
          'Bağlılık ihtiyacını baştan zorlamadan, ilişkinin daha yavaş ve doğal biçimde şekillenmesini tercih edebilirsin.',
      titleEn: 'You give relationships time',
      bodyEn:
          'Without forcing commitment early, you may prefer allowing the relationship to take shape more slowly and naturally.',
    ),
    'low_high': RelationshipInsightCopy(
      titleTr: 'Hızlı bağ kurabilirsin ama erken tanım koymak istemeyebilirsin',
      bodyTr:
          'Bir ilişki hızla gelişebilirken, onu hemen uzun vadeli bir çerçeveye yerleştirme konusunda daha özgür kalmayı tercih edebilirsin.',
      titleEn: 'You may connect quickly without defining it early',
      bodyEn:
          'A relationship may develop quickly for you while you still prefer flexibility before placing it in a long-term framework.',
    ),
    'low_balanced': RelationshipInsightCopy(
      titleTr: 'Bağlılık konusunda açık uçlu ilerleyebilirsin',
      bodyTr:
          'İlişkinin başında uzun vadeli sonuçları belirlemek yerine, bağın zaman içinde neye dönüşeceğini görmeyi tercih ediyor olabilirsin.',
      titleEn: 'You may keep commitment open-ended',
      bodyEn:
          'Rather than defining long-term outcomes early, you may prefer seeing what the connection becomes over time.',
    ),
    'low_low': RelationshipInsightCopy(
      titleTr: 'İlişkilere zaman ve özgürlük tanıyorsun',
      bodyTr:
          'Hem hızlı ilerleme hem de erken bağlılık beklentisi sana doğal gelmeyebilir. Bağın kendi zamanında gelişmesini tercih ediyor görünüyorsun.',
      titleEn: 'You give relationships time and freedom',
      bodyEn:
          'Neither rapid progression nor early commitment appears especially natural to you. You seem to prefer letting the connection develop in its own time.',
    ),
  };

  static const _affectionPlayfulness = <String, RelationshipInsightCopy>{
    'high_high': RelationshipInsightCopy(
      titleTr: 'Sevgini hem sıcaklıkla hem neşeyle gösteriyorsun',
      bodyTr:
          'İlişkide sevgiyi görünür biçimde ifade etmek ve birlikte eğlenmek senin için güçlü bir bağ kurma yolu olabilir.',
      titleEn: 'You show affection with warmth and playfulness',
      bodyEn:
          'Expressing affection openly and having fun together may both be important ways for you to build connection.',
    ),
    'high_balanced': RelationshipInsightCopy(
      titleTr: 'Sevgini göstermeyi önemsiyorsun',
      bodyTr:
          'İlgi ve sevgiyi görünür biçimde ifade etmek sana doğal geliyor olabilir; ilişkinin eğlenceli tarafı ise duruma göre değişebilir.',
      titleEn: 'Expressing affection matters to you',
      bodyEn:
          'Showing care and affection openly may come naturally to you, while the playful side of a relationship can depend more on the situation.',
    ),
    'high_low': RelationshipInsightCopy(
      titleTr: 'Sevgin daha ciddi ve doğrudan olabilir',
      bodyTr:
          'İlgini açıkça göstermeye değer verirken, ilişkide sürekli şakalaşma veya oyun aramak senin için daha az önemli olabilir.',
      titleEn: 'Your affection may be more direct than playful',
      bodyEn:
          'You appear to value showing care openly, while constant joking or playfulness may be less central to how you connect.',
    ),
    'balanced_high': RelationshipInsightCopy(
      titleTr: 'Eğlence bağ kurmanın önemli bir parçası',
      bodyTr:
          'Sevgiyi her zaman doğrudan ifade etmesen bile mizah, oyun ve birlikte keyifli zaman geçirmek sana yakınlık hissettirebilir.',
      titleEn: 'Playfulness is an important way to connect',
      bodyEn:
          'Even when affection is not always expressed directly, humor, play, and enjoyable shared moments may help you feel connected.',
    ),
    'balanced_balanced': RelationshipInsightCopy(
      titleTr: 'Sevgi dilin duruma göre değişebiliyor',
      bodyTr:
          'Hem duygusal ifade hem de eğlence konusunda tek bir tarz baskın görünmüyor. Karşındaki kişiye ve ana göre farklı biçimlerde bağ kurabilirsin.',
      titleEn: 'Your way of showing affection is flexible',
      bodyEn:
          'Neither emotional expression nor playfulness dominates strongly. You may connect in different ways depending on the person and situation.',
    ),
    'balanced_low': RelationshipInsightCopy(
      titleTr: 'Bağ kurarken daha sakin bir ton tercih edebilirsin',
      bodyTr:
          'Sevgi ifaden değişken olabilir; ancak ilişkide sürekli eğlence veya yüksek enerji yerine daha sakin etkileşimlerden hoşlanıyor olabilirsin.',
      titleEn: 'You may prefer a calmer way of connecting',
      bodyEn:
          'Your affection style may vary, while calmer interactions may feel more natural than constant playfulness or high energy.',
    ),
    'low_high': RelationshipInsightCopy(
      titleTr: 'Sevgini eğlence ve paylaşım üzerinden gösterebilirsin',
      bodyTr:
          'Duygularını doğrudan ifade etmekten çok birlikte gülmek, şakalaşmak ve deneyim paylaşmak sana daha doğal gelebilir.',
      titleEn: 'You may show affection through shared fun',
      bodyEn:
          'Rather than expressing feelings directly, laughing, joking, and sharing experiences may feel like a more natural way for you to show care.',
    ),
    'low_balanced': RelationshipInsightCopy(
      titleTr: 'Sevgini daha örtük biçimde gösterebilirsin',
      bodyTr:
          'Yoğun duygusal ifadeler yerine davranışların, zaman ayırman veya küçük jestlerin senin için daha doğal bir sevgi göstergesi olması mümkün.',
      titleEn: 'You may express affection more subtly',
      bodyEn:
          'Instead of intense emotional expression, your actions, time, or small gestures may be more natural ways for you to show affection.',
    ),
    'low_low': RelationshipInsightCopy(
      titleTr: 'Bağın daha sakin ve sade olabilir',
      bodyTr:
          'Ne yoğun duygusal ifade ne de sürekli eğlence ihtiyacı belirgin görünüyor. Daha sakin, doğal ve baskısız bir ilişki biçimi sana yakın olabilir.',
      titleEn: 'Your connection style may be calm and understated',
      bodyEn:
          'Neither intense emotional expression nor constant playfulness appears especially strong. A calmer, natural, low-pressure connection may suit you.',
    ),
  };
}
