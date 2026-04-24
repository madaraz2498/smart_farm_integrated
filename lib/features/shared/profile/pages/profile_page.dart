import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/features/auth/providers/auth_provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import 'package:smart_farm/providers/navigation_provider.dart';
import 'package:smart_farm/core/network/api_client.dart';
import 'package:smart_farm/shared/theme/app_theme.dart';
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
  bool _obscureConfirm = true;

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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.logout, style: AppTextStyles.cardTitle),
        content: Text(
          l10n.confirm_logout_message,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSubtle,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSubtle,
                    side: BorderSide(
                      color: AppColors.cardBorder.withValues(alpha: 0.9),
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
                    backgroundColor: AppColors.error,
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
    final w = MediaQuery.sizeOf(context).width;
    final pagePadding = (w * 0.04).clamp(16.0, 24.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: RefreshIndicator(
              onRefresh: () async {
                await context.read<AuthProvider>().loadUserProfile();
              },
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              Text(l10n.profile_settings, style: AppTextStyles.pageTitle),
              const SizedBox(height: 24),

              // Profile Header / Avatar Section
              _buildAvatarSection(isAdmin, auth.displayName),
              const SizedBox(height: 32),

              // Personal Info Card
              _buildSectionCard(
                title: l10n.personal_information,
                icon: Icons.person_outline,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: l10n.full_name,
                        enabled: _isEditing,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: l10n.email,
                        enabled: false, // Email usually fixed
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        label: l10n.phone_number,
                        enabled: _isEditing,
                        hint: l10n.phone_number,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: auth.isLoading
                              ? null
                              : () async {
                                  if (!_isEditing) {
                                    setState(() => _isEditing = true);
                                  } else {
                                    if (_formKey.currentState!.validate()) {
                                      final success = await context
                                          .read<AuthProvider>()
                                          .updateProfile(
                                            name: _nameController.text,
                                            email: _emailController.text,
                                            phone: _phoneController.text,
                                          );
                                      if (success) {
                                        setState(() => _isEditing = false);
                                        _snack(l10n.profile_saved);
                                      } else {
                                        _snack(auth.errorMsg ??
                                            l10n.failed_to_save_changes);
                                      }
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text(_isEditing
                                  ? l10n.save_changes
                                  : l10n.edit_profile),
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
                icon: Icons.lock_outline,
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
                            : (v.length < 6 ? l10n.password_too_short : null),
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        controller: _newPassController,
                        label: l10n.new_password,
                        obscure: _obscureNew,
                        onToggle: () =>
                            setState(() => _obscureNew = !_obscureNew),
                        validator: (v) => (v == null || v.isEmpty)
                            ? l10n.field_required
                            : (v.length < 6 ? l10n.password_too_short : null),
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        controller: _confirmPassController,
                        label: l10n.confirm_password,
                        obscure: _obscureConfirm,
                        onToggle: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        validator: (v) => v != _newPassController.text
                            ? l10n.passwords_dont_match
                            : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: auth.isLoading
                              ? null
                              : () async {
                                  if (_passKey.currentState!.validate()) {
                                    final success = await auth.changePassword(
                                      oldPassword: _oldPassController.text,
                                      newPassword: _newPassController.text,
                                    );

                                    if (success) {
                                      _snack(l10n.password_changed_success);
                                      _oldPassController.clear();
                                      _newPassController.clear();
                                      _confirmPassController.clear();
                                    } else {
                                      _snack(auth.errorMsg ?? l10n.error_msg);
                                    }
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : Text(l10n.update_password),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLogout(l10n),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(l10n.logout),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
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
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isAdmin ? AppColors.adminAccent : AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
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
                            return _buildInitials(isAdmin, name, size: 40);
                          },
                        )
                      : _buildInitials(isAdmin, name, size: 40)),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12, blurRadius: 4, spreadRadius: 1),
                  ],
                ),
                child: Icon(Icons.camera_alt_outlined,
                    size: 20,
                    color: isAdmin ? AppColors.adminAccent : AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitials(bool isAdmin, String name, {double size = 40}) {
    return Center(
      child: isAdmin
          ? Text('A',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: size,
                  fontWeight: FontWeight.bold))
          : Icon(Icons.person_rounded, color: Colors.white, size: size + 10),
    );
  }

  Widget _buildSectionCard(
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
            ],
          ),
          const Divider(height: 32),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            filled: !enabled,
            fillColor: Colors.grey.shade50,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            suffixIcon: IconButton(
                icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20),
                onPressed: onToggle),
          ),
        ),
      ],
    );
  }
}
