import 'package:flutter/material.dart';

class AppSizes {
  static double w(BuildContext context, double fraction) =>
      MediaQuery.of(context).size.width * fraction;

  static double h(BuildContext context, double fraction) =>
      MediaQuery.of(context).size.height * fraction;
}
