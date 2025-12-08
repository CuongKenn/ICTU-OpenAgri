import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/chatbot_models.dart';
import '../viewmodels/chatbot_viewmodel.dart';

class ChatbotOverlay extends StatefulWidget {
  const ChatbotOverlay({super.key});

  @override
  State<ChatbotOverlay> createState() => _ChatbotOverlayState();
}

class _ChatbotOverlayState extends State<ChatbotOverlay>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatbotViewModel>(
      builder: (context, viewModel, child) {
        final mediaQuery = MediaQuery.of(context);
        final isCompact = mediaQuery.size.width < 600;
        final panelWidth = isCompact
            ? mediaQuery.size.width - 32
            : math.min(380.0, mediaQuery.size.width * 0.35);
        final panelBottom = mediaQuery.padding.bottom + 90;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              right: 20,
              bottom: viewModel.isPanelOpen ? panelBottom : -(mediaQuery.size.height),
              child: Material(
                elevation: 16,
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: panelWidth,
                  height: isCompact ? mediaQuery.size.height * 0.72 : 540,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: const Color(0xFF101220).withOpacity(0.96),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x44000000),
                        blurRadius: 24,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      children: [
                        _buildHeader(context, viewModel),
                        if (viewModel.error != null)
                          _buildErrorBanner(context, viewModel),
                        Expanded(
                          child: _ChatScrollArea(viewModel: viewModel),
                        ),
                        _buildInputArea(context, viewModel),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: mediaQuery.padding.bottom + 20,
              child: _ChatbotFab(
                isOpen: viewModel.isPanelOpen,
                onTap: () {
                  viewModel.togglePanel();
                  if (viewModel.isPanelOpen) {
                    Future.delayed(const Duration(milliseconds: 220), () {
                      if (mounted) {
                        FocusScope.of(context).requestFocus(_focusNode);
                      }
                    });
                  } else {
                    _controller.clear();
                    _focusNode.unfocus();
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ChatbotViewModel viewModel) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OpenAgri Companion',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Powered by Gemini · Chuyên gia cây trồng',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: viewModel.isPanelOpen ? 'Thu gọn' : 'Mở trợ lý',
            child: InkWell(
              onTap: viewModel.closePanel,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, ChatbotViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF87171),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              viewModel.error!,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: viewModel.clearError,
            child: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, ChatbotViewModel viewModel) {
    return Container(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        bottom: 18 + MediaQuery.of(context).padding.bottom,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C2C),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF22D3EE),
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: _CustomTextInput(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: (_) => viewModel.clearError(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF22D3EE), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4422D3EE),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: viewModel.isSending
                  ? null
                  : () {
                      final text = _controller.text.trim();
                      if (text.isEmpty) {
                        return;
                      }
                      viewModel.sendMessage(text).then((_) {
                        if (mounted) {
                          _controller.clear();
                        }
                      });
                    },
              icon: viewModel.isSending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomTextInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _CustomTextInput({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  State<_CustomTextInput> createState() => _CustomTextInputState();
}

class _CustomTextInputState extends State<_CustomTextInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChange);
  }

  void _handleChange() {
    widget.onChanged(widget.controller.text);
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: EdgeInsets.zero,
          isDense: true,
          hintStyle: const TextStyle(
            color: Color(0xFF999999),
            fontSize: 15,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
      ),
      child: Stack(
        children: [
          // Material TextField - will render text properly
          TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            minLines: 1,
            maxLines: 4,
            onChanged: widget.onChanged,
            style: const TextStyle(
              color: Color(0xFF000000),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
              height: 1.6,
              letterSpacing: 0.3,
            ),
            cursorColor: const Color(0xFF22D3EE),
            decoration: InputDecoration(
              hintText: 'Gõ câu hỏi...',
              hintStyle: const TextStyle(
                color: Color(0xFF999999),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
              filled: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatbotFab extends StatelessWidget {
  const _ChatbotFab({required this.isOpen, required this.onTap});

  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 220),
        scale: isOpen ? 0.9 : 1.0,
        child: Container(
          height: 68,
          width: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x338B5CF6),
                blurRadius: 18,
                offset: Offset(0, 10),
              )
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'AI',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF6366F1),
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatScrollArea extends StatelessWidget {
  const _ChatScrollArea({required this.viewModel});

  final ChatbotViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final messages = viewModel.messages;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: messages.length,
      reverse: true,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        final isUser = message.role == ChatMessageRole.user;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isUser
                      ? const Color(0xFF22D3EE)
                      : Colors.white.withOpacity(0.08),
                  gradient: isUser
                      ? const LinearGradient(
                          colors: [Color(0xFF38BDF8), Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft:
                        Radius.circular(isUser ? 18 : 4),
                    bottomRight:
                        Radius.circular(isUser ? 4 : 18),
                  ),
                  border: isUser
                      ? null
                      : Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: isUser
                      ? const [
                          BoxShadow(
                            color: Color(0x3322D3EE),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: GoogleFonts.inter(
                          color: isUser ? Colors.white : Colors.white,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      if (message.tips != null && message.tips!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gợi ý chuyên gia',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.7),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: message.tips!
                                    .map(
                                      (tip) => _TipChip(tip: tip),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TipChip extends StatelessWidget {
  const _TipChip({required this.tip});

  final ChatTip tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0EA5E9).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.2)),
      ),
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tip.title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tip.summary,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
