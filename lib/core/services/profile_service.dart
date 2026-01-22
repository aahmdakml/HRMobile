import 'package:mobile_app/core/services/api_client.dart';
import 'package:flutter/foundation.dart';

/// Profile Service for HRIS Profile API calls
class ProfileService {
  /// Get personal data
  static Future<ProfileResult<PersonalData>> getPersonalData() async {
    try {
      final response = await apiClient.get('/hris/profile/personal-data');
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return ProfileResult.success(PersonalData.fromJson(data));
      }
      return ProfileResult.failure(
          response.data['message'] ?? 'Failed to load');
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
      return ProfileResult.failure('Connection error');
    }
  }

  /// Get addresses
  static Future<ProfileResult<List<Address>>> getAddresses() async {
    try {
      final response = await apiClient.get('/hris/profile/address');
      if (response.statusCode == 200) {
        final rawData = response.data['data'];
        List<dynamic> data;
        if (rawData is List) {
          data = rawData;
        } else if (rawData is Map) {
          data = [rawData]; // Wrap single object in list
        } else {
          data = [];
        }
        return ProfileResult.success(
          data.map((e) => Address.fromJson(e)).toList(),
        );
      }
      return ProfileResult.failure(
          response.data['message'] ?? 'Failed to load');
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
      return ProfileResult.failure('Connection error');
    }
  }

  /// Get contacts
  static Future<ProfileResult<List<Contact>>> getContacts() async {
    try {
      final response = await apiClient.get('/hris/profile/contact');
      if (response.statusCode == 200) {
        final rawData = response.data['data'];
        List<dynamic> data;
        if (rawData is List) {
          data = rawData;
        } else if (rawData is Map) {
          data = [rawData];
        } else {
          data = [];
        }
        return ProfileResult.success(
          data.map((e) => Contact.fromJson(e)).toList(),
        );
      }
      return ProfileResult.failure(
          response.data['message'] ?? 'Failed to load');
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
      return ProfileResult.failure('Connection error');
    }
  }

  /// Get family members
  static Future<ProfileResult<List<Family>>> getFamily() async {
    try {
      final response = await apiClient.get('/hris/profile/family');
      if (response.statusCode == 200) {
        final rawData = response.data['data'];
        List<dynamic> data;
        if (rawData is List) {
          data = rawData;
        } else if (rawData is Map) {
          data = [rawData];
        } else {
          data = [];
        }
        return ProfileResult.success(
          data.map((e) => Family.fromJson(e)).toList(),
        );
      }
      return ProfileResult.failure(
          response.data['message'] ?? 'Failed to load');
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
      return ProfileResult.failure('Connection error');
    }
  }

  /// Get education history
  static Future<ProfileResult<List<Education>>> getEducation() async {
    try {
      final response = await apiClient.get('/hris/profile/education');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List? ?? [];
        return ProfileResult.success(
          data.map((e) => Education.fromJson(e)).toList(),
        );
      }
      return ProfileResult.failure(
          response.data['message'] ?? 'Failed to load');
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
      return ProfileResult.failure('Connection error');
    }
  }

  /// Get emergency contacts
  static Future<ProfileResult<List<EmergencyContact>>>
      getEmergencyContacts() async {
    try {
      final response = await apiClient.get('/hris/profile/emergency-contact');
      if (response.statusCode == 200) {
        final rawData = response.data['data'];
        List<dynamic> data;
        if (rawData is List) {
          data = rawData;
        } else if (rawData is Map) {
          data = [rawData];
        } else {
          data = [];
        }
        return ProfileResult.success(
          data.map((e) => EmergencyContact.fromJson(e)).toList(),
        );
      }
      return ProfileResult.failure(
          response.data['message'] ?? 'Failed to load');
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
      return ProfileResult.failure('Connection error');
    }
  }

  /// Get attendance history
  static Future<ProfileResult<List<AttendanceRecord>>>
      getAttendanceHistory() async {
    try {
      final response = await apiClient.get('/hris/profile/attendance');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List? ?? [];
        return ProfileResult.success(
          data.map((e) => AttendanceRecord.fromJson(e)).toList(),
        );
      }
      return ProfileResult.failure(
          response.data['message'] ?? 'Failed to load');
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
      return ProfileResult.failure('Connection error');
    }
  }
}

/// Generic result wrapper
class ProfileResult<T> {
  final bool success;
  final T? data;
  final String? error;

  ProfileResult._({required this.success, this.data, this.error});

  factory ProfileResult.success(T data) =>
      ProfileResult._(success: true, data: data);
  factory ProfileResult.failure(String error) =>
      ProfileResult._(success: false, error: error);
}

// ============ Models ============

class PersonalData {
  final String empId;
  final String name;
  final String? email;
  final String? phone;
  final String? birthDate;
  final String? gender;
  final String? religion;
  final String? maritalStatus;
  final String? bloodType;

  PersonalData({
    required this.empId,
    required this.name,
    this.email,
    this.phone,
    this.birthDate,
    this.gender,
    this.religion,
    this.maritalStatus,
    this.bloodType,
  });

  factory PersonalData.fromJson(Map<String, dynamic> json) {
    return PersonalData(
      empId: json['emp_id'] ?? '',
      name: json['emp_name'] ?? '',
      email: json['emp_email'],
      phone: json['emp_phone'],
      birthDate: json['emp_birth_date'],
      gender: json['emp_gender'],
      religion: json['emp_religion'],
      maritalStatus: json['emp_marital_status'],
      bloodType: json['emp_blood_type'],
    );
  }
}

class Address {
  final int id;
  final String type;
  final String address;
  final String? city;
  final String? province;
  final String? postalCode;

  Address({
    required this.id,
    required this.type,
    required this.address,
    this.city,
    this.province,
    this.postalCode,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? 0,
      type: json['addr_type'] ?? json['type'] ?? '',
      address: json['addr_full'] ?? json['address'] ?? '',
      city: json['addr_city'] ?? json['city'],
      province: json['addr_province'] ?? json['province'],
      postalCode: json['addr_postal_code'] ?? json['postal_code'],
    );
  }
}

class Contact {
  final int id;
  final String type;
  final String value;

  Contact({required this.id, required this.type, required this.value});

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] ?? 0,
      type: json['contact_type'] ?? json['type'] ?? '',
      value: json['contact_value'] ?? json['value'] ?? '',
    );
  }
}

class Family {
  final int id;
  final String name;
  final String relationship;
  final String? birthDate;
  final String? occupation;

  Family({
    required this.id,
    required this.name,
    required this.relationship,
    this.birthDate,
    this.occupation,
  });

  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      id: json['id'] ?? 0,
      name: json['fam_name'] ?? json['name'] ?? '',
      relationship: json['fam_relationship'] ?? json['relationship'] ?? '',
      birthDate: json['fam_birth_date'] ?? json['birth_date'],
      occupation: json['fam_occupation'] ?? json['occupation'],
    );
  }
}

class Education {
  final int id;
  final String level;
  final String institution;
  final String? major;
  final String? graduationYear;
  final String? gpa;

  Education({
    required this.id,
    required this.level,
    required this.institution,
    this.major,
    this.graduationYear,
    this.gpa,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      id: json['id'] ?? 0,
      level: json['edu_level'] ?? json['level'] ?? '',
      institution: json['edu_institution'] ?? json['institution'] ?? '',
      major: json['edu_major'] ?? json['major'],
      graduationYear: json['edu_graduation_year']?.toString() ??
          json['graduation_year']?.toString(),
      gpa: json['edu_gpa']?.toString() ?? json['gpa']?.toString(),
    );
  }
}

class EmergencyContact {
  final int id;
  final String name;
  final String relationship;
  final String phone;
  final String? address;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phone,
    this.address,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] ?? 0,
      name: json['ec_name'] ?? json['name'] ?? '',
      relationship: json['ec_relationship'] ?? json['relationship'] ?? '',
      phone: json['ec_phone'] ?? json['phone'] ?? '',
      address: json['ec_address'] ?? json['address'],
    );
  }
}

class AttendanceRecord {
  final int id;
  final String date;
  final String? clockIn;
  final String? clockOut;
  final String? status;
  final String? notes;

  AttendanceRecord({
    required this.id,
    required this.date,
    this.clockIn,
    this.clockOut,
    this.status,
    this.notes,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? 0,
      date: json['att_date'] ?? json['date'] ?? '',
      clockIn: json['att_clock_in'] ?? json['clock_in'],
      clockOut: json['att_clock_out'] ?? json['clock_out'],
      status: json['att_status'] ?? json['status'],
      notes: json['att_notes'] ?? json['notes'],
    );
  }
}
