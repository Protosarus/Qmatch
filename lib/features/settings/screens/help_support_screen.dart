import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: Text(
          'Yardım & Destek',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        children: [
          _faq(
            q: 'Qmatch nasıl çalışır?',
            a:
                'Qmatch; düşünme (IQ), hissetme (EQ) ve bağ kurma tarzını (Frequency) temel alarak eşleşmeler önerir. Amaç, sadece görünüşe değil uyuma odaklanmaktır.',
          ),
          _faq(
            q: 'Fotoğraflar neden bulanık?',
            a:
                'Fotoğraflar, konuşma ve karşılıklı güven arttıkça kademeli olarak netleşir. Tam netleşme için karşılıklı onay gerekir.',
          ),
          _faq(
            q: 'Reveal isteği nedir?',
            a:
                'Reveal isteği, fotoğrafları tamamen netleştirmek için gönderilen onay talebidir. İki taraf da kabul ederse fotoğraflar açılır.',
          ),
          _faq(
            q: 'Frequency ne anlama gelir?',
            a:
                'Frequency, birinin nasıl bağ kurduğunu ve iletişim ritmini anlatır. Derinlik, sosyal enerji ve güven hızı gibi boyutlardan oluşur.',
          ),
          _faq(
            q: 'Bir kullanıcıyı nasıl engellerim?',
            a:
                'Sohbet ekranındaki menüden engelleme seçeneğini kullanabilirsin. Engellenen kullanıcılar ayarlardaki “Engellenenler” bölümünde görünür.',
          ),
          _faq(
            q: 'Birini nasıl şikayet ederim?',
            a:
                'Sohbet ekranındaki menüden şikayet seçeneğini kullanarak gerekçeni seçebilirsin. Şikayetler incelenmek üzere kaydedilir.',
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
            ),
            child: Text(
              'Destek ile iletişim (MVP):\n\n'
              'TODO: Uygulama içi destek talebi veya e-posta bağlantısı ekle.',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _faq({required String q, required String a}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: ExpansionTile(
        collapsedIconColor: AppColors.textSecondary,
        iconColor: AppColors.primary,
        title: Text(
          q,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            a,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

