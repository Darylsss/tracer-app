// lib/models/revenu.dart
class Revenu {
  int? id;
  String date;
  String origine;
  double montant;

  Revenu({this.id, required this.date, required this.origine, required this.montant});

  factory Revenu.fromJson(Map<String, dynamic> json) {
    return Revenu(
      id: json['id'],
      date: json['date'],
      origine: json['origine'],
      montant: double.parse(json['montant'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'origine': origine,
      'montant': montant,
    };
  }
}