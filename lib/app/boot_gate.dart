// First screen after the native splash. Holds the mark briefly so the handoff
// from drawable/launch_background.xml is seamless, then routes to onboarding
// or straight to the calendar.

import 'package:flutter/material.dart';

import '../data/entry_store.dart';
import '../data/settings_store.dart';
import '../navigation/quiet_route.dart';
import '../screens/calendar_screen.dart';
import '../screens/onboarding_screen.dart';
import '../widgets/sodam_mark.dart';
import 'theme.dart';

class BootGate extends StatefulWidget {
  const BootGate({
    super.key,
    required this.entryStore,
    required this.settingsStore,
    this.splashHold = const Duration(milliseconds: 1100),
  });

  final EntryStore entryStore;
  final SettingsStore settingsStore;
  final Duration splashHold;

  @override
  State<BootGate> createState() => _BootGateState();
}

class _BootGateState extends State<BootGate> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final results = await Future.wait(<Future<Object?>>[
      widget.settingsStore.load(),
      Future<void>.delayed(widget.splashHold),
    ]);

    if (!mounted) {
      return;
    }

    final settings = results.first! as SodamSettings;
    Navigator.of(context).pushReplacement(
      quietRoute<void>(
        settings.onboarded
            ? CalendarScreen(store: widget.entryStore)
            : OnboardingScreen(
                entryStore: widget.entryStore,
                settingsStore: widget.settingsStore,
                settings: settings,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: kBackground,
      body: Center(child: SodamMark()),
    );
  }
}
