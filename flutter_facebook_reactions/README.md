# Flutter Facebook Reactions

A Flutter widget that mimics Facebook's social interactions bar, complete with Lottie animations and sound effects.

## Features

- Like button with long-press reaction picker.
- Animated emoji selection using Lottie.
- Sound effects for interactions (box open, focus, pick, close).
- Comment and Share buttons.
- Customizable callbacks.

## Usage

```dart
import 'package:flutter_facebook_reactions/flutter_facebook_reactions.dart';

FacebookSocialBar(
  currentReaction: _currentReaction, // ReactionType?
  onLikeTap: () {
    // Handle tap (toggle like)
  },
  onReactionSelected: (reaction) {
    setState(() => _currentReaction = reaction);
  },
  onCommentTap: () {
    // Handle comment tap
  },
  onShareTap: () {
    // Handle share tap
  },
  commentsCount: 10,
  sharesCount: 5,
)
```

## Assets

Ensure you include the package assets in your app configuration if needed, though usually automatic if defined in the package pubspec.

## License

MIT
