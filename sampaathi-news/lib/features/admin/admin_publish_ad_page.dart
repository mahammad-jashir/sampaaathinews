import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../themes/app_theme.dart';

class AdminPublishAdPage extends ConsumerStatefulWidget {
  const AdminPublishAdPage({super.key});

  @override
  ConsumerState<AdminPublishAdPage> createState() => _AdminPublishAdPageState();
}

class _AdCampaign {
  final int id;
  final String businessName;
  final String position;
  final String startDate;
  final String endDate;
  final String status;

  _AdCampaign.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? 0,
        businessName = json['business_name'] ?? '',
        position = json['position'] ?? '',
        startDate = json['start_date'] ?? '',
        endDate = json['end_date'] ?? '',
        status = json['status'] ?? 'expired';
}

class _AdminPublishAdPageState extends ConsumerState<AdminPublishAdPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessController = TextEditingController();
  final _headingController = TextEditingController();
  final _bannerUrlController = TextEditingController();
  final _landingUrlController = TextEditingController();
  final _durationController = TextEditingController(text: '7');

  String _position = 'header_banner';
  bool _fastForward = false;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  String? _statusMessage;
  bool _statusIsError = false;

  // Image source toggle, matching the wp-admin Ad Dashboard page.
  bool _useFileUpload = false;
  PlatformFile? _selectedImageFile;

  List<_AdCampaign>? _campaigns;
  bool _isLoadingCampaigns = true;

  // Time period: when the campaign should begin. Defaults to "now" (starts
  // immediately); picking a future date/time schedules it instead — the
  // backend cron scheduler activates it automatically once that time comes.
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();

  static const _positions = {
    'header_banner': 'Header Banner',
    'sidebar_banner': 'Sidebar Banner',
    'article_banner': 'Article Banner',
  };

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  @override
  void dispose() {
    _businessController.dispose();
    _headingController.dispose();
    _bannerUrlController.dispose();
    _landingUrlController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  // Fetches every campaign (any status), matching the wp-admin Ad Dashboard's
  // "Active & Scheduled Campaigns" table.
  Future<void> _loadCampaigns() async {
    setState(() => _isLoadingCampaigns = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get('/sampathi/v1/ads/all');
      final list = (response.data as List).map((j) => _AdCampaign.fromJson(j)).toList();
      if (mounted) setState(() => _campaigns = list);
    } catch (_) {
      if (mounted) setState(() => _campaigns = []);
    } finally {
      if (mounted) setState(() => _isLoadingCampaigns = false);
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTime);
    if (picked != null) setState(() => _startTime = picked);
  }

  String get _formattedStartDateTime {
    final dt = DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute);
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:00';
  }

  Future<void> _pickImageFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _selectedImageFile = result.files.first);
    }
  }

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _statusMessage = null;
    });

    try {
      String? bannerImageUrl;
      if (_useFileUpload) {
        if (_selectedImageFile != null) {
          bannerImageUrl = await _uploadSelectedImage();
        }
      } else if (_bannerUrlController.text.trim().isNotEmpty) {
        bannerImageUrl = _bannerUrlController.text.trim();
      }

      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.post('/sampathi/v1/ads/add', data: {
        'business_name': _businessController.text.trim(),
        'heading': _headingController.text.trim(),
        'position': _position,
        'banner_image': bannerImageUrl,
        'landing_url': _landingUrlController.text.trim().isEmpty ? null : _landingUrlController.text.trim(),
        'start_date': _formattedStartDateTime,
        'duration_days': int.tryParse(_durationController.text) ?? 7,
        'fast_forward': _fastForward,
      });

      if (!mounted) return;

      setState(() {
        _statusMessage = '✅ Campaign scheduled successfully (ID: ${response.data['id']})';
        _statusIsError = false;
      });

      _formKey.currentState!.reset();
      _businessController.clear();
      _headingController.clear();
      _bannerUrlController.clear();
      _landingUrlController.clear();
      _durationController.text = '7';
      setState(() {
        _position = 'header_banner';
        _fastForward = false;
        _selectedImageFile = null;
        _startDate = DateTime.now();
        _startTime = TimeOfDay.now();
      });

      _loadCampaigns(); // refresh the table below with the new campaign
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? (e.response?.data['message'] ?? e.message) : e.message;
      setState(() {
        _statusMessage = 'Failed to book ad: $msg';
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

  Future<void> _updateStatus(int id, String newStatus) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.dio.post('/sampathi/v1/ads/update-status', data: {
        'id': id,
        'status': newStatus,
      });
      _loadCampaigns();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  Widget _statusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'active':
        color = Colors.green;
        label = 'ACTIVE';
        break;
      case 'scheduled':
        color = Colors.orange;
        label = 'SCHEDULED';
        break;
      case 'inactive':
        color = Colors.grey;
        label = 'INACTIVE';
        break;
      default:
        color = Colors.red;
        label = 'EXPIRED';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  // Tappable status editor: shows the current status as a chip; tapping
  // opens a small menu to change it to any of the four allowed statuses.
  Widget _statusEditor(_AdCampaign campaign) {
    return PopupMenuButton<String>(
      tooltip: 'Change status',
      onSelected: (value) => _updateStatus(campaign.id, value),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'scheduled', child: Text('Scheduled')),
        PopupMenuItem(value: 'active', child: Text('Active')),
        PopupMenuItem(value: 'inactive', child: Text('Inactive')),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _statusChip(campaign.status),
          const SizedBox(width: 2),
          const Icon(Icons.arrow_drop_down, size: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ಜಾಹೀರಾತು ಬುಕಿಂಗ್ (Book Advertisement)'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/admin/publish'),
            icon: const Icon(Icons.article_outlined, color: Colors.white),
            label: const Text('News', style: TextStyle(color: Colors.white)),
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
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Book New Ad form ---
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('ಹೊಸ ಜಾಹೀರಾತು ಬುಕಿಂಗ್ (Book New Ad)',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const Divider(height: 24),
                          TextFormField(
                            controller: _businessController,
                            decoration: const InputDecoration(labelText: 'Sponsor Business Name *', border: OutlineInputBorder()),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Business name is required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _headingController,
                            decoration: const InputDecoration(labelText: 'Advertisement Heading', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _position,
                            decoration: const InputDecoration(labelText: 'Position Display Slot', border: OutlineInputBorder()),
                            items: _positions.entries
                                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                                .toList(),
                            onChanged: (v) => setState(() => _position = v ?? 'header_banner'),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Banner Image', style: Theme.of(context).textTheme.bodyMedium),
                          ),
                          const SizedBox(height: 6),
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
                          const SizedBox(height: 8),
                          if (_useFileUpload) ...[
                            OutlinedButton.icon(
                              onPressed: _pickImageFile,
                              icon: const Icon(Icons.image_outlined),
                              label: Text(_selectedImageFile == null ? 'Choose Banner Image' : _selectedImageFile!.name),
                            ),
                            if (_isUploadingImage) ...[
                              const SizedBox(height: 8),
                              const LinearProgressIndicator(),
                            ],
                            if (_selectedImageFile != null && _selectedImageFile!.bytes != null) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.memory(_selectedImageFile!.bytes!, height: 100, fit: BoxFit.cover),
                              ),
                            ],
                          ] else
                            TextFormField(
                              controller: _bannerUrlController,
                              decoration: const InputDecoration(
                                labelText: 'Banner Image URL',
                                hintText: 'https://...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _landingUrlController,
                            decoration: const InputDecoration(
                              labelText: 'Landing / Target URL',
                              hintText: 'https://...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Campaign Start (Time Period)', style: Theme.of(context).textTheme.bodyMedium),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickStartDate,
                                  icon: const Icon(Icons.calendar_today, size: 16),
                                  label: Text(
                                    '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickStartTime,
                                  icon: const Icon(Icons.access_time, size: 16),
                                  label: Text(_startTime.format(context)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Leave as now to start immediately, or pick a future date/time to schedule the campaign — it activates automatically.',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Ad Duration (days)', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            value: _fastForward,
                            onChanged: (v) => setState(() => _fastForward = v ?? false),
                            title: const Text('⚡ Fast-forward testing (treat days as seconds)', style: TextStyle(fontSize: 13)),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (_statusMessage != null) ...[
                            const SizedBox(height: 8),
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
                                : const Icon(Icons.rocket_launch, color: Colors.white),
                            label: Text(
                              _isSubmitting ? 'Submitting...' : 'Submit & Schedule Campaign',
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

                const SizedBox(height: 24),

                // --- Campaigns list, matching wp-admin's table ---
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ಜಾಹೀರಾತು ಬುಕಿಂಗ್ ವಿವರಗಳು (Active & Scheduled Campaigns)',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Refresh',
                              onPressed: _loadCampaigns,
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        if (_isLoadingCampaigns)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_campaigns == null || _campaigns!.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('ಯಾವುದೇ ಜಾಹೀರಾತು ಬುಕಿಂಗ್ ಲಭ್ಯವಿಲ್ಲ.'),
                          )
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Business Name')),
                                DataColumn(label: Text('Position')),
                                DataColumn(label: Text('Start Date')),
                                DataColumn(label: Text('End Date')),
                                DataColumn(label: Text('Status')),
                              ],
                              rows: _campaigns!.map((c) {
                                return DataRow(cells: [
                                  DataCell(Text(c.businessName)),
                                  DataCell(Text(c.position)),
                                  DataCell(Text(c.startDate)),
                                  DataCell(Text(c.endDate)),
                                  DataCell(_statusEditor(c)),
                                ]);
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
