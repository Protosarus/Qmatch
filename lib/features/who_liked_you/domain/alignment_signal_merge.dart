import 'who_liked_you_card.dart';

/// Merge Super Resonance + ordinary Alignment Signals.
///
/// Super Resonance rows stay first. Duplicate UIDs collapse to the Super
/// Resonance card. Ordinary likes never unlock Super Resonance identity.
List<WhoLikedYouCard> mergeAlignmentSignals({
  required List<WhoLikedYouCard> superResonance,
  required List<WhoLikedYouCard> ordinary,
}) {
  final out = <WhoLikedYouCard>[];
  final seen = <String>{};
  for (final card in superResonance) {
    if (card.uid.isEmpty || !seen.add(card.uid)) continue;
    out.add(card.superResonance ? card : card.copyWith(superResonance: true));
  }
  for (final card in ordinary) {
    if (card.uid.isEmpty || !seen.add(card.uid)) continue;
    out.add(card.copyWith(superResonance: false));
  }
  return List<WhoLikedYouCard>.unmodifiable(out);
}
