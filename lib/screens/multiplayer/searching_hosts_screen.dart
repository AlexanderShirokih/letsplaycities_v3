import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/base/remote/bloc/searching_for_hosts_bloc.dart';
import 'package:lets_play_cities/remote/remote_host.dart';
import 'package:lets_play_cities/screens/common/base_bloc_builder.dart';

/// Screen used to search all game server hosts on local network
class SearchingHostsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Мультиплеер'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: BlocProvider(
          create: (_) => SearchingForHostsBloc()..add(StartSearchingEvent()),
          child: BaseBlocBuilder<SearchingForHostsBloc, HostSearchingResult>(
            dataBuilder: _buildScanResults,
            loadingBuilder: _buildLoadingView,
            initialBuilder: _buildInitialView,
          ),
        ),
      ),
    );
  }

  Widget _buildInitialView(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        icon: Icon(Icons.search),
        label: Text('Поиск'),
        onPressed: () =>
            context.read<SearchingForHostsBloc>().add(StartSearchingEvent()),
      ),
    );
  }

  Widget _buildLoadingView(BuildContext context, int? progress) =>
      _buildScanResults(context, HostSearchingResult([], isCompleted: false));

  Widget _buildScanResults(BuildContext context, HostSearchingResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Доступные устройства',
                style: Theme.of(context).textTheme.headline5,
              ),
            ),
            result.isCompleted
                ? IconButton(
                    icon: FaIcon(FontAwesomeIcons.syncAlt),
                    onPressed: () => context
                        .read<SearchingForHostsBloc>()
                        .add(StartSearchingEvent()),
                  )
                : CircularProgressIndicator(),
          ],
        ),
        Container(
          height: 300.0,
          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: _buildContent(context, result),
        ),
        const SizedBox(height: 12.0),
        Text(
          'Вы должны находиться в одной сети для поиска устройств',
          style: Theme.of(context).textTheme.caption,
        ),
      ],
    );
  }

  Widget _buildItem(BuildContext context, RemoteHost e) {
    return Card(
      elevation: 4.0,
      child: Container(
        margin: EdgeInsets.all(8.0),
        child: ListTile(
          leading: FaIcon(FontAwesomeIcons.wifi, size: 28.0),
          title: Text(e.hostName),
          subtitle: Text(e.address),
          trailing: Text(e.versionName),
          onTap: () => Navigator.pop(context, e),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, HostSearchingResult result) {
    if (result.availableHosts.isNotEmpty) {
      return ListView(
        children:
            result.availableHosts.map((e) => _buildItem(context, e)).toList(),
      );
    }

    if (result.isCompleted) {
      return Center(
        child: Text(
            'Ничего не найдено. Убедитесь что у оппонента создано соединение и '
            'вы находитесь в одной сети'),
      );
    }

    return Center(
      child: FaIcon(
        FontAwesomeIcons.search,
        color: Theme.of(context).textTheme.caption!.color,
        size: 80.0,
      ),
    );
  }
}
