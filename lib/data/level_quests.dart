import '../game/airport_game.dart';

/// Тип задания. Каждый case проверяется по данным, которые
/// AirportGame и так уже считает - hadMistake/usedHint/isPerfectRun
/// (Perfect Run), сравнение с level.parMoves/parSeconds (ScoringSystem)
/// и firstArrivedPlaneId (см. _updateRun). Новой проверочной логики
/// в движке не появилось - только чтение уже существующих флагов.
enum LevelQuestKind { noMistakes, underPar, noHint, perfectRun, firstPlane }

class LevelQuest {
  const LevelQuest({
    required this.kind,
    required this.titleKey,
    required this.reward,
    this.targetPlaneId,
  });

  final LevelQuestKind kind;
  final String titleKey;
  final int reward;

  /// Только для firstPlane: id борта, который должен прилететь первым.
  final int? targetPlaneId;

  /// true - выполнено, false - провалено, null - ещё не ясно (уровень
  /// не завершён). Вызывается один раз в момент победы, не каждый кадр.
  bool check(AirportGame game) {
    switch (kind) {
      case LevelQuestKind.noMistakes:
        return !game.hadMistake;
      case LevelQuestKind.noHint:
        return !game.usedHint;
      case LevelQuestKind.perfectRun:
        return game.isPerfectRun;
      case LevelQuestKind.underPar:
        return game.routes.moves <= game.level.parMoves &&
            game.elapsedSeconds <= game.level.parSeconds;
      case LevelQuestKind.firstPlane:
        return game.firstArrivedPlaneId == targetPlaneId;
    }
  }
}

class LevelQuests {
  const LevelQuests._();

  /// Награда растёт вместе со сложностью самого задания и уровня -
  /// умеренно, чтобы не спорить с основной экономикой звёзд и монет.
  static LevelQuest forLevel(int id, {required int planeCount}) {
    final int baseReward = 20 + (id ~/ 10) * 5;
    final int step = (id * 5 + id ~/ 7) % 5;

    switch (step) {
      case 0:
        return LevelQuest(
          kind: LevelQuestKind.noMistakes,
          titleKey: 'quest_no_mistakes',
          reward: baseReward,
        );
      case 1:
        return LevelQuest(
          kind: LevelQuestKind.underPar,
          titleKey: 'quest_under_par',
          reward: baseReward + 10,
        );
      case 2:
        return LevelQuest(
          kind: LevelQuestKind.noHint,
          titleKey: 'quest_no_hint',
          reward: baseReward,
        );
      case 3:
        // На один борт - задание неприменимо, пропускаем на noMistakes.
        if (planeCount < 2) {
          return LevelQuest(
            kind: LevelQuestKind.noMistakes,
            titleKey: 'quest_no_mistakes',
            reward: baseReward,
          );
        }
        return LevelQuest(
          kind: LevelQuestKind.firstPlane,
          titleKey: 'quest_first_plane',
          reward: baseReward + 15,
          targetPlaneId: (id * 3) % planeCount,
        );
      default:
        return LevelQuest(
          kind: LevelQuestKind.perfectRun,
          titleKey: 'quest_perfect_run',
          reward: baseReward + 25,
        );
    }
  }
}
