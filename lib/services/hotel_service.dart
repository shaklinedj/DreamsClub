import 'package:casinoloyalty_flutter/models/hotel_model.dart';

class HotelService {
  final Map<int, Hotel> _hotels = {
    1: Hotel(id: "1", casinoId: "1", nombre: 'Hotel Dreams Iquique', imageUrl: 'https://iquique.dreams.cl/wp-content/uploads/2021/09/hotel-1-1.jpg'),
    2: Hotel(id: "2", casinoId: "2", nombre: 'Hotel Dreams Temuco', imageUrl: 'https://temuco.dreams.cl/wp-content/uploads/2021/09/hotel-1.jpg'),
    3: Hotel(id: "3", casinoId: "3", nombre: 'Hotel Dreams Valdivia', imageUrl: 'https://valdivia.dreams.cl/wp-content/uploads/2021/09/hotel-1.jpg'),
    4: Hotel(id: "4", casinoId: "4", nombre: 'Hotel Dreams Punta Arenas', imageUrl: 'https://punta-arenas.dreams.cl/wp-content/uploads/2021/09/hotel-1.jpg'),
    5: Hotel(id: "5", casinoId: "5", nombre: 'Hotel Monticello', imageUrl: 'https://www.monticello.cl/wp-content/uploads/2021/09/hotel-1.jpg'),
    6: Hotel(id: "6", casinoId: "6", nombre: 'Hotel Dreams Puerto Varas', imageUrl: 'https://puerto-varas.dreams.cl/wp-content/uploads/2021/09/hotel-1.jpg'),
    7: Hotel(id: "7", casinoId: "7", nombre: 'Hotel Dreams Coyhaique', imageUrl: 'https://coyhaique.dreams.cl/wp-content/uploads/2021/09/hotel-1.jpg'),
  };

  Future<Hotel?> getHotelByCasinoId(int casinoId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _hotels[casinoId];
  }
}
