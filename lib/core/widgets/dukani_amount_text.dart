import 'package:flutter/material.dart';

/// Renders numbers/currency amounts (and any other digit-led string) with
/// forced LTR direction. Under the app's global RTL directionality, a plain
/// [Text] showing e.g. "8,250.00 ر.س" gets its comma/period-separated digit
/// groups reordered by the bidi algorithm — this pins the run so amounts
/// always read in the correct order regardless of ambient text direction.
class DukaniAmountText extends StatelessWidget {
  const DukaniAmountText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      overflow: overflow,
      textDirection: TextDirection.ltr,
    );
  }
}
