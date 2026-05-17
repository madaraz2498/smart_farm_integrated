import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/features/auth/providers/auth_provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import 'package:smart_farm/providers/navigation_provider.dart';
import 'package:smart_farm/core/network/api_client.dart';
import 'package:smart_farm/core/theme/app_colors.dart';
import 'package:smart_farm/core/utils/production_logger.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _passKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _isEditing = false;
  bool _obscureOld = true;
  bool _obscureNew = true;

  Future<void> _pickImage() async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.choose_image,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (image != null) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          final auth = context.read<AuthProvider>();
          final bytes = await image.readAsBytes();

          if (!mounted) return;

          final success = await auth.updateProfile(
            name: auth.currentUser?.name,
            email: auth.currentUser?.email,
            imageBytes: bytes,
            imageName: image.name,
          );
          if (success) {
            _snack(l10n.profile_picture_updated);
          } else {
            _snack(l10n.failed_to_update_profile_picture);
          }
        }
      }
    } catch (e) {
      _snack('Failed to pick image: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _confirmLogout(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.logout, style: textTheme.titleMedium),
        content: Text(
          l10n.confirm_logout_message,
          style: textTheme.bodyMedium,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurfaceVariant,
                    side: BorderSide(
                      color: colorScheme.outlineVariant,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.read<NavigationProvider>().reset();
                    context.read<AuthProvider>().logout();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(l10n.logout),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final w = MediaQuery.sizeOf(context).width;
    final pagePadding = (w * 0.04).clamp(16.0, 24.0);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: RefreshIndicator(
              onRefresh: () async {
                await context.read<AuthProvider>().loadUserProfile();
              },
              color: colorScheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    EdgeInsets.symmetric(horizontal: pagePadding, vertical: 32),
                child: Column(
                  children: [
                    Text(l10n.profile_settings,
                        style: textTheme.headlineMedium),
                    const SizedBox(height: 40),

                    // Profile Header / Avatar Section
                    _buildAvatarSection(isAdmin, auth.displayName),
                    const SizedBox(height: 12),
                    Text(
                      auth.currentUser?.email ?? '',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 48),

                    // Personal Info Card
                    _buildSectionCard(
                      title: l10n.personal_information,
                      icon: Icons.person_outline_rounded,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _nameController,
                              label: l10n.full_name,
                              enabled: _isEditing,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _emailController,
                              label: l10n.email,
                              enabled: false,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _phoneController,
                              label: l10n.phone_number,
                              enabled: _isEditing,
                              hint: l10n.phone_number,
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () async {
                                        if (!_isEditing) {
                                          setState(() => _isEditing = true);
                                        } else {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            final success = await context
                                                .read<AuthProvider>()
                                                .updateProfile(
                                                  name: _nameController.text,
                                                  email: _emailController.text,
                                                  phone: _phoneController.text,
                                                );
                                            if (success) {
                                              setState(
                                                  () => _isEditing = false);
                                              _snack(l10n.profile_saved);
                                            } else {
                                              _snack(auth.errorMsg ??
                                                  l10n.failed_to_save_changes);
                                            }
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: auth.isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                            color: Colors.black,
                                            strokeWidth: 2.5))
                                    : Text(
                                        _isEditing
                                            ? l10n.save_changes
                                            : l10n.edit_profile,
                                        style: textTheme.labelLarge
                                            ?.copyWith(color: Colors.black),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Change Password Card
                    _buildSectionCard(
                      title: l10n.change_password,
                      icon: Icons.lock_outline_rounded,
                      child: Form(
                        key: _passKey,
                        child: Column(
                          children: [
                            _buildPasswordField(
                              controller: _oldPassController,
                              label: l10n.current_password,
                              obscure: _obscureOld,
                              onToggle: () =>
                                  setState(() => _obscureOld = !_obscureOld),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? l10n.field_required
                                  : (v.length < 6
                                      ? l10n.password_too_short
                                      : null),
                            ),
                            const SizedBox(height: 20),
                            _buildPasswordField(
                              controller: _newPassController,
                              label: l10n.new_password,
                              obscure: _obscureNew,
                              onToggle: () =>
                                  setState(() => _obscureNew = !_obscureNew),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? l10n.field_required
                                  : (v.length < 6
                                      ? l10n.password_too_short
                                      : null),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () async {
                                        if (_passKey.currentState!.validate()) {
                                          final success =
                                              await auth.changePassword(
                                            oldPassword:
                                                _oldPassController.text,
                                            newPassword:
                                                _newPassController.text,
                                          );

                                          if (success) {
                                            _snack(
                                                l10n.password_changed_success);
                                            _oldPassController.clear();
                                            _newPassController.clear();
                                            _confirmPassController.clear();
                                          } else {
                                            _snack(auth.errorMsg ??
                                                l10n.error_msg);
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: auth.isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.black,
                                        ),
                                      )
                                    : Text(l10n.update_password,
                                        style: textTheme.labelLarge
                                            ?.copyWith(color: Colors.black)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => _confirmLogout(l10n),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: Text(l10n.logout),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(bool isAdmin, String name) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final imgUrl = user?.profileImg;
    final localBytes = auth.localProfileImage;

    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isAdmin ? AppColors.adminAccent : AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: ClipOval(
              child: localBytes != null
                  ? Image.memory(localBytes, fit: BoxFit.cover)
                  : (imgUrl != null && imgUrl.isNotEmpty
                      ? Image.network(
                          imgUrl.startsWith('http')
                              ? imgUrl
                              : '${ApiClient.baseUrl}$imgUrl',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            ProductionLogger.info('Image load error: $error');
                            return _buildInitials(isAdmin, name, size: 48);
                          },
                        )
                      : _buildInitials(isAdmin, name, size: 48)),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        spreadRadius: 0),
                  ],
                ),
                child: Icon(Icons.camera_alt_rounded,
                    size: 20,
                    color: isAdmin ? AppColors.adminAccent : AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitials(bool isAdmin, String name, {double size = 48}) {
    return Center(
      child: isAdmin
          ? Text('A',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: size,
                  fontWeight: FontWeight.bold))
          : Icon(Icons.person_rounded, color: Colors.white, size: size + 12),
    );
  }

  Widget _buildSectionCard(
      {required String title, required IconData icon, required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 22),
              const SizedBox(width: 12),
              Text(title, style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      bool enabled = true,
      String? hint}) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: textTheme.labelMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          enabled: enabled,
          style: textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: colorScheme.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(
      {required TextEditingController controller,
      required String label,
      required bool obscure,
      required VoidCallback onToggle,
      String? Function(String?)? validator}) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: textTheme.labelMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: textTheme.bodyLarge,
          decoration: InputDecoration(
            filled: true,
            fillColor: colorScheme.surface,
            suffixIcon: IconButton(
                icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: colorScheme.onSurfaceVariant,
                    size: 20),
                onPressed: onToggle),
          ),
        ),
      ],
    );
  }
}
