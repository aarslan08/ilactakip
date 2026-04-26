import 'package:flutter/material.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/core/localization/app_localizations.dart';

enum LegalContentType { privacy, terms }

class LegalContentScreen extends StatelessWidget {
  final LegalContentType type;

  const LegalContentScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final title = type == LegalContentType.privacy
        ? l10n.privacyPolicy
        : l10n.termsOfService;

    final sections = type == LegalContentType.privacy
        ? _privacySections(l10n)
        : _termsSections(l10n);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            centerTitle: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                '${l10n.legalLastUpdated}: ${l10n.locale.languageCode == 'tr' ? '21 Nisan 2025' : 'April 21, 2025'}',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildSection(
                context,
                sections[index],
                isDark,
                theme,
              ),
              childCount: sections.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    _LegalSection section,
    bool isDark,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: section.initiallyExpanded,
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                section.icon,
                color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                size: 20,
              ),
            ),
            title: Text(
              section.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            children: section.paragraphs.map((p) {
              if (p.startsWith('•')) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ',
                          style: TextStyle(
                              fontSize: 14,
                              color: theme.textTheme.bodyMedium?.color)),
                      Expanded(
                        child: Text(
                          p.substring(2),
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  p,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  List<_LegalSection> _privacySections(AppLocalizations l10n) {
    final isTr = l10n.locale.languageCode == 'tr';

    if (isTr) {
      return [
        const _LegalSection(
          icon: Icons.visibility_rounded,
          title: '1. Genel Bakış',
          initiallyExpanded: true,
          paragraphs: [
            'İlaç Takip uygulaması, kullanıcıların ilaç kullanımlarını takip etmelerine yardımcı olmak amacıyla geliştirilmiş bir mobil uygulamadır. Gizliliğiniz bizim için en önemli önceliktir.',
            'Temel ilkemiz: Tüm kişisel verileriniz yalnızca cihazınızda saklanır. Hiçbir veri harici sunuculara, bulut hizmetlerine veya üçüncü taraflara gönderilmez.',
          ],
        ),
        const _LegalSection(
          icon: Icons.storage_rounded,
          title: '2. Toplanan Veriler',
          paragraphs: [
            'Uygulama, işlevselliğini sağlamak için aşağıdaki bilgileri yalnızca cihazınızda saklar:',
            '• İlaç bilgileri: İlaç adı, doz miktarı, kullanım sıklığı, stok miktarı, son kullanma tarihi ve notlar',
            '• Doz kayıtları: İlaç alım, atlama veya kaçırma kayıtları ile tarihleri',
            '• Uygulama tercihleri: Dil, tema, bildirim ayarları',
            '• Bildirim planları: Hatırlatma saatleri ve sessiz saat tercihleri',
            'Uygulama şunları kesinlikle toplamaz:',
            '• Ad, soyad, e-posta adresi veya telefon numarası',
            '• Konum bilgileri',
            '• Cihaz kimlik bilgileri',
            '• Kullanım analitiği veya davranış verileri',
          ],
        ),
        const _LegalSection(
          icon: Icons.track_changes_rounded,
          title: '3. Verilerin Kullanım Amacı',
          paragraphs: [
            'Cihazınızda saklanan veriler yalnızca şu amaçlarla kullanılır:',
            '• İlaç kullanım programınızı oluşturmak ve yönetmek',
            '• Zamanında doz hatırlatmaları göndermek',
            '• Stok durumu ve düşük stok uyarıları sağlamak',
            '• İlaç uyum istatistiklerini hesaplamak ve göstermek',
            '• Doz geçmişi kayıtlarını tutmak',
            '• Uygulama tercihlerinizi hatırlamak',
          ],
        ),
        const _LegalSection(
          icon: Icons.security_rounded,
          title: '4. Veri Depolama ve Güvenlik',
          paragraphs: [
            'Tüm veriler cihazınızdaki yerel veritabanında saklanır. Verileriniz:',
            '• Hiçbir zaman internet üzerinden iletilmez',
            '• Hiçbir sunucuya yedeklenmez',
            '• Cihazınızın güvenlik mekanizmaları tarafından korunur',
            '• Uygulamayı kaldırdığınızda otomatik olarak silinir',
            'Uygulama internet bağlantısı gerektirmez ve tamamen çevrimdışı çalışır.',
          ],
        ),
        const _LegalSection(
          icon: Icons.share_rounded,
          title: '5. Veri Paylaşımı',
          paragraphs: [
            'İlaç Takip uygulaması:',
            '• Hiçbir veriyi üçüncü taraflarla paylaşmaz',
            '• Reklam ağları veya analitik hizmetleri kullanmaz',
            '• Veri satışı veya ticareti yapmaz',
            '• Sosyal medya entegrasyonu içermez',
          ],
        ),
        const _LegalSection(
          icon: Icons.phonelink_lock_rounded,
          title: '6. Uygulama İzinleri',
          paragraphs: [
            'Uygulama yalnızca şu izinleri talep eder:',
            '• Bildirim İzni: İlaç hatırlatmaları göndermek için. İsteğe bağlıdır.',
            '• Tam Zamanlı Alarm: Android\'de zamanında bildirim için gereklidir.',
            'Uygulama; kamera, mikrofon, konum, kişiler veya diğer hassas izinleri talep etmez.',
          ],
        ),
        const _LegalSection(
          icon: Icons.child_care_rounded,
          title: '7. Çocukların Gizliliği',
          paragraphs: [
            'Uygulama hiçbir kişisel bilgi toplamadığından, çocuklara özel ek gizlilik endişesi bulunmamaktadır. Ebeveynler, çocuklarının ilaç takibini bu uygulama aracılığıyla güvenle yapabilirler.',
          ],
        ),
        const _LegalSection(
          icon: Icons.gavel_rounded,
          title: '8. Kullanıcı Hakları',
          paragraphs: [
            'Tüm verileriniz cihazınızda saklandığından:',
            '• Erişim: Uygulama içinden tüm verilerinize erişebilirsiniz',
            '• Düzeltme: Bilgilerinizi istediğiniz zaman düzenleyebilirsiniz',
            '• Silme: İlaçları veya uygulamayı kaldırarak tüm verileri silebilirsiniz',
            '• Taşınabilirlik: Cihaz yedekleme araçlarını kullanabilirsiniz',
          ],
        ),
        const _LegalSection(
          icon: Icons.mail_outline_rounded,
          title: '9. İletişim',
          paragraphs: [
            'Gizlilik politikamız hakkında sorularınız için bize destek@ilactakip.app adresinden ulaşabilirsiniz.',
          ],
        ),
      ];
    }

    return [
      const _LegalSection(
        icon: Icons.visibility_rounded,
        title: '1. Overview',
        initiallyExpanded: true,
        paragraphs: [
          'Medication Tracker ("App") is a mobile application designed to help users track their medication usage. Your privacy is our top priority.',
          'Core principle: All your personal data is stored only on your device. No data is sent to external servers, cloud services, or third parties.',
        ],
      ),
      const _LegalSection(
        icon: Icons.storage_rounded,
        title: '2. Data Collected',
        paragraphs: [
          'The app stores the following information only on your device:',
          '• Medication info: name, dosage, frequency, stock, expiration date, and notes',
          '• Dose records: taken, skipped, or missed dose logs with dates',
          '• App preferences: language, theme, notification settings',
          '• Notification schedules: reminder times and quiet hours',
          'The app does NOT collect:',
          '• Name, email, or phone number',
          '• Location data',
          '• Device identifiers',
          '• Usage analytics or behavioral data',
        ],
      ),
      const _LegalSection(
        icon: Icons.track_changes_rounded,
        title: '3. Purpose of Data Use',
        paragraphs: [
          'Data stored on your device is used only for:',
          '• Creating and managing your medication schedule',
          '• Sending timely dose reminders',
          '• Providing stock status and low stock alerts',
          '• Calculating and displaying adherence statistics',
          '• Keeping dose history records',
          '• Remembering your app preferences',
        ],
      ),
      const _LegalSection(
        icon: Icons.security_rounded,
        title: '4. Data Storage & Security',
        paragraphs: [
          'All data is stored in the local database on your device. Your data:',
          '• Is never transmitted over the internet',
          '• Is never backed up to any server',
          '• Is protected by your device\'s security mechanisms',
          '• Is automatically deleted when you uninstall the app',
          'The app does not require internet and works fully offline.',
        ],
      ),
      const _LegalSection(
        icon: Icons.share_rounded,
        title: '5. Data Sharing',
        paragraphs: [
          'Medication Tracker:',
          '• Does NOT share any data with third parties',
          '• Does NOT use ad networks or analytics',
          '• Does NOT sell or trade data',
          '• Does NOT include social media integration',
        ],
      ),
      const _LegalSection(
        icon: Icons.phonelink_lock_rounded,
        title: '6. App Permissions',
        paragraphs: [
          'The app only requests:',
          '• Notification permission: For medication reminders. Optional.',
          '• Exact Alarm: Required on Android for timely notifications.',
          'The app does NOT request camera, microphone, location, contacts, or other sensitive permissions.',
        ],
      ),
      const _LegalSection(
        icon: Icons.child_care_rounded,
        title: '7. Children\'s Privacy',
        paragraphs: [
          'Since the app does not collect any personal information, there are no additional privacy concerns for children. Parents can safely use this app to track their children\'s medications.',
        ],
      ),
      const _LegalSection(
        icon: Icons.gavel_rounded,
        title: '8. User Rights',
        paragraphs: [
          'Since all data is stored on your device:',
          '• Access: View all your data within the app',
          '• Correction: Edit your information anytime',
          '• Deletion: Delete medications or uninstall to remove all data',
          '• Portability: Use device backup tools',
        ],
      ),
      const _LegalSection(
        icon: Icons.mail_outline_rounded,
        title: '9. Contact',
        paragraphs: [
          'For questions about our privacy policy, contact us at destek@ilactakip.app.',
        ],
      ),
    ];
  }

  List<_LegalSection> _termsSections(AppLocalizations l10n) {
    final isTr = l10n.locale.languageCode == 'tr';

    if (isTr) {
      return [
        const _LegalSection(
          icon: Icons.handshake_rounded,
          title: '1. Koşulların Kabulü',
          initiallyExpanded: true,
          paragraphs: [
            'İlaç Takip uygulamasını indirerek, yükleyerek veya kullanarak bu Kullanım Koşullarını kabul etmiş olursunuz. Bu koşulları kabul etmiyorsanız, lütfen uygulamayı kullanmayınız.',
          ],
        ),
        const _LegalSection(
          icon: Icons.apps_rounded,
          title: '2. Hizmet Tanımı',
          paragraphs: [
            'İlaç Takip uygulaması aşağıdaki hizmetleri sunar:',
            '• İlaç bilgilerinin kaydedilmesi ve yönetilmesi',
            '• Doz hatırlatıcıları ve zamanlı bildirimler',
            '• Doz alım kayıtlarının tutulması',
            '• İlaç stok takibi ve düşük stok uyarıları',
            '• İlaç uyum istatistiklerinin görüntülenmesi',
            'Uygulama tamamen ücretsizdir ve uygulama içi satın alım içermez.',
          ],
        ),
        const _LegalSection(
          icon: Icons.person_rounded,
          title: '3. Kullanıcı Yükümlülükleri',
          paragraphs: [
            'Uygulamayı kullanırken şunları kabul edersiniz:',
            '• Girdiğiniz ilaç bilgilerinin doğruluğundan siz sorumlusunuz',
            '• Uygulamayı yalnızca yasal amaçlarla kullanacaksınız',
            '• Tersine mühendislik veya modifiye etme girişiminde bulunmayacaksınız',
            '• Uygulamayı başka bir uygulama içinde yeniden dağıtmayacaksınız',
            '• Cihazınızın güvenliğini sağlamak sizin sorumluluğunuzdadır',
          ],
        ),
        const _LegalSection(
          icon: Icons.medical_services_rounded,
          title: '4. Tıbbi Sorumluluk Reddi',
          paragraphs: [
            'Bu bölüm çok önemlidir. Lütfen dikkatlice okuyun.',
            '• Uygulama tıbbi bir cihaz değildir ve tıbbi cihaz olarak onaylanmamıştır',
            '• Tıbbi tavsiye sağlamaz; yalnızca bir hatırlatma ve takip aracıdır',
            '• Doktor veya eczacı yerine geçmez',
            '• Hatırlatmaların zamanında ulaşacağını garanti etmez',
            'Acil durumlarda uygulamaya değil, derhal 112 veya en yakın sağlık kuruluşuna başvurun.',
            'İlaçlarınızla ilgili herhangi bir değişiklik yapmadan önce mutlaka doktorunuza danışın.',
          ],
        ),
        const _LegalSection(
          icon: Icons.copyright_rounded,
          title: '5. Fikri Mülkiyet',
          paragraphs: [
            'Uygulama ve içeriği (tasarım, kod, grafikler, simgeler ve metin) geliştiricinin fikri mülkiyetidir ve telif hakkı yasaları ile korunmaktadır.',
            'Kullanıcıya, uygulamayı kişisel ve ticari olmayan amaçlarla kullanmak üzere sınırlı, devredilemez bir lisans verilir.',
          ],
        ),
        const _LegalSection(
          icon: Icons.warning_amber_rounded,
          title: '6. Garanti Reddi',
          paragraphs: [
            'Uygulama "olduğu gibi" ve "mevcut haliyle" sunulmaktadır. Geliştirici:',
            '• Uygulamanın kesintisiz veya hatasız çalışacağını garanti etmez',
            '• Bildirimlerin her zaman zamanında ulaşacağını garanti etmez',
            '• Belirli bir amaca uygunluk garantisi vermez',
            '• Veri kaybına karşı garanti vermez',
          ],
        ),
        const _LegalSection(
          icon: Icons.shield_rounded,
          title: '7. Sorumluluk Sınırlaması',
          paragraphs: [
            'Geliştirici aşağıdaki durumlardan kaynaklanan zararlardan sorumlu tutulamaz:',
            '• Uygulamanın kullanımı veya kullanılamaması',
            '• Bildirimlerin gecikmesi veya ulaşmaması',
            '• Hatalı veri girişi veya hesaplama',
            '• Veri kaybı',
            '• İlaç kullanımından kaynaklanan sağlık sorunları',
          ],
        ),
        const _LegalSection(
          icon: Icons.cancel_rounded,
          title: '8. Fesih',
          paragraphs: [
            'Bu koşulları ihlal etmeniz durumunda, uygulamayı kullanma hakkınız otomatik olarak sona erer.',
            'Uygulamayı istediğiniz zaman cihazınızdan kaldırarak kullanımı sonlandırabilirsiniz. Tüm yerel verileriniz silinir.',
          ],
        ),
        const _LegalSection(
          icon: Icons.balance_rounded,
          title: '9. Uygulanacak Hukuk',
          paragraphs: [
            'Bu Kullanım Koşulları, Türkiye Cumhuriyeti yasalarına tabi olup, bu yasalara göre yorumlanacaktır.',
            'Uygulama, 6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) ve ilgili mevzuata uygun olarak geliştirilmiştir.',
          ],
        ),
        const _LegalSection(
          icon: Icons.mail_outline_rounded,
          title: '10. İletişim',
          paragraphs: [
            'Bu Kullanım Koşulları hakkında sorularınız için bize destek@ilactakip.app adresinden ulaşabilirsiniz.',
          ],
        ),
      ];
    }

    return [
      const _LegalSection(
        icon: Icons.handshake_rounded,
        title: '1. Acceptance of Terms',
        initiallyExpanded: true,
        paragraphs: [
          'By downloading, installing, or using Medication Tracker ("App"), you agree to these Terms of Service. If you do not agree, please do not use the App.',
        ],
      ),
      const _LegalSection(
        icon: Icons.apps_rounded,
        title: '2. Service Description',
        paragraphs: [
          'Medication Tracker provides:',
          '• Medication recording and management',
          '• Dose reminders and timed notifications',
          '• Dose intake logging',
          '• Medication stock tracking and low stock alerts',
          '• Adherence statistics',
          'The app is completely free with no in-app purchases.',
        ],
      ),
      const _LegalSection(
        icon: Icons.person_rounded,
        title: '3. User Obligations',
        paragraphs: [
          'By using the App, you agree to:',
          '• Take responsibility for the accuracy of medication data you enter',
          '• Use the App only for lawful purposes',
          '• Not attempt reverse engineering or modification',
          '• Not redistribute the App within another application',
          '• Maintain the security of your device',
        ],
      ),
      const _LegalSection(
        icon: Icons.medical_services_rounded,
        title: '4. Medical Disclaimer',
        paragraphs: [
          'This section is very important. Please read carefully.',
          '• The App is NOT a medical device and is not approved as one',
          '• It does NOT provide medical advice; it is only a reminder tool',
          '• It does NOT replace a doctor or pharmacist',
          '• It does NOT guarantee timely delivery of reminders',
          'In emergencies, contact emergency services immediately, not the App.',
          'Always consult your doctor before making any changes to your medications.',
        ],
      ),
      const _LegalSection(
        icon: Icons.copyright_rounded,
        title: '5. Intellectual Property',
        paragraphs: [
          'The App and its content (design, code, graphics, icons, and text) are the intellectual property of the developer and protected by copyright laws.',
          'Users are granted a limited, non-transferable license to use the App for personal, non-commercial purposes.',
        ],
      ),
      const _LegalSection(
        icon: Icons.warning_amber_rounded,
        title: '6. Disclaimer of Warranties',
        paragraphs: [
          'The App is provided "as is" and "as available". The developer:',
          '• Does not guarantee uninterrupted or error-free operation',
          '• Does not guarantee timely delivery of notifications',
          '• Makes no warranty of fitness for a particular purpose',
          '• Does not guarantee against data loss',
        ],
      ),
      const _LegalSection(
        icon: Icons.shield_rounded,
        title: '7. Limitation of Liability',
        paragraphs: [
          'The developer shall not be liable for damages arising from:',
          '• Use or inability to use the App',
          '• Delay or failure of notifications',
          '• Incorrect data entry or calculations',
          '• Data loss',
          '• Health issues from medication use',
        ],
      ),
      const _LegalSection(
        icon: Icons.cancel_rounded,
        title: '8. Termination',
        paragraphs: [
          'Violation of these terms automatically terminates your right to use the App.',
          'You may terminate use at any time by uninstalling the App. All local data will be deleted.',
        ],
      ),
      const _LegalSection(
        icon: Icons.balance_rounded,
        title: '9. Governing Law',
        paragraphs: [
          'These Terms of Service are governed by the laws of the Republic of Turkey.',
          'The App is developed in compliance with the Personal Data Protection Law (KVKK) No. 6698.',
        ],
      ),
      const _LegalSection(
        icon: Icons.mail_outline_rounded,
        title: '10. Contact',
        paragraphs: [
          'For questions about these Terms of Service, contact us at destek@ilactakip.app.',
        ],
      ),
    ];
  }
}

class _LegalSection {
  final IconData icon;
  final String title;
  final List<String> paragraphs;
  final bool initiallyExpanded;

  const _LegalSection({
    required this.icon,
    required this.title,
    required this.paragraphs,
    this.initiallyExpanded = false,
  });
}
