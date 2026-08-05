import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0; // 0 = Business info, 1 = Owner info

  // Business info
  final _businessNameCtrl = TextEditingController();
  final _shopNameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String _businessType = 'retail';

  // Owner info
  final _ownerNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final List<String> _businessTypes = [
    'retail', 'wholesale', 'food', 'pharmacy',
    'electronics', 'fashion', 'general',
  ];

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _shopNameCtrl.dispose();
    _cityCtrl.dispose();
    _ownerNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      setState(() => _step = 1);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final ok = await auth.register({
      'business_name': _businessNameCtrl.text.trim(),
      'business_type': _businessType,
      'shop_name': _shopNameCtrl.text.trim().isEmpty
          ? null
          : _shopNameCtrl.text.trim(),
      'city': _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      'owner_name': _ownerNameCtrl.text.trim(),
      'owner_email': _emailCtrl.text.trim(),
      'owner_phone': _phoneCtrl.text.trim(),
      'password': _passwordCtrl.text,
    });

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Registration failed'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
    // On success the router will navigate to the main shell automatically
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Create Business Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _step == 1
              ? () => setState(() => _step = 0)
              : () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Step indicator ────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  _stepDot(0, 'Business'),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _step >= 1
                          ? AppColors.primary
                          : AppColors.lightTextSecondary.withOpacity(0.3),
                    ),
                  ),
                  _stepDot(1, 'Owner'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child:
                        _step == 0 ? _buildStep0() : _buildStep1(auth),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepDot(int index, String label) {
    final isActive = _step >= index;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.lightTextSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? AppColors.primary : AppColors.lightTextSecondary,
            fontWeight:
                isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Details',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Tell us about your business',
          style: TextStyle(color: AppColors.lightTextSecondary, fontSize: 13),
        ),
        const SizedBox(height: 24),

        TextFormField(
          controller: _businessNameCtrl,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Business Name *',
            prefixIcon: Icon(Icons.business),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Business name is required' : null,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _shopNameCtrl,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Shop / Branch Name (optional)',
            prefixIcon: Icon(Icons.storefront_outlined),
            hintText: 'Defaults to business name',
          ),
        ),
        const SizedBox(height: 16),

        // Business type dropdown
        DropdownButtonFormField<String>(
          value: _businessType,
          decoration: const InputDecoration(
            labelText: 'Business Type',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: _businessTypes
              .map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t[0].toUpperCase() + t.substring(1)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _businessType = v!),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _cityCtrl,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'City / Town (optional)',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _nextStep,
            child: const Text('Continue →'),
          ),
        ),
      ],
    );
  }

  Widget _buildStep1(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Owner Account',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Create your owner login credentials',
          style:
              TextStyle(color: AppColors.lightTextSecondary, fontSize: 13),
        ),
        const SizedBox(height: 24),

        TextFormField(
          controller: _ownerNameCtrl,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Your Full Name *',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Your name is required' : null,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Email Address *',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Phone Number *',
            prefixIcon: Icon(Icons.phone_outlined),
            hintText: '024 XXX XXXX',
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Phone number is required' : null,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Password *',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password is required';
            if (v.length < 8) return 'Minimum 8 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _confirmCtrl,
          obscureText: _obscureConfirm,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: 'Confirm Password *',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          validator: (v) {
            if (v != _passwordCtrl.text) return 'Passwords do not match';
            return null;
          },
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: auth.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Create Business Account'),
          ),
        ),

        const SizedBox(height: 16),
        Center(
          child: Text(
            '14-day free trial • No credit card required',
            style: TextStyle(
                color: AppColors.lightTextSecondary, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
