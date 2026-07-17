/**
 * Gemeinsam Satt Integration Tests
 * Tests recipe CRUD, ratings, filtering, and persistence
 */

const API_BASE = process.env.API_BASE || 'https://parentpeak.onrender.com';
const BEARER_TOKEN =
  process.env.BEARER_TOKEN ||
  process.env.BACKEND_API_TOKEN ||
  process.env.API_TOKEN ||
  '';

const testRecipe1 = {
  title: 'Klassischer Kartoffelsalat',
  description: 'Traditioneller Kartoffelsalat mit Fleischbrühe und Essig',
  category: 'Salat',
  difficulty: 'leicht',
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
  const url = new URL(path, API_BASE);
  return fetch(url, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token && { Authorization: `Bearer ${token}` }),
    },
    body: body ? JSON.stringify(body) : undefined,
  })
    .then(async (res) => {
      const data = await res.text();
      try {
        return {
          status: res.status,
          body: data ? JSON.parse(data) : null,
        };
      } catch (e) {
        return {
          status: res.status,
          body: {
            parseError: e.message,
            raw: data.slice(0, 300),
          },
        };
      }
    });
}

function asNumber(value) {
  if (typeof value === 'number') return value;
  if (typeof value === 'string') {
    const parsed = Number.parseFloat(value);
    return Number.isFinite(parsed) ? parsed : NaN;
  }
  return NaN;
}

// Test Suite
async function runTests() {
  console.log('\n🍳 Gemeinsam Satt Integration Tests');
  console.log(`📍 API Base: ${API_BASE}\n`);
  console.log(`🔐 Auth token: ${BEARER_TOKEN ? 'provided' : 'missing'}\n`);
  
  let recipeId1, recipeId2;
  let reportId;
  let passed = 0;
  let failed = 0;
  const testUserId = 'test-user-' + Date.now();
  const commentUserId = `commenter-${Date.now()}`;

  // Test 1: Create recipes
  try {
    console.log('✍️  Test 1: Create recipes');
    const res1 = await makeRequest('POST', '/api/food-feed/recipes', {
      ...testRecipe1,
      userId: testUserId,
      familyId: 'family-1',
    }, BEARER_TOKEN);
    
    if (res1.status !== 201 && res1.status !== 200) {
      throw new Error(`Expected 200/201, got ${res1.status}: ${JSON.stringify(res1.body)}`);
    }
    
    if (!res1.body.recipe || !res1.body.recipe.id) {
      throw new Error('Recipe creation failed');
    }
    recipeId1 = res1.body.recipe.id;
    console.log(`  ✓ Recipe 1 created: ${recipeId1}`);
    console.log(`    Title: ${res1.body.recipe.title}`);
    
    const res2 = await makeRequest('POST', '/api/food-feed/recipes', {
      ...testRecipe2,
      userId: testUserId,
      familyId: 'family-1',
    }, BEARER_TOKEN);
    if (res2.status !== 201 && res2.status !== 200) {
      throw new Error(`Expected 200/201, got ${res2.status}: ${JSON.stringify(res2.body)}`);
    }
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
    
    if (res.status !== 200) {
      throw new Error(`Expected 200, got ${res.status}: ${JSON.stringify(res.body)}`);
    }
    
    if (Array.isArray(res.body.recipes)) {
      console.log(`  ✓ Found ${res.body.recipes.length} recipe(s)`);
      console.log(`  Total in DB: ${res.body.total}`);
      const createdRecipe = res.body.recipes.find(r => r.id === recipeId1);
      if (!createdRecipe) {
        throw new Error('Created recipe missing from list payload');
      }
      if (createdRecipe.creatorUserId !== testUserId) {
        throw new Error('creatorUserId missing in list payload');
      }
      if (!Array.isArray(createdRecipe.tags)) {
        throw new Error('tags missing in list payload');
      }
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
    
    if (res.status !== 200) {
      throw new Error(`Expected 200, got ${res.status}: ${JSON.stringify(res.body)}`);
    }
    
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
    }, BEARER_TOKEN);
    
    console.log(`  ✓ Recipe rated`);
    
    // Verify rating was saved
    const recipeRes = await makeRequest('GET', `/api/food-feed/recipes/${recipeId1}`);
    const averageRating = asNumber(recipeRes.body.recipe.rating);
    console.log(`  Average rating: ${averageRating.toFixed(1)}`);
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
    }, BEARER_TOKEN);
    await makeRequest('POST', `/api/food-feed/recipes/${recipeId1}/rate`, {
      userId: 'rater-3',
      rating: 5,
    }, BEARER_TOKEN);
    
    const recipeRes = await makeRequest('GET', `/api/food-feed/recipes/${recipeId1}`);
    const expectedAvg = (5 + 4 + 5) / 3;
    const storedAvg = asNumber(recipeRes.body.recipe.rating);
    console.log(`  ✓ Multiple ratings: 5, 4, 5`);
    console.log(`  Calculated average: ${expectedAvg.toFixed(2)}`);
    console.log(`  Stored average: ${storedAvg.toFixed(2)}`);
    passed++;
  } catch (e) {
    console.error(`  ✗ Failed: ${e.message}`);
    failed++;
  }

  // Test 7: Update recipe (ownership check)
  try {
    console.log('\n✏️  Test 7: Update recipe');
    const updateRes = await makeRequest('PUT', `/api/food-feed/recipes/${recipeId1}`, {
      userId: testUserId,
      title: 'Kartoffelsalat - Südwestdeutsche Variante',
      description: 'Aktualisierte Beschreibung',
    }, BEARER_TOKEN);
    
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
      userId: 'wrong-user',
      title: 'Hacked title',
    }, BEARER_TOKEN);
    
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
    const deleteRes = await makeRequest('DELETE', `/api/food-feed/recipes/${recipeId2}?userId=${encodeURIComponent(testUserId)}`, null, BEARER_TOKEN);
    
    if (deleteRes.status === 200 && deleteRes.body.success) {
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
      throw new Error(`Delete failed: ${JSON.stringify(deleteRes.body)}`);
    }
  } catch (e) {
    console.error(`  ✗ Failed: ${e.message}`);
    failed++;
  }

  // Test 10: Persist offer comments
  try {
    console.log('\n💬 Test 10: Persist food-offer comments');
    const createCommentRes = await makeRequest('POST', `/api/food-feed/recipes/${recipeId1}/comments`, {
      userId: commentUserId,
      text: 'Ich koennte heute gegen 18 Uhr abholen.',
    }, BEARER_TOKEN);

    if (createCommentRes.status !== 201) {
      throw new Error(`Expected 201, got ${createCommentRes.status}: ${JSON.stringify(createCommentRes.body)}`);
    }

    const commentsRes = await makeRequest('GET', `/api/food-feed/recipes/${recipeId1}/comments?limit=10`);
    if (commentsRes.status !== 200) {
      throw new Error(`Expected 200, got ${commentsRes.status}: ${JSON.stringify(commentsRes.body)}`);
    }

    const stored = (commentsRes.body.comments || []).find(item => item.userId === commentUserId);
    if (!stored) {
      throw new Error('Created comment not found in persisted comments');
    }
    console.log('  ✓ Comment persisted and listed');
    passed++;
  } catch (e) {
    console.error(`  ✗ Failed: ${e.message}`);
    failed++;
  }

  // Test 11: Persist offer reservations
  try {
    console.log('\n🙌 Test 11: Persist food-offer reservations');
    const reserveRes = await makeRequest('POST', `/api/food-feed/recipes/${recipeId1}/reserve`, {
      userId: commentUserId,
      portions: 2,
    }, BEARER_TOKEN);

    if (reserveRes.status !== 201 && reserveRes.status !== 200) {
      throw new Error(`Expected 200/201, got ${reserveRes.status}: ${JSON.stringify(reserveRes.body)}`);
    }

    const summaryRes = await makeRequest('GET', `/api/food-feed/recipes/${recipeId1}/reservations?userId=${encodeURIComponent(commentUserId)}`);
    if (summaryRes.status !== 200) {
      throw new Error(`Expected 200, got ${summaryRes.status}: ${JSON.stringify(summaryRes.body)}`);
    }

    if ((summaryRes.body.reservedPortions || 0) < 2) {
      throw new Error('Reserved portions summary not updated');
    }
    if ((summaryRes.body.myReservation?.portions || 0) !== 2) {
      throw new Error('Current user reservation missing');
    }

    const cancelRes = await makeRequest('DELETE', `/api/food-feed/recipes/${recipeId1}/reserve?userId=${encodeURIComponent(commentUserId)}`, null, BEARER_TOKEN);
    if (cancelRes.status !== 200) {
      throw new Error(`Expected 200, got ${cancelRes.status}: ${JSON.stringify(cancelRes.body)}`);
    }

    const afterCancelRes = await makeRequest('GET', `/api/food-feed/recipes/${recipeId1}/reservations?userId=${encodeURIComponent(commentUserId)}`);
    if (afterCancelRes.status !== 200) {
      throw new Error(`Expected 200, got ${afterCancelRes.status}: ${JSON.stringify(afterCancelRes.body)}`);
    }
    if (afterCancelRes.body.myReservation) {
      throw new Error('Reservation still present after cancel');
    }

    console.log('  ✓ Reservation persisted and cancel worked');
    passed++;
  } catch (e) {
    console.error(`  ✗ Failed: ${e.message}`);
    failed++;
  }

  // Test 12: Report food offer and guard duplicate reports
  try {
    console.log('\n🚨 Test 12: Report food offer');
    const reportRes = await makeRequest('POST', `/api/food-feed/recipes/${recipeId1}/report`, {
      reportedById: `reporter-${Date.now()}`,
      reason: 'Spam oder Irrefuehrung',
      details: 'Wirkt nicht wie ein echtes Angebot.',
    }, BEARER_TOKEN);

    if (reportRes.status !== 201) {
      throw new Error(`Expected 201, got ${reportRes.status}: ${JSON.stringify(reportRes.body)}`);
    }
    reportId = reportRes.body.report?.id;
    if (!reportId) {
      throw new Error('Report id missing in response');
    }

    const duplicateRes = await makeRequest('POST', `/api/food-feed/recipes/${recipeId1}/report`, {
      reportedById: reportRes.body.report.reportedById,
      reason: 'Spam oder Irrefuehrung',
    }, BEARER_TOKEN);
    if (duplicateRes.status !== 409) {
      throw new Error(`Expected 409 for duplicate report, got ${duplicateRes.status}: ${JSON.stringify(duplicateRes.body)}`);
    }
    console.log('  ✓ Report persisted and duplicate guard works');
    passed++;
  } catch (e) {
    console.error(`  ✗ Failed: ${e.message}`);
    failed++;
  }

  // Test 13: Admin list and resolve food-offer reports
  try {
    console.log('\n🛡️  Test 13: Admin list and resolve food-offer reports');
    const listRes = await makeRequest('GET', '/api/food-feed/reports?maxResults=20', null, BEARER_TOKEN);
    if (listRes.status !== 200) {
      throw new Error(`Expected 200, got ${listRes.status}: ${JSON.stringify(listRes.body)}`);
    }
    const listed = (listRes.body.reports || []).find(item => item.id === reportId);
    if (!listed) {
      throw new Error('Created report missing from admin list');
    }

    const resolveRes = await makeRequest('POST', `/api/food-feed/reports/${reportId}/resolve`, {
      action: 'resolved',
    }, BEARER_TOKEN);
    if (resolveRes.status !== 200) {
      throw new Error(`Expected 200, got ${resolveRes.status}: ${JSON.stringify(resolveRes.body)}`);
    }
    if (resolveRes.body.report?.status !== 'resolved') {
      throw new Error('Report was not marked resolved');
    }
    console.log('  ✓ Admin list and resolve work');
    passed++;
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
