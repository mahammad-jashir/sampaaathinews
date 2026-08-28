import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../themes/app_theme.dart';

class AdminPublishPage extends ConsumerStatefulWidget {
  const AdminPublishPage({super.key});

  @override
  ConsumerState<AdminPublishPage> createState() => _AdminPublishPageState();
}

class _AdminPublishPageState extends ConsumerState<AdminPublishPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _excerptController = TextEditingController();
  final _contentController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _readingTimeController = TextEditingController(text: '3');

  int? _selectedCategoryId;
  int? _selectedDistrictId;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  String? _statusMessage;
  bool _statusIsError = false;

  // Image source toggle, matching the wp-admin Publish News page: either a
  // pasted URL or a file uploaded straight into the WordPress Media Library.
  bool _useFileUpload = false;
  PlatformFile? _selectedImageFile;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _excerptController.dispose();
    _contentController.dispose();
    _imageUrlController.dispose();
    _readingTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, // needed on web to get raw bytes for upload
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _selectedImageFile = result.files.first);
    }
  }

  /// Uploads the selected file into the WordPress Media Library via our
  /// token-authenticated proxy endpoint, returning the resulting image URL.
  Future<String?> _uploadSelectedImage() async {
    if (_selectedImageFile == null || _selectedImageFile!.bytes == null) return null;

    setState(() => _isUploadingImage = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          _selectedImageFile!.bytes!,
          filename: _selectedImageFile!.name,
        ),
      });
      final response = await apiClient.dio.post('/sampathi/v1/media/upload', data: formData);
      return response.data['source_url'] as String?;
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  /// Shows a small "type a name, submit" dialog and POSTs it to the given
  /// endpoint (categories/add or districts/add). Used by the "+" buttons
  /// next to the Category/District dropdowns so an admin never has to leave
  /// the Flutter app to add one that's missing.
  Future<void> _showQuickAddDialog({
    required String title,
    required String endpoint,
    required VoidCallback onAdded,
  }) async {
    final controller = TextEditingController();
    bool isSubmitting = false;
    String? error;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                onSubmitted: (_) {},
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final name = controller.text.trim();
                      if (name.isEmpty) return;

                      setDialogState(() {
                        isSubmitting = true;
                        error = null;
                      });

                      try {
                        final apiClient = ref.read(apiClientProvider);
                        await apiClient.dio.post(endpoint, data: {'name': name});
                        onAdded();
                        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                      } on DioException catch (e) {
                        final msg = e.response?.data is Map ? (e.response?.data['message'] ?? e.message) : e.message;
                        setDialogState(() {
                          error = 'Failed: $msg';
                          isSubmitting = false;
                        });
                      } catch (e) {
                        setDialogState(() {
                          error = 'Failed: $e';
                          isSubmitting = false;
                        });
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _statusMessage = null;
    });

    try {
      String? featuredImageUrl;
      if (_useFileUpload) {
        if (_selectedImageFile != null) {
          featuredImageUrl = await _uploadSelectedImage();
        }
      } else if (_imageUrlController.text.trim().isNotEmpty) {
        featuredImageUrl = _imageUrlController.text.trim();
      }

      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.post('/sampathi/v1/news/add', data: {
        'title': _titleController.text.trim(),
        'subtitle': _subtitleController.text.trim(),
        'excerpt': _excerptController.text.trim(),
        'content': '<p>${_contentController.text.trim()}</p>',
        'featured_image_url': featuredImageUrl,
        'category_id': _selectedCategoryId,
        'district_id': _selectedDistrictId,
        'reading_time': int.tryParse(_readingTimeController.text) ?? 3,
      });

      if (!mounted) return;

      setState(() {
        _statusMessage = 'ಸುದ್ದಿ ಯಶಸ್ವಿಯಾಗಿ ಪ್ರಕಟಿಸಲಾಗಿದೆ! (Published — Post ID: ${response.data['id']})';
        _statusIsError = false;
      });

      ref.invalidate(latestNewsProvider);
      ref.invalidate(breakingNewsProvider);

      _formKey.currentState!.reset();
      _titleController.clear();
      _subtitleController.clear();
      _excerptController.clear();
      _contentController.clear();
      _imageUrlController.clear();
      _readingTimeController.text = '3';
      setState(() {
        _selectedCategoryId = null;
        _selectedDistrictId = null;
        _selectedImageFile = null;
      });
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? (e.response?.data['message'] ?? e.message) : e.message;
      setState(() {
        _statusMessage = 'Failed to publish: $msg';
        _statusIsError = true;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Something went wrong: $e';
        _statusIsError = true;
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final districtsAsync = ref.watch(districtsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ಸುದ್ದಿ ಪ್ರಕಟಿಸಿ (Publish News)'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/admin/publish-ad'),
            icon: const Icon(Icons.campaign_outlined, color: Colors.white),
            label: const Text('Advertisements', style: TextStyle(color: Colors.white)),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(adminAuthProvider.notifier).logout();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _subtitleController,
                        decoration: const InputDecoration(labelText: 'Subtitle', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _excerptController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Excerpt / Summary', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _contentController,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          labelText: 'Content *',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Content is required' : null,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Featured Cover Image', style: Theme.of(context).textTheme.bodyMedium),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => setState(() {
                              _useFileUpload = !_useFileUpload;
                              _selectedImageFile = null;
                            }),
                            icon: Icon(_useFileUpload ? Icons.link : Icons.upload_file, size: 16),
                            label: Text(_useFileUpload ? 'Switch to URL Link' : 'Switch to File Upload'),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_useFileUpload) ...[
                        OutlinedButton.icon(
                          onPressed: _pickImageFile,
                          icon: const Icon(Icons.image_outlined),
                          label: Text(_selectedImageFile == null ? 'Choose Image File' : _selectedImageFile!.name),
                        ),
                        if (_isUploadingImage) ...[
                          const SizedBox(height: 8),
                          const LinearProgressIndicator(),
                        ],
                        if (_selectedImageFile != null && _selectedImageFile!.bytes != null) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.memory(
                              _selectedImageFile!.bytes!,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ] else
                        TextFormField(
                          controller: _imageUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Featured Image URL',
                            hintText: 'https://...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: categoriesAsync.when(
                              loading: () => const LinearProgressIndicator(),
                              error: (_, __) => const Text('Failed to load categories'),
                              data: (categories) => DropdownButtonFormField<int>(
                                value: _selectedCategoryId,
                                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                                items: categories
                                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                                    .toList(),
                                onChanged: (v) => setState(() => _selectedCategoryId = v),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                            tooltip: 'Add new category',
                            onPressed: () => _showQuickAddDialog(
                              title: 'Add New Category',
                              endpoint: '/sampathi/v1/categories/add',
                              onAdded: () => ref.invalidate(categoriesProvider),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: districtsAsync.when(
                              loading: () => const LinearProgressIndicator(),
                              error: (_, __) => const Text('No districts yet — add one with the + button'),
                              data: (districts) => DropdownButtonFormField<int>(
                                value: _selectedDistrictId,
                                decoration: const InputDecoration(labelText: 'District', border: OutlineInputBorder()),
                                items: districts
                                    .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                                    .toList(),
                                onChanged: (v) => setState(() => _selectedDistrictId = v),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                            tooltip: 'Add new district',
                            onPressed: () => _showQuickAddDialog(
                              title: 'Add New District',
                              endpoint: '/sampathi/v1/districts/add',
                              onAdded: () => ref.invalidate(districtsProvider),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _readingTimeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Reading time (minutes)', border: OutlineInputBorder()),
                      ),
                      if (_statusMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _statusMessage!,
                          style: TextStyle(
                            color: _statusIsError ? AppTheme.errorColor : Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.publish, color: Colors.white),
                        label: Text(
                          _isSubmitting ? 'Publishing...' : 'Publish',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
