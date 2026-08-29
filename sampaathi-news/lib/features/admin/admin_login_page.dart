import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';

// Colors matching WordPress's own wp-login.php admin screen.
class _WpLoginColors {
  static const background = Color(0xFFF0F0F1);
  static const cardBorder = Color(0xFFC3C4C7);
  static const labelText = Color(0xFF1D2327);
  static const inputBorder = Color(0xFF8C8F94);
  static const wpBlue = Color(0xFF2271B1);
  static const wpBlueDark = Color(0xFF135E96);
  static const linkText = Color(0xFF2271B1);
  static const errorBorder = Color(0xFFD63638);
  static const errorBackground = Color(0xFFFCF0F1);
}

class AdminLoginPage extends ConsumerStatefulWidget {
  const AdminLoginPage({super.key});

  @override
  ConsumerState<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends ConsumerState<AdminLoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final error = await ref.read(adminAuthProvider.notifier).login(
          _usernameController.text.trim(),
          _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      context.go('/admin/publish');
    } else {
      setState(() => _errorText = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _WpLoginColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // WordPress-style logo badge (the "W" swirl, simplified)
                _WpLogoBadge(),
                const SizedBox(height: 24),

                // The login card itself
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _WpLoginColors.cardBorder),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorText != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: _WpLoginColors.errorBackground,
                            border: const Border(
                              left: BorderSide(color: _WpLoginColors.errorBorder, width: 4),
                            ),
                          ),
                          child: Text(
                            _errorText!,
                            style: const TextStyle(fontSize: 13, color: _WpLoginColors.labelText),
                          ),
                        ),
                      ],

                      // Username field
                      const _WpLabel('Username or Email Address'),
                      const SizedBox(height: 4),
                      _WpTextField(
                        controller: _usernameController,
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      const _WpLabel('Password'),
                      const SizedBox(height: 4),
                      _WpTextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        onSubmitted: (_) => _submit(),
                        suffixIcon: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            size: 18,
                            color: _WpLoginColors.inputBorder,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Remember Me checkbox, WP-style
                      Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (v) => setState(() => _rememberMe = v ?? false),
                              activeColor: _WpLoginColors.wpBlue,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Remember Me',
                            style: TextStyle(fontSize: 13, color: _WpLoginColors.labelText),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Log In button, WP-blue
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _WpLoginColors.wpBlue,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                              side: const BorderSide(color: _WpLoginColors.wpBlueDark),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Log In',
                                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Footer links, WP-style: "Lost your password?" + back link
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {}, // Password reset happens in wp-admin itself
                      child: const Text(
                        'Lost your password?',
                        style: TextStyle(fontSize: 13, color: _WpLoginColors.linkText),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => context.go('/'),
                  child: const Text(
                    '← Go to Sampathi News',
                    style: TextStyle(fontSize: 13, color: _WpLoginColors.linkText),
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

// Simplified WordPress "W" swirl badge shown above the login card,
// same spot as the real wp-login.php WordPress logo.
class _WpLogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: const BoxDecoration(
        color: _WpLoginColors.wpBlue,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        'W',
        style: TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
          fontFamily: 'Georgia',
        ),
      ),
    );
  }
}

// WP-style field label: small, grey-ish, above the input.
class _WpLabel extends StatelessWidget {
  final String text;
  const _WpLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, color: _WpLoginColors.labelText),
    );
  }
}

// WP-style text field: square corners, thin grey border, full width.
class _WpTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  const _WpTextField({
    required this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      onSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: _WpLoginColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: _WpLoginColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: _WpLoginColors.wpBlue, width: 1.5),
        ),
      ),
    );
  }
}
