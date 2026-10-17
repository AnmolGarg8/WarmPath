import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/app_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/w_button.dart';
import '../../../core/widgets/w_card.dart';
import '../auth_providers.dart';

class OtpPage extends ConsumerStatefulWidget {
  final String email;

  const OtpPage({super.key, required this.email});

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> with SingleTickerProviderStateMixin {
  static const int _otpLength = 6;
  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(_otpLength, (_) => FocusNode());

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  Timer? _countdownTimer;
  int _secondsRemaining = 30;
  bool _canResend = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startCountdown();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 12.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  void _startCountdown() {
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _shakeController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String _getOtpCode() {
    return _controllers.map((c) => c.text.trim()).join();
  }

  void _handlePastedText(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= _otpLength) {
      for (int i = 0; i < _otpLength; i++) {
        _controllers[i].text = digits[i];
      }
      _focusNodes[_otpLength - 1].requestFocus();
      _verify();
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend || _isLoading) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await ref.read(authStateProvider.notifier).requestOtp(widget.email);
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A fresh 6-digit code has been sent.')),
        );
      }
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Failed to resend code. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verify() async {
    final code = _getOtpCode();
    if (code.length < _otpLength) {
      setState(() => _errorMessage = 'Please enter all 6 digits of the code.');
      _shakeController.forward(from: 0.0);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isNew = await ref.read(authStateProvider.notifier).verifyOtp(widget.email, code);
      if (mounted) {
        if (isNew) {
          context.go('/auth/profile-basics');
        } else {
          context.go('/profile');
        }
      }
    } on AppException catch (e) {
      _shakeController.forward(from: 0.0);
      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      _shakeController.forward(from: 0.0);
      setState(() {
        _errorMessage = 'Invalid code or expired. Please check and try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => context.go('/auth/email'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Enter Verification Code',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit verification code to:\n${widget.email}',
                style: const TextStyle(fontSize: 15, color: AppColors.slate, height: 1.4),
              ),
              const SizedBox(height: 28),
              AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  final offset = _shakeAnimation.value *
                      (1 - _shakeController.value) *
                      (2 * ((_shakeController.value * 10).toInt() % 2) - 1);
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: child,
                  );
                },
                child: WCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(_otpLength, (index) {
                          return SizedBox(
                            width: 44,
                            height: 54,
                            child: KeyboardListener(
                              focusNode: FocusNode(),
                              onKeyEvent: (event) {
                                if (event is KeyDownEvent &&
                                    event.logicalKey == LogicalKeyboardKey.backspace) {
                                  if (_controllers[index].text.isEmpty && index > 0) {
                                    _focusNodes[index - 1].requestFocus();
                                  }
                                }
                              },
                              child: TextField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                                maxLength: 1,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: const InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: AppRadii.button,
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: AppRadii.button,
                                    borderSide:
                                        BorderSide(color: AppColors.primaryAction, width: 2),
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value.length > 1) {
                                    // Handle paste in individual box
                                    _handlePastedText(value);
                                    return;
                                  }

                                  if (value.isNotEmpty) {
                                    if (index < _otpLength - 1) {
                                      _focusNodes[index + 1].requestFocus();
                                    } else {
                                      _focusNodes[index].unfocus();
                                      _verify();
                                    }
                                  }
                                },
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      // Paste from clipboard helper button
                      TextButton.icon(
                        icon: const Icon(Icons.paste_rounded, size: 16, color: AppColors.teal),
                        label: const Text(
                          'Paste Code from Clipboard',
                          style: TextStyle(fontSize: 13, color: AppColors.teal),
                        ),
                        onPressed: () async {
                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                          if (data?.text != null) {
                            _handlePastedText(data!.text!);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: AppRadii.card,
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 13, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_canResend) ...[
                    const Icon(Icons.timer_outlined, size: 16, color: AppColors.slate),
                    const SizedBox(width: 4),
                    Text(
                      'Resend code in ${_secondsRemaining}s',
                      style: const TextStyle(fontSize: 14, color: AppColors.slate),
                    ),
                  ] else ...[
                    TextButton(
                      onPressed: _resendCode,
                      child: const Text(
                        'Resend OTP Code',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryAction,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: WButton(
                  label: 'Verify & Continue',
                  isLoading: _isLoading,
                  onPressed: _verify,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
