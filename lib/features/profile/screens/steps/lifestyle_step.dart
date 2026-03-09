import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class LifestyleStep extends StatelessWidget {
  final String? occupation;
  final String? drinking;
  final String? smoking;
  final String? pets;
  final String? children;
  final String? religion;
  final String? animalLove;
  final Function(String?) onOccupationChanged;
  final Function(String?) onDrinkingChanged;
  final Function(String?) onSmokingChanged;
  final Function(String?) onPetsChanged;
  final Function(String?) onChildrenChanged;
  final Function(String?) onReligionChanged;
  final Function(String?) onAnimalLoveChanged;

  const LifestyleStep({
    super.key,
    required this.occupation,
    required this.drinking,
    required this.smoking,
    required this.pets,
    required this.children,
    required this.religion,
    required this.animalLove,
    required this.onOccupationChanged,
    required this.onDrinkingChanged,
    required this.onSmokingChanged,
    required this.onPetsChanged,
    required this.onChildrenChanged,
    required this.onReligionChanged,
    required this.onAnimalLoveChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Yaşam Tarzı',
            style: GoogleFonts.playfairDisplay(
              color: AppColors.primary,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Opsiyonel - Paylaşmak istersen doldur',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          
          // Meslek
          _buildLabel('Meslek'),
          TextField(
            onChanged: onOccupationChanged,
            style: GoogleFonts.inter(color: Colors.white),
            decoration: _buildInputDecoration('Örn: Yazılım Geliştirici'),
          ),
          const SizedBox(height: 24),
          
          // İçki
          _buildLabel('İçki'),
          DropdownButtonFormField<String>(
            initialValue: drinking,
            decoration: _buildInputDecoration('Seçiniz'),
            dropdownColor: Colors.grey.shade900,
            style: GoogleFonts.inter(color: Colors.white),
            items: const [
              DropdownMenuItem(value: 'Kullanmıyorum', child: Text('Kullanmıyorum')),
              DropdownMenuItem(value: 'Sosyal', child: Text('Sosyal İçiciyim')),
              DropdownMenuItem(value: 'Sık sık', child: Text('Sık İçerim')),
              DropdownMenuItem(value: 'Özel Günlerde', child: Text('Sadece Özel Günlerde')),
            ],
            onChanged: onDrinkingChanged,
          ),
          const SizedBox(height: 24),
          
          // Sigara
          _buildLabel('Sigara'),
          DropdownButtonFormField<String>(
            initialValue: smoking,
            decoration: _buildInputDecoration('Seçiniz'),
            dropdownColor: Colors.grey.shade900,
            style: GoogleFonts.inter(color: Colors.white),
            items: const [
              DropdownMenuItem(value: 'Kullanmıyorum', child: Text('Kullanmıyorum')),
              DropdownMenuItem(value: 'Bazen', child: Text('Sosyal İçiyorum')),
              DropdownMenuItem(value: 'Düzenli', child: Text('Düzenli İçiyorum')),
              DropdownMenuItem(value: 'Bırakmaya Çalışıyorum', child: Text('Bırakmaya Çalışıyorum')),
            ],
            onChanged: onSmokingChanged,
          ),
          const SizedBox(height: 24),
          
          // Evcil Hayvan
          _buildLabel('Evcil Hayvan'),
          DropdownButtonFormField<String>(
            initialValue: pets,
            decoration: _buildInputDecoration('Seçiniz'),
            dropdownColor: Colors.grey.shade900,
            style: GoogleFonts.inter(color: Colors.white),
            items: const [
              DropdownMenuItem(value: 'Var', child: Text('Evcil Hayvanım Var')),
              DropdownMenuItem(value: 'Yok', child: Text('Hayvanım Yok')),
              DropdownMenuItem(value: 'İstiyorum', child: Text('Hayvan Sahibi Olmak İstiyorum')),
              DropdownMenuItem(value: 'Alerji', child: Text('Alerjim Var')),
            ],
            onChanged: onPetsChanged,
          ),
          const SizedBox(height: 24),
          
          // Hayvan Sevgisi
          _buildLabel('Hayvan Sevgisi'),
          DropdownButtonFormField<String>(
            initialValue: animalLove,
            decoration: _buildInputDecoration('Seçiniz'),
            dropdownColor: Colors.grey.shade900,
            style: GoogleFonts.inter(color: Colors.white),
            items: const [
              DropdownMenuItem(value: 'Çok Seviyorum', child: Text('Hayvan Delisiyim 🐾')),
              DropdownMenuItem(value: 'Seviyorum', child: Text('Seviyorum')),
              DropdownMenuItem(value: 'Nötr', child: Text('Normal Karşılıyorum')),
              DropdownMenuItem(value: 'Pek Sevmem', child: Text('Pek Sevmem')),
            ],
            onChanged: onAnimalLoveChanged,
          ),
          const SizedBox(height: 24),
          
          // Çocuk
          _buildLabel('Çocuk İsteği'),
          DropdownButtonFormField<String>(
            initialValue: children,
            decoration: _buildInputDecoration('Seçiniz'),
            dropdownColor: Colors.grey.shade900,
            style: GoogleFonts.inter(color: Colors.white),
            items: const [
              DropdownMenuItem(value: 'Var', child: Text('Çocuğum Var')),
              DropdownMenuItem(value: 'Yok Ama İstiyorum', child: Text('Yok Ama İstiyorum')),
              DropdownMenuItem(value: 'Yok ve İstemiyorum', child: Text('İstemiyorum')),
              DropdownMenuItem(value: 'Kararsızım', child: Text('Henüz Kararsızım')),
              DropdownMenuItem(value: 'Belki İleride', child: Text('Belki İleride')),
            ],
            onChanged: onChildrenChanged,
          ),
          const SizedBox(height: 24),
          
          // Din
          _buildLabel('Din / İnanç'),
          DropdownButtonFormField<String>(
            initialValue: religion,
            decoration: _buildInputDecoration('Seçiniz'),
            dropdownColor: Colors.grey.shade900,
            style: GoogleFonts.inter(color: Colors.white),
            items: const [
              DropdownMenuItem(value: 'Müslüman', child: Text('Müslüman')),
              DropdownMenuItem(value: 'Hristiyan', child: Text('Hristiyan')),
              DropdownMenuItem(value: 'Yahudi', child: Text('Yahudi')),
              DropdownMenuItem(value: 'Budist', child: Text('Budist')),
              DropdownMenuItem(value: 'Hindu', child: Text('Hindu')),
              DropdownMenuItem(value: 'Agnostik', child: Text('Agnostik')),
              DropdownMenuItem(value: 'Ateist', child: Text('Ateist')),
              DropdownMenuItem(value: 'Manevi', child: Text('Manevi (Dini Olmayan)')),
              DropdownMenuItem(value: 'Diğer', child: Text('Diğer')),
              DropdownMenuItem(value: 'Belirtmek İstemiyorum', child: Text('Belirtmek İstemiyorum')),
            ],
            onChanged: onReligionChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.grey.shade900,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
