// lib/services/plant_update_service.dart
import 'dart:async';

class PlantUpdateService {
  // Singleton
  static final PlantUpdateService _instance = PlantUpdateService._internal();
  factory PlantUpdateService() => _instance;
  PlantUpdateService._internal();

  // Stream controller
  final _plantUpdateController = StreamController<void>.broadcast();

  // Stream để listen
  Stream<void> get plantUpdates => _plantUpdateController.stream;

  // Notify có thay đổi
  void notifyPlantUpdated() {
    print('📢 Notifying plant updated');
    _plantUpdateController.add(null);
  }

  void dispose() {
    _plantUpdateController.close();
  }
}
