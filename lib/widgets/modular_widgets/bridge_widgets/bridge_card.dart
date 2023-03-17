import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/card_scaffold.dart';

class BridgeCard extends StatelessWidget {
  const BridgeCard({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Bridge',
      description:
      'The ZNN to wZNN bridge is unavailable. A new bridge will be available soon.',
      childBuilder: () => const SyriusErrorWidget(
          'The ZNN to wZNN bridge is unavailable. A new bridge will be available soon.'),
    );
  }
}
