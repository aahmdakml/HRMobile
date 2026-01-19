# Mobile Attendance Feature - Technical Documentation

> **For**: Backend Team & Frontend Integration  
> **Project**: HRMobile + Enterprise-backend  
> **Version**: 1.0 (Draft)

---

## Table of Contents

1. [Overview](#overview)
2. [Database Schema](#database-schema)
3. [Backend API Specification](#backend-api-specification)
4. [GPS & WiFi Validation](#gps--wifi-validation)
5. [Frontend Integration](#frontend-integration)
6. [Security Considerations](#security-considerations)

---

## Overview

### Feature Description

Mobile attendance allows employees to clock in/out via the HRMobile app with location and network validation.

### Core Requirements

- ✅ Check-in with timestamp
- ✅ Check-out with timestamp
- ✅ GPS location validation (geofencing)
- ✅ WiFi network validation (SSID/BSSID check)
- ✅ View attendance history
- ✅ Real-time status display

### Architecture

```
┌─────────────────┐     HTTP/JSON     ┌─────────────────┐     PostgreSQL     ┌─────────────────┐
│   HRMobile      │ ◄──────────────► │ Enterprise-     │ ◄────────────────► │   Database      │
│   (Flutter)     │   (Sanctum Auth) │ backend (Laravel)│                    │   (sc_trx)      │
└─────────────────┘                   └─────────────────┘                    └─────────────────┘
```

---

## Database Schema

### Existing Table: `sc_trx.transready`

Already used for attendance. Add mobile-specific columns.

```sql
-- NO CHANGES NEEDED for basic attendance
-- Existing columns used:
-- emp_id, workdate, checkintime_absen, checkouttime_absen, status
```

### New Table: `sc_mst.attendance_locations` (GPS/WiFi)

```sql
CREATE TABLE sc_mst.attendance_locations (
    id              SERIAL PRIMARY KEY,
    company_id      VARCHAR(10) NOT NULL,
    ol_id           VARCHAR(10) NOT NULL,          -- Links to office_locations
    location_name   VARCHAR(100) NOT NULL,

    -- GPS Geofencing
    latitude        DECIMAL(10, 8) NOT NULL,       -- e.g., -7.25754610
    longitude       DECIMAL(11, 8) NOT NULL,       -- e.g., 112.75209790
    radius_meters   INTEGER DEFAULT 100,           -- Geofence radius

    -- WiFi Validation
    wifi_ssid       VARCHAR(100),                  -- e.g., "OFFICE-WIFI"
    wifi_bssid      VARCHAR(50),                   -- MAC address (more reliable)

    -- Metadata
    is_active       BOOLEAN DEFAULT true,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (company_id, ol_id) REFERENCES sc_mst.office_locations(company_id, ol_id)
);
```

### Optional: Add columns to `sc_trx.transready` for mobile metadata

```sql
ALTER TABLE sc_trx.transready ADD COLUMN IF NOT EXISTS
    checkin_latitude    DECIMAL(10, 8),
    checkin_longitude   DECIMAL(11, 8),
    checkin_wifi_ssid   VARCHAR(100),
    checkout_latitude   DECIMAL(10, 8),
    checkout_longitude  DECIMAL(11, 8),
    checkout_wifi_ssid  VARCHAR(100),
    checkin_source      VARCHAR(20) DEFAULT 'biometric', -- 'mobile', 'biometric', 'web'
    checkout_source     VARCHAR(20) DEFAULT 'biometric';
```

---

## Backend API Specification

### Base URL

```
/api/v1/hris/profile/attendance
```

### Authentication

All endpoints require `Authorization: Bearer {token}` (Sanctum)

---

### 1. GET `/status` - Get Today's Status

**Purpose**: Check current attendance state for today

**Response** (200):

```json
{
  "success": true,
  "data": {
    "status": "idle", // "idle" | "working" | "on_break" | "shift_ended"
    "check_in_time": null, // "08:30" or null
    "check_out_time": null, // "17:00" or null
    "location": "Surabaya Office"
  }
}
```

**Status Logic**:
| Condition | Status |
|-----------|--------|
| No record today | `idle` |
| `checkintime_absen` exists, no checkout | `working` |
| Both check-in and check-out exist | `shift_ended` |

---

### 2. POST `/check-in` - Clock In

**Purpose**: Record employee check-in with location/network validation

**Request Body**:

```json
{
  "latitude": -7.2575461,
  "longitude": 112.7520979,
  "wifi_ssid": "OFFICE-WIFI",
  "wifi_bssid": "AA:BB:CC:DD:EE:FF" // Optional, more reliable
}
```

**Response** (200 - Success):

```json
{
  "success": true,
  "data": {
    "message": "Check-in successful",
    "check_in_time": "08:30",
    "location": "Surabaya Office"
  }
}
```

**Response** (400 - Validation Failed):

```json
{
  "success": false,
  "message": "Location validation failed. You are 250m away from office.",
  "data": {
    "distance_meters": 250,
    "allowed_radius": 100
  }
}
```

**Response** (400 - Already Checked In):

```json
{
  "success": false,
  "message": "Already checked in today at 08:30"
}
```

---

### 3. POST `/check-out` - Clock Out

**Purpose**: Record employee check-out

**Request Body**:

```json
{
  "latitude": -7.2575461,
  "longitude": 112.7520979,
  "wifi_ssid": "OFFICE-WIFI"
}
```

**Response** (200):

```json
{
  "success": true,
  "data": {
    "message": "Check-out successful",
    "check_out_time": "17:30",
    "working_hours": "9h 0m"
  }
}
```

---

### 4. GET `/locations` - Get Allowed Locations

**Purpose**: Fetch list of office locations for GPS validation

**Response** (200):

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Surabaya Office",
      "latitude": -7.2575461,
      "longitude": 112.7520979,
      "radius_meters": 100,
      "wifi_ssid": "OFFICE-WIFI"
    }
  ]
}
```

---

### 5. GET `/` (existing) - Attendance History

Already implemented. No changes needed.

---

## GPS & WiFi Validation

### Validation Concept

The attendance buttons (Check-in, Break, Resume, Check-out) are **only enabled** when **BOTH** conditions are met:

1. ✅ GPS location is within office geofence
2. ✅ WiFi is connected to office network

```
┌─────────────────────────────────────────────────────────────────┐
│                    ATTENDANCE PAGE                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────┐                 │
│   │ 📍 Surabaya │  │ 📶 Office   │  │   🔄   │                  │
│   │    ✓ Valid  │  │   WiFi ✓    │  │ Refresh │                 │
│   └─────────────┘  └─────────────┘  └─────────┘                 │
│                                                                  │
│            ↑ Auto-refresh every 5 seconds ↑                      │
│            ↑ Manual refresh via button     ↑                     │
│                                                                  │
│   ┌──────────────────────────────────────────────┐              │
│   │                                              │              │
│   │        [CHECK IN] ← ENABLED only if          │              │
│   │                     GPS ✓ AND WiFi ✓         │              │
│   │                                              │              │
│   └──────────────────────────────────────────────┘              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### What's Measured

| Check            | Flutter Package     | What it Returns     | Compared To                      |
| ---------------- | ------------------- | ------------------- | -------------------------------- |
| **GPS Location** | `geolocator`        | Latitude, Longitude | Office location + radius from DB |
| **WiFi Network** | `network_info_plus` | SSID (WiFi name)    | Office WiFi SSID from DB         |

### Refresh Behavior

| Type               | Interval        | Trigger                     |
| ------------------ | --------------- | --------------------------- |
| **Auto-refresh**   | Every 5 seconds | Timer in Flutter            |
| **Manual refresh** | On demand       | User taps refresh button 🔄 |

### UI State Logic

```dart
// In AttendanceScreen
bool get _isSecurityValid => _isLocationValid && _isNetworkValid;

// Button is enabled only when both are true
AttendanceButton(
  isEnabled: _isSecurityValid && _currentStatus != AttendanceStatus.shiftEnded,
  // ...
)
```

### GPS Validation Logic (Frontend - Flutter)

```dart
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Check if user is within office geofence
  Future<bool> validateLocation(OfficeLocation office) async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Calculate distance using Haversine formula (built into Geolocator)
    final distance = Geolocator.distanceBetween(
      position.latitude, position.longitude,
      office.latitude, office.longitude,
    );

    // Valid if within radius
    return distance <= office.radiusMeters;
  }
}
```

### WiFi Validation Logic (Frontend - Flutter)

```dart
import 'package:network_info_plus/network_info_plus.dart';

class WifiService {
  final NetworkInfo _networkInfo = NetworkInfo();

  /// Check if connected to office WiFi
  Future<bool> validateWifi(String expectedSsid) async {
    final currentSsid = await _networkInfo.getWifiName();

    // Remove quotes that some platforms add
    final cleanSsid = currentSsid?.replaceAll('"', '');

    return cleanSsid == expectedSsid;
  }
}
```

### WiFi Validation Options

Choose one of these options based on security requirements:

#### Option 1: SSID Check (Basic)

Compare WiFi network name.

| Pros                                   | Cons                         |
| -------------------------------------- | ---------------------------- |
| Simple to implement                    | Easy to spoof (fake hotspot) |
| Works with multiple APs with same SSID |                              |

#### Option 2: BSSID Check (Recommended for Multiple Access Points)

Compare router MAC address(es). Store list of allowed BSSIDs in database.

**Database Schema:**

```sql
-- Store multiple BSSIDs per office
wifi_bssids JSONB  -- ["AA:BB:CC:DD:EE:01", "AA:BB:CC:DD:EE:02", ...]
```

**Flutter Code:**

```dart
Future<bool> validateByBssid(List<String> allowedBssids) async {
  final currentBssid = await _networkInfo.getWifiBSSID();
  if (currentBssid == null) return false;

  return allowedBssids.any(
    (allowed) => allowed.toUpperCase() == currentBssid.toUpperCase()
  );
}
```

| Pros              | Cons                                  |
| ----------------- | ------------------------------------- |
| Harder to spoof   | Need to register all AP MAC addresses |
| Unique per router | Must update when router replaced      |

#### Option 3: Internal API Ping (Highest Security)

Ping a server that's **ONLY accessible from office network**.

**Concept:**

```
Phone → Tries to reach internal API →
  ✅ Reachable = On office network
  ❌ Unreachable = Not on office network
```

**Flutter Code:**

```dart
Future<bool> validateByInternalPing() async {
  try {
    // This URL only works on office internal network
    final response = await http.get(
      Uri.parse('http://192.168.1.1/api/attendance/verify'),
    ).timeout(Duration(seconds: 3));

    return response.statusCode == 200;
  } catch (e) {
    return false; // Can't reach = not in office
  }
}
```

**Backend (Laravel) - Internal Endpoint:**

```php
// Only accessible from internal network (configure in nginx/apache)
Route::get('/attendance/verify', function() {
    return response()->json(['valid' => true]);
});
```

| Pros                                | Cons                           |
| ----------------------------------- | ------------------------------ |
| **Impossible to fake from outside** | Requires internal server setup |
| Works with any AP automatically     | Needs network configuration    |
| No need to track BSSIDs             |                                |

### Recommended Approach

| Security Level | Combination             |
| -------------- | ----------------------- |
| **Basic**      | GPS + SSID              |
| **Medium**     | GPS + BSSID list        |
| **High**       | GPS + Internal API Ping |

### Backend: Store Office Location + WiFi

The backend needs to provide an API to get the user's assigned office with GPS and WiFi info:

```php
// GET /api/v1/hris/profile/attendance/locations
public function locations(Request $request)
{
    $employee = Employee::with('officeLocation.attendanceLocation')
        ->where('emp_id', $this->user->emp_id)
        ->first();

    $location = $employee->officeLocation->attendanceLocation;

    return ApiResponse::success([
        'name' => $location->location_name,
        'latitude' => $location->latitude,
        'longitude' => $location->longitude,
        'radius_meters' => $location->radius_meters,
        'wifi_ssid' => $location->wifi_ssid,
    ]);
}
```

---

## Frontend Integration

### 1. AttendanceService (Flutter/Dart)

```dart
class AttendanceService {
  static const String baseUrl = 'https://api.example.com/api/v1';

  /// Get today's status
  Future<AttendanceStatus> getStatus() async {
    final response = await dio.get('/hris/profile/attendance/status');
    return AttendanceStatus.fromJson(response.data['data']);
  }

  /// Check-in with location
  Future<CheckInResult> checkIn({
    required double latitude,
    required double longitude,
    String? wifiSsid,
    String? wifiBssid,
  }) async {
    final response = await dio.post('/hris/profile/attendance/check-in', data: {
      'latitude': latitude,
      'longitude': longitude,
      'wifi_ssid': wifiSsid,
      'wifi_bssid': wifiBssid,
    });
    return CheckInResult.fromJson(response.data);
  }

  /// Check-out with location
  Future<CheckOutResult> checkOut({
    required double latitude,
    required double longitude,
  }) async {
    final response = await dio.post('/hris/profile/attendance/check-out', data: {
      'latitude': latitude,
      'longitude': longitude,
    });
    return CheckOutResult.fromJson(response.data);
  }
}
```

### 2. LocationService (Flutter/Dart)

```dart
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Get current GPS position
  Future<Position> getCurrentPosition() async {
    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Check if within geofence (client-side preview)
  bool isWithinGeofence(
    Position position,
    double officeLat,
    double officeLng,
    double radiusMeters,
  ) {
    final distance = Geolocator.distanceBetween(
      position.latitude, position.longitude,
      officeLat, officeLng,
    );
    return distance <= radiusMeters;
  }
}
```

### 3. WiFiService (Flutter/Dart)

```dart
import 'package:network_info_plus/network_info_plus.dart';

class WifiService {
  final NetworkInfo _networkInfo = NetworkInfo();

  /// Get current WiFi info
  Future<WifiInfo> getWifiInfo() async {
    return WifiInfo(
      ssid: await _networkInfo.getWifiName(),       // e.g., "OFFICE-WIFI"
      bssid: await _networkInfo.getWifiBSSID(),     // e.g., "AA:BB:CC:DD:EE:FF"
    );
  }
}
```

### 4. Required Flutter Packages

Add to `pubspec.yaml`:

```yaml
dependencies:
  geolocator: ^11.0.0 # Already added
  network_info_plus: ^5.0.0 # For WiFi info
  permission_handler: ^11.0.0 # For permission requests
```

---

## Security Considerations

### 1. GPS Spoofing Prevention

- **Server-side validation only**: Never trust client-side distance calculations
- **Log all attempts**: Store coordinates for audit trail
- **Anomaly detection**: Flag suspicious patterns (e.g., instant teleportation)

### 2. WiFi Spoofing Prevention

- **Use BSSID over SSID**: MAC addresses are harder to spoof
- **Consider as secondary validation**: GPS should be primary
- **Regular BSSID updates**: If router changes

### 3. Time Manipulation

- **Server timestamp only**: Use `Carbon::now()` on server, ignore client time
- **Timezone handling**: Store in UTC, display in user's timezone

### 4. Rate Limiting

- Maximum 2 check-ins per day per employee
- Minimum 1 minute between check-in and check-out
- Block rapid retry attempts (429 Too Many Requests)

---

## Implementation Checklist

### Backend Team

- [ ] Create `attendance_locations` migration
- [ ] Create `GpsValidationService`
- [ ] Create `WifiValidationService`
- [ ] Add `status` endpoint to AttendanceController
- [ ] Add `checkIn` endpoint with validation
- [ ] Add `checkOut` endpoint
- [ ] Add `locations` endpoint
- [ ] Write unit tests
- [ ] Update API documentation

### Frontend Team

- [ ] Create `AttendanceService`
- [ ] Create `LocationService`
- [ ] Create `WifiService`
- [ ] Connect `AttendanceScreen` to services
- [ ] Handle permission flows
- [ ] Add error handling UI
- [ ] Add loading states
- [ ] Test on physical device

---

## API Summary Table

| Endpoint                             | Method | Description        | Auth Required |
| ------------------------------------ | ------ | ------------------ | ------------- |
| `/hris/profile/attendance`           | GET    | Attendance history | ✅            |
| `/hris/profile/attendance/status`    | GET    | Today's status     | ✅            |
| `/hris/profile/attendance/check-in`  | POST   | Clock in           | ✅            |
| `/hris/profile/attendance/check-out` | POST   | Clock out          | ✅            |
| `/hris/profile/attendance/locations` | GET    | Office locations   | ✅            |

---

_Document Version: 1.0_  
_Last Updated: January 19, 2026_
