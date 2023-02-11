import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/dropdown/coin_dropdown.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_field/amount_suffix_widgets.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_field/input_field.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AmountInputField extends StatefulWidget {
  final TextEditingController controller;
  final AccountInfo accountInfo;
  final void Function(Token, bool)? onChanged;
  final double? valuePadding;
  final Color? textColor;
  final Token? initialToken;

  const AmountInputField({
    required this.controller,
    required this.accountInfo,
    this.onChanged,
    this.valuePadding,
    this.textColor,
    this.initialToken,
    Key? key,
  }) : super(key: key);

  @override
  State createState() {
    return _AmountInputFieldState();
  }
}

class _AmountInputFieldState extends State<AmountInputField> {
  final List<Token?> _tokensWithBalance = [];
  Token? _selectedToken;
  bool valid = false;

  @override
  void initState() {
    super.initState();
    _tokensWithBalance.addAll(kDualCoin);
    _addTokensWithBalance();
    _selectedToken = widget.initialToken ?? kDualCoin.first;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.key,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: InputField(
        onChanged: (value) {
          setState(() {});
        },
        inputFormatters: FormatUtils.getAmountTextInputFormatters(
          widget.controller.text,
        ),
        validator: (value) => InputValidators.correctValue(
          value,
          widget.accountInfo.getBalanceWithDecimals(
            _selectedToken!.tokenStandard,
          ),
          _selectedToken!.decimals,
        ),
        controller: widget.controller,
        suffixIcon: _getAmountSuffix(),
        hintText: 'Amount',
      ),
      onChanged: () => (widget.onChanged != null)
          ? widget.onChanged!(_selectedToken!, (_isInputValid()) ? true : false)
          : null,
    );
  }

  Widget _getAmountSuffix() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _getCoinDropdown(),
        const SizedBox(
          width: 5.0,
        ),
        AmountSuffixMaxWidget(
          onPressed: () => _onMaxPressed(),
          context: context,
        ),
        const SizedBox(
          width: 5.0,
        ),
      ],
    );
  }

  void _onMaxPressed() => setState(() {
        num maxBalance = widget.accountInfo.getBalanceWithDecimals(
          _selectedToken!.tokenStandard,
        );
        widget.controller.text = maxBalance.toString();
      });

  Widget _getCoinDropdown() => CoinDropdown(
        _tokensWithBalance,
        _selectedToken!,
        (value) {
          if (_selectedToken != value) {
            setState(
              () {
                _selectedToken = value!;
                _isInputValid();
                widget.onChanged!(_selectedToken!, _isInputValid());
              },
            );
          }
        },
      );

  void _addTokensWithBalance() {
    for (var balanceInfo in widget.accountInfo.balanceInfoList!) {
      if (balanceInfo.balance! > 0 &&
          !_tokensWithBalance.contains(balanceInfo.token)) {
        _tokensWithBalance.add(balanceInfo.token);
      }
    }
  }

  bool _isInputValid() =>
      InputValidators.correctValue(
        widget.controller.text,
        widget.accountInfo.getBalanceWithDecimals(
          _selectedToken!.tokenStandard,
        ),
        _selectedToken!.decimals,
      ) ==
      null;

  @override
  void dispose() {
    super.dispose();
  }
}
