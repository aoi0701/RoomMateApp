import '../models/roommate_criteria_model.dart';

// Chuyển đổi thói quen (habit ID) sang tiêu chí tìm roommate tương ứng.
// Bảng mapping: habit → RoommateCriteriaModel để tự động điền roommateCriteria khi user chọn thói quen.
class HabitRoommateCriteriaMapper {
  static const Map<String, RoommateCriteriaModel> _mapping = {
    'no_smoking': RoommateCriteriaModel(
      id: 'criteria_no_smoking',
      label: 'Không hút thuốc',
    ),
    'clean': RoommateCriteriaModel(
      id: 'criteria_hygiene',
      label: 'Giữ gìn vệ sinh',
    ),
    'sleep_early': RoommateCriteriaModel(
      id: 'criteria_schedule',
      label: 'Lịch sinh hoạt ổn định',
    ),
    'prefer_quiet': RoommateCriteriaModel(
      id: 'criteria_prefer_quiet',
      label: 'Ưu tiên không gian yên tĩnh',
    ),
    'study_often': RoommateCriteriaModel(
      id: 'criteria_study_friendly',
      label: 'Phù hợp với môi trường học tập nghiêm túc',
    ),
    'less_partying': RoommateCriteriaModel(
      id: 'criteria_quiet',
      label: 'Không ồn ào, hạn chế tiệc tùng',
    ),
    'pet_friendly': RoommateCriteriaModel(
      id: 'criteria_pet_friendly',
      label: 'Thoải mái với thú cưng',
    ),
    'has_pet': RoommateCriteriaModel(
      id: 'criteria_has_pet',
      label: 'Chấp nhận ở cùng người có nuôi thú cưng',
    ),
    'neat': RoommateCriteriaModel(
      id: 'criteria_neat',
      label: 'Giữ không gian gọn gàng',
    ),
    'stay_up_late': RoommateCriteriaModel(
      id: 'criteria_late_schedule',
      label: 'Phù hợp với lịch sinh hoạt muộn',
    ),
    'communicative': RoommateCriteriaModel(
      id: 'criteria_communication',
      label: 'Giao tiếp rõ ràng, tôn trọng nhau',
    ),
    'like_gathering': RoommateCriteriaModel(
      id: 'criteria_social',
      label: 'Thoải mái với việc bạn bè ghé chơi hợp lý',
    ),
    'flexible_schedule': RoommateCriteriaModel(
      id: 'criteria_flexible_schedule',
      label: 'Tôn trọng lịch sinh hoạt linh hoạt của nhau',
    ),
    'like_midnight_snack': RoommateCriteriaModel(
      id: 'criteria_midnight_snack',
      label: 'Thoải mái với sinh hoạt ăn uống buổi tối',
    ),
    'no_cooking': RoommateCriteriaModel(
      id: 'criteria_no_cooking',
      label: 'Không phụ thuộc vào nhu cầu nấu ăn chung',
    ),
    'employed': RoommateCriteriaModel(
      id: 'criteria_stable_job',
      label: 'Công việc ổn định',
    ),
    'cook_at_home': RoommateCriteriaModel(
      id: 'criteria_shared_living',
      label: 'Có thể sinh hoạt chung, nấu ăn chung văn minh',
    ),
  };

  static List<String> mapHabitsToRoommateCriteria(List<String> habits) {
    final uniqueLabels = <String>{};
    for (final habit in habits) {
      final criteria = _mapping[habit];
      if (criteria != null) {
        uniqueLabels.add(criteria.label);
      }
    }
    return uniqueLabels.toList();
  }
}
