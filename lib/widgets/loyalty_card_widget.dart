
import 'package:casinoloyalty_flutter/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LoyaltyCardWidget extends StatelessWidget {
  const LoyaltyCardWidget({
    super.key,
    required this.user,
    this.compact = false,
  });

  final User user;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'es_CL', symbol: 'CLP\$');
    final pointsFormatter = NumberFormat.decimalPattern('es_CL');
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(compact ? 22 : 28);
    final padding = compact ? const EdgeInsets.all(20) : const EdgeInsets.all(24);
    final double height = compact ? 170 : 210;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          colors: [
            user.levelColor.withValues(alpha: 0.95),
            colorScheme.surface.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: user.levelColor.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Dreams Club',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Chip(
                label: Text(
                  user.levelName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '**** **** **** 1234',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: compact ? 16 : 20,
              letterSpacing: 2.4,
              fontFamily: 'RobotoMono',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _CardMetric(
                  label: 'PUNTOS',
                  value: pointsFormatter.format(user.points),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _CardMetric(
                  label: 'SALDO',
                  value: currencyFormatter.format(user.balance),
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              user.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardMetric extends StatelessWidget {
  const _CardMetric({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final alignment = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: alignment,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
