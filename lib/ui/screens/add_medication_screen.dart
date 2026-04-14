import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ilac_takip/providers/medication_provider.dart';
import 'package:ilac_takip/models/medication.dart';
import 'package:ilac_takip/models/dosage.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';
import 'package:ilac_takip/core/utils/date_utils.dart';
import 'package:ilac_takip/core/localization/app_localizations.dart';

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
  AppLocalizations get l10n => AppLocalizations.of(context)!;
  
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
  FrequencyType _frequencyType = FrequencyType.daily;
  List<int> _weeklyDays = [];
  int _monthlyDay = 1;
  
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
      _frequencyType = med.dosage.frequencyType;
      _weeklyDays = List.from(med.dosage.weeklyDays);
      _monthlyDay = med.dosage.monthlyDay ?? 1;
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
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editMedication : l10n.addMedication),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _isLoading ? null : _handleSave,
              child: Text(l10n.save),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // İlaç adı
            _buildSectionTitle(l10n.medicationInfo),
            const SizedBox(height: 12),
            _buildNameField(),
            const SizedBox(height: 16),
            
            // Stok
            _buildStockField(),
            const SizedBox(height: 24),
            
            // Kullanım sıklığı
            _buildSectionTitle(l10n.frequency),
            const SizedBox(height: 12),
            _buildFrequencySelector(),
            const SizedBox(height: 16),
            if (_frequencyType == FrequencyType.weekly)
              _buildWeeklyDaysSelector(),
            if (_frequencyType == FrequencyType.monthly)
              _buildMonthlyDaySelector(),
            if (_frequencyType != FrequencyType.daily)
              const SizedBox(height: 16),
            
            // Dozaj bilgileri
            _buildSectionTitle(l10n.dosageInfo),
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
            _buildSectionTitle(l10n.reminderSettings),
            const SizedBox(height: 12),
            _buildReminderSwitch(),
            const SizedBox(height: 16),
            _buildThresholdSettings(),
            const SizedBox(height: 24),
            
            // Ek bilgiler
            _buildSectionTitle(l10n.additionalInfo),
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
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: context.textPrimaryClr,
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: l10n.medicationName,
        hintText: l10n.medicationNameHint,
        prefixIcon: const Icon(Icons.medication_rounded),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.required;
        }
        return null;
      },
    );
  }

  Widget _buildStockField() {
    return TextFormField(
      controller: _stockController,
      decoration: InputDecoration(
        labelText: l10n.currentStock,
        hintText: l10n.stockHint,
        prefixIcon: const Icon(Icons.inventory_2_rounded),
        suffixText: l10n.units,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n.required;
        }
        final stock = int.tryParse(value);
        if (stock == null || stock < 0) {
          return l10n.validNumber;
        }
        return null;
      },
    );
  }

  Widget _buildPillsPerDoseField() {
    return TextFormField(
      controller: _pillsPerDoseController,
      decoration: InputDecoration(
        labelText: l10n.pillsPerDose,
        hintText: '1',
        suffixText: l10n.units,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n.required;
        }
        final pills = int.tryParse(value);
        if (pills == null || pills < 1) {
          return l10n.atLeast1;
        }
        return null;
      },
    );
  }

  Widget _buildDosesPerDayField() {
    return TextFormField(
      controller: _dosesPerDayController,
      decoration: InputDecoration(
        labelText: l10n.dosesPerDay,
        hintText: '1',
        suffixText: l10n.times,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n.required;
        }
        final doses = int.tryParse(value);
        if (doses == null || doses < 1) {
          return l10n.atLeast1;
        }
        return null;
      },
    );
  }

  Widget _buildScheduleTimesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerClr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                l10n.doseTimes,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryClr,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _showTimePickerDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.addTime),
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
                  backgroundColor: AppTheme.primaryColor.withValues(
                    alpha: context.primaryAlpha,
                  ),
                  deleteIconColor: AppTheme.primaryColor,
                  labelStyle: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.noTimeAdded,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondaryClr,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFrequencySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerClr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_repeat_rounded, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                l10n.frequency,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryClr,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: FrequencyType.values.map((type) {
              final isSelected = _frequencyType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _frequencyType = type;
                    if (type == FrequencyType.weekly && _weeklyDays.isEmpty) {
                      _weeklyDays = [DateTime.now().weekday];
                    }
                  }),
                  child: Container(
                    margin: EdgeInsets.only(
                      right: type != FrequencyType.monthly ? 8 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withValues(
                              alpha: context.primaryAlpha,
                            )
                          : context.subtleBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : context.dividerClr,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getFrequencyIcon(type),
                          size: 24,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : context.textSecondaryClr,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getFrequencyLabel(type),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : context.textSecondaryClr,
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

  IconData _getFrequencyIcon(FrequencyType type) {
    switch (type) {
      case FrequencyType.daily:
        return Icons.today_rounded;
      case FrequencyType.weekly:
        return Icons.date_range_rounded;
      case FrequencyType.monthly:
        return Icons.calendar_month_rounded;
    }
  }

  String _getFrequencyLabel(FrequencyType type) {
    switch (type) {
      case FrequencyType.daily:
        return l10n.frequencyDaily;
      case FrequencyType.weekly:
        return l10n.frequencyWeekly;
      case FrequencyType.monthly:
        return l10n.frequencyMonthly;
    }
  }

  Widget _buildWeeklyDaysSelector() {
    final dayLabels = [
      l10n.monday, l10n.tuesday, l10n.wednesday, l10n.thursday,
      l10n.friday, l10n.saturday, l10n.sunday,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerClr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_view_week_rounded, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                l10n.selectDays,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryClr,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (index) {
              final weekday = index + 1;
              final isSelected = _weeklyDays.contains(weekday);
              return FilterChip(
                label: Text(dayLabels[index]),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _weeklyDays.add(weekday);
                      _weeklyDays.sort();
                    } else if (_weeklyDays.length > 1) {
                      _weeklyDays.remove(weekday);
                    }
                  });
                },
                selectedColor: AppTheme.primaryColor.withValues(
                  alpha: context.primaryAlpha,
                ),
                checkmarkColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : context.textSecondaryClr,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyDaySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerClr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                l10n.dayOfMonth,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryClr,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 31,
              itemBuilder: (context, index) {
                final day = index + 1;
                final isSelected = _monthlyDay == day;
                return GestureDetector(
                  onTap: () => setState(() => _monthlyDay = day),
                  child: Container(
                    width: 42,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : context.subtleBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : context.dividerClr,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : context.textPrimaryClr,
                      ),
                    ),
                  ),
                );
              },
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
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerClr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_rounded, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                l10n.whenToTake,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryClr,
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
                          ? AppTheme.primaryColor.withValues(
                              alpha: context.primaryAlpha,
                            )
                          : context.subtleBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : context.dividerClr,
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
                          _getIntakeTypeName(type),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : context.textSecondaryClr,
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

  String _getIntakeTypeName(IntakeType type) {
    switch (type) {
      case IntakeType.empty:
        return l10n.onEmptyStomach;
      case IntakeType.full:
        return l10n.onFullStomach;
      case IntakeType.either:
        return l10n.anytime;
    }
  }

  Widget _buildReminderSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerClr),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_rounded, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.doseReminders,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryClr,
                  ),
                ),
                Text(
                  l10n.getNotified,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecondaryClr,
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
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerClr),
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
                    Text(
                      l10n.lowStockAlert,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryClr,
                      ),
                    ),
                    Text(
                      '$_lowStockThreshold ${l10n.alertWhenLow}',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondaryClr,
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
                    Text(
                      l10n.runoutWarning,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryClr,
                      ),
                    ),
                    Text(
                      '$_firstRunoutWarningDays ${l10n.daysBeforeRunout}',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondaryClr,
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
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.dividerClr),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_rounded, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.expirationDate,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryClr,
                    ),
                  ),
                  Text(
                    _expirationDate != null
                        ? AppDateUtils.formatDate(_expirationDate!)
                        : l10n.selectDate,
                    style: TextStyle(
                      fontSize: 13,
                      color: _expirationDate != null
                          ? context.textPrimaryClr
                          : context.textSecondaryClr,
                    ),
                  ),
                ],
              ),
            ),
            if (_expirationDate != null)
              IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () => setState(() => _expirationDate = null),
                color: context.textSecondaryClr,
              ),
            Icon(Icons.chevron_right_rounded, color: context.textLightClr),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: l10n.notes,
        hintText: l10n.notesHint,
        prefixIcon: const Icon(Icons.note_rounded),
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
            : Text(_isEditing ? l10n.saveChanges : l10n.addMedication),
      ),
    );
  }

  void _showTimePickerDialog() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
        final updatedMedication = widget.medication!.copyWith(
          name: name,
          currentStock: stock,
          dosage: widget.medication!.dosage.copyWith(
            pillsPerDose: pillsPerDose,
            dosesPerDay: dosesPerDay,
            scheduleTimes: _scheduleTimes,
            frequencyType: _frequencyType,
            weeklyDays: _weeklyDays,
            monthlyDay: _frequencyType == FrequencyType.monthly ? _monthlyDay : null,
            clearMonthlyDay: _frequencyType != FrequencyType.monthly,
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
        await provider.addMedication(
          name: name,
          currentStock: stock,
          pillsPerDose: pillsPerDose,
          dosesPerDay: dosesPerDay,
          scheduleTimes: _scheduleTimes,
          frequencyType: _frequencyType,
          weeklyDays: _weeklyDays,
          monthlyDay: _frequencyType == FrequencyType.monthly ? _monthlyDay : null,
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
              _isEditing ? l10n.medicationUpdated : l10n.medicationAdded,
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
            content: Text('${l10n.error}: $e'),
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
