import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(IMCAdapter());
  await Hive.openBox<IMC>('IMCBox');

  runApp(MyApp());
}

@HiveType(typeId: 0)
class IMC {
  @HiveField(0)
  late double peso;

  @HiveField(1)
  late double altura;

  IMC({
    required this.peso,
    required this.altura,
  });
}

class IMCAdapter extends TypeAdapter<IMC> {
  @override
  IMC read(BinaryReader reader) {
    return IMC(
      peso: reader.readDouble(),
      altura: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, IMC obj) {
    writer.writeDouble(obj.peso);
    writer.writeDouble(obj.altura);
  }

  @override
  int get typeId => 0;
}

class ConfiguracoesScreen extends StatefulWidget {
  @override
  _ConfiguracoesScreenState createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  final TextEditingController alturaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurações'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: alturaController,
              decoration: InputDecoration(labelText: 'Altura (m)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final novaAltura = double.tryParse(alturaController.text) ?? 0;
                if (novaAltura > 0) {
                  final box = await Hive.openBox<IMC>('IMCBox');
                  await box.put('altura', novaAltura);
                  Navigator.pop(context, novaAltura);
                }
              },
              child: Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController pesoController = TextEditingController();
  late double altura;
  late IMC imc;

  @override
  void initState() {
    super.initState();
    _lerAlturaSalva();
  }

  void _lerAlturaSalva() async {
    final box = await Hive.openBox<IMC>('IMCBox');
    altura = box.get('altura', defaultValue: 1.70) ?? 1.70;
    imc = IMC(peso: 0, altura: altura);
  }

  void _calcularIMC() {
    double peso = double.tryParse(pesoController.text) ?? 0;
    if (peso > 0 && altura > 0) {
      setState(() {
        imc = IMC(peso: peso, altura: altura);
      });
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Erro'),
            content: Text('Por favor, insira valores válidos para peso e altura.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _configurarAltura() async {
    final novaAltura = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ConfiguracoesScreen()),
    );

    if (novaAltura != null) {
      setState(() {
        altura = novaAltura;
        imc = IMC(peso: 0, altura: altura);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora de IMC',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Calculadora de IMC'),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: _configurarAltura,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: pesoController,
                decoration: InputDecoration(labelText: 'Peso (kg)'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _calcularIMC,
                child: Text('Calcular IMC'),
              ),
              Text('IMC: ${(imc.peso / (imc.altura * imc.altura)).toStringAsFixed(2)}'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    Hive.close();
    super.dispose();
  }
}



