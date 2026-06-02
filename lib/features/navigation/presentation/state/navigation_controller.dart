import 'package:signals/signals.dart';

class NavigationController {
  final currentIndex = signal(0);

  void setIndex(int index) {
    currentIndex.value = index;
  }
}
