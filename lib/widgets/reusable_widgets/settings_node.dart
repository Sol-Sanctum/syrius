import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/node_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/material_icon_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/outlined_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/settings_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/dialogs/dialogs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/icons/standard_tooltip_icon.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_field/input_field.dart';

class SettingsNode extends StatefulWidget {
  final String node;
  final void Function(String?) onNodePressed;
  final VoidCallback onChangedOrDeletedNode;

  const SettingsNode({
    required this.node,
    required this.onNodePressed,
    required this.onChangedOrDeletedNode,
    Key? key,
  }) : super(key: key);

  @override
  _SettingsNodeState createState() => _SettingsNodeState();
}

class _SettingsNodeState extends State<SettingsNode> {
  bool _editable = false;

  final TextEditingController _nodeController = TextEditingController();

  final GlobalKey<MyOutlinedButtonState> _changeButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _nodeController.text = widget.node;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 5.0,
      ),
      child: _editable ? _getNodeInputField() : _getNode(context),
    );
  }

  Row _getNode(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(
              10.0,
            ),
            onTap: () => widget.onNodePressed(widget.node),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nodeController.text,
                    style: Theme.of(context).textTheme.bodyText1!.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodyText1!
                              .color!
                              .withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(
          width: 5.0,
        ),
        Visibility(
          visible: widget.node.contains("Embedded"),
          child: const StandardTooltipIcon(
            'The Embedded Node can take several hours to fully sync with the network',
          ),
        ),
        const SizedBox(
          width: 5.0,
        ),
        Visibility(
          visible: !kDefaultNodes.contains(widget.node),
          child: MaterialIconButton(
            iconData: Icons.edit,
            onPressed: () {
              setState(() {
                _editable = true;
              });
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(
          width: 5.0,
        ),
        Visibility(
          visible: !kDefaultNodes.contains(widget.node),
          child: MaterialIconButton(
            onPressed: () {
              showDialogWithNoAndYesOptions(
                context: context,
                title: 'Node Management',
                description: 'Are you sure you want to delete '
                    '${widget.node} from the list of nodes? This action '
                    'can\'t be undone.',
                onYesButtonPressed: () {
                  _deleteNodeFromDb(widget.node);
                },
              );
            },
            iconData: Icons.delete_forever,
          ),
        ),
      ],
    );
  }

  Widget _getNodeInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40.0,
                child: InputField(
                  controller: _nodeController,
                  onSubmitted: (value) {
                    if (_nodeController.text != widget.node) {
                      _onChangeButtonPressed();
                    }
                  },
                  onChanged: (value) {
                    setState(() {});
                  },
                  inputtedTextStyle:
                      Theme.of(context).textTheme.bodyText2!.copyWith(
                            color: AppColors.znnColor,
                          ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  contentLeftPadding: 5.0,
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.znnColor),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(
                      color: AppColors.errorColor,
                      width: 2.0,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(
                      color: AppColors.errorColor,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 15.0,
            ),
            SettingsButton(
              onPressed: _nodeController.text != widget.node
                  ? _onChangeButtonPressed
                  : null,
              text: 'Change',
              key: _changeButtonKey,
            ),
            MaterialIconButton(
              onPressed: () {
                setState(() {
                  _nodeController.text = widget.node;
                  _editable = false;
                });
              },
              iconData: Icons.clear,
            ),
          ],
        ),
      ],
    );
  }

  void _onChangeButtonPressed() async {
    try {
      _changeButtonKey.currentState!.showLoadingIndicator(true);
      if (_nodeController.text.isNotEmpty &&
          _nodeController.text.length <= kAddressLabelMaxLength &&
          ![...kDefaultNodes, ...kDbNodes].contains(_nodeController.text)) {
        Box<String> nodesBox = await Hive.openBox<String>(kNodesBox);
        dynamic key = nodesBox.keys.firstWhere(
          (key) => nodesBox.get(key) == widget.node,
        );
        await nodesBox.put(key, _nodeController.text);
        await NodeUtils.loadDbNodes(context);
        setState(() {
          _editable = false;
        });
      } else if (_nodeController.text.isEmpty) {
        NotificationUtils.sendNotificationError(
          'Node address can\'t be empty',
          'Node error',
        );
      } else if (_nodeController.text.length > kAddressLabelMaxLength) {
        NotificationUtils.sendNotificationError(
          'The node ${_nodeController.text} is ${_nodeController.text.length} '
              'characters long, which is more than the $kAddressLabelMaxLength limit.',
          'The node has more than $kAddressLabelMaxLength characters',
        );
      } else {
        NotificationUtils.sendNotificationError(
          'Node ${_nodeController.text} already exists in the database',
          'Node already exists',
        );
      }
    } catch (e) {
      NotificationUtils.sendNotificationError(
        e,
        'Something went wrong',
      );
    } finally {
      _changeButtonKey.currentState!.showLoadingIndicator(false);
    }
  }

  Future<void> _deleteNodeFromDb(String node) async {
    try {
      if (!Hive.isBoxOpen(kNodesBox)) {
        await Hive.openBox<String>(kNodesBox);
      }
      Box<String> nodesBox = Hive.box<String>(kNodesBox);
      var nodeKey = nodesBox.keys.firstWhere(
        (key) => nodesBox.get(key) == node,
      );
      await nodesBox.delete(nodeKey);
      kDbNodes.remove(node);
      Navigator.pop(context);
      widget.onChangedOrDeletedNode();
    } catch (e) {
      NotificationUtils.sendNotificationError(
        e,
        'Error during deleting node $node from the database',
      );
    }
  }

  @override
  void dispose() {
    _nodeController.dispose();
    super.dispose();
  }
}
