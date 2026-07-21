import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../assessment/utils/assessment_persona_reference_catalog.dart';
import '../../assessment/widgets/assessment_result_frame.dart';

/// Debug-only carousel for reviewing every persona result without taking tests.
class PersonaResultPreviewScreen extends StatefulWidget {
  const PersonaResultPreviewScreen({super.key});

  @override
  State<PersonaResultPreviewScreen> createState() =>
      _PersonaResultPreviewScreenState();
}

class _PersonaResultPreviewScreenState
    extends State<PersonaResultPreviewScreen> {
  final _personas = assessmentPersonaReferenceCatalog.values.toList();
  int _index = 0;

  void _show(int index) {
    setState(() {
      _index = (index + _personas.length) % _personas.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(
          child: Text('Persona preview is available only in debug builds.'),
        ),
      );
    }

    final isTurkish =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'tr';
    final persona = _personas[_index];

    return Stack(
      children: [
        AssessmentResultFrame(
          title: isTurkish ? persona.titleTr : persona.titleEn,
          description:
              isTurkish ? persona.descriptionTr : persona.descriptionEn,
          personaAsset: persona.asset,
          statusLabel: '${isTurkish ? 'Önizleme' : 'Preview'} ${_index + 1}'
              '/${_personas.length} · ${persona.id}',
          ctaLabel: isTurkish ? 'Sonraki Persona' : 'Next Persona',
          onCta: () => _show(_index + 1),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _PreviewControl(
                    tooltip: isTurkish ? 'Kapat' : 'Close',
                    icon: Icons.close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Row(
                    children: [
                      _PreviewControl(
                        tooltip: isTurkish ? 'Önceki' : 'Previous',
                        icon: Icons.chevron_left,
                        onPressed: () => _show(_index - 1),
                      ),
                      const SizedBox(width: 8),
                      _PreviewControl(
                        tooltip: isTurkish ? 'Sonraki' : 'Next',
                        icon: Icons.chevron_right,
                        onPressed: () => _show(_index + 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewControl extends StatelessWidget {
  const _PreviewControl({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xB314071D),
      shape: const CircleBorder(
        side: BorderSide(color: Color(0x99FFD867)),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: const Color(0xFFFFD867)),
      ),
    );
  }
}
