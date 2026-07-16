import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parentpeak/config/api_config.dart';
import 'package:parentpeak/logic/auth_service.dart';
import 'package:parentpeak/models/food_share_post.dart';
import 'package:parentpeak/models/shared_recipe.dart';
import 'package:parentpeak/models/meal_plan.dart';
import 'package:parentpeak/services/meal_planner_service.dart';
import 'package:parentpeak/logic/gemeinsam_satt_backend_service.dart' as backend_service;

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

enum _RecipeFeedMode { forYou, newest, bestRated, quickMeals }

class _GemeinsamSattScreenState extends State<GemeinsamSattScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _commentController = TextEditingController();
  final backend_service.GemeinsamSattBackendService _service =
      backend_service.GemeinsamSattBackendService();

  late List<FoodSharePost> _posts;
  late List<SharedRecipe> _recipes;
  late WeekPlan _weekPlan;
  bool _isLoadingRecipes = false;
  _RecipeFeedMode _recipeFeedMode = _RecipeFeedMode.forYou;
  Set<String> _savedRecipeIds = <String>{};

  static const String _savedRecipeStoragePrefix =
      'gemeinsam_satt.saved_recipes.v1';

  String get _myUserId =>
      AuthService.instance.currentUser?.uid.trim().isNotEmpty == true
          ? AuthService.instance.currentUser!.uid.trim()
          : 'guest_parent';

  String get _myDisplayName {
    final raw = AuthService.instance.currentUser?.displayName.trim();
    if (raw == null || raw.isEmpty) {
      return 'Ein Elternteil';
    }
    return raw;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _posts = _buildDemoPosts();
    _recipes = [];
    _weekPlan = _buildDemoWeekPlan();
    _loadSavedRecipes();

    // Load recipes from backend
    _loadRecipes();
    // Load meal plan from API
    _loadWeekMealPlan();
  }

  Future<void> _loadWeekMealPlan() async {
    try {
      final familyId = APIConfig.getBackendFamilyId();
      final weekPlan = await MealPlannerService.getWeekMealPlan(
        familyId,
        DateTime.now(),
      );
      
      if (weekPlan != null && weekPlan.days.isNotEmpty) {
        setState(() {
          _weekPlan = weekPlan;
        });
      }
    } catch (e) {
      debugPrint('GemeinsamSattScreen._loadWeekMealPlan(): failed: $e');
      // Keep using demo data
    }
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoadingRecipes = true);
    try {
      final result = await _service.fetchRecipes(
        skip: 0,
        take: 40,
        sortBy:
            _recipeFeedMode == _RecipeFeedMode.bestRated ? 'rating' : 'createdAt',
      );

      final backendRecipes = (result['recipes'] as List?)
              ?.whereType<backend_service.SharedRecipe>()
              .toList() ??
          const <backend_service.SharedRecipe>[];

      final recipes = backendRecipes
          .map(_convertBackendRecipeToUI)
          .map((recipe) =>
            recipe.copyWith(isSavedByMe: _savedRecipeIds.contains(recipe.id)))
          .map((recipe) => recipe.copyWith(relevanceScore: _scoreForCurrentParent(recipe)))
          .toList();

      if (!mounted) return;
      setState(() {
        _recipes = recipes;
        _isLoadingRecipes = false;
      });
    } catch (e) {
      debugPrint('GemeinsamSattScreen._loadRecipes(): failed: $e');
      if (!mounted) return;
      setState(() {
        _recipes = _buildDemoRecipes()
          .map((recipe) =>
            recipe.copyWith(isSavedByMe: _savedRecipeIds.contains(recipe.id)))
            .map((recipe) =>
                recipe.copyWith(relevanceScore: _scoreForCurrentParent(recipe)))
            .toList();
        _isLoadingRecipes = false;
      });
    }
  }

  // Convert backend recipe format to UI model
  SharedRecipe _convertBackendRecipeToUI(backend_service.SharedRecipe data) {
    final title = data.title;
    final category = data.category;
    final ingredients = data.ingredients
        .map((e) =>
            '${e['quantity'] ?? ''} ${e['unit'] ?? ''} ${e['name'] ?? ''}'.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return SharedRecipe(
      id: data.id,
      authorId: (data.creatorUserId ?? '').toString(),
      authorName: _getUserDisplayName(data.creatorUserId),
      authorInitials: _getInitials((data.creatorUserId ?? '').toString()),
      authorColor: _getColorForAuthor((data.creatorUserId ?? '').toString()),
      title: title,
      description: (data.description ?? '').toString(),
      imageEmoji: _getEmojiForCategory(category),
      durationMinutes: data.prepTimeMinutes ?? 30,
      difficulty: _parseDifficulty(data.difficulty),
      tags: data.tags,
      likedByUserIds: data.rating > 0 ? ['seed_like'] : const [],
      ingredients: ingredients,
      steps: data.instructions,
      averageRating: data.rating,
      ratingCount: data.ratingCount,
      viewCount: data.viewCount,
      createdAt: data.createdAt,
    );
  }

  List<SharedRecipe> get _sortedRecipes {
    final list = List<SharedRecipe>.from(_recipes);
    switch (_recipeFeedMode) {
      case _RecipeFeedMode.forYou:
        list.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
        break;
      case _RecipeFeedMode.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _RecipeFeedMode.bestRated:
        list.sort((a, b) {
          final ratingComp = b.averageRating.compareTo(a.averageRating);
          if (ratingComp != 0) return ratingComp;
          return b.ratingCount.compareTo(a.ratingCount);
        });
        break;
      case _RecipeFeedMode.quickMeals:
        list.sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
        break;
    }
    return list;
  }

  double _scoreForCurrentParent(SharedRecipe recipe) {
    final lowerTags = recipe.tags.map((e) => e.toLowerCase()).toList();
    final timeFit = recipe.durationMinutes <= 25 ? 1.0 : recipe.durationMinutes <= 40 ? 0.7 : 0.4;
    final childFit = lowerTags.any((tag) =>
            tag.contains('kinder') ||
            tag.contains('baby') ||
            tag.contains('familie'))
        ? 1.0
        : 0.55;
    final trust = recipe.ratingCount > 0
        ? (recipe.averageRating / 5).clamp(0.0, 1.0)
        : 0.45;
    final freshnessDays = DateTime.now().difference(recipe.createdAt).inDays;
    final freshness = freshnessDays <= 2
        ? 1.0
        : freshnessDays <= 7
            ? 0.75
            : 0.45;
    final interest = recipe.viewCount > 0
        ? (recipe.viewCount / 100).clamp(0.0, 1.0)
        : 0.35;

    return (0.30 * timeFit) +
        (0.25 * childFit) +
        (0.20 * trust) +
        (0.15 * freshness) +
        (0.10 * interest);
  }

  Future<void> _loadSavedRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_savedRecipeStorageKey) ?? const <String>[];
    if (!mounted) return;
    setState(() {
      _savedRecipeIds = saved.toSet();
      _recipes = _recipes
          .map((recipe) =>
              recipe.copyWith(isSavedByMe: saved.contains(recipe.id)))
          .toList();
    });
  }

  Future<void> _persistSavedRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedRecipeStorageKey, _savedRecipeIds.toList());
  }

  String get _savedRecipeStorageKey =>
      '$_savedRecipeStoragePrefix.$_myUserId';

  RecipeDifficulty _parseDifficulty(dynamic value) {
    final val = value?.toString().toLowerCase() ?? '';
    switch (val) {
      case 'einfach':
      case 'easy':
        return RecipeDifficulty.einfach;
      case 'mittel':
      case 'medium':
        return RecipeDifficulty.mittel;
      case 'leicht':
        return RecipeDifficulty.einfach;
      case 'schwer':
        return RecipeDifficulty.fortgeschritten;
      case 'fortgeschritten':
      case 'schwierig':
      case 'hard':
      case 'advanced':
        return RecipeDifficulty.fortgeschritten;
      default:
        return RecipeDifficulty.einfach;
    }
  }

  String _getUserDisplayName(String? userId) {
    if (userId == _myUserId) {
      return _myDisplayName;
    }
    final names = {
      'mueller': 'Familie Müller',
      'kaya': 'Familie Kaya',
      'nguyen': 'Familie Nguyen',
    };
    return names[userId] ?? 'Familie aus der Community';
  }

  String _getInitials(String userId) {
    final firstName = userId.split('_').first;
    return firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';
  }

  Color _getColorForAuthor(String userId) {
    const colors = [
      Color(0xFF2563EB), // blue
      Color(0xFF16A34A), // green
      Color(0xFF8B5CF6), // purple
      Color(0xFFDC2626), // red
    ];
    return colors[userId.hashCode % colors.length];
  }

  String _getEmojiForCategory(String category) {
    final emojis = {
      'Suppe': '🍲',
      'Pasta': '🍝',
      'Salat': '🥗',
      'Fleisch': '🍖',
      'Fisch': '🐟',
      'Dessert': '🍰',
      'Frühstück': '🍳',
      'breakfast': '🍳',
      'lunch': '🍲',
      'dinner': '🍝',
      'snack': '🥙',
    };
    return emojis[category] ?? '🍽️';
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
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          indicatorSize: TabBarIndicatorSize.tab,
          isScrollable: false,
          tabs: const [
            Tab(
              icon: Icon(Icons.location_on_rounded, size: 20),
              text: 'Nähe',
            ),
            Tab(
              icon: Icon(Icons.menu_book_rounded, size: 20),
              text: 'Rezepte',
            ),
            Tab(
              icon: Icon(Icons.calendar_month_rounded, size: 20),
              text: 'Planer',
            ),
            Tab(
              icon: Icon(Icons.favorite_rounded, size: 20),
              text: 'Angebote',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNearbyFeed(),
          _buildRecipesFeed(),
          _buildMealPlanTab(),
          _buildMyOffers(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          final tabIndex = _tabController.index;
          final isRecipeTab = tabIndex == 1;
          final isMealTab = tabIndex == 2;
          return FloatingActionButton.extended(
            backgroundColor: _brand,
            foregroundColor: Colors.white,
            icon: Icon(isRecipeTab
                ? Icons.menu_book_rounded
                : isMealTab
                    ? Icons.add_rounded
                    : Icons.add_circle_outline_rounded),
            label: Text(
              isRecipeTab
                  ? 'Rezept teilen'
                  : isMealTab
                      ? 'Mahlzeit hinzufügen'
                      : 'Ich habe extra gekocht!',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            onPressed: () {
              if (isRecipeTab) {
                _openCreateRecipe(context);
              } else if (isMealTab) {
                _openAddMeal(context);
              } else {
                _openCreatePost(context);
              }
            },
          );
        },
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

  // -------------------------------------------------------
  // MEAL PLANNER TAB
  // -------------------------------------------------------

  Widget _buildMealPlanTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: _cardBg,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Diese Woche',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF516072),
                ),
              ),
              Text(
                '${_weekPlan.weekStart.day}. - ${_weekPlan.weekStart.add(const Duration(days: 6)).day}. ${_monthName(_weekPlan.weekStart.month)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _brand,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
            itemCount: 7,
            itemBuilder: (context, i) {
              final dayPlan =
                  _weekPlan.getDay(i) ?? DayPlan(date: _weekPlan.weekStart.add(Duration(days: i)));
              return _DayPlanCard(
                dayPlan: dayPlan,
                onAddMeal: () => _openAddMealForDay(context, dayPlan.date),
                onRemoveMeal: (type) {
                  setState(() {
                    _weekPlan = _weekPlan.updateDay(dayPlan.removeMeal(type));
                  });
                  _showSnack('Mahlzeit entfernt');
                },
                onTapMeal: (meal) => _showMealDetail(meal),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openAddMeal(BuildContext context) {
    _openAddMealForDay(context, DateTime.now());
  }

  void _openAddMealForDay(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMealSheet(
        date: date,
        onSubmit: (meal) {
          final dayPlan = _weekPlan.getDay(
                date.difference(_weekPlan.weekStart.toDateOnly).inDays,
              ) ??
              DayPlan(date: date);
          setState(() {
            _weekPlan = _weekPlan.updateDay(dayPlan.addMeal(meal));
          });
          _showSnack('Mahlzeit hinzugefügt ✅');
        },
      ),
    );
  }

  void _showMealDetail(Meal meal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MealDetailSheet(meal: meal),
    );
  }

  String _monthName(int month) {
    const months = [
      'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
    ];
    return months[month - 1];
  }

  // -------------------------------------------------------
  // RECIPES FEED
  // -------------------------------------------------------

  Widget _buildRecipesFeed() {
    if (_isLoadingRecipes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recipes.isEmpty) {
      return _buildEmptyState(
        emoji: '📖',
        title: 'Noch keine Rezepte geteilt',
        subtitle: 'Teile dein Lieblingsrezept mit anderen Eltern!',
      );
    }

    final recipes = _sortedRecipes;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF2D7D1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'So werden Rezepte gezeigt',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A2A3A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Standard ist Fuer dich: kinderfreundlich, schnell, gut bewertet und aktuell.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B778C),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildRecipeModeChip(
                      label: 'Fuer dich',
                      mode: _RecipeFeedMode.forYou,
                    ),
                    const SizedBox(width: 8),
                    _buildRecipeModeChip(
                      label: 'Neueste',
                      mode: _RecipeFeedMode.newest,
                    ),
                    const SizedBox(width: 8),
                    _buildRecipeModeChip(
                      label: 'Top bewertet',
                      mode: _RecipeFeedMode.bestRated,
                    ),
                    const SizedBox(width: 8),
                    _buildRecipeModeChip(
                      label: 'Schnell unter 30 min',
                      mode: _RecipeFeedMode.quickMeals,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadRecipes,
            color: _brand,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
              itemCount: recipes.length,
              itemBuilder: (context, i) => _RecipeCard(
                recipe: recipes[i],
                myUserId: _myUserId,
                onLike: () => _toggleRecipeLike(recipes[i]),
                onSave: () => _toggleSave(recipes[i].id),
                onTap: () => _showRecipeDetail(recipes[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeModeChip({
    required String label,
    required _RecipeFeedMode mode,
  }) {
    final selected = _recipeFeedMode == mode;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _recipeFeedMode = mode);
        _loadRecipes();
      },
      selectedColor: _brandLight,
      checkmarkColor: _brand,
      side: BorderSide(
        color: selected ? _brand : const Color(0xFFE9EEF5),
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        color: selected ? _brand : const Color(0xFF516072),
      ),
    );
  }

  Future<void> _toggleRecipeLike(SharedRecipe recipe) async {
    final alreadyLiked = recipe.likedByUserIds.contains(_myUserId);
    if (alreadyLiked) {
      _showSnack('Du hast dieses Rezept bereits empfohlen.');
      return;
    }

    final result = await _service.rateRecipe(
      recipeId: recipe.id,
      userId: _myUserId,
      rating: 5,
      comment: 'Sehr hilfreich fuer Familienalltag',
    );

    if (result == null) {
      _showSnack(_service.lastSyncError ?? 'Empfehlung konnte nicht gespeichert werden.');
      return;
    }

    setState(() {
      final idx = _recipes.indexWhere((r) => r.id == recipe.id);
      if (idx == -1) return;
      final updated = List<String>.from(_recipes[idx].likedByUserIds)..add(_myUserId);
      _recipes[idx] = _recipes[idx].copyWith(
        likedByUserIds: updated,
        ratingCount: _recipes[idx].ratingCount + 1,
        averageRating: (_recipes[idx].averageRating + 5) / 2,
      );
    });
    HapticFeedback.lightImpact();
    _showSnack('Danke! Deine Empfehlung hilft anderen Eltern.');
  }

  Future<void> _toggleSave(String recipeId) async {
    setState(() {
      final idx = _recipes.indexWhere((r) => r.id == recipeId);
      if (idx == -1) return;
      if (_savedRecipeIds.contains(recipeId)) {
        _savedRecipeIds.remove(recipeId);
      } else {
        _savedRecipeIds.add(recipeId);
      }
      _recipes[idx] = _recipes[idx].copyWith(
        isSavedByMe: !_recipes[idx].isSavedByMe,
      );
    });
    await _persistSavedRecipes();
    final saved = _recipes.firstWhere((r) => r.id == recipeId).isSavedByMe;
    _showSnack(saved ? 'Rezept gespeichert ✅' : 'Rezept entfernt');
  }

  Future<void> _showRecipeDetail(SharedRecipe recipe) async {
    SharedRecipe detail = recipe;
    final backendDetail = await _service.getRecipe(recipe.id);
    if (backendDetail != null) {
      final mapped = _convertBackendRecipeToUI(backendDetail);
      detail = mapped.copyWith(
        isSavedByMe: _savedRecipeIds.contains(mapped.id),
        relevanceScore: _scoreForCurrentParent(mapped),
      );
      if (mounted) {
        setState(() {
          final idx = _recipes.indexWhere((r) => r.id == detail.id);
          if (idx != -1) {
            _recipes[idx] = detail;
          }
        });
      }
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecipeDetailSheet(recipe: detail),
    );
  }

  void _openCreateRecipe(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateRecipeSheet(
        onSubmit: (draft) async {
          final created = await _service.createRecipe(
            userId: _myUserId,
            title: draft.title,
            description: draft.description,
            category: draft.category,
            difficulty: draft.difficulty,
            prepTimeMinutes: draft.durationMinutes,
            servings: draft.servings,
            ingredients: draft.ingredients,
            instructions: draft.steps,
            tags: draft.tags,
          );

          if (!mounted) return false;
          if (created == null) {
            _showSnack(_service.lastSyncError ?? 'Rezept konnte nicht geteilt werden.');
            return false;
          }

          final mappedRecipe = _convertBackendRecipeToUI(created);
          setState(() {
            _recipes.insert(
              0,
              mappedRecipe.copyWith(
                isSavedByMe: _savedRecipeIds.contains(mappedRecipe.id),
                relevanceScore: _scoreForCurrentParent(mappedRecipe),
              ),
            );
          });
          _showSnack('Dein Rezept ist jetzt fuer alle sichtbar!');
          return true;
        },
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

  WeekPlan _buildDemoWeekPlan() {
    final today = DateTime.now().toDateOnly;
    final days = <DayPlan>[];
    for (int i = 0; i < 7; i++) {
      final date = today.add(Duration(days: i - (today.weekday - 1)));
      if (i == 0) {
        days.add(
          DayPlan(
            date: date,
            meals: const [
              Meal(
                id: '1',
                title: 'Müsli mit Joghurt',
                type: MealType.breakfast,
                description: 'Mit Beeren und Honig',
              ),
              Meal(
                id: '2',
                title: 'Pasta Bolognese',
                type: MealType.lunch,
                description: 'Hausgemacht, kinderfreundlich',
                ingredients: ['500g Pasta', '400g Hack', 'Tomaten', 'Zwiebel'],
              ),
            ],
          ),
        );
      } else if (i == 2) {
        days.add(
          DayPlan(
            date: date,
            meals: const [
              Meal(
                id: '3',
                title: 'Pancakes',
                type: MealType.breakfast,
              ),
              Meal(
                id: '4',
                title: 'Fischstäbchen mit Kartoffeln',
                type: MealType.lunch,
              ),
              Meal(
                id: '5',
                title: 'Obst & Käse',
                type: MealType.snack,
              ),
            ],
          ),
        );
      } else {
        days.add(DayPlan(date: date));
      }
    }
    return WeekPlan(weekStart: today.subtract(Duration(days: today.weekday - 1)), days: days);
  }

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

  List<SharedRecipe> _buildDemoRecipes() {
    return [
      SharedRecipe(
        id: 'rec-1',
        authorId: 'mueller',
        authorName: 'Familie Müller',
        authorInitials: 'FM',
        authorColor: const Color(0xFF2563EB),
        title: 'Schnelle Linsensuppe für die ganze Familie',
        description: 'Super einfach, nahrhaft und die Kinder lieben sie! In 20 Minuten fertig.',
        imageEmoji: '🍲',
        durationMinutes: 20,
        difficulty: RecipeDifficulty.einfach,
        tags: ['vegan', 'schnell', 'baby-geeignet'],
        likedByUserIds: ['mama_fatih', 'kaya', 'nguyen'],
        ingredients: [
          '200g rote Linsen',
          '1 Zwiebel, gewürfelt',
          '2 Karotten, gewürfelt',
          '1 TL Kurkuma',
          '800ml Gemüsebrühe',
          'Etwas Olivenöl, Salz, Pfeffer',
        ],
        steps: [
          'Zwiebeln in Olivenöl glasig anbraten.',
          'Karotten hinzufügen, 2 Min mitbraten.',
          'Linsen und Kurkuma einrühren.',
          'Mit Brühe aufgießen, 15 Min köcheln lassen.',
          'Mit Stabmixer halb pürieren für cremige Konsistenz.',
          'Mit Salz und Pfeffer abschmecken – fertig!',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      SharedRecipe(
        id: 'rec-2',
        authorId: 'kaya',
        authorName: 'Familie Kaya',
        authorInitials: 'FK',
        authorColor: const Color(0xFF16A34A),
        title: 'Türkische Menemen – Eier in Tomatensauce',
        description: 'Unser Familienfrühstück! Kinder lippen ab, super schnell und sättigend.',
        imageEmoji: '🍳',
        durationMinutes: 15,
        difficulty: RecipeDifficulty.einfach,
        tags: ['vegetarisch', 'frühstück', 'kinderfreundlich'],
        likedByUserIds: ['mueller'],
        ingredients: [
          '4 Eier',
          '2 reife Tomaten, gewürfelt',
          '1 grüne Paprika, gewürfelt',
          '1 Zwiebel',
          'Olivenöl, Salz, Pfeffer, Paprikapulver',
          'Fladenbrot zum Servieren',
        ],
        steps: [
          'Zwiebel und Paprika in Öl anbraten.',
          'Tomaten hinzufügen, 5 Min einkochen lassen.',
          'Eier direkt in die Pfanne aufschlagen.',
          'Vorsichtig mit Gemüse verrühren.',
          'Würzen und bei niedriger Hitze stocken lassen.',
          'Mit Fladenbrot warm servieren.',
        ],
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      SharedRecipe(
        id: 'rec-3',
        authorId: 'nguyen',
        authorName: 'Familie Nguyen',
        authorInitials: 'FN',
        authorColor: const Color(0xFF8B5CF6),
        title: 'Gebratener Reis mit Gemüse (One-Pan)',
        description: 'Perfekt um Reisereste zu verwerten! Kinder können beim Kochen helfen.',
        imageEmoji: '🍱',
        durationMinutes: 25,
        difficulty: RecipeDifficulty.mittel,
        tags: ['vegan', 'one-pan', 'resteverwertung'],
        likedByUserIds: ['mama_fatih'],
        ingredients: [
          '400g vorgekochter Reis (vom Vortag)',
          '2 Eier',
          '1 Tasse gefrorene Erbsen',
          '2 Frühlingszwiebeln',
          '2 EL Sojasoße',
          '1 TL Sesamöl',
        ],
        steps: [
          'Pfanne mit Öl stark erhitzen.',
          'Erbsen und Frühlingszwiebeln kurz anbraten.',
          'Reis hinzufügen, aufbrechen und braten.',
          'Eine Mulde machen, Eier hineinschlagen und rühren.',
          'Alles vermischen, mit Sojasoße würzen.',
          'Mit Sesamöl abschmecken und servieren.',
        ],
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
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

// ============================================================
// RECIPE CARD
// ============================================================

class _RecipeCard extends StatefulWidget {
  final SharedRecipe recipe;
  final String myUserId;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onTap;

  const _RecipeCard({
    required this.recipe,
    required this.myUserId,
    required this.onLike,
    required this.onSave,
    required this.onTap,
  });

  @override
  State<_RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<_RecipeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _likeCtrl;
  late final Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    _likeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _likeScale = Tween<double>(begin: 1, end: 1.4).animate(
        CurvedAnimation(parent: _likeCtrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _likeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final isLiked = recipe.likedByUserIds.contains(widget.myUserId);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE AREA
            Container(
              height: 130,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(
                  colors: [
                    recipe.authorColor.withValues(alpha: 0.12),
                    recipe.authorColor.withValues(alpha: 0.04),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(recipe.imageEmoji, style: const TextStyle(fontSize: 60)),
                  ),
                  // Difficulty badge
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: recipe.difficultyColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        recipe.difficultyLabel,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                  // Time badge
                  Positioned(
                    top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF516072)),
                          const SizedBox(width: 3),
                          Text(
                            '${recipe.durationMinutes} min',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF516072)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: recipe.authorColor.withValues(alpha: 0.15),
                        child: Text(recipe.authorInitials,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: recipe.authorColor)),
                      ),
                      const SizedBox(width: 8),
                      Text(recipe.authorName,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF516072))),
                      const Spacer(),
                      if (recipe.ratingCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${recipe.averageRating.toStringAsFixed(1)} ★ · ${recipe.ratingCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE07B39),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(recipe.title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A2A3A))),
                  const SizedBox(height: 4),
                  Text(recipe.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF516072), height: 1.4)),

                  if (recipe.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      children: recipe.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _brandLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('#$tag',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _brand)),
                      )).toList(),
                    ),
                  ],

                  const SizedBox(height: 8),
                  Text(
                    'Reichweite: ${recipe.viewCount} Aufrufe',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8A9AB0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF0F4F8)),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      // Like
                      GestureDetector(
                        onTap: () {
                          _likeCtrl.forward().then((_) => _likeCtrl.reverse());
                          widget.onLike();
                        },
                        child: ScaleTransition(
                          scale: _likeScale,
                          child: Row(
                            children: [
                              Icon(
                                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isLiked ? _brand : const Color(0xFF8A9AB0),
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text('${recipe.likedByUserIds.length}',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isLiked ? _brand : const Color(0xFF8A9AB0))),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Save button
                      GestureDetector(
                        onTap: widget.onSave,
                        child: Icon(
                          recipe.isSavedByMe ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: recipe.isSavedByMe ? _brand : const Color(0xFF8A9AB0),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // View Recipe button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _brandLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Rezept ansehen →',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _brand),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// RECIPE DETAIL SHEET
// ============================================================

class _RecipeDetailSheet extends StatelessWidget {
  final SharedRecipe recipe;

  const _RecipeDetailSheet({required this.recipe});

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
          // Header
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              gradient: LinearGradient(
                colors: [
                  recipe.authorColor.withValues(alpha: 0.15),
                  recipe.authorColor.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Stack(
              children: [
                Center(child: Text(recipe.imageEmoji, style: const TextStyle(fontSize: 56))),
                Positioned(
                  top: 12, right: 12,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A2A3A))),
                  const SizedBox(height: 4),
                  Text('von ${recipe.authorName}',
                      style: const TextStyle(color: Color(0xFF8A9AB0), fontSize: 13)),
                  const SizedBox(height: 12),

                  // Stats row
                  Row(
                    children: [
                      _statChip(Icons.schedule_rounded, '${recipe.durationMinutes} min'),
                      const SizedBox(width: 8),
                      _statChip(Icons.bar_chart_rounded, recipe.difficultyLabel),
                      const SizedBox(width: 8),
                      _statChip(Icons.star_rounded,
                          '${recipe.averageRating.toStringAsFixed(1)} (${recipe.ratingCount})'),
                      const SizedBox(width: 8),
                      _statChip(Icons.visibility_rounded, '${recipe.viewCount}'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(recipe.description,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF516072), height: 1.5)),
                  const SizedBox(height: 20),

                  // Ingredients
                  const Text('🛒 Zutaten',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A2A3A))),
                  const SizedBox(height: 10),
                  ...recipe.ingredients.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: _brandLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text('${e.key + 1}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _brand)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(e.value,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF1A2A3A))),
                        ),
                      ],
                    ),
                  )).toList(),

                  const SizedBox(height: 20),

                  // Steps
                  const Text('👨‍🍳 Zubereitung',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A2A3A))),
                  const SizedBox(height: 10),
                  ...recipe.steps.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: _brand,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text('${e.key + 1}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(e.value,
                                style: const TextStyle(fontSize: 14, color: Color(0xFF516072), height: 1.5)),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _brandLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _brand),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _brand)),
        ],
      ),
    );
  }
}

class _RecipeDraft {
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final int durationMinutes;
  final int servings;
  final List<Map<String, String>> ingredients;
  final List<String> steps;
  final List<String> tags;

  const _RecipeDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.durationMinutes,
    required this.servings,
    required this.ingredients,
    required this.steps,
    required this.tags,
  });
}

// ============================================================
// CREATE RECIPE SHEET
// ============================================================

class _CreateRecipeSheet extends StatefulWidget {
  final Future<bool> Function(_RecipeDraft) onSubmit;

  const _CreateRecipeSheet({required this.onSubmit});

  @override
  State<_CreateRecipeSheet> createState() => _CreateRecipeSheetState();
}

class _CreateRecipeSheetState extends State<_CreateRecipeSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _ingredientsCtrl = TextEditingController();
  final _stepsCtrl = TextEditingController();
  int _duration = 30;
  int _servings = 4;
  RecipeDifficulty _difficulty = RecipeDifficulty.einfach;
  String _category = 'dinner';
  String _emoji = '🍲';

  final List<String> _emojis = ['🍲', '🍝', '🥗', '🍱', '🥘', '🍜', '🥙', '🫕', '🍛', '🥞'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _ingredientsCtrl.dispose();
    _stepsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 60, 16, 16),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE0E3E8), borderRadius: BorderRadius.circular(4))),
            ),
            const SizedBox(height: 16),
            const Center(child: Text('📖 Rezept teilen',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A2A3A)))),
            const SizedBox(height: 4),
            const Center(child: Text('Teile dein Lieblingsrezept mit anderen Eltern',
                style: TextStyle(color: Color(0xFF8A9AB0), fontSize: 13))),
            const SizedBox(height: 20),

            // Emoji picker
            const Text('Emoji wählen', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2A3A))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _emojis.map((e) => GestureDetector(
                onTap: () => setState(() => _emoji = e),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _emoji == e ? _brandLight : const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _emoji == e ? _brand : Colors.transparent, width: 1.5),
                  ),
                  child: Text(e, style: const TextStyle(fontSize: 22)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 14),

            const Text('Rezeptname', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2A3A))),
            const SizedBox(height: 6),
            TextField(controller: _titleCtrl, decoration: _inputDeco('z. B. Mamas Linsensuppe 🍲')),
            const SizedBox(height: 12),

            const Text('Kurze Beschreibung', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2A3A))),
            const SizedBox(height: 6),
            TextField(controller: _descCtrl, maxLines: 2, decoration: _inputDeco('Was macht dieses Rezept besonders?')),
            const SizedBox(height: 12),

            const Text('Kategorie', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2A3A))),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: const [
                DropdownMenuItem(value: 'breakfast', child: Text('Fruehstueck')),
                DropdownMenuItem(value: 'lunch', child: Text('Mittagessen')),
                DropdownMenuItem(value: 'dinner', child: Text('Abendessen')),
                DropdownMenuItem(value: 'snack', child: Text('Snack')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _category = value);
              },
              decoration: _inputDeco('Kategorie waehlen'),
            ),
            const SizedBox(height: 12),

            const Text('Zutaten (eine pro Zeile)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2A3A))),
            const SizedBox(height: 6),
            TextField(controller: _ingredientsCtrl, maxLines: 4,
                decoration: _inputDeco('z. B.\n200g rote Linsen\n1 Zwiebel\n2 Karotten')),
            const SizedBox(height: 12),

            const Text('Zubereitung (Schritt für Schritt, eine Zeile pro Schritt)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2A3A))),
            const SizedBox(height: 6),
            TextField(controller: _stepsCtrl, maxLines: 5,
                decoration: _inputDeco('z. B.\nZwiebeln anbraten\nLinsen hinzufügen...')),
            const SizedBox(height: 12),

            // Duration + Difficulty
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Zeit (min)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2A3A))),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          IconButton.outlined(
                            onPressed: () { if (_duration > 5) setState(() => _duration -= 5); },
                            icon: const Icon(Icons.remove_rounded, size: 18),
                            padding: const EdgeInsets.all(4),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text('$_duration', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          ),
                          IconButton.filled(
                            style: IconButton.styleFrom(backgroundColor: _brand, padding: const EdgeInsets.all(4)),
                            onPressed: () => setState(() => _duration += 5),
                            icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Portionen', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2A3A))),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          IconButton.outlined(
                            onPressed: () {
                              if (_servings > 1) setState(() => _servings -= 1);
                            },
                            icon: const Icon(Icons.remove_rounded, size: 18),
                            padding: const EdgeInsets.all(4),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '$_servings',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                          ),
                          IconButton.filled(
                            style: IconButton.styleFrom(backgroundColor: _brand, padding: const EdgeInsets.all(4)),
                            onPressed: () => setState(() => _servings += 1),
                            icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Schwierigkeit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2A3A))),
                      const SizedBox(height: 6),
                      DropdownButton<RecipeDifficulty>(
                        value: _difficulty,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: RecipeDifficulty.values.map((d) {
                          final labels = ['Einfach', 'Mittel', 'Fortgeschritten'];
                          return DropdownMenuItem(value: d, child: Text(labels[d.index]));
                        }).toList(),
                        onChanged: (v) { if (v != null) setState(() => _difficulty = v); },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _brand,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  final title = _titleCtrl.text.trim();
                  if (title.isEmpty) return;
                  final ingredients = _ingredientsCtrl.text
                      .split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                  final steps = _stepsCtrl.text
                      .split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                  final draft = _RecipeDraft(
                    title: title,
                    description: _descCtrl.text.trim(),
                    category: _category,
                    difficulty: _difficulty == RecipeDifficulty.einfach
                        ? 'leicht'
                        : _difficulty == RecipeDifficulty.mittel
                            ? 'mittel'
                            : 'schwer',
                    durationMinutes: _duration,
                    servings: _servings,
                    ingredients: (ingredients.isEmpty
                            ? ['Zutaten werden noch ergänzt']
                            : ingredients)
                        .map(
                          (value) => {
                            'name': value,
                            'quantity': '',
                            'unit': '',
                          },
                        )
                        .toList(),
                    steps: steps.isEmpty ? ['Zubereitung wird noch ergänzt'] : steps,
                    tags: _buildDraftTags(_duration, _difficulty, _category),
                  );

                  final success = await widget.onSubmit(draft);
                  if (!context.mounted) return;
                  if (success) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Rezept teilen 📖',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _buildDraftTags(
    int duration,
    RecipeDifficulty difficulty,
    String category,
  ) {
    final tags = <String>['familie'];
    if (duration <= 30) tags.add('schnell');
    if (difficulty == RecipeDifficulty.einfach) tags.add('kinderfreundlich');
    if (category == 'snack') tags.add('alltagssnack');
    if (category == 'breakfast') tags.add('fruehstueck');
    return tags;
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB0BBC8), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF8FAFD),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _brand, width: 1.5)),
    );
  }
}

// ============================================================
// MEAL PLANNER COMPONENTS
// ============================================================

class _DayPlanCard extends StatelessWidget {
  final DayPlan dayPlan;
  final VoidCallback onAddMeal;
  final Function(MealType) onRemoveMeal;
  final Function(Meal) onTapMeal;

  const _DayPlanCard({
    required this.dayPlan,
    required this.onAddMeal,
    required this.onRemoveMeal,
    required this.onTapMeal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: dayPlan.isToday ? const Color(0xFFFFF1EE) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dayPlan.isToday ? const Color(0xFFE8543A) : const Color(0xFFE8E8E8),
          width: dayPlan.isToday ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header with day name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: dayPlan.isToday ? const Color(0xFFE8543A) : const Color(0xFFF5F5F5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayPlan.dayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: dayPlan.isToday ? Colors.white : const Color(0xFF516072),
                      ),
                    ),
                    Text(
                      '${dayPlan.dayOfMonth}.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: dayPlan.isToday ? Colors.white70 : const Color(0xFF8A9BA8),
                      ),
                    ),
                  ],
                ),
                if (dayPlan.isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Heute',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE8543A),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Meals list
          if (dayPlan.meals.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text(
                    '📅 Nichts geplant',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF516072).withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onAddMeal,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Mahlzeit hinzufügen'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE8543A),
                      side: const BorderSide(color: Color(0xFFE8543A)),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  ...dayPlan.meals.map((meal) => _MealListItem(
                    meal: meal,
                    onTap: () => onTapMeal(meal),
                    onRemove: () => onRemoveMeal(meal.type),
                  )),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onAddMeal,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Hinzufügen'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE8543A),
                          side: const BorderSide(color: Color(0xFFE8543A)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MealListItem extends StatelessWidget {
  final Meal meal;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _MealListItem({
    required this.meal,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: meal.type.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: meal.type.color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Text(meal.type.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A2A3A),
                      ),
                    ),
                    if (meal.description != null && meal.description!.isNotEmpty)
                      Text(
                        meal.description!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8A9BA8),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 18),
                iconSize: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: const Color(0xFF8A9BA8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddMealSheet extends StatefulWidget {
  final DateTime date;
  final Function(Meal) onSubmit;

  const _AddMealSheet({
    required this.date,
    required this.onSubmit,
  });

  @override
  State<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<_AddMealSheet> {
  late MealType _selectedType;
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _ingredientsController;

  @override
  void initState() {
    super.initState();
    _selectedType = MealType.lunch;
    _titleController = TextEditingController();
    _descController = TextEditingController();
    _ingredientsController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _ingredientsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty) return;

    final meal = Meal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      type: _selectedType,
      description: _descController.text.trim(),
      ingredients: _ingredientsController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    );
    widget.onSubmit(meal);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mahlzeit hinzufügen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2A3A),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF516072),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Meal type selector
              const Text(
                'Mahlzeitentyp',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF516072),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: MealType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return FilterChip(
                    label: Text('${type.emoji} ${type.label}'),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedType = type),
                    backgroundColor: Colors.white,
                    selectedColor: type.color.withValues(alpha: 0.2),
                    side: BorderSide(
                      color: isSelected ? type.color : const Color(0xFFE8E8E8),
                      width: isSelected ? 2 : 1,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: type.color,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              // Title
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Mahlzeitenname *',
                  hintText: 'z.B. Spaghetti Carbonara',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFD),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE8543A), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Description
              TextField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'Beschreibung',
                  hintText: 'z.B. Mit frischem Parmesan',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFD),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE8543A), width: 2),
                  ),
                ),
                minLines: 2,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Ingredients
              TextField(
                controller: _ingredientsController,
                decoration: InputDecoration(
                  labelText: 'Zutaten (optional)',
                  hintText: 'Eine pro Zeile:\nSpaghetti\nEier\nSpeck',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFD),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE8543A), width: 2),
                  ),
                ),
                minLines: 3,
                maxLines: 6,
              ),
              const SizedBox(height: 24),
              // Submit button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE8543A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Hinzufügen',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealDetailSheet extends StatelessWidget {
  final Meal meal;

  const _MealDetailSheet({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${meal.type.emoji} ${meal.type.label}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8A9BA8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          meal.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A2A3A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              if (meal.description != null && meal.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  meal.description!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF516072),
                    height: 1.5,
                  ),
                ),
              ],
              if (meal.ingredients.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Zutaten',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2A3A),
                  ),
                ),
                const SizedBox(height: 10),
                ...meal.ingredients.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.key + 1}.',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE8543A),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF516072),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

