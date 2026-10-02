import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../l10n/app_localizations.dart';
import '../models/health_reading.dart';
import '../utils/formatters.dart';
import 'schedule_service.dart';
import 'settings_service.dart';
import 'storage_service.dart';

/// Builds a PDF adherence report the user can share with a doctor.
class ReportService {
  final StorageService _storage = StorageService();
  final ScheduleService _schedule = const ScheduleService();

  Future<void> shareDoctorReport({int days = 30}) async {
    final bytes = await buildReport(days: days);
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'dawaii-report-${DateTime.now().toIso8601String().split('T').first}.pdf',
    );
  }

  Future<Uint8List> buildReport({int days = 30}) async {
    var l = SettingsService().strings;
    final pills = await _storage.getPills();
    final records = await _storage.getDoseRecords();
    final allReadings = await _storage.getReadings();
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day - (days - 1));

    // Arabic needs a font with Arabic glyphs (downloaded once and cached by
    // the printing package). Medication names may be Arabic in an English
    // report too, so it is used as a fallback font either way.
    pw.Font? arabic;
    pw.Font? arabicBold;
    try {
      arabic = await PdfGoogleFonts.notoNaskhArabicRegular();
      arabicBold = await PdfGoogleFonts.notoNaskhArabicBold();
    } catch (e) {
      debugPrint('ARABIC PDF FONT UNAVAILABLE (offline?): $e');
      if (l.localeName == 'ar') l = lookupAppLocalizations(const Locale('en'));
    }
    final isArabic = l.localeName == 'ar' && arabic != null;
    final fmt = Formatters(l);

    final theme = isArabic
        ? pw.ThemeData.withFont(base: arabic, bold: arabicBold)
        : pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
            fontFallback: [?arabic],
          );

    final overall = _schedule.stats(
      pills: pills,
      records: records,
      from: from,
      now: now,
    );
    final missed = _schedule.missedDoses(
      pills: pills,
      records: records,
      from: from,
      now: now,
    );
    final pillsById = {for (final p in pills) p.id: p};
    final readings = allReadings.where((r) => !r.at.isBefore(from)).toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    final bpReadings = readings
        .where((r) => r.type == ReadingType.bloodPressure)
        .toList();
    final sugarReadings = readings
        .where((r) => r.type == ReadingType.bloodSugar)
        .toList();
    final bpSummary = HealthSummary.of(bpReadings, ReadingType.bloodPressure);
    final sugarSummary = HealthSummary.of(
      sugarReadings,
      ReadingType.bloodSugar,
    );

    PdfColor levelColor(ReadingLevel level) => switch (level) {
      ReadingLevel.normal => PdfColors.green800,
      ReadingLevel.elevated => PdfColors.orange800,
      ReadingLevel.low => PdfColors.blue800,
      _ => PdfColors.red800,
    };

    pw.Widget readingTable(List<String> headers, List<List<pw.Widget>> rows) {
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFEAF1FE),
            ),
            children: [
              for (final h in headers)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 5,
                  ),
                  child: pw.Text(
                    h,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          for (final row in rows) pw.TableRow(children: row),
        ],
      );
    }

    String percent(double? value) =>
        value == null ? '—' : '${(value * 100).round()}%';

    pw.Widget cell(String text, {bool bold = false, PdfColor? color}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: bold ? pw.FontWeight.bold : null,
              color: color,
            ),
          ),
        );

    final headerRow = pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEAF1FE)),
      children: [
        l.reportMedication,
        l.reportSchedule,
        l.reportTaken,
        l.reportSkipped,
        l.reportMissed,
        l.reportAdherence,
      ].map((t) => cell(t, bold: true)).toList(),
    );

    final rows = <pw.TableRow>[headerRow];
    for (final pill in pills) {
      final stats = _schedule.stats(
        pills: [pill],
        records: records,
        from: from,
        now: now,
      );
      rows.add(
        pw.TableRow(
          children: [
            cell('${pill.name}\n${fmt.doseSummary(pill)}'),
            cell(
              '${fmt.frequency(pill)}\n'
              '${pill.scheduleTimes.map(fmt.time24).join(', ')}',
            ),
            cell('${stats.taken}'),
            cell('${stats.skipped}'),
            cell(
              '${stats.missed}',
              color: stats.missed > 0 ? PdfColors.red800 : null,
            ),
            cell(percent(stats.adherence), bold: true),
          ],
        ),
      );
    }
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          cell(l.reportOverall, bold: true),
          cell(''),
          cell('${overall.taken}', bold: true),
          cell('${overall.skipped}', bold: true),
          cell('${overall.missed}', bold: true),
          cell(percent(overall.adherence), bold: true),
        ],
      ),
    );

    final doc = pw.Document(title: l.reportTitle, author: 'Dawaii');
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        build: (context) => [
          pw.Text(
            l.reportTitle,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(l.reportPeriod(fmt.date(from), fmt.date(now))),
          pw.Text(
            l.reportGenerated(fmt.date(now)),
            style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
          ),
          pw.SizedBox(height: 16),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(3),
              2: pw.FlexColumnWidth(1.2),
              3: pw.FlexColumnWidth(1.2),
              4: pw.FlexColumnWidth(1.2),
              5: pw.FlexColumnWidth(1.4),
            },
            children: rows,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            l.adherenceExplanation,
            style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 9),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            l.reportMissedList,
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (missed.isEmpty)
            pw.Text(l.reportNoMissed)
          else
            ...missed.map((ref) {
              final pill = pillsById[ref.pillId];
              return pw.Bullet(
                text:
                    '${fmt.date(ref.date)} • ${fmt.time24(ref.time)} — '
                    '${pill?.name ?? ''}',
              );
            }),
          // ---------------- Blood pressure ----------------
          pw.SizedBox(height: 22),
          pw.Text(
            l.bloodPressure,
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (bpReadings.isEmpty)
            pw.Text(l.reportNoReadings)
          else ...[
            pw.Text(
              l.reportBpSummary(
                bpReadings.length,
                '${bpSummary.avgSystolic!.round()}/'
                '${bpSummary.avgDiastolic!.round()}',
                bpSummary.avgPulse == null
                    ? '—'
                    : '${bpSummary.avgPulse!.round()}',
              ),
            ),
            pw.SizedBox(height: 6),
            readingTable(
              [l.reportDateTime, l.unitMmHg, l.pulse, l.reportLevel],
              [
                for (final r in bpReadings)
                  [
                    cell('${fmt.date(r.at)} • ${fmt.timeOf(r.at)}'),
                    cell('${r.systolic}/${r.diastolic}', bold: true),
                    cell(r.pulse == null ? '—' : '${r.pulse}'),
                    cell(fmt.levelName(r.level), color: levelColor(r.level)),
                  ],
              ],
            ),
          ],
          // ---------------- Blood sugar ----------------
          pw.SizedBox(height: 22),
          pw.Text(
            l.bloodSugar,
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (sugarReadings.isEmpty)
            pw.Text(l.reportNoReadings)
          else ...[
            pw.Text(
              l.reportSugarSummary(
                sugarReadings.length,
                '${sugarSummary.avgSugar!.round()}',
                '${sugarSummary.minSugar}',
                '${sugarSummary.maxSugar}',
              ),
            ),
            pw.SizedBox(height: 6),
            readingTable(
              [l.reportDateTime, l.unitMgDl, l.whenMeasured, l.reportLevel],
              [
                for (final r in sugarReadings)
                  [
                    cell('${fmt.date(r.at)} • ${fmt.timeOf(r.at)}'),
                    cell('${r.sugar}', bold: true),
                    cell(
                      r.sugarContext == null
                          ? '—'
                          : fmt.sugarContext(r.sugarContext!),
                    ),
                    cell(fmt.levelName(r.level), color: levelColor(r.level)),
                  ],
              ],
            ),
          ],
          pw.SizedBox(height: 10),
          pw.Text(
            l.reportReadingsNote,
            style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 9),
          ),
        ],
      ),
    );
    return doc.save();
  }
}
