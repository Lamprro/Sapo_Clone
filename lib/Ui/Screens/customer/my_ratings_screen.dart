import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Providers/rating_provider.dart';
import '../../Widgets/rating_display_widget.dart';

class MyRatingsScreen extends StatefulWidget {
  const MyRatingsScreen({super.key});

  @override
  State<MyRatingsScreen> createState() => _MyRatingsScreenState();
}

class _MyRatingsScreenState extends State<MyRatingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RatingProvider>().loadUserRatings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ratingProvider = context.watch<RatingProvider>();
    final ratings = ratingProvider.userRatings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Ratings'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<RatingProvider>().loadUserRatings(),
        child: ratingProvider.isLoading && ratings.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ratingProvider.errorMessage != null && ratings.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 160),
                      Center(child: Text(ratingProvider.errorMessage!)),
                    ],
                  )
                : ratings.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 160),
                          Center(child: Text('No ratings yet')),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: ratings.length,
                        itemBuilder: (context, index) {
                          final rating = ratings[index];
                          return Dismissible(
                            key: ValueKey(rating.id),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              return await showDialog<bool>(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: const Text('Delete rating?'),
                                      content: const Text('This action cannot be undone.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dialogContext, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(dialogContext, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;
                            },
                            onDismissed: (_) async {
                              await context.read<RatingProvider>().deleteRating(rating.id);
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                RatingDisplayWidget(rating: rating),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Text(
                                    'Product ID: ${rating.productId}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}