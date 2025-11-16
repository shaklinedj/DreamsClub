import 'package:casinoloyalty_flutter/models/restaurante_model.dart';

class RestaurantService {
  final Map<int, List<Restaurante>> _restaurants = {
    1: [
      Restaurante(id: "1", casinoId: "1", nombre: 'La Pampa', imageUrl: 'https://media-cdn.tripadvisor.com/media/photo-s/0a/01/29/73/la-pampa.jpg'),
      Restaurante(id: "2", casinoId: "1", nombre: 'Doña Inés', imageUrl: 'https://media-cdn.tripadvisor.com/media/photo-s/0a/01/29/73/la-pampa.jpg'),
    ],
    2: [
      Restaurante(id: "3", casinoId: "2", nombre: 'In', imageUrl: 'https://temuco.dreams.cl/wp-content/uploads/2021/10/in-1.jpg'),
      Restaurante(id: "4", casinoId: "2", nombre: 'Pichanga', imageUrl: 'https://temuco.dreams.cl/wp-content/uploads/2021/10/pichanga-1.jpg'),
    ],
    3: [
      Restaurante(id: "5", casinoId: "3", nombre: 'Doña Inés', imageUrl: 'https://valdivia.dreams.cl/wp-content/uploads/2021/10/dona-ines-1.jpg'),
      Restaurante(id: "6", casinoId: "3", nombre: 'Sky Bar', imageUrl: 'https://valdivia.dreams.cl/wp-content/uploads/2021/10/sky-bar-1.jpg'),
    ],
    4: [
      Restaurante(id: "7", casinoId: "4", nombre: 'Doña Inés', imageUrl: 'https://punta-arenas.dreams.cl/wp-content/uploads/2021/10/dona-ines-1.jpg'),
      Restaurante(id: "8", casinoId: "4", nombre: 'Sky Bar', imageUrl: 'https://punta-arenas.dreams.cl/wp-content/uploads/2021/10/sky-bar-1.jpg'),
    ],
    5: [
      Restaurante(id: "9", casinoId: "5", nombre: 'El Pescador', imageUrl: 'https://www.monticello.cl/wp-content/uploads/2021/10/el-pescador-1.jpg'),
      Restaurante(id: "10", casinoId: "5", nombre: 'El Rincón del Chef', imageUrl: 'https://www.monticello.cl/wp-content/uploads/2021/10/el-rincon-del-chef-1.jpg'),
      Restaurante(id: "11", casinoId: "5", nombre: 'La Pica de la Esquina', imageUrl: 'https://www.monticello.cl/wp-content/uploads/2021/10/la-pica-de-la-esquina-1.jpg'),
    ],
    6: [
      Restaurante(id: "12", casinoId: "6", nombre: 'Doña Inés', imageUrl: 'https://puerto-varas.dreams.cl/wp-content/uploads/2021/10/dona-ines-1.jpg'),
      Restaurante(id: "13", casinoId: "6", nombre: 'Sky Bar', imageUrl: 'https://puerto-varas.dreams.cl/wp-content/uploads/2021/10/sky-bar-1.jpg'),
    ],
    7: [
      Restaurante(id: "14", casinoId: "7", nombre: 'Donde el Chef', imageUrl: 'https://coyhaique.dreams.cl/wp-content/uploads/2021/10/donde-el-chef-1.jpg'),
      Restaurante(id: "15", casinoId: "7", nombre: 'El Fogón', imageUrl: 'https://coyhaique.dreams.cl/wp-content/uploads/2021/10/el-fogon-1.jpg'),
    ],
  };

  Future<List<Restaurante>> getRestaurantsByCasinoId(int casinoId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _restaurants[casinoId] ?? [];
  }
}
