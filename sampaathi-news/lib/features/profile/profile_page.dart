import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../providers/providers.dart';
import '../../themes/app_theme.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/widgets.dart';
import '../../widgets/app_bottom_nav.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  Map<String, dynamic>? _profile;
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  String? _error;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Only fetch profile data if already logged in — viewing the tab itself
    // never requires logging in.
    final isLoggedIn = ref.read(adminAuthProvider);
    if (isLoggedIn) _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get('/sampathi/v1/auth/me');
      setState(() {
        _profile = Map<String, dynamic>.from(response.data);
        _nameController.text = _profile?['name'] ?? '';
        _phoneController.text = _profile?['phone'] ?? '';
      });
    } catch (e) {
      setState(() => _error = 'Failed to load profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.post('/sampathi/v1/auth/update-profile', data: {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      setState(() {
        _profile = Map<String, dynamic>.from(response.data);
        _isEditing = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changeAvatar() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final file = result.files.first;
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      });
      final uploadResponse = await apiClient.dio.post('/sampathi/v1/media/upload', data: formData);
      final avatarUrl = uploadResponse.data['source_url'] as String?;

      if (avatarUrl != null) {
        final profileResponse = await apiClient.dio.post('/sampathi/v1/auth/update-profile', data: {
          'avatar_url': avatarUrl,
        });
        setState(() => _profile = Map<String, dynamic>.from(profileResponse.data));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update photo: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final isLoggedIn = ref.watch(adminAuthProvider);

    // If login state flips to true (e.g. user just logged in via /admin and
    // came back), fetch their profile the first time we notice.
    if (isLoggedIn && _profile == null && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
    }

    return Scaffold(
      appBar: buildAppHeader(context),
      drawer: const MobileDrawer(),
      bottomNavigationBar: isMobile ? const AppBottomNav(currentPath: '/profile') : null,
      body: ResponsiveLayout(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: isLoggedIn ? _buildLoggedInView(context) : _buildGuestView(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const CircleAvatar(radius: 48, backgroundColor: AppTheme.primaryColor, child: Icon(Icons.person, size: 48, color: Colors.white)),
        const SizedBox(height: 16),
        const Text('ಅತಿಥಿ (Guest)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'ಪ್ರೊಫೈಲ್ ವಿವರಗಳನ್ನು ಸಂಪಾದಿಸಲು ಲಾಗಿನ್ ಮಾಡಿ.\n(Log in to edit your profile picture and details.)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => context.go('/admin'),
          icon: const Icon(Icons.login, color: Colors.white),
          label: const Text('Login', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildLoggedInView(BuildContext context) {
    if (_isLoading) {
      return const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(_error!, style: const TextStyle(color: AppTheme.errorColor)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadProfile, child: const Text('Retry')),
          ],
        ),
      );
    }

    final avatarUrl = _profile?['avatar_url'] as String? ?? '';

    return Column(
      children: [
        const SizedBox(height: 24),
        Stack(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: AppTheme.primaryColor,
              child: ClipOval(
                child: avatarUrl.isNotEmpty
                    ? SampathiImage(avatarUrl, width: 96, height: 96, fit: BoxFit.cover)
                    : const Icon(Icons.person, size: 48, color: Colors.white),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _isUploadingAvatar ? null : _changeAvatar,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: _isUploadingAvatar
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (!_isEditing) ...[
          Text(_profile?['name'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(_profile?['email'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 4),
          if ((_profile?['phone'] ?? '').toString().isNotEmpty)
            Text(_profile!['phone'], style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => setState(() => _isEditing = true),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit Profile'),
          ),
        ] else ...[
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Text(_profile?['email'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 4),
          const Text('(Email is managed in WordPress and can\'t be changed here)', style: TextStyle(fontSize: 11, color: AppTheme.greyColor)),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  child: _isSaving
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () async {
            await ref.read(adminAuthProvider.notifier).logout();
            setState(() => _profile = null);
          },
          icon: const Icon(Icons.logout, color: AppTheme.errorColor, size: 18),
          label: const Text('Logout', style: TextStyle(color: AppTheme.errorColor)),
        ),
      ],
    );
  }
}
