import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../network/mock_api_interceptor.dart';
import '../theme/theme_store.dart';
import '../../data/datasources/native_ring_channel_data_source.dart';
import '../../data/repositories/ring_repository_impl.dart';
import '../../data/repositories/workout_repository_impl.dart';
import '../../data/repositories/nutrition_repository_impl.dart';
import '../../data/repositories/running_repository_impl.dart';
import '../../data/repositories/ai_coach_repository_impl.dart';
import '../../data/repositories/social_repository_impl.dart';
import '../../domain/repositories/ring_repository.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../domain/repositories/nutrition_repository.dart';
import '../../domain/repositories/running_repository.dart';
import '../../domain/repositories/ai_coach_repository.dart';
import '../../domain/repositories/social_repository.dart';
import '../../presentation/dashboard/stores/dashboard_store.dart';
import '../../presentation/exercise_workout/stores/exercise_store.dart';
import '../../presentation/exercise_workout/stores/workout_logger_store.dart';
import '../../presentation/nutrition/stores/fasting_store.dart';
import '../../presentation/nutrition/stores/nutrition_store.dart';
import '../../presentation/gps_running/stores/gps_running_store.dart';
import '../../presentation/ai_coach/stores/ai_coach_store.dart';
import '../../presentation/social_feed/stores/social_store.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // Network
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  dio.interceptors.add(MockApiInterceptor());
  sl.registerSingleton<Dio>(dio);

  // Data Sources
  sl.registerLazySingleton<NativeRingChannelDataSource>(
    () => NativeRingChannelDataSource(),
  );

  // Repositories
  sl.registerLazySingleton<RingRepository>(
    () => RingRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<WorkoutRepository>(
    () => WorkoutRepositoryImpl(dio: sl()),
  );
  sl.registerLazySingleton<NutritionRepository>(
    () => NutritionRepositoryImpl(dio: sl()),
  );
  sl.registerLazySingleton<RunningRepository>(
    () => RunningRepositoryImpl(dio: sl()),
  );
  sl.registerLazySingleton<AiCoachRepository>(
    () => AiCoachRepositoryImpl(ringRepository: sl()),
  );
  sl.registerLazySingleton<SocialRepository>(
    () => SocialRepositoryImpl(dio: sl()),
  );

  // Stores
  sl.registerLazySingleton<ThemeStore>(() => ThemeStore());
  sl.registerLazySingleton<DashboardStore>(
    () => DashboardStore(ringRepository: sl()),
  );
  sl.registerLazySingleton<ExerciseStore>(
    () => ExerciseStore(workoutRepository: sl()),
  );
  sl.registerLazySingleton<WorkoutLoggerStore>(
    () => WorkoutLoggerStore(workoutRepository: sl()),
  );
  sl.registerLazySingleton<NutritionStore>(
    () => NutritionStore(nutritionRepository: sl()),
  );
  sl.registerLazySingleton<FastingStore>(() => FastingStore());
  sl.registerLazySingleton<GpsRunningStore>(
    () => GpsRunningStore(runningRepository: sl(), ringRepository: sl()),
  );
  sl.registerLazySingleton<AiCoachStore>(
    () => AiCoachStore(aiCoachRepository: sl()),
  );
  sl.registerLazySingleton<SocialStore>(
    () => SocialStore(socialRepository: sl()),
  );
}
