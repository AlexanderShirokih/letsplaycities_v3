import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/remote/bloc/searching_for_hosts_bloc.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/remote_host.dart';
import 'package:lets_play_cities/remote/server/probe/network_discovery.dart';
import 'package:lets_play_cities/screens/common/base_bloc_builder.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

/// Screen used to search all game server hosts on local network
class SearchingHostsScreen extends StatelessWidget {
  /// Creates the discovery the screen scans with, the bloc closes it
  final NetworkDiscovery Function()? createDiscovery;

  const SearchingHostsScreen({super.key, this.createDiscovery});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: BlocProvider(
          create: (_) {
            final getIt = GetIt.instance;
            return SearchingForHostsBloc(
              discovery:
                  createDiscovery?.call() ??
                  NetworkDiscovery.createDiscovery(
                    port: AppConfig.lanPort,
                    errorLogger: getIt.get<ErrorLogger>(),
                  ),
            )..add(StartSearchingEvent());
          },
          child: BaseBlocBuilder<SearchingForHostsBloc, HostSearchingResult>(
            dataBuilder: _buildResult,
            loadingBuilder: (context, _) => _buildResult(
              context,
              const HostSearchingResult([], isCompleted: false),
            ),
            initialBuilder: (context) => _buildResult(
              context,
              const HostSearchingResult([], isCompleted: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context, HostSearchingResult result) {
    final t = context.t;
    final c = AppColors.of(context);
    void retry() {
      context.read<SearchingForHostsBloc>().add(StartSearchingEvent());
    }

    final nothingFound = result.isCompleted && result.availableHosts.isEmpty;

    return Column(
      children: [
        AppScreenHeader(
          title: t.multiplayer.gamesNearby,
          onBack: () => Navigator.of(context).maybePop(),
          actions: [
            if (result.isCompleted && !nothingFound)
              AppIconButton(
                AppGlyph.replay,
                tooltip: t.multiplayer.retry,
                onPressed: retry,
              ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              if (!result.isCompleted)
                Center(child: AppRadar(size: 200, center: _RadarCenter())),
              if (nothingFound) ...[
                const SizedBox(height: 24),
                Text(
                  t.multiplayer.nothingFound,
                  textAlign: TextAlign.center,
                  style: AppText.title.copyWith(color: c.ink),
                ),
                const SizedBox(height: 16),
                Center(
                  child: AppButton(
                    label: t.multiplayer.retry,
                    icon: AppGlyph.replay,
                    onPressed: retry,
                  ),
                ),
              ],
              if (result.availableHosts.isNotEmpty) ...[
                const SizedBox(height: 18),
                _HostList(hosts: result.availableHosts),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RadarCenter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Container(
      width: 36,
      height: 54,
      decoration: BoxDecoration(
        color: c.violet,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: c.shadow, width: 2.5),
      ),
      alignment: Alignment.center,
      child: AppIcon(AppGlyph.wifi, size: 20, color: AppColors.light.surface),
    );
  }
}

class _HostList extends StatelessWidget {
  final List<RemoteHost> hosts;

  const _HostList({required this.hosts});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: c.edge, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          for (var i = 0; i < hosts.length; i++) ...[
            if (i > 0) Container(height: 2, color: c.bg),
            _HostRow(host: hosts[i], color: i.isEven ? c.orange : c.yellow),
          ],
        ],
      ),
    );
  }
}

class _HostRow extends StatelessWidget {
  final RemoteHost host;
  final Color color;

  const _HostRow({required this.host, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return InkWell(
      onTap: () => Navigator.pop(context, host),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: AppIcon(
                  AppGlyph.phone,
                  size: 22,
                  color: AppColors.light.ink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      host.hostName,
                      style: AppText.body.copyWith(color: c.ink),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      host.address,
                      style: AppText.caption.copyWith(color: c.inkSoft),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Transform.flip(
                flipX: true,
                child: AppIcon(AppGlyph.back, size: 20, color: c.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
