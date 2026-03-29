import 'package:flutter/material.dart';
import 'package:raiko_ui/raiko_ui.dart';
import 'package:shared_theme/shared_theme.dart';

import '../../../core/network/raiko_ws_client.dart';

class DesktopDashboardScreen extends StatefulWidget {
  const DesktopDashboardScreen({super.key});

  @override
  State<DesktopDashboardScreen> createState() => _DesktopDashboardScreenState();
}

class _DesktopDashboardScreenState extends State<DesktopDashboardScreen> {
  late final RaikoWsClient client;

  @override
  void initState() {
    super.initState();
    client = RaikoWsClient(
      deviceId: 'desktop-windows-01',
      deviceName: 'RAIKO Desktop',
      platform: 'windows',
      kind: 'desktop',
    )..addListener(_onChanged);
  }

  @override
  void dispose() {
    client.removeListener(_onChanged);
    client.disconnect();
    client.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return RaikoScaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final compact = constraints.maxWidth < RaikoBreakpoints.medium || constraints.maxHeight < 760;
          return compact ? _buildCompactLayout(context) : _buildWideLayout(context);
        },
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return ListView(
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildSessionCard(context, orbSize: 188),
        const SizedBox(height: 16),
        _buildDeviceTile(context),
        const SizedBox(height: 16),
        _buildCommandConsole(context, compact: true),
        const SizedBox(height: 16),
        SizedBox(height: 320, child: _buildActivityStream(context)),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Expanded(child: _buildSessionCard(context, orbSize: 210)),
                    const SizedBox(height: 16),
                    _buildDeviceTile(context),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Expanded(child: _buildCommandConsole(context, compact: false)),
                    const SizedBox(height: 16),
                    Expanded(child: _buildActivityStream(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return RaikoHeader(
      eyebrow: 'DESKTOP ORCHESTRATION',
      title: 'Operations Bridge',
      subtitle: 'Desktop control station for device orchestration and command flow.',
      trailing: RaikoStatusBadge(
        label: client.isConnected ? 'Synchronized' : 'Disconnected',
        color: client.isConnected ? RaikoColors.success : RaikoColors.danger,
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, {required double orbSize}) {
    return RaikoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: RaikoVoiceOrb(
              label: 'LIVE\nLINK',
              size: orbSize,
              isActive: client.isConnected,
            ),
          ),
          const SizedBox(height: 20),
          Text('Neural session', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Stabilize the control link, select a target agent, then dispatch commands.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          RaikoButton(
            label: client.isConnected ? 'Disconnect' : 'Connect to Backend',
            icon: client.isConnected ? Icons.link_off_rounded : Icons.wifi_tethering_rounded,
            onPressed: client.isConnected ? client.disconnect : () => client.connect(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: client.agents.contains(client.selectedAgentId) ? client.selectedAgentId : null,
            decoration: const InputDecoration(labelText: 'Target agent'),
            dropdownColor: RaikoColors.cardElevated,
            items: client.agents
                .map((String agentId) => DropdownMenuItem<String>(value: agentId, child: Text(agentId)))
                .toList(growable: false),
            onChanged: client.agents.isEmpty
                ? null
                : (String? value) {
                    if (value != null) {
                      client.updateSelectedAgent(value);
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTile(BuildContext context) {
    return RaikoDeviceTile(
      title: 'Primary Agent',
      subtitle: client.agents.isEmpty ? 'No connected agents' : client.selectedAgentId,
      statusLabel: client.agents.isEmpty ? 'Unavailable' : 'Operational',
      statusColor: client.agents.isEmpty ? RaikoColors.danger : RaikoColors.success,
      icon: Icons.hub_rounded,
      trailing: Text(client.deviceName, style: Theme.of(context).textTheme.labelMedium),
    );
  }

  Widget _buildCommandConsole(BuildContext context, {required bool compact}) {
    final actions = <Widget>[
      RaikoButton(label: 'Lock', icon: Icons.lock_outline_rounded, onPressed: () => client.sendCommand('lock')),
      RaikoButton(label: 'Sleep', icon: Icons.nightlight_round, onPressed: () => client.sendCommand('sleep')),
      RaikoButton(label: 'Restart', icon: Icons.restart_alt_rounded, onPressed: () => client.sendCommand('restart')),
      RaikoButton(
        label: 'Shutdown',
        icon: Icons.power_settings_new_rounded,
        isDanger: true,
        onPressed: () => client.sendCommand('shutdown'),
      ),
    ];

    return RaikoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Command Console', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'High-priority execution controls for the linked desktop node.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (compact)
            Column(
              children: [
                for (var index = 0; index < actions.length; index++) ...[
                  actions[index],
                  if (index != actions.length - 1) const SizedBox(height: 12),
                ],
              ],
            )
          else
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.8,
                children: actions,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityStream(BuildContext context) {
    return RaikoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activity Stream', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Expanded(
            child: client.logs.isEmpty
                ? Align(
                    alignment: Alignment.topLeft,
                    child: Text('No events yet.', style: Theme.of(context).textTheme.bodyMedium),
                  )
                : ListView.builder(
                    itemCount: client.logs.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(client.logs[index], style: Theme.of(context).textTheme.bodyMedium),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
