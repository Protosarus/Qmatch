import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text(
                    'Ayarlar',
                    style: GoogleFonts.playfairDisplay(
                      color: AppColors.primary,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Settings List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildSettingItem(
                    icon: Icons.notifications,
                    title: 'Bildirimler',
                    subtitle: 'Bildirim tercihlerini yönet',
                    onTap: () {
                      // TODO: Navigate to notifications settings
                    },
                  ),
                  _buildSettingItem(
                    icon: Icons.privacy_tip,
                    title: 'Gizlilik',
                    subtitle: 'Gizlilik ayarları',
                    onTap: () {
                      // TODO: Navigate to privacy settings
                    },
                  ),
                  _buildSettingItem(
                    icon: Icons.block,
                    title: 'Engellenenler',
                    subtitle: 'Engellenen kullanıcılar',
                    onTap: () {
                      // TODO: Navigate to blocked users
                    },
                  ),
                  _buildSettingItem(
                    icon: Icons.help,
                    title: 'Yardım & Destek',
                    subtitle: 'Sıkça sorulan sorular',
                    onTap: () {
                      // TODO: Navigate to help
                    },
                  ),
                  _buildSettingItem(
                    icon: Icons.info,
                    title: 'Hakkında',
                    subtitle: 'Uygulama bilgileri',
                    onTap: () {
                      // TODO: Navigate to about
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSettingItem(
                    icon: Icons.logout,
                    title: 'Çıkış Yap',
                    subtitle: 'Hesabından çıkış yap',
                    isDestructive: true,
                    onTap: () {
                      // TODO: Logout
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDestructive
              ? Colors.red.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withValues(alpha: 0.1)
                : AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : AppColors.primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: isDestructive ? Colors.red : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
