import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../core/widgets/premium_pressable.dart';

class DeploymentScreen extends StatefulWidget {
  const DeploymentScreen({super.key});

  @override
  State<DeploymentScreen> createState() => _DeploymentScreenState();
}

class _DeploymentScreenState extends State<DeploymentScreen> {
  String _status = 'READY'; // READY, BUILDING, SUCCESS, ERROR
  String _version = 'v1.0.0 (Build 12)';
  String _lastLog = 'Idle. Waiting for manual trigger.';

  void _triggerDeploy() {
    setState(() {
      _status = 'BUILDING';
      _lastLog = 'Deployment command SENT. Waiting for agent execution...';
    });
    // In a real scenario, this might trigger a backend hook.
    // For this redesign, we're providing the UI to the user.
    debugPrint('DEPLOY_STABLE_TRIGGERED');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ops Center'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVersionCard(context),
            const SizedBox(height: 32),
            _buildStatusCard(context),
            const SizedBox(height: 32),
            const Spacer(),
            _buildDeployButton(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.indigo.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.indigo.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded, color: AppTheme.indigo),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Version', style: theme.textTheme.labelMedium),
              Text(
                _version,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final theme = Theme.of(context);
    Color statusColor;
    switch (_status) {
      case 'BUILDING':
        statusColor = AppTheme.indigo;
        break;
      case 'SUCCESS':
        statusColor = AppTheme.emerald;
        break;
      case 'ERROR':
        statusColor = AppTheme.rose;
        break;
      default:
        statusColor = AppTheme.slate600;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _lastLog,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.slate400,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeployButton(BuildContext context) {
    final isBuilding = _status == 'BUILDING';
    return PremiumPressable(
      onTap: isBuilding ? null : _triggerDeploy,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: isBuilding ? null : AppTheme.primaryGradient,
          color: isBuilding ? AppTheme.slate200 : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isBuilding
              ? []
              : [
                  BoxShadow(
                    color: AppTheme.indigo.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Center(
          child: isBuilding
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.indigo,
                  ),
                )
              : const Text(
                  'Initiate Stable Deploy',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}
