import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
    final pills = await _storage.getPills();
    final records = await _storage.getDoseRecords();
    final allReadings = await _storage.getReadings();
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day - (days - 1));

    // Fonts come from the app itself (no internet: the release app has no
    // internet permission). IBM Plex Sans Arabic also covers Latin text, and
    // is the fallback for Arabic medication names in an English report.
    final l = SettingsService().strings;
    final isArabic = l.localeName == 'ar';
    final arabic = pw.Font.ttf(
      await rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'),
    );
    final arabicBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf'),
    );
    final fmt = Formatters(l);

    final theme = isArabic
        ? pw.ThemeData.withFont(base: arabic, bold: arabicBold)
        : pw.ThemeData.withFont(
            base: pw.Font.ttf(
              await rootBundle.load(
                'assets/fonts/AtkinsonHyperlegibleNext-Regular.ttf',
              ),
            ),
            bold: pw.Font.ttf(
              await rootBundle.load(
                'assets/fonts/AtkinsonHyperlegibleNext-Bold.ttf',
              ),
            ),
            fontFallback: [arabic],
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

    // The PDF library only joins Arabic letters (and orders them right to
    // left) in RTL text, so any line containing Arabic is laid out RTL,
    // even inside an English report (e.g. an Arabic medication name).
    final arabicLetters = RegExp('[\u0600-\u06FF]');
    pw.TextDirection dirOf(String text) => arabicLetters.hasMatch(text)
        ? pw.TextDirection.rtl
        : pw.TextDirection.ltr;

    pw.Widget line(
      String text, {
      double size = 10,
      bool bold = false,
      PdfColor? color,
    }) => pw.Text(
      text,
      textDirection: dirOf(text),
      style: pw.TextStyle(
        // Shape Arabic with the Arabic font itself, not as a fallback.
        font: arabicLetters.hasMatch(text)
            ? (bold ? arabicBold : arabic)
            : null,
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : null,
        color: color,
      ),
    );

    pw.Widget cell(String text, {bool bold = false, PdfColor? color}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (final part in text.split('\n'))
                line(part, bold: bold, color: color),
            ],
          ),
        );
    final listSeparator = isArabic ? '، ' : ', ';

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
              '${pill.scheduleTimes.map(fmt.time24).join(listSeparator)}',
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
              // Date and name as separate pieces so an Arabic name keeps
              // its own direction inside an English line (and vice versa).
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 4,
                      height: 4,
                      margin: const pw.EdgeInsetsDirectional.only(end: 8),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.black,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    line(
                      '${fmt.date(ref.date)} • ${fmt.time24(ref.time)} — ',
                      size: 11,
                    ),
                    line(pill?.name ?? '', size: 11),
                  ],
                ),
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
