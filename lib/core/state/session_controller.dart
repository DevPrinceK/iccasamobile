import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sample_data/demo_repository.dart';

class SessionState {
  const SessionState({
    required this.isAuthenticated,
    required this.agentName,
    required this.role,
    required this.isOnline,
  });

  final bool isAuthenticated;
  final String agentName;
  final String role;
  final bool isOnline;

  SessionState copyWith({
    bool? isAuthenticated,
    String? agentName,
    String? role,
    bool? isOnline,
  }) {
    return SessionState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      agentName: agentName ?? this.agentName,
      role: role ?? this.role,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    return const SessionState(
      isAuthenticated: false,
      agentName: 'Amara Johnson',
      role: 'Field supervisor',
      isOnline: false,
    );
  }

  void signIn() {
    state = state.copyWith(isAuthenticated: true);
  }

  void signOut() {
    state = state.copyWith(isAuthenticated: false);
  }

  void toggleNetwork() {
    state = state.copyWith(isOnline: !state.isOnline);
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

final demoRepositoryProvider = Provider((ref) => const DemoRepository());
