import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../ui/navigation/destinations.dart';
import '../../../ui/widgets/navigation_layout.dart';
import '../catalogue/discovery_catalogue.dart';
import '../engine/discovery_runtime.dart';
import '../engine/discovery_see_all_controller.dart';
import 'homelab_discovery_see_all_screen.dart';

HomeLabDiscoverySection? findHomeLabDiscoverySection(
  HomeLabDiscoveryCatalogue catalogue,
  String sectionId,
) {
  for (final tab in catalogue.tabs) {
    for (final section in tab.sections) {
      if (section.id == sectionId) return section;
    }
  }
  return null;
}

class HomeLabDiscoverySeeAllEntry extends StatefulWidget {
  final HomeLabDiscoveryCatalogue catalogue;
  final String sectionId;
  final HomeLabDiscoverySeeAllController? controller;
  final HomeLabDiscoveryRuntimeLoad? runtimeLoad;

  const HomeLabDiscoverySeeAllEntry({
    super.key,
    required this.catalogue,
    required this.sectionId,
    this.controller,
    this.runtimeLoad,
  });

  @override
  State<HomeLabDiscoverySeeAllEntry> createState() =>
      _HomeLabDiscoverySeeAllEntryState();
}

class _HomeLabDiscoverySeeAllEntryState
    extends State<HomeLabDiscoverySeeAllEntry> {
  late Future<HomeLabDiscoverySeeAllController> _controllerFuture;
  HomeLabDiscoveryRuntime? _ownedRuntime;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _controllerFuture = _resolveController(++_generation);
  }

  @override
  void didUpdateWidget(covariant HomeLabDiscoverySeeAllEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.catalogue != widget.catalogue ||
        oldWidget.sectionId != widget.sectionId ||
        oldWidget.controller != widget.controller ||
        oldWidget.runtimeLoad != widget.runtimeLoad) {
      _replaceControllerFuture();
    }
  }

  void _replaceControllerFuture() {
    _ownedRuntime?.dispose();
    _ownedRuntime = null;
    final generation = ++_generation;
    setState(() => _controllerFuture = _resolveController(generation));
  }

  Future<HomeLabDiscoverySeeAllController> _resolveController(
    int generation,
  ) async {
    final supplied = widget.controller;
    if (supplied != null) return supplied;

    final section = findHomeLabDiscoverySection(
      widget.catalogue,
      widget.sectionId,
    );
    if (section == null) {
      throw StateError(
        'Discovery section ${widget.sectionId} is no longer in the catalogue',
      );
    }

    final runtime =
        await (widget.runtimeLoad ?? HomeLabDiscoveryRuntime.create)(
          widget.catalogue,
        );
    if (!mounted || generation != _generation) {
      runtime.dispose();
      throw StateError('Stale Discovery deep-route resolution');
    }

    try {
      final controller = runtime.seeAllControllerFor(section);
      _ownedRuntime = runtime;
      return controller;
    } catch (_) {
      runtime.dispose();
      rethrow;
    }
  }

  @override
  void dispose() {
    _generation++;
    _ownedRuntime?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeLabDiscoverySeeAllController>(
      future: _controllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _shell(const Center(child: CircularProgressIndicator()));
        }
        final controller = snapshot.data;
        if (snapshot.hasError || controller == null) {
          return _shell(
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'This Discovery collection could not be opened.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: _replaceControllerFuture,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              context.go(Destinations.seerrDiscover),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Discovery'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return HomeLabDiscoverySeeAllScreen(controller: controller);
      },
    );
  }

  Widget _shell(Widget child) {
    return Scaffold(
      body: NavigationLayout(
        activeRoute: Destinations.seerrDiscover,
        showBackButton: true,
        child: SafeArea(child: child),
      ),
    );
  }
}
