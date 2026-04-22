// lib/models/depense.dart
class Depense {
  int? id;
  String date;
  String objetDepense;
  double montantDepense;
  String? justificatif;

  Depense({
    this.id,
    required this.date,
    required this.objetDepense,
    required this.montantDepense,
    this.justificatif,
  });

  factory Depense.fromJson(Map<String, dynamic> json) {
    return Depense(
      id: json['id'],
      date: json['date'],
      objetDepense: json['objet_depense'],
      montantDepense: double.parse(json['montant_depense'].toString()),
      justificatif: json['justificatif'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'objet_depense': objetDepense,
      'montant_depense': montantDepense,
      'justificatif': justificatif,
    };
  }
}