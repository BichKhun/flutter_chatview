/*
 * Copyright (c) 2022 Simform Solutions
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
import 'package:chat/chat.dart';
import 'package:flutter/material.dart';

import 'package:chatview/src/models/models.dart';
import 'package:logic_module/extension/int_extension.dart';
import 'package:logic_module/utils/emotions_manager.dart';

import '../utils/constants/constants.dart';
import 'link_preview.dart';
import 'reaction_widget.dart';

class TextMessageView extends StatelessWidget {
  TextMessageView({
    Key? key,
    required this.isMessageBySender,
    required this.message,
    this.chatBubbleMaxWidth,
    this.inComingChatBubbleConfig,
    this.outgoingChatBubbleConfig,
    this.messageReactionConfig,
    this.highlightMessage = false,
    this.highlightColor,
  }) : super(key: key);

  /// Represents current message is sent by current user.
  final bool isMessageBySender;

  /// Provides message instance of chat.
  final MessageModel message;

  /// Allow users to give max width of chat bubble.
  final double? chatBubbleMaxWidth;

  /// Provides configuration of chat bubble appearance from other user of chat.
  final ChatBubble? inComingChatBubbleConfig;

  /// Provides configuration of chat bubble appearance from current user of chat.
  final ChatBubble? outgoingChatBubbleConfig;

  /// Provides configuration of reaction appearance in chat bubble.
  final MessageReactionConfiguration? messageReactionConfig;

  /// Represents message should highlight.
  final bool highlightMessage;

  /// Allow user to set color of highlighted message.
  final Color? highlightColor;

  final FocusNode? focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final textMessage = message.message;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 气泡背景
        Positioned(
            left: isMessageBySender ? null : (9 - 10).px,
            right: isMessageBySender ? (9 - 10).px : null,
            top: 2.px,
            child: Image.asset(_bubbleBackgroundImageUrl, package: 'chatview')),
        Container(
            // constraints: BoxConstraints(
            //     maxWidth: chatBubbleMaxWidth ??
            //         MediaQuery.of(context).size.width * 0.75),
            margin: EdgeInsets.fromLTRB(isMessageBySender ? 116.px : 9.px, 2.px,
                isMessageBySender ? 9.px : 116.px, 8.px),
            padding: _padding ??
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
            decoration: BoxDecoration(
              color: highlightMessage ? highlightColor : _color,
              borderRadius: _borderRadius(textMessage),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GestureDetector(
                onTap: () => focusNode?.unfocus(),
                child: assembledMesageContents(textTheme),
              ),
              if (message.reaction.reactions.isNotEmpty)
                Padding(
                    padding: EdgeInsets.only(top: 8.px),
                    child: ReactionWidget(
                      key: key,
                      isMessageBySender: isMessageBySender,
                      reaction: message.reaction,
                      messageReactionConfig: messageReactionConfig,
                    ))
            ])),
      ],
    );
  }

  EdgeInsetsGeometry? get _padding => isMessageBySender
      ? outgoingChatBubbleConfig?.padding
      : inComingChatBubbleConfig?.padding;

  EdgeInsetsGeometry? get _margin => isMessageBySender
      ? outgoingChatBubbleConfig?.margin
      : inComingChatBubbleConfig?.margin;

  LinkPreviewConfiguration? get _linkPreviewConfig => isMessageBySender
      ? outgoingChatBubbleConfig?.linkPreviewConfig
      : inComingChatBubbleConfig?.linkPreviewConfig;

  TextStyle? get _textStyle => isMessageBySender
      ? outgoingChatBubbleConfig?.textStyle
      : inComingChatBubbleConfig?.textStyle;

  BorderRadiusGeometry _borderRadius(String message) => isMessageBySender
      ? outgoingChatBubbleConfig?.borderRadius ??
          (message.length < 37
              ? BorderRadius.circular(replyBorderRadius1)
              : BorderRadius.circular(replyBorderRadius2))
      : inComingChatBubbleConfig?.borderRadius ??
          (message.length < 29
              ? BorderRadius.circular(replyBorderRadius1)
              : BorderRadius.circular(replyBorderRadius2));

  Color get _color => isMessageBySender
      ? outgoingChatBubbleConfig?.color ?? Colors.purple
      : inComingChatBubbleConfig?.color ?? Colors.grey.shade500;

  String get _bubbleBackgroundImageUrl => isMessageBySender
      ? 'images/msg_corner_blue_r.png'
      : 'images/msg_corner_grey_l.png';

  SelectableText assembledMesageContents(TextTheme textTheme) {
    final style = _textStyle ??
        textTheme.bodyMedium!.copyWith(
          color: Colors.white,
          fontSize: 16,
        );
    List<InlineSpan> spans = [];
    for (final content in message.contents) {
      if (content.contentType == MessageContentType.text) {
        final textContont = content as MessageContentText;
        spans.add(TextSpan(text: textContont.text, style: style));
      } else if (content.contentType == MessageContentType.face) {
        final faceContent = content as MessageContentFace;
        final emotionName = '[${faceContent.name}]';
        final emotionItem =
            EmotionsManager().fetchEmotionItemWithName(emotionName);
        final emotionUrl = emotionItem?.iconPng ?? '';
        if (emotionUrl.isNotEmpty) {
          final emotionSpan = WidgetSpan(
              child: Image.asset(emotionUrl,
                  fit: BoxFit.fitWidth, width: 30, height: 30),
              alignment: PlaceholderAlignment.middle);
          spans.add(emotionSpan);
        } else {
          spans.add(TextSpan(text: emotionName, style: style));
        }
      } else if (content.contentType == MessageContentType.href) {
        final hrefContent = content as MessageContentHref;
        final widgetSpan = WidgetSpan(
            child: LinkPreview(
          linkPreviewConfig: _linkPreviewConfig,
          url: hrefContent.text,
        ));
        spans.add(widgetSpan);
      } else if (content.contentType == MessageContentType.reply) {
        final reply = content as MessageContentReply;
        final replyTxt = reply.generateReplyBlockStr();
        final replyWidget = Container(
          margin: const EdgeInsets.only(bottom: 5),
          color: const Color(0xfffdfeff),
          padding: const EdgeInsets.all(6),
          child: Text(
            replyTxt,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Color(0xff959ea6), fontSize: 13, height: 1.5),
          ),
        );
        spans.add(WidgetSpan(
            child: replyWidget,
            alignment: PlaceholderAlignment.middle,
            baseline: TextBaseline.ideographic));
      } else if (content.contentType == MessageContentType.custom) {
        final customContent = content as MessageContentCustom;
        if (messageContentBuilderManager.messageContentBuilders.keys
            .contains(customContent.customType)) {
          final builder = messageContentBuilderManager
              .messageContentBuilders[customContent.customType];
          final widgetSpan =
              builder?.buildMessageBubbleWidgetSpan(customContent);
          if (widgetSpan != null) {
            spans.add(widgetSpan);
          }
        }
      }
    }
    return SelectableText.rich(
      TextSpan(children: spans),
      focusNode: focusNode,
      contextMenuBuilder: (context, editableTextState) {
        return _buildContextMenu(context, editableTextState);
      },
    );
  }

  Widget _buildContextMenu(BuildContext context, EditableTextState state) {
    final buttonItems = state.contextMenuButtonItems;
    final selectAllButton = ContextMenuButtonItem(
        onPressed: () {
          state.selectAll(SelectionChangedCause.tap);
          state.hideToolbar();
        },
        type: ContextMenuButtonType.selectAll);
    buttonItems.add(selectAllButton);
    return AdaptiveTextSelectionToolbar.buttonItems(
        buttonItems: buttonItems, anchors: state.contextMenuAnchors);
  }

  void showPopupMenu(BuildContext context) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final selectionMenuItems = [
      const PopupMenuItem(
        value: 'Copy',
        child: Text('Copy'),
      ),
      const PopupMenuItem(
        value: 'Paste',
        child: Text('Paste'),
      ),
    ];

    showMenu(
      context: context,
      items: selectionMenuItems,
      position: RelativeRect.fromRect(
        Rect.fromPoints(
          Offset.zero,
          const Offset(100, 100),
        ),
        Offset.zero & overlay.size,
      ),
    ).then((value) {
      if (value == 'Copy') {
        // 执行复制操作
        print('Copy selected');
      } else if (value == 'Paste') {
        // 执行粘贴操作
        print('Paste selected');
      }
    });
  }
}
