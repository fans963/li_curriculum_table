import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationController extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final navigationControllerProvider =
    NotifierProvider<NavigationController, int>(NavigationController.new);
