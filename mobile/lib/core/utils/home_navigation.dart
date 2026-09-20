// lib/core/utils/home_navigation.dart
//
// Permet à un écran ouvert par-dessus l'accueil (assistant d'ajout, écran de
// confirmation...) de revenir à l'accueil sur un onglet précis.

import 'package:flutter/material.dart';

const int kTabAccueil = 0;
const int kTabArbre = 1;

final ValueNotifier<int?> homeTabRequest = ValueNotifier<int?>(null);

void backToHome(BuildContext context, {int tab = kTabAccueil}) {
  Navigator.of(context).popUntil((route) => route.isFirst);
  homeTabRequest.value = tab;
}
