import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pill_model.dart';
import '../services/storage_service.dart';
import '../services/language_service.dart';

enum AnalyticsTimeframe {
  last7Days,
  last30Days,
  thisYear,
  allTime,
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with WidgetsBindingObserver {
  final StorageService _storageService = StorageService();
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

  List<PillModel> _pills = [];
  Map<String, String> _doseLogs = {};
  Map<String, String> _takenTimes = {};

  bool _isLoading = true;

  AnalyticsTimeframe _selectedTimeframe =
      AnalyticsTimeframe.last30Days;

  int _totalDosesCount = 0;
  int _takenDosesCount = 0;
  int _skippedDosesCount = 0;
  int _streakDays = 0;

  bool get _isDark =>
      Theme.of(context).brightness == Brightness.dark;

  Color get _pageBackground =>
      _isDark
          ? const Color(0xFF0B1220)
          : const Color(0xFFF8FAFC);

  Color get _surface =>
      _isDark
          ? const Color(0xFF172033)
          : Colors.white;

  Color get _innerSurface =>
      _isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC);

  Color get _primaryText =>
      _isDark
          ? const Color(0xFFF8FAFC)
          : const Color(0xFF0F172A);

  Color get _secondaryText =>
      _isDark
          ? const Color(0xFFCBD5E1)
          : const Color(0xFF64748B);

  Color get _mutedText =>
      _isDark
          ? const Color(0xFF94A3B8)
          : const Color(0xFF94A3B8);

  Color get _border =>
      _isDark
          ? const Color(0xFF283548)
          : const Color(0xFFE2E8F0);

  Color get _accent =>
      _isDark
          ? const Color(0xFF818CF8)
          : const Color(0xFF4F46E5);

  List<BoxShadow> get _cardShadow {
    if (_isDark) {
      return const [];
    }

    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHistoryData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      _loadHistoryData();
    }
  }

  bool _isDateInTimeframe(
    DateTime date,
  ) {
    final now = DateTime.now();
    final today =
        DateTime(now.year, now.month, now.day);

    final targetDate =
        DateTime(date.year, date.month, date.day);

    switch (_selectedTimeframe) {
      case AnalyticsTimeframe.last7Days:
        final start =
            today.subtract(const Duration(days: 6));

        return targetDate.isAfter(
              start.subtract(const Duration(days: 1)),
            ) &&
            targetDate.isBefore(
              today.add(const Duration(days: 1)),
            );

      case AnalyticsTimeframe.last30Days:
        final start =
            today.subtract(const Duration(days: 29));

        return targetDate.isAfter(
              start.subtract(const Duration(days: 1)),
            ) &&
            targetDate.isBefore(
              today.add(const Duration(days: 1)),
            );

      case AnalyticsTimeframe.thisYear:
        return targetDate.year == now.year;

      case AnalyticsTimeframe.allTime:
        return true;
    }
  }

  Future<void> _loadHistoryData() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final pills =
          await _storageService.getPills();

      final logs =
          await _storageService.getDoseLogs();

      final takenTimes =
          await _storageService.getTakenTimes();

      int total = 0;
      int taken = 0;
      int skipped = 0;

      logs.forEach(
        (key, status) {
          final parts = key.split('_');

          if (parts.isEmpty) {
            return;
          }

          final date =
              DateTime.tryParse(parts[0]);

          if (date == null ||
              !_isDateInTimeframe(date)) {
            return;
          }

          if (status == 'taken') {
            taken++;
            total++;
          } else if (status == 'skipped') {
            skipped++;
            total++;
          }
        },
      );

      int streak = 0;

      final now = DateTime.now();

      for (int i = 0; i < 365; i++) {
        final checkDate =
            DateTime(
          now.year,
          now.month,
          now.day - i,
        );

        final dateStr =
            checkDate.toIso8601String().split('T')[0];

        bool dayHasLogs = false;
        bool dayAllTaken = true;

        for (final pill in pills) {
          if (!_storageService
              .isPillScheduledForDate(
            pill,
            checkDate,
          )) {
            continue;
          }

          for (final time
              in pill.scheduleTimes) {
            final key =
                '${dateStr}_${pill.id}_$time';

            final status = logs[key];

            if (status != null) {
              dayHasLogs = true;

              if (status != 'taken') {
                dayAllTaken = false;
              }
            } else {
              dayAllTaken = false;
            }
          }
        }

        if (dayHasLogs && dayAllTaken) {
          streak++;
        } else if (i > 0 && dayHasLogs) {
          break;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _pills = pills;
        _doseLogs = logs;
        _takenTimes = takenTimes;
        _totalDosesCount = total;
        _takenDosesCount = taken;
        _skippedDosesCount = skipped;
        _streakDays = streak;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime? _getLatestTakenForPill(
    PillModel pill,
  ) {
    DateTime? latest;

    _takenTimes.forEach(
      (key, value) {
        if (!key.contains(
          '_${pill.id}_',
        )) {
          return;
        }

        final parts =
            key.split('_');

        if (parts.isEmpty) {
          return;
        }

        final doseDate =
            DateTime.tryParse(
          parts.first,
        );

        if (doseDate == null ||
            !_isDateInTimeframe(
              doseDate,
            )) {
          return;
        }

        final takenAt =
            DateTime.tryParse(value);

        if (takenAt == null) {
          return;
        }

        if (latest == null ||
            takenAt.isAfter(latest!)) {
          latest = takenAt;
        }
      },
    );

    return latest;
  }

  String _formatTakenDateTime(
    DateTime dateTime,
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

    final local =
        dateTime.toLocal();

    final hour12 =
        local.hour % 12 == 0
            ? 12
            : local.hour % 12;

    final minute =
        local.minute
            .toString()
            .padLeft(2, '0');

    final period =
        local.hour >= 12
            ? _t('pm')
            : _t('am');

    return '${months[local.month - 1]} '
        '${local.day} • '
        '$hour12:$minute $period';
  }

  double _getPillAdherence(
    PillModel pill,
  ) {
    int pillTaken = 0;
    int pillTotal = 0;

    _doseLogs.forEach(
      (key, status) {
        final parts = key.split('_');

        if (parts.isEmpty) {
          return;
        }

        final date =
            DateTime.tryParse(parts[0]);

        if (date == null ||
            !_isDateInTimeframe(date)) {
          return;
        }

        if (!key.contains('_${pill.id}_')) {
          return;
        }

        if (status == 'taken') {
          pillTaken++;
        }

        if (status == 'taken' ||
            status == 'skipped') {
          pillTotal++;
        }
      },
    );

    return pillTotal == 0
        ? 1.0
        : pillTaken / pillTotal;
  }

  String _getTimeframeLabel(
    AnalyticsTimeframe timeframe,
  ) {
    switch (timeframe) {
      case AnalyticsTimeframe.last7Days:
        return _t('last7Days');

      case AnalyticsTimeframe.last30Days:
        return _t('last30Days');

      case AnalyticsTimeframe.thisYear:
        return _t('thisYear');

      case AnalyticsTimeframe.allTime:
        return _t('allTime');
    }
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _border,
        ),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: _secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final double adherenceRate =
        _totalDosesCount == 0
            ? 0.0
            : _takenDosesCount /
                _totalDosesCount;

    final overlayStyle =
        _isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor:
                    Colors.transparent,
                systemNavigationBarColor:
                    _pageBackground,
                systemNavigationBarIconBrightness:
                    Brightness.light,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor:
                    Colors.transparent,
                systemNavigationBarColor:
                    _pageBackground,
                systemNavigationBarIconBrightness:
                    Brightness.dark,
              );

    return AnnotatedRegion<
        SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor:
            _pageBackground,
        appBar: AppBar(
          backgroundColor:
              _pageBackground,
          foregroundColor:
              _primaryText,
          surfaceTintColor:
              Colors.transparent,
          systemOverlayStyle:
              overlayStyle,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            _t('analyticsHistory'),
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
              color: _primaryText,
              fontSize: 22,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: _accent,
              ),
              onPressed:
                  _loadHistoryData,
              tooltip: _t('syncData'),
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child:
                    CircularProgressIndicator(
                  color: _accent,
                ),
              )
            : RefreshIndicator(
                color: _accent,
                onRefresh:
                    _loadHistoryData,
                child:
                    SingleChildScrollView(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  physics:
                      const AlwaysScrollableScrollPhysics(
                    parent:
                        BouncingScrollPhysics(),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration:
                            BoxDecoration(
                          color: _surface,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                          border:
                              Border.all(
                            color: _border,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons
                                      .filter_alt_rounded,
                                  size: 20,
                                  color:
                                      _accent,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  _t('timeframe'),
                                  style:
                                      TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    color:
                                        _primaryText,
                                    fontSize:
                                        14,
                                  ),
                                ),
                              ],
                            ),
                            DropdownButton<
                                AnalyticsTimeframe>(
                              value:
                                  _selectedTimeframe,
                              dropdownColor:
                                  _surface,
                              underline:
                                  const SizedBox
                                      .shrink(),
                              icon: Icon(
                                Icons
                                    .keyboard_arrow_down_rounded,
                                color:
                                    _accent,
                              ),
                              style:
                                  TextStyle(
                                color:
                                    _accent,
                                fontSize:
                                    14,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                              items:
                                  AnalyticsTimeframe
                                      .values
                                      .map(
                                (timeframe) {
                                  return DropdownMenuItem<
                                      AnalyticsTimeframe>(
                                    value:
                                        timeframe,
                                    child:
                                        Text(
                                      _getTimeframeLabel(
                                        timeframe,
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

                                setState(
                                  () {
                                    _selectedTimeframe =
                                        value;
                                  },
                                );

                                _loadHistoryData();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child:
                                _buildMetricCard(
                              icon: Icons
                                  .local_fire_department_rounded,
                              iconColor:
                                  const Color(
                                0xFFFF9100,
                              ),
                              value:
                                  _t(
                  'streakDays',
                  params: {'count': _streakDays},
                ),
                              label:
                                  _t('activeStreak'),
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child:
                                _buildMetricCard(
                              icon: Icons
                                  .pie_chart_rounded,
                              iconColor:
                                  _accent,
                              value:
                                  '${(adherenceRate * 100).round()}%',
                              label:
                                  _t('adherenceRate'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Container(
                        padding:
                            const EdgeInsets.all(
                          20,
                        ),
                        decoration:
                            BoxDecoration(
                          color: _surface,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                          border:
                              Border.all(
                            color: _border,
                          ),
                          boxShadow:
                              _cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                              children: [
                                Text(
                                  _t('doseBreakdown'),
                                  style:
                                      TextStyle(
                                    fontSize:
                                        16,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    color:
                                        _primaryText,
                                  ),
                                ),
                                Text(
                                  _getTimeframeLabel(
                                    _selectedTimeframe,
                                  ),
                                  style:
                                      TextStyle(
                                    fontSize:
                                        12,
                                    color:
                                        _mutedText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 16,
                            ),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceAround,
                              children: [
                                _buildStatItem(
                                  _t('taken'),
                                  '$_takenDosesCount',
                                  const Color(
                                    0xFF22C55E,
                                  ),
                                ),
                                _buildStatItem(
                                  _t('skipped'),
                                  '$_skippedDosesCount',
                                  const Color(
                                    0xFFEF4444,
                                  ),
                                ),
                                _buildStatItem(
                                  _t('totalLogged'),
                                  '$_totalDosesCount',
                                  const Color(
                                    0xFF3B82F6,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Text(
                        _t('medicationsAdherence'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              _primaryText,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      if (_pills.isEmpty)
                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets.all(
                            24,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                _surface,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                            border:
                                Border.all(
                              color:
                                  _border,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons
                                    .medication_outlined,
                                size: 48,
                                color:
                                    _mutedText,
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              Text(
                                _t('noSavedMedications'),
                                style:
                                    TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  color:
                                      _secondaryText,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          itemCount:
                              _pills.length,
                          itemBuilder:
                              (
                            context,
                            index,
                          ) {
                            final pill =
                                _pills[
                                    index];

                            final progress =
                                _getPillAdherence(
                              pill,
                            );

                            final color =
                                Color(
                              pill.colorHex,
                            );

                            final latestTaken =
                                _getLatestTakenForPill(
                              pill,
                            );

                            return Container(
                              margin:
                                  const EdgeInsets
                                      .only(
                                bottom: 12,
                              ),
                              padding:
                                  const EdgeInsets
                                      .all(
                                16,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    _surface,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  20,
                                ),
                                border:
                                    Border.all(
                                  color:
                                      _border,
                                ),
                                boxShadow:
                                    _cardShadow,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            color
                                                .withValues(
                                          alpha:
                                              _isDark
                                                  ? 0.20
                                                  : 0.15,
                                        ),
                                        child:
                                            Icon(
                                          Icons
                                              .medication,
                                          color:
                                              color,
                                        ),
                                      ),
                                      const SizedBox(
                                        width:
                                            12,
                                      ),
                                      Expanded(
                                        child:
                                            Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                          children: [
                                            Text(
                                              pill.name,
                                              maxLines:
                                                  1,
                                              overflow:
                                                  TextOverflow
                                                      .ellipsis,
                                              style:
                                                  TextStyle(
                                                fontWeight:
                                                    FontWeight.bold,
                                                fontSize:
                                                    16,
                                                color:
                                                    _primaryText,
                                              ),
                                            ),
                                            const SizedBox(
                                              height:
                                                  2,
                                            ),
                                            Text(
                                              _t(
                          'dosePerDay',
                          params: {
                            'dosage': pill.dosage,
                            'count': pill.scheduleTimes.length,
                          },
                        ),
                                              maxLines:
                                                  1,
                                              overflow:
                                                  TextOverflow
                                                      .ellipsis,
                                              style:
                                                  TextStyle(
                                                fontSize:
                                                    12,
                                                color:
                                                    _secondaryText,
                                              ),
                                            ),
                                            if (latestTaken !=
                                                null) ...[
                                              const SizedBox(
                                                height:
                                                    3,
                                              ),
                                              Text(
                                                _t(
                                  'lastTaken',
                                  params: {
                                    'time': _formatTakenDateTime(latestTaken),
                                  },
                                ),
                                                maxLines:
                                                    1,
                                                overflow:
                                                    TextOverflow
                                                        .ellipsis,
                                                style:
                                                    TextStyle(
                                                  fontSize:
                                                      11,
                                                  color:
                                                      _mutedText,
                                                  fontWeight:
                                                      FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      Text(
                                        '${(progress * 100).round()}%',
                                        style:
                                            TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          fontSize:
                                              16,
                                          color:
                                              color,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      8,
                                    ),
                                    child:
                                        LinearProgressIndicator(
                                      value:
                                          progress,
                                      minHeight:
                                          8,
                                      backgroundColor:
                                          _isDark
                                              ? _innerSurface
                                              : color
                                                  .withValues(
                                                  alpha:
                                                      0.12,
                                                ),
                                      valueColor:
                                          AlwaysStoppedAnimation<
                                              Color>(
                                        color,
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
              ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _secondaryText,
          ),
        ),
      ],
    );
  }
}
