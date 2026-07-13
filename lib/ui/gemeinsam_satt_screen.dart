import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trusted_circle_demo/models/food_share_post.dart';

// ============================================================
// GEMEINSAM SATT — Eltern-Essenssolidarität
// ============================================================

const Color _brand = Color(0xFFE8543A);
const Color _brandLight = Color(0xFFFFF1EE);
const Color _surface = Color(0xFFF8FAFD);
const Color _cardBg = Colors.white;

class GemeinsamSattScreen extends StatefulWidget {
  const GemeinsamSattScreen({super.key});

  @override
  State<GemeinsamSattScreen> createState() => _GemeinsamSattScreenState();
}

class _GemeinsamSattScreenState extends State<GemeinsamSattScreen>
    with SingleTickerProviderStateMixin {
  static const String _myUserId = 'mama_fatih';
  late final TabController _tabController;
  final TextEditingController _commentController = TextEditingController();

  late List<FoodSharePost> _posts;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _posts = _buildDemoPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        foregroundColor: const Color(0xFF1A2A3A),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _brandLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('🤝', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GemeinsamSatt',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Color(0xFF1A2A3A),
                  ),
                ),
                Text(
                  'Essen teilen · Zusammen satt werden',

                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8A9AB0),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _brand,
          labelColor: _brand,
          unselectedLabelColor: const Color(0xFF8A9AB0),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'In meiner Nähe'),
            Tab(text: 'Meine Angebote'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNearbyFeed(),
          _buildMyOffers(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text(
          'Ich habe extra gekocht!',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () => _openCreatePost(context),
      ),
    );
  }

  // -------------------------------------------------------
  // NEARBY FEED
  // -------------------------------------------------------

  Widget _buildNearbyFeed() {
    final available = _posts.where((p) => p.isAvailable).toList();
    if (available.isEmpty) {
      return _buildEmptyState(
        emoji: '🍲',
        title: 'Noch keine Angebote in deiner Nähe',
        subtitle: 'Sei der Erste! Drücke unten auf „Ich habe extra gekocht!"',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: available.length,
      itemBuilder: (context, i) => _PostCard(
        post: available[i],
        myUserId: _myUserId,
        onLike: () => _toggleLike(available[i].id),
        onAbholen: () => _reservePost(available[i].id),
        onComment: () => _showComments(available[i]),
      ),
    );
  }

  Widget _buildMyOffers() {
    final mine = _posts.where((p) => p.authorId == _myUserId).toList();
    if (mine.isEmpty) {
      return _buildEmptyState(
        emoji: '👩‍🍳',
        title: 'Du hast noch nichts geteilt',
        subtitle: 'Hast du heute extra gekocht? Teile es mit anderen Eltern!',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: mine.length,
      itemBuilder: (context, i) => _PostCard(
        post: mine[i],
        myUserId: _myUserId,
        onLike: () => _toggleLike(mine[i].id),
        onAbholen: () => _reservePost(mine[i].id),
        onComment: () => _showComments(mine[i]),
        isOwner: true,
      ),
    );
  }

  Widget _buildEmptyState({
    required String emoji,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2A3A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF8A9AB0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // ACTIONS
  // -------------------------------------------------------

  void _toggleLike(String postId) {
    setState(() {
      final idx = _posts.indexWhere((p) => p.id == postId);
      if (idx == -1) return;
      final post = _posts[idx];
      final liked = post.likedByUserIds.contains(_myUserId);
      final updated = liked
          ? (List<String>.from(post.likedByUserIds)..remove(_myUserId))
          : (List<String>.from(post.likedByUserIds)..add(_myUserId));
      _posts[idx] = post.copyWith(likedByUserIds: updated);
    });
    HapticFeedback.lightImpact();
  }

  void _reservePost(String postId) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final post = _posts[idx];

    if (post.isReservedByMe) {
      _showSnack('Reservierung aufgehoben 👋');
      setState(() {
        _posts[idx] = post.copyWith(
          isReservedByMe: false,
          remainingPortions: post.remainingPortions + 1,
        );
      });
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickupBottomSheet(
        post: post,
        onConfirm: (message) {
          setState(() {
            _posts[idx] = post.copyWith(
              isReservedByMe: true,
              remainingPortions: post.remainingPortions - 1,
            );
          });
          _showSnack('Super! ${post.authorName} wurde benachrichtigt 🎉');
        },
      ),
    );
  }

  void _showComments(FoodSharePost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(
        post: post,
        myUserId: _myUserId,
        onAddComment: (text) {
          final idx = _posts.indexWhere((p) => p.id == post.id);
          if (idx == -1) return;
          final newComment = FoodShareComment(
            id: 'c-${DateTime.now().millisecondsSinceEpoch}',
            authorName: 'Ich',
            authorInitials: 'ME',
            authorColor: _brand,
            text: text,
            createdAt: DateTime.now(),
          );
          setState(() {
            _posts[idx] = _posts[idx].copyWith(
              comments: [..._posts[idx].comments, newComment],
            );
          });
        },
      ),
    );
  }

  void _openCreatePost(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePostSheet(
        onSubmit: (title, description, portions, pickupWindow) {
          final newPost = FoodSharePost(
            id: 'p-${DateTime.now().millisecondsSinceEpoch}',
            authorId: _myUserId,
            authorName: 'Ich (Familie Fatih)',
            authorInitials: 'FF',
            authorColor: _brand,
            title: title,
            description: description,
            totalPortions: portions,
            remainingPortions: portions,
            pickupWindow: pickupWindow,
            distanceKm: 0.0,
            createdAt: DateTime.now(),
            imageEmoji: '🍲',
          );
          setState(() {
            _posts.insert(0, newPost);
          });
          _showSnack('Dein Angebot ist jetzt sichtbar für Eltern in der Nähe! 🎉');
          _tabController.animateTo(1);
        },
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1A2A3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // -------------------------------------------------------
  // DEMO DATA
  // -------------------------------------------------------

  List<FoodSharePost> _buildDemoPosts() {
    return [
      FoodSharePost(
        id: 'p-1',
        authorId: 'mueller',
        authorName: 'Familie Müller',
        authorInitials: 'FM',
        authorColor: const Color(0xFF2563EB),
        title: 'Selbstgemachte Lasagne 🍝',
        description:
            'Heute groß gekocht! Hausgemachte Lasagne mit Gemüse und Hack. Perfekt für Familien mit kleinen Kindern.',
        totalPortions: 4,
        remainingPortions: 3,
        pickupWindow: 'Heute 17:30 – 19:00 Uhr',
        distanceKm: 0.4,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        likedByUserIds: ['kaya', 'nguyen'],
        comments: [
          FoodShareComment(
            id: 'c-1',
            authorName: 'Familie Kaya',
            authorInitials: 'FK',
            authorColor: const Color(0xFF16A34A),
            text: 'Klingt mega lecker! Ich komme vorbei 😍',
            createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ],
        imageEmoji: '🍝',
      ),
      FoodSharePost(
        id: 'p-2',
        authorId: 'kaya',
        authorName: 'Familie Kaya',
        authorInitials: 'FK',
        authorColor: const Color(0xFF16A34A),
        title: 'Linsensuppe mit Brot 🍲',
        description:
            'Türkische Linsensuppe – super nahrhaft für Kinder. Dazu frisches Fladenbrot. Vegan & glutenfrei möglich.',
        totalPortions: 3,
        remainingPortions: 2,
        pickupWindow: 'Heute 18:00 – 20:00 Uhr',
        distanceKm: 0.7,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        likedByUserIds: ['mueller', 'mama_fatih', 'nguyen'],
        comments: [],
        imageEmoji: '🍲',
      ),
      FoodSharePost(
        id: 'p-3',
        authorId: 'nguyen',
        authorName: 'Familie Nguyen',
        authorInitials: 'FN',
        authorColor: const Color(0xFF8B5CF6),
        title: 'Vietnamesische Reisschüssel 🍱',
        description:
            'Bunter Gemüsereis mit Tofu – die Kinder lieben es! Heute zu viel gekocht.',
        totalPortions: 2,
        remainingPortions: 2,
        pickupWindow: 'Heute 17:00 – 18:30 Uhr',
        distanceKm: 1.1,
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        likedByUserIds: ['kaya'],
        comments: [],
        imageEmoji: '🍱',
      ),
    ];
  }
}

// ============================================================
// POST CARD
// ============================================================

class _PostCard extends StatefulWidget {
  final FoodSharePost post;
  final String myUserId;
  final VoidCallback onLike;
  final VoidCallback onAbholen;
  final VoidCallback onComment;
  final bool isOwner;

  const _PostCard({
    required this.post,
    required this.myUserId,
    required this.onLike,
    required this.onAbholen,
    required this.onComment,
    this.isOwner = false,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _likeController;
  late final Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _likeScale = Tween<double>(begin: 1, end: 1.4).animate(
      CurvedAnimation(parent: _likeController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  void _handleLike() {
    _likeController.forward().then((_) => _likeController.reverse());
    widget.onLike();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isLiked = post.likedByUserIds.contains(widget.myUserId);
    final likeCount = post.likedByUserIds.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FOOD IMAGE AREA
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                colors: [
                  post.authorColor.withValues(alpha: 0.15),
                  post.authorColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    post.imageEmoji ?? '🍽️',
                    style: const TextStyle(fontSize: 64),
                  ),
                ),
                // Distance badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 12, color: post.authorColor),
                        const SizedBox(width: 3),
                        Text(
                          '${post.distanceKm.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: post.authorColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Portions badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: post.isAvailable
                          ? const Color(0xFF16A34A).withValues(alpha: 0.9)
                          : Colors.grey.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      post.isAvailable
                          ? '${post.remainingPortions} Portion${post.remainingPortions != 1 ? 'en' : ''} frei'
                          : 'Ausgebucht',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // CONTENT
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: post.authorColor.withValues(alpha: 0.15),
                      child: Text(
                        post.authorInitials,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: post.authorColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A2A3A),
                            ),
                          ),
                          Text(
                            _timeAgo(post.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8A9AB0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A2A3A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  post.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF516072),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 12),

                // Pickup time
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 14, color: Color(0xFFE07B39)),
                      const SizedBox(width: 6),
                      Text(
                        post.pickupWindow,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE07B39),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF0F4F8)),
                const SizedBox(height: 12),

                // ACTION ROW: Like, Comment, Abholen
                Row(
                  children: [
                    // LIKE
                    GestureDetector(
                      onTap: _handleLike,
                      child: ScaleTransition(
                        scale: _likeScale,
                        child: Row(
                          children: [
                            Icon(
                              isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isLiked ? _brand : const Color(0xFF8A9AB0),
                              size: 22,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$likeCount',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isLiked
                                    ? _brand
                                    : const Color(0xFF8A9AB0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),

                    // COMMENT
                    GestureDetector(
                      onTap: widget.onComment,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Color(0xFF8A9AB0),
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.comments.length}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8A9AB0),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // ABHOLEN BUTTON
                    if (!widget.isOwner)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: post.isReservedByMe
                                ? const Color(0xFFE8F5E9)
                                : post.isAvailable
                                    ? _brand
                                    : Colors.grey.shade300,
                            foregroundColor: post.isReservedByMe
                                ? const Color(0xFF16A34A)
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed:
                              post.isAvailable || post.isReservedByMe
                                  ? widget.onAbholen
                                  : null,
                          child: Text(
                            post.isReservedByMe
                                ? '✓ Reserviert'
                                : post.isAvailable
                                    ? 'Ich hole ab 🙌'
                                    : 'Ausgebucht',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                    if (widget.isOwner)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4F8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${post.totalPortions - post.remainingPortions}/${post.totalPortions} vergeben',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF516072),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
    return 'vor ${diff.inDays} Tag(en)';
  }
}

// ============================================================
// PICKUP BOTTOM SHEET
// ============================================================

class _PickupBottomSheet extends StatelessWidget {
  final FoodSharePost post;
  final Function(String message) onConfirm;

  const _PickupBottomSheet({required this.post, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E3E8),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            post.imageEmoji ?? '🍽️',
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            post.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A2A3A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'von ${post.authorName}',
            style: const TextStyle(color: Color(0xFF8A9AB0)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _brandLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, color: _brand, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Abholzeit',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8A9AB0),
                        ),
                      ),
                      Text(
                        post.pickupWindow,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _brand,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    color: Color(0xFF516072), size: 18),
                const SizedBox(width: 10),
                Text(
                  '${post.distanceKm.toStringAsFixed(1)} km entfernt',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF516072),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _brand,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(context);
                onConfirm('Ich komme!');
              },
              child: const Text(
                'Ich hole ab! 🙌',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: Color(0xFF8A9AB0)),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// COMMENTS SHEET
// ============================================================

class _CommentsSheet extends StatefulWidget {
  final FoodSharePost post;
  final String myUserId;
  final Function(String text) onAddComment;

  const _CommentsSheet({
    required this.post,
    required this.myUserId,
    required this.onAddComment,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _ctrl = TextEditingController();
  late List<FoodShareComment> _comments;

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.post.comments);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final comment = FoodShareComment(
      id: 'c-${DateTime.now().millisecondsSinceEpoch}',
      authorName: 'Ich',
      authorInitials: 'ME',
      authorColor: _brand,
      text: text,
      createdAt: DateTime.now(),
    );
    setState(() {
      _comments.add(comment);
      _ctrl.clear();
    });
    widget.onAddComment(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 60, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E3E8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Kommentare · ${widget.post.title}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2A3A),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _comments.isEmpty
                ? const Center(
                    child: Text(
                      'Noch keine Kommentare.\nSei der Erste! 💬',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF8A9AB0)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _comments.length,
                    itemBuilder: (_, i) {
                      final c = _comments[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  c.authorColor.withValues(alpha: 0.15),
                              child: Text(
                                c.authorInitials,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: c.authorColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.authorName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A2A3A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    c.text,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF516072),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              8 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Kommentar schreiben...',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFD),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: _brand),
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CREATE POST SHEET
// ============================================================

class _CreatePostSheet extends StatefulWidget {
  final Function(String title, String description, int portions,
      String pickupWindow) onSubmit;

  const _CreatePostSheet({required this.onSubmit});

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _portions = 2;
  String _pickupWindow = 'Heute 17:00 – 19:00 Uhr';

  final List<String> _presets = [
    'Heute 12:00 – 13:30 Uhr',
    'Heute 17:00 – 19:00 Uhr',
    'Heute 18:00 – 20:00 Uhr',
    'Morgen 12:00 – 13:00 Uhr',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 60, 16, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E3E8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                '🍲 Essen anbieten',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A2A3A),
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text(
                'Was hast du heute zu viel gekocht?',
                style: TextStyle(color: Color(0xFF8A9AB0), fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),

            _label('Gericht'),
            const SizedBox(height: 6),
            TextField(
              controller: _titleCtrl,
              decoration: _inputDeco('z. B. Selbstgemachte Lasagne 🍝'),
            ),
            const SizedBox(height: 14),

            _label('Beschreibung'),
            const SizedBox(height: 6),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: _inputDeco(
                'Zutaten, besondere Hinweise (vegan, glutenfrei, scharf...)'),
            ),
            const SizedBox(height: 14),

            _label('Wie viele Portionen?'),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton.outlined(
                  onPressed: () {
                    if (_portions > 1) setState(() => _portions--);
                  },
                  icon: const Icon(Icons.remove_rounded),
                ),
                const SizedBox(width: 12),
                Text(
                  '$_portions',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A2A3A),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: _brand),
                  onPressed: () => setState(() => _portions++),
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _label('Abholzeit'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((p) {
                final selected = _pickupWindow == p;
                return GestureDetector(
                  onTap: () => setState(() => _pickupWindow = p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? _brandLight : const Color(0xFFF0F4F8),
                      border: Border.all(
                        color: selected ? _brand : Colors.transparent,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      p,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? _brand : const Color(0xFF516072),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _brand,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final title = _titleCtrl.text.trim();
                  final desc = _descCtrl.text.trim();
                  if (title.isEmpty) return;
                  Navigator.pop(context);
                  widget.onSubmit(title, desc, _portions, _pickupWindow);
                },
                child: const Text(
                  'Jetzt teilen 🙌',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A2A3A),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB0BBC8), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF8FAFD),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _brand, width: 1.5),
      ),
    );
  }
}
