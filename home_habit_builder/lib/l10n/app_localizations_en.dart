// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get change_language => 'Settings';

  @override
  String get language_vietnamese => 'Vietnamese';

  @override
  String get language_english => 'English';

  @override
  String get edit_profile => 'Edit profile';

  @override
  String get logout => 'Log out';

  @override
  String get save => 'Save';

  @override
  String get update_avatar => 'Update avatar';

  @override
  String get notifications => 'Notifications';

  @override
  String get feedback => 'Rate & Feedback';

  @override
  String get about_app => 'About app';

  @override
  String get user => 'User';

  @override
  String get start_date => 'Start date';

  @override
  String progress_label(Object completed, Object total) {
    return '$completed/$total days';
  }

  @override
  String get myPlant => 'My Plant';

  @override
  String get refresh => 'Refresh';

  @override
  String get resetPlant => 'Reset Plant';

  @override
  String get confirmResetPlant =>
      'Are you sure you want to reset the plant?\n\nAll progress will be lost!';

  @override
  String get cancel => 'Cancel';

  @override
  String get resetPlantSuccess => 'Plant has been reset to seed';

  @override
  String get resetPlantFail => 'Reset failed, please try again';

  @override
  String get today => 'Today';

  @override
  String get xp => 'XP';

  @override
  String get streak => 'Streak';

  @override
  String get days => 'days';

  @override
  String get progress => 'Progress';

  @override
  String get completed => 'completed';

  @override
  String get totalXp => 'Total XP';

  @override
  String get growthTips => 'Growth Tips';

  @override
  String tipCompleteHabit(Object xp) {
    return 'Complete habits to earn $xp XP';
  }

  @override
  String tipDailyLimit(Object dailyMax) {
    return 'Daily limit $dailyMax XP';
  }

  @override
  String tipStreakBonus(Object bonus) {
    return '7-day streak: +$bonus XP bonus';
  }

  @override
  String tipDaysToMax(Object days) {
    return 'Estimated $days days to max';
  }

  @override
  String get stages => 'Growth Stages';

  @override
  String get stageSeed => 'Seed';

  @override
  String get stageSprout => 'Sprout';

  @override
  String get stageLeaves => 'Leaves';

  @override
  String get stageBranches => 'Branches';

  @override
  String get stageFlower => 'Flower';

  @override
  String get habitName => 'Habit name';

  @override
  String get habitDescription => 'Description';

  @override
  String get habitType => 'Habit type';

  @override
  String get habitTypeNormal => 'Normal';

  @override
  String get habitTypeChallenge => 'Challenge';

  @override
  String get difficulty => 'Difficulty';

  @override
  String get easy => 'Easy';

  @override
  String get medium => 'Medium';

  @override
  String get hard => 'Hard';

  @override
  String get veryHard => 'Very Hard';

  @override
  String get repeat => 'Repeat';

  @override
  String get repeatDaily => 'Daily';

  @override
  String get repeatWeekly => 'Weekly';

  @override
  String get repeatMonthly => 'Monthly';

  @override
  String get selectEnoughDays =>
      'Please select enough days according to difficulty';

  @override
  String get selectAll => 'Select all';

  @override
  String get challengeDuration => 'Challenge duration';

  @override
  String get totalXP => 'Total XP';

  @override
  String get saving => 'Saving...';

  @override
  String get addHabitSuccess => '🎉 Habit added successfully!';

  @override
  String get addHabitFail => '❌ Cannot add habit.';

  @override
  String get aiSuggestionsTitle =>
      '💡 AI habit suggestions (morning/noon/evening)';

  @override
  String get aiMorning => '🌅 Morning';

  @override
  String get aiNoon => '🌞 Noon';

  @override
  String get aiEvening => '🌙 Evening';

  @override
  String aiQuickSuggestion(Object suggestion) {
    return '💡 AI suggestion: $suggestion';
  }

  @override
  String get habitAddedSuccess => '🎉 Habit added successfully!';

  @override
  String get habitAddedFail => '❌ Could not add habit.';

  @override
  String get addHabit => 'Add Habit';

  @override
  String get habitDesc => 'Habit Description';

  @override
  String get aiSuggestion => 'AI Suggestion';

  @override
  String get normalHabit => 'Normal';

  @override
  String get challengeHabit => 'Challenge';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get selectNextTwoWeeks => 'Select next 2 weeks';

  @override
  String get nextMonth => 'Next Month';

  @override
  String get thisMonth => 'This Month';

  @override
  String get atLeast => 'at least';

  @override
  String get saveHabit => 'Save Habit';

  @override
  String get aiHabitSuggestions => 'AI Habit Suggestions';

  @override
  String get morning => 'Morning';

  @override
  String get noon => 'Noon';

  @override
  String get evening => 'Evening';

  @override
  String get benefit => 'Benefit';
}
