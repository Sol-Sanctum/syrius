import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/loading_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/send_payment_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/transfer_toggle_card_size_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/dialogs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/dropdown/coin_dropdown.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_field/amount_suffix_widgets.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_field/input_field.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/card_scaffold.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SendMediumCard extends StatefulWidget {
  final VoidCallback onExpandClicked;
  final VoidCallback onOkBridgeWarningDialogPressed;

  const SendMediumCard({
    required this.onExpandClicked,
    required this.onOkBridgeWarningDialogPressed,
    Key? key,
  }) : super(key: key);

  @override
  _SendMediumCardState createState() => _SendMediumCardState();
}

class _SendMediumCardState extends State<SendMediumCard> {
  TextEditingController _recipientController = TextEditingController();
  TextEditingController _amountController = TextEditingController();
  TextEditingController _dataController = TextEditingController();

  GlobalKey<FormState> _recipientKey = GlobalKey();
  GlobalKey<FormState> _amountKey = GlobalKey();
  GlobalKey<FormState> _dataKey = GlobalKey();

  Token _selectedToken = kDualCoin.first;

  final List<Token?> _tokensWithBalance = [];

  final FocusNode _recipientFocusNode = FocusNode();
  final FocusNode _dataFocusNode = FocusNode();

  final GlobalKey<LoadingButtonState> _sendPaymentButtonKey = GlobalKey();

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
              _addTokensWithBalance(snapshot.data![kSelectedAddress!]!);
            }
            return _getBody(
              context,
              snapshot.data![kSelectedAddress!]!,
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
                thisNode: _recipientFocusNode,
                validator: (value) => InputValidators.checkAddress(value),
                controller: _recipientController,
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
          kVerticalSpacing,
          Container(
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
                validator: (value) => InputValidators.correctValue(
                  value,
                  accountInfo.getBalanceWithDecimals(
                    _selectedToken.tokenStandard,
                  ),
                  _selectedToken.decimals,
                ),
                controller: _amountController,
                suffixIcon: _getAmountSuffix(accountInfo),
                hintText: 'Amount',
              ),
            ),
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
                thisNode: _dataFocusNode,
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
          kVerticalSpacing,
          Row(
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Container(
                  child: _getSendPaymentViewModel(accountInfo),
                ),
              ),
              Expanded(
                flex: 0,
                child: TransferToggleCardSizeButton(
                    onPressed: widget.onExpandClicked,
                    iconData: Icons.navigate_next,
                  ),
              ),
            ],
          )
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
            description:
            'Use the form from the Bridge tab in order to perform the swap',
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

  void _sendPayment(SendPaymentBloc model) {
    Navigator.pop(context);
    _sendPaymentButtonKey.currentState?.animateForward();
    model.sendTransfer(
      fromAddress: kSelectedAddress,
      toAddress: _recipientController.text,
      amount: _amountController.text,
      data: utf8.encode(_dataController.text),
      token: _selectedToken,
    );
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
      fireOnModelReadyOnce: true,
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
                'from ${AddressUtils.getLabel(kSelectedAddress!)} to ${AddressUtils.getLabel(_recipientController.text)}',
            type: NotificationType.paymentSent,
            id: null,
          ),
        );
  }

  bool _hasBalance(AccountInfo accountInfo) =>
      accountInfo.getBalance(
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
