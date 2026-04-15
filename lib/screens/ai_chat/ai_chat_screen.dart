import 'package:flutter/material.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  late TextEditingController _messageController;
  List<Map<String, dynamic>> messages = [
    {
      'text': 'السلام عليكم، أنا مساعدتك الصحية. كيف يمكنني مساعدتك اليوم؟',
      'isUser': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الدعم الذكي'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Align(
                  alignment: message['isUser']
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: message['isUser']
                          ? const Color(0xFFE91E63)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      message['text'],
                      style: TextStyle(
                        color: message['isUser'] ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]\!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'اكتبي رسالتك...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    if (_messageController.text.isNotEmpty) {
                      setState(() {
                        messages.add({
                          'text': _messageController.text,
                          'isUser': true,
                        });
                        messages.add({
                          'text':
                              'شكراً على سؤالك. هذا رد آلي حالياً. يمكنك الاتصال بطبيبك للحصول على استشارة متخصصة.',
                          'isUser': false,
                        });
                        _messageController.clear();
                      });
                    }
                  },
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
