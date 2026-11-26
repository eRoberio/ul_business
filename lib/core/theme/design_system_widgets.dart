import 'package:flutter/material.dart';

import 'app_colors.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final double? width;
  final VoidCallback? onTap;

  const CustomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 12,
    this.width,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final decoration = BoxDecoration(
      color: backgroundColor ?? tokens.surfaceElevated1,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? tokens.borderSubtle,
        width: 1,
      ),
      boxShadow: tokens.cardShadow,
    );

    final content = onTap == null
        ? Padding(padding: padding, child: child)
        : Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadius),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Padding(padding: padding, child: child),
            ),
          );

    return Container(
      width: width,
      margin: margin,
      decoration: decoration,
      child: content,
    );
  }
}

class KpiCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final String trend;
  final IconData icon;
  final Color color;

  const KpiCard({
    super.key,
    required this.width,
    required this.title,
    required this.value,
    required this.trend,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return CustomCard(
      width: width,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: tokens.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tokens.badgeBackground(color),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            trend,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback? onLongPress;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tokens.badgeBackground(color),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );

    if (onLongPress == null) return badge;
    return GestureDetector(onLongPress: onLongPress, child: badge);
  }
}

class EmptyStateBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const EmptyStateBox({
    super.key,
    required this.icon,
    this.title = '',
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tokens.surfaceElevated2,
              shape: BoxShape.circle,
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: Icon(icon, size: 24, color: tokens.textSecondary),
          ),
          if (title.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

String formatBrlCurrency(double value) {
  final isNegative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final decPart = parts[1];

  final buffer = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    final reversedIndex = intPart.length - i;
    if (i > 0 && reversedIndex % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(intPart[i]);
  }

  return '${isNegative ? '-' : ''}R\$ ${buffer.toString()},$decPart';
}

class ULBusinessLogo extends StatelessWidget {
  final double size;
  final double borderRadius;
  final bool showBorder;

  const ULBusinessLogo({
    super.key,
    this.size = 48,
    this.borderRadius = 12,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.darkCanvas,
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(
                color: tokens.isDark
                    ? tokens.primary.withValues(alpha: 0.35)
                    : tokens.borderSubtle,
                width: 1,
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/ULbussineslogo.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.business_center_rounded,
          color: tokens.primary,
          size: size * 0.55,
        ),
      ),
    );
  }
}

class BrandLoadingView extends StatefulWidget {
  final String message;
  final double logoSize;

  const BrandLoadingView({
    super.key,
    this.message = 'Carregando...',
    this.logoSize = 84,
  });

  @override
  State<BrandLoadingView> createState() => _BrandLoadingViewState();
}

class _BrandLoadingViewState extends State<BrandLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: tokens.primary.withValues(alpha: 0.22),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: widget.logoSize + 18,
                    height: widget.logoSize + 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: tokens.primary,
                      backgroundColor: tokens.borderSubtle,
                    ),
                  ),
                  ULBusinessLogo(
                    size: widget.logoSize,
                    borderRadius: widget.logoSize / 2,
                    showBorder: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.message,
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
