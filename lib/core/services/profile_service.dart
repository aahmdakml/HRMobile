import 'package:dio/dio.dart';
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

  /// Update personal data
  static Future<ProfileResult<bool>> updatePersonalData(
      Map<String, dynamic> data) async {
    try {
      final response =
          await apiClient.post('/hris/profile/personal-data', data: data);
      if (response.statusCode == 200) {
        return ProfileResult.success(true);
      }
      return ProfileResult.failure(
          response.data['message'] ?? 'Failed to update');
    } catch (e) {
      debugPrint('PROFILE UPDATE ERROR: $e');
      if (e is DioException) {
        return ProfileResult.failure(
            e.response?.data['message'] ?? e.message ?? 'Connection error');
      }
      return ProfileResult.failure(e.toString());
    }
  }

  /// Get addresses
  static Future<ProfileResult<List<Address>>> getAddresses() async {
    try {
      final response = await apiClient.get('/hris/profile/address');
      if (response.statusCode == 200) {
        // Backend returns: {data: {data: [...], count: N}}
        final wrapper = response.data['data'];
        var rawData = wrapper?['data'];
        List<dynamic> data = rawData is List ? rawData : [];
        return ProfileResult.success(
          data.map((e) => Address.fromJson(e as Map<String, dynamic>)).toList(),
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
        // Backend returns: {data: {data: [...], count: N}}
        final wrapper = response.data['data'];
        var rawData = wrapper?['data'];
        List<dynamic> data = rawData is List ? rawData : [];
        return ProfileResult.success(
          data.map((e) => Contact.fromJson(e as Map<String, dynamic>)).toList(),
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
        // Backend returns: {data: {data: [...], count: N}}
        final wrapper = response.data['data'];
        var rawData = wrapper?['data'];
        List<dynamic> data = rawData is List ? rawData : [];
        return ProfileResult.success(
          data.map((e) => Family.fromJson(e as Map<String, dynamic>)).toList(),
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
        // Backend returns: {data: {data: [...], count: N}}
        final wrapper = response.data['data'];
        var rawData = wrapper?['data'];
        List<dynamic> data = rawData is List ? rawData : [];
        return ProfileResult.success(
          data
              .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }
      return ProfileResult.failure(
          response.data['message'] ?? 'Failed to load');
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
      return ProfileResult.failure('Connection error');
    }
  }

  /// Get supporting files
  static Future<ProfileResult<List<SupportingFile>>>
      getSupportingFiles() async {
    try {
      final response = await apiClient.get('/hris/profile/supporting-file');
      if (response.statusCode == 200) {
        final rawData = response.data['data']['data']; // Pagination wrapper
        List<dynamic> data = rawData is List ? rawData : [];
        return ProfileResult.success(
          data.map((e) => SupportingFile.fromJson(e)).toList(),
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

  // ============ Delete Methods ============

  static Future<bool> deleteAddress(int id) async {
    return _deleteItem('/hris/profile/address/$id');
  }

  static Future<bool> deleteContact(int id) async {
    return _deleteItem('/hris/profile/contact/$id');
  }

  static Future<bool> deleteEmergencyContact(int id) async {
    return _deleteItem('/hris/profile/emergency-contact/$id');
  }

  static Future<bool> deleteFamily(int id) async {
    return _deleteItem('/hris/profile/family/$id');
  }

  static Future<bool> deleteEducation(int id) async {
    return _deleteItem('/hris/profile/education/$id');
  }

  static Future<bool> deleteSupportingFile(int id) async {
    return _deleteItem('/hris/profile/supporting-file/$id');
  }

  // Helper for delete operations
  static Future<bool> _deleteItem(String endpoint) async {
    try {
      final response = await apiClient.delete(endpoint);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting item at $endpoint: $e');
      return false;
    }
  }

  // ============ Create/Update Methods ============

  /// Create a new address
  static Future<ProfileResult<Address>> createAddress(
      Map<String, dynamic> data) async {
    try {
      final response =
          await apiClient.post('/hris/profile/address', data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ProfileResult.success(Address.fromJson(response.data['data']));
      }
      return ProfileResult.failure(
          response.data['message'] ?? 'Failed to create address');
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
      return ProfileResult.failure('Connection error');
    }
  }

  /// Update an existing address
  static Future<ProfileResult<Address>> updateAddress(
      int id, Map<String, dynamic> data) async {
    try {
      final response =
          await apiClient.put('/hris/profile/address/$id', data: data);
      if (response.statusCode == 200) {
        return ProfileResult.success(Address.fromJson(response.data['data']));
      }
      return ProfileResult.failure(
          response.data['message'] ?? 'Failed to update address');
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
      return ProfileResult.failure('Connection error');
    }
  }

  /// Create a new contact
  static Future<ProfileResult<Contact>> createContact(
      Map<String, dynamic> data) async {
    try {
      final response =
          await apiClient.post('/hris/profile/contact', data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ProfileResult.success(Contact.fromJson(response.data['data']));
      }
      return ProfileResult.failure(
          response.data['message'] ?? 'Failed to create contact');
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
      return ProfileResult.failure('Connection error');
    }
  }

  /// Update an existing contact
  static Future<ProfileResult<Contact>> updateContact(
      int id, Map<String, dynamic> data) async {
    try {
      final response =
          await apiClient.put('/hris/profile/contact/$id', data: data);
      if (response.statusCode == 200) {
        return ProfileResult.success(Contact.fromJson(
            response.data['data']['data'] ?? response.data['data']));
      }
      return ProfileResult.failure(
          response.data['message'] ?? 'Failed to update contact');
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
      return ProfileResult.failure('Connection error');
    }
  }

  /// Create a new family member
  static Future<ProfileResult<Family>> createFamily(
      Map<String, dynamic> data) async {
    try {
      final response = await apiClient.post('/hris/profile/family', data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ProfileResult.success(Family.fromJson(response.data['data']));
      }
      return ProfileResult.failure(
          response.data['message'] ?? 'Failed to create family member');
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
      return ProfileResult.failure('Connection error');
    }
  }

  /// Update an existing family member
  static Future<ProfileResult<Family>> updateFamily(
      int id, Map<String, dynamic> data) async {
    try {
      final response =
          await apiClient.put('/hris/profile/family/$id', data: data);
      if (response.statusCode == 200) {
        final respData = response.data['data'];
        return ProfileResult.success(
            Family.fromJson(respData['data'] ?? respData));
      }
      return ProfileResult.failure(
          response.data['message'] ?? 'Failed to update family member');
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
      return ProfileResult.failure('Connection error');
    }
  }

  /// Create a new education record
  static Future<ProfileResult<Education>> createEducation(
      Map<String, dynamic> data) async {
    try {
      final response =
          await apiClient.post('/hris/profile/education', data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ProfileResult.success(Education.fromJson(response.data['data']));
      }
      return ProfileResult.failure(
          response.data['message'] ?? 'Failed to create education');
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
      return ProfileResult.failure('Connection error');
    }
  }

  /// Update an existing education record
  static Future<ProfileResult<Education>> updateEducation(
      int id, Map<String, dynamic> data) async {
    try {
      final response =
          await apiClient.put('/hris/profile/education/$id', data: data);
      if (response.statusCode == 200) {
        return ProfileResult.success(Education.fromJson(response.data['data']));
      }
      return ProfileResult.failure(
          response.data['message'] ?? 'Failed to update education');
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
      return ProfileResult.failure('Connection error');
    }
  }

  /// Create a new emergency contact
  static Future<ProfileResult<EmergencyContact>> createEmergencyContact(
      Map<String, dynamic> data) async {
    try {
      final response =
          await apiClient.post('/hris/profile/emergency-contact', data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ProfileResult.success(
            EmergencyContact.fromJson(response.data['data']));
      }
      return ProfileResult.failure(
          response.data['message'] ?? 'Failed to create emergency contact');
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
      return ProfileResult.failure('Connection error');
    }
  }

  /// Update an existing emergency contact
  static Future<ProfileResult<EmergencyContact>> updateEmergencyContact(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await apiClient
          .put('/hris/profile/emergency-contact/$id', data: data);
      if (response.statusCode == 200) {
        return ProfileResult.success(
            EmergencyContact.fromJson(response.data['data']));
      }
      return ProfileResult.failure(
          response.data['message'] ?? 'Failed to update emergency contact');
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
      return ProfileResult.failure('Connection error');
    }
  }

  /// Create a new supporting file (multipart upload)
  static Future<ProfileResult<SupportingFile>> createSupportingFile(
      String fileType, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'efl_type': fileType,
        'efl_file': await MultipartFile.fromFile(filePath,
            filename: filePath.split('/').last),
      });
      final response =
          await apiClient.post('/hris/profile/supporting-file', data: formData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ProfileResult.success(
            SupportingFile.fromJson(response.data['data']));
      }
      return ProfileResult.failure(
          response.data['message'] ?? 'Failed to upload file');
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
      return ProfileResult.failure('Connection error');
    }
  }

  /// Update an existing supporting file
  static Future<ProfileResult<SupportingFile>> updateSupportingFile(int id,
      {String? fileType, String? filePath}) async {
    try {
      final Map<String, dynamic> formMap = {};
      if (fileType != null) formMap['efl_type'] = fileType;
      if (filePath != null) {
        formMap['efl_file'] = await MultipartFile.fromFile(filePath,
            filename: filePath.split('/').last);
      }
      final formData = FormData.fromMap(formMap);
      final response = await apiClient.put('/hris/profile/supporting-file/$id',
          data: formData);
      if (response.statusCode == 200) {
        final respData = response.data['data'];
        return ProfileResult.success(
            SupportingFile.fromJson(respData['data'] ?? respData));
      }
      return ProfileResult.failure(
          response.data['message'] ?? 'Failed to update file');
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
      return ProfileResult.failure('Connection error');
    }
  }

  /// Get supporting file URL for viewing
  static Future<ProfileResult<String>> getSupportingFileUrl(int id) async {
    try {
      final response = await apiClient.get('/hris/profile/supporting-file/$id');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        return ProfileResult.success(data['efl_file'] ?? '');
      }
      return ProfileResult.failure(
          response.data['message'] ?? 'Failed to get file');
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
      return ProfileResult.failure('Connection error');
    }
  }

  // ============ Location Data Methods (for Address form) ============

  static Future<ProfileResult<List<Map<String, dynamic>>>>
      getProvinces() async {
    try {
      final response = await apiClient.get('/province');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List? ?? [];
        return ProfileResult.success(data.cast<Map<String, dynamic>>());
      }
      return ProfileResult.failure('Failed to load provinces');
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
      return ProfileResult.failure('Connection error');
    }
  }

  static Future<ProfileResult<List<Map<String, dynamic>>>> getCities(
      String provinceCode) async {
    try {
      final response = await apiClient.get('/province/$provinceCode/regency');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List? ?? [];
        return ProfileResult.success(data.cast<Map<String, dynamic>>());
      }
      return ProfileResult.failure('Failed to load cities');
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
      return ProfileResult.failure('Connection error');
    }
  }

  static Future<ProfileResult<List<Map<String, dynamic>>>> getDistricts(
      String provinceCode, String regencyCode) async {
    try {
      final response = await apiClient
          .get('/province/$provinceCode/regency/$regencyCode/district');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List? ?? [];
        return ProfileResult.success(data.cast<Map<String, dynamic>>());
      }
      return ProfileResult.failure('Failed to load districts');
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
      return ProfileResult.failure('Connection error');
    }
  }

  static Future<ProfileResult<List<Map<String, dynamic>>>> getVillages(
      String provinceCode, String regencyCode, String districtCode) async {
    try {
      final response = await apiClient.get(
          '/province/$provinceCode/regency/$regencyCode/district/$districtCode/village');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List? ?? [];
        return ProfileResult.success(data.cast<Map<String, dynamic>>());
      }
      return ProfileResult.failure('Failed to load villages');
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
  final String? birthPlace;
  final String? gender;
  final String? religion;
  final String? maritalStatus;
  final String? bloodType;
  final String? ktp;
  final String? npwp;
  final String? address;

  PersonalData({
    required this.empId,
    required this.name,
    this.email,
    this.phone,
    this.birthDate,
    this.birthPlace,
    this.gender,
    this.religion,
    this.maritalStatus,
    this.bloodType,
    this.ktp,
    this.npwp,
    this.address,
  });

  factory PersonalData.fromJson(Map<String, dynamic> json) {
    return PersonalData(
      empId: json['emp_id'] ?? '',
      name: json['emp_full_name'] ?? json['emp_name'] ?? '',
      email: json['emp_email'],
      phone: json['emp_tlp'] ?? json['emp_phone'],
      birthDate: json['emp_birth_date'],
      birthPlace: json['emp_birth_place'],
      gender: json['emp_gender'],
      religion: json['emp_religion'],
      maritalStatus: json['emp_marital_status'],
      bloodType: json['emp_blood_type'],
      ktp: json['emp_ktp'],
      npwp: json['emp_npwp'],
      address: json['emp_address'],
    );
  }
}

class Address {
  final int id;
  final String
      type; // Not explicitly in Vue but good to keep if backend sends it
  final String address;
  final String? city;
  final String? province;
  final String? district;
  final String? village;
  final String? postalCode;
  final bool isPrimary;

  Address({
    required this.id,
    required this.type,
    required this.address,
    this.city,
    this.province,
    this.district,
    this.village,
    this.postalCode,
    this.isPrimary = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['ed_id'] ?? json['id'] ?? 0,
      type: json['addr_type'] ?? '', // Vue doesn't show type, but backend might
      address: json['ed_address'] ?? json['address'] ?? '',
      city: json['regency']?['regency_name'] ?? json['addr_city'],
      province: json['province']?['province_name'] ?? json['addr_province'],
      district: json['district']?['district_name'],
      village: json['village']?['village_name'],
      postalCode: json['ed_zip_code'] ?? json['postal_code'],
      isPrimary: json['ed_is_primary'] == 1 || json['ed_is_primary'] == true,
    );
  }
}

class Contact {
  final int id;
  final String type;
  final String value;
  final bool isPrimary;

  Contact({
    required this.id,
    required this.type,
    required this.value,
    this.isPrimary = false,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['ec_id'] ?? json['id'] ?? 0,
      type: json['ec_type'] ?? json['contact_type'] ?? '',
      value: json['ec_value'] ?? json['contact_value'] ?? '',
      isPrimary: json['ec_is_primary'] == 1 || json['ec_is_primary'] == true,
    );
  }
}

class Family {
  final int id;
  final String name;
  final String relationship;
  final String? birthDate;
  final String? gender;
  final bool isBpjsCovered;

  Family({
    required this.id,
    required this.name,
    required this.relationship,
    this.birthDate,
    this.gender,
    this.isBpjsCovered = false,
  });

  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      id: json['ef_id'] ?? json['id'] ?? 0,
      name: json['ef_name'] ?? json['fam_name'] ?? '',
      relationship:
          json['relationship']?['trx_name'] ?? json['fam_relationship'] ?? '',
      birthDate: json['ef_birthday'] ?? json['fam_birth_date'],
      gender: json['ef_gender'],
      isBpjsCovered:
          json['ef_cover_bpjs'] == 1 || json['ef_cover_bpjs'] == true,
    );
  }
}

class Education {
  final int id;
  final String level;
  final String institution;
  final String? major;
  final String? startYear;
  final String? endYear;
  final String? gpa;

  Education({
    required this.id,
    required this.level,
    required this.institution,
    this.major,
    this.startYear,
    this.endYear,
    this.gpa,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      id: json['edu_id'] ?? json['id'] ?? 0,
      level: json['edu_level'] ?? '',
      institution: json['institution_name'] ?? json['edu_institution'] ?? '',
      major: json['major_name'] ?? json['edu_major'],
      startYear: json['edu_start']?.toString(),
      endYear: json['edu_end']?.toString(),
      gpa: json['edu_gpa']?.toString(),
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
      id: json['emp_ec_id'] ?? json['id'] ?? 0,
      name: json['emp_ec_name'] ?? '',
      relationship: json['emp_ec_relationship'] ?? '',
      phone: json['emp_ec_phone'] ?? '',
      address: json['emp_ec_address'],
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

class SupportingFile {
  final int id;
  final String fileName; // extracted from URL
  final String fileUrl;
  final String type;
  final String? uploadDate;

  SupportingFile({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.type,
    this.uploadDate,
  });

  factory SupportingFile.fromJson(Map<String, dynamic> json) {
    final url = json['efl_file'] ?? '';
    final name = url.toString().split('/').last;
    return SupportingFile(
      id: json['efl_id'] ?? 0,
      fileName: name,
      fileUrl: url,
      type: json['file_type']?['trx_name'] ?? '-',
      uploadDate: json['created_at'],
    );
  }
}
