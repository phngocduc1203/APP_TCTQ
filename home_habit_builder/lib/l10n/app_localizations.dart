import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @change_language.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get change_language;

  /// No description provided for @language_vietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get language_vietnamese;

  /// No description provided for @language_english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language_english;

  /// No description provided for @edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get edit_profile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @update_avatar.
  ///
  /// In en, this message translates to:
  /// **'Update avatar'**
  String get update_avatar;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Rate & Feedback'**
  String get feedback;

  /// No description provided for @about_app.
  ///
  /// In en, this message translates to:
  /// **'About app'**
  String get about_app;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @start_date.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get start_date;

  /// No description provided for @progress_label.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} days'**
  String progress_label(Object completed, Object total);

  /// No description provided for @myPlant.
  ///
  /// In en, this message translates to:
  /// **'My Plant'**
  String get myPlant;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @resetPlant.
  ///
  /// In en, this message translates to:
  /// **'Reset Plant'**
  String get resetPlant;

  /// No description provided for @confirmResetPlant.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset the plant?\n\nAll progress will be lost!'**
  String get confirmResetPlant;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @resetPlantSuccess.
  ///
  /// In en, this message translates to:
  /// **'Plant has been reset to seed'**
  String get resetPlantSuccess;

  /// No description provided for @resetPlantFail.
  ///
  /// In en, this message translates to:
  /// **'Reset failed, please try again'**
  String get resetPlantFail;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @xp.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get xp;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get completed;

  /// No description provided for @totalXp.
  ///
  /// In en, this message translates to:
  /// **'Total XP'**
  String get totalXp;

  /// No description provided for @growthTips.
  ///
  /// In en, this message translates to:
  /// **'Growth Tips'**
  String get growthTips;

  /// No description provided for @tipCompleteHabit.
  ///
  /// In en, this message translates to:
  /// **'Complete habits to earn {xp} XP'**
  String tipCompleteHabit(Object xp);

  /// No description provided for @tipDailyLimit.
  ///
  /// In en, this message translates to:
  /// **'Daily limit {dailyMax} XP'**
  String tipDailyLimit(Object dailyMax);

  /// No description provided for @tipStreakBonus.
  ///
  /// In en, this message translates to:
  /// **'7-day streak: +{bonus} XP bonus'**
  String tipStreakBonus(Object bonus);

  /// No description provided for @tipDaysToMax.
  ///
  /// In en, this message translates to:
  /// **'Estimated {days} days to max'**
  String tipDaysToMax(Object days);

  /// No description provided for @stages.
  ///
  /// In en, this message translates to:
  /// **'Growth Stages'**
  String get stages;

  /// No description provided for @stageSeed.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get stageSeed;

  /// No description provided for @stageSprout.
  ///
  /// In en, this message translates to:
  /// **'Sprout'**
  String get stageSprout;

  /// No description provided for @stageLeaves.
  ///
  /// In en, this message translates to:
  /// **'Leaves'**
  String get stageLeaves;

  /// No description provided for @stageBranches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get stageBranches;

  /// No description provided for @stageFlower.
  ///
  /// In en, this message translates to:
  /// **'Flower'**
  String get stageFlower;

  /// No description provided for @habitName.
  ///
  /// In en, this message translates to:
  /// **'Habit name'**
  String get habitName;

  /// No description provided for @habitDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get habitDescription;

  /// No description provided for @habitType.
  ///
  /// In en, this message translates to:
  /// **'Habit type'**
  String get habitType;

  /// No description provided for @habitTypeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get habitTypeNormal;

  /// No description provided for @habitTypeChallenge.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get habitTypeChallenge;

  /// No description provided for @difficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficulty;

  /// No description provided for @easy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easy;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @hard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hard;

  /// No description provided for @veryHard.
  ///
  /// In en, this message translates to:
  /// **'Very Hard'**
  String get veryHard;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get repeatDaily;

  /// No description provided for @repeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get repeatWeekly;

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get repeatMonthly;

  /// No description provided for @selectEnoughDays.
  ///
  /// In en, this message translates to:
  /// **'Please select enough days according to difficulty'**
  String get selectEnoughDays;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @challengeDuration.
  ///
  /// In en, this message translates to:
  /// **'Challenge duration'**
  String get challengeDuration;

  /// No description provided for @totalXP.
  ///
  /// In en, this message translates to:
  /// **'Total XP'**
  String get totalXP;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @addHabitSuccess.
  ///
  /// In en, this message translates to:
  /// **'🎉 Habit added successfully!'**
  String get addHabitSuccess;

  /// No description provided for @addHabitFail.
  ///
  /// In en, this message translates to:
  /// **'❌ Cannot add habit.'**
  String get addHabitFail;

  /// No description provided for @aiSuggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'💡 AI habit suggestions (morning/noon/evening)'**
  String get aiSuggestionsTitle;

  /// No description provided for @aiMorning.
  ///
  /// In en, this message translates to:
  /// **'🌅 Morning'**
  String get aiMorning;

  /// No description provided for @aiNoon.
  ///
  /// In en, this message translates to:
  /// **'🌞 Noon'**
  String get aiNoon;

  /// No description provided for @aiEvening.
  ///
  /// In en, this message translates to:
  /// **'🌙 Evening'**
  String get aiEvening;

  /// No description provided for @aiQuickSuggestion.
  ///
  /// In en, this message translates to:
  /// **'💡 AI suggestion: {suggestion}'**
  String aiQuickSuggestion(Object suggestion);

  /// No description provided for @habitAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'🎉 Habit added successfully!'**
  String get habitAddedSuccess;

  /// No description provided for @habitAddedFail.
  ///
  /// In en, this message translates to:
  /// **'❌ Could not add habit.'**
  String get habitAddedFail;

  /// No description provided for @addHabit.
  ///
  /// In en, this message translates to:
  /// **'Add Habit'**
  String get addHabit;

  /// No description provided for @habitDesc.
  ///
  /// In en, this message translates to:
  /// **'Habit Description'**
  String get habitDesc;

  /// No description provided for @aiSuggestion.
  ///
  /// In en, this message translates to:
  /// **'AI Suggestion'**
  String get aiSuggestion;

  /// No description provided for @normalHabit.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normalHabit;

  /// No description provided for @challengeHabit.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get challengeHabit;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @selectNextTwoWeeks.
  ///
  /// In en, this message translates to:
  /// **'Select next 2 weeks'**
  String get selectNextTwoWeeks;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next Month'**
  String get nextMonth;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @atLeast.
  ///
  /// In en, this message translates to:
  /// **'at least'**
  String get atLeast;

  /// No description provided for @saveHabit.
  ///
  /// In en, this message translates to:
  /// **'Save Habit'**
  String get saveHabit;

  /// No description provided for @aiHabitSuggestions.
  ///
  /// In en, this message translates to:
  /// **'AI Habit Suggestions'**
  String get aiHabitSuggestions;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @noon.
  ///
  /// In en, this message translates to:
  /// **'Noon'**
  String get noon;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @benefit.
  ///
  /// In en, this message translates to:
  /// **'Benefit'**
  String get benefit;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
