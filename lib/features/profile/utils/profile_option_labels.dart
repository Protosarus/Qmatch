import '../../../l10n/app_localizations.dart';

/// Maps canonical profile option values (as stored in Firestore) to
/// locale-aware display labels. Stored values stay Turkish legacy strings.
class ProfileOptionLabels {
  const ProfileOptionLabels._();

  static String label(AppLocalizations l10n, String? stored) {
    if (stored == null || stored.isEmpty) return '';
    switch (stored) {
      case 'Agnostik':
        return l10n.optReligionAgnostic;
      case 'Akışına Bırakıyorum':
        return l10n.optLookingGoWithFlow;
      case 'Alerji':
        return l10n.optPetsAllergy;
      case 'Arkadaşlık':
        return l10n.optLookingFriendship;
      case 'Ateist':
        return l10n.optReligionAtheist;
      case 'Bazen':
        return l10n.optSmokingSometimes;
      case 'Belirtmek İstemiyorum':
        return l10n.optPreferNotToSay;
      case 'Belki İleride':
        return l10n.optChildrenMaybe;
      case 'Budist':
        return l10n.optReligionBuddhist;
      case 'Bırakmaya Çalışıyorum':
        return l10n.optSmokingQuitting;
      case 'Ciddi İlişki':
        return l10n.optLookingSerious;
      case 'Diğer':
        // Religion option stored as legacy TR "Diğer" — not gender.
        return l10n.optReligionOther;
      case 'Doktora':
        return l10n.optEduDoctorate;
      case 'Düzenli':
        return l10n.optSmokingRegular;
      case 'Erkek':
        return l10n.optGenderMale;
      case 'Evlilik':
        return l10n.optLookingMarriage;
      case 'Henüz Emin Değilim':
        return l10n.optLookingUnsure;
      case 'Hindu':
        return l10n.optReligionHindu;
      case 'Hristiyan':
        return l10n.optReligionChristian;
      case 'Kadın':
        return l10n.optGenderFemale;
      case 'Kararsızım':
        return l10n.optChildrenUnsure;
      case 'Kullanmıyorum':
        return l10n.optNever;
      case 'Lisans':
        return l10n.optEduBachelor;
      case 'Lise':
        return l10n.optEduHighSchool;
      case 'Manevi':
        return l10n.optReligionSpiritual;
      case 'Müslüman':
        return l10n.optReligionMuslim;
      case 'Nötr':
        return l10n.optAnimalLoveNeutral;
      case 'Pek Sevmem':
        return l10n.optAnimalLoveLow;
      case 'Seviyorum':
        return l10n.optAnimalLoveYes;
      case 'Sosyal':
        return l10n.optDrinkingSocial;
      case 'Sık sık':
        return l10n.optDrinkingOften;
      case 'Tanışma':
        return l10n.optLookingCasual;
      case 'Uzun Vadeli İlişki':
        return l10n.optLookingLongTerm;
      case 'Var':
        return l10n.optYesHave;
      case 'Yahudi':
        return l10n.optReligionJewish;
      case 'Yakın Arkadaşlık':
        return l10n.optLookingCloseFriendship;
      case 'Yok':
        return l10n.optNo;
      case 'Yok Ama İstiyorum':
        return l10n.optChildrenWant;
      case 'Yok ve İstemiyorum':
        return l10n.optChildrenNo;
      case 'Yüksek Lisans':
        return l10n.optEduMaster;
      case 'Çok Seviyorum':
        return l10n.optAnimalLoveHigh;
      case 'Ön Lisans':
        return l10n.optEduAssociate;
      case 'Özel Günlerde':
        return l10n.optDrinkingSpecial;
      case 'İstiyorum':
        return l10n.optPetsWant;
      case 'AI/ML':
        return l10n.interestAiml;
      case 'Backpacking':
        return l10n.interestBackpacking;
      case 'Bale':
        return l10n.interestBallet;
      case 'Basketbol':
        return l10n.interestBasketball;
      case 'Bisiklet':
        return l10n.interestCycling;
      case 'Blockchain':
        return l10n.interestBlockchain;
      case 'Boks':
        return l10n.interestBoxing;
      case 'Cloud Computing':
        return l10n.interestCloud;
      case 'Dans':
        return l10n.interestDance;
      case 'Dağcılık':
        return l10n.interestHiking;
      case 'Doğa':
        return l10n.interestNature;
      case 'Edebiyat':
        return l10n.interestLiterature;
      case 'Enstrüman Çalmak':
        return l10n.interestInstrument;
      case 'Extreme Sporlar':
        return l10n.interestExtremeSports;
      case 'Fitness':
        return l10n.interestFitness;
      case 'Fotoğrafçılık':
        return l10n.interestPhotography;
      case 'Futbol':
        return l10n.interestFootball;
      case 'Gastro Turlar':
        return l10n.interestFoodTours;
      case 'Golf':
        return l10n.interestGolf;
      case 'Grafik Tasarım':
        return l10n.interestGraphicDesign;
      case 'Heykel':
        return l10n.interestSculpture;
      case 'IoT':
        return l10n.interestIot;
      case 'Jimnastik':
        return l10n.interestGymnastics;
      case 'Kamp':
        return l10n.interestCamping;
      case 'Kodlama':
        return l10n.interestCoding;
      case 'Koşu':
        return l10n.interestRunning;
      case 'Kripto':
        return l10n.interestCrypto;
      case 'Kültür Turları':
        return l10n.interestCultureTours;
      case 'Lüks Tatil':
        return l10n.interestLuxuryTravel;
      case 'Mobil Uygulama':
        return l10n.interestMobileApps;
      case 'Müzik':
        return l10n.interestMusic;
      case 'Opera':
        return l10n.interestOpera;
      case 'Oyun':
        return l10n.interestGaming;
      case 'Pilates':
        return l10n.interestPilates;
      case 'Plaj Tatili':
        return l10n.interestBeach;
      case 'Resim':
        return l10n.interestPainting;
      case 'Robotik':
        return l10n.interestRobotics;
      case 'Safari':
        return l10n.interestSafari;
      case 'Sanat':
        return l10n.interestCatArts;
      case 'Seyahat':
        return l10n.interestCatTravel;
      case 'Siber Güvenlik':
        return l10n.interestCybersecurity;
      case 'Sinema':
        return l10n.interestCinema;
      case 'Solo Seyahat':
        return l10n.interestSoloTravel;
      case 'Spor':
        return l10n.interestCatSports;
      case 'Stand-up':
        return l10n.interestStandup;
      case 'Tarihi Yerler':
        return l10n.interestHistoricSites;
      case 'Teknoloji':
        return l10n.interestCatTech;
      case 'Tenis':
        return l10n.interestTennis;
      case 'Tiyatro':
        return l10n.interestTheatre;
      case 'Veri Bilimi':
        return l10n.interestDataScience;
      case 'Voleybol':
        return l10n.interestVolleyball;
      case 'Web3':
        return l10n.interestWeb3;
      case 'Yazarlık':
        return l10n.interestWriting;
      case 'Yelken':
        return l10n.interestSailing;
      case 'Yoga':
        return l10n.interestYoga;
      case 'Yurt Dışı':
        return l10n.interestAbroad;
      case 'Yüzme':
        return l10n.interestSwimming;
      case 'Şiir':
        return l10n.interestPoetry;
      default:
        return stored;
    }
  }

  static String interest(AppLocalizations l10n, String stored) =>
      label(l10n, stored);

  /// Context-aware pet option display (same stored keys as children).
  static String petsLabel(AppLocalizations l10n, String stored) {
    switch (stored) {
      case 'Var':
        return l10n.optPetsHave;
      case 'Yok':
        return l10n.optPetsNone;
      case 'İstiyorum':
        return l10n.optPetsWant;
      case 'Alerji':
        return l10n.optPetsAllergy;
      default:
        return label(l10n, stored);
    }
  }

  static String childrenLabel(AppLocalizations l10n, String stored) {
    switch (stored) {
      case 'Var':
        return l10n.optChildrenHave;
      case 'Yok Ama İstiyorum':
        return l10n.optChildrenWant;
      case 'Yok ve İstemiyorum':
        return l10n.optChildrenNo;
      case 'Kararsızım':
        return l10n.optChildrenUnsure;
      case 'Belki İleride':
        return l10n.optChildrenMaybe;
      default:
        return label(l10n, stored);
    }
  }
}
