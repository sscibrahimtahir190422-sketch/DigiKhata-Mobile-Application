import 'package:digikhata/core/widgets/premium_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodels/auth_view_model.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _register = false;
  bool _obscure = true;

  AuthViewModel get vm => Get.find<AuthViewModel>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();
    final successful = _register
        ? await vm.signUp(email: _email.text, password: _password.text)
        : await vm.signIn(email: _email.text, password: _password.text);
    if (!mounted || !successful) return;
    if (_register && vm.registrationEmailSent.value) {
      Get.snackbar(
        'Check your email',
        'We sent a confirmation link. Verify your email, then sign in.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 6),
      );
      setState(() => _register = false);
    } else {
      Get.offAllNamed(AppRoutes.dashboard);
    }
  }

  Future<void> _resetPassword() async {
    final text = _email.text.trim();
    if (!GetUtils.isEmail(text)) {
      Get.snackbar(
        'Email required',
        'Enter your email above to request a password reset.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final sent = await vm.requestPasswordReset(text);
    if (sent) {
      Get.snackbar(
        'Check your inbox',
        'If that account exists, password reset instructions have been sent.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) => PremiumEntrance(
    child: Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, layout) {
            final wide = layout.maxWidth >= 900;
            return Row(
              children: [
                if (wide)
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(56),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 470),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Colors.white,
                                  size: 70,
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Your shop. Your numbers. In control.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    height: 1.14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Track Udhar, Jama, customer and supplier '
                                  'accounts, products and financial reports in one place.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 17,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 30,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          curve: Curves.easeOutCubic,
                          duration: const Duration(milliseconds: 600),
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - value) * 20),
                              child: child,
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.lightGreen,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_wallet_rounded,
                                        color: AppTheme.primaryGreen,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'DigiKhata',
                                      style: TextStyle(
                                        fontSize: 27,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.darkGreen,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 35),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: Text(
                                    _register
                                        ? 'Create your shop account'
                                        : 'Welcome back',
                                    key: ValueKey(_register),
                                    style: const TextStyle(
                                      fontSize: 27,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _register
                                      ? 'Securely manage all your daily shop finances.'
                                      : 'Sign in to see your live shop balances.',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                TextFormField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  decoration: const InputDecoration(
                                    labelText: 'Email address',
                                    prefixIcon: Icon(
                                      Icons.mail_outline_rounded,
                                    ),
                                  ),
                                  validator: (text) =>
                                      GetUtils.isEmail(text?.trim() ?? '')
                                      ? null
                                      : 'Enter a valid email address',
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _password,
                                  obscureText: _obscure,
                                  textInputAction: _register
                                      ? TextInputAction.next
                                      : TextInputAction.done,
                                  autofillHints: [
                                    _register
                                        ? AutofillHints.newPassword
                                        : AutofillHints.password,
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                    ),
                                    suffixIcon: IconButton(
                                      tooltip: _obscure
                                          ? 'Show password'
                                          : 'Hide password',
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (text) =>
                                      text == null || text.isEmpty
                                      ? 'Enter your password'
                                      : _register && text.length < 8
                                      ? 'Password must contain at least 8 characters'
                                      : null,
                                ),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  child: _register
                                      ? Padding(
                                          padding: const EdgeInsets.only(
                                            top: 14,
                                          ),
                                          child: TextFormField(
                                            controller: _confirmPassword,
                                            obscureText: _obscure,
                                            decoration: const InputDecoration(
                                              labelText: 'Confirm password',
                                              prefixIcon: Icon(
                                                Icons.verified_user_outlined,
                                              ),
                                            ),
                                            validator: (text) =>
                                                text != _password.text
                                                ? 'Passwords do not match'
                                                : null,
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                if (!_register)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _resetPassword,
                                      child: const Text('Forgot password?'),
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                Obx(
                                  () => vm.errorMessage.value.isEmpty
                                      ? const SizedBox.shrink()
                                      : Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 14,
                                          ),
                                          child: Text(
                                            vm.errorMessage.value,
                                            style: const TextStyle(
                                              color: AppTheme.danger,
                                            ),
                                          ),
                                        ),
                                ),
                                Obx(
                                  () => FilledButton.icon(
                                    onPressed: vm.isLoading.value
                                        ? null
                                        : _submit,
                                    icon: vm.isLoading.value
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            _register
                                                ? Icons.person_add_alt_1_rounded
                                                : Icons.login_rounded,
                                          ),
                                    label: Text(
                                      vm.isLoading.value
                                          ? 'Working...'
                                          : _register
                                          ? 'Create Account'
                                          : 'Sign In',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () => setState(() {
                                    _register = !_register;
                                    vm.errorMessage.value = '';
                                  }),
                                  child: Text(
                                    _register
                                        ? 'Already registered? Sign in'
                                        : 'New to DigiKhata? Create an account',
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Protected by authentication and shop-level '
                                  'database access controls.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
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
              ],
            );
          },
        ),
      ),
    ),
  );
}
