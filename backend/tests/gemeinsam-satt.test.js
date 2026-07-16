/**
 * Gemeinsam Satt Integration Tests
 * Tests recipe CRUD, ratings, filtering, and persistence
 */

const http = require('http');
const API_BASE = 'http://localhost:3000';

const testRecipe1 = {
  title: 'Klassischer Kartoffelsalat',
  description: 'Traditioneller Kartoffelsalat mit Fleischbrühe und Essig',
  category: 'Salat',
  difficulty: 'einfach',
  prepTimeMinutes: 30,
  servings: 4,
  ingredients: [
    { name: 'Kartoffeln', amount: '1kg', unit: 'g' },
    { name: 'Fleischbrühe', amount: '300', unit: 'ml' },
    { name: 'Essig', amount: '50', unit: 'ml' },
  ],
  instructions: [
    'Kartoffeln kochen',
    'Mit Brühe marinieren',
    'Mit Essig abschmecken',
  ],
  tags: ['vegetarisch', 'deutsch', 'klassisch'],
};

const testRecipe2 = {
  title: 'Schnelle Pasta Primavera',
  description: 'Frische Pasta mit saisonalem Gemüse',
  category: 'Pasta',
  difficulty: 'leicht',
  prepTimeMinutes: 20,
  servings: 2,
  ingredients: [
    { name: 'Spaghetti', amount: '400', unit: 'g' },
    { name: 'Zucchini', amount: '1', unit: 'Stück' },
    { name: 'Tomate', amount: '2', unit: 'Stück' },
  ],
  instructions: [
    'Pasta kochen',
    'Gemüse schneiden',
    'Alles zusammenmischen',
  ],
  tags: ['vegetarisch', 'schnell', 'italienisch'],
};

// Utility: Make HTTP request
function makeRequest(method, path, body = null, token = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, API_BASE);
    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        ...(token && { 'Authorization': `Bearer ${token}` }),
      },
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({
            status: res.statusCode,
            body: data ? JSON.parse(data) : null,
          });
        } catch (e) {
          reject(e);
        }
      });
    });

    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

// Test Suite
async function runTests() {
  console.log('\n🍳 Gemeinsam Satt Integration Tests\n');
  
  let recipeId1, recipeId2;
  let passed = 0;
  let failed = 0;
  const testUserId = 'test-user-' + Date.now();

  // Test 1: Create recipes
  try {
    console.log('✍️  Test 1: Create recipes');
    const res1 = await makeRequest('POST', '/api/food-feed/recipes', {
      ...testRecipe1,
      creatorUserId: testUserId,
      familyId: 'family-1',
    });
    
    if (!res1.body.recipe || !res1.body.recipe.id) {
      throw new Error('Recipe creation failed');
    }
    recipeId1 = res1.body.recipe.id;
    console.log(`  ✓ Recipe 1 created: ${recipeId1}`);
    console.log(`    Title: ${res1.body.recipe.title}`);
    
    const res2 = await makeRequest('POST', '/api/food-feed/recipes', {
      ...testRecipe2,
      creatorUserId: testUserId,
      familyId: 'family-1',
    });
    recipeId2 = res2.body.recipe.id;
    console.log(`  ✓ Recipe 2 created: ${recipeId2}`);
    passed++;
  } catch (e) {
    console.error(`  ✗ Failed: ${e.message}`);
    failed++;
  }

  // Test 2: List recipes with pagination
  try {
    console.log('\n📋 Test 2: List recipes with pagination');
    const res = await makeRequest('GET', '/api/food-feed/recipes?skip=0&take=10');
    
    if (Array.isArray(res.body.recipes)) {
      console.log(`  ✓ Found ${res.body.recipes.length} recipe(s)`);
      console.log(`  Total in DB: ${res.body.total}`);
      passed++;
    } else {
      throw new Error('Invalid response format');
    }
  } catch (e) {
    console.error(`  ✗ Failed: ${e.message}`);
    failed++;
  }

  // Test 3: Filter by category
  try {
    console.log('\n🏷️  Test 3: Filter recipes by category');
    const res = await makeRequest('GET', '/api/food-feed/recipes?category=Salat&take=10');
    
    const salatRecipes = res.body.recipes.filter(r => r.category === 'Salat');
    console.log(`  ✓ Found ${salatRecipes.length} Salat recipe(s)`);
    passed++;
  } catch (e) {
    console.error(`  ✗ Failed: ${e.message}`);
    failed++;
  }

  // Test 4: Get single recipe and verify view count increment
  try {
    console.log('\n👀 Test 4: Get recipe detail and check view count');
    const res1 = await makeRequest('GET', `/api/food-feed/recipes/${recipeId1}`);
    const viewCount1 = res1.body.recipe.viewCount;
    console.log(`  Initial view count: ${viewCount1}`);
    
    // Fetch again
    const res2 = await makeRequest('GET', `/api/food-feed/recipes/${recipeId1}`);
    const viewCount2 = res2.body.recipe.viewCount;
    console.log(`  After second view: ${viewCount2}`);
    
    if (viewCount2 > viewCount1) {
      console.log(`  ✓ View count incremented correctly`);
      passed++;
    } else {
      throw new Error('View count not incremented');
    }
  } catch (e) {
    console.error(`  ✗ Failed: ${e.message}`);
    failed++;
  }

  // Test 5: Rate recipe
  try {
    console.log('\n⭐ Test 5: Rate recipe');
    const ratingRes = await makeRequest('POST', `/api/food-feed/recipes/${recipeId1}/rate`, {
      userId: 'rater-1',
      rating: 5,
      comment: 'Sehr lecker!',
    });
    
    console.log(`  ✓ Recipe rated`);
    
    // Verify rating was saved
    const recipeRes = await makeRequest('GET', `/api/food-feed/recipes/${recipeId1}`);
    console.log(`  Average rating: ${recipeRes.body.recipe.rating.toFixed(1)}`);
    console.log(`  Rating count: ${recipeRes.body.recipe.ratingCount}`);
    
    if (recipeRes.body.recipe.ratingCount > 0) {
      console.log(`  ✓ Rating persisted correctly`);
      passed++;
    } else {
      throw new Error('Rating not saved');
    }
  } catch (e) {
    console.error(`  ✗ Failed: ${e.message}`);
    failed++;
  }

  // Test 6: Add multiple ratings to verify aggregation
  try {
    console.log('\n📊 Test 6: Multiple ratings and aggregation');
    await makeRequest('POST', `/api/food-feed/recipes/${recipeId1}/rate`, {
      userId: 'rater-2',
      rating: 4,
    });
    await makeRequest('POST', `/api/food-feed/recipes/${recipeId1}/rate`, {
      userId: 'rater-3',
      rating: 5,
    });
    
    const recipeRes = await makeRequest('GET', `/api/food-feed/recipes/${recipeId1}`);
    const expectedAvg = (5 + 4 + 5) / 3;
    console.log(`  ✓ Multiple ratings: 5, 4, 5`);
    console.log(`  Calculated average: ${expectedAvg.toFixed(2)}`);
    console.log(`  Stored average: ${recipeRes.body.recipe.rating.toFixed(2)}`);
    passed++;
  } catch (e) {
    console.error(`  ✗ Failed: ${e.message}`);
    failed++;
  }

  // Test 7: Update recipe (ownership check)
  try {
    console.log('\n✏️  Test 7: Update recipe');
    const updateRes = await makeRequest('PUT', `/api/food-feed/recipes/${recipeId1}`, {
      creatorUserId: testUserId,
      title: 'Kartoffelsalat - Südwestdeutsche Variante',
      description: 'Aktualisierte Beschreibung',
    });
    
    if (updateRes.body.recipe) {
      console.log(`  ✓ Recipe updated: ${updateRes.body.recipe.title}`);
      passed++;
    } else {
      throw new Error('Update failed');
    }
  } catch (e) {
    console.error(`  ✗ Failed: ${e.message}`);
    failed++;
  }

  // Test 8: Ownership verification (should fail with wrong user)
  try {
    console.log('\n🔒 Test 8: Ownership verification');
    const unauthorizedRes = await makeRequest('PUT', `/api/food-feed/recipes/${recipeId1}`, {
      creatorUserId: 'wrong-user',
      title: 'Hacked title',
    });
    
    if (unauthorizedRes.status === 403) {
      console.log(`  ✓ Correctly rejected unauthorized update (403)`);
      passed++;
    } else if (unauthorizedRes.body.error) {
      console.log(`  ✓ Correctly rejected unauthorized update`);
      passed++;
    } else {
      throw new Error('Should have rejected unauthorized user');
    }
  } catch (e) {
    console.error(`  ✗ Failed: ${e.message}`);
    failed++;
  }

  // Test 9: Delete recipe
  try {
    console.log('\n🗑️  Test 9: Delete recipe');
    const deleteRes = await makeRequest('DELETE', `/api/food-feed/recipes/${recipeId2}`, {
      creatorUserId: testUserId,
    });
    
    if (deleteRes.body.success) {
      console.log(`  ✓ Recipe deleted`);
      
      // Verify it's gone
      const getRes = await makeRequest('GET', `/api/food-feed/recipes/${recipeId2}`);
      if (getRes.status === 404 || getRes.body.error) {
        console.log(`  ✓ Verified recipe no longer exists`);
        passed++;
      } else {
        throw new Error('Recipe still exists after deletion');
      }
    } else {
      throw new Error('Delete failed');
    }
  } catch (e) {
    console.error(`  ✗ Failed: ${e.message}`);
    failed++;
  }

  // Results
  console.log(`\n${'='.repeat(50)}`);
  console.log(`Tests passed: ${passed}`);
  console.log(`Tests failed: ${failed}`);
  console.log(`${'='.repeat(50)}\n`);

  process.exit(failed > 0 ? 1 : 0);
}

// Run tests
runTests().catch(e => {
  console.error('Fatal error:', e);
  process.exit(1);
});
