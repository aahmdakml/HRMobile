/// Attendance state enums and models

/// Current attendance status of the employee
enum AttendanceStatus {
  idle, // Not checked in yet
  working, // Currently working
  onBreak, // On break
  shiftEnded, // Already checked out
}

/// Actions available for attendance
enum AttendanceAction {
  checkIn, // Clock in
  breakOut, // Start break
  resume, // End break / resume work
  checkOut, // Clock out
}

/// Security validation status
enum SecurityStatus {
  valid, // GPS/WiFi validated
  invalid, // GPS/WiFi not validated
}

/// Extension to get display properties for AttendanceStatus
extension AttendanceStatusX on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.idle:
        return 'NOT CHECKED IN';
      case AttendanceStatus.working:
        return 'WORKING';
      case AttendanceStatus.onBreak:
        return 'ON BREAK';
      case AttendanceStatus.shiftEnded:
        return 'SHIFT ENDED';
    }
  }
}

/// Extension to get display properties for AttendanceAction
extension AttendanceActionX on AttendanceAction {
  String get label {
    switch (this) {
      case AttendanceAction.checkIn:
        return 'Check In';
      case AttendanceAction.breakOut:
        return 'Break';
      case AttendanceAction.resume:
        return 'Resume';
      case AttendanceAction.checkOut:
        return 'Check Out';
    }
  }

  String get shortLabel {
    switch (this) {
      case AttendanceAction.checkIn:
        return 'In';
      case AttendanceAction.breakOut:
        return 'Break';
      case AttendanceAction.resume:
        return 'Resume';
      case AttendanceAction.checkOut:
        return 'Out';
    }
  }
}
