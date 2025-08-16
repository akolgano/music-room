import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;



class CustomSingleChildScrollView extends StatefulWidget {
  final Widget? child;
  final Axis scrollDirection;
  final bool reverse;
  final ScrollPhysics? physics;
  final EdgeInsets? padding;

  const CustomSingleChildScrollView({
    super.key,
    this.child,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.physics,
    this.padding,
  });

  @override
  State<CustomSingleChildScrollView> createState() => _CustomSingleChildScrollViewState();
}

class _CustomSingleChildScrollViewState extends State<CustomSingleChildScrollView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: kIsWeb,
      thickness: 12.0,
      radius: const Radius.circular(8.0),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: widget.scrollDirection,
        reverse: widget.reverse,
        physics: widget.physics,
        padding: widget.padding,
        child: widget.child,
      ),
    );
  }
}