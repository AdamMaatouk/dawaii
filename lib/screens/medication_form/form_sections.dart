import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_localizations.dart';
import '../../models/pill_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/big_time_picker.dart';
import '../../widgets/pill_shape_widget.dart';
import 'medication_form_controller.dart';

class ColorOption {
  final int value;
  final String Function(AppLocalizations) name;
  const ColorOption(this.value, this.name);
}

final List<ColorOption> pillColorOptions = [
  ColorOption(0xFF6366F1, (l) => l.colorIndigo),
  ColorOption(0xFF3B82F6, (l) => l.colorBlue),
  ColorOption(0xFF10B981, (l) => l.colorGreen),
  ColorOption(0xFFFACC15, (l) => l.colorYellow),
  ColorOption(0xFFF59E0B, (l) => l.colorOrange),
  ColorOption(0xFFEF4444, (l) => l.colorRed),
  ColorOption(0xFFEC4899, (l) => l.colorPink),
  ColorOption(0xFF92400E, (l) => l.colorBrown),
  ColorOption(0xFF9CA3AF, (l) => l.colorGray),
  ColorOption(0xFFFFFFFF, (l) => l.colorWhite),
];

/// Common reminder times offered as one-tap chips.
const List<TimeOfDay> quickTimes = [
  TimeOfDay(hour: 8, minute: 0),
  TimeOfDay(hour: 13, minute: 0),
  TimeOfDay(hour: 20, minute: 0),
  TimeOfDay(hour: 22, minute: 0),
];

TextStyle formInputStyle(BuildContext context) => TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: context.palette.textPrimary,
);

Widget formLabel(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Text(
    text,
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: context.palette.textSecondary,
    ),
  ),
);

void _message(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

// ============================================================
// 1. NAME
// ============================================================

class NameSection extends StatelessWidget {
  final MedicationFormController form;
  final bool autofocus;

  const NameSection({super.key, required this.form, this.autofocus = false});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final style = formInputStyle(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: form.name,
          autofocus: autofocus,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          style: style,
          decoration: InputDecoration(
            labelText: l.medicationName,
            hintText: l.medicationNameHint,
            prefixIcon: const Icon(Icons.edit_note_rounded),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? l.enterMedicationName : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: form.dosage,
          textInputAction: TextInputAction.next,
          style: style,
          decoration: InputDecoration(
            labelText: l.dosage,
            hintText: l.dosageHint,
            prefixIcon: const Icon(Icons.science_outlined),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? l.enterDosage : null,
        ),
        const SizedBox(height: 14),
        PillCountField(form: form),
        const SizedBox(height: 14),
        TextFormField(
          controller: form.instructions,
          textInputAction: TextInputAction.done,
          style: style,
          decoration: InputDecoration(
            labelText: l.instructionsOptional,
            hintText: l.instructionsHint,
            prefixIcon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
        ),
      ],
    );
  }
}

/// "Pills per dose" with big − / + buttons instead of typing.
class PillCountField extends StatelessWidget {
  final MedicationFormController form;

  const PillCountField({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;

    void change(int delta) {
      final current = int.tryParse(form.pillCount.text.trim()) ?? 1;
      final next = (current + delta).clamp(1, 99);
      form.pillCount.text = '$next';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton.filledTonal(
          tooltip: '−',
          iconSize: 30,
          style: IconButton.styleFrom(minimumSize: const Size(60, 60)),
          onPressed: () => change(-1),
          icon: const Icon(Icons.remove_rounded),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: form.pillCount,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            style: formInputStyle(context).copyWith(fontSize: 22),
            decoration: InputDecoration(labelText: l.numberOfPills),
            validator: (v) {
              final n = int.tryParse(v?.trim() ?? '');
              return n == null || n < 1 || n > 99 ? l.invalidPillCount : null;
            },
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          tooltip: '+',
          iconSize: 30,
          style: IconButton.styleFrom(
            minimumSize: const Size(60, 60),
            foregroundColor: palette.accent,
          ),
          onPressed: () => change(1),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

// ============================================================
// 2. LOOKS
// ============================================================

class LooksSection extends StatelessWidget {
  final MedicationFormController form;

  const LooksSection({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fmt = Formatters(l);
    return ListenableBuilder(
      listenable: form,
      builder: (context, _) {
        final color = Color(form.colorHex);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            formLabel(context, l.medicationType),
            Row(
              children: [
                for (final shape in PillShape.values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _SelectableTile(
                        selected: form.shape == shape,
                        label: fmt.shapeName(shape),
                        onTap: () => form.update(() => form.shape = shape),
                        child: PillShapeWidget(
                          shape: shape,
                          color: color,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            formLabel(context, l.pillColor),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final option in pillColorOptions)
                  _ColorDot(
                    color: Color(option.value),
                    name: option.name(l),
                    selected: form.colorHex == option.value,
                    onTap: () =>
                        form.update(() => form.colorHex = option.value),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            PhotoPicker(form: form),
            const SizedBox(height: 20),
            formLabel(context, l.notificationPreview),
            ReminderPreview(form: form),
          ],
        );
      },
    );
  }
}

class PhotoPicker extends StatelessWidget {
  final MedicationFormController form;

  const PhotoPicker({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;

    Future<void> pick(ImageSource source) async {
      if (!await form.pickPhoto(source) && context.mounted) {
        _message(context, l.cameraError);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        formLabel(context, l.pillPhotoOptional),
        Text(
          l.pillPhotoHelp,
          style: TextStyle(fontSize: 15, color: palette.textMuted),
        ),
        const SizedBox(height: 12),
        if (form.hasPhoto) ...[
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(form.photoPath!),
                  width: 92,
                  height: 92,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.pillPhotoAdded,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      l.shownInsideAppOnly,
                      style: TextStyle(fontSize: 14, color: palette.textMuted),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: palette.danger,
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: form.removePhoto,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(l.remove),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => pick(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_rounded),
                label: Text(l.takePhoto, textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded),
                label: Text(l.chooseFromGallery, textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ReminderPreview extends StatelessWidget {
  final MedicationFormController form;

  const ReminderPreview({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final fmt = Formatters(l);
    final name = form.name.text.trim().isEmpty
        ? l.medication
        : form.name.text.trim();
    final dosage = form.dosage.text.trim().isEmpty
        ? l.yourDose
        : form.dosage.text.trim();
    final count = int.tryParse(form.pillCount.text.trim()) ?? 1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.innerSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.pillTray,
              borderRadius: BorderRadius.circular(14),
            ),
            child: PillShapeWidget(
              shape: form.shape,
              color: Color(form.colorHex),
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.timeFor(name),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                Text(
                  l.takeDoseBody(fmt.pills(count < 1 ? 1 : count), dosage),
                  style: TextStyle(fontSize: 15, color: palette.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 3. WHEN
// ============================================================

class WhenSection extends StatelessWidget {
  final MedicationFormController form;

  const WhenSection({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final fmt = Formatters(l);

    void add(TimeOfDay time) {
      if (!form.addTime(time)) _message(context, l.duplicateDoseTime);
    }

    return ListenableBuilder(
      listenable: form,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          formLabel(context, l.frequency),
          SegmentedButton<FrequencyType>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: FrequencyType.daily,
                label: Text(l.everyDay, textAlign: TextAlign.center),
              ),
              ButtonSegment(
                value: FrequencyType.specificDays,
                label: Text(l.specificDays, textAlign: TextAlign.center),
              ),
              ButtonSegment(
                value: FrequencyType.interval,
                label: Text(l.interval, textAlign: TextAlign.center),
              ),
            ],
            selected: {form.frequency},
            onSelectionChanged: (s) =>
                form.update(() => form.frequency = s.first),
          ),
          if (form.frequency == FrequencyType.specificDays) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var day = 1; day <= 7; day++)
                  FilterChip(
                    label: Text(
                      fmt.weekdayNames[day - 1],
                      style: const TextStyle(fontSize: 17),
                    ),
                    selected: form.days.contains(day),
                    selectedColor: palette.softAccent,
                    checkmarkColor: palette.accent,
                    onSelected: (on) => form.update(
                      () => on ? form.days.add(day) : form.days.remove(day),
                    ),
                  ),
              ],
            ),
          ],
          if (form.frequency == FrequencyType.interval) ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              initialValue: form.intervalDays,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.repeatEvery),
              style: formInputStyle(context),
              dropdownColor: palette.surface,
              items: [
                for (var d = 2; d <= 30; d++)
                  DropdownMenuItem(value: d, child: Text(l.everyNDays(d))),
              ],
              onChanged: (v) {
                if (v != null) form.update(() => form.intervalDays = v);
              },
            ),
          ],
          const SizedBox(height: 22),
          formLabel(context, l.doseTimings),
          if (form.times.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                l.noTimes,
                style: TextStyle(fontSize: 16, color: palette.textMuted),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final time in form.times)
                  InputChip(
                    backgroundColor: palette.softAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    label: Text(
                      fmt.time(time.hour, time.minute),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    deleteIcon: const Icon(Icons.close_rounded, size: 24),
                    onDeleted: () => form.removeTime(time),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final time in quickTimes)
                if (!form.hasTime(time))
                  ActionChip(
                    avatar: Icon(Icons.add_rounded, color: palette.accent),
                    label: Text(
                      fmt.time(time.hour, time.minute),
                      style: const TextStyle(fontSize: 17),
                    ),
                    onPressed: () => add(time),
                  ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showBigTimePicker(context);
              if (picked != null && context.mounted) add(picked);
            },
            icon: const Icon(Icons.more_time_rounded),
            label: Text(l.addOtherTime),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 4. HOW LONG
// ============================================================

class DurationSection extends StatelessWidget {
  final MedicationFormController form;

  const DurationSection({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final fmt = Formatters(l);

    return ListenableBuilder(
      listenable: form,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChoiceCard(
            selected: form.ongoing,
            icon: Icons.all_inclusive_rounded,
            title: l.ongoingOption,
            subtitle: l.ongoingHelp,
            onTap: () => form.update(() => form.ongoing = true),
          ),
          const SizedBox(height: 10),
          _ChoiceCard(
            selected: !form.ongoing,
            icon: Icons.date_range_rounded,
            title: l.fixedDuration,
            subtitle: null,
            onTap: () => form.update(() => form.ongoing = false),
          ),
          if (!form.ongoing) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: form.duration,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    style: formInputStyle(context),
                    decoration: InputDecoration(labelText: l.duration),
                    validator: (v) => form.ongoing || form.validDuration != null
                        ? null
                        : l.enterValueRange(form.durationMax),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<TreatmentDurationUnit>(
                    initialValue: form.durationUnit,
                    isExpanded: true,
                    style: formInputStyle(context),
                    dropdownColor: palette.surface,
                    items: [
                      DropdownMenuItem(
                        value: TreatmentDurationUnit.days,
                        child: Text(l.days),
                      ),
                      DropdownMenuItem(
                        value: TreatmentDurationUnit.weeks,
                        child: Text(l.weeks),
                      ),
                      DropdownMenuItem(
                        value: TreatmentDurationUnit.months,
                        child: Text(l.months),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) form.update(() => form.durationUnit = v);
                    },
                  ),
                ),
              ],
            ),
            if (form.validDuration != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.event_available_rounded, color: palette.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.scheduleEndsDate(
                        fmt.date(form.endDate(form.validDuration!)),
                      ),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ============================================================
// 5. STOCK
// ============================================================

class StockSection extends StatelessWidget {
  final MedicationFormController form;

  const StockSection({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;

    Widget number(TextEditingController controller, String label) {
      return TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        style: formInputStyle(context),
        decoration: InputDecoration(labelText: label, errorMaxLines: 2),
        validator: (v) =>
            !form.trackStock || int.tryParse(v?.trim() ?? '') != null
            ? null
            : l.enterWholeNumber,
      );
    }

    return ListenableBuilder(
      listenable: form,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.stockHelp,
            style: TextStyle(fontSize: 16, color: palette.textSecondary),
          ),
          const SizedBox(height: 12),
          _ChoiceCard(
            selected: !form.trackStock,
            icon: Icons.not_interested_rounded,
            title: l.noStockTracking,
            subtitle: null,
            onTap: () => form.update(() => form.trackStock = false),
          ),
          const SizedBox(height: 10),
          _ChoiceCard(
            selected: form.trackStock,
            icon: Icons.inventory_2_outlined,
            title: l.trackStock,
            subtitle: null,
            onTap: () => form.update(() => form.trackStock = true),
          ),
          if (form.trackStock) ...[
            const SizedBox(height: 16),
            number(form.stock, l.pillsInBox),
            const SizedBox(height: 14),
            number(form.threshold, l.refillThreshold),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// SMALL PIECES
// ============================================================

/// A large radio-style card, easier to hit than a small switch.
class _ChoiceCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? palette.softAccent : palette.innerSurface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? palette.accent : palette.border,
                width: selected ? 2.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: palette.accent, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 15,
                            color: palette.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? palette.accent : palette.textMuted,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  final bool selected;
  final String label;
  final VoidCallback onTap;
  final Widget child;

  const _SelectableTile({
    required this.selected,
    required this.label,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? palette.softAccent : palette.innerSurface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? palette.accent : palette.border,
                width: selected ? 2.5 : 1,
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: 44, child: Center(child: child)),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? palette.accent : palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _ColorDot({
    required this.color,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: Tooltip(
        message: name,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? palette.accent : Colors.transparent,
                width: 3,
              ),
            ),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: palette.textMuted.withValues(alpha: 0.6),
                  width: 1.4,
                ),
              ),
              child: selected
                  ? Icon(
                      Icons.check_rounded,
                      color: color.computeLuminance() > 0.6
                          ? const Color(0xFF0F172A)
                          : Colors.white,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
