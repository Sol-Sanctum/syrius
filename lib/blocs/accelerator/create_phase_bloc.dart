import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class CreatePhaseBloc extends BaseBloc<AccountBlockTemplate?> {
  Future<void> createPhase(
    Hash id,
    String name,
    String description,
    String url,
    int znnFundsNeeded,
    int qsrFundsNeeded,
    Address projectOwner,
  ) async {
    try {
      addEvent(null);
      KeyPair blockSigningKeyPair = kKeyStore!.getKeyPair(
        kDefaultAddressList.indexOf(projectOwner.toString()),
      );
      AccountBlockTemplate transactionParams =
          zenon!.embedded.accelerator.addPhase(
        id,
        name,
        description,
        url,
        znnFundsNeeded,
        qsrFundsNeeded,
      );
      AccountBlockUtils.createAccountBlock(transactionParams, 'create phase',
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
