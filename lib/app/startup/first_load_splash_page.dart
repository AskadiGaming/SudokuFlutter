import 'package:flutter/material.dart';

class FirstLoadSplashPage extends StatelessWidget {
  const FirstLoadSplashPage({
    required this.progress,
    required this.message,
    required this.isLoading,
    this.errorMessage,
    this.onRetry,
    super.key,
  });

  final double progress;
  final String message;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasError = errorMessage != null;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF09203F), Color(0xFF1F4C7A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Icon(
                          hasError
                              ? Icons.error_outline
                              : Icons.grid_view_rounded,
                          size: 56,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          hasError
                              ? 'Initialisierung fehlgeschlagen'
                              : 'Sudoku wird vorbereitet',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          hasError
                              ? 'Die App konnte die Startdaten nicht vollstaendig laden.'
                              : 'Dies passiert nur beim ersten Start und kann einen kurzen Moment dauern.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        LinearProgressIndicator(
                          value: hasError ? null : progress,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          hasError ? (errorMessage ?? '') : message,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                        if (hasError) ...<Widget>[
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: isLoading ? null : onRetry,
                            child:
                                isLoading
                                    ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text('Erneut versuchen'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
