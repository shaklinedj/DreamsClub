import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casinoloyalty_flutter/data/repositories/admin_casino_repository.dart';
import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';

class AdminCasinosScreen extends ConsumerWidget {
  const AdminCasinosScreen({super.key});

  @override
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
    // Usamos FutureBuilder o StreamBuilder simple por ahora,
    // idealmente se usaría un provider dedicado.
    final repository = AdminCasinoRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Casinos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push('/admin/casinos/new');
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Casino>>(
        stream: repository.watchCasinos(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final casinos = snapshot.data!;
          if (casinos.isEmpty) {
            return const Center(child: Text('No hay casinos registrados.'));
          }

          return ListView.builder(
            itemCount: casinos.length,
            itemBuilder: (context, index) {
              final casino = casinos[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(casino.imageUrl),
                    onBackgroundImageError: (_, __) =>
                        const Icon(Icons.broken_image),
                  ),
                  title: Text(casino.nombre),
                  subtitle: Text(casino.ciudad),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          // Pasar el objeto casino extra a la ruta sería ideal,
                          // pero por simplicidad de GoRouter pasamos ID
                          context.push('/admin/casinos/edit/${casino.id}',
                              extra: casino);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, casino),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Casino casino) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Casino'),
        content: Text('¿Estás seguro de que deseas eliminar ${casino.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repository = AdminCasinoRepository();
      try {
        await repository.deleteCasino(casino.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Casino eliminado correctamente')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }
}
