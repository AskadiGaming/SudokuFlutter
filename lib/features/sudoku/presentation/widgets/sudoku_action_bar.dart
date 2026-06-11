import 'package:flutter/material.dart';

class SudokuActionBar extends StatelessWidget {
  const SudokuActionBar({
    required this.isDeleteModeSelected,
    required this.canUndo,
    required this.canSelectDeleteMode,
    required this.canRequestHint,
    required this.isHintLoading,
    required this.showAdminSolve,
    required this.canUseAdminSolve,
    required this.undoLabel,
    required this.deleteLabel,
    required this.hintLabel,
    required this.adminSolveLabel,
    this.onUndo,
    this.onDeleteModeSelected,
    this.onHint,
    this.onAdminSolve,
    super.key,
  });

  final bool isDeleteModeSelected;
  final bool canUndo;
  final bool canSelectDeleteMode;
  final bool canRequestHint;
  final bool isHintLoading;
  final bool showAdminSolve;
  final bool canUseAdminSolve;
  final String undoLabel;
  final String deleteLabel;
  final String hintLabel;
  final String adminSolveLabel;
  final VoidCallback? onUndo;
  final VoidCallback? onDeleteModeSelected;
  final VoidCallback? onHint;
  final VoidCallback? onAdminSolve;

  @override
  Widget build(BuildContext context) {
    final List<Widget> actions = <Widget>[
      _ActionBarButton(
        key: const Key('sudoku-action-undo'),
        keyName: 'sudoku-action-undo',
        label: undoLabel,
        icon: Icons.undo_rounded,
        enabled: canUndo,
        isSelected: false,
        onPressed: onUndo,
      ),
      _ActionBarButton(
        key: const Key('sudoku-action-delete'),
        keyName: 'sudoku-action-delete',
        label: deleteLabel,
        icon: Icons.backspace_outlined,
        enabled: canSelectDeleteMode,
        isSelected: isDeleteModeSelected,
        onPressed: onDeleteModeSelected,
      ),
      _ActionBarButton(
        key: const Key('sudoku-hint-button'),
        keyName: 'sudoku-hint-button',
        label: hintLabel,
        icon: Icons.lightbulb_outline,
        enabled: canRequestHint && !isHintLoading,
        isSelected: false,
        onPressed: onHint,
        trailingBadgeIcon: Icons.smart_display_rounded,
        showProgress: isHintLoading,
      ),
    ];

    if (showAdminSolve) {
      actions.add(
        _ActionBarButton(
          key: const Key('admin-solve-sudoku-button'),
          keyName: 'admin-solve-sudoku-button',
          label: adminSolveLabel,
          icon: Icons.key_outlined,
          enabled: canUseAdminSolve,
          isSelected: false,
          onPressed: onAdminSolve,
        ),
      );
    }

    return Row(
      children: actions
          .map(
            (Widget action) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: action,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ActionBarButton extends StatelessWidget {
  const _ActionBarButton({
    required this.keyName,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.isSelected,
    required this.onPressed,
    this.trailingBadgeIcon,
    this.showProgress = false,
    super.key,
  });

  final String keyName;
  final String label;
  final IconData icon;
  final bool enabled;
  final bool isSelected;
  final VoidCallback? onPressed;
  final IconData? trailingBadgeIcon;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color backgroundColor =
        isSelected
            ? colorScheme.primaryContainer
            : enabled
            ? colorScheme.surface
            : colorScheme.surfaceContainerHighest;
    final Color foregroundColor =
        isSelected
            ? colorScheme.onPrimaryContainer
            : enabled
            ? colorScheme.onSurface
            : colorScheme.onSurface.withValues(alpha: 0.38);
    final Color borderColor =
        isSelected
            ? colorScheme.primary
            : enabled
            ? colorScheme.outline
            : colorScheme.outline.withValues(alpha: 0.4);

    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('$keyName-button'),
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            key: Key('$keyName-${isSelected ? 'selected' : 'idle'}'),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  height: 36,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Center(
                        child:
                            showProgress
                                ? SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: foregroundColor,
                                  ),
                                )
                                : Icon(icon, size: 30, color: foregroundColor),
                      ),
                      if (trailingBadgeIcon != null && !showProgress)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                trailingBadgeIcon,
                                size: 12,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
