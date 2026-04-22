// lib/screens/statistiques_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/revenu.dart';
import '../models/depense.dart';

class StatistiquesScreen extends StatefulWidget {
  const StatistiquesScreen({super.key});

  @override
  State<StatistiquesScreen> createState() => _StatistiquesScreenState();
}

class _StatistiquesScreenState extends State<StatistiquesScreen> {
  List<Revenu> _revenus = [];
  List<Depense> _depenses = [];
  bool _isLoading = true;

  static const _darkBlue = Color(0xFF014AAA);
  static const _lightBlue = Color(0xFFEAF2FB);
  static const _warmBg = Color(0xFFF8F3F0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final api = ApiService();
    final revenusResult = await api.getRevenus();
    final depensesResult = await api.getDepenses();

    if (revenusResult['success']) {
      _revenus = List<Revenu>.from(revenusResult['data'].map((j) => Revenu.fromJson(j)));
    }
    if (depensesResult['success']) {
      _depenses = List<Depense>.from(depensesResult['data'].map((j) => Depense.fromJson(j)));
    }
    setState(() => _isLoading = false);
  }

  double get totalRevenus => _revenus.fold(0, (sum, r) => sum + r.montant);
  double get totalDepenses => _depenses.fold(0, (sum, d) => sum + d.montantDepense);
  double get solde => totalRevenus - totalDepenses;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'fr_FR');

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Cartes récapitulatives
          Row(
            children: [
              _buildStatCard('Revenus', totalRevenus, Colors.green),
              const SizedBox(width: 12),
              _buildStatCard('Dépenses', totalDepenses, Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          Row(children: [
  _buildStatCard('Solde', solde, solde >= 0 ? Colors.blue : Colors.orange),
]),
          const SizedBox(height: 24),
          
          // Graphique
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (totalRevenus > totalDepenses ? totalRevenus : totalDepenses) * 1.2,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          formatter.format(value.toInt()),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        const titles = ['Revenus', 'Dépenses'];
                        if (value.toInt() >= 0 && value.toInt() < titles.length) {
                          return Text(
                            titles[value.toInt()],
                            style: const TextStyle(fontSize: 12),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: totalRevenus,
                        color: Colors.green,
                        width: 40,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: totalDepenses,
                        color: Colors.red,
                        width: 40,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Liste des dernières transactions
          const Text(
            'Dernières transactions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ..._getDernieresTransactions(),
        ],
      ),
    );
  }

 Widget _buildStatCard(String title, double amount, Color color) {
  final formatter = NumberFormat('#,##0', 'fr_FR');
  return Expanded(   // garde Expanded
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            '${formatter.format(amount)} FCFA',
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
}

  List<Widget> _getDernieresTransactions() {
    List<Map<String, dynamic>> transactions = [];
    
    for (var r in _revenus) {
      transactions.add({
        'date': r.date,
        'libelle': r.origine,
        'montant': r.montant,
        'type': 'revenu',
      });
    }
    
    for (var d in _depenses) {
      transactions.add({
        'date': d.date,
        'libelle': d.objetDepense,
        'montant': d.montantDepense,
        'type': 'depense',
      });
    }
    
    transactions.sort((a, b) => b['date'].compareTo(a['date']));
    transactions = transactions.take(5).toList();
    
    return transactions.map((t) {
      final formatter = NumberFormat('#,##0', 'fr_FR');
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: Icon(
            t['type'] == 'revenu' ? Icons.trending_up : Icons.trending_down,
            color: t['type'] == 'revenu' ? Colors.green : Colors.red,
          ),
          title: Text(t['libelle']),
          subtitle: Text(t['date']),
          trailing: Text(
            '${t['type'] == 'revenu' ? '+' : '-'} ${formatter.format(t['montant'])} FCFA',
            style: TextStyle(
              color: t['type'] == 'revenu' ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }).toList();
  }
}