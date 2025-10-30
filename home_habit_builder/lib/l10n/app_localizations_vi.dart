// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get change_language => 'Cài đặt';

  @override
  String get language_vietnamese => 'Tiếng Việt';

  @override
  String get language_english => 'Tiếng Anh';

  @override
  String get edit_profile => 'Chỉnh sửa thông tin';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get save => 'Lưu';

  @override
  String get update_avatar => 'Cập nhật ảnh đại diện';

  @override
  String get notifications => 'Thông báo';

  @override
  String get feedback => 'Đánh giá & Phản hồi';

  @override
  String get about_app => 'Giới thiệu ứng dụng';

  @override
  String get user => 'Người dùng';

  @override
  String get start_date => 'Bắt đầu';

  @override
  String progress_label(Object completed, Object total) {
    return '$completed/$total ngày';
  }

  @override
  String get myPlant => 'Cây của tôi';

  @override
  String get refresh => 'Làm mới';

  @override
  String get resetPlant => 'Đặt lại cây';

  @override
  String get confirmResetPlant =>
      'Bạn có chắc muốn đặt lại cây về trạng thái ban đầu?\n\nMọi tiến trình sẽ bị xóa!';

  @override
  String get cancel => 'Hủy';

  @override
  String get resetPlantSuccess => 'Đã đặt lại cây về hạt giống';

  @override
  String get resetPlantFail => 'Đặt lại thất bại, thử lại sau';

  @override
  String get today => 'Hôm nay';

  @override
  String get xp => 'XP';

  @override
  String get streak => 'Streak';

  @override
  String get days => 'ngày';

  @override
  String get progress => 'Tiến độ';

  @override
  String get completed => 'hoàn thành';

  @override
  String get totalXp => 'Tổng XP';

  @override
  String get growthTips => 'Mẹo phát triển';

  @override
  String tipCompleteHabit(Object xp) {
    return 'Hoàn thành habit để nhận $xp XP';
  }

  @override
  String tipDailyLimit(Object dailyMax) {
    return 'Giới hạn $dailyMax XP mỗi ngày';
  }

  @override
  String tipStreakBonus(Object bonus) {
    return 'Streak 7 ngày: +$bonus XP bonus';
  }

  @override
  String tipDaysToMax(Object days) {
    return 'Ước tính $days ngày để max';
  }

  @override
  String get stages => 'Các giai đoạn phát triển';

  @override
  String get stageSeed => 'Hạt giống';

  @override
  String get stageSprout => 'Mọc mầm';

  @override
  String get stageLeaves => 'Mọc lá';

  @override
  String get stageBranches => 'Mọc cành';

  @override
  String get stageFlower => 'Ra hoa';

  @override
  String get habitName => 'Tên thói quen';

  @override
  String get habitDescription => 'Mô tả';

  @override
  String get habitType => 'Loại thói quen';

  @override
  String get habitTypeNormal => 'Thông thường';

  @override
  String get habitTypeChallenge => 'Thử thách';

  @override
  String get difficulty => 'Độ khó';

  @override
  String get easy => 'Easy';

  @override
  String get medium => 'Medium';

  @override
  String get hard => 'Hard';

  @override
  String get veryHard => 'Very Hard';

  @override
  String get repeat => 'Lặp lại';

  @override
  String get repeatDaily => 'Hàng ngày';

  @override
  String get repeatWeekly => 'Hàng tuần';

  @override
  String get repeatMonthly => 'Hàng tháng';

  @override
  String get selectEnoughDays => 'Vui lòng chọn đủ ngày theo độ khó';

  @override
  String get selectAll => 'Chọn tất cả';

  @override
  String get challengeDuration => 'Thời lượng thử thách';

  @override
  String get totalXP => 'Tổng XP';

  @override
  String get saving => 'Đang lưu...';

  @override
  String get addHabitSuccess => '🎉 Thêm thói quen thành công!';

  @override
  String get addHabitFail => '❌ Không thể thêm thói quen.';

  @override
  String get aiSuggestionsTitle =>
      '💡 Gợi ý thói quen từ AI (theo sáng/trưa/tối)';

  @override
  String get aiMorning => '🌅 Buổi sáng';

  @override
  String get aiNoon => '🌞 Buổi trưa';

  @override
  String get aiEvening => '🌙 Buổi tối';

  @override
  String aiQuickSuggestion(Object suggestion) {
    return '💡 Gợi ý AI: $suggestion';
  }

  @override
  String get habitAddedSuccess => '🎉 Thêm thói quen thành công!';

  @override
  String get habitAddedFail => '❌ Không thể thêm thói quen.';

  @override
  String get addHabit => 'Thêm thói quen';

  @override
  String get habitDesc => 'Mô tả thói quen';

  @override
  String get aiSuggestion => 'Gợi ý AI';

  @override
  String get normalHabit => 'Thông thường';

  @override
  String get challengeHabit => 'Thử thách';

  @override
  String get daily => 'Hàng ngày';

  @override
  String get weekly => 'Hàng tuần';

  @override
  String get monthly => 'Hàng tháng';

  @override
  String get selectNextTwoWeeks => 'Chọn 2 tuần tiếp theo';

  @override
  String get nextMonth => 'Tháng sau';

  @override
  String get thisMonth => 'Tháng này';

  @override
  String get atLeast => 'ít nhất';

  @override
  String get saveHabit => 'Lưu thói quen';

  @override
  String get aiHabitSuggestions => 'Gợi ý thói quen từ AI';

  @override
  String get morning => 'Buổi sáng';

  @override
  String get noon => 'Buổi trưa';

  @override
  String get evening => 'Buổi tối';

  @override
  String get benefit => 'Lợi ích';
}
