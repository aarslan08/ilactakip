import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ilac_takip/providers/medication_provider.dart';
import 'package:ilac_takip/models/medication.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/core/utils/date_utils.dart';

/// İlaç ekleme/düzenleme ekranı
class AddMedicationScreen extends StatefulWidget {
  final Medication? medication;

  const AddMedicationScreen({
    super.key,
    this.medication,
  });

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _stockController;
  late TextEditingController _pillsPerDoseController;
  late TextEditingController _dosesPerDayController;
  late TextEditingController _notesController;
  
  List<String> _scheduleTimes = [];
  DateTime? _expirationDate;
  bool _perDoseReminders = true;
  int _lowStockThreshold = 5;
  int _firstRunoutWarningDays = 5;
  IntakeType _intakeType = IntakeType.either;
  
  bool _isLoading = false;

  bool get _isEditing => widget.medication != null;

  @override
  void initState() {
    super.initState();
    
    final med = widget.medication;
    
    _nameController = TextEditingController(text: med?.name ?? '');
    _stockController = TextEditingController(
      text: med?.currentStock.toString() ?? '',
    );
    _pillsPerDoseController = TextEditingController(
      text: med?.dosage.pillsPerDose.toString() ?? '1',
    );
    _dosesPerDayController = TextEditingController(
      text: med?.dosage.dosesPerDay.toString() ?? '1',
    );
    _notesController = TextEditingController(text: med?.notes ?? '');
    
    if (med != null) {
      _scheduleTimes = List.from(med.dosage.scheduleTimes);
      _expirationDate = med.expirationDate;
      _perDoseReminders = med.perDoseReminders;
      _lowStockThreshold = med.lowStockThreshold;
      _firstRunoutWarningDays = med.firstRunoutWarningDays;
      _intakeType = med.intakeType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _pillsPerDoseController.dispose();
    _dosesPerDayController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_isEditing ? 'İlacı Düzenle' : 'Yeni İlaç Ekle'),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _isLoading ? null : _handleSave,
              child: const Text('Kaydet'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // İlaç adı
            _buildSectionTitle('İlaç Bilgileri'),
            const SizedBox(height: 12),
            _buildNameField(),
            const SizedBox(height: 16),
            
            // Stok
            _buildStockField(),
            const SizedBox(height: 24),
            
            // Dozaj bilgileri
            _buildSectionTitle('Dozaj Bilgileri'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildPillsPerDoseField()),
                const SizedBox(width: 16),
                Expanded(child: _buildDosesPerDayField()),
              ],
            ),
            const SizedBox(height: 16),
            
            // Saat seçimi
            _buildScheduleTimesSection(),
            const SizedBox(height: 16),
            
            // Aç/Tok seçimi
            _buildIntakeTypeSection(),
            const SizedBox(height: 24),
            
            // Hatırlatma ayarları
            _buildSectionTitle('Hatırlatma Ayarları'),
            const SizedBox(height: 12),
            _buildReminderSwitch(),
            const SizedBox(height: 16),
            _buildThresholdSettings(),
            const SizedBox(height: 24),
            
            // Ek bilgiler
            _buildSectionTitle('Ek Bilgiler'),
            const SizedBox(height: 12),
            _buildExpirationDateField(),
            const SizedBox(height: 16),
            _buildNotesField(),
            const SizedBox(height: 32),
            
            // Kaydet butonu
            _buildSaveButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'İlaç Adı',
        hintText: 'Örn: Paracetamol 500mg',
        prefixIcon: Icon(Icons.medication_rounded),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'İlaç adı gerekli';
        }
        return null;
      },
    );
  }

  Widget _buildStockField() {
    return TextFormField(
      controller: _stockController,
      decoration: const InputDecoration(
        labelText: 'Mevcut Stok',
        hintText: 'Adet sayısı',
        prefixIcon: Icon(Icons.inventory_2_rounded),
        suffixText: 'adet',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Stok miktarı gerekli';
        }
        final stock = int.tryParse(value);
        if (stock == null || stock < 0) {
          return 'Geçerli bir sayı girin';
        }
        return null;
      },
    );
  }

  Widget _buildPillsPerDoseField() {
    return TextFormField(
      controller: _pillsPerDoseController,
      decoration: const InputDecoration(
        labelText: 'Doz Başına',
        hintText: '1',
        suffixText: 'adet',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Gerekli';
        }
        final pills = int.tryParse(value);
        if (pills == null || pills < 1) {
          return 'En az 1';
        }
        return null;
      },
    );
  }

  Widget _buildDosesPerDayField() {
    return TextFormField(
      controller: _dosesPerDayController,
      decoration: const InputDecoration(
        labelText: 'Günlük Doz',
        hintText: '1',
        suffixText: 'kez',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Gerekli';
        }
        final doses = int.tryParse(value);
        if (doses == null || doses < 1) {
          return 'En az 1';
        }
        return null;
      },
    );
  }

  Widget _buildScheduleTimesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Doz Saatleri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _showTimePickerDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Saat Ekle'),
              ),
            ],
          ),
          if (_scheduleTimes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _scheduleTimes.map((time) {
                return Chip(
                  label: Text(time),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _scheduleTimes.remove(time);
                    });
                  },
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  deleteIconColor: AppTheme.primaryColor,
                  labelStyle: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Saat eklenmedi (opsiyonel)',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIntakeTypeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.restaurant_rounded, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'Ne Zaman Alınmalı?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: IntakeType.values.map((type) {
              final isSelected = _intakeType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _intakeType = type),
                  child: Container(
                    margin: EdgeInsets.only(
                      right: type != IntakeType.either ? 8 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withValues(alpha: 0.1)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          type.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          type.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_rounded, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Doz Hatırlatıcıları',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Zamanı gelince bildirim al',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _perDoseReminders,
            onChanged: (value) {
              setState(() {
                _perDoseReminders = value;
              });
            },
            activeTrackColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Düşük stok eşiği
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.warningColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Düşük Stok Uyarısı',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '$_lowStockThreshold adet kaldığında uyar',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _lowStockThreshold > 1
                        ? () => setState(() => _lowStockThreshold--)
                        : null,
                    color: AppTheme.primaryColor,
                  ),
                  Text(
                    '$_lowStockThreshold',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(() => _lowStockThreshold++),
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          // Bitme uyarısı eşiği
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: AppTheme.accentColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bitme Uyarısı',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '$_firstRunoutWarningDays gün kala uyar',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _firstRunoutWarningDays > 1
                        ? () => setState(() => _firstRunoutWarningDays--)
                        : null,
                    color: AppTheme.primaryColor,
                  ),
                  Text(
                    '$_firstRunoutWarningDays',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(() => _firstRunoutWarningDays++),
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpirationDateField() {
    return GestureDetector(
      onTap: _showDatePicker,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_rounded, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Son Kullanma Tarihi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    _expirationDate != null
                        ? AppDateUtils.formatDate(_expirationDate!)
                        : 'Tarih seç (opsiyonel)',
                    style: TextStyle(
                      fontSize: 13,
                      color: _expirationDate != null
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (_expirationDate != null)
              IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () => setState(() => _expirationDate = null),
                color: AppTheme.textSecondary,
              ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notlar (opsiyonel)',
        hintText: 'Ek bilgiler...',
        prefixIcon: Icon(Icons.note_rounded),
        alignLabelWithHint: true,
      ),
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(_isEditing ? 'Değişiklikleri Kaydet' : 'İlaç Ekle'),
      ),
    );
  }

  void _showTimePickerDialog() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeString =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      
      if (!_scheduleTimes.contains(timeString)) {
        setState(() {
          _scheduleTimes.add(timeString);
          _scheduleTimes.sort();
        });
      }
    }
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _expirationDate = picked;
      });
    }
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<MedicationProvider>();
      
      final name = _nameController.text.trim();
      final stock = int.parse(_stockController.text);
      final pillsPerDose = int.parse(_pillsPerDoseController.text);
      final dosesPerDay = int.parse(_dosesPerDayController.text);
      final notes = _notesController.text.trim();

      if (_isEditing) {
        // Güncelle
        final updatedMedication = widget.medication!.copyWith(
          name: name,
          currentStock: stock,
          dosage: widget.medication!.dosage.copyWith(
            pillsPerDose: pillsPerDose,
            dosesPerDay: dosesPerDay,
            scheduleTimes: _scheduleTimes,
          ),
          lowStockThreshold: _lowStockThreshold,
          firstRunoutWarningDays: _firstRunoutWarningDays,
          perDoseReminders: _perDoseReminders,
          notes: notes.isNotEmpty ? notes : null,
          expirationDate: _expirationDate,
          intakeType: _intakeType,
          clearNotes: notes.isEmpty,
          clearExpirationDate: _expirationDate == null && widget.medication!.expirationDate != null,
        );

        await provider.updateMedication(updatedMedication);
      } else {
        // Yeni ekle
        await provider.addMedication(
          name: name,
          currentStock: stock,
          pillsPerDose: pillsPerDose,
          dosesPerDay: dosesPerDay,
          scheduleTimes: _scheduleTimes,
          lowStockThreshold: _lowStockThreshold,
          firstRunoutWarningDays: _firstRunoutWarningDays,
          perDoseReminders: _perDoseReminders,
          notes: notes.isNotEmpty ? notes : null,
          expirationDate: _expirationDate,
          intakeType: _intakeType,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'İlaç güncellendi' : 'İlaç eklendi',
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
