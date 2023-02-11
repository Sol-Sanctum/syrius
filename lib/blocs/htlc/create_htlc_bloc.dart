import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class CreateHtlcBloc extends BaseBloc<AccountBlockTemplate?> {
  void createHtlc({
    required Address timeLocked,
    required Token token,
    required String amount,
    required Address hashLocked,
    required int expirationTime,
    required int hashType,
    required int keyMaxSize,
    required List<int> hashLock,
  }) {
    try {
      addEvent(null);
      AccountBlockTemplate transactionParams = zenon!.embedded.htlc.create(
        token,
        amount.toNum().extractDecimals(token.decimals),
        hashLocked,
        expirationTime,
        hashType,
        keyMaxSize,
        hashLock,
      );
      KeyPair blockSigningKeyPair = kKeyStore!.getKeyPair(
        kDefaultAddressList.indexOf(timeLocked.toString()),
      );
      AccountBlockUtils.createAccountBlock(transactionParams, 'create swap',
              blockSigningKey: blockSigningKeyPair, waitForRequiredPlasma: true)
          .then(
        (response) {
          AddressUtils.refreshBalance();
          addEvent(response);
        },
      ).onError(
        (error, stackTrace) {
          addError(error.toString());
        },
      );
    } catch (e) {
      addError(e);
    }
  }
}
