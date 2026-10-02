import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../l10n/app_localizations.dart';
import '../../models/pill_model.dart';
import '../../services/app_data.dart';
import '../../services/dose_actions.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/pill_shape_widget.dart';
import '../../widgets/responsive_center.dart';
import '../medication_form/add_medication_wizard.dart';
import 'medication_screen.dart';

/// Every medication, active and paused, with a clear "Add medication"
/// button.
class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  final AppData _data = AppData();
  bool _showFab = true;

  @override
  void initState() {
    super.initState();
    _data.addListener(_onData);
  }

  @override
  void dispose() {
    _data.removeListener(_onData);
    super.dispose();
  }

  void _onData() {
    if (mounted) setState(() {});
  }

  Future<void> _add() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddMedicationWizard()));
    await _data.reload();
  }

  Future<void> _open(PillModel pill) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MedicationScreen(pillId: pill.id)),
    );
  }

  Future<void> _resume(PillModel pill) async {
    final l = AppLocalizations.of(context);
    try {
      await DoseActions().setPaused(pill, false);
      await _data.reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.unableResume)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final active = _data.pills.where((p) => p.isActive).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final paused = _data.pills.where((p) => !p.isActive).toList();

    Widget header(String text) => Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 16, 4, 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: palette.textSecondary,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.medicinesTitle)),
      floatingActionButton: _data.pills.isEmpty
          ? null
          : AnimatedSlide(
              duration: const Duration(milliseconds: 200),
              offset: _showFab ? Offset.zero : const Offset(0, 2),
              child: FloatingActionButton.extended(
                onPressed: _add,
                icon: const Icon(Icons.add_rounded, size: 28),
                label: Text(
                  l.addMedication,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
      body: _data.pills.isEmpty
          ? EmptyStateWidget(
              icon: Icons.medication_rounded,
              title: l.welcomeTitle,
              message: l.welcomeBody,
              actionText: l.addFirstMedication,
              onAction: _add,
            )
          : NotificationListener<UserScrollNotification>(
              onNotification: (n) {
                final show = n.direction != ScrollDirection.reverse;
                if (n.direction != ScrollDirection.idle && show != _showFab) {
                  setState(() => _showFab = show);
                }
                return false;
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                children: [
                  ResponsiveCenter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (active.isNotEmpty) header(l.activeMedicines),
                        for (final pill in active)
                          MedicineTile(pill: pill, onTap: () => _open(pill)),
                        if (paused.isNotEmpty) header(l.pausedMedications),
                        for (final pill in paused)
                          MedicineTile(
                            pill: pill,
                            onTap: () => _open(pill),
                            onResume: () => _resume(pill),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class MedicineTile extends StatelessWidget {
  final PillModel pill;
  final VoidCallback onTap;
  final VoidCallback? onResume;

  const MedicineTile({
    super.key,
    required this.pill,
    required this.onTap,
    this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final fmt = Formatters(l);
    final color = Color(pill.colorHex);
    final stripe = color.computeLuminance() > 0.75
        ? palette.pillTrayBorder
        : color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.cardBorder),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 6, color: stripe),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Opacity(
                            opacity: pill.isActive ? 1 : 0.55,
                            child: PillVisual(pill: pill),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pill.name,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: palette.textPrimary,
                                  ),
                                ),
                                Text(
                                  fmt.doseSummary(pill),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: palette.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${fmt.frequency(pill)} • '
                                  '${pill.scheduleTimes.map(fmt.time24).join(', ')}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: palette.textMuted,
                                  ),
                                ),
                                if (pill.tracksStock) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    pill.isLowOnStock
                                        ? '${l.pillsLeft(pill.stockCount!)} • ${l.lowStockWarning}'
                                        : l.pillsLeft(pill.stockCount!),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: pill.isLowOnStock
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color: pill.isLowOnStock
                                          ? palette.warningText
                                          : palette.textSecondary,
                                    ),
                                  ),
                                ],
                                if (onResume != null) ...[
                                  const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    onPressed: onResume,
                                    icon: const Icon(Icons.play_arrow_rounded),
                                    label: Text(l.resume),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            Directionality.of(context) == TextDirection.rtl
                                ? Icons.chevron_left_rounded
                                : Icons.chevron_right_rounded,
                            color: palette.textMuted,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
