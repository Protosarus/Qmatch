import 'package:flutter/material.dart';

import '../utils/assessment_persona_reference_catalog.dart';
import '../widgets/assessment_result_frame.dart';

class PersonaLabScreen extends StatelessWidget {
  const PersonaLabScreen({
    super.key,
    required this.primaryPersonaId,
    required this.secondaryPersonaId,
  }) : assert(primaryPersonaId != secondaryPersonaId);

  final String primaryPersonaId;
  final String secondaryPersonaId;

  @override
  Widget build(BuildContext context) {
    final isTurkish =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'tr';

    final persona = assessmentPersonaReferenceCatalog[primaryPersonaId] ??
        assessmentPersonaReferenceCatalog.values.first;

    return Stack(
      key: const Key('persona-lab-screen'),
      children: [
        AssessmentResultFrame(
          title: isTurkish ? persona.titleTr : persona.titleEn,
          description:
              isTurkish ? persona.descriptionTr : persona.descriptionEn,
          personaAsset: persona.asset,
          statusLabel: null,
          ctaLabel: '',
          onCta: () {},
          showCta: false,
          plateLabel: isTurkish ? persona.signatureTr : persona.signatureEn,
        ),

        // Production Persona Lab: only close control.
        // Persona browsing remains exclusively in the debug preview screen.
        Positioned(
          top: 0,
          left: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 0, 0),
              child: _PersonaLabCloseControl(
                tooltip: isTurkish ? 'Kapat' : 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PersonaLabCloseControl extends StatelessWidget {
  const _PersonaLabCloseControl({
    required this.tooltip,
    required this.onPressed,
  });

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xB3121630),
      shape: const CircleBorder(
        side: BorderSide(
          color: Color(0x99DAC8ED),
        ),
      ),
      child: IconButton(
        key: const Key('persona-lab-close'),
        tooltip: tooltip,
        onPressed: onPressed,
        icon: const Icon(
          Icons.close,
          color: Color(0xFFDAC8ED),
        ),
      ),
    );
  }
}
