enum FlashcardState {
  toLearn('To Learn'),
  known('Know'),
  learned('Learned');

  final String displayName;
  const FlashcardState(this.displayName);

  /// Convert string to enum value
  static FlashcardState fromString(String value) {
    return FlashcardState.values.firstWhere(
      (state) => state.name == value,
      orElse: () => FlashcardState.toLearn,
    );
  }
}
