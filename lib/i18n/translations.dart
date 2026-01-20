// Generated from i18n YAML files
// Base locale: en

import 'package:flutter/widgets.dart';

/// Global translations accessor
Translations get t => LocaleSettings.currentTranslations;

class LocaleSettings {
  static Translations _currentTranslations = TranslationsEn();
  static Locale _currentLocale = const Locale('en');

  static Translations get currentTranslations => _currentTranslations;
  static Locale get currentLocale => _currentLocale;

  static List<Locale> get supportedLocales => const [
        Locale('en'),
        Locale('id'),
      ];

  static void setLocale(Locale locale) {
    _currentLocale = locale;
    if (locale.languageCode == 'id') {
      _currentTranslations = TranslationsId();
    } else {
      _currentTranslations = TranslationsEn();
    }
  }

  static void setLocaleRaw(String languageCode) {
    setLocale(Locale(languageCode));
  }
}

/// Get translated module name by database key
String translateModuleKey(String key) {
  return t.module.byKey(key) ?? key;
}

// ============ Base Translations Class ============

abstract class Translations {
  AppTranslations get app;
  CommonTranslations get common;
  ModuleTranslations get module;
  ProfileTranslations get profile;
  AuthTranslations get auth;
  SettingsTranslations get settings;
  HomeTranslations get home;
  AttendanceTranslations get attendance;
}

// ============ Section Classes ============

abstract class AppTranslations {
  String get name;
  String get tagline;
}

abstract class CommonTranslations {
  String get cancel;
  String get save;
  String get delete;
  String get edit;
  String get add;
  String get back;
  String get close;
  String get search;
  String get refresh;
  String get loading;
  String get success;
  String get error;
  String get tapToOpen;
  String get comingSoon;
  String get noData;
}

abstract class ModuleTranslations {
  String get dashboard;
  String get attendance;
  String get employee;
  String get payroll;
  String get reports;
  String get approval;
  String get recruitment;
  String get organization;
  String get masterPayroll;
  String get clockIn;
  String get clockOut;
  String get leave;
  String get permission;
  String get leaveAndPermission;
  String get overtime;
  String get publicHolidays;
  String get timeOffManagement;
  String get leaveBalance;
  String get travelOrder;
  String get payslip;
  String get processPayroll;
  String get payrollSummary;
  String get payrollCorrection;
  String get payrollLoan;
  String get paySlipComponent;
  String get importsOvertime;
  String get employeeSalaryComponent;
  String get companyComponent;
  String get masterBpjs;
  String get masterBpjsCompany;
  String get masterAttendanceDeduction;
  String get myPersonalInfo;
  String get reportsPayrollSummary;
  String get reportsPayrollSlipEmployee;
  String get reportsPayrollRecapitulation;
  String get reportsAttendance;
  String get reportsSam;
  String get reportPayrollTr;
  String get reportsEmployeeStatus;
  String get approvalTravelOrder;
  String get information;
  String get survey;
  String get onBoarding;
  String get employeeLetter;
  String get profile;
  String get loan;
  String get loanArchive;
  String get reimburse;
  String get reimbursementBalance;
  String get travel;
  String get masterMenu;
  String get masterRole;
  String get masterRoleMenu;
  String get masterUser;
  String get masterOption;
  String get masterPasswordMenuCompany;
  String get archiveDocument;
  String get loanArchiveForm;
  String get masterArchiveLocation;
  String get masterDocument;
  String get portalDocument;
  String get manPowerPlanning;
  String get requestMpp;
  String get approveMpp;
  String get loadMpp;
  String get directorate;
  String get subDirectorate;
  String get department;
  String get subDepartment;
  String get section;
  String get unit;
  String get position;
  String get organizationChart;
  String get empOrgMapping;

  /// Get translation by database key
  String? byKey(String key);
}

abstract class ProfileTranslations {
  String get title;
  String get personalData;
  String get address;
  String get contact;
  String get family;
  String get education;
  String get emergencyContact;
  String get employmentData;
  String get attendanceHistory;
  String get loanHistory;
  String get salaryHistory;
  String get supportingFile;
}

abstract class AuthTranslations {
  String get login;
  String get logout;
  String get forgotPassword;
  String get changePassword;
  String get resetPassword;
  String get email;
  String get password;
  String get confirmPassword;
  String get rememberMe;
}

abstract class SettingsTranslations {
  String get title;
  String get account;
  String get notifications;
  String get language;
  String get theme;
  String get darkMode;
  String get about;
  String get version;
  String get privacy;
  String get terms;
  String get help;
}

abstract class HomeTranslations {
  HomeGreetingTranslations get greeting;
  String get quickAccess;
  String get modules;
  String get recentActivity;
  String get customize;
  String get viewAll;
  String get allModules;
}

abstract class HomeGreetingTranslations {
  String get morning;
  String get afternoon;
  String get evening;
}

abstract class AttendanceTranslations {
  String get title;
  String get clockIn;
  String get clockOut;
  String get history;
  String get today;
  String get present;
  String get absent;
  String get late;
  String get early;
  String get workingHours;
  String get location;
}

// ============ English Translations ============

class TranslationsEn implements Translations {
  @override
  AppTranslationsEn get app => AppTranslationsEn();
  @override
  CommonTranslationsEn get common => CommonTranslationsEn();
  @override
  ModuleTranslationsEn get module => ModuleTranslationsEn();
  @override
  ProfileTranslationsEn get profile => ProfileTranslationsEn();
  @override
  AuthTranslationsEn get auth => AuthTranslationsEn();
  @override
  SettingsTranslationsEn get settings => SettingsTranslationsEn();
  @override
  HomeTranslationsEn get home => HomeTranslationsEn();
  @override
  AttendanceTranslationsEn get attendance => AttendanceTranslationsEn();
}

class AppTranslationsEn implements AppTranslations {
  @override
  String get name => 'HRIS Mobile';
  @override
  String get tagline => 'Employee Self Service';
}

class CommonTranslationsEn implements CommonTranslations {
  @override
  String get cancel => 'Cancel';
  @override
  String get save => 'Save';
  @override
  String get delete => 'Delete';
  @override
  String get edit => 'Edit';
  @override
  String get add => 'Add';
  @override
  String get back => 'Back';
  @override
  String get close => 'Close';
  @override
  String get search => 'Search';
  @override
  String get refresh => 'Refresh';
  @override
  String get loading => 'Loading...';
  @override
  String get success => 'Success';
  @override
  String get error => 'Error';
  @override
  String get tapToOpen => 'Tap to open';
  @override
  String get comingSoon => 'Coming soon';
  @override
  String get noData => 'No data available';
}

class ModuleTranslationsEn implements ModuleTranslations {
  @override
  String get dashboard => 'Dashboard';
  @override
  String get attendance => 'Attendance';
  @override
  String get employee => 'Employee';
  @override
  String get payroll => 'Payroll';
  @override
  String get reports => 'Reports';
  @override
  String get approval => 'Approval';
  @override
  String get recruitment => 'Recruitment';
  @override
  String get organization => 'Organization';
  @override
  String get masterPayroll => 'Master Payroll';
  @override
  String get clockIn => 'Clock In';
  @override
  String get clockOut => 'Clock Out';
  @override
  String get leave => 'Leave';
  @override
  String get permission => 'Permission';
  @override
  String get leaveAndPermission => 'Leave & Permission';
  @override
  String get overtime => 'Overtime';
  @override
  String get publicHolidays => 'Holidays & Collective Leave';
  @override
  String get timeOffManagement => 'Time Off Management';
  @override
  String get leaveBalance => 'Leave Balance';
  @override
  String get travelOrder => 'Travel Order';
  @override
  String get payslip => 'Payslip';
  @override
  String get processPayroll => 'Process Payroll';
  @override
  String get payrollSummary => 'Payroll Summary';
  @override
  String get payrollCorrection => 'Payroll Correction';
  @override
  String get payrollLoan => 'Payroll Loan';
  @override
  String get paySlipComponent => 'Pay Slip Component';
  @override
  String get importsOvertime => 'Imports Overtime';
  @override
  String get employeeSalaryComponent => 'Employee Component';
  @override
  String get companyComponent => 'Company Component';
  @override
  String get masterBpjs => 'Master BPJS';
  @override
  String get masterBpjsCompany => 'Master BPJS Company';
  @override
  String get masterAttendanceDeduction => 'Attendance Deduction';
  @override
  String get myPersonalInfo => 'My Personal Info';
  @override
  String get reportsPayrollSummary => 'Reports Payroll Summary';
  @override
  String get reportsPayrollSlipEmployee => 'Reports Payroll Slip';
  @override
  String get reportsPayrollRecapitulation => 'Payroll Recapitulation';
  @override
  String get reportsAttendance => 'Reports Attendance';
  @override
  String get reportsSam => 'Reports Attendance 2';
  @override
  String get reportPayrollTr => 'Report Payroll TR';
  @override
  String get reportsEmployeeStatus => 'Employee Status Report';
  @override
  String get approvalTravelOrder => 'Approval Travel Order';
  @override
  String get information => 'Information';
  @override
  String get survey => 'Survey';
  @override
  String get onBoarding => 'Onboarding';
  @override
  String get employeeLetter => 'Employee Letter';
  @override
  String get profile => 'Profile';
  @override
  String get loan => 'Loan';
  @override
  String get loanArchive => 'Loan List';
  @override
  String get reimburse => 'Reimbursement';
  @override
  String get reimbursementBalance => 'Reimbursement Balance';
  @override
  String get travel => 'Travel';
  @override
  String get masterMenu => 'Master Menu';
  @override
  String get masterRole => 'Master Role';
  @override
  String get masterRoleMenu => 'Master Role Menu';
  @override
  String get masterUser => 'Master User';
  @override
  String get masterOption => 'Master Option';
  @override
  String get masterPasswordMenuCompany => 'Password Menu Company';
  @override
  String get archiveDocument => 'Archive Document';
  @override
  String get loanArchiveForm => 'Loan Archive Form';
  @override
  String get masterArchiveLocation => 'Master Location Archive';
  @override
  String get masterDocument => 'Master Document';
  @override
  String get portalDocument => 'Portal Document';
  @override
  String get manPowerPlanning => 'Man Power Planning';
  @override
  String get requestMpp => 'Request MPP';
  @override
  String get approveMpp => 'Approve MPP';
  @override
  String get loadMpp => 'Load MPP';
  @override
  String get directorate => 'Directorate';
  @override
  String get subDirectorate => 'Sub Directorate';
  @override
  String get department => 'Department';
  @override
  String get subDepartment => 'Sub Department';
  @override
  String get section => 'Section';
  @override
  String get unit => 'Unit';
  @override
  String get position => 'Position';
  @override
  String get organizationChart => 'Organization Chart';
  @override
  String get empOrgMapping => 'Employee Org Mapping';

  @override
  String? byKey(String key) {
    final map = <String, String>{
      'dashboard': dashboard,
      'attendance': attendance,
      'Attendance': attendance,
      'employee': employee,
      'payroll': payroll,
      'Payroll': payroll,
      'reports': reports,
      'approval': approval,
      'recruitment': recruitment,
      'organization': organization,
      'masterPayroll': masterPayroll,
      'clockIn': clockIn,
      'clock_in': clockIn,
      'clockOut': clockOut,
      'leave': leave,
      'permission': permission,
      'leaveAndPermission': leaveAndPermission,
      'overtime': overtime,
      'publicHolidays': publicHolidays,
      'timeOffManagement': timeOffManagement,
      'leaveBalance': leaveBalance,
      'travelOrder': travelOrder,
      'payslip': payslip,
      'processPayroll': processPayroll,
      'payrollSummary': payrollSummary,
      'payrollCorrection': payrollCorrection,
      'payrollLoan': payrollLoan,
      'paySlipComponent': paySlipComponent,
      'importsOvertime': importsOvertime,
      'employeeSalaryComponent': employeeSalaryComponent,
      'companyComponent': companyComponent,
      'masterBpjs': masterBpjs,
      'masterBpjsCompany': masterBpjsCompany,
      'masterAttendanceDeduction': masterAttendanceDeduction,
      'myPersonalInfo': myPersonalInfo,
      'reportsPayrollSummary': reportsPayrollSummary,
      'reportsPayrollSlipEmployee': reportsPayrollSlipEmployee,
      'reportsPayrollRecapitulation': reportsPayrollRecapitulation,
      'reportsAttendance': reportsAttendance,
      'reportsSam': reportsSam,
      'reportPayrollTr': reportPayrollTr,
      'reportsEmployeeStatus': reportsEmployeeStatus,
      'approvalTravelOrder': approvalTravelOrder,
      'information': information,
      'survey': survey,
      'onBoarding': onBoarding,
      'employeeLetter': employeeLetter,
      'profile': profile,
      'loan': loan,
      'loanArchive': loanArchive,
      'reimburse': reimburse,
      'reimbursementBalance': reimbursementBalance,
      'travel': travel,
      'masterMenu': masterMenu,
      'masterRole': masterRole,
      'masterRoleMenu': masterRoleMenu,
      'masterUser': masterUser,
      'masterOption': masterOption,
      'masterPasswordMenuCompany': masterPasswordMenuCompany,
      'archiveDocument': archiveDocument,
      'loanArchiveForm': loanArchiveForm,
      'masterArchiveLocation': masterArchiveLocation,
      'masterDocument': masterDocument,
      'portalDocument': portalDocument,
      'manPowerPlanning': manPowerPlanning,
      'requestMpp': requestMpp,
      'approveMpp': approveMpp,
      'loadMpp': loadMpp,
      'directorate': directorate,
      'subDirectorate': subDirectorate,
      'department': department,
      'subDepartment': subDepartment,
      'section': section,
      'unit': unit,
      'position': position,
      'organizationChart': organizationChart,
      'empOrgMapping': empOrgMapping,
    };
    return map[key];
  }
}

class ProfileTranslationsEn implements ProfileTranslations {
  @override
  String get title => 'Profile';
  @override
  String get personalData => 'Personal Data';
  @override
  String get address => 'Address';
  @override
  String get contact => 'Contact';
  @override
  String get family => 'Family';
  @override
  String get education => 'Education';
  @override
  String get emergencyContact => 'Emergency Contact';
  @override
  String get employmentData => 'Employment Data';
  @override
  String get attendanceHistory => 'Attendance History';
  @override
  String get loanHistory => 'Loan History';
  @override
  String get salaryHistory => 'Salary History';
  @override
  String get supportingFile => 'Supporting File';
}

class AuthTranslationsEn implements AuthTranslations {
  @override
  String get login => 'Sign In';
  @override
  String get logout => 'Sign Out';
  @override
  String get forgotPassword => 'Forgot Password';
  @override
  String get changePassword => 'Change Password';
  @override
  String get resetPassword => 'Reset Password';
  @override
  String get email => 'Email';
  @override
  String get password => 'Password';
  @override
  String get confirmPassword => 'Confirm Password';
  @override
  String get rememberMe => 'Remember Me';
}

class SettingsTranslationsEn implements SettingsTranslations {
  @override
  String get title => 'Settings';
  @override
  String get account => 'Account';
  @override
  String get notifications => 'Notifications';
  @override
  String get language => 'Language';
  @override
  String get theme => 'Theme';
  @override
  String get darkMode => 'Dark Mode';
  @override
  String get about => 'About';
  @override
  String get version => 'Version';
  @override
  String get privacy => 'Privacy Policy';
  @override
  String get terms => 'Terms of Service';
  @override
  String get help => 'Help & Support';
}

class HomeTranslationsEn implements HomeTranslations {
  @override
  HomeGreetingTranslationsEn get greeting => HomeGreetingTranslationsEn();
  @override
  String get quickAccess => 'Quick Access';
  @override
  String get modules => 'Modules';
  @override
  String get recentActivity => 'Recent Activity';
  @override
  String get customize => 'Customize';
  @override
  String get viewAll => 'View All';
  @override
  String get allModules => 'All Modules';
}

class HomeGreetingTranslationsEn implements HomeGreetingTranslations {
  @override
  String get morning => 'Good Morning!';
  @override
  String get afternoon => 'Good Afternoon!';
  @override
  String get evening => 'Good Evening!';
}

class AttendanceTranslationsEn implements AttendanceTranslations {
  @override
  String get title => 'Attendance';
  @override
  String get clockIn => 'Clock In';
  @override
  String get clockOut => 'Clock Out';
  @override
  String get history => 'History';
  @override
  String get today => 'Today';
  @override
  String get present => 'Present';
  @override
  String get absent => 'Absent';
  @override
  String get late => 'Late';
  @override
  String get early => 'Early Leave';
  @override
  String get workingHours => 'Working Hours';
  @override
  String get location => 'Location';
}

// ============ Indonesian Translations ============

class TranslationsId implements Translations {
  @override
  AppTranslationsId get app => AppTranslationsId();
  @override
  CommonTranslationsId get common => CommonTranslationsId();
  @override
  ModuleTranslationsId get module => ModuleTranslationsId();
  @override
  ProfileTranslationsId get profile => ProfileTranslationsId();
  @override
  AuthTranslationsId get auth => AuthTranslationsId();
  @override
  SettingsTranslationsId get settings => SettingsTranslationsId();
  @override
  HomeTranslationsId get home => HomeTranslationsId();
  @override
  AttendanceTranslationsId get attendance => AttendanceTranslationsId();
}

class AppTranslationsId implements AppTranslations {
  @override
  String get name => 'HRIS Mobile';
  @override
  String get tagline => 'Layanan Mandiri Karyawan';
}

class CommonTranslationsId implements CommonTranslations {
  @override
  String get cancel => 'Batal';
  @override
  String get save => 'Simpan';
  @override
  String get delete => 'Hapus';
  @override
  String get edit => 'Ubah';
  @override
  String get add => 'Tambah';
  @override
  String get back => 'Kembali';
  @override
  String get close => 'Tutup';
  @override
  String get search => 'Cari';
  @override
  String get refresh => 'Refresh';
  @override
  String get loading => 'Memuat...';
  @override
  String get success => 'Berhasil';
  @override
  String get error => 'Kesalahan';
  @override
  String get tapToOpen => 'Ketuk untuk buka';
  @override
  String get comingSoon => 'Segera hadir';
  @override
  String get noData => 'Tidak ada data';
}

class ModuleTranslationsId implements ModuleTranslations {
  @override
  String get dashboard => 'Dasbor';
  @override
  String get attendance => 'Kehadiran';
  @override
  String get employee => 'Karyawan';
  @override
  String get payroll => 'Penggajian';
  @override
  String get reports => 'Laporan';
  @override
  String get approval => 'Persetujuan';
  @override
  String get recruitment => 'Rekrutmen';
  @override
  String get organization => 'Organisasi';
  @override
  String get masterPayroll => 'Master Penggajian';
  @override
  String get clockIn => 'Masuk';
  @override
  String get clockOut => 'Pulang';
  @override
  String get leave => 'Cuti';
  @override
  String get permission => 'Izin';
  @override
  String get leaveAndPermission => 'Cuti & Izin';
  @override
  String get overtime => 'Lembur';
  @override
  String get publicHolidays => 'Libur & Cuti Bersama';
  @override
  String get timeOffManagement => 'Manajemen Izin';
  @override
  String get leaveBalance => 'Saldo Cuti';
  @override
  String get travelOrder => 'Perjalanan Dinas';
  @override
  String get payslip => 'Slip Gaji';
  @override
  String get processPayroll => 'Proses Payroll';
  @override
  String get payrollSummary => 'Ringkasan Penggajian';
  @override
  String get payrollCorrection => 'Koreksi Penggajian';
  @override
  String get payrollLoan => 'Pinjaman Payroll';
  @override
  String get paySlipComponent => 'Komponen Slip Gaji';
  @override
  String get importsOvertime => 'Impor Lembur';
  @override
  String get employeeSalaryComponent => 'Komponen Karyawan';
  @override
  String get companyComponent => 'Komponen Perusahaan';
  @override
  String get masterBpjs => 'Master BPJS';
  @override
  String get masterBpjsCompany => 'Master BPJS Perusahaan';
  @override
  String get masterAttendanceDeduction => 'Potongan Absensi';
  @override
  String get myPersonalInfo => 'Info Pribadi Saya';
  @override
  String get reportsPayrollSummary => 'Laporan Ringkasan Penggajian';
  @override
  String get reportsPayrollSlipEmployee => 'Laporan Slip Gaji';
  @override
  String get reportsPayrollRecapitulation => 'Rekapitulasi Gaji';
  @override
  String get reportsAttendance => 'Laporan Kehadiran';
  @override
  String get reportsSam => 'Laporan Kehadiran 2';
  @override
  String get reportPayrollTr => 'Laporan Payroll TR';
  @override
  String get reportsEmployeeStatus => 'Laporan Status Karyawan';
  @override
  String get approvalTravelOrder => 'Persetujuan SPPD';
  @override
  String get information => 'Informasi';
  @override
  String get survey => 'Survey';
  @override
  String get onBoarding => 'Orientasi';
  @override
  String get employeeLetter => 'Surat Karyawan';
  @override
  String get profile => 'Profil';
  @override
  String get loan => 'Pinjaman';
  @override
  String get loanArchive => 'Daftar Pinjaman';
  @override
  String get reimburse => 'Pengembalian';
  @override
  String get reimbursementBalance => 'Saldo Reimbursement';
  @override
  String get travel => 'Perjalanan';
  @override
  String get masterMenu => 'Menu Master';
  @override
  String get masterRole => 'Peran Master';
  @override
  String get masterRoleMenu => 'Peran Menu Master';
  @override
  String get masterUser => 'Pengguna Master';
  @override
  String get masterOption => 'Master Option';
  @override
  String get masterPasswordMenuCompany => 'Password Menu Perusahaan';
  @override
  String get archiveDocument => 'Dokumen Arsip';
  @override
  String get loanArchiveForm => 'Peminjaman Arsip';
  @override
  String get masterArchiveLocation => 'Master Lokasi Arsip';
  @override
  String get masterDocument => 'Dokumen Master';
  @override
  String get portalDocument => 'Portal Dokumen';
  @override
  String get manPowerPlanning => 'Perencanaan Tenaga Kerja';
  @override
  String get requestMpp => 'Permintaan MPP';
  @override
  String get approveMpp => 'Persetujuan MPP';
  @override
  String get loadMpp => 'Muat MPP';
  @override
  String get directorate => 'Direktorat';
  @override
  String get subDirectorate => 'Sub Direktorat';
  @override
  String get department => 'Departemen';
  @override
  String get subDepartment => 'Sub Departemen';
  @override
  String get section => 'Seksi';
  @override
  String get unit => 'Unit';
  @override
  String get position => 'Jabatan';
  @override
  String get organizationChart => 'Struktur Organisasi';
  @override
  String get empOrgMapping => 'Pemetaan Org Karyawan';

  @override
  String? byKey(String key) {
    final map = <String, String>{
      'dashboard': dashboard,
      'attendance': attendance,
      'Attendance': attendance,
      'employee': employee,
      'payroll': payroll,
      'Payroll': payroll,
      'reports': reports,
      'approval': approval,
      'recruitment': recruitment,
      'organization': organization,
      'masterPayroll': masterPayroll,
      'clockIn': clockIn,
      'clock_in': clockIn,
      'clockOut': clockOut,
      'leave': leave,
      'permission': permission,
      'leaveAndPermission': leaveAndPermission,
      'overtime': overtime,
      'publicHolidays': publicHolidays,
      'timeOffManagement': timeOffManagement,
      'leaveBalance': leaveBalance,
      'travelOrder': travelOrder,
      'payslip': payslip,
      'processPayroll': processPayroll,
      'payrollSummary': payrollSummary,
      'payrollCorrection': payrollCorrection,
      'payrollLoan': payrollLoan,
      'paySlipComponent': paySlipComponent,
      'importsOvertime': importsOvertime,
      'employeeSalaryComponent': employeeSalaryComponent,
      'companyComponent': companyComponent,
      'masterBpjs': masterBpjs,
      'masterBpjsCompany': masterBpjsCompany,
      'masterAttendanceDeduction': masterAttendanceDeduction,
      'myPersonalInfo': myPersonalInfo,
      'reportsPayrollSummary': reportsPayrollSummary,
      'reportsPayrollSlipEmployee': reportsPayrollSlipEmployee,
      'reportsPayrollRecapitulation': reportsPayrollRecapitulation,
      'reportsAttendance': reportsAttendance,
      'reportsSam': reportsSam,
      'reportPayrollTr': reportPayrollTr,
      'reportsEmployeeStatus': reportsEmployeeStatus,
      'approvalTravelOrder': approvalTravelOrder,
      'information': information,
      'survey': survey,
      'onBoarding': onBoarding,
      'employeeLetter': employeeLetter,
      'profile': profile,
      'loan': loan,
      'loanArchive': loanArchive,
      'reimburse': reimburse,
      'reimbursementBalance': reimbursementBalance,
      'travel': travel,
      'masterMenu': masterMenu,
      'masterRole': masterRole,
      'masterRoleMenu': masterRoleMenu,
      'masterUser': masterUser,
      'masterOption': masterOption,
      'masterPasswordMenuCompany': masterPasswordMenuCompany,
      'archiveDocument': archiveDocument,
      'loanArchiveForm': loanArchiveForm,
      'masterArchiveLocation': masterArchiveLocation,
      'masterDocument': masterDocument,
      'portalDocument': portalDocument,
      'manPowerPlanning': manPowerPlanning,
      'requestMpp': requestMpp,
      'approveMpp': approveMpp,
      'loadMpp': loadMpp,
      'directorate': directorate,
      'subDirectorate': subDirectorate,
      'department': department,
      'subDepartment': subDepartment,
      'section': section,
      'unit': unit,
      'position': position,
      'organizationChart': organizationChart,
      'empOrgMapping': empOrgMapping,
    };
    return map[key];
  }
}

class ProfileTranslationsId implements ProfileTranslations {
  @override
  String get title => 'Profil';
  @override
  String get personalData => 'Data Pribadi';
  @override
  String get address => 'Alamat';
  @override
  String get contact => 'Kontak';
  @override
  String get family => 'Keluarga';
  @override
  String get education => 'Pendidikan';
  @override
  String get emergencyContact => 'Kontak Darurat';
  @override
  String get employmentData => 'Data Kepegawaian';
  @override
  String get attendanceHistory => 'Riwayat Kehadiran';
  @override
  String get loanHistory => 'Riwayat Pinjaman';
  @override
  String get salaryHistory => 'Riwayat Gaji';
  @override
  String get supportingFile => 'File Pendukung';
}

class AuthTranslationsId implements AuthTranslations {
  @override
  String get login => 'Masuk';
  @override
  String get logout => 'Keluar';
  @override
  String get forgotPassword => 'Lupa Password';
  @override
  String get changePassword => 'Ubah Password';
  @override
  String get resetPassword => 'Reset Password';
  @override
  String get email => 'Email';
  @override
  String get password => 'Password';
  @override
  String get confirmPassword => 'Konfirmasi Password';
  @override
  String get rememberMe => 'Ingat Saya';
}

class SettingsTranslationsId implements SettingsTranslations {
  @override
  String get title => 'Pengaturan';
  @override
  String get account => 'Akun';
  @override
  String get notifications => 'Notifikasi';
  @override
  String get language => 'Bahasa';
  @override
  String get theme => 'Tema';
  @override
  String get darkMode => 'Mode Gelap';
  @override
  String get about => 'Tentang';
  @override
  String get version => 'Versi';
  @override
  String get privacy => 'Kebijakan Privasi';
  @override
  String get terms => 'Syarat & Ketentuan';
  @override
  String get help => 'Bantuan & Dukungan';
}

class HomeTranslationsId implements HomeTranslations {
  @override
  HomeGreetingTranslationsId get greeting => HomeGreetingTranslationsId();
  @override
  String get quickAccess => 'Akses Cepat';
  @override
  String get modules => 'Modul';
  @override
  String get recentActivity => 'Aktivitas Terbaru';
  @override
  String get customize => 'Kustomisasi';
  @override
  String get viewAll => 'Lihat Semua';
  @override
  String get allModules => 'Semua Modul';
}

class HomeGreetingTranslationsId implements HomeGreetingTranslations {
  @override
  String get morning => 'Selamat Pagi!';
  @override
  String get afternoon => 'Selamat Siang!';
  @override
  String get evening => 'Selamat Malam!';
}

class AttendanceTranslationsId implements AttendanceTranslations {
  @override
  String get title => 'Kehadiran';
  @override
  String get clockIn => 'Masuk';
  @override
  String get clockOut => 'Pulang';
  @override
  String get history => 'Riwayat';
  @override
  String get today => 'Hari Ini';
  @override
  String get present => 'Hadir';
  @override
  String get absent => 'Tidak Hadir';
  @override
  String get late => 'Terlambat';
  @override
  String get early => 'Pulang Awal';
  @override
  String get workingHours => 'Jam Kerja';
  @override
  String get location => 'Lokasi';
}
