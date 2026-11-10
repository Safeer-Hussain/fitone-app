import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _database;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'fitone_core.db');

    return await openDatabase(dbPath, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        body_part TEXT NOT NULL,
        equipment TEXT NOT NULL,
        target_muscles TEXT NOT NULL,
        instructions TEXT NOT NULL,
        difficulty TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE workouts (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        total_volume_kg REAL NOT NULL,
        completed_sets INTEGER NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_sets (
        id TEXT PRIMARY KEY,
        workout_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        set_number INTEGER NOT NULL,
        weight_kg REAL NOT NULL,
        reps INTEGER NOT NULL,
        rpe REAL NOT NULL,
        is_completed INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (workout_id) REFERENCES workouts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_plans (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        days_per_week INTEGER NOT NULL,
        schedule_json TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE nutrition_logs (
        id TEXT PRIMARY KEY,
        date_str TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        food_name TEXT NOT NULL,
        calories REAL NOT NULL,
        protein_g REAL NOT NULL,
        carbs_g REAL NOT NULL,
        fat_g REAL NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE hydration_logs (
        id TEXT PRIMARY KEY,
        date_str TEXT NOT NULL,
        amount_ml INTEGER NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE running_routes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        start_time INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL,
        distance_km REAL NOT NULL,
        avg_pace_sec_per_km INTEGER NOT NULL,
        elevation_gain_m REAL NOT NULL,
        calories_burned REAL NOT NULL,
        avg_heart_rate INTEGER NOT NULL,
        coordinates_json TEXT NOT NULL,
        splits_json TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE social_posts (
        id TEXT PRIMARY KEY,
        user_name TEXT NOT NULL,
        user_handle TEXT NOT NULL,
        avatar_initials TEXT NOT NULL,
        post_type TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        metrics_json TEXT NOT NULL,
        likes_count INTEGER NOT NULL,
        is_liked INTEGER NOT NULL,
        comments_json TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    await _seedDatabase(db);
  }

  Future<void> _seedDatabase(Database db) async {
    final batch = db.batch();

    final exercises = _getInitialExercises();
    for (final ex in exercises) {
      batch.insert('exercises', ex);
    }

    final plans = _getInitialWorkoutPlans();
    for (final plan in plans) {
      batch.insert('workout_plans', plan);
    }

    final nutrition = _getInitialNutritionLogs();
    for (final item in nutrition) {
      batch.insert('nutrition_logs', item);
    }

    final hydration = _getInitialHydrationLogs();
    for (final item in hydration) {
      batch.insert('hydration_logs', item);
    }

    final runs = _getInitialRunningRoutes();
    for (final run in runs) {
      batch.insert('running_routes', run);
    }

    final posts = _getInitialSocialPosts();
    for (final post in posts) {
      batch.insert('social_posts', post);
    }

    await batch.commit(noResult: true);
  }

  List<Map<String, dynamic>> _getInitialExercises() {
    return [
      {
        'id': 'ex_01',
        'name': 'Barbell Bench Press',
        'body_part': 'Chest',
        'equipment': 'Barbell',
        'target_muscles':
            'Pectoralis Major, Anterior Deltoids, Triceps Brachii',
        'instructions': 'Lie flat on the bench, grip bar slightly wider than shoulder width. Retract scapula, lower bar with control to lower chest, press upward explosively.',
        'difficulty': 'Intermediate',
      },
      {
        'id': 'ex_02',
        'name': 'Incline Dumbbell Press',
        'body_part': 'Chest',
        'equipment': 'Dumbbells',
        'target_muscles':
            'Clavicular Pectoral Head, Anterior Deltoids, Triceps',
        'instructions': 'Set bench to 30-45 degrees incline. Press dumbbells vertically while maintaining retracted shoulder girdle.',
        'difficulty': 'Intermediate',
      },
      {
        'id': 'ex_03',
        'name': 'Cable Chest Flyes',
        'body_part': 'Chest',
        'equipment': 'Cables',
        'target_muscles': 'Sternal Pectoral Head, Sternal Fibers',
        'instructions': 'Position dual pulleys at chest height. Step forward into staggered stance, bring hands together in wide sweeping arc.',
        'difficulty': 'Beginner',
      },
      {
        'id': 'ex_04',
        'name': 'Weighted Dips',
        'body_part': 'Chest',
        'equipment': 'Bodyweight',
        'target_muscles': 'Lower Pectorals, Anterior Deltoids, Triceps',
        'instructions': 'Lean torso forward at 30 degrees, lower body until upper arms parallel floor, press up through palms.',
        'difficulty': 'Advanced',
      },
      {
        'id': 'ex_05',
        'name': 'Pec Deck Machine',
        'body_part': 'Chest',
        'equipment': 'Gym Machines',
        'target_muscles': 'Pectoralis Major Sternal Head',
        'instructions': 'Adjust seat height so handles align with mid-chest. Contract chest to bring levers together, squeeze peak contraction.',
        'difficulty': 'Beginner',
      },
      {
        'id': 'ex_06',
        'name': 'Push-Ups',
        'body_part': 'Chest',
        'equipment': 'Bodyweight',
        'target_muscles': 'Pectoralis Major, Triceps, Core Stabilizers',
        'instructions': 'High plank position with hands under shoulders. Lower chest to 2cm above floor, drive ground away.',
        'difficulty': 'Beginner',
      },
      {
        'id': 'ex_07',
        'name': 'Decline Barbell Press',
        'body_part': 'Chest',
        'equipment': 'Barbell',
        'target_muscles': 'Costal Pectorals, Triceps',
        'instructions': 'Secure legs on decline bench. Lower barbell to inferolateral sternum, drive upward locking elbows.',
        'difficulty': 'Intermediate',
      },
      {
        'id': 'ex_08',
        'name': 'Kettlebell Floor Press',
        'body_part': 'Chest',
        'equipment': 'Kettlebells',
        'target_muscles': 'Pectoralis Major, Triceps, Forearm Flexors',
        'instructions': 'Lie supine on floor, press kettlebells until elbows lock out, minimizing shoulder hyper-extension.',
        'difficulty': 'Intermediate',
      },
      {
        'id': 'ex_09',
        'name': 'Deadlift (Conventional)',
        'body_part': 'Back',
        'equipment': 'Barbell',
        'target_muscles':
            'Erector Spinae, Latissimus Dorsi, Gluteus Maximus, Hamstrings',
        'instructions': 'Feet hip width under bar. Hinge hips back, brace abdominal wall, pull slack from bar, drive hips through.',
        'difficulty': 'Advanced',
      },
      {
        'id': 'ex_10',
        'name': 'Barbell Bent Over Row',
        'body_part': 'Back',
        'equipment': 'Barbell',
        'target_muscles': 'Latissimus Dorsi, Rhomboids, Trapezius, Biceps',
        'instructions': 'Hinge torso to 45 degrees, pull barbell to lower ribcage while driving elbows upward and back.',
        'difficulty': 'Intermediate',
      },
      {
        'id': 'ex_11',
        'name': 'Wide Grip Pull-Up',
        'body_part': 'Back',
        'equipment': 'Bodyweight',
        'target_muscles': 'Latissimus Dorsi, Teres Major, Biceps Brachii',
        'instructions': 'Hang with pronated grip outside shoulder width. Drive elbows down into back pockets until chin clears bar.',
        'difficulty': 'Intermediate',
      },
      {
        'id': 'ex_12',
        'name': 'Seated Cable Row',
        'body_part': 'Back',
        'equipment': 'Cables',
        'target_muscles': 'Mid Trapezius, Rhomboids, Latissimus Dorsi',
        'instructions': 'Sit upright with feet on plates. Retract shoulder blades and pull V-bar to upper abdomen.',
        'difficulty': 'Beginner',
      },
      {
        'id': 'ex_13',
        'name': 'Lat Pulldown Machine',
        'body_part': 'Back',
        'equipment': 'Gym Machines',
        'target_muscles': 'Latissimus Dorsi, Biceps, Posterior Deltoid',
        'instructions': 'Thighs locked under pads, grab wide bar. Depress scapula and pull bar toward upper sternum.',
        'difficulty': 'Beginner',
      },
      {
        'id': 'ex_14',
        'name': 'Single Arm Dumbbell Row',
        'body_part': 'Back',
        'equipment': 'Dumbbells',
        'target_muscles': 'Latissimus Dorsi, Rhomboids, Posterior Deltoid',
        'instructions': 'Place one knee and hand on flat bench. Pull dumbbell vertically to hip pocket, pause and lower under control.',
        'difficulty': 'Beginner',
      },
      {
        'id': 'ex_15',
        'name': 'Kettlebell Gorilla Row',
        'body_part': 'Back',
        'equipment': 'Kettlebells',
        'target_muscles': 'Upper Back, Rhomboids, Core Anti-Rotation',
        'instructions': 'Hinge with two kettlebells between feet. Row one side while pressing opposite bell firmly into floor.',
        'difficulty': 'Intermediate',
      },
      {
        'id': 'ex_16',
        'name': 'Barbell Back Squat',
        'body_part': 'Legs',
        'equipment': 'Barbell',
        'target_muscles':
            'Quadriceps, Gluteus Maximus, Adductor Magnus, Soleus',
        'instructions': 'Bar resting on mid-trapezius shelf. Descend below parallel keeping knees tracking over second toes, drive upward through mid-foot.',
        'difficulty': 'Advanced',
      },
      {
        'id': 'ex_17',
        'name': 'Romanian Deadlift',
        'body_part': 'Legs',
        'equipment': 'Barbell',
        'target_muscles': 'Hamstrings, Gluteus Maximus, Erector Spinae',
        'instructions': 'Hold bar at hips with soft knee bend. Push hips posterior until deep hamstring stretch, drive hips forward.',
        'difficulty': 'Intermediate',
      },
      {
        'id': 'ex_18',
        'name': 'Leg Press Machine',
        'body_part': 'Legs',
        'equipment': 'Gym Machines',
        'target_muscles': 'Quadriceps, Glutes',
        'instructions': 'Feet shoulder width on sled. Release safety handles, lower sled to 90 degrees knee angle, press platform away.',
        'difficulty': 'Beginner',
      },
      {
        'id': 'ex_19',
        'name': 'Bulgarian Split Squat',
        'body_part': 'Legs',
        'equipment': 'Dumbbells',
        'target_muscles': 'Quadriceps, Gluteus Medius, Hamstrings',
        'instructions': 'Rear foot elevated on bench. Lower hips vertically until front thigh parallel to floor, drive up through front heel.',
        'difficulty': 'Intermediate',
      },
      {
        'id': 'ex_20',
        'name': 'Kettlebell Goblet Squat',
        'body_part': 'Legs',
        'equipment': 'Kettlebells',
        'target_muscles': 'Quadriceps, Core Stabilizers',
        'instructions': 'Hold kettlebell at chest by the horns. Squat deep between hips with elbows inside knees.',
        'difficulty': 'Beginner',
      },
      {
        'id': 'ex_21',
        'name': 'Leg Extension Machine',
        'body_part': 'Legs',
        'equipment': 'Gym Machines',
        'target_muscles': 'Rectus Femoris, Vastus Lateralis/Medialis',
        'instructions': 'Sit with pad against lower shins. Extend knees fully, hold peak contraction for 1 second, lower smoothly.',
        'difficulty': 'Beginner',
      },
      {
        'id': 'ex_22',
        'name': 'Seated Leg Curl Machine',
        'body_part': 'Legs',
        'equipment': 'Gym Machines',
        'target_muscles': 'Biceps Femoris, Semitendinosus, Semimembranosus',
        'instructions': 'Thigh pad secure, heel pad behind Achilles tendon. Flex knees curling pad downward behind calves.',
        'difficulty': 'Beginner',
      },
      {
        'id': 'ex_23',
        'name': 'Standing Calf Raise',
        'body_part': 'Legs',
        'equipment': 'Gym Machines',
        'target_muscles': 'Gastrocnemius, Soleus',
        'instructions': 'Shoulder pads resting, balls of feet on edge. Lower heels for maximal dorsiflexion, plantarflex onto big toes.',
        'difficulty': 'Beginner',
      },
      {
        'id': 'ex_24',
        'name': 'Pistol Squat',
        'body_part': 'Legs',
        'equipment': 'Bodyweight',
        'target_muscles': 'Quadriceps, Glutes, Ankle Mobility',
        'instructions': 'Single leg balance with opposite leg extended forward. Descend until hamstring contacts calf, rise under control.',
        'difficulty': 'Advanced',
      },
      {
        'id': 'ex_25',
        'name': 'Overhead Barbell Press',
        'body_part': 'Shoulders',
        'equipment': 'Barbell',
        'target_muscles':
            'Anterior Deltoids, Lateral Deltoids, Triceps, Serratus Anterior',
        'instructions': 'Bar at collarbone height. Squeeze glutes and core, press barbell vertically overhead clearing face.',
        'difficulty': 'Intermediate',
      },
      {
        'id': 'ex_26',
        'name': 'Dumbbell Lateral Raise',
        'body_part': 'Shoulders',
        'equipment': 'Dumbbells',
        'target_muscles': 'Lateral Deltoids',
        'instructions': 'Slight forward lean with dumbbells at sides. Raise arms in scapular plane until parallel to floor, lead with elbows.',
        'difficulty': 'Beginner',
      },
      {
        'id': 'ex_27',
        'name': 'Face Pulls',
        'body_part': 'Shoulders',
        'equipment': 'Cables',
        'target_muscles': 'Posterior Deltoids, Infraspinatus, Rhomboids',
        'instructions': 'Rope attachment at eye level. Pull rope toward forehead while externally rotating forearms backwards.',
        'difficulty': 'Beginner',
      },
      {
        'id': 'ex_28',
        'name': 'Arnold Press',
        'body_part': 'Shoulders',
        'equipment': 'Dumbbells',
        'target_muscles': 'Anterior and Lateral Deltoids',
        'instructions': 'Start with palms facing chest. Rotate wrists outward while pressing dumbbells overhead in continuous motion.',
        'difficulty': 'Intermediate',
      },
      {
        'id': 'ex_29',
        'name': 'Shoulder Press Machine',
        'body_part': 'Shoulders',
        'equipment': 'Gym Machines',
        'target_muscles': 'Anterior Deltoids, Triceps',
        'instructions': 'Grip neutral or pronated handles at ear level. Press upward to full extension without locking elbows violently.',
        'difficulty': 'Beginner',
      },
      {
        'id': 'ex_30',
        'name': 'Kettlebell Clean and Press',
        'body_part': 'Shoulders',
        'equipment': 'Kettlebells',
        'target_muscles': 'Full Deltoid Complex, Trapezius, Core',
        'instructions': 'Swing kettlebell from floor into rack position at chest, press upward explosively overhead.',
        'difficulty': 'Advanced',
      },
      {
        'id': 'ex_31',
        'name': 'Barbell Bicep Curl',
        'body_part': 'Arms',
        'equipment': 'Barbell',
        'target_muscles': 'Biceps Brachii, Brachialis',
        'instructions': 'Shoulder width supinated grip. Keep elbows pinned to sides, curl barbell up to upper chest, lower under tension.',
        'difficulty': 'Beginner',
      },
      {
        'id': 'ex_32',
        'name': 'Incline Dumbbell Curl',
        'body_part': 'Arms',
        'equipment': 'Dumbbells',
        'target_muscles': 'Biceps Long Head',
        'instructions': 'Bench at 60 degree incline. Allow arms to hang vertically behind torso for maximal long head stretch, curl forward.',
        'difficulty': 'Intermediate',
      },
      {
        'id': 'ex_33',
        'name': 'Triceps Rope Pushdown',
        'body_part': 'Arms',
        'equipment': 'Cables',
        'target_muscles': 'Triceps Lateral and Medial Heads',
        'instructions': 'Elbows pinned to ribcage. Push rope down, flaring ends outward at bottom for peak triceps contraction.',
        'difficulty': 'Beginner',
      },
      {
        'id': 'ex_34',
        'name': 'Skull Crushers (Lying Triceps Extension)',
        'body_part': 'Arms',
        'equipment': 'Barbell',
        'target_muscles': 'Triceps Long Head',
        'instructions': 'Lying on bench with EZ curl bar. Lower bar behind crown of head by flexing elbows, extend back upward.',
        'difficulty': 'Intermediate',
      },
      {
        'id': 'ex_35',
        'name': 'Preacher Curl Machine',
        'body_part': 'Arms',
        'equipment': 'Gym Machines',
        'target_muscles': 'Brachialis, Biceps Short Head',
        'instructions': 'Armpits nestled against slanted preacher pad. Curl lever toward chin, preventing shoulder movement.',
        'difficulty': 'Beginner',
      },
      {
        'id': 'ex_36',
        'name': 'Diamond Push-Up',
        'body_part': 'Arms',
        'equipment': 'Bodyweight',
        'target_muscles': 'Triceps Brachii, Inner Chest',
        'instructions': 'Hands forming diamond index and thumb shape under sternum. Lower chest to hands, press back up.',
        'difficulty': 'Intermediate',
      },
      {
        'id': 'ex_37',
        'name': 'Hammer Curls',
        'body_part': 'Arms',
        'equipment': 'Dumbbells',
        'target_muscles': 'Brachioradialis, Brachialis',
        'instructions': 'Neutral grip with thumbs pointing upward. Curl weights alternately or simultaneously without torso swing.',
        'difficulty': 'Beginner',
      },
      {
        'id': 'ex_38',
        'name': 'Overhead Cable Triceps Extension',
        'body_part': 'Arms',
        'equipment': 'Cables',
        'target_muscles': 'Triceps Long Head',
        'instructions': 'Rope high pulley, face away from stack in staggered stance. Extend arms forward and upward.',
        'difficulty': 'Intermediate',
      },
      {
        'id': 'ex_39',
        'name': 'Hanging Leg Raise',
        'body_part': 'Core',
        'equipment': 'Bodyweight',
        'target_muscles': 'Rectus Abdominis, Iliopsoas',
        'instructions': 'Hang from pull-up bar. Posterior pelvic tilt, raise straight legs until parallel to floor or toes touch bar.',
        'difficulty': 'Advanced',
      },
      {
        'id': 'ex_40',
        'name': 'Cable Woodchopper',
        'body_part': 'Core',
        'equipment': 'Cables',
        'target_muscles': 'Internal & External Obliques, Transverse Abdominis',
        'instructions': 'High pulley grip with both hands. Rotate torso diagonally down across body to opposite hip.',
        'difficulty': 'Intermediate',
      },
      {
        'id': 'ex_41',
        'name': 'Ab Roller Wheel',
        'body_part': 'Core',
        'equipment': 'Bodyweight',
        'target_muscles': 'Rectus Abdominis, Core Anti-Extension',
        'instructions': 'Kneel on mat holding roller handles. Roll forward extending hips and arms, pull back using core contraction.',
        'difficulty': 'Advanced',
      },
      {
        'id': 'ex_42',
        'name': 'Kettlebell Russian Twist',
        'body_part': 'Core',
        'equipment': 'Kettlebells',
        'target_muscles': 'Obliques, Rectus Abdominis',
        'instructions': 'V-sit position with heels hovering above floor. Rotate kettlebell from side to side tapping ground lightly.',
        'difficulty': 'Intermediate',
      },
      {
        'id': 'ex_43',
        'name': 'Plank Hold',
        'body_part': 'Core',
        'equipment': 'Bodyweight',
        'target_muscles': 'Transverse Abdominis, Glutes, Shoulders',
        'instructions': 'Forearms on floor under shoulders. Maintain neutral spine with active posterior pelvic tilt and glute squeeze.',
        'difficulty': 'Beginner',
      },
      {
        'id': 'ex_44',
        'name': 'Abdominal Crunch Machine',
        'body_part': 'Core',
        'equipment': 'Gym Machines',
        'target_muscles': 'Upper Rectus Abdominis',
        'instructions': 'Seat positioned so pivot point aligns with lower ribs. Contract abdomen rolling ribs towards pelvis.',
        'difficulty': 'Beginner',
      },
      {
        'id': 'ex_45',
        'name': 'Kettlebell Turkish Get-Up',
        'body_part': 'Full Body',
        'equipment': 'Kettlebells',
        'target_muscles': 'Shoulder Stability, Core, Glutes, Hip Hinge',
        'instructions': 'Sequential roll from floor to standing while balancing kettlebell locked out overhead continuously.',
        'difficulty': 'Advanced',
      },
      {
        'id': 'ex_46',
        'name': 'Barbell Clean and Jerk',
        'body_part': 'Full Body',
        'equipment': 'Barbell',
        'target_muscles': 'Posterior Chain, Traps, Quads, Deltoids',
        'instructions': 'Explosive triple extension from floor to shoulders, split jerk barbell locked out overhead.',
        'difficulty': 'Advanced',
      },
      {
        'id': 'ex_47',
        'name': 'Kettlebell Swing',
        'body_part': 'Full Body',
        'equipment': 'Kettlebells',
        'target_muscles': 'Glutes, Hamstrings, Core, Latissimus Dorsi',
        'instructions': 'Dynamic hip hinge projection. Snap hips forward to float kettlebell to chest level, absorb on backswing.',
        'difficulty': 'Intermediate',
      },
      {
        'id': 'ex_48',
        'name': 'Burpees',
        'body_part': 'Full Body',
        'equipment': 'Bodyweight',
        'target_muscles': 'Cardiovascular, Pectorals, Quads, Deltoids',
        'instructions': 'Drop into squat, kick feet back to plank, perform push-up, jump feet in, explode upward with overhead reach.',
        'difficulty': 'Intermediate',
      },
      {
        'id': 'ex_49',
        'name': 'Barbell Snatch',
        'body_part': 'Full Body',
        'equipment': 'Barbell',
        'target_muscles': 'Traps, Posterior Chain, Deltoids, Core',
        'instructions': 'Wide grip single continuous explosive pull from floor directly into full overhead squat reception.',
        'difficulty': 'Advanced',
      },
      {
        'id': 'ex_50',
        'name': 'Farmer Walk',
        'body_part': 'Full Body',
        'equipment': 'Dumbbells',
        'target_muscles': 'Forearms, Trapezius, Core Anti-Lateral Flexion',
        'instructions': 'Pick up heavy dumbbells from floor. Walk upright with short purposeful steps for prescribed distance.',
        'difficulty': 'Beginner',
      },
      {
        'id': 'ex_51',
        'name': 'Battle Ropes Wave',
        'body_part': 'Full Body',
        'equipment': 'Gym Machines',
        'target_muscles': 'Shoulders, Core, Forearms, Cardiovascular',
        'instructions': 'Athletic quarter-squat stance. Alternate rhythmic vertical whipping waves of ropes into floor.',
        'difficulty': 'Beginner',
      },
      {
        'id': 'ex_52',
        'name': 'Sled Push (Prowler)',
        'body_part': 'Full Body',
        'equipment': 'Gym Machines',
        'target_muscles': 'Quads, Calves, Glutes, Core',
        'instructions': 'Hands low on sled handles, lean body at 45 degrees, drive balls of feet down with piston leg motion.',
        'difficulty': 'Intermediate',
      },
      {
        'id': 'ex_53',
        'name': 'Dumbbell Renegade Row',
        'body_part': 'Full Body',
        'equipment': 'Dumbbells',
        'target_muscles': 'Core, Latissimus Dorsi, Posterior Deltoid',
        'instructions': 'High plank position gripping hex dumbbells on floor. Row one dumbbell to hip while resisting hip twist.',
        'difficulty': 'Advanced',
      },
      {
        'id': 'ex_54',
        'name': 'Assault Air Bike Sprint',
        'body_part': 'Full Body',
        'equipment': 'Gym Machines',
        'target_muscles': 'Full Body Anaerobic Lactic System',
        'instructions': 'Maximal exertion push-pull handle cycling coupled with leg pedaling for high intensity intervals.',
        'difficulty': 'Intermediate',
      },
      {
        'id': 'ex_55',
        'name': 'Outdoor Hill Sprint',
        'body_part': 'Full Body',
        'equipment': 'Bodyweight',
        'target_muscles': 'Posterior Chain, Quadriceps, Ankle Stiffness',
        'instructions': 'Sprint uphill at 100% effort with forward torso lean and high knee drive. Walk down to recover.',
        'difficulty': 'Advanced',
      },
      {
        'id': 'ex_56',
        'name': 'Cable Pallof Press',
        'body_part': 'Core',
        'equipment': 'Cables',
        'target_muscles': 'Core Anti-Rotation, Obliques',
        'instructions': 'Hold cable handle at sternum with sideways stance. Press handle forward resisting rotational pull.',
        'difficulty': 'Beginner',
      },
      {
        'id': 'ex_57',
        'name': 'Barbell Hip Thrust',
        'body_part': 'Legs',
        'equipment': 'Barbell',
        'target_muscles': 'Gluteus Maximus, Hamstrings',
        'instructions': 'Upper back against flat bench, padded barbell across hip crease. Drive hips to full lockout squeeze.',
        'difficulty': 'Intermediate',
      },
      {
        'id': 'ex_58',
        'name': 'Seated Calf Extension',
        'body_part': 'Legs',
        'equipment': 'Gym Machines',
        'target_muscles': 'Soleus',
        'instructions': 'Knees flexed at 90 degrees with thigh pad. Plantarflex ankles targeting deep slow-twitch soleus.',
        'difficulty': 'Beginner',
      },
      {
        'id': 'ex_59',
        'name': 'Cable Rope Hammer Curl',
        'body_part': 'Arms',
        'equipment': 'Cables',
        'target_muscles': 'Brachioradialis, Biceps Brachii',
        'instructions': 'Low pulley rope attachment. Neutral grip hammer curl upward keeping constant mechanical tension.',
        'difficulty': 'Beginner',
      },
      {
        'id': 'ex_60',
        'name': 'Dumbbell Front Squat',
        'body_part': 'Legs',
        'equipment': 'Dumbbells',
        'target_muscles': 'Quadriceps, Thoracic Extensors, Core',
        'instructions': 'Dumbbells rested vertically on anterior deltoid heads. Squat deep maintaining upright torso.',
        'difficulty': 'Intermediate',
      },
    ];
  }

  List<Map<String, dynamic>> _getInitialWorkoutPlans() {
    return [
      {
        'id': 'plan_ppl',
        'title': 'Push Pull Legs Hypertrophy',
        'description': '6-day high-frequency split optimizing progressive overload and muscle hypertrophy across primary compound patterns.',
        'days_per_week': 6,
        'schedule_json': jsonEncode([
          {'day': 'Monday', 'focus': 'Push Hypertrophy', 'exerciseCount': 6},
          {'day': 'Tuesday', 'focus': 'Pull Hypertrophy', 'exerciseCount': 6},
          {'day': 'Wednesday', 'focus': 'Legs & Calves', 'exerciseCount': 6},
          {'day': 'Thursday', 'focus': 'Push Strength', 'exerciseCount': 5},
          {'day': 'Friday', 'focus': 'Pull Strength', 'exerciseCount': 5},
          {'day': 'Saturday', 'focus': 'Legs Strength', 'exerciseCount': 5},
          {'day': 'Sunday', 'focus': 'Active Recovery', 'exerciseCount': 0},
        ]),
      },
      {
        'id': 'plan_upper_lower',
        'title': 'Upper Lower Athletic Performance',
        'description': '4-day split balancing barbell strength development with cardiovascular engine output and ring biometric recovery.',
        'days_per_week': 4,
        'schedule_json': jsonEncode([
          {'day': 'Monday', 'focus': 'Upper Body Power', 'exerciseCount': 5},
          {
            'day': 'Tuesday',
            'focus': 'Lower Body Strength',
            'exerciseCount': 5,
          },
          {
            'day': 'Wednesday',
            'focus': 'Cardio & Mobility',
            'exerciseCount': 0,
          },
          {
            'day': 'Thursday',
            'focus': 'Upper Body Hypertrophy',
            'exerciseCount': 6,
          },
          {'day': 'Friday', 'focus': 'Lower Body Volume', 'exerciseCount': 6},
          {'day': 'Saturday', 'focus': 'Zone 2 Running', 'exerciseCount': 0},
          {'day': 'Sunday', 'focus': 'Rest & Recovery', 'exerciseCount': 0},
        ]),
      },
    ];
  }

  List<Map<String, dynamic>> _getInitialNutritionLogs() {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return [
      {
        'id': 'nut_01',
        'date_str': todayStr,
        'meal_type': 'Breakfast',
        'food_name': 'Steel Cut Oats with Whey Protein and Blueberries',
        'calories': 480.0,
        'protein_g': 42.0,
        'carbs_g': 62.0,
        'fat_g': 8.0,
        'timestamp': now
            .subtract(const Duration(hours: 6))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'nut_02',
        'date_str': todayStr,
        'meal_type': 'Lunch',
        'food_name': 'Grilled Chicken Breast, Quinoa and Steamed Asparagus',
        'calories': 620.0,
        'protein_g': 58.0,
        'carbs_g': 54.0,
        'fat_g': 14.0,
        'timestamp': now
            .subtract(const Duration(hours: 3))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'nut_03',
        'date_str': todayStr,
        'meal_type': 'Snacks',
        'food_name': 'Greek Yogurt 0% with Almonds and Honey',
        'calories': 290.0,
        'protein_g': 24.0,
        'carbs_g': 22.0,
        'fat_g': 11.0,
        'timestamp': now
            .subtract(const Duration(hours: 1))
            .millisecondsSinceEpoch,
      },
    ];
  }

  List<Map<String, dynamic>> _getInitialHydrationLogs() {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return [
      {
        'id': 'hyd_01',
        'date_str': todayStr,
        'amount_ml': 500,
        'timestamp': now
            .subtract(const Duration(hours: 8))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'hyd_02',
        'date_str': todayStr,
        'amount_ml': 500,
        'timestamp': now
            .subtract(const Duration(hours: 5))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'hyd_03',
        'date_str': todayStr,
        'amount_ml': 750,
        'timestamp': now
            .subtract(const Duration(hours: 2))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'hyd_04',
        'date_str': todayStr,
        'amount_ml': 250,
        'timestamp': now
            .subtract(const Duration(minutes: 30))
            .millisecondsSinceEpoch,
      },
    ];
  }

  List<Map<String, dynamic>> _getInitialRunningRoutes() {
    final now = DateTime.now();

    final lahoreCoordinates = [
      {'lat': 31.5204, 'lng': 74.3587},
      {'lat': 31.5220, 'lng': 74.3601},
      {'lat': 31.5245, 'lng': 74.3620},
      {'lat': 31.5270, 'lng': 74.3645},
      {'lat': 31.5295, 'lng': 74.3670},
      {'lat': 31.5320, 'lng': 74.3695},
      {'lat': 31.5345, 'lng': 74.3720},
      {'lat': 31.5360, 'lng': 74.3745},
      {'lat': 31.5340, 'lng': 74.3770},
      {'lat': 31.5315, 'lng': 74.3795},
      {'lat': 31.5285, 'lng': 74.3810},
      {'lat': 31.5255, 'lng': 74.3780},
      {'lat': 31.5225, 'lng': 74.3740},
      {'lat': 31.5204, 'lng': 74.3587},
    ];

    final splits = [
      {'km': 1, 'paceSec': 312, 'elevationDelta': 4.5, 'avgHeartRate': 148},
      {'km': 2, 'paceSec': 298, 'elevationDelta': 3.2, 'avgHeartRate': 154},
      {'km': 3, 'paceSec': 304, 'elevationDelta': -1.2, 'avgHeartRate': 157},
      {'km': 4, 'paceSec': 292, 'elevationDelta': 2.0, 'avgHeartRate': 162},
      {'km': 5, 'paceSec': 285, 'elevationDelta': 5.8, 'avgHeartRate': 168},
    ];

    return [
      {
        'id': 'run_lahore_liberty',
        'title': 'Liberty Roundabout to Gulberg Linear Tempo',
        'start_time': now
            .subtract(const Duration(days: 1, hours: 2))
            .millisecondsSinceEpoch,
        'duration_seconds': 1491,
        'distance_km': 5.0,
        'avg_pace_sec_per_km': 298,
        'elevation_gain_m': 28.5,
        'calories_burned': 415.0,
        'avg_heart_rate': 158,
        'coordinates_json': jsonEncode(lahoreCoordinates),
        'splits_json': jsonEncode(splits),
      },
    ];
  }

  List<Map<String, dynamic>> _getInitialSocialPosts() {
    final now = DateTime.now();

    return [
      {
        'id': 'post_01',
        'user_name': 'Safeer Hussain',
        'user_handle': '@safeer_h',
        'avatar_initials': 'SH',
        'post_type': 'WORKOUT_MILESTONE',
        'title': 'New 1RM PR: Barbell Bench Press at 135 kg',
        'description': 'AuraRing Readiness was 91 this morning. Hit 135kg x 1 rep at RPE 9.5 followed by 4x4 backoff sets at 112.5kg.',
        'metrics_json': jsonEncode({
          'volumeKg': 4280,
          'sets': 18,
          'recoveryScore': 91,
        }),
        'likes_count': 42,
        'is_liked': 1,
        'comments_json': jsonEncode([
          {
            'author': 'Marcus Vance',
            'text':
                'Clean lockout velocity. What program cycle are you running?',
          },
          {
            'author': 'Elena Rostova',
            'text': 'Outstanding recovery numbers. My ring had me at 74 today.',
          },
        ]),
        'timestamp': now
            .subtract(const Duration(hours: 4))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'post_02',
        'user_name': 'Zainab Tariq',
        'user_handle': '@zainab_runs',
        'avatar_initials': 'ZT',
        'post_type': 'RUN_ROUTE',
        'title': 'Sunrise 10K Tempo - Model Town Park Loop',
        'description': 'Maintained Zone 3 aerobic threshold at 4:48 min/km pace. Telemetry stream stayed rock solid with zero GPS dropouts.',
        'metrics_json': jsonEncode({
          'distanceKm': 10.2,
          'pace': '4:48/km',
          'avgBpm': 156,
        }),
        'likes_count': 78,
        'is_liked': 0,
        'comments_json': jsonEncode([
          {
            'author': 'Safeer Hussain',
            'text': 'Consistent cadence throughout the middle splits!',
          },
        ]),
        'timestamp': now
            .subtract(const Duration(hours: 7))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'post_03',
        'user_name': 'Liam O Connor',
        'user_handle': '@liam_athletics',
        'avatar_initials': 'LO',
        'post_type': 'RECOVERY_BENCHMARK',
        'title': '94 Sleep Score: 2h 14m Deep Sleep Registered',
        'description': 'KinetixRing Ultra tracked a skin temperature drop of -0.3C and average resting HR of 47 BPM during slow-wave sleep.',
        'metrics_json': jsonEncode({
          'sleepScore': 94,
          'hrvMs': 76,
          'restingHr': 47,
        }),
        'likes_count': 56,
        'is_liked': 0,
        'comments_json': jsonEncode([]),
        'timestamp': now
            .subtract(const Duration(hours: 12))
            .millisecondsSinceEpoch,
      },
    ];
  }
}
