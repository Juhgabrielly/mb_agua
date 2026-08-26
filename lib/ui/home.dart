import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Map<String, dynamic>> registros = [];

  @override
  void initState() {
    super.initState();
    carregar();
  }

  String dataHoje() {
    final hoje = DateTime.now();

    String dia = hoje.day.toString().padLeft(2, '0');
    String mes = hoje.month.toString().padLeft(2, '0');

    return '$dia/$mes/${hoje.year}';
  }

  Future<void> salvar() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('registrosAgua', jsonEncode(registros));
  }

  Future<void> carregar() async {
    final prefs = await SharedPreferences.getInstance();

    final dados = prefs.getString('registrosAgua');

    if (dados != null) {
      final lista = jsonDecode(dados);

      if (!mounted) return;

      setState(() {
        registros = List<Map<String, dynamic>>.from(
          lista.map((item) => Map<String, dynamic>.from(item)),
        );
      });
    }
  }

  double totalHoje() {
    double total = 0;

    for (var registro in registros) {
      if (registro['data'] == dataHoje()) {
        total += (registro['quantidade'] as num).toDouble();
      }
    }

    return total;
  }

  double pesoHoje() {
    for (int i = registros.length - 1; i >= 0; i--) {
      if (registros[i]['data'] == dataHoje()) {
        return (registros[i]['peso'] as num).toDouble();
      }
    }

    return 0;
  }

  double metaDiaria() {
    return pesoHoje() * 35;
  }

  double porcentagemMeta() {
    if (metaDiaria() == 0) {
      return 0;
    }

    return (totalHoje() / metaDiaria()) * 100;
  }

  void excluir(int index) async {
    setState(() {
      registros.removeAt(index);
    });

    await salvar();
  }

  void abrirModal({int? index}) {
    bool editando = index != null;

    final data = TextEditingController(
      text: editando ? registros[index]['data'] : dataHoje(),
    );

    final quantidade = TextEditingController(
      text: editando ? registros[index]['quantidade'].toString() : '',
    );

    final peso = TextEditingController(
      text: editando ? registros[index]['peso'].toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(editando ? 'Editar consumo' : 'Adicionar consumo'),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: data,
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    hintText: 'dd/mm/aaaa',
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: quantidade,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Quantidade em ml',
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: peso,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Peso atual em kg',
                  ),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),

            ElevatedButton(
              onPressed: () async {
                double? quantidadeValor = double.tryParse(
                  quantidade.text.replaceAll(',', '.'),
                );

                double? pesoValor = double.tryParse(
                  peso.text.replaceAll(',', '.'),
                );

                if (data.text.isEmpty ||
                    quantidadeValor == null ||
                    pesoValor == null) {
                  return;
                }

                final novoRegistro = {
                  'data': data.text,
                  'quantidade': quantidadeValor,
                  'peso': pesoValor,
                };

                setState(() {
                  if (editando) {
                    registros[index] = novoRegistro;
                  } else {
                    registros.add(novoRegistro);
                  }
                });

                await salvar();

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text(editando ? 'Salvar' : 'Adicionar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double total = totalHoje();
    double meta = metaDiaria();
    double porcentagem = porcentagemMeta();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bebi água',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        actions: [
          IconButton(
            onPressed: () {
              abrirModal();
            },
            icon: const Icon(Icons.add_circle, size: 35),
          ),

          const SizedBox(width: 10),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Text(
                      'Consumo de hoje',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      '${total.toStringAsFixed(0)} ml',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text('Meta: ${meta.toStringAsFixed(0)} ml'),

                    const SizedBox(height: 10),

                    LinearProgressIndicator(
                      value: porcentagem > 100 ? 1 : porcentagem / 100,
                    ),

                    const SizedBox(height: 8),

                    Text('${porcentagem.toStringAsFixed(1)}% da meta diária'),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: registros.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.water_drop_outlined,
                          size: 70,
                          color: Colors.grey,
                        ),

                        SizedBox(height: 10),

                        Text('Nenhum consumo registrado'),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(15),

                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.2,
                        ),

                    itemCount: registros.length,

                    itemBuilder: (context, index) {
                      final registro = registros[index];

                      final quantidade = (registro['quantidade'] as num)
                          .toDouble();

                      final peso = (registro['peso'] as num).toDouble();

                      return InkWell(
                        onTap: () {
                          abrirModal(index: index);
                        },

                        child: Card(
                          elevation: 3,

                          child: Stack(
                            children: [
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.water_drop,
                                        color: Colors.blue,
                                        size: 30,
                                      ),

                                      const SizedBox(height: 8),

                                      Text(
                                        '${quantidade.toStringAsFixed(0)} ml',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 5),

                                      Text(registro['data']),

                                      Text('${peso.toStringAsFixed(1)} kg'),
                                    ],
                                  ),
                                ),
                              ),

                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  onPressed: () {
                                    excluir(index);
                                  },
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.grey,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
