class FaqModel {
  final String id;
  final String question;
  final String answer;
  final String category;
  final int order;

  FaqModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'answer': answer,
      'category': category,
      'order': order,
    };
  }

  factory FaqModel.fromMap(String id, Map<String, dynamic> map) {
    return FaqModel(
      id: id,
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      category: map['category'] ?? 'General',
      order: map['order'] ?? 0,
    );
  }
}
