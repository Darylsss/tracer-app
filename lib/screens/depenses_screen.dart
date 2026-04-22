// lib/screens/depenses_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/depense.dart';

class DepensesScreen extends StatefulWidget {
  const DepensesScreen({super.key});

  @override
  State<DepensesScreen> createState() => _DepensesScreenState();
}

class _DepensesScreenState extends State<DepensesScreen> {
  List<Depense> _depenses = [];
  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();
  final _objetCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  static const _darkBlue = Color(0xFF014AAA);
  static const _lightBlue = Color(0xFFEAF2FB);
  static const _warmBg = Color(0xFFF8F3F0);

  @override
  void initState() {
    super.initState();
    _loadDepenses();
  }

  @override
  void dispose() {
    _objetCtrl.dispose();
    _montantCtrl.dispose();
    super.dispose();
  }

  // ── Chargement ─────────────────────────────────────────────────────────────
  Future<void> _loadDepenses() async {
    setState(() => _isLoading = true);
    final result = await ApiService().getDepenses();
    if (!mounted) return;
    if (result['success']) {
      setState(() {
        _depenses = List<Depense>.from(
            result['data'].map((j) => Depense.fromJson(j)));
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      _snack('Erreur: ${result['error']}', error: true);
    }
  }

  // ── Ajout ──────────────────────────────────────────────────────────────────
  Future<void> _ajouterDepense(File? justificatifFile) async {
    print('Justificatif reçu: ${justificatifFile?.path}');
    if (!_formKey.currentState!.validate()) return;

    final result = await ApiService().addDepense(
      DateFormat('yyyy-MM-dd').format(_selectedDate),
      _objetCtrl.text.trim(),
      double.parse(_montantCtrl.text),
      justificatif: justificatifFile,
    );

    if (!mounted) return;

    if (result['success']) {
      _objetCtrl.clear();
      _montantCtrl.clear();
      _snack('✅ Dépense ajoutée avec succès');
      _loadDepenses();
    } else {
      _snack('Erreur: ${result['error']}', error: true);
    }
  }

  // ── Suppression ────────────────────────────────────────────────────────────
  Future<void> _supprimerDepense(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer'),
        content: const Text('Voulez-vous vraiment supprimer cette dépense ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final result = await ApiService().deleteDepense(id);
      if (result['success']) {
        _snack('🗑️ Dépense supprimée');
        _loadDepenses();
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red[700] : null,
    ));
  }

  String _categoryIcon(String objet) {
    final o = objet.toLowerCase();
    if (o.contains('nourriture') || o.contains('repas') ||
        o.contains('course') || o.contains('pain')) {
      return '🍔';
    }
    if (o.contains('transport') || o.contains('essence') ||
        o.contains('taxi')) {
      return '🚗';
    }
    if (o.contains('logement') || o.contains('loyer')) return '🏠';
    if (o.contains('santé') || o.contains('medic') ||
        o.contains('hopital')) {
      return '💊';
    }
    if (o.contains('loisir') || o.contains('cinema')) return '🎬';
    if (o.contains('éducation') || o.contains('école') ||
        o.contains('cours')) {
      return '📚';
    }
    if (o.contains('facture') || o.contains('eau') ||
        o.contains('electricite')) {
      return '⚡';
    }
    return '📄';
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final total = _depenses.fold(0.0, (s, d) => s + d.montantDepense);
    final formatter = NumberFormat('#,##0', 'fr_FR');

    return Scaffold(
      backgroundColor: _warmBg,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: _darkBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // ── Carte total ──
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFC62828), Color(0xFFEF5350)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_down, color: Colors.white70, size: 20),
                  SizedBox(width: 8),
                  Text('Total des dépenses',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              Text('${formatter.format(total)} FCFA',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold)),
            ]),
          ),

          // ── Liste ──
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _darkBlue))
                : _depenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long,
                                size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('Aucune dépense enregistrée',
                                style: TextStyle(color: Colors.grey[600])),
                            const SizedBox(height: 8),
                            Text('Appuyez sur + pour ajouter',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _depenses.length,
                        itemBuilder: (_, i) {
                          final d = _depenses[i];
                          return GestureDetector(
                            onTap: () => _showDetail(d),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2))
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: _lightBlue,
                                  child: Text(_categoryIcon(d.objetDepense),
                                      style: const TextStyle(fontSize: 20)),
                                ),
                                title: Text(d.objetDepense,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15)),
                                subtitle: Row(
                                  children: [
                                    Text(
                                      DateFormat('dd/MM/yyyy')
                                          .format(DateTime.parse(d.date)),
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600]),
                                    ),
                                    if (d.justificatif != null &&
                                        d.justificatif!.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _lightBlue,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text('📎 justif.',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: _darkBlue)),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '-${formatter.format(d.montantDepense)} FCFA',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFFC62828)),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.grey, size: 20),
                                      onPressed: () =>
                                          _supprimerDepense(d.id!),
                                    ),
                                  ],
                                ),
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

  // ══════════════════════════════════════════════════════════════════════════
  //  BOTTOM SHEET : Détail dépense
  // ══════════════════════════════════════════════════════════════════════════
  void _showDetail(Depense d) {
    final formatter = NumberFormat('#,##0', 'fr_FR');
    final hasJustif =
        d.justificatif != null && d.justificatif!.isNotEmpty;
    final justifUrl = hasJustif
        ? '${ApiService.baseUrl.replaceAll('/api', '')}/storage/${d.justificatif}'
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFFFEBEE),
                radius: 22,
                child: Text(_categoryIcon(d.objetDepense),
                    style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(d.objetDepense,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            _detailRow(Icons.calendar_today, 'Date',
                DateFormat('dd MMMM yyyy').format(DateTime.parse(d.date))),
            const SizedBox(height: 12),
            _detailRow(Icons.attach_money, 'Montant',
                '${formatter.format(d.montantDepense)} FCFA',
                valueColor: const Color(0xFFC62828)),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.attach_file, size: 18, color: Colors.grey),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Justificatif',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    if (!hasJustif)
                      const Text('Aucun justificatif',
                          style: TextStyle(
                              fontSize: 14, color: Colors.black54))
                    else ...[
                      ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: Image.network(
    justifUrl!,
    height: 280,        // ← augmente ici
    width: double.infinity,
    fit: BoxFit.contain, // ← contain pour voir l'image entière sans crop
    errorBuilder: (_, __, ___) => Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file, color: Color(0xFF014AAA)),
          SizedBox(width: 8),
          Text('Voir le fichier',
              style: TextStyle(color: Color(0xFF014AAA))),
        ],
      ),
    ),
  ),
),
                    ],
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _supprimerDepense(d.id!);
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Supprimer cette dépense',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: Colors.grey),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87)),
      ]),
    ]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BOTTOM SHEET : Formulaire ajout
  // ══════════════════════════════════════════════════════════════════════════
  void _showAddDialog() {
    File? justificatifLocal;
    _selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) {
          return Padding(
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
                  const Text('Ajouter une dépense',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // Date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date'),
                    subtitle: Text(
                        DateFormat('dd/MM/yyyy').format(_selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setModal(() => _selectedDate = date);
                      }
                    },
                  ),
                  const SizedBox(height: 10),

                  // Objet
                  TextFormField(
                    controller: _objetCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Objet de la dépense',
                      hintText: 'Ex: Courses, Essence, Loyer...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.shopping_cart),
                    ),
                    validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 10),

                  // Montant
                  TextFormField(
                    controller: _montantCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Montant',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                      prefixText: 'FCFA ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 10),

                  // Justificatif (optionnel)
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16))),
                        builder: (_) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Choisir depuis la galerie'),
                                onTap: () async {
                                  Navigator.pop(context);
                                  final file = await picker.pickImage(
                                      source: ImageSource.gallery);
                                  if (file != null) {
                                    setModal(() {
                                      justificatifLocal = File(file.path);
                                    });
                                  }
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: const Text('Prendre une photo'),
                                onTap: () async {
                                  Navigator.pop(context);
                                  final file = await picker.pickImage(
                                      source: ImageSource.camera);
                                  if (file != null) {
                                    setModal(() {
                                      justificatifLocal = File(file.path);
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        Icon(
                          justificatifLocal != null
                              ? Icons.check_circle
                              : Icons.attach_file,
                          color: justificatifLocal != null
                              ? Colors.green
                              : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            justificatifLocal != null
                                ? justificatifLocal!.path.split('/').last
                                : 'Ajouter un justificatif (optionnel)',
                            style: TextStyle(
                              color: justificatifLocal != null
                                  ? Colors.black87
                                  : Colors.grey[600],
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (justificatifLocal != null)
                          GestureDetector(
                            onTap: () => setModal(() {
                              justificatifLocal = null;
                            }),
                            child: const Icon(Icons.close,
                                size: 18, color: Colors.grey),
                          ),
                      ]),
                    ),
                  ),

                  // Aperçu image
                  if (justificatifLocal != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(justificatifLocal!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Bouton ajouter
                  ElevatedButton(
                    onPressed: () async {
  final file = justificatifLocal; // capture avant fermeture
  Navigator.pop(context);
  await _ajouterDepense(file);
},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF014AAA),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Ajouter la dépense',
                        style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}