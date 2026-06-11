import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/product_provider.dart';
import '../../../shared/widgets/animations.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      setState(() {
        _query = _ctrl.text;
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(searchResultsProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'SEARCH',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 3),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search Zanny Collection...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _ctrl.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_query.isEmpty)
            Expanded(child: _SearchSuggestions())
          else
            Expanded(
              child: searchAsync.when(
                loading: () => const Center(
                  child: ZannyLoadingIndicator(size: 32, color: AppColors.textPrimary),
                ),
                error: (err, stack) => Center(
                  child: Text(
                    'Error: $err',
                    style: GoogleFonts.inter(color: AppColors.error),
                  ),
                ),
                data: (results) {
                  if (results.isEmpty) {
                    return _NoResults(query: _query);
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: results.length,
                    itemBuilder: (ctx, i) => _SearchResultCard(product: results[i]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchSuggestions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final categories = ProductCategory.all.take(6).toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'POPULAR CATEGORIES',
            style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((cat) => TactileButton(
              onTap: () => context.push('/collections/${cat.slug}'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border, width: 0.5),
                  color: AppColors.surface,
                ),
                child: Text(
                  cat.name,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Product product;
  const _SearchResultCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return FadeInSlide(
      child: TactileButton(
        onTap: () => context.push('/product/${product.id}'),
        child: Container(
          color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                color: AppColors.surfaceElevated,
                child: product.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.images.first,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => const Center(
                          child: ZannyLoadingIndicator(
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.image_outlined, color: AppColors.textMuted, size: 28),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image_outlined, color: AppColors.textMuted, size: 28),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('KES ${product.price.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),);
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('No results for "$query"',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Try a different search term',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
