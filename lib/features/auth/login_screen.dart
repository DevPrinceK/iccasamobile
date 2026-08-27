import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../core/state/app_controller.dart';
import '../../design_system/app_ui.dart';
import '../../design_system/components/app_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: AppConfig.showPreviewAccess ? 'abena.mensah@iccasa.local' : '',
    );
    _passwordController = TextEditingController(
      text: AppConfig.showPreviewAccess ? 'Password123!' : '',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(appControllerProvider)
        .signIn(_emailController.text, _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (wide) const Expanded(flex: 11, child: _LoginStoryPanel()),
            Expanded(
              flex: wide ? 9 : 1,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 56 : 22,
                    vertical: 28,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 470),
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!wide) ...[
                              const Row(
                                children: [
                                  LogoMark(),
                                  SizedBox(width: 10),
                                  Text(
                                    'ICCASA Field',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 44),
                            ],
                            Text(
                              'Welcome back',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Sign in to access your assigned collection work and saved field records.',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 30),
                            if (controller.errorMessage != null) ...[
                              MessageBanner(
                                message: controller.errorMessage!,
                                onDismiss: controller.clearError,
                              ),
                              const SizedBox(height: 18),
                            ],
                            Text(
                              'Email address',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              enabled: !controller.isBusy,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.username,
                                AutofillHints.email,
                              ],
                              decoration: const InputDecoration(
                                hintText: 'name@iccasa-africa.org',
                                prefixIcon: Icon(Icons.alternate_email_rounded),
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (email.isEmpty) {
                                  return 'Enter your email address.';
                                }
                                if (!email.contains('@')) {
                                  return 'Enter a valid email address.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Password',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              enabled: !controller.isBusy,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                hintText: 'Enter your password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) => (value?.length ?? 0) < 8
                                  ? 'Password must be at least 8 characters.'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: controller.isBusy
                                    ? null
                                    : () async {
                                        final changed = await showDialog<bool>(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) =>
                                              _PasswordResetDialog(
                                                controller: controller,
                                                initialEmail:
                                                    _emailController.text,
                                              ),
                                        );
                                        if (!context.mounted) return;
                                        if (changed == true) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Password updated. You can now sign in.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                child: const Text('Forgot password?'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: controller.isBusy ? null : _submit,
                              icon: controller.isBusy
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.arrow_forward_rounded),
                              label: Text(
                                controller.isBusy
                                    ? 'Signing in...'
                                    : 'Sign in securely',
                              ),
                            ),
                            if (AppConfig.showPreviewAccess) ...[
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: controller.isBusy
                                    ? null
                                    : controller.enterPreview,
                                icon: const Icon(Icons.preview_outlined),
                                label: const Text('Open preview workspace'),
                              ),
                            ],
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'Protected ICCASA workspace',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordResetDialog extends StatefulWidget {
  const _PasswordResetDialog({
    required this.controller,
    required this.initialEmail,
  });

  final AppController controller;
  final String initialEmail;

  @override
  State<_PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<_PasswordResetDialog> {
  late final TextEditingController _email;
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  int _step = 0;
  bool _busy = false;
  bool _obscure = true;
  String? _resetToken;
  String? _error;
  String? _developmentCode;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail.trim());
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (_step == 1 && _code.text.trim().length != 6) {
      setState(() => _error = 'Enter the six-digit reset code.');
      return;
    }
    if (_step == 2) {
      if (_password.text.length < 8) {
        setState(() => _error = 'Use at least eight characters.');
        return;
      }
      if (_password.text != _confirmation.text) {
        setState(() => _error = 'The passwords do not match.');
        return;
      }
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_step == 0) {
        final debugCode = await widget.controller.requestPasswordReset(email);
        if (!mounted) return;
        setState(() {
          _developmentCode = debugCode;
          _step = 1;
        });
      } else if (_step == 1) {
        final token = await widget.controller.verifyPasswordResetCode(
          email,
          _code.text,
        );
        if (!mounted) return;
        setState(() {
          _resetToken = token;
          _step = 2;
        });
      } else {
        await widget.controller.resetPassword(_resetToken!, _password.text);
        if (mounted) Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_step) {
      0 => 'Reset your password',
      1 => 'Enter reset code',
      _ => 'Choose a new password',
    };
    final action = switch (_step) {
      0 => 'Send reset code',
      1 => 'Verify code',
      _ => 'Update password',
    };
    return AlertDialog(
      icon: const Icon(Icons.lock_reset_rounded),
      title: Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_step == 0)
                TextField(
                  controller: _email,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                ),
              if (_step == 1) ...[
                Text(
                  'Enter the code sent to $emailLabel. It expires in 10 minutes.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _code,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Six-digit code',
                    prefixIcon: Icon(Icons.password_rounded),
                  ),
                ),
                if (_developmentCode != null)
                  Text(
                    'Development code: $_developmentCode',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
              if (_step == 2) ...[
                TextField(
                  controller: _password,
                  autofocus: true,
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: 'New password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _confirmation,
                  obscureText: _obscure,
                  onSubmitted: (_) => _continue(),
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                    prefixIcon: Icon(Icons.verified_user_outlined),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _continue,
          child: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(action),
        ),
      ],
    );
  }

  String get emailLabel => _email.text.trim();
}

class _LoginStoryPanel extends StatelessWidget {
  const _LoginStoryPanel();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(48),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF073A37), Color(0xFF0F1F34)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -80,
          bottom: -100,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.emerald.withValues(alpha: 0.16),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                LogoMark(size: 48),
                SizedBox(width: 14),
                Text(
                  'ICCASA Field',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const StatusBadge(
              'Offline-ready',
              icon: Icons.offline_bolt_rounded,
              color: Color(0xFF61E7C5),
            ),
            const SizedBox(height: 22),
            const Text(
              'Evidence that moves\nclimate action forward.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 42,
                height: 1.07,
                letterSpacing: -1.4,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Collect trusted, inclusive monitoring data in the field, even when connectivity is limited.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 17,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 34),
            const Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _StoryPoint(
                  Icons.assignment_turned_in_outlined,
                  'Guided forms',
                ),
                _StoryPoint(Icons.cloud_sync_outlined, 'Reliable sync'),
                _StoryPoint(
                  Icons.accessibility_new_rounded,
                  'Accessible by design',
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

class _StoryPoint extends StatelessWidget {
  const _StoryPoint(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: const Color(0xFF61E7C5), size: 21),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
