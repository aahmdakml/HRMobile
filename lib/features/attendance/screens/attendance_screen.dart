import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/attendance_api_service.dart';
import '../../../core/services/auth_state.dart';
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
    if (authState.token != null) {
      AttendanceApiService.setToken(authState.token!);
    }

    // Sync locations from server on app open (updates cache)
    try {
      //print('DEBUG: Calling syncLocations()...'); (Refresh when menu is opened for the first time)
      //await AttendanceApiService.syncLocations();
      debugPrint('DEBUG: syncLocations() complete');
    } catch (e) {
      debugPrint('DEBUG: syncLocations() ERROR: $e');
    }

    await _fetchAttendanceStatus();
    await _loadCachedServerTime(); // Set initial clock from cache (secure uptime)
    await _checkLocation();
    await _checkNetwork();
  }

  // ============ API INTEGRATION ============

  Future<void> _fetchAttendanceStatus() async {
    try {
      final status = await AttendanceApiService.getStatus();
      setState(() {
        _checkInTime =
            status['check_in'] != null ? _formatTime(status['check_in']) : null;
        _checkOutTime = status['check_out'] != null
            ? _formatTime(status['check_out'])
            : null;

        if (status['server_time'] != null) {
          _serverTime = DateTime.tryParse(status['server_time'])?.toLocal();
          // Note: Time is for display only; server handles all timestamps
        }

        // Determine current status from API response
        if (status['check_out'] != null) {
          _currentStatus = AttendanceStatus.shiftEnded;
        } else if (status['break_in'] != null && status['break_out'] == null) {
          _currentStatus = AttendanceStatus.onBreak;
        } else if (status['check_in'] != null) {
          _currentStatus = AttendanceStatus.working;
        } else {
          _currentStatus = AttendanceStatus.idle;
        }

        // _selectedAction = _getSmartDefault(); // Manual override
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
        bool isValid = false;
        String matchedLocation = 'Out of range';
        List<String> validLog = []; // distinct logs

        print('DOCS: Received ${locations.length} locations');

        for (var location in locations) {
          // Safe parsing helper
          double? safeParse(dynamic value) {
            if (value == null) return null;
            if (value is num) return value.toDouble();
            if (value is String) return double.tryParse(value);
            return null;
          }

          final lat = safeParse(location['latitude']);
          final lng = safeParse(location['longitude']);
          final radius = safeParse(location['radius']) ?? 100.0;
          final name = location['location_name']?.toString() ?? 'Unknown';

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

      if (bssid == null || bssid == '02:00:00:00:00:00') {
        // Not connected to WiFi or permission issue
        setState(() {
          _isNetworkValid = false;
          _networkName = 'No WiFi';
        });
        debugPrint('NETWORK: No WiFi or permission denied');
        return;
      }

      // Fetch allowed locations and check MAC
      try {
        final locations = await AttendanceApiService.getLocations();
        bool isValid = false;
        String matchedNetwork = 'Unknown Network';

        for (var location in locations) {
          final isEnableMac = location['is_enable_mac'] ?? false;
          if (!isEnableMac) continue;

          final macList = location['mac'];
          if (macList == null) continue;

          // MAC can be a list or single string
          List<String> allowedMacs = [];
          if (macList is List) {
            allowedMacs = macList.map((m) => m.toString()).toList();
          } else if (macList is String) {
            allowedMacs = [macList];
          }

          print(
              'NETWORK: Location "${location['location_name']}" allowed MACs: $allowedMacs');

          if (allowedMacs.contains(bssid)) {
            isValid = true;
            matchedNetwork =
                location['location_name']?.toString() ?? 'Office WiFi';
            debugPrint('NETWORK: ✓ MAC matched for $matchedNetwork');
            break;
          }
        }

        setState(() {
          _isNetworkValid = isValid;
          _networkName = isValid ? matchedNetwork : 'Unknown Network';
        });

        print(
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

    // TEMPORARILY DISABLED - Causing 25s+ timeouts and blocking Leave module
    // Sync locations from server on manual refresh (updates cache)
    // await AttendanceApiService.syncLocations();
    debugPrint('ATTENDANCE: Location sync skipped (disabled)');

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
            _selectedAction = _getSmartDefault();
          });
          break;
        case AttendanceAction.resume:
          result = await AttendanceApiService.breakOut(
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
          );
          setState(() {
            _currentStatus = AttendanceStatus.working;
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

      _showSuccess('${_selectedAction.label} successful!');
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  String _formatTime(String? datetime) {
    if (datetime == null) return '--:--';
    try {
      final dt = DateTime.parse(datetime).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.checkIn,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
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
    return Scaffold(
      backgroundColor: Colors.white, // White background everywhere
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ========== A. HEADER SECTION ==========
                _buildHeader(),

                // ========== MAIN CONTENT (Expanded to prevent overflow) ==========
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // ========== A2. SECURITY CLUSTER ==========
                      _buildSecurityCluster(),

                      // ========== B. TIME SECTION ==========
                      LiveClock(serverTime: _serverTime),

                      // ========== C. STATUS SECTION ==========
                      StatusBadge(
                        status: _currentStatus,
                        sinceTime: _checkInTime,
                      ),

                      // ========== E. ACTION SECTION ==========
                      Center(
                        child: AttendanceButton(
                          action: _selectedAction,
                          isEnabled: _isSecurityValid,
                          onComplete: _onAttendanceComplete,
                        ),
                      ),

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
                    ],
                  ),
                ),
              ],
            ),
            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: AttendanceFooter(
          checkInTime: _checkInTime,
          checkOutTime: _checkOutTime,
          status: _currentStatus,
          serverTime: _serverTime,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white, // White background
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Debug Reset Button (Left)
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

          // App Title
          Text(
            'Attendance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary, // Dark text
            ),
          ),

          // Refresh Button (Right)
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: () {
              _onRefresh();
            },
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
}
