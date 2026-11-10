# Fitone Autonomous Engineering Backlog

This document maintains 25 high-value engineering upgrades for the Fitone mobile ecosystem. Whenever the autonomous sprint engine is triggered with `"run daily sprint"`, the engine reads this file, picks the next pending `[ ]` task, implements the full functional feature end-to-end, writes unit tests, verifies that `flutter analyze` and `flutter test` pass with zero warnings, marks the task `[x]`, and performs a conventional git commit and push.

---

### Sprint Backlog Items

- [x] **Sprint 01: Barbell Plate Loading Calculator**
  - Implement a visual Olympic barbell plate loading calculator (45lb / 20kg bar + 25kg, 20kg, 15kg, 10kg, 5kg, 2.5kg, 1.25kg plates) that calculates exact plate configurations per side for any target weight. Add unit tests for odd and standard loads.

- [x] **Sprint 02: GPX Route Exporter**
  - Add standard GPX 1.1 XML generation for completed GPS running routes stored in SQLite, allowing runners to export route coordinates, timestamps, and elevation points to file storage or share intent.

- [x] **Sprint 03: Intermittent Fasting Window Tracker**
  - Add a dedicated fasting tracker (16:8, 18:6, 20:4, Circadian) with live countdown progress ring, elapsed fasting hours, ketone production phase markers, and local notifications.

- [ ] **Sprint 04: CSV Biometric Telemetry Exporter**
  - Add one-tap export of historical smart-ring telemetry packets (Heart Rate, SpO2, HRV, Skin Temp, Sleep Stages) into standard CSV format for sports scientist analysis.

- [ ] **Sprint 05: Custom Superset & Drop Set Builder**
  - Extend the workout logger to support linking two exercises into an antagonist superset or multi-stage drop set with automated back-to-back timer tracking.

- [ ] **Sprint 06: Wilks & DOTS Powerlifting Score Calculator**
  - Implement standard Wilks-2 and DOTS powerlifting coefficient calculators using bodyweight, gender, and total compound volume (Squat + Bench + Deadlift).

- [ ] **Sprint 07: Audio Cadence Metronome for Running**
  - Add a rhythmic audio and visual metronome (160 to 190 SPM) inside the GPS run tracker to guide optimal running cadence and reduce ground contact impact time.

- [ ] **Sprint 08: Water Intake Goal Auto-Adjustment Engine**
  - Dynamically calculate and adjust the daily water target based on running distance logged today (+350ml per 5km) and wearable ambient skin temperature delta.

- [ ] **Sprint 09: Barbell Warmup Set Auto-Calculator**
  - Given a target working weight and rep goal, automatically generate standard ramp-up warmup sets (Empty bar x 10, 40% x 5, 60% x 3, 75% x 2, 85% x 1) with plate breakdowns.

- [ ] **Sprint 10: Biometric Sleep Debt Calculator**
  - Compute cumulative 14-day sleep debt by comparing nightly sleep hours against the athlete's 8-hour baseline, projecting cognitive and muscular recovery impact.

- [ ] **Sprint 11: Micronutrient Tracker (Electrolytes & Fiber)**
  - Expand the daily nutrition summary to track Sodium, Potassium, Magnesium, and Dietary Fiber intake with threshold warnings for endurance runners.

- [ ] **Sprint 12: Lactate Threshold Heart Rate (LTHR) Zone Modeler**
  - Add automatic calculation of 5-zone Coggan and Friel heart rate training zones derived from a 20-minute functional threshold test or 10K running pace.

- [ ] **Sprint 13: Exercise Replacement Recommender**
  - In the exercise encyclopedia, provide one-tap alternative exercise suggestions matching identical primary muscle recruitment patterns (e.g. Barbell Squat -> Bulgarian Split Squat or Leg Press).

- [ ] **Sprint 14: PDF Weekly Athlete Digest Generator**
  - Generate a formatted PDF report summarizing 7-day workout volume tonnage, running distance splits, average HRV, sleep efficiency, and macro compliance.

- [ ] **Sprint 15: Voice Memo Audio Logger for Set Notes**
  - Allow athletes to record a brief voice memo on individual workout sets to capture subjective biomechanical feedback, stored locally with playback controls.

- [ ] **Sprint 16: Weekly Muscle Volume Landmark Audit (MEV/MRV)**
  - Track weekly direct sets per muscle group against Dr. Mike Israetel's Volume Landmarks (Maintenance Volume, Minimum Effective Volume, Maximum Recoverable Volume).

- [ ] **Sprint 17: Strava / Garmin GPX Route Importer**
  - Allow importing external `.gpx` running track files into the local SQLite database to replay route waypoints and elevation profiles on the map engine.

- [ ] **Sprint 18: Anthropometric Body Measurement Logger**
  - Implement a tracking module for bodyweight, waist circumference, chest, arms, and thighs with rolling 30-day moving average trendlines.

- [ ] **Sprint 19: Pre-Workout Readiness Questionnaire**
  - Implement a 5-point subjective assessment (Muscle Soreness, Mental Stress, Motivation, Energy Level) that weights the smart-ring readiness score.

- [ ] **Sprint 20: Meal Prep Ingredient Batch Yield Multiplier**
  - Build a meal prep calculator that scales raw ingredient weights by serving counts (e.g., 5 days of lunches) while preserving exact macronutrient targets.

- [ ] **Sprint 21: Running Footwear Mileage Retirement Tracker**
  - Track cumulative kilometers logged on specific running shoe models with replacement warnings when mileage exceeds 650km.

- [ ] **Sprint 22: Offline Mutation Queue Sync Worker**
  - Implement an exponential backoff synchronization worker that replays queued SQLite mutations once network connectivity is restored.

- [ ] **Sprint 23: Smart-Ring Battery Discharge Forecaster**
  - Analyze ring battery telemetry draw over 48 hours to forecast the exact hour the ring will deplete charge based on active telemetry sampling frequency.

- [ ] **Sprint 24: Deload Week Automated Planner**
  - After 4 to 6 weeks of consecutive high volume training, automatically propose a 50% volume and 85% intensity deload week template in SQLite.

- [ ] **Sprint 25: Native Apple Health & Google Health Connect Synchronization Engine**
  - Implement bidirectional synchronization with native platform health repositories for background step counts and resting heart rate data.
