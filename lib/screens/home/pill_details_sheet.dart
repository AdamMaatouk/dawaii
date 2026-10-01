import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/pill_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/pill_shape_widget.dart';
import 'medication_card.dart';

enum DetailsAction { edit, togglePause, delete, refill }

DetailsAction detailsActionFromMenu(CardMenuAction action) =>
    switch (action) {
      CardMenuAction.edit => DetailsAction.edit,
      CardMenuAction.togglePause => DetailsAction.togglePause,
      CardMenuAction.delete => DetailsAction.delete,
    };

Future<DetailsAction?> showPillDetailsSheet(
  BuildContext context,
  PillModel pill,
) {
  return showModalBottomSheet<DetailsAction>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _PillDetails(pill: pill),
  );
}

class _PillDetails extends StatelessWidget {
  final PillModel pill;

  const _PillDetails({required this.pill});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final fmt = Formatters(l);

    Widget meta(IconData icon, String title, String value) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.innerSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: palette.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 14, color: palette.textMuted),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PillVisual(pill: pill, width: 92, height: 84, shapeSize: 52),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pill.name,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      Text(
                        l.doseLine(fmt.doseSummary(pill)),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (pill.instructions != null) ...[
              const SizedBox(height: 16),
              meta(
                Icons.info_outline_rounded,
                l.instructions,
                pill.instructions!,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              l.scheduleConfiguration,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            meta(Icons.repeat_rounded, l.frequency, fmt.frequency(pill)),
            const SizedBox(height: 8),
            meta(
              Icons.alarm_rounded,
              l.doseTimings,
              pill.scheduleTimes.map(fmt.time24).join('  •  '),
            ),
            const SizedBox(height: 8),
            meta(
              Icons.flag_rounded,
              l.scheduleEnds,
              pill.treatmentEndDate == null
                  ? l.ongoing
                  : fmt.date(pill.treatmentEndDate!),
            ),
            if (pill.tracksStock) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: meta(
                      Icons.inventory_2_outlined,
                      l.stock,
                      l.pillsLeft(pill.stockCount!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pop(DetailsAction.refill),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l.refill),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.warning,
                    ),
                    onPressed: () =>
                        Navigator.of(context).pop(DetailsAction.togglePause),
                    icon: Icon(
                      pill.isActive
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    label: Text(pill.isActive ? l.pause : l.resume),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pop(DetailsAction.edit),
                    icon: const Icon(Icons.edit_rounded),
                    label: Text(l.editSchedule),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: palette.danger),
                onPressed: () =>
                    Navigator.of(context).pop(DetailsAction.delete),
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(l.delete),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
