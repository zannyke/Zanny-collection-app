import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../providers/cart_provider.dart';

/// Premium Zanny app bar — reusable across all screens
class ZannyAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;
  final bool showLogo;
  final bool showCart;
  final bool showBack;
  final List<Widget>? extraActions;

  const ZannyAppBar({
    super.key,
    this.title,
    this.showLogo = false,
    this.showCart = true,
    this.showBack = false,
    this.extraActions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);

    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            )
          : null,
      automaticallyImplyLeading: showBack,
      centerTitle: true,
      title: showLogo
          ? Text(
              'ZANNY',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 6, color: AppColors.textPrimary,
              ),
            )
          : title != null
              ? Text(
                  title!.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 3, color: AppColors.textPrimary),
                )
              : null,
      actions: [
        if (extraActions != null) ...extraActions!,
        if (showCart)
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.textPrimary),
                onPressed: () => context.push('/cart'),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(color: AppColors.textPrimary, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        cartCount > 9 ? '9+' : '$cartCount',
                        style: const TextStyle(color: AppColors.background, fontSize: 9, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: AppColors.border),
      ),
    );
  }
}
