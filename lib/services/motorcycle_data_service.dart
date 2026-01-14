import '../models/motorcycle_model.dart';

class MotorcycleDataService {
  static List<MotorcycleModel> getAllMotorcycles() {
    return [
      // Honda
      MotorcycleModel(id: '1', brand: 'Honda', model: 'CG 125', displacement: '125 cc', abs: 'Sem ABS'),
      MotorcycleModel(id: '2', brand: 'Honda', model: 'CG 160', displacement: '160 cc', abs: 'ABS em versões superiores'),
      MotorcycleModel(id: '3', brand: 'Honda', model: 'Biz 110', displacement: '110 cc', abs: 'Sem ABS'),
      MotorcycleModel(id: '4', brand: 'Honda', model: 'Biz 125', displacement: '125 cc', abs: 'Sem ABS'),
      MotorcycleModel(id: '5', brand: 'Honda', model: 'Pop 110i', displacement: '110 cc', abs: 'Sem ABS'),
      MotorcycleModel(id: '6', brand: 'Honda', model: 'NXR/Bros 150', displacement: '150 cc', abs: 'ABS opcional'),
      MotorcycleModel(id: '7', brand: 'Honda', model: 'NXR/Bros 160', displacement: '160 cc', abs: 'ABS opcional'),
      MotorcycleModel(id: '8', brand: 'Honda', model: 'CB 300F Twister', displacement: '300 cc', abs: 'ABS em versões topo'),
      MotorcycleModel(id: '9', brand: 'Honda', model: 'XRE 190', displacement: '190 cc', abs: 'ABS em versões modernas'),
      MotorcycleModel(id: '10', brand: 'Honda', model: 'XRE 300', displacement: '300 cc', abs: 'ABS disponível'),
      MotorcycleModel(id: '11', brand: 'Honda', model: 'PCX 150', displacement: '150 cc', abs: 'ABS de série'),
      MotorcycleModel(id: '12', brand: 'Honda', model: 'PCX 160', displacement: '160 cc', abs: 'ABS de série'),
      MotorcycleModel(id: '13', brand: 'Honda', model: 'ADV 160', displacement: '160 cc', abs: 'ABS de série'),
      MotorcycleModel(id: '14', brand: 'Honda', model: 'CBR 500', displacement: '500 cc', abs: 'ABS de série'),
      MotorcycleModel(id: '15', brand: 'Honda', model: 'Hornet 500', displacement: '500 cc', abs: 'ABS de série'),
      MotorcycleModel(id: '16', brand: 'Honda', model: 'CB 650', displacement: '650 cc', abs: 'ABS, controle de tração'),
      MotorcycleModel(id: '17', brand: 'Honda', model: 'CB 650R', displacement: '650 cc', abs: 'ABS, controle de tração'),
      MotorcycleModel(id: '18', brand: 'Honda', model: 'Forza 350', displacement: '330 cc', abs: 'ABS de série'),
      
      // Yamaha
      MotorcycleModel(id: '19', brand: 'Yamaha', model: 'YBR 125', displacement: '125 cc', abs: 'Sem ABS em versões básicas'),
      MotorcycleModel(id: '20', brand: 'Yamaha', model: 'YBR 150', displacement: '150 cc', abs: 'Sem ABS em versões básicas'),
      MotorcycleModel(id: '21', brand: 'Yamaha', model: 'Factor 150', displacement: '150 cc', abs: 'Sem ABS'),
      MotorcycleModel(id: '22', brand: 'Yamaha', model: 'Fazer 150', displacement: '150 cc', abs: 'ABS em versões completas'),
      MotorcycleModel(id: '23', brand: 'Yamaha', model: 'Fazer 250', displacement: '250 cc', abs: 'ABS em versões completas'),
      MotorcycleModel(id: '24', brand: 'Yamaha', model: 'XTZ 250 Lander', displacement: '250 cc', abs: 'ABS em versões equipadas'),
      MotorcycleModel(id: '25', brand: 'Yamaha', model: 'Crosser 150', displacement: '150 cc', abs: 'ABS em versões superiores'),
      MotorcycleModel(id: '26', brand: 'Yamaha', model: 'NMAX', displacement: '155 cc', abs: 'ABS'),
      MotorcycleModel(id: '27', brand: 'Yamaha', model: 'NMAX 160', displacement: '160 cc', abs: 'ABS'),
      MotorcycleModel(id: '28', brand: 'Yamaha', model: 'MT-03', displacement: '300 cc', abs: 'ABS de série'),
      MotorcycleModel(id: '29', brand: 'Yamaha', model: 'MT-07', displacement: '700 cc', abs: 'ABS de série'),
      
      // Kawasaki
      MotorcycleModel(id: '30', brand: 'Kawasaki', model: 'Ninja 300', displacement: '300 cc', abs: 'ABS de série'),
      MotorcycleModel(id: '31', brand: 'Kawasaki', model: 'Ninja 650', displacement: '650 cc', abs: 'ABS de série'),
      MotorcycleModel(id: '32', brand: 'Kawasaki', model: 'Z 650', displacement: '650 cc', abs: 'ABS'),
      MotorcycleModel(id: '33', brand: 'Kawasaki', model: 'Versys', displacement: '650 cc', abs: 'ABS'),
      
      // Outras marcas principais
      MotorcycleModel(id: '34', brand: 'Royal Enfield', model: 'Meteor 350', displacement: '350 cc', abs: 'ABS'),
      MotorcycleModel(id: '35', brand: 'Royal Enfield', model: 'Hunter 350', displacement: '350 cc', abs: 'ABS'),
      MotorcycleModel(id: '36', brand: 'Royal Enfield', model: 'Himalayan', displacement: '410 cc', abs: 'ABS'),
      MotorcycleModel(id: '37', brand: 'Bajaj', model: 'Dominar 160', displacement: '160 cc', abs: 'ABS em algumas versões'),
      MotorcycleModel(id: '38', brand: 'Bajaj', model: 'NS200', displacement: '200 cc', abs: 'ABS'),
      MotorcycleModel(id: '39', brand: 'Bajaj', model: 'Dominar 400', displacement: '400 cc', abs: 'ABS'),
      MotorcycleModel(id: '40', brand: 'BMW Motorrad', model: 'G 310 R', displacement: '310 cc', abs: 'ABS de série'),
      MotorcycleModel(id: '41', brand: 'BMW Motorrad', model: 'G 310 GS', displacement: '310 cc', abs: 'ABS de série'),
      MotorcycleModel(id: '42', brand: 'Harley-Davidson', model: 'Street Glide', displacement: '1800 cc', abs: 'ABS de série'),
      MotorcycleModel(id: '43', brand: 'Harley-Davidson', model: 'Sportster', displacement: '900 cc', abs: 'ABS de série'),
      MotorcycleModel(id: '44', brand: 'Ducati', model: 'Panigale V2', displacement: '950 cc', abs: 'ABS + electronics'),
      MotorcycleModel(id: '45', brand: 'Ducati', model: 'Multistrada', displacement: '1260 cc', abs: 'ABS + electronics'),
    ];
  }

  static List<MotorcycleModel> searchMotorcycles(String query) {
    if (query.isEmpty) return [];
    
    final all = getAllMotorcycles();
    final lowerQuery = query.toLowerCase();
    
    return all.where((moto) {
      return moto.brand.toLowerCase().contains(lowerQuery) ||
             moto.model.toLowerCase().contains(lowerQuery) ||
             '${moto.brand} ${moto.model}'.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  static MotorcycleModel? findMotorcycleById(String id) {
    return getAllMotorcycles().firstWhere(
      (moto) => moto.id == id,
      orElse: () => getAllMotorcycles().first,
    );
  }
}
