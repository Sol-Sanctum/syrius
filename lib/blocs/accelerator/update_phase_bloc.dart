import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class UpdatePhaseBloc extends BaseBloc<AccountBlockTemplate?> {
  void updatePhase(
    Hash id,
    String name,
    String description,
    String url,
    double znnFundsNeeded,
    double qsrFundsNeeded,
    Address projectOwner,
  ) {
    try {
      addEvent(null);
      KeyPair blockSigningKeyPair = kKeyStore!.getKeyPair(
        kDefaultAddressList.indexOf(projectOwner.toString()),
      );
      AccountBlockTemplate transactionParams =
          zenon!.embedded.accelerator.updatePhase(
        id,
        name,
        description,
        url,
        AmountUtils.extractDecimals(
          znnFundsNeeded,
          znnDecimals,
        ),
        AmountUtils.extractDecimals(
          qsrFundsNeeded,
          qsrDecimals,
        ),
      );
      AccountBlockUtils.createAccountBlock(transactionParams, 'update phase',
              blockSigningKey: blockSigningKeyPair)
          .then(
        (block) => addEvent(block),
      )
          .onError(
        (error, stackTrace) {
          addError(error, stackTrace);
        },
      );
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}
