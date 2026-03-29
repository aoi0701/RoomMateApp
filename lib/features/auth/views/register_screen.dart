import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _validateFullName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Vui lòng nhập họ tên';
    if (text.length < 2) return 'Họ tên phải có ít nhất 2 ký tự';
    return null;
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Vui lòng nhập email';

    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(text)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (text.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Vui lòng xác nhận mật khẩu';
    if (text.trim() != _passwordController.text.trim()) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Vui lòng nhập số điện thoại';

    final phoneRegex = RegExp(r'^[0-9]{10,11}$');
    if (!phoneRegex.hasMatch(text)) {
      return 'Số điện thoại phải gồm 10 đến 11 chữ số';
    }

    return null;
  }

  String? _validateAddress(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Vui lòng nhập địa chỉ';
    if (text.length < 5) return 'Địa chỉ quá ngắn';
    return null;
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        await user.updateDisplayName(fullName);

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'address': address,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công')),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = 'Đăng ký thất bại';

      if (e.code == 'email-already-in-use') {
        message = 'Email đã được sử dụng';
      } else if (e.code == 'weak-password') {
        message = 'Mật khẩu quá yếu';
      } else if (e.code == 'invalid-email') {
        message = 'Email không hợp lệ';
      } else if (e.code == 'network-request-failed') {
        message = 'Lỗi mạng, vui lòng thử lại';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF5B6B8C)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD9DFEA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD9DFEA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFF4F7BFF),
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      labelStyle: const TextStyle(
        color: Color(0xFF667085),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF4F7BFF), Color(0xFF3563E9)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _isLoading ? null : _register,
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Đăng ký',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF6F7FB),
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'Đăng ký',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            // autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _fullNameController,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          label: 'Họ tên',
                          icon: Icons.person_outline,
                        ),
                        validator: _validateFullName,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          label: 'Email',
                          icon: Icons.email_outlined,
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          label: 'Số điện thoại',
                          icon: Icons.phone_outlined,
                        ),
                        validator: _validatePhone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          label: 'Địa chỉ',
                          icon: Icons.location_on_outlined,
                        ),
                        validator: _validateAddress,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          label: 'Mật khẩu',
                          icon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF667085),
                            ),
                          ),
                        ),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        decoration: _inputDecoration(
                          label: 'Xác nhận mật khẩu',
                          icon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF667085),
                            ),
                          ),
                        ),
                        validator: _validateConfirmPassword,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildPrimaryButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}