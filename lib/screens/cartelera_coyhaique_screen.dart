import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CarteleraCoyhaiqueScreen extends StatefulWidget {
  const CarteleraCoyhaiqueScreen({super.key});

  @override
  State<CarteleraCoyhaiqueScreen> createState() => _CarteleraCoyhaiqueScreenState();
}

class _CarteleraCoyhaiqueScreenState extends State<CarteleraCoyhaiqueScreen> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;
  List<QueryDocumentSnapshot> _items = [];

  @override
  void initState() {
    super.initState();
    // Iniciar auto-scroll cada 10 segundos
    _timer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      if (_items.isEmpty) return;
      
      if (_currentPage < _items.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('carteleras')
            .where('casino', isEqualTo: 'Coyhaique')
            .where('isActive', isEqualTo: true)
            .orderBy('order', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar la cartelera: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          _items = snapshot.data?.docs ?? [];

          if (_items.isEmpty) {
            return const Center(
              child: Text(
                'No hay contenido disponible para Coyhaique',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            );
          }

          return PageView.builder(
            controller: _pageController,
            itemCount: _items.length,
            onPageChanged: (int index) {
              _currentPage = index;
            },
            itemBuilder: (context, index) {
              final data = _items[index].data() as Map<String, dynamic>;
              final imageUrl = data['imageUrl'] as String?;
              final title = data['title'] as String?;

              return Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.error, color: Colors.white, size: 50),
                      ),
                    ),
                  // Optional overlay for text
                  if (title != null && title.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(40.0),
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(2.0, 2.0),
                                blurRadius: 3.0,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
