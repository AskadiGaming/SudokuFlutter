enum AppStartupStatus { loading, ready, error }

class AppStartupState {
  const AppStartupState({
    required this.status,
    required this.progress,
    required this.message,
    required this.showFirstLoadSplash,
    this.errorMessage,
  });

  const AppStartupState.loading({
    double progress = 0,
    String message = '',
    bool showFirstLoadSplash = false,
  }) : this(
         status: AppStartupStatus.loading,
         progress: progress,
         message: message,
         showFirstLoadSplash: showFirstLoadSplash,
       );

  const AppStartupState.ready()
    : this(
        status: AppStartupStatus.ready,
        progress: 1,
        message: 'App bereit',
        showFirstLoadSplash: false,
      );

  const AppStartupState.error({
    required String errorMessage,
    required double progress,
    required String message,
    required bool showFirstLoadSplash,
  }) : this(
         status: AppStartupStatus.error,
         progress: progress,
         message: message,
         showFirstLoadSplash: showFirstLoadSplash,
         errorMessage: errorMessage,
       );

  final AppStartupStatus status;
  final double progress;
  final String message;
  final bool showFirstLoadSplash;
  final String? errorMessage;

  bool get isReady => status == AppStartupStatus.ready;
  bool get hasError => status == AppStartupStatus.error;

  AppStartupState copyWith({
    AppStartupStatus? status,
    double? progress,
    String? message,
    bool? showFirstLoadSplash,
    String? errorMessage,
  }) {
    return AppStartupState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      showFirstLoadSplash: showFirstLoadSplash ?? this.showFirstLoadSplash,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
