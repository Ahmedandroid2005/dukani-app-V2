import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/store/platform_config.dart';
import '../../core/support/support_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _faqs = [
  ('كيف أضيف منتج جديد؟', 'من قائمة المنتجات اضغط على أيقونة + في أعلى الشاشة، ثم أدخل بيانات المنتج واحفظ.'),
  ('كيف أستعيد فاتورة معلّقة؟', 'من نقطة البيع اضغط على أيقونة الفواتير المعلّقة أعلى الشاشة، ثم اضغط استئناف على الفاتورة المطلوبة.'),
  ('هل يعمل التطبيق بدون إنترنت؟', 'نعم، يعمل دُكاني بالكامل بدون إنترنت ويحفظ عملياتك محليًا حتى تتم مزامنتها تلقائيًا عند عودة الاتصال.'),
  ('كيف أضيف موظفًا جديدًا وأحدد صلاحياته؟', 'من الإعدادات ← الموظفون والصلاحيات، اضغط على أيقونة إضافة موظف وحدد الدور والصلاحيات المناسبة.'),
];

String _formatMessageTime(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}';
}

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  void _send() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    ref.read(supportChatControllerProvider).send(text);
    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _contactSheet() async {
    final config = await fetchPlatformConfig();
    if (!mounted) return;
    final waDigits = config.supportWhatsapp.replaceAll(RegExp(r'[^0-9]'), '');

    showDukaniSheet(
      context,
      title: 'تواصل معنا',
      child: Column(
        children: [
          DukaniSheetAction(
            icon: LucideIcons.messageCircle,
            label: 'واتساب',
            color: DukaniColors.success,
            onTap: () async {
              Navigator.pop(context);
              if (waDigits.isEmpty) return;
              await launchUrl(Uri.parse('https://wa.me/$waDigits'), mode: LaunchMode.externalApplication);
            },
          ),
          DukaniSheetAction(
            icon: LucideIcons.phone,
            label: 'اتصال هاتفي',
            onTap: () async {
              Navigator.pop(context);
              if (waDigits.isEmpty) return;
              await launchUrl(Uri(scheme: 'tel', path: waDigits));
            },
          ),
          DukaniSheetAction(
            icon: LucideIcons.mail,
            label: 'البريد الإلكتروني',
            onTap: () async {
              Navigator.pop(context);
              await launchUrl(Uri(scheme: 'mailto', path: config.supportEmail));
            },
          ),
        ],
      ),
    );
  }

  void _faqSheet() {
    showDukaniSheet(
      context,
      title: 'الأسئلة الشائعة',
      child: Column(
        children: [
          for (final (q, a) in _faqs) ...[
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(q, style: Theme.of(context).textTheme.titleSmall),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [Align(alignment: Alignment.centerRight, child: Text(a, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.ink500)))],
            ),
            if (q != _faqs.last.$1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(supportChatProvider);
    ref.listen(supportChatProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      appBar: DukaniAppBar(
        title: 'الدعم الفني',
        actions: [
          DukaniIconAction(icon: LucideIcons.helpCircle, onTap: _faqSheet),
          DukaniIconAction(icon: LucideIcons.headset, onTap: _contactSheet),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const DukaniEmptyState(title: 'تعذّر تحميل المحادثة', message: 'تأكد من الاتصال بالإنترنت وحاول تاني', icon: LucideIcons.wifiOff),
              data: (messages) {
                if (messages.isEmpty) {
                  return const DukaniEmptyState(
                    title: 'ابدأ محادثة مع فريق الدعم',
                    message: 'اكتب رسالتك بالأسفل وسيرد عليك فريق دُكاني في أقرب وقت',
                    icon: LucideIcons.messageCircle,
                  );
                }
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(DukaniSpacing.lg),
                  itemCount: messages.length,
                  itemBuilder: (context, i) => _ChatBubble(message: messages[i]),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, DukaniSpacing.sm, DukaniSpacing.lg, DukaniSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: DukaniTextField(hint: 'اكتب رسالتك...', controller: _messageController, onSubmitted: (_) => _send()),
                  ),
                  const SizedBox(width: DukaniSpacing.sm),
                  Material(
                    color: DukaniColors.forest700,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _send,
                      child: const Padding(padding: EdgeInsets.all(14), child: Icon(LucideIcons.send, color: Colors.white, size: 20)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final SupportChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.fromMerchant;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        margin: const EdgeInsets.only(bottom: DukaniSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? DukaniColors.forest700 : DukaniColors.forest50,
          borderRadius: BorderRadius.only(
            topRight: const Radius.circular(DukaniRadii.md),
            topLeft: const Radius.circular(DukaniRadii.md),
            bottomRight: Radius.circular(mine ? 2 : DukaniRadii.md),
            bottomLeft: Radius.circular(mine ? DukaniRadii.md : 2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine) ...[
              Text('فريق دُكاني', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.forest600, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
            ],
            Text(message.text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: mine ? Colors.white : null)),
            const SizedBox(height: 4),
            Text(
              _formatMessageTime(message.sentAt),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: mine ? Colors.white70 : DukaniColors.ink300),
            ),
          ],
        ),
      ),
    );
  }
}
