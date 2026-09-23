import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ConnectionFooter extends StatelessWidget {
  const ConnectionFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10);
    final linkStyle = style?.copyWith(decoration: TextDecoration.underline);

    void openUrl(String url) {
      canLaunchUrlString(url).then((can) {
        if (can) {
          launchUrlString(url);
        }
      });
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => openUrl('https://ticonsultores.cl/'),
          child: Text('Términos de Uso', style: linkStyle),
        ),
        Text(' - ', style: style),
        InkWell(
          onTap: () => openUrl('https://ticonsultores.cl/privacy.html'),
          child: Text('Privacidad', style: linkStyle),
        ),
        Text(' - ', style: style),
        Text('TiConsultores SpA.', style: style),
        Text('   ', style: style), // Right-Padding, so it doesn't collide with the border.
      ],
    );
  }
}
