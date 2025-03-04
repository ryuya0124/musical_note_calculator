// ゲームの判定幅データを管理するクラス
class GameJudgmentData {
  final String judgmentName; // 判定名
  final double timeWindow;  // 判定の許容時間(ms)

  GameJudgmentData(this.judgmentName, this.timeWindow);
}

final Map<String, List<GameJudgmentData>> gameJudgmentWindows = {
  'Game A': [
    GameJudgmentData('Perfect', 25.0),
    GameJudgmentData('Good', 50.0),
    GameJudgmentData('Bad', 100.0),
  ],
  'Game B': [
    GameJudgmentData('Perfect', 20.0),
    GameJudgmentData('Great', 35.0),
    GameJudgmentData('Miss', 75.0),
  ],
};

/// ゲームと判定を追加
void addGame(String gameName, List<GameJudgmentData> judgments) {
  gameJudgmentWindows[gameName] = judgments;
}

/// ゲームの判定を更新
void updateJudgment(String gameName, String judgment, double value) {
  if (gameJudgmentWindows.containsKey(gameName)) {
    final judgments = gameJudgmentWindows[gameName]!;
    for (var j in judgments) {
      if (j.judgmentName == judgment) {
        judgments[judgments.indexOf(j)] = GameJudgmentData(judgment, value);
        break;
      }
    }
  }
}

/// ゲームの判定を削除
void removeJudgment(String gameName, String judgment) {
  gameJudgmentWindows[gameName]?.removeWhere((j) => j.judgmentName == judgment);
}

/// ゲームごとの判定を削除
void removeGame(String gameName) {
  gameJudgmentWindows.remove(gameName);
}

/// 指定された時間がどの判定に属するかを取得
String? getJudgment(String gameName, double timeDifference) {
  if (!gameJudgmentWindows.containsKey(gameName)) return null;

  for (var judgment in gameJudgmentWindows[gameName]!) {
    if (timeDifference <= judgment.timeWindow) {
      return judgment.judgmentName;
    }
  }
  return null;
}
