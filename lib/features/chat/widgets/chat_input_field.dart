import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../providers/chat_experience_provider.dart';

// ── Chat Input Field ──────────────────────────────────────────────────────────
//
// Bottom input bar with:
//  - Multi-line expandable text field
//  - Language selector (pill)
//  - Send button with loading state
// ─────────────────────────────────────────────────────────────────────────────

class ChatInputField extends StatefulWidget {
  const ChatInputField({super.key});

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send(ChatExperienceProvider prov) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || prov.isSending) return;
    _ctrl.clear();
    _focusNode.requestFocus();
    await prov.sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatExperienceProvider>(
      builder: (_, prov, __) {
        final isArabic = prov.language == 'Arabic';

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                offset: const Offset(0, -3),
                blurRadius: 12,
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Language toggle ──────────────────────────────────────────
                Row(
                  children: [
                    _LanguageToggle(
                      current: prov.language,
                      onChanged: prov.setLanguage,
                    ),
                    const Spacer(),
                    if (prov.isSending)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppColors.primary.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isArabic ? 'جاري الإرسال...' : 'Thinking...',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSubtle,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // ── Input row ────────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _focusNode.hasFocus
                                ? AppColors.primary.withValues(alpha: 0.5)
                                : AppColors.cardBorder,
                          ),
                        ),
                        child: TextField(
                          controller: _ctrl,
                          focusNode: _focusNode,
                          maxLines: 5,
                          minLines: 1,
                          textDirection: isArabic
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark,
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            hintText: isArabic
                                ? 'اكتب رسالتك هنا...'
                                : 'Ask about crops, diseases, irrigation...',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textDisabled,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          onSubmitted:
                              prov.isSending ? null : (_) => _send(prov),
                          textInputAction: TextInputAction.send,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ── Send button ──────────────────────────────────────────
                    _SendButton(
                      enabled:
                          _ctrl.text.trim().isNotEmpty && !prov.isSending,
                      isSending: prov.isSending,
                      onTap: () => _send(prov),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Language toggle ───────────────────────────────────────────────────────────

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({
    required this.current,
    required this.onChanged,
  });

  final String current;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ChatExperienceProvider.supportedLanguages.map((lang) {
          final isSelected = lang == current;
          return GestureDetector(
            onTap: () => onChanged(lang),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                lang == 'Arabic' ? 'عربي' : 'EN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Send button ───────────────────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.enabled,
    required this.isSending,
    required this.onTap,
  });

  final bool enabled;
  final bool isSending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.primary.withValues(alpha: 0.4),
          shape: BoxShape.circle,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: isSending
            ? const Padding(
                padding: EdgeInsets.all(13),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
      ),
    );
  }
}
