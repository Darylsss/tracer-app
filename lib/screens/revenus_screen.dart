// lib/screens/revenus_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/revenu.dart';

class RevenusScreen extends StatefulWidget {
  const RevenusScreen({super.key});

  @override
  State<RevenusScreen> createState() => _RevenusScreenState();
}

class _RevenusScreenState extends State<RevenusScreen> {
  List<Revenu> _revenus = [];
  bool _isLoading = true;
  
  final _formKey = GlobalKey<FormState>();
  final _origineController = TextEditingController();
  final _montantController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadRevenus();
  }

  Future<void> _loadRevenus() async {
    setState(() => _isLoading = true);
    final api = ApiService();
    final result = await api.getRevenus();
    
    if (result['success']) {
      setState(() {
        _revenus = List<Revenu>.from(result['data'].map((j) => Revenu.fromJson(j)));
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${result['error']}')),
      );
    }
  }

  Future<void> _ajouterRevenu() async {
    if (!_formKey.currentState!.validate()) return;

    final api = ApiService();
    final result = await api.addRevenu(
      DateFormat('yyyy-MM-dd').format(_selectedDate),
      _origineController.text,
      double.parse(_montantController.text),
    );

    if (result['success']) {
      _origineController.clear();
      _montantController.clear();
      _loadRevenus();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Revenu ajouté avec succès')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${result['error']}')),
      );
    }
  }

  Future<void> _supprimerRevenu(int id) async {
    final api = ApiService();
    final result = await api.deleteRevenu(id);
    
    if (result['success']) {
      _loadRevenus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Revenu supprimé')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalRevenus = _revenus.fold(0, (sum, item) => sum + item.montant);
    final formatter = NumberFormat('#,##0', 'fr_FR');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F3F0),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        backgroundColor: const Color(0xFF014AAA),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Carte total
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF014AAA), Color(0xFF4A6FE3)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'Total des revenus',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '${formatter.format(totalRevenus)} FCFA',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Liste
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _revenus.isEmpty
                    ? const Center(
                        child: Text('Aucun revenu enregistré'),
                      )
                    : ListView.builder(
                        itemCount: _revenus.length,
                        itemBuilder: (context, index) {
                          final r = _revenus[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: const Icon(Icons.attach_money,
                                  color: Colors.green),
                              title: Text(r.origine),
                              subtitle: Text(r.date),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${formatter.format(r.montant)} FCFA',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _supprimerRevenu(r.id!),
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

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ajouter un revenu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                title: const Text('Date'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
              ),
              TextFormField(
                controller: _origineController,
                decoration: const InputDecoration(
                  labelText: 'Origine',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _montantController,
                decoration: const InputDecoration(
                  labelText: 'Montant',
                  border: OutlineInputBorder(),
                  prefixText: 'FCFA ',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _ajouterRevenu,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 48, 96, 192),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Ajouter',
                style: TextStyle(color: Colors.white)),
                
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}