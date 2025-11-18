import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:casinoloyalty_flutter/widgets/app_drawer.dart';
import 'package:casinoloyalty_flutter/widgets/favorite_casino_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
	const HomeScreen({super.key});

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final selectedCasinoAsync = ref.watch(selectedCasinoProvider);

		return Scaffold(
			drawer: const AppDrawer(),
			appBar: AppBar(
				title: const Text('Mi Casino'),
				actions: [
					IconButton(
						tooltip: 'Cambiar casino',
						onPressed: () => context.go('/select-favorite'),
						icon: const Icon(Icons.swap_horiz),
					),
				],
			),
			body: SafeArea(
				child: selectedCasinoAsync.when(
					loading: () => const Center(child: CircularProgressIndicator()),
					error: (err, stack) => Center(child: Text('Error al cargar casino: $err')),
					data: (casino) {
						if (casino == null) {
							return _EmptyState(onAction: () => context.go('/select-favorite'));
						}

						return RefreshIndicator(
							onRefresh: () async {
								ref.invalidate(selectedCasinoIdProvider);
								final _ = await ref.refresh(selectedCasinoProvider.future);
							},
							child: SingleChildScrollView(
								physics: const AlwaysScrollableScrollPhysics(),
								padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										_HeroImage(casino: casino),
										const SizedBox(height: 24),
										Text(
											casino.nombre,
											style: Theme.of(context).textTheme.headlineMedium,
											maxLines: 2,
											overflow: TextOverflow.ellipsis,
										),
										const SizedBox(height: 4),
										Text(
											'${casino.ciudad} · ${casino.direccion}',
											style: Theme.of(context).textTheme.bodyMedium,
											maxLines: 2,
											overflow: TextOverflow.ellipsis,
										),
										const SizedBox(height: 24),
										Wrap(
											spacing: 12,
											runSpacing: 12,
											children: [
												_InfoChip(icon: Icons.hotel, label: casino.hotel != null ? 'Hotel disponible' : 'Sin hotel'),
												_InfoChip(
													icon: Icons.restaurant,
													label: '${casino.restaurantes?.length ?? 0} restaurantes',
												),
												_InfoChip(icon: Icons.location_on, label: casino.ciudad),
											],
										),
										const SizedBox(height: 32),
										Text('Acciones rápidas', style: Theme.of(context).textTheme.titleLarge),
										const SizedBox(height: 12),
										_QuickActionGrid(casino: casino),
										const SizedBox(height: 32),
										Text('Explora más', style: Theme.of(context).textTheme.titleLarge),
										const SizedBox(height: 12),
										_ExploreCard(
											title: 'Ver detalle del casino',
											subtitle: 'Fotos, servicios y amenities exclusivos.',
											icon: Icons.visibility_outlined,
											onTap: () => context.push('/all-casinos/${casino.id}'),
										),
										const SizedBox(height: 12),
										_ExploreCard(
											title: 'Cómo llegar',
											subtitle: casino.direccion,
											icon: Icons.map_outlined,
											onTap: () => context.push('/all-casinos/${casino.id}'),
										),
									],
								),
							),
						);
					},
				),
			),
		);
	}
}

class _HeroImage extends StatelessWidget {
	const _HeroImage({required this.casino});

	final Casino casino;

	@override
	Widget build(BuildContext context) {
		return ClipRRect(
			borderRadius: BorderRadius.circular(24),
			child: AspectRatio(
				aspectRatio: 16 / 9,
				child: Stack(
					fit: StackFit.expand,
					children: [
						Image.asset(
							casino.imageUrl,
							fit: BoxFit.cover,
							errorBuilder: (context, error, stack) => Container(
								color: Colors.grey[300],
								child: const Icon(Icons.photo, size: 48),
							),
						),
						Container(
						decoration: BoxDecoration(
							gradient: LinearGradient(
								colors: [Colors.black.withValues(alpha: 0.65), Colors.transparent],
								begin: Alignment.bottomCenter,
								end: Alignment.topCenter,
							),
						),
					),
						Align(
							alignment: Alignment.bottomLeft,
							child: Padding(
								padding: const EdgeInsets.all(16.0),
								child: Column(
									mainAxisSize: MainAxisSize.min,
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											casino.nombre,
											style: Theme.of(context)
													.textTheme
													.headlineSmall
													?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
											maxLines: 2,
											overflow: TextOverflow.ellipsis,
										),
										Text(
											casino.ciudad,
											style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
											maxLines: 1,
											overflow: TextOverflow.ellipsis,
										),
									],
								),
							),
						)
					],
				),
			),
		);
	}
}

class _InfoChip extends StatelessWidget {
	const _InfoChip({required this.icon, required this.label});

	final IconData icon;
	final String label;

	@override
	Widget build(BuildContext context) {
		return Chip(
			avatar: Icon(icon, size: 18),
			label: Text(label),
			padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
		);
	}
}

class _QuickActionGrid extends StatelessWidget {
	const _QuickActionGrid({required this.casino});

	final Casino casino;

	@override
	Widget build(BuildContext context) {
		return GridView.count(
			crossAxisCount: 2,
			childAspectRatio: 1.6,
			shrinkWrap: true,
			mainAxisSpacing: 12,
			crossAxisSpacing: 12,
			physics: const NeverScrollableScrollPhysics(),
			children: [
				_QuickActionCard(
					icon: Icons.card_giftcard,
					title: 'Promociones',
					subtitle: 'Bonos y beneficios',
					onTap: () => context.go('/promotions'),
				),
				_QuickActionCard(
					icon: Icons.event,
					title: 'Eventos',
					subtitle: 'Shows y conciertos',
					onTap: () => context.go('/events'),
				),
				_QuickActionCard(
					icon: Icons.restaurant_menu,
					title: 'Restaurantes',
					subtitle: 'Gastronomía destacada',
					onTap: () => context.go('/restaurants'),
				),
				_QuickActionCard(
					icon: Icons.favorite_outline,
					title: 'Cambiar favorito',
					subtitle: 'Personaliza tu experiencia',
					onTap: () => context.go('/select-favorite'),
				),
			],
		);
	}
}

class _QuickActionCard extends StatelessWidget {
	const _QuickActionCard({
		required this.icon,
		required this.title,
		required this.subtitle,
		required this.onTap,
	});

	final IconData icon;
	final String title;
	final String subtitle;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		return Card(
			elevation: 2,
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
			child: InkWell(
				borderRadius: BorderRadius.circular(20),
				onTap: onTap,
				child: Padding(
					padding: const EdgeInsets.all(12.0),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						mainAxisAlignment: MainAxisAlignment.center,
						children: [
							Icon(icon, size: 24),
							const SizedBox(height: 8),
							Flexible(
								child: Text(
									title, 
									style: Theme.of(context).textTheme.titleSmall,
									maxLines: 1,
									overflow: TextOverflow.ellipsis,
								),
							),
							const SizedBox(height: 2),
							Flexible(
								child: Text(
									subtitle, 
									style: Theme.of(context).textTheme.bodySmall,
									maxLines: 2,
									overflow: TextOverflow.ellipsis,
								),
							),
						],
					),
				),
			),
		);
	}
}

class _ExploreCard extends StatelessWidget {
	const _ExploreCard({
		required this.title,
		required this.subtitle,
		required this.icon,
		required this.onTap,
	});

	final String title;
	final String subtitle;
	final IconData icon;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		return Card(
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
			child: ListTile(
				onTap: onTap,
				leading: CircleAvatar(
					backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
					child: Icon(icon, color: Theme.of(context).colorScheme.primary),
				),
				title: Text(
					title,
					maxLines: 1,
					overflow: TextOverflow.ellipsis,
				),
				subtitle: Text(
					subtitle,
					maxLines: 2,
					overflow: TextOverflow.ellipsis,
				),
				trailing: const Icon(Icons.chevron_right),
			),
		);
	}
}

class _EmptyState extends StatelessWidget {
	const _EmptyState({required this.onAction});

	final VoidCallback onAction;

	@override
	Widget build(BuildContext context) {
		return FavoriteCasinoPlaceholder(onSelect: onAction);
	}
}
