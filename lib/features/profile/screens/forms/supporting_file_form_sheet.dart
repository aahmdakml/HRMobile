import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import 'package:mobile_app/core/services/profile_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bottom sheet form for adding/editing supporting files
class SupportingFileFormSheet extends StatefulWidget {
  final SupportingFile? file; // null for create, non-null for edit

  const SupportingFileFormSheet({super.key, this.file});

  static Future<bool?> show(BuildContext context, {SupportingFile? file}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SupportingFileFormSheet(file: file),
    );
  }

  /// Open file for viewing
  static Future<void> viewFile(BuildContext context, int fileId) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final result = await ProfileService.getSupportingFileUrl(fileId);

    if (context.mounted) {
      Navigator.pop(context); // Close loading
    }

    if (result.success && result.data != null && result.data!.isNotEmpty) {
      final uri = Uri.parse(result.data!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot open file'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Failed to get file URL'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  State<SupportingFileFormSheet> createState() =>
      _SupportingFileFormSheetState();
}

class _SupportingFileFormSheetState extends State<SupportingFileFormSheet> {
  final _formKey = GlobalKey<FormState>();
  String _fileType = 'KTP';
  String? _selectedFilePath;
  String? _selectedFileName;
  bool _isLoading = false;

  // File type options
  final List<Map<String, dynamic>> _fileTypeOptions = [
    {'id': 'KTP', 'name': 'KTP (ID Card)', 'icon': Icons.credit_card},
    {'id': 'KK', 'name': 'Kartu Keluarga', 'icon': Icons.family_restroom},
    {'id': 'NPWP', 'name': 'NPWP (Tax ID)', 'icon': Icons.receipt_long},
    {'id': 'IJAZAH', 'name': 'Ijazah (Diploma)', 'icon': Icons.school},
    {'id': 'SERTIFIKAT', 'name': 'Sertifikat', 'icon': Icons.workspace_premium},
    {'id': 'CV', 'name': 'CV / Resume', 'icon': Icons.description},
    {'id': 'LAINNYA', 'name': 'Lainnya (Other)', 'icon': Icons.folder},
  ];

  bool get isEdit => widget.file != null;

  @override
  void initState() {
    super.initState();
    if (widget.file != null) {
      _fileType = widget.file!.type;
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (!isEdit && _selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    ProfileResult<SupportingFile> result;

    if (isEdit) {
      result = await ProfileService.updateSupportingFile(
        widget.file!.id,
        fileType: _fileType,
        filePath: _selectedFilePath,
      );
    } else {
      result = await ProfileService.createSupportingFile(
        _fileType,
        _selectedFilePath!,
      );
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'File updated' : 'File uploaded'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to save file'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.upload_file,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit File' : 'Upload File',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Select file type and upload',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File Type
                    _buildLabel('File Type'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _fileTypeOptions.map((type) {
                        final isSelected = _fileType == type['id'];
                        return GestureDetector(
                          onTap: () => setState(() => _fileType = type['id']),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withAlpha(20)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  type['icon'] as IconData,
                                  size: 16,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  type['name'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // File Picker
                    _buildLabel('Select File'),
                    GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _selectedFileName != null
                                  ? Icons.insert_drive_file
                                  : Icons.cloud_upload_outlined,
                              size: 48,
                              color: _selectedFileName != null
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedFileName ?? 'Tap to select file',
                              style: TextStyle(
                                color: _selectedFileName != null
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_selectedFileName == null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'PDF, DOC, DOCX, JPG, PNG (max 10MB)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    if (isEdit && widget.file != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Current file: ${widget.file!.fileName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Save button
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isEdit ? 'Update' : 'Upload File',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
