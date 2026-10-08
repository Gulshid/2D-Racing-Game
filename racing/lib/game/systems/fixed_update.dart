/// Implement on components that need constant-rate updates (physics).
mixin FixedUpdate {
  /// [dt] is always GameConfig.physicsStep.
  void fixedUpdate(double dt);
}
