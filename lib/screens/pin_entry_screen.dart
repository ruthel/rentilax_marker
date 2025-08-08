import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rentilax_tracker/l10n/l10n_extensions.dart';
import '../services/pin_service.dart';
import '../utils/app_spacing.dart';

class PinEntryScreen extends StatefulWidget {
  final VoidCallback onPinVerified;

  const PinEntryScreen({super.key, required this.onPinVerified});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(5, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (index) => FocusNode());
  String _errorMessage = '';
  bool _isLoading = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _shakeController.dispose();
    super.dispose();
  }

  String get _pin => _controllers.map((c) => c.text).join();

  Future<void> _verifyPin() async {
    final localizations = context.l10n;
    if (_pin.length != 5) {
      _showError(localizations.pleaseEnter5DigitsPin);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Ajouter un petit délai pour l'effet visuel
    await Future.delayed(const Duration(milliseconds: 500));

    final isVerified = await PinService.verifyPin(_pin);

    if (mounted) {
      setState(() => _isLoading = false);

      if (isVerified) {
        // Animation de succès
        HapticFeedback.lightImpact();
        widget.onPinVerified();
      } else {
        _showError(localizations.incorrectPin);
        _shakeController.forward().then((_) => _shakeController.reset());
        HapticFeedback.heavyImpact();
        _clearPin();
      }
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _errorMessage = '');
      }
    });
  }

  void _clearPin() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _onDigitChanged(int index, String value) {
    // Uniquement pour faire avancer le focus
    if (value.isNotEmpty) {
      if (index < 4) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyPin();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = context.l10n;

    final double maxContentWidth = 600;
    final double horizontalInset = AppSpacing.xl + AppSpacing.sm; // 40px

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxWidth: maxContentWidth,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo et titre
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          size: 52,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      Text(
                        'Code PIN',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      Text(
                        localizations.enterYourPin,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Champs PIN
                      KeyboardListener(
                        focusNode: FocusNode(),
                        onKeyEvent: (KeyEvent event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey ==
                                  LogicalKeyboardKey.backspace) {
                            int focusedIndex =
                                _focusNodes.indexWhere((node) => node.hasFocus);
                            if (focusedIndex != -1) {
                              if (_controllers[focusedIndex].text.isNotEmpty) {
                                _controllers[focusedIndex].clear();
                              } else if (focusedIndex > 0) {
                                _focusNodes[focusedIndex - 1].requestFocus();
                                _controllers[focusedIndex - 1].clear();
                              }
                            }
                          }
                        },
                        child: AnimatedBuilder(
                          animation: _shakeAnimation,
                          builder: (context, child) {
                            // Calcul réactif de la taille des champs PIN
                            final double availableWidth =
                                MediaQuery.of(context).size.width;
                            final double contentWidth =
                                availableWidth > maxContentWidth
                                    ? maxContentWidth
                                    : availableWidth - (horizontalInset * 2);
                            const double gap = 12;
                            double pinSize = (contentWidth - (gap * 4)) / 5;
                            pinSize = pinSize.clamp(44.0, 44.0);

                            return Transform.translate(
                              offset: Offset(_shakeAnimation.value, 0),
                              child: Row(
                                spacing: 8,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (index) {
                                  return Container(
                                    width: pinSize,
                                    height: pinSize,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _errorMessage.isNotEmpty
                                            ? colorScheme.error
                                            : _controllers[index]
                                                    .text
                                                    .isNotEmpty
                                                ? colorScheme.primary
                                                : colorScheme.outline,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: _controllers[index].text.isNotEmpty
                                          ? colorScheme.primaryContainer
                                              .withValues(alpha: 0.3)
                                          : colorScheme.surface,
                                    ),
                                    child: TextField(
                                      controller: _controllers[index],
                                      focusNode: _focusNodes[index],
                                      showCursor:
                                          false, // 👈 hides the blinking cursor
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                      keyboardType: TextInputType.number,
                                      obscureText: true,
                                      maxLength: 1,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        counterText: '',
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      onChanged: (value) =>
                                          _onDigitChanged(index, value),
                                      onTap: () {
                                        // Trouve le premier champ vide et y met le focus
                                        final firstEmpty = _controllers
                                            .indexWhere((c) => c.text.isEmpty);
                                        if (firstEmpty != -1) {
                                          _focusNodes[firstEmpty]
                                              .requestFocus();
                                        }
                                      },
                                    ),
                                  );
                                }),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Message d'erreur
                      Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: _errorMessage.isNotEmpty ? 32 : 0,
                          child: _errorMessage.isNotEmpty
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: colorScheme.onErrorContainer,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _errorMessage,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onErrorContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Bouton de validation
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyPin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 1,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.lock_open,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      localizations.unlock,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Footer
                      Center(
                        child: Text(
                          localizations.appTitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
