enum AiDifficulty { easy, normal, hard }

extension AiDifficultyPersistence on AiDifficulty {
  static AiDifficulty fromSaved(String? value) =>
      AiDifficulty.values
          .where((difficulty) => difficulty.name == value)
          .firstOrNull ??
      AiDifficulty.normal;
}
