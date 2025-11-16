import 'package:casinoloyalty_flutter/models/restaurant_model.dart';

class RestaurantService {
  final List<Restaurante> _mockRestaurants = [
    Restaurante(
      id: 1,
      casinoId: 5,
      nombre: 'Yann Yvin Brasserie',
      descripcion: 'Cocina francesa de autor con el sello del reconocido chef.',
      imageUrl:
          'https://dreams.cl/content/uploads/sites/2/2021/10/yann-400x280-1.jpg',
      tipoCocina: 'Francesa',
    ),
    Restaurante(
      id: 2,
      casinoId: 5,
      nombre: 'Lola Tapas Bar',
      descripcion: 'Sabores de España en un ambiente relajado y moderno.',
      imageUrl:
          'https://dreams.cl/content/uploads/sites/2/2021/11/lola-400x280-.jpg',
      tipoCocina: 'Española',
    ),
    Restaurante(
      id: 3,
      casinoId: 5,
      nombre: 'Olivera Pastas',
      descripcion: 'Auténtica pasta italiana preparada al momento.',
      imageUrl:
          'https://dreams.cl/content/uploads/sites/2/2021/09/olivera-3.jpg',
      tipoCocina: 'Italiana',
    ),
    Restaurante(
      id: 4,
      casinoId: 5,
      nombre: 'Hops',
      descripcion:
          'El lugar ideal para los amantes de la cerveza y la buena comida.',
      imageUrl: 'https://dreams.cl/content/uploads/sites/2/2022/03/hops.jpg',
      tipoCocina: 'Bar',
    ),
    Restaurante(
      id: 5,
      casinoId: 5,
      nombre: 'El Capataz',
      descripcion: 'Carnes a la parrilla y los mejores sabores chilenos.',
      imageUrl:
          'https://dreams.cl/content/uploads/sites/2/2021/09/capataz-2.jpg',
      tipoCocina: 'Chilena',
    ),
    Restaurante(
      id: 6,
      casinoId: 5,
      nombre: 'Black Bar',
      descripcion: 'Coctelería de autor y una selección de tragos premium.',
      imageUrl:
          'https://dreams.cl/content/uploads/sites/2/2022/03/bbar_400x280.jpg',
      tipoCocina: 'Bar',
    ),
    Restaurante(
      id: 7,
      casinoId: 5,
      nombre: 'Johnny Rockets',
      descripcion: 'Las clásicas hamburguesas y malteadas americanas.',
      imageUrl: 'https://dreams.cl/content/uploads/sites/2/2021/09/jr-3.jpg',
      tipoCocina: 'Americana',
    ),
    Restaurante(
      id: 8,
      casinoId: 5,
      nombre: 'Res de Angostura',
      descripcion: 'Carnes premium y una vista espectacular.',
      imageUrl: 'https://dreams.cl/content/uploads/sites/2/2021/09/res-3.jpg',
      tipoCocina: 'Carnes',
    ),
    Restaurante(
      id: 9,
      casinoId: 5,
      nombre: 'Starbucks',
      descripcion: 'Tu café favorito en el corazón de Monticello.',
      imageUrl:
          'https://dreams.cl/content/uploads/sites/2/2021/09/starb-1.jpg',
      tipoCocina: 'Cafetería',
    ),
    Restaurante(
      id: 10,
      casinoId: 5,
      nombre: 'Tian yi jiao',
      descripcion: 'La mejor comida china en un ambiente elegante.',
      imageUrl: 'https://dreams.cl/content/uploads/sites/2/2021/11/tian.jpg',
      tipoCocina: 'China',
    ),
    Restaurante(
      id: 11,
      casinoId: 5,
      nombre: 'YUHUI',
      descripcion: 'Sabores asiáticos que te sorprenderán.',
      imageUrl:
          'https://dreams.cl/content/uploads/sites/2/2022/11/portada-gastronomia-400x280-2.jpg',
      tipoCocina: 'Asiática',
    ),
    Restaurante(
      id: 12,
      casinoId: 5,
      nombre: 'Burger King',
      descripcion: 'Las hamburguesas a la parrilla que ya conoces.',
      imageUrl:
          'https://dreams.cl/content/uploads/sites/2/2022/03/bk_400x280.jpg',
      tipoCocina: 'Comida Rápida',
    ),

    // Iquique
    Restaurante(
      id: 13,
      casinoId: 1,
      nombre: 'Bar Lucky 7',
      descripcion:
          'En Lucky 7 hemos creado una experiencia gastronómica única, pensada en ti. A tus clásicos favoritos les añadimos un toque especial y sumamos nuevas propuestas imperdibles.',
      imageUrl:
          'https://dreams.cl/content/uploads/sites/3/2023/03/1920x700-px.jpg',
      tipoCocina: 'Bar',
    ),

    // Temuco
    Restaurante(
      id: 14,
      casinoId: 2,
      nombre: 'Las Tranqueras',
      descripcion:
          'Las tranqueras de temuco tiene un toque inigualable y una especial pasión por variados cortes de carne.',
      imageUrl:
          'https://dreams.cl/content/uploads/sites/5/2021/11/las-tranq-3.jpg',
      tipoCocina: 'Carnes',
    ),
    Restaurante(
      id: 15,
      casinoId: 2,
      nombre: 'Restaurant In',
      descripcion: 'Un lugar con los mejores sabores del mundo.',
      imageUrl: 'https://dreams.cl/content/uploads/sites/5/2021/09/in-4.jpg',
      tipoCocina: 'Internacional',
    ),
    Restaurante(
      id: 16,
      casinoId: 2,
      nombre: 'Lucky 7',
      descripcion: 'Disfruta de los más ricos cockteles y tablas.',
      imageUrl:
          'https://dreams.cl/content/uploads/sites/5/2021/09/portada-gastronimia-400x280-1.jpg',
      tipoCocina: 'Bar',
    ),
    Restaurante(
      id: 17,
      casinoId: 2,
      nombre: 'Burger King',
      descripcion: '',
      imageUrl:
          'https://dreams.cl/content/uploads/sites/5/2022/03/bk_400x280.jpg',
      tipoCocina: 'Comida Rápida',
    ),
    Restaurante(
      id: 18,
      casinoId: 2,
      nombre: 'Starbucks',
      descripcion: '',
      imageUrl:
          'https://dreams.cl/content/uploads/sites/5/2022/03/admin-ajax-1-e1656992937810.jpg',
      tipoCocina: 'Cafetería',
    ),

    // Valdivia
    Restaurante(
      id: 19,
      casinoId: 3,
      nombre: 'Lucky 7',
      descripcion: 'Disfruta de los más ricos cockteles y tablas.',
      imageUrl:
          'https://dreams.cl/content/uploads/sites/4/2021/09/portada-gastronimia-400x280-1.jpg',
      tipoCocina: 'Bar',
    ),
    Restaurante(
      id: 20,
      casinoId: 3,
      nombre: 'Sky bar',
      descripcion:
          'Déjate encantar por sus exquisitos tragos, variedad de tablas y la mejor música',
      imageUrl: 'https://dreams.cl/content/uploads/sites/4/2021/09/sky-1.jpg',
      tipoCocina: 'Bar',
    ),
    Restaurante(
      id: 21,
      casinoId: 3,
      nombre: 'Gohan Sushi&Shrimps',
      descripcion:
          'Un lugar en dónde podrás encontrar a los especialistas en sushi - comida japonesa.',
      imageUrl:
          'https://dreams.cl/content/uploads/sites/4/2021/09/My-Post-2021-11-16T030317.223.png',
      tipoCocina: 'Sushi',
    ),
  ];

  Future<List<Restaurante>> getRestaurantsForCasino(int casinoId) async {
    await Future.delayed(const Duration(milliseconds: 450));
    return _mockRestaurants.where((r) => r.casinoId == casinoId).toList();
  }
}
