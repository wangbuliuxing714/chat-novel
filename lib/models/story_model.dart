import 'package:flutter/foundation.dart';

class StoryMessage {
  final String role;
  final String content;
  
  StoryMessage({
    required this.role,
    required this.content,
  });
  
  factory StoryMessage.fromJson(Map<String, dynamic> json) {
    return StoryMessage(
      role: json['role'],
      content: json['content'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }
}

class Story {
  final String id;
  final String title;
  final String coverPrompt;
  final String genre;
  final DateTime createdAt;
  final List<StoryChapter> chapters;
  final List<StoryMessage> chatHistory;
  
  Story({
    required this.id,
    required this.title,
    required this.coverPrompt,
    required this.genre,
    required this.createdAt,
    required this.chapters,
    required this.chatHistory,
  });
  
  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'],
      title: json['title'],
      coverPrompt: json['coverPrompt'],
      genre: json['genre'],
      createdAt: DateTime.parse(json['createdAt']),
      chapters: (json['chapters'] as List)
          .map((chapterJson) => StoryChapter.fromJson(chapterJson))
          .toList(),
      chatHistory: (json['chatHistory'] as List)
          .map((messageJson) => StoryMessage.fromJson(messageJson))
          .toList(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'coverPrompt': coverPrompt,
      'genre': genre,
      'createdAt': createdAt.toIso8601String(),
      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
      'chatHistory': chatHistory.map((message) => message.toJson()).toList(),
    };
  }
  
  Story copyWith({
    String? id,
    String? title,
    String? coverPrompt,
    String? genre,
    DateTime? createdAt,
    List<StoryChapter>? chapters,
    List<StoryMessage>? chatHistory,
  }) {
    return Story(
      id: id ?? this.id,
      title: title ?? this.title,
      coverPrompt: coverPrompt ?? this.coverPrompt,
      genre: genre ?? this.genre,
      createdAt: createdAt ?? this.createdAt,
      chapters: chapters ?? this.chapters,
      chatHistory: chatHistory ?? this.chatHistory,
    );
  }
}

class StoryChapter {
  final String content;
  final List<StoryChoice> choices;
  
  StoryChapter({
    required this.content,
    required this.choices,
  });
  
  factory StoryChapter.fromJson(Map<String, dynamic> json) {
    return StoryChapter(
      content: json['content'],
      choices: (json['choices'] as List)
          .map((choiceJson) => StoryChoice.fromJson(choiceJson))
          .toList(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'choices': choices.map((choice) => choice.toJson()).toList(),
    };
  }
}

class StoryChoice {
  final String text;
  
  StoryChoice({
    required this.text,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'text': text,
    };
  }
  
  factory StoryChoice.fromJson(Map<String, dynamic> json) {
    return StoryChoice(
      text: json['text'],
    );
  }
}

class StoryListModel extends ChangeNotifier {
  List<Story> _stories = [];
  
  List<Story> get stories => _stories;
  
  void addStory(Story story) {
    _stories.add(story);
    notifyListeners();
  }
  
  void updateStory(Story updatedStory) {
    final index = _stories.indexWhere((story) => story.id == updatedStory.id);
    if (index != -1) {
      _stories[index] = updatedStory;
      notifyListeners();
    }
  }
  
  void removeStory(String storyId) {
    _stories.removeWhere((story) => story.id == storyId);
    notifyListeners();
  }
  
  void loadStories(List<Story> stories) {
    _stories = stories;
    notifyListeners();
  }
} 