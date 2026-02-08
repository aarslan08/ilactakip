import 'package:flutter/material.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';

/// Boş durum widget'ı
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // İkon container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.1),
                    AppTheme.primaryLight.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 56,
                color: AppTheme.primaryColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            
            // Başlık
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Alt başlık
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            // Buton
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.add_rounded),
                label: Text(buttonText!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
