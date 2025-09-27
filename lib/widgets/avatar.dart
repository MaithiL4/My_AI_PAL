import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Avatar extends StatelessWidget {
  const Avatar({super.key, this.url, this.radius = 20});

  final String? url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final placeholder = CircleAvatar(
      radius: radius,
      child: const CircularProgressIndicator(),
    );

    if (url != null && url!.isNotEmpty) {
      if (url!.endsWith('.svg')) {
        return CircleAvatar(
          radius: radius,
          child: ClipOval(
            child: SvgPicture.network(
              url!,
              placeholderBuilder: (context) => placeholder,
            ),
          ),
        );
      } else {
        return CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(url!),
        );
      }
    } else {
      return CircleAvatar(
        radius: radius,
        child: ClipOval(
          child: SvgPicture.network(
            'https://api.dicebear.com/7.x/adventurer/svg?seed=0',
            placeholderBuilder: (context) => placeholder,
          ),
        ),
      );
    }
  }
}
