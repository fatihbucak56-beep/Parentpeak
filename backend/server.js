const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Providers-Daten aus JSON laden
const providersPath = path.join(__dirname, 'providers.json');

function getProviders() {
  try {
    const data = fs.readFileSync(providersPath, 'utf8');
    return JSON.parse(data).providers;
  } catch (error) {
    console.error('Fehler beim Lesen der Providers:', error);
    return [];
  }
}

function saveProviders(providers) {
  try {
    fs.writeFileSync(providersPath, JSON.stringify({ providers }, null, 2));
    return true;
  } catch (error) {
    console.error('Fehler beim Speichern der Providers:', error);
    return false;
  }
}

// Routes

// 1. Alle Anbieter abrufen
app.get('/api/providers', (req, res) => {
  const providers = getProviders();
  res.json(providers);
});

// 2. Anbieter nach Kategorie filtern
app.get('/api/providers/category/:category', (req, res) => {
  const { category } = req.params;
  const providers = getProviders();
  const filtered = providers.filter(p => p.category === category || p.subcategory === category);
  res.json(filtered);
});

// 3. Anbieter nach ID abrufen
app.get('/api/providers/:id', (req, res) => {
  const { id } = req.params;
  const providers = getProviders();
  const provider = providers.find(p => p.id === id);
  
  if (!provider) {
    return res.status(404).json({ error: 'Anbieter nicht gefunden' });
  }
  
  res.json(provider);
});

// 4. Suche nach Name
app.get('/api/search', (req, res) => {
  const { q } = req.query;
  
  if (!q) {
    return res.status(400).json({ error: 'Suchtext erforderlich' });
  }
  
  const providers = getProviders();
  const filtered = providers.filter(p => 
    p.name.toLowerCase().includes(q.toLowerCase()) ||
    p.category.toLowerCase().includes(q.toLowerCase()) ||
    p.description.toLowerCase().includes(q.toLowerCase())
  );
  
  res.json(filtered);
});

// 5. Alle Kategorien abrufen
app.get('/api/categories', (req, res) => {
  const providers = getProviders();
  const categories = [...new Set(providers.map(p => p.category))];
  res.json(categories);
});

// 6. Neue Bewertung hinzufügen (Mock - speichert nicht wirklich)
app.post('/api/providers/:id/review', (req, res) => {
  const { id } = req.params;
  const { rating, comment, parentName } = req.body;
  
  if (!rating || rating < 1 || rating > 5) {
    return res.status(400).json({ error: 'Bewertung muss zwischen 1 und 5 liegen' });
  }
  
  const providers = getProviders();
  const provider = providers.find(p => p.id === id);
  
  if (!provider) {
    return res.status(404).json({ error: 'Anbieter nicht gefunden' });
  }
  
  // Mock: Aktualisiere Rating
  provider.reviews += 1;
  provider.rating = ((provider.rating * (provider.reviews - 1)) + rating) / provider.reviews;
  
  saveProviders(providers);
  
  res.json({
    message: 'Bewertung hinzugefügt',
    provider: provider
  });
});

// 7. Filter nach Kriterien
app.post('/api/providers/filter', (req, res) => {
  const { categories, maxPrice, minRating } = req.body;
  
  let providers = getProviders();
  
  if (categories && categories.length > 0) {
    providers = providers.filter(p => categories.includes(p.category));
  }
  
  if (maxPrice) {
    providers = providers.filter(p => p.price <= maxPrice);
  }
  
  if (minRating) {
    providers = providers.filter(p => p.rating >= minRating);
  }
  
  res.json(providers);
});

// Health Check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'Parentpeak Backend läuft!' });
});

// Server starten
app.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ Parentpeak Backend läuft auf http://localhost:${PORT}`);
  console.log(`📍 API verfügbar unter http://localhost:${PORT}/api`);
});
