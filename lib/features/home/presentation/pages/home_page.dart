import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_notice.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/krl_station_locations.dart';
import '../../data/services/user_location_service.dart';
import '../../domain/entities/station_geo_point.dart';
import '../../../timetable/domain/services/platform_display.dart';
import '../controllers/next_train_controller.dart';
import '../widgets/station_located_map.dart';

/// Halaman Beranda (Screen 3 di Figma)
/// Menampilkan peta skematik berwarna, filter jalur, info stasiun terdekat,
/// dan banner aksesibilitas. Stasiun di peta bisa diklik.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.nextTrainController,
    this.locationService = const UserLocationService(),
    this.stationLocations = krlStationLocations,
  });

  final NextTrainController? nextTrainController;
  final UserLocationService locationService;
  final List<StationGeoPoint> stationLocations;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final bool _ownsNextTrainController;
  late final NextTrainController _nextTrainController;
  String? _selectedStation;
  String? _selectedStationId;
  String? _fromStation;
  String? _fromStationId;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  final Set<String> _visibleLineIds = {
    'bogor',
    'bogor_nambo',
    'cikarang_loop',
    'cikarang_east',
    'tanjung_priok',
    'tangerang',
    'rangkasbitung',
    'mrt',
    'lrt_bekasi',
    'lrt_cibubur',
    'lrt_jakarta',
  };

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _ownsNextTrainController = widget.nextTrainController == null;
    _nextTrainController = widget.nextTrainController ?? NextTrainController();
  }

  void _onNearestStationChanged(StationGeoPoint? station) {
    unawaited(_nextTrainController.loadStation(station?.name));
  }

  @override
  void dispose() {
    _sheetController.dispose();
    if (_ownsNextTrainController) _nextTrainController.dispose();
    super.dispose();
  }

  Widget _buildFilterOption(String label, List<String> lineIds, Color color) {
    final isAllSelected = lineIds.every((id) => _visibleLineIds.contains(id));

    return Theme(
      data: ThemeData(unselectedWidgetColor: AppColors.textHint),
      child: CheckboxListTile(
        key: ValueKey('home-filter-${lineIds.first}'),
        minTileHeight: 48,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        title: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        activeColor: AppColors.primaryBlue,
        value: isAllSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _visibleLineIds.addAll(lineIds);
            } else {
              _visibleLineIds.removeAll(lineIds);
            }
          });
        },
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }

  Widget _buildEndDrawer(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: ListTileTheme(
          data: const ListTileThemeData(minTileHeight: 48),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
            children: [
              // Filter Jalur (Line Filter)
              ExpansionTile(
                leading: const Icon(
                  Icons.train_rounded,
                  color: AppColors.primaryBlue,
                ),
                title: Text(
                  l10n.filterLine,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                initiallyExpanded: true,
                shape: const Border(),
                children: [
                  // Header KRL
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.homeLineKRL,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  _buildFilterOption(l10n.homeFilterBogor, [
                    'bogor',
                    'bogor_nambo',
                  ], AppColors.lineBogor),
                  _buildFilterOption(l10n.homeFilterCikarang, [
                    'cikarang_loop',
                    'cikarang_east',
                  ], AppColors.lineCikarang),
                  _buildFilterOption(l10n.homeFilterRangkas, [
                    'rangkasbitung',
                  ], AppColors.lineRangkasbitung),
                  _buildFilterOption(l10n.homeFilterTangerang, [
                    'tangerang',
                  ], AppColors.lineTangerang),
                  _buildFilterOption(l10n.homeFilterPriok, [
                    'tanjung_priok',
                  ], AppColors.lineTanjungPriok),

                  const Divider(color: AppColors.cardBorder, height: 16),

                  // Header MRT
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.homeLineMRTJ,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  _buildFilterOption(l10n.homeFilterMRTNorthSouth, [
                    'mrt',
                  ], AppColors.lineMRT),

                  const Divider(color: AppColors.cardBorder, height: 16),

                  // Header LRT Jabodebek
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.homeLineLRTJabo,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  _buildFilterOption(l10n.homeFilterLRTBekasi, [
                    'lrt_bekasi',
                  ], AppColors.lineLRTBekasi),
                  _buildFilterOption(l10n.homeFilterLRTCibubur, [
                    'lrt_cibubur',
                  ], AppColors.lineLRTCibubur),

                  const Divider(color: AppColors.cardBorder, height: 16),

                  // Header LRT Jakarta
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.homeLineLRTJakarta,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  _buildFilterOption(l10n.homeFilterLRTPegangsaan, [
                    'lrt_jakarta',
                  ], AppColors.lineLRTJakarta),

                  const SizedBox(height: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onStationSelected(String stationName) {
    setState(() {
      _selectedStation = stationName;
      _selectedStationId = null;
    });
    context.go(
      Uri(
        path: '/',
        queryParameters: {
          'selected': stationName,
          'from': ?_fromStation,
          'fromId': ?_fromStationId,
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uri = GoRouterState.of(context).uri;
    final selectedParam = uri.queryParameters['selected'];
    final selectedIdParam = uri.queryParameters['selectedId'];
    final fromParam = uri.queryParameters['from'];
    final fromIdParam = uri.queryParameters['fromId'];

    // Jika parameter URL dibersihkan, sinkronkan state lokal ke null agar pop-up tertutup
    if (selectedParam == null && _selectedStation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedStation = null;
            _selectedStationId = null;
          });
        }
      });
    }

    // Sync state if returned from search with fromParam
    if (fromParam != null &&
        (_fromStation != fromParam || _fromStationId != fromIdParam)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _fromStation = fromParam;
            _fromStationId = fromIdParam;
          });
        }
      });
    }

    if (selectedParam != null && _selectedStationId != selectedIdParam) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedStationId = selectedIdParam);
      });
    }

    final currentStation = selectedParam ?? _selectedStation;
    final currentStationId = selectedIdParam ?? _selectedStationId;

    return PopScope(
      canPop: currentStation == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (currentStation != null) {
          setState(() {
            _selectedStation = null;
            _selectedStationId = null;
          });
          context.go(
            Uri(
              path: '/',
              queryParameters: {
                'from': ?_fromStation,
                'fromId': ?_fromStationId,
              },
            ).toString(),
          );
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        endDrawer: _buildEndDrawer(context),
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header fixed: Search Bar + Filter Chips ──
              const SizedBox(height: 16),

              // ── Top Banner (Dari) ──
              if (_fromStation != null)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.startFrom(_fromStation!),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _fromStation = null;
                            _fromStationId = null;
                          });
                          context.go('/');
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          context.go(
                            Uri(
                              path: '/cari-stasiun',
                              queryParameters: {
                                'from': ?_fromStation,
                                'fromId': ?_fromStationId,
                              },
                            ).toString(),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search_rounded,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.searchStationHint,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        _scaffoldKey.currentState?.openEndDrawer();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Icon(
                          Icons.menu_rounded,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Peta Skematik (di luar ScrollView agar gesture tidak konflik) ──
              Expanded(
                child: Stack(
                  children: [
                    // Peta mengisi seluruh area tengah
                    Positioned.fill(
                      child: StationLocatedMap(
                        showColors: true,
                        selectedStation: currentStation,
                        fromStation: _fromStation,
                        visibleLineIds: _visibleLineIds,
                        onStationSelected: _onStationSelected,
                        onNearestStationChanged: _onNearestStationChanged,
                        locationService: widget.locationService,
                        stationLocations: widget.stationLocations,
                      ),
                    ),

                    // ── Panel Info Stasiun (DraggableSheet: tampilkan header saja, drag ke atas untuk detail) ──
                    if (currentStation != null)
                      DraggableScrollableSheet(
                        controller: _sheetController,
                        initialChildSize: 0.23,
                        minChildSize: 0.18,
                        maxChildSize: 1.0,
                        snap: true,
                        snapSizes: const [0.23, 0.55, 1.0],
                        builder: (context, scrollController) {
                          final topInset = MediaQuery.of(context).padding.top;
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 16,
                                  offset: const Offset(0, -4),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              controller: scrollController,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  16,
                                  topInset > 0 ? topInset + 6 : 10,
                                  16,
                                  32,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Drag handle & collapse bar
                                    GestureDetector(
                                      onTap: () {
                                        _sheetController.animateTo(
                                          0.23,
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 42,
                                              height: 5,
                                              margin: const EdgeInsets.only(
                                                bottom: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade400,
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryBlueLight,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            l10n.selectedStation,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primaryBlue,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _selectedStation = null;
                                              _selectedStationId = null;
                                            });
                                            context.go(
                                              Uri(
                                                path: '/',
                                                queryParameters: {
                                                  'from': ?_fromStation,
                                                  'fromId': ?_fromStationId,
                                                },
                                              ).toString(),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            color: AppColors.textSecondary,
                                            size: 20,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryBlue
                                                      .withValues(alpha: 0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.swap_vert_rounded,
                                                  color: AppColors.primaryBlue,
                                                  size: 22,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Flexible(
                                                child: Text(
                                                  currentStation,
                                                  style: const TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  _fromStation = currentStation;
                                                  _fromStationId =
                                                      currentStationId;
                                                  _selectedStation = null;
                                                  _selectedStationId = null;
                                                });
                                                context.go(
                                                  Uri(
                                                    path: '/',
                                                    queryParameters: {
                                                      'from': currentStation,
                                                      'fromId':
                                                          ?currentStationId,
                                                    },
                                                  ).toString(),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.surface,
                                                foregroundColor:
                                                    AppColors.primaryBlue,
                                                side: const BorderSide(
                                                  color: AppColors.primaryBlue,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 10,
                                                    ),
                                              ),
                                              child: Text(
                                                l10n.from,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              onPressed: () {
                                                if (_fromStation != null) {
                                                  context.go(
                                                    Uri(
                                                      path: '/rute',
                                                      queryParameters: {
                                                        'from':
                                                            _fromStationId ??
                                                            _fromStation!,
                                                        'to':
                                                            currentStationId ??
                                                            currentStation,
                                                      },
                                                    ).toString(),
                                                  );
                                                } else {
                                                  AppNotice.show(
                                                    context,
                                                    message:
                                                        l10n.selectFromFirst,
                                                    type: AppNoticeType.warning,
                                                  );
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.primaryBlue,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                      vertical: 10,
                                                    ),
                                              ),
                                              child: Text(
                                                l10n.to,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    const Divider(color: AppColors.cardBorder),
                                    const SizedBox(height: 12),

                                    _NextTrainBoard(
                                      controller: _nextTrainController,
                                      onDepartureTap: (dep) {
                                        final schedule = dep.schedule;
                                        final uri = Uri(
                                          path: '/departure-detail',
                                          queryParameters: {
                                            'lineType': schedule.trainType,
                                            'destination':
                                                schedule.destination ?? '',
                                            'duration': l10n
                                                .scheduleStatusUpcoming(
                                                  dep.minutesUntilDeparture,
                                                ),
                                            'platform': schedule.platform,
                                          },
                                        );
                                        context.push(uri.toString());
                                      },
                                    ),

                                    const SizedBox(height: 16),
                                    const Divider(color: AppColors.cardBorder),
                                    const SizedBox(height: 12),

                                    // ── Fasilitas Stasiun ──
                                    _StationFacilitiesSection(
                                      stationName: currentStation,
                                    ),

                                    const SizedBox(height: 16),
                                    const Divider(color: AppColors.cardBorder),
                                    const SizedBox(height: 12),

                                    // ── Informasi Stasiun ──
                                    _StationInfoSection(
                                      stationName: currentStation,
                                    ),

                                    const SizedBox(height: 16),
                                    const Divider(color: AppColors.cardBorder),
                                    const SizedBox(height: 12),

                                    // ── Panduan Pintu Keluar ──
                                    _StationExitGateSection(
                                      stationName: currentStation,
                                    ),

                                    const SizedBox(height: 16),
                                    const Divider(color: AppColors.cardBorder),
                                    const SizedBox(height: 12),

                                    // ── Customer Service & Bantuan ──
                                    _StationCustomerServiceSection(
                                      stationName: currentStation,
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),

              // ── Bottom Navigation Bar ──
              const AppBottomNavBar(currentIndex: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextTrainBoard extends StatelessWidget {
  final NextTrainController controller;
  final ValueChanged<NextTrainDeparture> onDepartureTap;

  const _NextTrainBoard({
    required this.controller,
    required this.onDepartureTap,
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final l10n = AppLocalizations.of(context)!;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          key: const Key('next-train-board'),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: controller.state == NextTrainState.success
                        ? AppColors.statusGreen
                        : AppColors.textHint,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.stationName == null
                        ? l10n.nextTrain
                        : l10n.homeNextTrainFrom(controller.stationName!),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (controller.state == NextTrainState.loading)
              const LinearProgressIndicator(
                key: Key('next-train-loading'),
                minHeight: 3,
                borderRadius: BorderRadius.all(Radius.circular(3)),
              )
            else if (controller.state == NextTrainState.idle)
              _NextTrainMessage(
                icon: Icons.location_searching_rounded,
                message: l10n.mapLocationUnconfirmed,
              )
            else if (controller.state == NextTrainState.error)
              _NextTrainMessage(
                icon: Icons.cloud_off_rounded,
                message: l10n.scheduleBackendError,
                onRetry: controller.retry,
              )
            else if (controller.state == NextTrainState.empty)
              _NextTrainMessage(
                icon: Icons.schedule_rounded,
                message: l10n.scheduleNotFound,
                onRetry: controller.retry,
              )
            else
              for (final group in controller.groups) ...[
                Padding(
                  key: ValueKey('next-train-direction-${group.nextStation}'),
                  padding: const EdgeInsets.only(top: 6, bottom: 2),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 17,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        group.nextStation,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                for (var i = 0; i < group.departures.length; i++)
                  _NextTrainRow(
                    departure: group.departures[i],
                    showDivider: i < group.departures.length - 1,
                    onTap: () => onDepartureTap(group.departures[i]),
                  ),
              ],
            if (controller.isRefreshing) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(minHeight: 2),
            ],
            if (controller.hasRefreshError)
              _NextTrainMessage(
                icon: Icons.sync_problem_rounded,
                message: l10n.scheduleBackendError,
                onRetry: controller.retry,
              ),
          ],
        ),
      );
    },
  );
}

class _NextTrainMessage extends StatelessWidget {
  const _NextTrainMessage({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          message,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
      if (onRetry != null)
        TextButton(
          onPressed: onRetry,
          child: Text(AppLocalizations.of(context)!.actionRetry),
        ),
    ],
  );
}

class _NextTrainRow extends StatelessWidget {
  final NextTrainDeparture departure;
  final bool showDivider;
  final VoidCallback onTap;

  const _NextTrainRow({
    required this.departure,
    required this.showDivider,
    required this.onTap,
  });

  Color get _badgeColor {
    if (departure.schedule.trainType == 'KRL') {
      return AppColors.badgeKRL;
    }
    if (departure.schedule.trainType == 'MRT') {
      return AppColors.badgeMRT;
    }
    return AppColors.badgeLRT;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final schedule = departure.schedule;
    final destination = schedule.destination ?? '';
    final platform = PlatformDisplay.isAvailable(schedule.platform)
        ? l10n.homePlatform(schedule.platform)
        : l10n.homePlatformUnavailable;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _badgeColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    schedule.trainType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        destination,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${schedule.trainName} · ${schedule.departureTime}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            platform,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            l10n.homeDestination(destination),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.scheduleStatusUpcoming(
                        departure.minutesUntilDeparture,
                      ),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      AppLocalizations.of(context)!.homeAtStation,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showDivider)
            const Divider(height: 1, color: AppColors.cardBorder),
        ],
      ),
    );
  }
}

// ── Section Preview Fasilitas Stasiun ──
class _StationFacilitiesSection extends StatelessWidget {
  final String stationName;
  const _StationFacilitiesSection({required this.stationName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final facilities = [
      {
        'icon': Icons.accessible_rounded,
        'label': l10n.facilityAccessibleLift,
        'color': AppColors.primaryBlue,
      },
      {
        'icon': Icons.escalator_rounded,
        'label': l10n.facilityEscalator,
        'color': AppColors.statusGreen,
      },
      {
        'icon': Icons.mosque_rounded,
        'label': l10n.facilityPrayerRoom,
        'color': Colors.amber.shade800,
      },
      {
        'icon': Icons.wc_rounded,
        'label': l10n.facilityAccessibleToilet,
        'color': Colors.teal.shade700,
      },
      {
        'icon': Icons.power_rounded,
        'label': l10n.facilityCharger,
        'color': Colors.orange.shade800,
      },
      {
        'icon': Icons.store_rounded,
        'label': l10n.facilityMinimarket,
        'color': Colors.indigo.shade700,
      },
      {
        'icon': Icons.child_friendly_rounded,
        'label': l10n.facilityNursingRoom,
        'color': Colors.pink.shade600,
      },
      {
        'icon': Icons.local_atm_rounded,
        'label': l10n.facilityAtmCenter,
        'color': Colors.blue.shade800,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.stars_rounded,
              color: AppColors.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppLocalizations.of(
                  context,
                )!.homeStationFacilities(stationName),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.95,
          ),
          itemCount: facilities.length,
          itemBuilder: (context, index) {
            final f = facilities[index];
            final color = f['color'] as Color;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(f['icon'] as IconData, color: color, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    f['label'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── Section Informasi Stasiun ──
class _StationInfoSection extends StatelessWidget {
  final String stationName;
  const _StationInfoSection({required this.stationName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppLocalizations.of(
                  context,
                )!.homeStationInformation(stationName),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              _buildInfoRow(
                Icons.account_tree_outlined,
                AppLocalizations.of(context)!.homeConstructionType,
                AppLocalizations.of(context)!.homeConstructionTypeDesc,
              ),
              const Divider(height: 16, color: AppColors.cardBorder),
              _buildInfoRow(
                Icons.access_time_rounded,
                AppLocalizations.of(context)!.homeOperationalHours,
                AppLocalizations.of(context)!.homeOperationalHoursDesc,
              ),
              const Divider(height: 16, color: AppColors.cardBorder),
              _buildInfoRow(
                Icons.confirmation_number_outlined,
                AppLocalizations.of(context)!.homeTicketServices,
                AppLocalizations.of(context)!.homeTicketServicesDesc,
              ),
              const Divider(height: 16, color: AppColors.cardBorder),
              _buildInfoRow(
                Icons.blind_rounded,
                AppLocalizations.of(context)!.homeAccessibilityFeatures,
                AppLocalizations.of(context)!.homeAccessibilityFeaturesDesc,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primaryBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Section Panduan Pintu Keluar ──
class _StationExitGateSection extends StatelessWidget {
  final String stationName;
  const _StationExitGateSection({required this.stationName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.meeting_room_outlined,
              color: AppColors.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.homeExitGateGuide,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildExitCard(
          gate: AppLocalizations.of(context)!.homeExitNorth,
          description: AppLocalizations.of(context)!.homeExitNorthDesc,
          integrations: AppLocalizations.of(context)!.homeExitNorthIntegration,
          color: AppColors.primaryBlue,
        ),
        const SizedBox(height: 10),
        _buildExitCard(
          gate: AppLocalizations.of(context)!.homeExitSouth,
          description: AppLocalizations.of(context)!.homeExitSouthDesc,
          integrations: AppLocalizations.of(context)!.homeExitSouthIntegration,
          color: AppColors.statusGreen,
        ),
      ],
    );
  }

  Widget _buildExitCard({
    required String gate,
    required String description,
    required String integrations,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.door_sliding_outlined, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gate,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.directions_bus_filled_outlined,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        integrations,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
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
    );
  }
}

// ── Section Customer Service & Bantuan ──
class _StationCustomerServiceSection extends StatelessWidget {
  final String stationName;
  const _StationCustomerServiceSection({required this.stationName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.support_agent_rounded,
              color: AppColors.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.homeCustomerServiceHeader,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryBlueLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primaryBlue.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.headset_mic_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.homeCSStation(stationName),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(context)!.homeContactCenter,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(context)!.homeWhatsApp,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        AppNotice.show(
                          context,
                          message: AppLocalizations.of(
                            context,
                          )!.homeCallCSSnackbar(stationName),
                        );
                      },
                      icon: const Icon(Icons.phone_rounded, size: 16),
                      label: Text(
                        AppLocalizations.of(context)!.homeCallCSBtn,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        AppNotice.show(
                          context,
                          message: AppLocalizations.of(
                            context,
                          )!.homeAskHelpSnackbar(stationName),
                        );
                      },
                      icon: const Icon(Icons.accessible_rounded, size: 16),
                      label: Text(
                        AppLocalizations.of(context)!.homeAskHelpBtn,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        side: const BorderSide(color: AppColors.primaryBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
