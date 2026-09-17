// lib/shared/widgets/app_widgets.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────
// BOUTON PRIMAIRE CHARGEABLE
// ─────────────────────────────────────────────
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.or,
        disabledBackgroundColor: AppColors.or.withOpacity(0.6),
      ),
      child: isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.noir,
              ),
            )
          : Text(label),
    );
  }
}

// ─────────────────────────────────────────────
// CHAMP DE FORMULAIRE STYLED
// ─────────────────────────────────────────────
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int maxLines;
  final void Function(String)? onChanged;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CARTE D'INFORMATION (profil, détails personne)
// ─────────────────────────────────────────────
class AppInfoCard extends StatelessWidget {
  final String title;
  final List<InfoRow> rows;
  final Widget? trailing;

  const AppInfoCard({
    super.key,
    required this.title,
    required this.rows,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            ...rows.map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(
                          row.label,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          row.value,
                          style: const TextStyle(
                            color: AppColors.noir,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class InfoRow {
  final String label;
  final String value;
  const InfoRow(this.label, this.value);
}

// ─────────────────────────────────────────────
// LOADER CENTRÉ
// ─────────────────────────────────────────────
class AppLoader extends StatelessWidget {
  const AppLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.vertForet,
        strokeWidth: 3,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BANNIÈRE D'ERREUR / SUCCÈS
// ─────────────────────────────────────────────
class AppBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const AppBanner({super.key, required this.message, this.isError = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isError
            ? AppColors.erreur.withOpacity(0.1)
            : AppColors.succes.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? AppColors.erreur : AppColors.succes,
          width: 1,
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError ? AppColors.erreur : AppColors.succes,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// AVATAR UTILISATEUR
// ─────────────────────────────────────────────
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double radius;
  final Color? backgroundColor;

  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.initials,
    this.radius = 28,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppColors.or,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null
          ? Text(
              initials.toUpperCase(),
              style: TextStyle(
                color: AppColors.noir,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.65,
              ),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────
// INDICATEUR D'ÉTAPES (formulaires multi-étapes)
// ─────────────────────────────────────────────
class WizardStepIndicator extends StatelessWidget {
  final int stepCount;
  final int currentStep; // index 0-based
  final List<String>? labels;

  const WizardStepIndicator({
    super.key,
    required this.stepCount,
    required this.currentStep,
    this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(stepCount * 2 - 1, (i) {
        if (i.isOdd) {
          final leftStep = i ~/ 2;
          final done = leftStep < currentStep;
          return Expanded(
            child: Container(
              height: 2,
              color: done ? AppColors.vertForet : AppColors.grisClair,
            ),
          );
        }
        final step = i ~/ 2;
        final isDone = step < currentStep;
        final isCurrent = step == currentStep;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone || isCurrent ? AppColors.vertForet : AppColors.grisClair,
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 16, color: AppColors.blanc)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isCurrent ? AppColors.blanc : AppColors.gris,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
            ),
            if (labels != null && labels!.length > step) ...[
              const SizedBox(height: 4),
              Text(
                labels![step],
                style: const TextStyle(fontSize: 9, color: AppColors.gris),
              ),
            ],
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────
// SECTION AVEC TITRE STYLÉ (fond vert)
// ─────────────────────────────────────────────
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (subtitle != null)
              Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        if (action != null) action!,
      ],
    );
  }
}
