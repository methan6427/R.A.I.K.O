import 'package:flutter/material.dart';
import 'package:raiko_ui/raiko_ui.dart';
import 'package:shared_theme/shared_theme.dart';

import '../../../core/network/raiko_ws_client.dart';

class MobileDashboardScreen extends StatefulWidget {
  const MobileDashboardScreen({super.key});

  @override
  State<MobileDashboardScreen> createState() => _MobileDashboardScreenState();
}

class _MobileDashboardScreenState extends State<MobileDashboardScreen> {
  late final RaikoWsClient client;

  @override
  void initState() {
    super.initState();
    client = RaikoWsClient(
      deviceId: 'mobile-android-01',
      deviceName: 'RAIKO Mobile',
      platform: 'android',
      kind: 'mobile',
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
          final wide = constraints.maxWidth >= 700;

          return ListView(
            children: [
              RaikoHeader(
                eyebrow: 'MOBILE CONSOLE',
                title: 'Remote Kernel',
                subtitle: 'Mobile command console for Windows endpoints.',
                trailing: RaikoStatusBadge(
                  label: client.isConnected ? 'Linked' : 'Offline',
                  color: client.isConnected ? RaikoColors.success : RaikoColors.danger,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: RaikoVoiceOrb(
                  label: 'R.A.I.K.O',
                  size: wide ? 196 : 164,
                  isActive: client.isConnected,
                ),
              ),
              const SizedBox(height: 24),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildSessionCard(context)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDeviceCard(context)),
                  ],
                )
              else ...[
                _buildSessionCard(context),
                const SizedBox(height: 16),
                _buildDeviceCard(context),
              ],
              const SizedBox(height: 16),
              _buildCommandCard(context, wide: wide),
              const SizedBox(height: 16),
              _buildActivityCard(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context) {
    return RaikoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Session Link', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Bind the mobile relay to an available backend and route commands to a registered agent.',
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

  Widget _buildDeviceCard(BuildContext context) {
    return RaikoDeviceTile(
      title: 'Windows Agent',
      subtitle: client.agents.isEmpty ? 'Waiting for agent registration' : client.selectedAgentId,
      statusLabel: client.agents.isEmpty ? 'Unavailable' : 'Online',
      statusColor: client.agents.isEmpty ? RaikoColors.danger : RaikoColors.success,
      icon: Icons.laptop_windows_rounded,
      trailing: Text(client.deviceName, style: Theme.of(context).textTheme.labelMedium),
    );
  }

  Widget _buildCommandCard(BuildContext context, {required bool wide}) {
    final actions = _buildActions();

    return RaikoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Command Deck', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Low-latency device controls optimized for touch input.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          if (wide)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: actions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 72,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemBuilder: (BuildContext context, int index) => actions[index],
            )
          else
            Column(
              children: [
                for (var index = 0; index < actions.length; index++) ...[
                  actions[index],
                  if (index != actions.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context) {
    return RaikoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activity Log', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (client.logs.isEmpty)
            Text('No events yet.', style: Theme.of(context).textTheme.bodyMedium),
          for (final String entry in client.logs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(entry, style: Theme.of(context).textTheme.bodyMedium),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildActions() {
    return [
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
  }
}
