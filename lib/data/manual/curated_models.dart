import 'manual_models.dart';

/// Entrada curada de conteúdo por modelo (ou alias).
class ManualModelEntry {
  final String brand;
  final String model;
  /// Aliases normalizados para matching (ex.: "bros 160", "nxr 160").
  final List<String> aliases;
  final int displacementCc;
  final String vehicleClass; // street | scooter | trail | naked
  final ManualMaintenanceSchedule schedule;
  final List<String> tips;

  const ManualModelEntry({
    required this.brand,
    required this.model,
    this.aliases = const [],
    required this.displacementCc,
    required this.vehicleClass,
    required this.schedule,
    required this.tips,
  });
}

class ManualBrandEntry {
  final String brand;
  final List<String> tips;
  final List<ManualOfficialLink> links;

  const ManualBrandEntry({
    required this.brand,
    required this.tips,
    required this.links,
  });
}

class ManualClassEntry {
  final String id;
  final String label;
  final ManualMaintenanceSchedule schedule;
  final List<String> tips;

  const ManualClassEntry({
    required this.id,
    required this.label,
    required this.schedule,
    required this.tips,
  });
}

// --- Schedules reutilizáveis (aproximados, mercado BR) ---

const _street100160 = ManualMaintenanceSchedule(
  oilInterval: 'A cada ~2.500–4.000 km ou 6 meses (uso urbano intenso: mais cedo)',
  chainCare: 'Lubrificar a cada ~400–600 km; folga tipicamente 2–3 cm (confirme no manual)',
  tireCheck: 'Pressão semanal (ex.: ~28–32 psi — veja etiqueta/manual)',
  brakeCheck: 'Pastilhas a cada ~8.000–12.000 km; fluido a cada ~2 anos',
  otherNotes:
      'Motos 100–160 cc de rua: intervalos aproximados. Uso de entrega/app acelera desgaste.',
);

const _scooterSchedule = ManualMaintenanceSchedule(
  oilInterval: 'A cada ~2.000–4.000 km ou 6 meses',
  chainCare: 'Sem corrente: revise correia CVT / roletes conforme manual (~10–20 mil km)',
  tireCheck: 'Pressão semanal; scooters são sensíveis a pressão baixa',
  brakeCheck: 'Pastilhas e fluido: inspecionar a cada ~5.000 km',
  otherNotes:
      'Scooters: atenção à correia e ao filtro de ar em cidade com poeira.',
);

const _trailSchedule = ManualMaintenanceSchedule(
  oilInterval: 'A cada ~3.000–5.000 km (off-road: revise mais cedo)',
  chainCare: 'Lubrificar após chuva/lama; a cada ~300–500 km em uso misto',
  tireCheck: 'Pressão conforme uso (asfalto vs terra); sulco e laterais',
  brakeCheck: 'Pastilhas e discos: poeira/lama aceleram desgaste',
  otherNotes:
      'Trail/adventure leve: limpe filtro de ar com mais frequência em estrada de terra.',
);

const _naked250300 = ManualMaintenanceSchedule(
  oilInterval: 'A cada ~4.000–6.000 km ou conforme manual',
  chainCare: 'Lubrificar a cada ~500–800 km; alinhar pinhão/coroa',
  tireCheck: 'Pressão semanal; pneus esportivos desgastam mais rápido',
  brakeCheck: 'Pastilhas a cada ~8.000–15.000 km; fluido a cada ~2 anos',
  otherNotes: 'Naked 250–300: revise folga de válvulas no intervalo do fabricante.',
);

const _genericStreet = ManualContentCatalogDefaults.genericStreetSchedule;

// --- Modelos populares BR ---

const List<ManualModelEntry> kCuratedModels = [
  // Honda
  ManualModelEntry(
    brand: 'Honda',
    model: 'CG 160',
    aliases: ['cg160', 'cg 160 fan', 'cg 160 titan', 'cg 160 start'],
    displacementCc: 160,
    vehicleClass: 'street',
    schedule: _street100160,
    tips: [
      'Óleo 10W-30 / 20W-50 conforme ano — confira o manual da sua versão (Fan/Titan/Start).',
      'Corrente: lubrifique com frequência no uso de app/entrega; folga excessiva acelera desgaste de pinhão/coroa.',
      'Pressão dos pneus: cheque semanalmente; CG urbana sofre com carga e passageiro.',
      'Filtro de ar: limpe/troque mais cedo em cidade com poeira ou estrada de terra.',
      'Velas e cabos: falha a frio ou consumo alto merecem revisão antes de “só trocar óleo”.',
      'Use a Garagem do app para alertas de óleo e km — não substitui a revisão na concessionária.',
    ],
  ),
  ManualModelEntry(
    brand: 'Honda',
    model: 'CG 125',
    aliases: ['cg125', 'cg 125 fan', 'cg 125 titan'],
    displacementCc: 125,
    vehicleClass: 'street',
    schedule: _street100160,
    tips: [
      'Troca de óleo frequente é o que mais prolonga a vida do motor 125 em uso diário.',
      'Não force marcha alta em subida com carga — o motor pequeno sofre com overheating.',
      'Corrente e pneus: itens que mais falham em CG de trabalho; revise toda semana.',
      'Carburadas (anos antigos): limpeza de carburador e ponto de ignição fazem diferença.',
      'Injeção (anos recentes): use combustível de qualidade e não ignore luzes do painel.',
    ],
  ),
  ManualModelEntry(
    brand: 'Honda',
    model: 'Biz 125',
    aliases: ['biz125', 'biz 125'],
    displacementCc: 125,
    vehicleClass: 'scooter',
    schedule: _scooterSchedule,
    tips: [
      'Biz é scooter: sem corrente — foque em óleo, freios, pneus e correia/variador.',
      'Baú e carga excessiva alteram freio e pneu traseiro; não ultrapasse o limite do manual.',
      'Em chuva, freio combinado (CBS) ajuda, mas aumente a distância de frenagem.',
      'Bateria e farol: uso urbano noturno — revise terminais e carga.',
      'Assento e bagageiro: fixe bem a carga para não desequilibrar em curvas.',
    ],
  ),
  ManualModelEntry(
    brand: 'Honda',
    model: 'Biz 110',
    aliases: ['biz110', 'biz 110i', 'biz 110'],
    displacementCc: 110,
    vehicleClass: 'scooter',
    schedule: _scooterSchedule,
    tips: [
      'Motor 110: evite duas pessoas + carga pesada em subidas longas.',
      'Óleo no prazo é crítico — scooters urbanas rodam muito em marcha lenta.',
      'Pneus estreitos: pressão correta evita desgaste irregular e “flutuação”.',
      'Revise freio traseiro com frequência (uso urbano intenso).',
    ],
  ),
  ManualModelEntry(
    brand: 'Honda',
    model: 'NXR/Bros 160',
    aliases: [
      'bros 160',
      'bros160',
      'nxr 160',
      'nxr160',
      'nxr/bros 160',
      'bros',
    ],
    displacementCc: 160,
    vehicleClass: 'trail',
    schedule: _trailSchedule,
    tips: [
      'Bros/NXR: corrente e pinhão sofrem em terra — limpe e lubrifique após lama/chuva.',
      'Pneus mistos: pressão mais baixa na terra, mais alta no asfalto (dentro do seguro).',
      'Filtro de ar: peça crítica em trilha; nunca rode com filtro sujo/molhado.',
      'Suspensão e guidão alto: ajuste espelhos e postura para não cansar os ombros.',
      'ABS (se houver): em terra solta, entenda o comportamento antes de frear forte.',
      'Protetor de motor e pedaleiras: úteis se você usa a moto no dia a dia + terra.',
    ],
  ),
  ManualModelEntry(
    brand: 'Honda',
    model: 'NXR/Bros 150',
    aliases: ['bros 150', 'bros150', 'nxr 150', 'nxr150', 'nxr/bros 150'],
    displacementCc: 150,
    vehicleClass: 'trail',
    schedule: _trailSchedule,
    tips: [
      'Mesma lógica da Bros 160: corrente, filtro de ar e pneus mistos.',
      'Motor 150: não force marcha alta com carga em subida de terra.',
      'Após trilha, lave com cuidado (evite jato forte em rolamentos e elétrica).',
    ],
  ),
  ManualModelEntry(
    brand: 'Honda',
    model: 'CB 300F Twister',
    aliases: ['cb 300f', 'cb300f', 'twister', 'cb 300', 'cb300'],
    displacementCc: 300,
    vehicleClass: 'naked',
    schedule: _naked250300,
    tips: [
      'Twister 300: revise folga de válvulas e corrente no intervalo Honda.',
      'Pneus e pastilhas desgastam mais rápido se você anda esportivo.',
      'ABS: pratique frenagens progressivas em local seguro.',
      'Corrente: lubrifique e alinhe; ruído metálico costuma ser folga/desgaste.',
      'Não ignore vibração nova no guidão — pode ser pneu, rolamento ou folga.',
    ],
  ),
  ManualModelEntry(
    brand: 'Honda',
    model: 'Pop 110i',
    aliases: ['pop 110', 'pop110', 'pop 110i', 'pop110i'],
    displacementCc: 110,
    vehicleClass: 'street',
    schedule: _street100160,
    tips: [
      'Pop 110i: leve e econômica — ideal para cidade curta; não abuse de carga.',
      'Óleo e corrente no prazo evitam a maioria das falhas em uso diário.',
      'Freio e pneus: itens de segurança nº 1 em moto de entrada.',
      'Injeção: use combustível de qualidade e não rode com tanque quase vazio sempre.',
    ],
  ),
  ManualModelEntry(
    brand: 'Honda',
    model: 'PCX 160',
    aliases: ['pcx 160', 'pcx160', 'pcx'],
    displacementCc: 160,
    vehicleClass: 'scooter',
    schedule: _scooterSchedule,
    tips: [
      'PCX: revise correia/variador no intervalo Honda; não “estique” a troca.',
      'ABS e freios: ótimos, mas chuva + velocidade pedem distância maior.',
      'Baú e passageiro: respeite o limite de carga do manual.',
      'Bateria e eletrônica: evite acessórios mal instalados que drenam a bateria.',
    ],
  ),

  // Yamaha
  ManualModelEntry(
    brand: 'Yamaha',
    model: 'Factor 150',
    aliases: ['factor 150', 'factor150', 'ys 150', 'ys150'],
    displacementCc: 150,
    vehicleClass: 'street',
    schedule: _street100160,
    tips: [
      'Factor 150: clássica de trabalho — óleo e corrente são prioridade.',
      'Em uso de app, antecipe a troca de óleo em relação ao “máximo” do manual.',
      'Pneus: pressão semanal; carga + passageiro mudam o desgaste.',
      'Freio a tambor (algumas versões): ajuste e lonas no prazo.',
      'Filtro de ar limpo melhora resposta e consumo.',
    ],
  ),
  ManualModelEntry(
    brand: 'Yamaha',
    model: 'Fazer 250',
    aliases: ['fazer 250', 'fazer250', 'fz25', 'fz 25'],
    displacementCc: 250,
    vehicleClass: 'naked',
    schedule: _naked250300,
    tips: [
      'Fazer 250: corrente e pneus são os itens que mais “comem” km se você anda forte.',
      'Revise folga de válvulas no intervalo Yamaha.',
      'ABS (versões recentes): treine frenagem combinada.',
      'Óleo de qualidade e filtro no prazo protegem o motor em uso misto cidade/estrada.',
      'Espelhos e farol: ajuste antes de viagem noturna.',
    ],
  ),
  ManualModelEntry(
    brand: 'Yamaha',
    model: 'XTZ 250 Lander',
    aliases: [
      'lander',
      'lander 250',
      'xtz 250',
      'xtz250',
      'xtz 250 lander',
      'lander250',
    ],
    displacementCc: 250,
    vehicleClass: 'trail',
    schedule: _trailSchedule,
    tips: [
      'Lander: trail — corrente, filtro de ar e pneus mistos são o trio crítico.',
      'Após terra/lama: limpe corrente e verifique folga antes do próximo giro.',
      'Pressão de pneu: ajuste ao tipo de piso (sem ir abaixo do seguro).',
      'Protetores e pedaleiras ajudam no uso misto.',
      'Não ignore ruído de válvula/corrente de comando — leve a uma oficina Yamaha.',
    ],
  ),
  ManualModelEntry(
    brand: 'Yamaha',
    model: 'NMAX',
    aliases: ['nmax', 'nmax 160', 'nmax160', 'n-max'],
    displacementCc: 160,
    vehicleClass: 'scooter',
    schedule: _scooterSchedule,
    tips: [
      'NMAX: scooter premium — correia CVT e óleo no prazo são essenciais.',
      'ABS: ótimo recurso; ainda assim aumente distância em chuva.',
      'Baú/carga: não sobrecarregue o eixo traseiro.',
      'Atualize revisões na rede Yamaha para manter garantia (se aplicável).',
      'Pneus: pressão correta evita “flutuação” em alta velocidade.',
    ],
  ),
  ManualModelEntry(
    brand: 'Yamaha',
    model: 'Fazer 150',
    aliases: ['fazer 150', 'fazer150'],
    displacementCc: 150,
    vehicleClass: 'street',
    schedule: _street100160,
    tips: [
      'Fazer 150: óleo, corrente e pastilhas no ritmo do uso urbano.',
      'Não force o motor em marcha alta com duas pessoas em subida.',
      'Revise tensão da corrente com frequência se rodar muito.',
    ],
  ),

  // Suzuki (mesmo se não estiver no catálogo de imagens)
  ManualModelEntry(
    brand: 'Suzuki',
    model: 'Yes 125',
    aliases: ['yes 125', 'yes125'],
    displacementCc: 125,
    vehicleClass: 'street',
    schedule: _street100160,
    tips: [
      'Yes 125: manutenção clássica de 125 — óleo, corrente, pneus e freios.',
      'Peças: prefira fornecedores confiáveis; evite “economia” em freio/pneu.',
      'Carburação (anos antigos): limpeza periódica evita falha a frio.',
    ],
  ),
  ManualModelEntry(
    brand: 'Suzuki',
    model: 'Intruder 125',
    aliases: ['intruder 125', 'intruder125', 'intruder'],
    displacementCc: 125,
    vehicleClass: 'street',
    schedule: _street100160,
    tips: [
      'Intruder 125: postura custom — ajuste espelhos e evite fadiga nos braços.',
      'Corrente e pneus: revise com o mesmo rigor de qualquer 125 de rua.',
      'Freios: pratique frenagem progressiva; custom costuma ter menos “mordida” inicial.',
      'Óleo no prazo protege o motor em uso urbano com marcha lenta.',
    ],
  ),
];

const List<ManualBrandEntry> kBrandEntries = [
  ManualBrandEntry(
    brand: 'Honda',
    tips: [
      'Consulte o site Honda Motos Brasil / suporte para o manual do seu modelo e rede de concessionárias.',
      'Intervalos Honda variam por versão (Fan, Titan, Start, ABS etc.) — o ano importa.',
      'Em uso de entrega, antecipe óleo e corrente em relação ao intervalo “máximo”.',
      'Nunca ignore luzes do painel ou ruídos novos no motor.',
    ],
    links: [
      ManualOfficialLink(
        title: 'Honda Motos Brasil',
        url: 'https://www.honda.com.br/motos',
        note: 'Busque o manual e o suporte do seu modelo no site oficial.',
      ),
      ManualOfficialLink(
        title: 'Honda — Consórcios e serviços',
        url: 'https://www.honda.com.br/motos/servicos',
        note: 'Ponto de partida para serviços e rede autorizada.',
      ),
    ],
  ),
  ManualBrandEntry(
    brand: 'Yamaha',
    tips: [
      'No site Yamaha Motor do Brasil você encontra suporte e informações por modelo.',
      'Scooters Yamaha (NMAX, etc.): atenção especial à correia/variador.',
      'Trail (Lander/XTZ): limpeza pós-terra é tão importante quanto a troca de óleo.',
      'Use óleo e filtros recomendados para preservar o motor.',
    ],
    links: [
      ManualOfficialLink(
        title: 'Yamaha Motor do Brasil',
        url: 'https://www.yamaha-motor.com.br/',
        note: 'Busque o manual do seu modelo no site oficial.',
      ),
      ManualOfficialLink(
        title: 'Yamaha — Motocicletas',
        url: 'https://www.yamaha-motor.com.br/motos',
        note: 'Catálogo e caminhos para suporte por modelo.',
      ),
    ],
  ),
  ManualBrandEntry(
    brand: 'Suzuki',
    tips: [
      'Confirme intervalos e especificações no material oficial Suzuki do seu ano/modelo.',
      '125 cc de rua: óleo e corrente frequentes em uso urbano intenso.',
      'Prefira oficinas de confiança para freios e elétrica.',
    ],
    links: [
      ManualOfficialLink(
        title: 'Suzuki Motos Brasil',
        url: 'https://www.suzuki.com.br/motos',
        note: 'Busque o manual e o suporte do seu modelo no site oficial.',
      ),
    ],
  ),
];

const List<ManualClassEntry> kClassEntries = [
  ManualClassEntry(
    id: 'street_100_160',
    label: 'Rua 100–160 cc',
    schedule: _street100160,
    tips: [
      'Classe mais comum no BR: óleo e corrente são 80% da longevidade.',
      'Uso de app/entrega: revise pneus e freios com mais frequência.',
      'Pressão dos pneus semanal evita consumo alto e desgaste irregular.',
      'Não ignore vibração ou barulho novo — pare e revise antes de rodar.',
      'Capacete e luzes em dia: checklist de todo dia.',
    ],
  ),
  ManualClassEntry(
    id: 'scooter',
    label: 'Scooter',
    schedule: _scooterSchedule,
    tips: [
      'Sem corrente: o “coração” da transmissão é a correia CVT.',
      'Carga no baú muda freio e pneu traseiro — não sobrecarregue.',
      'Óleo no prazo: scooters passam muito tempo em marcha lenta no trânsito.',
      'Pneus estreitos pedem pressão correta toda semana.',
    ],
  ),
  ManualClassEntry(
    id: 'trail',
    label: 'Trail / big trail leve',
    schedule: _trailSchedule,
    tips: [
      'Terra e lama: limpe corrente e filtro de ar com mais frequência.',
      'Pressão de pneu muda com o piso — ajuste com segurança.',
      'Após chuva/trilha, revise freios e folga da corrente.',
      'Protetores ajudam, mas não substituem manutenção.',
    ],
  ),
  ManualClassEntry(
    id: 'naked_250_plus',
    label: 'Naked / street 250 cc+',
    schedule: _naked250300,
    tips: [
      'Mais potência = mais desgaste de pneu, pastilha e corrente se andar forte.',
      'Revise folga de válvulas no intervalo do fabricante.',
      'ABS (se houver): treine frenagens em local seguro.',
      'Viagens: cheque pressão, luzes, corrente e nível de óleo antes de sair.',
    ],
  ),
  ManualClassEntry(
    id: 'generic',
    label: 'Uso geral',
    schedule: _genericStreet,
    tips: [
      'Siga o manual do fabricante para intervalos e especificações de óleo.',
      'Checklist semanal: pneus, luzes, freios, nível de óleo e corrente (se houver).',
      'Qualquer luz no painel, ruído ou vibração nova: revise antes de rodar.',
      'Use a Garagem e Manutenção do Giro Certo para alertas de km.',
    ],
  ),
];

const String kManualDisclaimer =
    'Este guia traz dicas e intervalos aproximados para o mercado brasileiro. '
    'Não substitui o manual do fabricante nem a revisão em concessionária/oficina autorizada. '
    'Sempre confirme especificações (óleo, folgas, torque e intervalos) no manual oficial do seu modelo/ano.';
