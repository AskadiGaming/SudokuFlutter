import 'package:flutter/foundation.dart';

import '../../sudoku/domain/sudoku_difficulty.dart';
import '../data/challenge_repository.dart';
import '../domain/challenge_day_entry.dart';
import '../domain/challenge_month_data.dart';
import '../domain/challenge_selection.dart';

class ChallengeController extends ChangeNotifier {
  ChallengeController({
    required ChallengeRepository repository,
    DateTime? today,
  }) : _repository = repository,
       _today = today ?? DateTime.now();

  final ChallengeRepository _repository;
  final DateTime _today;

  SudokuDifficulty _selectedDifficulty = SudokuDifficulty.easy;
  ChallengeMonthData? _monthData;
  DateTime? _visibleMonth;
  DateTime? _selectedDate;
  Object? _error;
  bool _isLoading = false;
  bool _initialized = false;

  SudokuDifficulty get selectedDifficulty => _selectedDifficulty;
  ChallengeMonthData? get monthData => _monthData;
  DateTime? get visibleMonth => _visibleMonth;
  DateTime? get selectedDate => _selectedDate;
  Object? get error => _error;
  bool get isLoading => _isLoading;

  ChallengeDayEntry? get selectedEntry {
    final ChallengeMonthData? data = _monthData;
    final DateTime? selectedDate = _selectedDate;
    if (data == null || selectedDate == null) {
      return null;
    }
    for (final ChallengeDayEntry entry in data.entries) {
      if (_sameDate(entry.date, selectedDate)) {
        return entry;
      }
    }
    return null;
  }

  ChallengeSelection? get selection {
    final DateTime? selectedDate = _selectedDate;
    if (selectedDate == null) {
      return null;
    }
    return ChallengeSelection(
      date: selectedDate,
      difficulty: _selectedDifficulty,
    );
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    final DateTime initialMonth =
        await _repository.loadLastPlayedMonth() ?? _firstDayOfMonth(_today);
    await _loadMonth(initialMonth, preserveSelectedDate: false);
  }

  Future<void> refresh() async {
    final DateTime month = _visibleMonth ?? _firstDayOfMonth(_today);
    await _loadMonth(month, preserveSelectedDate: true);
  }

  Future<void> selectDifficulty(SudokuDifficulty difficulty) async {
    if (_selectedDifficulty == difficulty) {
      return;
    }
    _selectedDifficulty = difficulty;
    notifyListeners();
    await refresh();
  }

  Future<void> showPreviousMonth() async {
    final DateTime baseMonth = _visibleMonth ?? _firstDayOfMonth(_today);
    await _loadMonth(DateTime(baseMonth.year, baseMonth.month - 1));
  }

  Future<void> showNextMonth() async {
    final DateTime baseMonth = _visibleMonth ?? _firstDayOfMonth(_today);
    await _loadMonth(DateTime(baseMonth.year, baseMonth.month + 1));
  }

  Future<void> selectDate(DateTime date) async {
    final DateTime normalized = _dateOnly(date);
    final DateTime currentMonth = _visibleMonth ?? _firstDayOfMonth(_today);
    if (normalized.year != currentMonth.year ||
        normalized.month != currentMonth.month) {
      await _loadMonth(DateTime(normalized.year, normalized.month));
    }
    _selectedDate = normalized;
    notifyListeners();
  }

  Future<void> _loadMonth(
    DateTime month, {
    bool preserveSelectedDate = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final DateTime normalizedMonth = _firstDayOfMonth(month);
    try {
      final ChallengeMonthData data = await _repository.loadMonthData(
        month: normalizedMonth,
        difficulty: _selectedDifficulty,
      );
      _monthData = data;
      _visibleMonth = normalizedMonth;
      _selectedDate = _resolveSelectedDate(
        data: data,
        preserveSelectedDate: preserveSelectedDate,
      );
    } catch (error, stackTrace) {
      debugPrint('Challenge month loading failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  DateTime _resolveSelectedDate({
    required ChallengeMonthData data,
    required bool preserveSelectedDate,
  }) {
    if (preserveSelectedDate && _selectedDate != null) {
      return _selectedDate!;
    }

    final DateTime today = _dateOnly(_today);
    if (today.year == data.month.year && today.month == data.month.month) {
      return today;
    }

    for (final ChallengeDayEntry entry in data.entries) {
      if (entry.isInCurrentMonth) {
        return entry.date;
      }
    }
    return data.month;
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _firstDayOfMonth(DateTime value) {
    return DateTime(value.year, value.month);
  }

  bool _sameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
