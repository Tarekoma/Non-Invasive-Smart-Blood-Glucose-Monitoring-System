// lib/features/pdf_export/pdf_service.dart
//
// PDF generation ALWAYS runs in compute() — never on the main thread.

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart' show Locale;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/utils/glucose_zone.dart';
import '../../l10n/generated/app_localizations.dart';
import '../measurements/models/measurement_model.dart';
import '../patients/models/patient_model.dart';

// ── Data transfer object ───────────────────────────────────────────────────
// Must be a top-level class so compute() can pass it across isolates.

class PdfExportData {
  const PdfExportData({
    required this.patient,
    required this.measurements,
    required this.stats,
    required this.rangeLabel,
    required this.generatedAt,
    required this.languageCode,
  });

  final PatientModel           patient;
  final List<MeasurementModel> measurements;
  final MeasurementStats       stats;
  final String                 rangeLabel;
  final DateTime               generatedAt;

  /// Drives both the report's translated strings (via
  /// `lookupAppLocalizations`) and its text direction/font — pass
  /// `Localizations.localeOf(context).languageCode` from the caller.
  final String languageCode;
}

/// Bundles [PdfExportData] with the Arabic font bytes for the isolate.
/// Font bytes must be read via `rootBundle` on the main isolate (asset
/// loading needs a platform channel) *before* entering compute(), then
/// passed in as plain bytes — this is why it's a separate record rather
/// than a field the isolate loads itself.
typedef _IsolateArgs = ({PdfExportData data, Uint8List? arabicFontBytes});

// ── Public API ─────────────────────────────────────────────────────────────

class PdfService {
  const PdfService._();

  /// Generates the report in a compute() isolate and opens the
  /// system share-sheet (WhatsApp, Email, Save to Files, etc.).
  static Future<void> export(PdfExportData data) async {
    Uint8List? arabicFontBytes;
    if (data.languageCode == 'ar') {
      final fontData =
          await rootBundle.load('assets/fonts/NotoSansArabic-Variable.ttf');
      arabicFontBytes = fontData.buffer.asUint8List();
    }

    final bytes = await compute(
      _buildPdf,
      (data: data, arabicFontBytes: arabicFontBytes),
    );
    await Printing.sharePdf(
      bytes:    bytes,
      filename: 'glucotrack_${data.patient.fullName.replaceAll(' ', '_')}.pdf',
    );
  }
}

// ── Isolate-safe builder ───────────────────────────────────────────────────
// Must be a top-level function (not a closure) for compute() to work.

Future<Uint8List> _buildPdf(_IsolateArgs args) async {
  final data = args.data;
  final l10n = lookupAppLocalizations(Locale(data.languageCode));
  final isRtl = data.languageCode == 'ar';
  final textDirection = isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;

  pw.ThemeData? theme;
  if (args.arabicFontBytes != null) {
    final arabicFont = pw.Font.ttf(args.arabicFontBytes!.buffer.asByteData());
    theme = pw.ThemeData.withFont(
      base: arabicFont,
      bold: arabicFont,
      fontFallback: [arabicFont],
    );
  }

  final doc = pw.Document(theme: theme);

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin:     const pw.EdgeInsets.all(32),
    textDirection: textDirection,
    build: (ctx) => [
      // ── Report header ────────────────────────────────────
      pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color:        _kPrimary,
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Row(
          // Row auto-mirrors child order from the MultiPage's inherited
          // Directionality — no explicit textDirection/reversal needed here.
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  l10n.pdfReportTitle,
                  textDirection: textDirection,
                  style: pw.TextStyle(
                    fontSize:   22,
                    fontWeight: pw.FontWeight.bold,
                    color:      PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  l10n.pdfPeriod(data.rangeLabel),
                  textDirection: textDirection,
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color:    PdfColors.white,
                  ),
                ),
              ],
            ),
            pw.Text(
              l10n.pdfGenerated(_fmtDt(data.generatedAt)),
              textDirection: textDirection,
              style: const pw.TextStyle(
                fontSize: 10,
                color:    PdfColors.white,
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 20),

      // ── Patient info ─────────────────────────────────────
      pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color:        _kBgLight,
          borderRadius: pw.BorderRadius.circular(8),
          border:       pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              l10n.pdfPatientInformation,
              textDirection: textDirection,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize:   14,
                color:      _kPrimary,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              // Row auto-mirrors from inherited Directionality — no manual
              // reversal needed (unlike pw.Table below, which has none).
              children: [
                _infoCell(l10n.pdfName, data.patient.fullName, textDirection),
                _infoCell(l10n.pdfAge, '${data.patient.age ?? '—'}', textDirection),
                _infoCell(l10n.pdfGender, data.patient.gender ?? '—', textDirection),
                _infoCell(
                  l10n.pdfBloodType,
                  data.patient.bloodType ?? '—',
                  textDirection,
                ),
              ],
            ),
            if (data.patient.diseaseLabels.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Text(
                l10n.pdfConditions(data.patient.diseaseLabels.join(' · ')),
                textDirection: textDirection,
                style: const pw.TextStyle(fontSize: 11),
              ),
            ],
          ],
        ),
      ),
      pw.SizedBox(height: 16),

      // ── Stats summary ────────────────────────────────────
      pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color:        _kBgLight,
          borderRadius: pw.BorderRadius.circular(8),
          border:       pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              l10n.pdfStatisticalSummary,
              textDirection: textDirection,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize:   14,
                color:      _kPrimary,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                _statCell(l10n.pdfAverage,
                    '${data.stats.average.toStringAsFixed(1)} mg/dL', textDirection),
                _statCell(l10n.pdfMin,
                    '${data.stats.min.toStringAsFixed(1)} mg/dL', textDirection),
                _statCell(l10n.pdfMax,
                    '${data.stats.max.toStringAsFixed(1)} mg/dL', textDirection),
                _statCell(l10n.pdfStdDev,
                    '±${data.stats.stdDev.toStringAsFixed(1)}', textDirection),
                _statCell(l10n.pdfTimeInRange,
                    '${data.stats.timeInRangePercent.toStringAsFixed(1)}%', textDirection),
              ],
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 16),

      // ── Readings table ───────────────────────────────────
      pw.Text(
        l10n.pdfGlucoseReadings(data.measurements.length),
        textDirection: textDirection,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize:   14,
          color:      _kPrimary,
        ),
      ),
      pw.SizedBox(height: 8),

      pw.Table(
        border: pw.TableBorder.all(
            color: PdfColors.grey300, width: 0.5),
        columnWidths: const {
          0: pw.FlexColumnWidth(2.5),
          1: pw.FlexColumnWidth(1.5),
          2: pw.FlexColumnWidth(2.0),
          3: pw.FlexColumnWidth(1.5),
          4: pw.FlexColumnWidth(1.2),
        },
        children: [
          // Header
          pw.TableRow(
            decoration:
                const pw.BoxDecoration(color: _kPrimary),
            children: _maybeReversed([
              _th(l10n.pdfDateTime, textDirection),
              _th(l10n.pdfGlucose, textDirection),
              _th(l10n.pdfZone, textDirection),
              _th(l10n.pdfBp, textDirection),
              _th(l10n.pdfHr, textDirection),
            ], isRtl),
          ),
          // Data rows (newest first)
          ...data.measurements.reversed.map(
            (m) => pw.TableRow(
              children: _maybeReversed([
                _td(_fmtDt(m.measuredAt), textDirection),
                _td(
                  '${m.glucoseMgDl.toStringAsFixed(1)} mg/dL',
                  textDirection,
                  textColor: _zoneColor(m.glucoseMgDl),
                ),
                _td(
                  GlucoseZoneHelper.label(
                    GlucoseZoneHelper.fromValue(m.glucoseMgDl),
                    l10n,
                  ),
                  textDirection,
                  textColor: _zoneColor(m.glucoseMgDl),
                ),
                _td(
                  m.hasBp ? '${m.bpSystolic}/${m.bpDiastolic}' : '—',
                  textDirection,
                ),
                _td(
                  m.heartRateBpm != null ? '${m.heartRateBpm} bpm' : '—',
                  textDirection,
                ),
              ], isRtl),
            ),
          ),
        ],
      ),
    ],
  ));

  return doc.save();
}

/// Reverses column/cell order for RTL reports — `pw.*` widgets (unlike
/// Flutter's) don't auto-mirror for RTL locales, so header/row order must
/// be flipped explicitly to read right-to-left.
List<T> _maybeReversed<T>(List<T> items, bool reverse) =>
    reverse ? items.reversed.toList() : items;

// ── Top-level constants ────────────────────────────────────────────────────

const _kPrimary = PdfColor.fromInt(0xFF1A73E8);
const _kBgLight = PdfColor.fromInt(0xFFF8F9FA);

// ── Top-level pure helpers ─────────────────────────────────────────────────
// These MUST be top-level (not nested inside _buildPdf) because:
// 1. They are called from within the isolate spawned by compute().
// 2. Dart closures over mutable state cannot be transferred across isolates.

PdfColor _zoneColor(double g) {
  if (g < 70)   return const PdfColor.fromInt(0xFFEA4335); // danger
  if (g <= 140) return const PdfColor.fromInt(0xFF34A853); // success
  if (g <= 200) return const PdfColor.fromInt(0xFFFBBC04); // warning
  return const PdfColor.fromInt(0xFFEA4335);               // danger
}

String _fmtDt(DateTime dt) =>
    '${dt.year}-${_p(dt.month)}-${_p(dt.day)} '
    '${_p(dt.hour)}:${_p(dt.minute)}';

String _p(int n) => n.toString().padLeft(2, '0');

// ── Table cell helpers ─────────────────────────────────────────────────────

pw.Widget _th(String text, pw.TextDirection dir) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
          horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textDirection: dir,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize:   10,
          color:      PdfColors.white,
        ),
      ),
    );

pw.Widget _td(
  String   text,
  pw.TextDirection dir, {
  PdfColor textColor = PdfColors.black,
}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
          horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        textDirection: dir,
        style: pw.TextStyle(fontSize: 9, color: textColor),
      ),
    );

pw.Widget _infoCell(String label, String value, pw.TextDirection dir) =>
    pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            textDirection: dir,
            style: const pw.TextStyle(
                fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text(
            value,
            textDirection: dir,
            style: pw.TextStyle(
                fontSize:   11,
                fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );

pw.Widget _statCell(String label, String value, pw.TextDirection dir) =>
    pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            textDirection: dir,
            style: const pw.TextStyle(
                fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text(
            value,
            textDirection: dir,
            style: pw.TextStyle(
              fontSize:   12,
              fontWeight: pw.FontWeight.bold,
              color:      _kPrimary,
            ),
          ),
        ],
      ),
    );
