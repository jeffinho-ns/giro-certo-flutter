import '../models/motorcycle_model.dart';

class MotorcycleDataService {
  static List<MotorcycleModel>? _cachedList;

  static List<MotorcycleModel> getAllMotorcycles() {
    if (_cachedList != null) return _cachedList!;

    _cachedList = [
      // Honda
      MotorcycleModel(id: '1', brand: 'Honda', model: 'CG 125', displacement: '125 cc', abs: 'Sem ABS (basic)'),
      MotorcycleModel(id: '2', brand: 'Honda', model: 'CG 160', displacement: '160 cc', abs: 'ABS em versões superiores'),
      MotorcycleModel(id: '3', brand: 'Honda', model: 'Biz 110', displacement: '110 cc', abs: 'Sem ABS'),
      MotorcycleModel(id: '4', brand: 'Honda', model: 'Biz 125', displacement: '125 cc', abs: 'Sem ABS'),
      MotorcycleModel(id: '5', brand: 'Honda', model: 'Pop 110i', displacement: '110 cc', abs: 'Sem ABS'),
      MotorcycleModel(id: '6', brand: 'Honda', model: 'NXR/Bros 150', displacement: '150 cc', abs: 'ABS opcional em versões mais completas'),
      MotorcycleModel(id: '7', brand: 'Honda', model: 'NXR/Bros 160', displacement: '160 cc', abs: 'ABS opcional em versões mais completas'),
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
      MotorcycleModel(id: '26', brand: 'Yamaha', model: 'Lander 150', displacement: '150 cc', abs: 'ABS em versões superiores'),
      MotorcycleModel(id: '27', brand: 'Yamaha', model: 'Lander 250', displacement: '250 cc', abs: 'ABS em versões superiores'),
      MotorcycleModel(id: '28', brand: 'Yamaha', model: 'NMAX', displacement: '155 cc', abs: 'ABS'),
      MotorcycleModel(id: '29', brand: 'Yamaha', model: 'NMAX 160', displacement: '160 cc', abs: 'ABS'),
      MotorcycleModel(id: '30', brand: 'Yamaha', model: 'MT-03', displacement: '300 cc', abs: 'ABS de série'),
      MotorcycleModel(id: '31', brand: 'Yamaha', model: 'MT-07', displacement: '700 cc', abs: 'ABS de série'),
      
      // Shineray
      MotorcycleModel(id: '32', brand: 'Shineray', model: 'XY 50', displacement: '50 cc', abs: 'Sem ABS (geralmente)'),
      MotorcycleModel(id: '33', brand: 'Shineray', model: 'XY 125', displacement: '125 cc', abs: 'Sem ABS (geralmente)'),
      MotorcycleModel(id: '34', brand: 'Shineray', model: 'XY 150', displacement: '150 cc', abs: 'Sem ABS (geralmente)'),
      MotorcycleModel(id: '35', brand: 'Shineray', model: 'SHI 175', displacement: '175 cc', abs: 'Sem ABS'),
      
      // Mottu (TVS)
      MotorcycleModel(id: '36', brand: 'Mottu (TVS)', model: 'Sport 110i', displacement: '110 cc', abs: 'Sem ABS'),
      
      // Avelloz
      MotorcycleModel(id: '37', brand: 'Avelloz', model: 'AZ1', displacement: '125 cc', abs: 'Sem ABS'),
      
      // Royal Enfield
      MotorcycleModel(id: '38', brand: 'Royal Enfield', model: 'Meteor 350', displacement: '350 cc', abs: 'ABS'),
      MotorcycleModel(id: '39', brand: 'Royal Enfield', model: 'Hunter 350', displacement: '350 cc', abs: 'ABS'),
      MotorcycleModel(id: '40', brand: 'Royal Enfield', model: 'Himalayan', displacement: '410 cc', abs: 'ABS'),
      
      // Bajaj
      MotorcycleModel(id: '41', brand: 'Bajaj', model: 'Dominar 160', displacement: '160 cc', abs: 'ABS em algumas versões'),
      MotorcycleModel(id: '42', brand: 'Bajaj', model: 'NS160', displacement: '160 cc', abs: 'ABS em algumas versões'),
      MotorcycleModel(id: '43', brand: 'Bajaj', model: 'NS200', displacement: '200 cc', abs: 'ABS'),
      MotorcycleModel(id: '44', brand: 'Bajaj', model: 'Dominar 400', displacement: '400 cc', abs: 'ABS'),
      
      // Haojue
      MotorcycleModel(id: '45', brand: 'Haojue', model: 'DK 160', displacement: '160 cc', abs: 'ABS em certas configurações'),
      MotorcycleModel(id: '46', brand: 'Haojue', model: 'DR 160', displacement: '160 cc', abs: 'ABS em certas configurações'),
      
      // BMW Motorrad
      MotorcycleModel(id: '47', brand: 'BMW Motorrad', model: 'G 310 R', displacement: '310 cc', abs: 'ABS de série'),
      MotorcycleModel(id: '48', brand: 'BMW Motorrad', model: 'G 310 GS', displacement: '310 cc', abs: 'ABS de série'),
      MotorcycleModel(id: '49', brand: 'BMW Motorrad', model: 'R 1250 GS', displacement: '1250 cc', abs: 'ABS, controle de tração'),
      
      // Triumph
      MotorcycleModel(id: '50', brand: 'Triumph', model: 'Tiger 900', displacement: '900 cc', abs: 'Pacotes eletrônicos e ABS'),
      MotorcycleModel(id: '51', brand: 'Triumph', model: 'Tiger 1200', displacement: '1200 cc', abs: 'Pacotes eletrônicos e ABS'),
      MotorcycleModel(id: '52', brand: 'Triumph', model: 'Street Triple', displacement: '660 cc', abs: 'ABS, ride modes'),
      MotorcycleModel(id: '53', brand: 'Triumph', model: 'Street Triple 765', displacement: '765 cc', abs: 'ABS, ride modes'),
      
      // Kawasaki
      MotorcycleModel(id: '54', brand: 'Kawasaki', model: 'Ninja 300', displacement: '300 cc', abs: 'ABS de série nas modernas'),
      MotorcycleModel(id: '55', brand: 'Kawasaki', model: 'Ninja 400', displacement: '400 cc', abs: 'ABS de série nas modernas'),
      MotorcycleModel(id: '56', brand: 'Kawasaki', model: 'Ninja 650', displacement: '650 cc', abs: 'ABS de série nas modernas'),
      MotorcycleModel(id: '57', brand: 'Kawasaki', model: 'Z 650', displacement: '650 cc', abs: 'ABS'),
      MotorcycleModel(id: '58', brand: 'Kawasaki', model: 'Versys', displacement: '650 cc', abs: 'ABS'),
      
      // Dafra
      MotorcycleModel(id: '59', brand: 'Dafra', model: 'Apache RTR 200', displacement: '200 cc', abs: 'ABS em versões modernas'),
      
      // Suzuki
      MotorcycleModel(id: '60', brand: 'Suzuki', model: 'GSX-S 750', displacement: '750 cc', abs: 'ABS'),
      
      // Vmoto / Voltz / Watts
      MotorcycleModel(id: '61', brand: 'Vmoto / Voltz / Watts', model: 'EV1', displacement: 'Elétrico', abs: 'Frenagem regenerativa / ABS em alguns'),
      MotorcycleModel(id: '62', brand: 'Vmoto / Voltz / Watts', model: 'W125', displacement: 'Elétrico', abs: 'Frenagem regenerativa / ABS em alguns'),
      
      // Bull Motors
      MotorcycleModel(id: '63', brand: 'Bull Motors', model: 'Scooter 125', displacement: '125 cc', abs: 'Variável'),
      MotorcycleModel(id: '64', brand: 'Bull Motors', model: 'Scooter 300', displacement: '300 cc', abs: 'Variável'),
      MotorcycleModel(id: '65', brand: 'Bull Motors', model: 'Street 150', displacement: '150 cc', abs: 'Variável'),
      
      // GCX
      MotorcycleModel(id: '66', brand: 'GCX', model: 'Moto 50', displacement: '50 cc', abs: 'Geralmente sem ABS'),
      MotorcycleModel(id: '67', brand: 'GCX', model: 'Moto 125', displacement: '125 cc', abs: 'Geralmente sem ABS'),
      MotorcycleModel(id: '68', brand: 'GCX', model: 'Moto 150', displacement: '150 cc', abs: 'Geralmente sem ABS'),
      
      // Harley-Davidson
      MotorcycleModel(id: '69', brand: 'Harley-Davidson', model: 'Street Glide', displacement: '1800 cc', abs: 'ABS de série'),
      MotorcycleModel(id: '70', brand: 'Harley-Davidson', model: 'Road King', displacement: '1800 cc', abs: 'ABS de série'),
      MotorcycleModel(id: '71', brand: 'Harley-Davidson', model: 'Sportster', displacement: '900 cc', abs: 'ABS de série'),
      
      // Ducati
      MotorcycleModel(id: '72', brand: 'Ducati', model: 'Panigale V2', displacement: '950 cc', abs: 'ABS + electronics'),
      MotorcycleModel(id: '73', brand: 'Ducati', model: 'Multistrada', displacement: '1260 cc', abs: 'ABS + electronics'),
      
      // Zontes
      MotorcycleModel(id: '74', brand: 'Zontes', model: 'T310', displacement: '300 cc', abs: 'ABS'),
      MotorcycleModel(id: '75', brand: 'Zontes', model: 'R310', displacement: '300 cc', abs: 'ABS'),
      MotorcycleModel(id: '76', brand: 'Zontes', model: '310V', displacement: '300 cc', abs: 'ABS'),
      
      // KTM
      MotorcycleModel(id: '77', brand: 'KTM', model: 'Duke 250', displacement: '250 cc', abs: 'ABS'),
      MotorcycleModel(id: '78', brand: 'KTM', model: 'Duke 390', displacement: '390 cc', abs: 'ABS'),
      MotorcycleModel(id: '79', brand: 'KTM', model: 'Duke 790', displacement: '790 cc', abs: 'ABS'),
      MotorcycleModel(id: '80', brand: 'KTM', model: 'RC 250', displacement: '250 cc', abs: 'ABS'),
      MotorcycleModel(id: '81', brand: 'KTM', model: 'RC 390', displacement: '390 cc', abs: 'ABS'),
      
      // Kymco
      MotorcycleModel(id: '82', brand: 'Kymco', model: 'People 125', displacement: '125 cc', abs: 'ABS em modelos médios'),
      MotorcycleModel(id: '83', brand: 'Kymco', model: 'Downtown 300', displacement: '300 cc', abs: 'ABS em modelos médios'),
      MotorcycleModel(id: '84', brand: 'Kymco', model: 'AK 550', displacement: '550 cc', abs: 'ABS'),
      
      // Piaggio / Vespa
      MotorcycleModel(id: '85', brand: 'Piaggio / Vespa', model: 'Primavera 125', displacement: '125 cc', abs: 'ABS em modelos médios'),
      MotorcycleModel(id: '86', brand: 'Piaggio / Vespa', model: 'Primavera 150', displacement: '150 cc', abs: 'ABS em modelos médios'),
      MotorcycleModel(id: '87', brand: 'Piaggio / Vespa', model: 'GTS 300', displacement: '300 cc', abs: 'ABS'),
    ];
    return _cachedList!;
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
