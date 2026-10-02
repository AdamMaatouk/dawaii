import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/health_reading.dart';
import '../../services/app_data.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'add_reading_sheet.dart';
import 'health_screen.dart';
import 'health_ui.dart';

/// "My health" on the Progress tab: latest blood pressure and sugar, with
/// a quick "+" to log a new one and a tap to open the full history.
class HealthCard extends StatelessWidget {
  const HealthCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen directly: this card is const, so a parent rebuild alone would
    // not refresh it after a new reading is saved.
    return ListenableBuilder(
      listenable: AppData(),
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.myHealth,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Tile(type: ReadingType.bloodPressure)),
              const SizedBox(width: 10),
              Expanded(child: _Tile(type: ReadingType.bloodSugar)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final ReadingType type;

  const _Tile({required this.type});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = context.palette;
    final fmt = Formatters(l);
    HealthReading? latest;
    for (final r in AppData().readings) {
      if (r.type == type) {
        latest = r;
        break;
      }
    }
    final bp = type == ReadingType.bloodPressure;

    return Material(
      color: palette.innerSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => HealthScreen(initialType: type)),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    bp ? Icons.favorite_rounded : Icons.water_drop_rounded,
                    color: bp ? palette.danger : palette.accent,
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      bp ? l.bloodPressure : l.bloodSugar,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: bp ? l.addBloodPressure : l.addBloodSugar,
                    onPressed: () => showAddReadingSheet(context, type),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              if (latest == null)
                Text(
                  l.tapToAdd,
                  style: TextStyle(fontSize: 15, color: palette.textMuted),
                )
              else ...[
                Text(
                  readingValue(latest),
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                LevelChip(level: latest.level),
                const SizedBox(height: 4),
                Text(
                  fmt.since(latest.at, DateTime.now()),
                  style: TextStyle(fontSize: 13, color: palette.textMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
