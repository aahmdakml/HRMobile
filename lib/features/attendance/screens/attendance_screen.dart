import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/attendance_api_service.dart';
import '../../../core/services/time_service.dart';
import '../models/attendance_state.dart';
import '../widgets/security_pill.dart';
import '../widgets/live_clock.dart';
import '../widgets/attendance_type_selector.dart';
import '../widgets/status_badge.dart';

import '../widgets/attendance_button.dart';
import '../widgets/attendance_footer.dart';

/// Main Attendance Screen
/// Layout: Header > Time > Status > Selector > Button > Footer
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with WidgetsBindingObserver {
  Timer? _locationTimer;
  DateTime? _serverTime;
  // ============ STATE ============

  // Security status (default false - must be validated)
  bool _isLocationValid = false;
  bool _isNetworkValid = false; // MAC/WiFi validation
  bool _isLoading = true;
  String _locationName = 'Checking...';
  String _networkName = 'Checking...';

  // Attendance state
  AttendanceStatus _currentStatus = AttendanceStatus.idle;
  AttendanceAction _selectedAction = AttendanceAction.checkIn;

  // Times
  String? _checkInTime;
  String? _checkOutTime;
  Duration _breakDuration = Duration.zero;

  // Current position
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
    _startLocationTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopLocationTimer();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startLocationTimer();
    } else if (state == AppLifecycleState.paused) {
      _stopLocationTimer();
    }
  }

  void _startLocationTimer() {
    _stopLocationTimer(); // Safety check
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _checkLocation();
        _checkNetwork();
        // Server time sync removed to save bandwidth
        // _syncServerTime();
      }
    });
  }

  void _stopLocationTimer() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> _initialize() async {
    // Set auth token for API calls
    // Token is handled globally by ApiClient interceptor now

    // Sync locations from server on app open (updates cache)
    try {
      //print('DEBUG: Calling syncLocations()...'); (Refresh when menu is opened for the first time)
      //await AttendanceApiService.syncLocations();
      debugPrint('DEBUG: syncLocations() complete');
    } catch (e) {
      debugPrint('DEBUG: syncLocations() ERROR: $e');
    }

    // Check for pre-loaded data (from Login/Home)
    bool usedCache = false;

    // 1. Apply Cached Status
    if (AttendanceApiService.cachedStatus != null) {
      debugPrint('ATTENDANCE: Applying pre-loaded status');
      final status = AttendanceApiService.cachedStatus!;
      _applyStatusData(status); // Helper method to apply state
      AttendanceApiService.cachedStatus = null; // Consume
      usedCache = true;
      setState(() {
        _isLoading = false;
      });
    } else {
      await _fetchAttendanceStatus();
    }

    await _loadCachedServerTime(); // Set initial clock from cache (secure uptime)

    // 2. Apply Cached Validation
    if (AttendanceApiService.cachedValidation != null) {
      debugPrint('ATTENDANCE: Applying pre-loaded validation');
      final val = AttendanceApiService.cachedValidation!;
      setState(() {
        _isLocationValid = val.isLocationValid;
        _locationName = val.locationName;
        _isNetworkValid = val.isNetworkValid;
        _networkName = val.networkName;
      });
      AttendanceApiService.cachedValidation = null; // Consume
    } else {
      // Fallback to live check
      await _checkLocation();
      await _checkNetwork();
    }
  }

  // Extracted helper to reuse logic
  void _applyStatusData(Map<String, dynamic> status) {
    setState(() {
      _checkInTime =
          status['check_in'] != null ? _formatTime(status['check_in']) : null;
      _checkOutTime =
          status['check_out'] != null ? _formatTime(status['check_out']) : null;

      if (status['server_time'] != null) {
        _serverTime = DateTime.tryParse(status['server_time'])?.toLocal();
      }

      // Calculate break duration if completed
      if (status['break_in'] != null && status['break_out'] != null) {
        try {
          final breakIn = DateTime.parse(status['break_in']);
          final breakOut = DateTime.parse(status['break_out']);
          _breakDuration = breakOut.difference(breakIn);
        } catch (e) {
          _breakDuration = Duration.zero;
        }
      } else {
        _breakDuration = Duration.zero;
      }

      // Determine current status and display times
      if (status['check_out'] != null) {
        _currentStatus = AttendanceStatus.shiftEnded;
        _checkOutTime = _formatTime(status['check_out']);
      } else if (status['break_in'] != null && status['break_out'] == null) {
        _currentStatus = AttendanceStatus.onBreak;
        // Use break_in time as "check out" for visual timer freezing
        _checkOutTime = _formatTime(status['break_in']);
      } else if (status['check_in'] != null) {
        _currentStatus = AttendanceStatus.working;
      } else {
        _currentStatus = AttendanceStatus.idle;
      }

      // Capabilities logic
      // If backend provides 'can_check_in' etc, use them?
      // Logic currently relies on _currentStatus derivation above.
      // Assuming status object structure matches what _fetchAttendanceStatus expects.
    });
  }

  // ============ API INTEGRATION ============

  Future<void> _fetchAttendanceStatus() async {
    try {
      final status = await AttendanceApiService.getStatus();
      _applyStatusData(status);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to load attendance status');
    }
  }

  Future<void> _loadCachedServerTime() async {
    final cachedTime = await TimeService.getCachedServerTime();
    if (cachedTime != null) {
      if (mounted) {
        setState(() {
          _serverTime = cachedTime;
        });
        debugPrint('CLOCK: Loaded cached server time: $_serverTime');
      }
    }
  }

  Future<void> _checkLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLocationValid = false;
          _locationName = 'GPS disabled';
        });
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLocationValid = false;
            _locationName = 'Permission denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLocationValid = false;
          _locationName = 'Permission blocked';
        });
        return;
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Fetch allowed locations and validate
      try {
        final locations = await AttendanceApiService.getLocations();

        // Validating location...

        bool isValid = false;
        String matchedLocation = 'Out of range';
        List<String> validLog = []; // distinct logs

        print('DOCS: Received ${locations.length} locations');

        for (var location in locations) {
          final isEnableGps = location['is_enable_gps'] ?? true;
          final name = location['location_name']?.toString() ?? 'Mobile';

          // Safe parsing helper
          double? safeParse(dynamic value) {
            if (value == null) return null;
            if (value is num) return value.toDouble();
            if (value is String) return double.tryParse(value);
            return null;
          }

          if (!isEnableGps) {
            // Disabled: Skip check (Always pass criteria)
            isValid = true;
            matchedLocation = 'Verified';
            debugPrint('DOCS: ✓ Security Disabled (Skip GPS) for $name');
            break;
          } else {
            // Enabled: strict check
            final lat = safeParse(location['latitude']);
            final lng = safeParse(location['longitude']);
            final radius = safeParse(location['radius']) ?? 100.0;

            if (lat == null || lng == null) {
              debugPrint('DOCS: Invalid coordinates for $name');
              continue;
            }

            final distance = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              lat,
              lng,
            );

            validLog.add('$name: ${distance.toStringAsFixed(1)}m / ${radius}m');

            if (distance <= radius) {
              isValid = true;
              matchedLocation = name;
              break;
            }
          }
        }

        // debugPrint('DOCS: Location Check: $validLog');

        setState(() {
          _isLocationValid = isValid;
          _locationName = matchedLocation;
        });
      } catch (apiError) {
        // API error but GPS works
        String errorMsg = apiError.toString();
        if (errorMsg.contains('Exception:')) {
          errorMsg = errorMsg.split('Exception:').last.trim();
        }

        setState(() {
          _isLocationValid = false;
          _locationName = 'API: $errorMsg';
        });
        debugPrint('API Error Detail: $apiError');
      }
    } catch (e) {
      setState(() {
        _isLocationValid = false;
        _locationName = 'GPS Error: ${e.toString().split(':').last.trim()}';
      });
      debugPrint('Location Error Detail: $e');
    }
  }

  /// Check WiFi MAC (BSSID) against allowed locations
  Future<void> _checkNetwork() async {
    try {
      final info = NetworkInfo();
      final bssid = await info.getWifiBSSID();
      debugPrint('NETWORK: Connected WiFi BSSID (MAC): $bssid');

      // Fetch allowed locations
      try {
        final locations = await AttendanceApiService.getLocations();
        bool isValid = false;
        String matchedNetwork = 'Unknown Network';

        for (var location in locations) {
          final isEnableMac = location['is_enable_mac'] ?? false;
          final name = location['location_name']?.toString() ?? 'Mobile';

          if (!isEnableMac) {
            // Disabled: Skip check (Always pass criteria)
            isValid = true;
            matchedNetwork = 'Verified';
            debugPrint('NETWORK: ✓ Security Disabled (Skip Check) for $name');
            break;
          } else {
            // Enabled: strict check
            if (bssid == null || bssid == '02:00:00:00:00:00') continue;

            final macList = location['mac'];
            if (macList == null) continue;

            List<String> allowedMacs = [];
            if (macList is List) {
              allowedMacs = macList.map((m) => m.toString()).toList();
            } else if (macList is String) {
              allowedMacs = [macList];
            }

            if (allowedMacs.contains(bssid)) {
              isValid = true;
              matchedNetwork = name;
              debugPrint('NETWORK: ✓ MAC matched for $name');
              break;
            }
          }
        }

        // If not valid and failed due to connection (and strict mode was enforced)
        if (!isValid && (bssid == null || bssid == '02:00:00:00:00:00')) {
          setState(() {
            _isNetworkValid = false;
            _networkName = 'No WiFi';
          });
          return;
        }

        setState(() {
          _isNetworkValid = isValid;
          _networkName = isValid ? matchedNetwork : 'Unknown Network';
        });

        debugPrint(
            'NETWORK: Validation result: isValid=$isValid, networkName=$_networkName');
      } catch (apiError) {
        debugPrint('NETWORK: API Error: $apiError');
        setState(() {
          _isNetworkValid = false;
          _networkName = 'API Error';
        });
      }
    } catch (e) {
      debugPrint('NETWORK: Error getting BSSID: $e');
      setState(() {
        _isNetworkValid = false;
        _networkName = 'WiFi Error';
      });
    }
  }

  // ============ SMART DEFAULT LOGIC ============

  AttendanceAction _getSmartDefault() {
    switch (_currentStatus) {
      case AttendanceStatus.idle:
        return AttendanceAction.checkIn;
      case AttendanceStatus.working:
        return AttendanceAction.checkOut;
      case AttendanceStatus.onBreak:
        return AttendanceAction.resume;
      case AttendanceStatus.shiftEnded:
        return AttendanceAction.checkIn;
    }
  }

  bool get _isSecurityValid => _isLocationValid && _isNetworkValid;

  // ============ ACTIONS ============

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);

    // Sync locations from server on manual refresh (updates cache)
    await AttendanceApiService.syncLocations();

    await _fetchAttendanceStatus();
    await _checkLocation();
    await _checkNetwork();
  }

  Future<void> _onAttendanceComplete() async {
    if (_currentPosition == null) {
      _showError('Unable to get location');
      return;
    }

    try {
      Map<String, dynamic> result;

      switch (_selectedAction) {
        case AttendanceAction.checkIn:
          result = await AttendanceApiService.checkIn(
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
          );
          setState(() {
            _currentStatus = AttendanceStatus.working;
            _checkInTime = result['check_time'];
            _selectedAction = _getSmartDefault();
          });
          break;
        case AttendanceAction.breakOut:
          result = await AttendanceApiService.breakIn(
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
          );
          setState(() {
            _currentStatus = AttendanceStatus.onBreak;
            // Set break start time as "check out" time to freeze timer
            // Ensure we format it to HH:mm:ss so the footer parser understands it
            _checkOutTime = _formatTime(
                result['check_time'] ?? DateTime.now().toIso8601String());
            _selectedAction = _getSmartDefault();
          });
          break;
        case AttendanceAction.resume:
          result = await AttendanceApiService.breakOut(
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
          );

          // Calculate the duration of this break session locally (Visual only)
          if (_checkOutTime != null) {
            try {
              final parts = _checkOutTime!.split(':');
              final now = DateTime.now();
              final breakStart = DateTime(
                now.year,
                now.month,
                now.day,
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(parts[2]),
              );
              final breakEnd = DateTime.now(); // Approx resume time
              final thisBreak = breakEnd.difference(breakStart);
              _breakDuration += thisBreak;
            } catch (e) {
              debugPrint('VISUAL_TIMER: Error calculating break duration: $e');
            }
          }

          setState(() {
            _currentStatus = AttendanceStatus.working;
            // Clear check out time to resume live ticking
            _checkOutTime = null;
            _selectedAction = _getSmartDefault();
          });
          break;
        case AttendanceAction.checkOut:
          result = await AttendanceApiService.checkOut(
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
          );
          setState(() {
            _currentStatus = AttendanceStatus.shiftEnded;
            _checkOutTime = result['check_time'];
          });
          break;
      }

      String successMessage =
          result['message'] ?? '${_selectedAction.label} successful!';
      _showSuccessDialog(successMessage);
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  String _formatTime(String? datetime) {
    if (datetime == null) return '--:--';
    try {
      final dt = DateTime.parse(datetime).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return datetime;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.checkOut,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.checkIn),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error popup when user taps disabled button
  void _showSecurityError() {
    String errorMessage;

    if (!_isLocationValid && !_isNetworkValid) {
      // Both invalid
      errorMessage =
          'WiFi and location isn\'t verified yet. Please check your WiFi connection and location and refresh.';
    } else if (!_isLocationValid) {
      // Only location invalid
      errorMessage =
          'Location isn\'t verified yet. Please check your location and refresh.';
    } else {
      // Only network invalid
      errorMessage =
          'WiFi isn\'t verified yet. Please check your WiFi connection and refresh.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cannot Proceed'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ============ BUILD ============

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // ========== A. HEADER SECTION ==========
                _buildHeader(),

                // ========== A2. SECURITY CLUSTER ==========
                _buildSecurityCluster(),

                // ========== B. TIME SECTION ==========
                LiveClock(serverTime: _serverTime),

                const SizedBox(height: 12),

                // ========== C. STATUS SECTION ==========
                // Check Status Badge (Informational only)
                StatusBadge(
                  status: _currentStatus,
                  sinceTime: _checkInTime,
                ),

                const SizedBox(height: 8),

                // ========== D. MANUAL ACTION SELECTOR ==========
                Center(
                  child: AttendanceTypeSelector(
                    selectedAction: _selectedAction,
                    currentStatus: _currentStatus,
                    onActionSelected: (action) {
                      setState(() => _selectedAction = action);
                    },
                    isEnabled: _isSecurityValid,
                  ),
                ),

                const SizedBox(height: 16),

                // ========== E. ACTION SECTION ==========
                Center(
                  child: AttendanceButton(
                    action: _selectedAction,
                    isEnabled:
                        _isSecurityValid, // Manual override: always allow action if security is valid
                    onComplete: _onAttendanceComplete,
                    onDisabledTap: _showSecurityError,
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: AttendanceFooter(
              checkInTime: _checkInTime,
              checkOutTime: _checkOutTime,
              status: _currentStatus,
              serverTime: _serverTime,
              breakDuration: _breakDuration,
            ),
          ),
        ),
        // Loading overlay covering everything
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // History Button (Left)
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.textPrimary),
            tooltip: 'Attendance History',
            onPressed: _showHistoryModal,
          ),

          // App Title
          Text(
            'Attendance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          // Actions (Right)
          Row(
            children: [
              // Debug Reset Button
              IconButton(
                icon: const Icon(Icons.restore, color: Colors.orange),
                tooltip: 'Reset Attendance (Debug)',
                onPressed: () async {
                  setState(() => _isLoading = true);
                  try {
                    await AttendanceApiService.resetAttendance();
                    await _fetchAttendanceStatus();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Attendance data reset!')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Reset failed: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
              ),
              // Refresh Button
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
                onPressed: _onRefresh,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCluster() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Location Pill
          SecurityPill.location(
            locationName: _locationName,
            isValid: _isLocationValid,
          ),

          const SizedBox(width: 8),

          // Network Pill
          SecurityPill.network(
            networkName: _networkName,
            isValid: _isNetworkValid,
          ),
        ],
      ),
    );
  }

  // ============ HISTORY MODAL (VISUAL ONLY) ============

  void _showHistoryModal() {
    // Dummy Data
    final history = [
      {'date': '27 Jan 2026', 'in': '08:00', 'out': '17:00', 'state': 'Hadir'},
      {'date': '26 Jan 2026', 'in': '08:15', 'out': '17:00', 'state': 'Telat'},
      {'date': '25 Jan 2026', 'in': '--:--', 'out': '--:--', 'state': 'Alpha'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow full height/scrolling
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * 0.85, // Max 85% height
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Brief History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...history.map((record) => _buildHistoryCard(record)),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to full history page if available
                  },
                  child: const Text('View Full History'),
                ),
              ),
              // Add bottom padding for safe area
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, String> record) {
    Color stateColor;
    switch (record['state']) {
      case 'Hadir':
        stateColor = Colors.green;
        break;
      case 'Telat':
        stateColor = Colors.orange;
        break;
      case 'Alpha':
        stateColor = Colors.red;
        break;
      default:
        stateColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with State Color
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: stateColor.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  record['date']!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: stateColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    record['state']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeColumn('Clock In', record['in']!),
                Container(width: 1, height: 24, color: Colors.grey.shade300),
                _buildTimeColumn('Clock Out', record['out']!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String label, String time) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}
