import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/pill_model.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/language_service.dart';
import '../widgets/pill_shape_widget.dart';

class AddPillScreen extends StatefulWidget {
  final PillModel? pillToEdit;

  const AddPillScreen({
    super.key,
    this.pillToEdit,
  });

  @override
  State<AddPillScreen> createState() => _AddPillScreenState();
}

class _AddPillScreenState extends State<AddPillScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _pillCountController;
  late final TextEditingController _durationController;
  late final TextEditingController _instructionsController;

  late PillShape _selectedShape;
  late int _selectedColorHex;
  late FrequencyType _selectedFrequency;

  final ImagePicker _imagePicker = ImagePicker();
  String? _selectedPhotoPath;
  String? _originalPhotoPath;
  final Set<String> _newPhotoPaths = <String>{};
  bool _didSavePill = false;

  List<TimeOfDay> _selectedTimes = [];

  List<int> _selectedDaysOfWeek = [
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  ];

  int _intervalDays = 2;

  TreatmentDurationUnit _selectedDurationUnit =
      TreatmentDurationUnit.months;

  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  final LanguageService _languageService =
      LanguageService();

  String _t(
    String key, {
    Map<String, Object?> params =
        const <String, Object?>{},
  }) {
    return _languageService.tr(
      key,
      params: params,
    );
  }

  bool get _isDarkMode =>
      Theme.of(context).brightness == Brightness.dark;

  Color get _pageBackgroundColor =>
      _isDarkMode
          ? const Color(0xFF0B1220)
          : const Color(0xFFF8FAFC);

  Color get _surfaceColor =>
      _isDarkMode
          ? const Color(0xFF172033)
          : Colors.white;

  Color get _innerSurfaceColor =>
      _isDarkMode
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC);

  Color get _primaryTextColor =>
      _isDarkMode
          ? const Color(0xFFF8FAFC)
          : const Color(0xFF0F172A);

  Color get _secondaryTextColor =>
      _isDarkMode
          ? const Color(0xFFCBD5E1)
          : const Color(0xFF64748B);

  Color get _mutedTextColor =>
      _isDarkMode
          ? const Color(0xFF94A3B8)
          : const Color(0xFF94A3B8);

  Color get _borderColor =>
      _isDarkMode
          ? const Color(0xFF334155)
          : const Color(0xFFE2E8F0);

  Color get _accentColor =>
      _isDarkMode
          ? const Color(0xFF818CF8)
          : const Color(0xFF6366F1);

  Color get _softAccentColor =>
      _isDarkMode
          ? const Color(0xFF252C52)
          : const Color(0xFFEEF2FF);

  final List<int> _colorOptions = [
    0xFF6366F1, // Indigo
    0xFF10B981, // Green
    0xFFFACC15, // Yellow
    0xFFF59E0B, // Amber
    0xFFEF4444, // Red
    0xFF9CA3AF, // Gray
    0xFFFFFFFF, // White
  ];

  Map<int, String> get _dayLabels => {
    DateTime.monday: _t('mon'),
    DateTime.tuesday: _t('tue'),
    DateTime.wednesday: _t('wed'),
    DateTime.thursday: _t('thu'),
    DateTime.friday: _t('fri'),
    DateTime.saturday: _t('sat'),
    DateTime.sunday: _t('sun'),
  };

  @override
  void initState() {
    super.initState();

    final pill = widget.pillToEdit;

    _selectedPhotoPath = pill?.photoPath;
    _originalPhotoPath = pill?.photoPath;

    _nameController = TextEditingController(
      text: pill?.name ?? '',
    );

    _dosageController = TextEditingController(
      text: pill?.dosage ?? '',
    );

    _pillCountController = TextEditingController(
      text: (pill?.pillCount ?? 1).toString(),
    );

    _selectedDurationUnit =
        pill?.treatmentDurationUnit ??
            TreatmentDurationUnit.months;

    _durationController = TextEditingController(
      text: (pill?.treatmentDurationValue ??
              (pill == null ? 1 : 12))
          .toString(),
    );

    _instructionsController = TextEditingController(
      text: pill?.instructions ?? '',
    );

    _selectedShape =
        pill?.shape ?? PillShape.capsule;

    _selectedColorHex =
        pill?.colorHex ?? 0xFF6366F1;

    _selectedFrequency =
        pill?.frequencyType ?? FrequencyType.daily;

    if (pill != null) {
      _selectedTimes = pill.scheduleTimes
          .map(_parseTime)
          .whereType<TimeOfDay>()
          .toList();

      if (pill.daysOfWeek.isNotEmpty) {
        _selectedDaysOfWeek =
            List<int>.from(pill.daysOfWeek);
      }

      if (pill.intervalDays >= 2 &&
          pill.intervalDays <= 15) {
        _intervalDays = pill.intervalDays;
      }
    }

    _nameController.addListener(_refreshPreview);
    _dosageController.addListener(_refreshPreview);
    _pillCountController.addListener(_refreshPreview);

    _sortTimes();
  }

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_refreshPreview);
    _dosageController.removeListener(_refreshPreview);
    _pillCountController.removeListener(_refreshPreview);

    _nameController.dispose();
    _dosageController.dispose();
    _pillCountController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();

    if (!_didSavePill) {
      for (final path in _newPhotoPaths) {
        _deleteFileQuietly(path);
      }
    }

    super.dispose();
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.trim().split(':');

    if (parts.length != 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return TimeOfDay(
      hour: hour,
      minute: minute,
    );
  }

  void _sortTimes() {
    _selectedTimes.sort((a, b) {
      final aMinutes =
          (a.hour * 60) + a.minute;

      final bMinutes =
          (b.hour * 60) + b.minute;

      return aMinutes.compareTo(bMinutes);
    });
  }

  bool _containsTime(TimeOfDay time) {
    return _selectedTimes.any(
      (existing) =>
          existing.hour == time.hour &&
          existing.minute == time.minute,
    );
  }

  String _pillShapeLabel(PillShape shape) {
    switch (shape) {
      case PillShape.capsule:
        return _t('capsule');

      case PillShape.tablet:
        return _t('tablet');

      case PillShape.caplet:
        return _t('caplet');

      case PillShape.softgel:
        return _t('softgel');
    }
  }

  int get _durationMax {
    switch (_selectedDurationUnit) {
      case TreatmentDurationUnit.days:
        return 365;
      case TreatmentDurationUnit.weeks:
        return 52;
      case TreatmentDurationUnit.months:
        return 12;
    }
  }

  String get _durationUnitLabel {
    switch (_selectedDurationUnit) {
      case TreatmentDurationUnit.days:
        return _t('dayUnit');
      case TreatmentDurationUnit.weeks:
        return _t('weekUnit');
      case TreatmentDurationUnit.months:
        return _t('monthUnit');
    }
  }

  DateTime _addMonthsClamped(
    DateTime date,
    int months,
  ) {
    final zeroBasedMonth =
        (date.month - 1) + months;

    final targetYear =
        date.year + (zeroBasedMonth ~/ 12);

    final targetMonth =
        (zeroBasedMonth % 12) + 1;

    final lastDayOfTargetMonth =
        DateTime(
      targetYear,
      targetMonth + 1,
      0,
    ).day;

    final targetDay =
        date.day > lastDayOfTargetMonth
            ? lastDayOfTargetMonth
            : date.day;

    return DateTime(
      targetYear,
      targetMonth,
      targetDay,
    );
  }

  DateTime _calculateTreatmentEndDate(
    DateTime baseDate,
    int value,
  ) {
    final normalizedBase = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
    );

    switch (_selectedDurationUnit) {
      case TreatmentDurationUnit.days:
        return normalizedBase.add(
          Duration(days: value - 1),
        );

      case TreatmentDurationUnit.weeks:
        return normalizedBase.add(
          Duration(days: (value * 7) - 1),
        );

      case TreatmentDurationUnit.months:
        return _addMonthsClamped(
          normalizedBase,
          value,
        ).subtract(
          const Duration(days: 1),
        );
    }
  }

  String _formatTreatmentDate(
    DateTime date,
  ) {
    final months = [
      _t('jan'),
      _t('feb'),
      _t('mar'),
      _t('apr'),
      _t('may'),
      _t('jun'),
      _t('jul'),
      _t('aug'),
      _t('sep'),
      _t('oct'),
      _t('nov'),
      _t('dec'),
    ];

    return '${months[date.month - 1]} '
        '${date.day}, ${date.year}';
  }

  void _setDurationUnit(
    TreatmentDurationUnit unit,
  ) {
    setState(() {
      _selectedDurationUnit = unit;

      final current =
          int.tryParse(
            _durationController.text.trim(),
          ) ??
          1;

      if (current > _durationMax) {
        _durationController.text =
            _durationMax.toString();
      } else if (current < 1) {
        _durationController.text = '1';
      }
    });
  }

  Future<void> _deleteFileQuietly(
    String path,
  ) async {
    try {
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Photo cleanup should never block medication actions.
    }
  }

  Future<void> _takePillPhoto() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (picked == null) {
        return;
      }

      final documentsDirectory =
          await getApplicationDocumentsDirectory();

      final photosDirectory = Directory(
        '${documentsDirectory.path}/pill_photos',
      );

      if (!await photosDirectory.exists()) {
        await photosDirectory.create(
          recursive: true,
        );
      }

      final sourceName = picked.name;
      final dotIndex = sourceName.lastIndexOf('.');
      final extension =
          dotIndex >= 0 ? sourceName.substring(dotIndex) : '.jpg';

      final savedPath =
          '${photosDirectory.path}/pill_${DateTime.now().microsecondsSinceEpoch}$extension';

      await File(picked.path).copy(savedPath);

      final previousPath = _selectedPhotoPath;

      if (previousPath != null &&
          _newPhotoPaths.contains(previousPath)) {
        await _deleteFileQuietly(previousPath);
        _newPhotoPaths.remove(previousPath);
      }

      if (!mounted) {
        await _deleteFileQuietly(savedPath);
        return;
      }

      setState(() {
        _selectedPhotoPath = savedPath;
        _newPhotoPaths.add(savedPath);
      });
    } catch (_) {
      _showMessage(
        _t('cameraError'),
      );
    }
  }

  Future<void> _removePillPhoto() async {
    final currentPath = _selectedPhotoPath;

    if (currentPath != null &&
        _newPhotoPaths.contains(currentPath)) {
      await _deleteFileQuietly(currentPath);
      _newPhotoPaths.remove(currentPath);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedPhotoPath = null;
    });
  }

  Widget _buildPillPhotoSection() {
    final photoPath = _selectedPhotoPath;
    final hasPhoto =
        photoPath != null && File(photoPath).existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('pillPhotoOptional'),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _secondaryTextColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _t('pillPhotoHelp'),
          style: TextStyle(
            fontSize: 12,
            height: 1.35,
            color: _mutedTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        if (hasPhoto)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _innerSurfaceColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _borderColor,
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(photoPath),
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return Container(
                        width: 76,
                        height: 76,
                        alignment: Alignment.center,
                        color: _softAccentColor,
                        child: Icon(
                          Icons.medication_rounded,
                          color: _accentColor,
                          size: 30,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('pillPhotoAdded'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _t('shownInsideAppOnly'),
                        style: TextStyle(
                          fontSize: 11,
                          color: _mutedTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _takePillPhoto,
                            icon: const Icon(
                              Icons.photo_camera_rounded,
                              size: 17,
                            ),
                            label: Text(_t('retake')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _accentColor,
                              side: BorderSide(
                                color: _accentColor.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _removePillPhoto,
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 17,
                            ),
                            label: Text(_t('remove')),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFE11D48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _takePillPhoto,
              icon: const Icon(
                Icons.photo_camera_rounded,
                size: 21,
              ),
              label: Text(
                _t('addPillPhoto'),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _accentColor,
                backgroundColor: _softAccentColor,
                side: BorderSide(
                  color: _accentColor.withValues(
                    alpha: 0.35,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _addTimePicker() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode:
          TimePickerEntryMode.input,
      builder: (context, child) {
        final baseTheme = Theme.of(context);

        final colorScheme = _isDarkMode
            ? const ColorScheme.dark(
                primary: Color(0xFF818CF8),
                onPrimary: Color(0xFF0B1220),
                surface: Color(0xFF172033),
                onSurface: Color(0xFFF8FAFC),
              )
            : const ColorScheme.light(
                primary: Color(0xFF6366F1),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Color(0xFF0F172A),
              );

        return Theme(
          data: baseTheme.copyWith(
            colorScheme: colorScheme,
          ),
          child:
              child ?? const SizedBox.shrink(),
        );
      },
    );

    if (!mounted || picked == null) {
      return;
    }

    if (_containsTime(picked)) {
      _showMessage(
        _t('duplicateDoseTime'),
      );
      return;
    }

    setState(() {
      _selectedTimes.add(picked);
      _sortTimes();
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _savePill() async {
    final isValid =
        _formKey.currentState?.validate() ??
            false;

    if (!isValid) {
      return;
    }

    if (_selectedTimes.isEmpty) {
      _showMessage(
        _t('needDoseTime'),
      );
      return;
    }

    if (_selectedFrequency ==
            FrequencyType.specificDays &&
        _selectedDaysOfWeek.isEmpty) {
      _showMessage(
        _t('needWeekday'),
      );
      return;
    }

    final formattedTimes =
        _selectedTimes.map((time) {
      return '${time.hour.toString().padLeft(2, '0')}:'
          '${time.minute.toString().padLeft(2, '0')}';
    }).toList();

    final treatmentDurationValue =
        int.parse(
      _durationController.text.trim(),
    );

    final existingPill =
        widget.pillToEdit;

    final startDate =
        existingPill?.startDate ??
            DateTime.now();

    // Older saved medications did not have a treatment end date.
    // When one of those is edited, start the newly chosen duration
    // from today so it cannot immediately expire because of an old
    // original start date.
    final durationBaseDate =
        existingPill != null &&
                existingPill.treatmentEndDate == null
            ? DateTime.now()
            : startDate;

    final treatmentEndDate =
        _calculateTreatmentEndDate(
      durationBaseDate,
      treatmentDurationValue,
    );

    try {
      if (widget.pillToEdit != null) {
        await _notificationService
            .cancelPillReminders(
          widget.pillToEdit!,
        );
      }

      final instructions =
          _instructionsController.text.trim();

      final pill = PillModel(
        id: widget.pillToEdit?.id ??
            DateTime.now()
                .millisecondsSinceEpoch
                .toString(),
        name: _nameController.text.trim(),
        dosage:
            _dosageController.text.trim(),
        pillCount:
            int.parse(_pillCountController.text.trim()),
        colorHex: _selectedColorHex,
        shape: _selectedShape,
        frequencyType:
            _selectedFrequency,
        scheduleTimes: formattedTimes,
        daysOfWeek:
            _selectedFrequency ==
                    FrequencyType.specificDays
                ? List<int>.from(
                    _selectedDaysOfWeek,
                  )
                : [],
        intervalDays:
            _selectedFrequency ==
                    FrequencyType.interval
                ? _intervalDays
                : 1,
        startDate:
            startDate,
        treatmentDurationUnit:
            _selectedDurationUnit,
        treatmentDurationValue:
            treatmentDurationValue,
        treatmentEndDate:
            treatmentEndDate,
        photoPath:
            _selectedPhotoPath,
        instructions:
            instructions.isEmpty
                ? null
                : instructions,
        isActive:
            widget.pillToEdit?.isActive ??
                true,
      );

      await _storageService.savePill(pill);

      if (_originalPhotoPath != null &&
          _originalPhotoPath != _selectedPhotoPath) {
        await _deleteFileQuietly(_originalPhotoPath!);
      }

      _didSavePill = true;

      if (pill.isActive) {
        await _notificationService
            .schedulePillReminder(pill);
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      _showMessage(
        _t(
        'saveMedicationError',
        params: {'error': e},
      ),
      );
    }
  }

  Widget _buildModernCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius:
            BorderRadius.circular(24),
        border: _isDarkMode
            ? Border.all(
                color: _borderColor,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF0F172A,
            ).withValues(
              alpha: _isDarkMode ? 0.12 : 0.04,
            ),
            blurRadius:
                _isDarkMode ? 10 : 20,
            offset:
                const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 12,
        top: 20,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color:
                _accentColor,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w800,
              color:
                  _primaryTextColor,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    String label,
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: _mutedTextColor,
        size: 22,
      ),
      filled: true,
      fillColor: _innerSurfaceColor,
      labelStyle: TextStyle(
        color: _secondaryTextColor,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        color: _mutedTextColor,
        fontWeight: FontWeight.w500,
      ),
      errorStyle: TextStyle(
        color: _isDarkMode
            ? const Color(0xFFFCA5A5)
            : Colors.redAccent,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: BorderSide(
          color: _borderColor,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: BorderSide(
          color: _isDarkMode
              ? _borderColor
              : Colors.transparent,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: BorderSide(
          color: _accentColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  Widget _buildNotificationPreview() {
    final medicationName = _nameController.text.trim();
    final dosage = _dosageController.text.trim();
    final pillCount = int.tryParse(
          _pillCountController.text.trim(),
        ) ??
        1;

    final displayName =
        medicationName.isEmpty ? _t('medication') : medicationName;

    final displayDosage =
        dosage.isEmpty ? _t('yourDose') : dosage;

    final pillLabel =
        pillCount == 1 ? _t('onePill') : _t(
        'pillsCount',
        params: {'count': pillCount},
      );

    final pillColor = Color(_selectedColorHex);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _innerSurfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: pillColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: PillShapeWidget(
              shape: _selectedShape,
              color: pillColor,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t(
      'timeFor',
      params: {'name': displayName},
    ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _primaryTextColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _t(
      'takeDoseBody',
      params: {
        'pillLabel': pillLabel,
        'dosage': displayDosage,
      },
    ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _t('now'),
            style: TextStyle(
              fontSize: 10,
              color: _mutedTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing =
        widget.pillToEdit != null;

    final activeThemeColor =
        Color(_selectedColorHex);

    return Scaffold(
      backgroundColor:
          _pageBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            _pageBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor:
            Colors.transparent,
        systemOverlayStyle: _isDarkMode
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor:
                    Colors.transparent,
                systemNavigationBarColor:
                    _pageBackgroundColor,
                systemNavigationBarIconBrightness:
                    Brightness.light,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor:
                    Colors.transparent,
                systemNavigationBarColor:
                    _pageBackgroundColor,
                systemNavigationBarIconBrightness:
                    Brightness.dark,
              ),
        leading: IconButton(
          icon: Icon(
            Icons
                .arrow_back_ios_new_rounded,
            color:
                _primaryTextColor,
            size: 20,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          isEditing
              ? _t('editMedication')
              : _t('addMedication'),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color:
                _primaryTextColor,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          40,
        ),
        physics:
            const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // --------------------------------------------------
              // MEDICATION INFO
              // --------------------------------------------------

              _buildSectionTitle(
                _t('medicationInfo'),
                Icons.medication_rounded,
              ),

              _buildModernCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller:
                          _nameController,
                      textInputAction:
                          TextInputAction.next,
                      style:
                          TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            _primaryTextColor,
                      ),
                      cursorColor:
                          _accentColor,
                      decoration:
                          _buildInputDecoration(
                        _t('medicationName'),
                        _t('medicationNameHint'),
                        Icons
                            .edit_note_rounded,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value
                                .trim()
                                .isEmpty) {
                          return _t('enterMedicationName');
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    TextFormField(
                      controller:
                          _dosageController,
                      textInputAction:
                          TextInputAction.next,
                      style:
                          TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            _primaryTextColor,
                      ),
                      cursorColor:
                          _accentColor,
                      decoration:
                          _buildInputDecoration(
                        _t('dosage'),
                        _t('dosageHint'),
                        Icons
                            .numbers_rounded,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value
                                .trim()
                                .isEmpty) {
                          return _t('enterDosage');
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    TextFormField(
                      controller:
                          _pillCountController,
                      keyboardType:
                          TextInputType.number,
                      textInputAction:
                          TextInputAction.next,
                      style:
                          TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            _primaryTextColor,
                      ),
                      cursorColor:
                          _accentColor,
                      decoration:
                          _buildInputDecoration(
                        _t('numberOfPills'),
                        _t('pillCountHint'),
                        Icons.medication_rounded,
                      ),
                      validator: (value) {
                        final count = int.tryParse(
                          value?.trim() ?? '',
                        );

                        if (count == null || count < 1) {
                          return _t('invalidPillCount');
                        }

                        if (count > 99) {
                          return _t('max99Pills');
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    TextFormField(
                      controller:
                          _instructionsController,
                      textInputAction:
                          TextInputAction.done,
                      style:
                          TextStyle(
                        fontSize: 15,
                        color:
                            _primaryTextColor,
                      ),
                      cursorColor:
                          _accentColor,
                      decoration:
                          _buildInputDecoration(
                        _t('instructionsOptional'),
                        _t('instructionsHint'),
                        Icons
                            .chat_bubble_outline_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              // --------------------------------------------------
              // PILL APPEARANCE
              // --------------------------------------------------

              _buildSectionTitle(
                _t('pillAppearance'),
                Icons.palette_rounded,
              ),

              _buildModernCard(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      _t('medicationType'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            _secondaryTextColor,
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    Row(
                      children:
                          PillShape.values
                              .map((shape) {
                        final isSelected =
                            _selectedShape ==
                                shape;

                        return Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 4,
                            ),
                            child:
                                GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedShape =
                                      shape;
                                });
                              },
                              child:
                                  AnimatedContainer(
                                duration:
                                    const Duration(
                                  milliseconds:
                                      180,
                                ),
                                height: 100,
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 5,
                                  vertical: 10,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color: isSelected
                                      ? activeThemeColor
                                          .withValues(
                                          alpha:
                                              0.10,
                                        )
                                      : _innerSurfaceColor,
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    18,
                                  ),
                                  border:
                                      Border.all(
                                    color: isSelected
                                        ? _accentColor
                                        : _isDarkMode
                                            ? _borderColor
                                            : Colors
                                                .transparent,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                  children: [
                                    Expanded(
                                      child:
                                          Center(
                                        child:
                                            PillShapeWidget(
                                          shape:
                                              shape,
                                          color:
                                              activeThemeColor,
                                          size:
                                              40,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height:
                                          7,
                                    ),
                                    Text(
                                      _pillShapeLabel(
                                        shape,
                                      ),
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                      style:
                                          TextStyle(
                                        fontSize:
                                            10,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                        color: isSelected
                                            ? _accentColor
                                            : _secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    Text(
                      _t('pillColor'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            _secondaryTextColor,
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children:
                          _colorOptions
                              .map(
                        (colorValue) {
                          final isSelected =
                              _selectedColorHex ==
                                  colorValue;

                          final swatchColor =
                              Color(colorValue);

                          final useDarkCheck =
                              swatchColor.computeLuminance() >
                                  0.62;

                          return Semantics(
                            button: true,
                            selected:
                                isSelected,
                            label:
                                _t('selectPillColor'),
                            child:
                                GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedColorHex =
                                      colorValue;
                                });
                              },
                              child:
                                  AnimatedContainer(
                                duration:
                                    const Duration(
                                  milliseconds:
                                      180,
                                ),
                                padding:
                                    const EdgeInsets
                                        .all(3),
                                decoration:
                                    BoxDecoration(
                                  shape:
                                      BoxShape.circle,
                                  border:
                                      Border.all(
                                    color: isSelected
                                        ? _accentColor
                                        : Colors
                                            .transparent,
                                    width: 3,
                                  ),
                                ),
                                child:
                                    Container(
                                  width: 36,
                                  height: 36,
                                  alignment:
                                      Alignment.center,
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        swatchColor,
                                    shape:
                                        BoxShape.circle,
                                    border:
                                        Border.all(
                                      color: _isDarkMode
                                          ? const Color(
                                              0xFFCBD5E1,
                                            ).withValues(
                                              alpha: 0.55,
                                            )
                                          : const Color(
                                              0xFF64748B,
                                            ).withValues(
                                              alpha: 0.55,
                                            ),
                                      width: 1.4,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons
                                              .check_rounded,
                                          color: useDarkCheck
                                              ? const Color(
                                                  0xFF0F172A,
                                                )
                                              : Colors
                                                  .white,
                                          size:
                                              20,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ).toList(),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    _buildPillPhotoSection(),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  _t('notificationPreview'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _secondaryTextColor,
                  ),
                ),
              ),

              _buildNotificationPreview(),

              // --------------------------------------------------
              // FREQUENCY
              // --------------------------------------------------

              _buildSectionTitle(
                _t('frequency'),
                Icons
                    .event_repeat_rounded,
              ),

              _buildModernCard(
                child: Column(
                  children: [
                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          SingleChildScrollView(
                        scrollDirection:
                            Axis.horizontal,
                        child:
                            SegmentedButton<
                                FrequencyType>(
                          style:
                              SegmentedButton
                                  .styleFrom(
                            selectedBackgroundColor:
                                _accentColor,
                            selectedForegroundColor:
                                Colors.white,
                            foregroundColor:
                                _secondaryTextColor,
                            backgroundColor:
                                _innerSurfaceColor,
                            side:
                                BorderSide(
                              color:
                                  _borderColor,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                16,
                              ),
                            ),
                          ),
                          segments:
                              [
                            ButtonSegment<
                                FrequencyType>(
                              value:
                                  FrequencyType
                                      .daily,
                              label:
                                  Text(
                                _t('everyDay'),
                              ),
                            ),
                            ButtonSegment<
                                FrequencyType>(
                              value:
                                  FrequencyType
                                      .specificDays,
                              label:
                                  Text(
                                _t('specificDays'),
                              ),
                            ),
                            ButtonSegment<
                                FrequencyType>(
                              value:
                                  FrequencyType
                                      .interval,
                              label:
                                  Text(
                                _t('interval'),
                              ),
                            ),
                          ],
                          selected: {
                            _selectedFrequency,
                          },
                          onSelectionChanged:
                              (selected) {
                            if (selected
                                .isEmpty) {
                              return;
                            }

                            setState(() {
                              _selectedFrequency =
                                  selected
                                      .first;
                            });
                          },
                        ),
                      ),
                    ),

                    if (_selectedFrequency ==
                        FrequencyType
                            .specificDays) ...[
                      const SizedBox(
                        height: 18,
                      ),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment:
                            WrapAlignment
                                .center,
                        children: _dayLabels
                            .entries
                            .map(
                          (entry) {
                            final isSelected =
                                _selectedDaysOfWeek
                                    .contains(
                              entry.key,
                            );

                            return FilterChip(
                              label:
                                  Text(
                                entry.value,
                              ),
                              selected:
                                  isSelected,
                              selectedColor:
                                  _softAccentColor,
                              checkmarkColor:
                                  _accentColor,
                              backgroundColor:
                                  _innerSurfaceColor,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  12,
                                ),
                              ),
                              side:
                                  BorderSide(
                                color:
                                    _borderColor,
                              ),
                              labelStyle:
                                  TextStyle(
                                color: isSelected
                                    ? _accentColor
                                    : _secondaryTextColor,
                                fontWeight:
                                    isSelected
                                        ? FontWeight
                                            .bold
                                        : FontWeight
                                            .w500,
                              ),
                              onSelected:
                                  (selected) {
                                setState(() {
                                  if (selected) {
                                    if (!_selectedDaysOfWeek
                                        .contains(
                                      entry.key,
                                    )) {
                                      _selectedDaysOfWeek
                                          .add(
                                        entry
                                            .key,
                                      );
                                    }
                                  } else {
                                    _selectedDaysOfWeek
                                        .remove(
                                      entry.key,
                                    );
                                  }

                                  _selectedDaysOfWeek
                                      .sort();
                                });
                              },
                            );
                          },
                        ).toList(),
                      ),
                    ],

                    if (_selectedFrequency ==
                        FrequencyType
                            .interval) ...[
                      const SizedBox(
                        height: 18,
                      ),

                      Wrap(
                        crossAxisAlignment:
                            WrapCrossAlignment
                                .center,
                        alignment:
                            WrapAlignment
                                .center,
                        spacing: 8,
                        children: [
                          Text(
                            _t('repeatEvery'),
                            style:
                                TextStyle(
                              fontSize:
                                  15,
                              fontWeight:
                                  FontWeight
                                      .w600,
                              color:
                                  _primaryTextColor,
                            ),
                          ),
                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal:
                                  14,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  _innerSurfaceColor,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                            ),
                            child:
                                DropdownButton<
                                    int>(
                              value:
                                  _intervalDays,
                              dropdownColor:
                                  _surfaceColor,
                              iconEnabledColor:
                                  _accentColor,
                              underline:
                                  const SizedBox
                                      .shrink(),
                              items: List
                                      .generate(
                                14,
                                (index) =>
                                    index +
                                    2,
                              )
                                  .map(
                                (value) {
                                  return DropdownMenuItem<
                                      int>(
                                    value:
                                        value,
                                    child:
                                        Text(
                                      _t(
                                  'valueDays',
                                  params: {'value': value},
                                ),
                                      style:
                                          TextStyle(
                                        fontSize:
                                            15,
                                        fontWeight:
                                            FontWeight.bold,
                                        color:
                                            _accentColor,
                                      ),
                                    ),
                                  );
                                },
                              ).toList(),
                              onChanged:
                                  (value) {
                                if (value ==
                                    null) {
                                  return;
                                }

                                setState(() {
                                  _intervalDays =
                                      value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // --------------------------------------------------
              // TREATMENT DURATION
              // --------------------------------------------------

              _buildSectionTitle(
                _t('scheduleEnd'),
                Icons.flag_rounded,
              ),

              _buildModernCard(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('treatmentDuration'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _secondaryTextColor,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _t('durationHelp'),
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: _mutedTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<
                          TreatmentDurationUnit>(
                        style:
                            SegmentedButton.styleFrom(
                          selectedBackgroundColor:
                              _accentColor,
                          selectedForegroundColor:
                              Colors.white,
                          foregroundColor:
                              _secondaryTextColor,
                          backgroundColor:
                              _innerSurfaceColor,
                          side: BorderSide(
                            color: _borderColor,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                        ),
                        segments: [
                          ButtonSegment<
                              TreatmentDurationUnit>(
                            value:
                                TreatmentDurationUnit.days,
                            label: Text(_t('days')),
                          ),
                          ButtonSegment<
                              TreatmentDurationUnit>(
                            value:
                                TreatmentDurationUnit.weeks,
                            label: Text(_t('weeks')),
                          ),
                          ButtonSegment<
                              TreatmentDurationUnit>(
                            value:
                                TreatmentDurationUnit.months,
                            label: Text(_t('months')),
                          ),
                        ],
                        selected: {
                          _selectedDurationUnit,
                        },
                        onSelectionChanged:
                            (selected) {
                          if (selected.isEmpty) {
                            return;
                          }

                          _setDurationUnit(
                            selected.first,
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller:
                          _durationController,
                      keyboardType:
                          TextInputType.number,
                      textInputAction:
                          TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter
                            .digitsOnly,
                        LengthLimitingTextInputFormatter(
                          3,
                        ),
                      ],
                      onChanged: (value) {
                        final parsed =
                            int.tryParse(value);

                        if (parsed != null &&
                            parsed > _durationMax) {
                          final clamped =
                              _durationMax
                                  .toString();

                          _durationController.value =
                              TextEditingValue(
                            text: clamped,
                            selection:
                                TextSelection.collapsed(
                              offset:
                                  clamped.length,
                            ),
                          );
                        }

                        setState(() {});
                      },
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            _primaryTextColor,
                      ),
                      cursorColor:
                          _accentColor,
                      decoration:
                          _buildInputDecoration(
                        _t('duration'),
                        _t(
                          'enterDurationRange',
                          params: {'max': _durationMax},
                        ),
                        Icons
                            .hourglass_bottom_rounded,
                      ).copyWith(
                        suffixText:
                            _durationUnitLabel,
                        suffixStyle:
                            TextStyle(
                          color:
                              _secondaryTextColor,
                          fontWeight:
                              FontWeight.w700,
                        ),
                        helperText:
                            _t(
                      'maximumDuration',
                      params: {
                        'max': _durationMax,
                        'unit': _durationUnitLabel,
                      },
                    ),
                        helperStyle:
                            TextStyle(
                          color:
                              _mutedTextColor,
                          fontSize: 12,
                        ),
                      ),
                      validator: (value) {
                        final duration =
                            int.tryParse(
                          value?.trim() ?? '',
                        );

                        if (duration == null ||
                            duration < 1) {
                          return _t(
                                'enterValueRange',
                                params: {'max': _durationMax},
                              );
                        }

                        if (duration >
                            _durationMax) {
                          return _t(
                                'maximumIs',
                                params: {
                                  'max': _durationMax,
                                  'unit': _durationUnitLabel,
                                },
                              );
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    Builder(
                      builder: (context) {
                        final enteredValue =
                            int.tryParse(
                                  _durationController
                                      .text
                                      .trim(),
                                ) ??
                                1;

                        final safeValue =
                            enteredValue
                                .clamp(
                                  1,
                                  _durationMax,
                                )
                                .toInt();

                        final existingPill =
                            widget.pillToEdit;

                        final baseDate =
                            existingPill != null &&
                                    existingPill
                                            .treatmentEndDate ==
                                        null
                                ? DateTime.now()
                                : existingPill
                                        ?.startDate ??
                                    DateTime.now();

                        final endDate =
                            _calculateTreatmentEndDate(
                          baseDate,
                          safeValue,
                        );

                        return Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                _softAccentColor,
                            borderRadius:
                                BorderRadius
                                    .circular(14),
                            border:
                                Border.all(
                              color:
                                  _borderColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons
                                    .event_available_rounded,
                                size: 20,
                                color:
                                    _accentColor,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Text(
                                  _t(
                          'scheduleEndsDate',
                          params: {
                            'date': _formatTreatmentDate(endDate),
                          },
                        ),
                                  style:
                                      TextStyle(
                                    fontSize:
                                        13,
                                    fontWeight:
                                        FontWeight.w700,
                                    color:
                                        _primaryTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // --------------------------------------------------
              // DOSE TIMES
              // --------------------------------------------------

              _buildSectionTitle(
                _t('doseTimings'),
                Icons.alarm_rounded,
              ),

              _buildModernCard(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _t('scheduledTimes'),
                            style:
                                TextStyle(
                              fontSize:
                                  14,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              color:
                                  _secondaryTextColor,
                            ),
                          ),
                        ),
                        ElevatedButton
                            .icon(
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                _softAccentColor,
                            foregroundColor:
                                _accentColor,
                            elevation: 0,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal:
                                  14,
                              vertical:
                                  10,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                            ),
                          ),
                          onPressed:
                              _addTimePicker,
                          icon:
                              const Icon(
                            Icons
                                .access_time_rounded,
                            size: 18,
                          ),
                          label:
                              Text(
                            _t('addTime'),
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    if (_selectedTimes
                        .isEmpty)
                      Text(
                        _t('noTimes'),
                        style:
                            TextStyle(
                          fontSize: 13,
                          color:
                              _mutedTextColor,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _selectedTimes
                                .map(
                          (time) {
                            return Chip(
                              backgroundColor:
                                  _innerSurfaceColor,
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal:
                                    8,
                                vertical:
                                    6,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  14,
                                ),
                              ),
                              side:
                                  BorderSide(
                                color:
                                    _borderColor,
                              ),
                              label:
                                  Text(
                                time.format(
                                  context,
                                ),
                                style:
                                    TextStyle(
                                  fontSize:
                                      14,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  color:
                                      _primaryTextColor,
                                ),
                              ),
                              deleteIcon:
                                  Icon(
                                Icons
                                    .close_rounded,
                                size: 18,
                                color:
                                    _secondaryTextColor,
                              ),
                              onDeleted:
                                  () {
                                setState(() {
                                  _selectedTimes
                                      .removeWhere(
                                    (existing) =>
                                        existing
                                                .hour ==
                                            time
                                                .hour &&
                                        existing
                                                .minute ==
                                            time
                                                .minute,
                                  );
                                });
                              },
                            );
                          },
                        ).toList(),
                      ),
                  ],
                ),
              ),

              const SizedBox(
                height: 32,
              ),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        const Color(
                            0xFF6366F1),
                    foregroundColor:
                        Colors.white,
                    elevation: 4,
                    shadowColor:
                        const Color(
                      0xFF6366F1,
                    ).withValues(
                      alpha:
                          _isDarkMode ? 0.18 : 0.35,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        20,
                      ),
                    ),
                  ),
                  onPressed: _savePill,
                  child: Text(
                    isEditing
                        ? _t('updateSchedule')
                        : _t('saveMedicationSchedule'),
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}