import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casinoloyalty_flutter/models/game_config_model.dart';
import 'package:casinoloyalty_flutter/providers/game_availability_provider.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';

class AdminGamesScreen extends ConsumerWidget {
  const AdminGamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Verificar si es administrador
    final user = ref.watch(userProvider);
    if (!user.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso Denegado')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No tienes permisos de administrador.'),
            ],
          ),
        ),
      );
    }

    final configsAsync = ref.watch(gameConfigsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Juegos'),
      ),
      body: configsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (configs) {
          if (configs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.games, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No hay configuraciones de juegos.'),
                  SizedBox(height: 8),
                  Text(
                    'Las configuraciones se crean automáticamente\nal iniciar la app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: configs.length,
              itemBuilder: (context, index) {
                final config = configs[index];
                return _GameConfigCard(config: config);
              },
            ),
          );
        },
      ),
    );
  }
}

class _GameConfigCard extends StatelessWidget {
  final GameConfig config;

  const _GameConfigCard({required this.config});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/admin/games/edit/${config.gameId}', extra: config);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getGameIcon(config.gameId),
                    size: 32,
                    color: config.isActive ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          config.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          config.gameId,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: config.isActive ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      config.isActive ? 'ACTIVO' : 'INACTIVO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChip(
                    icon: Icons.location_on,
                    label:
                        config.requiresLocation ? 'GPS Requerido' : 'Sin GPS',
                    color:
                        config.requiresLocation ? Colors.orange : Colors.blue,
                  ),
                  _buildChip(
                    icon: Icons.repeat,
                    label: _getFrequencyLabel(config.frequency),
                    color: Colors.purple,
                  ),
                  if (config.activeWeekdays.isNotEmpty)
                    _buildChip(
                      icon: Icons.calendar_today,
                      label: '${config.activeWeekdays.length} días',
                      color: Colors.teal,
                    ),
                  if (config.allowedUserLevels.isNotEmpty)
                    _buildChip(
                      icon: Icons.star,
                      label: config.allowedUserLevels.join(', ').toUpperCase(),
                      color: Colors.amber.shade700,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  IconData _getGameIcon(String gameId) {
    switch (gameId) {
      case 'dreams_mania':
        return Icons.casino;
      case 'roulette':
        return Icons.circle_outlined;
      case 'slots':
        return Icons.view_column;
      case 'dreams_match':
        return Icons.grid_view_rounded;
      default:
        return Icons.games;
    }
  }

  String _getFrequencyLabel(GameFrequency frequency) {
    switch (frequency) {
      case GameFrequency.daily:
        return '1x/día';
      case GameFrequency.weekly:
        return '1x/semana';
      case GameFrequency.unlimited:
        return 'Ilimitado';
      case GameFrequency.oncePerStay:
        return '1x/visita';
    }
  }
}
