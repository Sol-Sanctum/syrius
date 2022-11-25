import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/notifications_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/transfer/send_payment_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/transfer/transfer_widgets_balance_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/notification_type.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/wallet_notification.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/clipboard_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/available_balance.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/loading_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/send_payment_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/transfer_toggle_card_size_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/dialogs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/dropdown/addresses_dropdown.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/dropdown/coin_dropdown.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_field/amount_suffix_widgets.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_field/input_field.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/card_scaffold.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SendLargeCard extends StatefulWidget {
  final double? cardWidth;
  final bool? extendIcon;
  final VoidCallback? onCollapsePressed;
  final VoidCallback onOkBridgeWarningDialogPressed;

  const SendLargeCard({
    required this.onOkBridgeWarningDialogPressed,
    Key? key,
    this.cardWidth,
    this.extendIcon,
    this.onCollapsePressed,
  }) : super(key: key);

  @override
  _SendLargeCardState createState() => _SendLargeCardState();
}

class _SendLargeCardState extends State<SendLargeCard> {
  TextEditingController _recipientController = TextEditingController();
  TextEditingController _amountController = TextEditingController();
  TextEditingController _dataController = TextEditingController();

  GlobalKey<FormState> _recipientKey = GlobalKey();
  GlobalKey<FormState> _amountKey = GlobalKey();
  GlobalKey<FormState> _dataKey = GlobalKey();

  final GlobalKey<LoadingButtonState> _sendPaymentButtonKey = GlobalKey();

  final List<Token?> _tokensWithBalance = [];

  Token _selectedToken = kDualCoin.first;

  String? _selectedSelfAddress = kSelectedAddress;

  @override
  void initState() {
    super.initState();
    sl.get<TransferWidgetsBalanceBloc>().getBalanceForAllAddresses();
    _tokensWithBalance.addAll(kDualCoin);
  }

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Send',
      titleFontSize: Theme.of(context).textTheme.headline5!.fontSize,
      description: 'Manage sending funds',
      childBuilder: () => _getBalanceStreamBuilder(),
    );
  }

  Widget _getBalanceStreamBuilder() {
    return StreamBuilder<Map<String, AccountInfo>?>(
      stream: sl.get<TransferWidgetsBalanceBloc>().stream,
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        }
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            if (_tokensWithBalance.length == kDualCoin.length) {
              _addTokensWithBalance(snapshot.data![_selectedSelfAddress!]!);
            }
            return _getBody(
              context,
              snapshot.data![_selectedSelfAddress!]!,
            );
          }
          return const SyriusLoadingWidget();
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  Widget _getBody(BuildContext context, AccountInfo accountInfo) {
    return Container(
      margin: const EdgeInsets.only(
        left: 20.0,
        top: 20.0,
      ),
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 20.0),
            child: Form(
              key: _recipientKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: InputField(
                onChanged: (value) {
                  setState(() {});
                },
                controller: _recipientController,
                validator: (value) => InputValidators.checkAddress(value),
                suffixIcon: RawMaterialButton(
                  child: const Icon(
                    Icons.content_paste,
                    color: AppColors.darkHintTextColor,
                    size: 15.0,
                  ),
                  shape: const CircleBorder(),
                  onPressed: () {
                    ClipboardUtils.pasteToClipboard(context, (String value) {
                      _recipientController.text = value;
                      setState(() {});
                    });
                  },
                ),
                suffixIconConstraints: const BoxConstraints(
                  maxWidth: 45.0,
                  maxHeight: 20.0,
                ),
                hintText: 'Recipient Address',
              ),
            ),
          ),
          const SizedBox(
            height: 5.0,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
                    'Send from',
                    style: Theme.of(context).inputDecorationTheme.hintStyle,
                  ),
                ),
              ),
              Expanded(
                flex: 0,

                child: AvailableBalance(
                  _selectedToken,
                  accountInfo,
                  ),
              ),
              //),
              const SizedBox(
                width: 20.0,
              ),
            ],
          ),
          const SizedBox(
            height: 5.0,
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: _getDefaultAddressDropdown(),
              ),
              const SizedBox( width: 15),
              Expanded(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.only(right: 20.0),
                  child: Form(
                    key: _amountKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: InputField(
                      onChanged: (value) {
                        setState(() {});
                      },
                      inputFormatters: FormatUtils.getAmountTextInputFormatters(
                        _amountController.text,
                      ),
                      controller: _amountController,
                      validator: (value) => InputValidators.correctValue(
                        value,
                        accountInfo.getBalanceWithDecimals(
                          _selectedToken.tokenStandard,
                        ),
                        _selectedToken.decimals,
                      ),
                      suffixIcon: _getAmountSuffix(accountInfo),
                      hintText: 'Amount',
                    ),
                  ),
                ),
              ),
            ],
          ),
          kVerticalSpacing,
          Container(
            margin: const EdgeInsets.only(right: 20.0),
            child: Form(
              key: _dataKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: InputField(
                onChanged: (value) {
                  setState(() {});
                },
                validator: (value) => InputValidators.checkDataLength(value),
                controller: _dataController,
                suffixIcon: RawMaterialButton(
                  child: const Icon(
                    Icons.content_paste,
                    color: AppColors.darkHintTextColor,
                    size: 15.0,
                  ),
                  shape: const CircleBorder(),
                  onPressed: () {
                    ClipboardUtils.pasteToClipboard(context, (String value) {
                      _dataController.text = value;
                      setState(() {});
                    });
                  },
                ),
                suffixIconConstraints: const BoxConstraints(
                  maxWidth: 45.0,
                  maxHeight: 20.0,
                ),
                hintText: 'Message (optional)',
              ),
            ),
          ),
          const SizedBox( height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Container(
                  height: 40,
                  child: _getSendPaymentViewModel(accountInfo),
                ),
              ),
              Expanded(
                flex: 0,
                child: TransferToggleCardSizeButton(
                  onPressed: widget.onCollapsePressed,
                  iconData: Icons.navigate_before,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onSendPaymentPressed(
      SendPaymentBloc model,
      Address fromAddress,
      List<int> data
      ) async
  {
    var inputValidatorsInstance = InputValidators();
    if (!await inputValidatorsInstance.checkPlasma(fromAddress, data)) {
      _sendErrorNotification(
          "syrius error: transaction data exceeded PoW Plasma limit", true);
    }
    else {
      var _dialogText;
      if (_recipientKey.currentState!.validate() &&
          _amountKey.currentState!.validate()) {
        if (_dataController.text.isNotEmpty) {
          _dialogText = "Are you sure you want to transfer "
              "${_amountController.text} ${_selectedToken.symbol} to "
              "${AddressUtils.getLabel(_recipientController.text)} "
              "with a message \"${_dataController.text}\" ?";
        }
        else {
          _dialogText = "Are you sure you want to transfer "
              "${_amountController.text} ${_selectedToken.symbol} to "
              "${AddressUtils.getLabel(_recipientController.text)} ?";
        }
        if (Address.parse(_recipientController.text) == bridgeAddress) {
          showOkDialog(
            context: context,
            title: 'Send Payment',
            description: 'Use the form from the \'Bridge\' tab to swap coins',
            onActionButtonPressed: () {
              Navigator.pop(context);
              widget.onOkBridgeWarningDialogPressed();
            },
          );
        } else {
          showDialogWithNoAndYesOptions(
            context: context,
            title: 'Send Payment',
            description: _dialogText,
            onYesButtonPressed: () => _sendPayment(model),
          );
        }
      }
    }
  }

  Widget _getAmountSuffix(AccountInfo accountInfo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _getCoinDropdown(),
        const SizedBox(
          width: 5.0,
        ),
        AmountSuffixMaxWidget(
          onPressed: () => _onMaxPressed(accountInfo),
          context: context,
        ),
        const SizedBox(
          width: 15.0,
        ),
      ],
    );
  }

  void _sendPayment(SendPaymentBloc model) {
    Navigator.pop(context);
    _sendPaymentButtonKey.currentState?.animateForward();
    model.sendTransfer(
      fromAddress: _selectedSelfAddress,
      toAddress: _recipientController.text,
      amount: _amountController.text,
      data: utf8.encode(_dataController.text),
      token: _selectedToken,
    );
  }

  Widget _getDefaultAddressDropdown() {
    return AddressesDropdown(
      _selectedSelfAddress,
      (value) => setState(
        () {
          _selectedSelfAddress = value;
          _selectedToken = kDualCoin.first;
          _tokensWithBalance.clear();
          _tokensWithBalance.addAll(kDualCoin);
          sl.get<TransferWidgetsBalanceBloc>().getBalanceForAllAddresses();
        },
      ),
    );
  }

  Widget _getCoinDropdown() => CoinDropdown(
        _tokensWithBalance,
        _selectedToken,
        (value) {
          if (_selectedToken != value) {
            setState(
              () {
                _selectedToken = value!;
              },
            );
          }
        },
      );

  void _onMaxPressed(AccountInfo accountInfo) {
    num maxBalance = accountInfo.getBalanceWithDecimals(
      _selectedToken.tokenStandard,
    );

    if (_amountController.text.isEmpty ||
        _amountController.text.toNum() < maxBalance) {
      setState(() {
        _amountController.text = maxBalance.toString();
      });
    }
  }

  Widget _getSendPaymentViewModel(AccountInfo? accountInfo) {
    return ViewModelBuilder<SendPaymentBloc>.reactive(
      onModelReady: (model) {
        model.stream.listen(
          (event) {
            if (event is AccountBlockTemplate) {
              _sendConfirmationNotification();
              setState(() {
                _sendPaymentButtonKey.currentState?.animateReverse();
                _amountController = TextEditingController();
                _recipientController = TextEditingController();
                _dataController = TextEditingController();
                _amountKey = GlobalKey();
                _recipientKey = GlobalKey();
                _dataKey = GlobalKey();
              });
            }
          },
          onError: (error) {
            _sendPaymentButtonKey.currentState?.animateReverse();
            _sendErrorNotification(error);
          },
        );
      },
      builder: (_, model, __) => SendPaymentButton(
        onPressed: _hasBalance(accountInfo!) && _isInputValid(accountInfo)
            ? () => _onSendPaymentPressed(
                      model,
                      Address.parse(kSelectedAddress!),
                      utf8.encode(_dataController.text))
            : null,
        minimumSize: const Size(50.0, 48.0),
        key: _sendPaymentButtonKey,
      ),
      viewModelBuilder: () => SendPaymentBloc(),
    );
  }

  void _sendErrorNotification(error, [displayInNotification]) {
    var displayedMessage = 'Couldn\'t send ${_amountController.text} '
        '${_selectedToken.symbol} to ${_recipientController.text}';
    if (displayInNotification) {
      displayedMessage += ': ${error}';
    }
    NotificationUtils.sendNotificationError(
        error, displayedMessage
    );
  }

  void _sendConfirmationNotification() {
    sl.get<NotificationsBloc>().addNotification(
          WalletNotification(
            title: 'Sent ${_amountController.text} ${_selectedToken.symbol} '
                'to ${AddressUtils.getLabel(_recipientController.text)}',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details: 'Sent ${_amountController.text} ${_selectedToken.symbol} '
                'from ${AddressUtils.getLabel(_selectedSelfAddress!)} to ${AddressUtils.getLabel(_recipientController.text)}',
            type: NotificationType.paymentSent,
            id: null,
          ),
        );
  }

  bool _hasBalance(AccountInfo accountInfo) =>
      accountInfo.getBalanceWithDecimals(
        _selectedToken.tokenStandard,
      ) >
      0;

  void _addTokensWithBalance(AccountInfo accountInfo) {
    for (var balanceInfo in accountInfo.balanceInfoList!) {
      if (balanceInfo.balance! > 0 &&
          !_tokensWithBalance.contains(balanceInfo.token)) {
        _tokensWithBalance.add(balanceInfo.token);
      }
    }
  }

  bool _isInputValid(AccountInfo accountInfo) =>
      InputValidators.checkAddress(_recipientController.text) == null &&
      InputValidators.correctValue(
        _amountController.text,
        accountInfo.getBalanceWithDecimals(
          _selectedToken.tokenStandard,
        ),
        _selectedToken.decimals,
      ) == null &&
      InputValidators.checkDataLength(_dataController.text) == null;

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _dataController.dispose();
    super.dispose();
  }
}
