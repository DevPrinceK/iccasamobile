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
                                    : () => showDialog<void>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text(
                                            'Reset your password',
                                          ),
                                          content: const Text(
                                            'Use the ICCASA dashboard password reset or contact your administrator for account support.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        ),
                                      ),
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
