/**
 * Zanny Collection — Cloudflare Worker API
 * Handles auth, products, wishlist, orders, street styles, and APK versioning.
 * Shared between the Flutter app and the Cloudflare Pages website.
 */

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;
    const origin = url.origin;

    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };

    if (method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders, status: 204 });
    }

    try {
      let response;

      // ── Auth ────────────────────────────────────────────────────────────────
      if (path === '/api/auth/signup' && method === 'POST') {
        response = await handleSignup(request, env);
      } else if (path === '/api/auth/signin' && method === 'POST') {
        response = await handleSignin(request, env);
      } else if (path === '/api/auth/profile' && method === 'GET') {
        response = await handleGetProfile(request, env);
      } else if (path === '/api/auth/profile' && method === 'PUT') {
        response = await handleUpdateProfile(request, env);
      } else if (path === '/api/auth/fcm-token' && method === 'POST') {
        response = await handleFcmToken(request, env);
      } else if (path === '/api/upload' && method === 'POST') {
        response = await handleUpload(request, env);
      } else if (path.startsWith('/api/images/') && method === 'GET') {
        response = await handleGetImage(path.slice(12), env);

      // ── Products ────────────────────────────────────────────────────────────
      } else if (path === '/api/products' && method === 'GET') {
        response = await handleGetProducts(request, env, origin);
      } else if (path === '/api/products' && method === 'POST') {
        response = await handleCreateProduct(request, env, origin);
      } else if (/^\/api\/products\/[^/]+$/.test(path) && method === 'GET') {
        response = await handleGetProduct(path.split('/')[3], env, origin);
      } else if (/^\/api\/products\/[^/]+$/.test(path) && method === 'PUT') {
        response = await handleUpdateProduct(path.split('/')[3], request, env, origin);
      } else if (/^\/api\/products\/[^/]+$/.test(path) && method === 'DELETE') {
        response = await handleDeleteProduct(path.split('/')[3], request, env);

      // ── Wishlist ────────────────────────────────────────────────────────────
      } else if (path === '/api/wishlist' && method === 'GET') {
        response = await handleGetWishlist(request, env, origin);
      } else if (path === '/api/wishlist' && method === 'POST') {
        response = await handleAddToWishlist(request, env);
      } else if (/^\/api\/wishlist\/[^/]+$/.test(path) && method === 'DELETE') {
        response = await handleRemoveFromWishlist(path.split('/')[3], request, env);

      // ── Orders ─────────────────────────────────────────────────────────────
      } else if (path === '/api/admin/orders' && method === 'GET') {
        response = await handleGetAdminOrders(request, env);
      } else if (path === '/api/orders' && method === 'GET') {
        response = await handleGetOrders(request, env);
      } else if (path === '/api/orders' && method === 'POST') {
        response = await handleCreateOrder(request, env);
      } else if (/^\/api\/orders\/[^/]+\/status$/.test(path) && method === 'PUT') {
        response = await handleUpdateOrderStatus(path.split('/')[3], request, env);

      // ── Street Styles ───────────────────────────────────────────────────────
      } else if (path === '/api/styles' && method === 'GET') {
        response = await handleGetStyles(request, env);
      } else if (path === '/api/styles' && method === 'POST') {
        response = await handleCreateStyle(request, env);
      } else if (/^\/api\/styles\/[^/]+\/like$/.test(path) && method === 'POST') {
        response = await handleLikeStyle(path.split('/')[3], request, env);
      } else if (/^\/api\/styles\/[^/]+\/comment$/.test(path) && method === 'POST') {
        response = await handleCommentStyle(path.split('/')[3], request, env);
      } else if (/^\/api\/styles\/[^/]+$/.test(path) && method === 'DELETE') {
        response = await handleDeleteStyle(path.split('/')[3], request, env);

      // ── Cart ─────────────────────────────────────────────────────────────────
      } else if (path === '/api/cart' && method === 'GET') {
        response = await handleGetCart(request, env, origin);
      } else if (path === '/api/cart' && method === 'POST') {
        response = await handlePostCart(request, env);

      // ── Version / APK ───────────────────────────────────────────────────────
      } else if (path === '/api/version' && method === 'GET') {
        response = await handleGetVersion(env);
      } else if (path === '/api/version' && method === 'PUT') {
        response = await handleSetVersion(request, env);

      // ── File Upload (APK / Images) ────────────────────────────────────────
      } else if (path === '/api/upload' && method === 'POST') {
        response = await handleUpload(request, env);

      // ── Health ──────────────────────────────────────────────────────────────
      } else if (path === '/api/health') {
        response = json({ status: 'ok', ts: new Date().toISOString() });
      } else {
        response = json({ error: 'Not found' }, 404);
      }

      // Attach CORS to all responses
      for (const [k, v] of Object.entries(corsHeaders)) {
        response.headers.set(k, v);
      }
      return response;

    } catch (e) {
      const r = json({ error: e.message || 'Internal server error' }, 500);
      for (const [k, v] of Object.entries(corsHeaders)) r.headers.set(k, v);
      return r;
    }
  }
};

// ════════════════════════════════════════════════════════════════════════════
// JWT Utilities (WebCrypto — no external deps needed)
// ════════════════════════════════════════════════════════════════════════════

function b64url(buf) {
  return btoa(String.fromCharCode(...new Uint8Array(buf)))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

async function createJwt(payload, secret) {
  const enc = new TextEncoder();
  const header = b64url(enc.encode(JSON.stringify({ alg: 'HS256', typ: 'JWT' })));
  const body = b64url(enc.encode(JSON.stringify(payload)));
  const data = `${header}.${body}`;
  const key = await crypto.subtle.importKey(
    'raw', enc.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']
  );
  const sig = b64url(await crypto.subtle.sign('HMAC', key, enc.encode(data)));
  return `${data}.${sig}`;
}

async function verifyJwt(token, secret) {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const [header, body, sig] = parts;
    const enc = new TextEncoder();
    const key = await crypto.subtle.importKey(
      'raw', enc.encode(secret),
      { name: 'HMAC', hash: 'SHA-256' }, false, ['verify']
    );
    const rawSig = Uint8Array.from(atob(sig.replace(/-/g, '+').replace(/_/g, '/')), c => c.charCodeAt(0));
    const valid = await crypto.subtle.verify('HMAC', key, rawSig, enc.encode(`${header}.${body}`));
    if (!valid) return null;
    const payload = JSON.parse(atob(body.replace(/-/g, '+').replace(/_/g, '/')));
    if (payload.exp && payload.exp < Math.floor(Date.now() / 1000)) return null;
    return payload;
  } catch { return null; }
}

async function getUser(request, env) {
  const auth = request.headers.get('Authorization') || '';
  if (!auth.startsWith('Bearer ')) return null;
  return verifyJwt(auth.slice(7), env.JWT_SECRET);
}

async function requireUser(request, env) {
  const user = await getUser(request, env);
  if (!user) throw { status: 401, message: 'Unauthorized' };
  return user;
}

async function requireAdmin(request, env) {
  const user = await requireUser(request, env);
  if (!user.is_admin && user.email !== 'admin@zannycollection.com') throw { status: 403, message: 'Admin access required' };
  return user;
}

// ════════════════════════════════════════════════════════════════════════════
// Password Utilities (PBKDF2 — available in WebCrypto)
// ════════════════════════════════════════════════════════════════════════════

async function hashPassword(password) {
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const key = await crypto.subtle.importKey('raw', new TextEncoder().encode(password), 'PBKDF2', false, ['deriveBits']);
  const bits = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', salt, iterations: 100000, hash: 'SHA-256' }, key, 256
  );
  const toHex = arr => Array.from(arr).map(b => b.toString(16).padStart(2, '0')).join('');
  return {
    salt: toHex(salt),
    hash: toHex(new Uint8Array(bits))
  };
}

async function verifyPassword(password, storedHash, saltHex) {
  if (!storedHash) return false;
  
  let actualHash = storedHash;
  let actualSaltHex = saltHex;

  // Support old prefix-encoded format "pbkdf2:saltHex:hashHex"
  if (storedHash.startsWith('pbkdf2:')) {
    const parts = storedHash.split(':');
    if (parts.length === 3) {
      actualSaltHex = parts[1];
      actualHash = parts[2];
    }
  }

  if (!actualSaltHex) return false;

  const salt = Uint8Array.from(actualSaltHex.match(/.{2}/g).map(b => parseInt(b, 16)));
  const key = await crypto.subtle.importKey('raw', new TextEncoder().encode(password), 'PBKDF2', false, ['deriveBits']);
  const bits = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', salt, iterations: 100000, hash: 'SHA-256' }, key, 256
  );
  const computed = Array.from(new Uint8Array(bits)).map(b => b.toString(16).padStart(2, '0')).join('');
  return computed === actualHash;
}

async function ensureUserSchema(env) {
  const cols = [
    "ALTER TABLE users ADD COLUMN salt TEXT",
    "ALTER TABLE users ADD COLUMN first_name TEXT DEFAULT ''",
    "ALTER TABLE users ADD COLUMN last_name TEXT DEFAULT ''",
    "ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'customer'",
    "ALTER TABLE users ADD COLUMN is_verified INTEGER DEFAULT 0",
    "ALTER TABLE users ADD COLUMN auth_provider TEXT DEFAULT 'local'",
    "ALTER TABLE users ADD COLUMN phone_number TEXT DEFAULT ''",
    "ALTER TABLE users ADD COLUMN full_name TEXT DEFAULT ''",
    "ALTER TABLE users ADD COLUMN phone TEXT DEFAULT ''",
    "ALTER TABLE users ADD COLUMN avatar_url TEXT DEFAULT ''",
    "ALTER TABLE users ADD COLUMN is_admin INTEGER DEFAULT 0",
    "ALTER TABLE users ADD COLUMN fcm_token TEXT DEFAULT ''",
    "ALTER TABLE users ADD COLUMN login_count INTEGER DEFAULT 0",
    "ALTER TABLE users ADD COLUMN last_login DATETIME",
    "ALTER TABLE users ADD COLUMN consecutive_cancellations INTEGER DEFAULT 0",
    "ALTER TABLE users ADD COLUMN restricted_from_cod INTEGER DEFAULT 0",
    "ALTER TABLE users ADD COLUMN consecutive_successful_orders INTEGER DEFAULT 0",
    "ALTER TABLE users ADD COLUMN default_delivery_zone TEXT DEFAULT ''",
    "ALTER TABLE users ADD COLUMN default_address TEXT DEFAULT ''"
  ];
  for (const sql of cols) {
    try {
      await env.DB.prepare(sql).run();
    } catch (e) {
      // ignore if column already exists
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Helpers
// ════════════════════════════════════════════════════════════════════════════

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' }
  });
}

function jsonError(message, status) {
  return json({ error: message }, status);
}

function parseJsonArray(val) {
  try { const r = JSON.parse(val || '[]'); return Array.isArray(r) ? r : []; }
  catch { return []; }
}

// ════════════════════════════════════════════════════════════════════════════
// Auth Handlers
// ════════════════════════════════════════════════════════════════════════════

async function handleSignup(request, env) {
  await ensureUserSchema(env);
  const body = await request.json().catch(() => ({}));
  const { email, password, full_name } = body;
  if (!email || !password) return jsonError('Email and password are required', 400);
  const em = email.trim().toLowerCase();

  const existing = await env.DB.prepare('SELECT id FROM users WHERE email = ?').bind(em).first();
  if (existing) return jsonError('Email already registered', 409);

  const id = crypto.randomUUID();
  const hashObj = await hashPassword(password);
  
  const parts = (full_name || '').trim().split(/\s+/);
  const first_name = parts[0] || '';
  const last_name = parts.slice(1).join(' ') || '';

  const isAdmin = em === 'admin@zannycollection.com';
  await env.DB.prepare(
    'INSERT INTO users (id, email, password_hash, salt, first_name, last_name, role, is_verified, full_name, is_admin) VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?)'
  ).bind(id, em, hashObj.hash, hashObj.salt, first_name, last_name, isAdmin ? 'admin' : 'customer', full_name || '', isAdmin ? 1 : 0).run();

  const token = await createJwt(
    { sub: id, email: em, is_admin: isAdmin, exp: Math.floor(Date.now() / 1000) + 30 * 86400 },
    env.JWT_SECRET
  );
  return json({ token, user: { id, email: em, full_name: full_name || '', is_admin: isAdmin } }, 201);
}

async function handleSignin(request, env) {
  await ensureUserSchema(env);
  const body = await request.json().catch(() => ({}));
  const { email, password } = body;
  if (!email || !password) return jsonError('Email and password are required', 400);
  const em = email.trim().toLowerCase();

  const user = await env.DB.prepare('SELECT * FROM users WHERE email = ?').bind(em).first();
  if (!user) return jsonError('Invalid email or password', 401);

  const valid = await verifyPassword(password, user.password_hash, user.salt);
  if (!valid) return jsonError('Invalid email or password', 401);

  const isAdmin = user.is_admin === 1 || user.role === 'admin' || user.email === 'admin@zannycollection.com';
  if (user.email === 'admin@zannycollection.com' && user.is_admin !== 1) {
    try {
      await env.DB.prepare("UPDATE users SET is_admin = 1, role = 'admin' WHERE id = ?").bind(user.id).run();
    } catch (_) {}
  }

  const token = await createJwt(
    { sub: user.id, email: user.email, is_admin: isAdmin, exp: Math.floor(Date.now() / 1000) + 30 * 86400 },
    env.JWT_SECRET
  );
  return json({
    token,
    user: {
      id: user.id, email: user.email,
      full_name: user.full_name || (user.first_name ? `${user.first_name} ${user.last_name}`.trim() : ''),
      phone: user.phone || user.phone_number || '',
      avatar_url: user.avatar_url || '',
      is_admin: isAdmin,
    }
  });
}

async function handleGetProfile(request, env) {
  await ensureUserSchema(env);
  const payload = await requireUser(request, env);
  const user = await env.DB.prepare(
    'SELECT * FROM users WHERE id = ?'
  ).bind(payload.sub).first();
  if (!user) return jsonError('User not found', 404);
  return json({
    user: {
      id: user.id,
      email: user.email,
      full_name: user.full_name || (user.first_name ? `${user.first_name} ${user.last_name}`.trim() : ''),
      phone: user.phone || user.phone_number || '',
      avatar_url: user.avatar_url || '',
      is_admin: user.is_admin === 1 || user.role === 'admin',
    }
  });
}

async function handleUpdateProfile(request, env) {
  await ensureUserSchema(env);
  const payload = await requireUser(request, env);
  const { full_name, phone, avatar_url } = await request.json().catch(() => ({}));
  
  const parts = (full_name || '').trim().split(/\s+/);
  const first_name = parts[0] || '';
  const last_name = parts.slice(1).join(' ') || '';

  await env.DB.prepare(
    'UPDATE users SET first_name = ?, last_name = ?, phone_number = ?, full_name = ?, phone = ?, avatar_url = ? WHERE id = ?'
  ).bind(first_name, last_name, phone || '', full_name || '', phone || '', avatar_url || '', payload.sub).run();
  return json({ success: true });
}

async function handleFcmToken(request, env) {
  const payload = await requireUser(request, env);
  const { token } = await request.json().catch(() => ({}));
  if (token) {
    await env.DB.prepare('UPDATE users SET fcm_token = ? WHERE id = ?').bind(token, payload.sub).run();
  }
  return json({ success: true });
}

// ════════════════════════════════════════════════════════════════════════════
// Product Handlers
// ════════════════════════════════════════════════════════════════════════════

function parseProduct(row, env, origin = '') {
  if (!row) return null;

  const publicUrl = env.CF_R2_PUBLIC_URL || '';
  let images = [];
  
  if (row.image_url) {
    images.push(resolveImage(row.image_url, publicUrl, origin));
  }
  
  if (row.gallery_urls) {
    const gallery = parseJsonArray(row.gallery_urls);
    for (let img of gallery) {
      images.push(resolveImage(img, publicUrl, origin));
    }
  }

  // Fallback if images list is empty but row.images exists
  if (images.length === 0 && row.images) {
    images = parseJsonArray(row.images).map(img => resolveImage(img, publicUrl, origin));
  }

  let colors = parseJsonArray(row.colors);
  let sizes = parseJsonArray(row.sizes);

  // Extract from variations if empty
  if (row.variations) {
    const vars = parseJsonArray(row.variations);
    if (colors.length === 0) {
      colors = [...new Set(vars.map(v => v.color).filter(c => c))];
    }
    if (sizes.length === 0) {
      sizes = [...new Set(vars.map(v => v.size).filter(s => s))];
    }
  }

  const badge = row.badge || '';
  const isNew = badge.toUpperCase() === 'NEW' || row.is_new === 1;
  const isSale = badge.toUpperCase() === 'SALE' || row.is_sale === 1 || (row.original_price && row.original_price > row.price);

  return {
    id: row.id,
    name: row.name,
    subtitle: row.subtitle || row.discount_label || badge || '',
    description: row.description || '',
    price: row.price || 0,
    original_price: row.original_price || null,
    images,
    colors,
    sizes,
    category: row.category || row.category_slug || '',
    category_slug: row.category || row.category_slug || '',
    is_new: isNew,
    is_sale: isSale,
    stock: row.stock !== undefined ? row.stock : 10,
    is_active: row.is_deleted === 0 || row.is_active === 1
  };
}

async function handleGetProducts(request, env, origin = '') {
  const url = new URL(request.url);
  const category = url.searchParams.get('category');
  const search = url.searchParams.get('search');
  const sort = url.searchParams.get('sort') || 'default';
  const limit = Math.min(parseInt(url.searchParams.get('limit') || '200'), 500);

  let query = 'SELECT * FROM products WHERE is_deleted = 0';
  const params = [];

  if (category) {
    if (category === 'new-arrivals') {
      query += " AND UPPER(badge) = 'NEW'";
    } else if (category === 'sale') {
      query += " AND (UPPER(badge) = 'SALE' OR (original_price IS NOT NULL AND original_price > price))";
    } else if (category !== 'all') {
      query += ' AND (category = ? OR category_slug = ?)';
      params.push(category, category);
    }
  }
  if (search) {
    query += ' AND (LOWER(name) LIKE ? OR LOWER(description) LIKE ?)';
    params.push(`%${search.toLowerCase()}%`, `%${search.toLowerCase()}%`);
  }

  switch (sort) {
    case 'price_asc': query += ' ORDER BY price ASC'; break;
    case 'price_desc': query += ' ORDER BY price DESC'; break;
    case 'newest': query += ' ORDER BY created_at DESC'; break;
    default: query += ' ORDER BY created_at DESC';
  }
  query += ` LIMIT ${limit}`;

  const stmt = env.DB.prepare(query);
  const result = params.length ? await stmt.bind(...params).all() : await stmt.all();
  return json({ products: result.results.map(row => parseProduct(row, env, origin)) });
}

async function handleGetProduct(id, env, origin = '') {
  const row = await env.DB.prepare('SELECT * FROM products WHERE id = ? AND is_deleted = 0').bind(id).first();
  if (!row) return jsonError('Product not found', 404);
  return json({ product: parseProduct(row, env, origin) });
}

async function handleCreateProduct(request, env, origin = '') {
  await requireAdmin(request, env);
  const data = await request.json().catch(() => ({}));
  const id = data.id || crypto.randomUUID();
  
  const mainImage = (data.images && data.images.length > 0) ? data.images[0] : null;
  const galleryUrls = (data.images && data.images.length > 1) ? JSON.stringify(data.images.slice(1)) : '[]';
  const badge = data.is_new ? 'NEW' : (data.is_sale ? 'SALE' : null);

  await env.DB.prepare(`
    INSERT INTO products (id, name, category, description, price, original_price, image_url, gallery_urls, colors, sizes, badge, is_deleted)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
  `).bind(
    id, data.name || '', data.category || data.category_slug || '', data.description || '',
    data.price || 0, data.original_price || null, mainImage, galleryUrls,
    JSON.stringify(data.colors || []), JSON.stringify(data.sizes || []), badge
  ).run();

  if (data.send_push === true) {
    const title = `New Arrival: ${data.name}! 🚀`;
    const body = data.push_body || `Check out the new drop: ${data.name} is in stock now in ${data.category || 'New Arrivals'}. Tap to view!`;
    const route = `/product/${id}`;
    await broadcastFcmNotification(env, title, body, route);
  }
  
  const product = await env.DB.prepare('SELECT * FROM products WHERE id = ?').bind(id).first();
  return json({ product: parseProduct(product, env, origin) }, 201);
}

async function handleUpdateProduct(id, request, env, origin = '') {
  await requireAdmin(request, env);
  const data = await request.json().catch(() => ({}));
  
  const mainImage = (data.images && data.images.length > 0) ? data.images[0] : null;
  const galleryUrls = (data.images && data.images.length > 1) ? JSON.stringify(data.images.slice(1)) : '[]';
  const badge = data.is_new ? 'NEW' : (data.is_sale ? 'SALE' : null);

  await env.DB.prepare(`
    UPDATE products SET name=?, category=?, description=?, price=?, original_price=?,
    image_url=?, gallery_urls=?, colors=?, sizes=?, badge=?, is_deleted=?
    WHERE id=?
  `).bind(
    data.name || '', data.category || data.category_slug || '', data.description || '',
    data.price || 0, data.original_price || null, mainImage, galleryUrls,
    JSON.stringify(data.colors || []), JSON.stringify(data.sizes || []), badge,
    data.is_deleted === true || data.is_active === false ? 1 : 0,
    id
  ).run();

  const product = await env.DB.prepare('SELECT * FROM products WHERE id = ?').bind(id).first();
  return json({ product: parseProduct(product, env, origin) });
}

async function handleDeleteProduct(id, request, env) {
  await requireAdmin(request, env);
  await env.DB.prepare('UPDATE products SET is_deleted = 1 WHERE id = ?').bind(id).run();
  return json({ success: true });
}

// ════════════════════════════════════════════════════════════════════════════
// Wishlist Handlers
// ════════════════════════════════════════════════════════════════════════════

async function handleGetWishlist(request, env, origin = '') {
  const payload = await requireUser(request, env);
  const result = await env.DB.prepare(`
    SELECT p.* FROM products p
    INNER JOIN wishlists w ON p.id = w.product_id
    WHERE w.user_id = ? AND p.is_deleted = 0
    ORDER BY w.created_at DESC
  `).bind(payload.sub).all();
  return json({ products: result.results.map(row => parseProduct(row, env, origin)) });
}

async function handleAddToWishlist(request, env) {
  const payload = await requireUser(request, env);
  const { product_id } = await request.json().catch(() => ({}));
  if (!product_id) return jsonError('product_id required', 400);
  await env.DB.prepare(
    'INSERT OR IGNORE INTO wishlists (user_id, product_id) VALUES (?, ?)'
  ).bind(payload.sub, product_id).run();
  return json({ success: true }, 201);
}

async function handleRemoveFromWishlist(productId, request, env) {
  const payload = await requireUser(request, env);
  await env.DB.prepare(
    'DELETE FROM wishlists WHERE user_id = ? AND product_id = ?'
  ).bind(payload.sub, productId).run();
  return json({ success: true });
}

// ════════════════════════════════════════════════════════════════════════════
// Order Handlers
// ════════════════════════════════════════════════════════════════════════════

async function handleGetAdminOrders(request, env) {
  await requireAdmin(request, env);
  const result = await env.DB.prepare(
    'SELECT * FROM orders ORDER BY created_at DESC'
  ).all();
  const orders = result.results.map(o => ({ ...o, items: parseJsonArray(o.items) }));
  return json({ orders });
}

async function handleGetOrders(request, env) {
  const payload = await requireUser(request, env);
  const result = await env.DB.prepare(
    'SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC'
  ).bind(payload.sub).all();
  const orders = result.results.map(o => ({ ...o, items: parseJsonArray(o.items) }));
  return json({ orders });
}

async function handleCreateOrder(request, env) {
  const payload = await requireUser(request, env);
  const data = await request.json().catch(() => ({}));
  const id = data.id || `ZC_ORD_${Date.now()}`;
  await env.DB.prepare(`
    INSERT INTO orders (id, user_id, items, total_amount, status, delivery_address, recipient_name, recipient_phone)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `).bind(
    id, payload.sub,
    JSON.stringify(data.items || []), data.total_amount || 0,
    data.status || 'pending',
    data.delivery_address || '', data.recipient_name || '', data.recipient_phone || ''
  ).run();
  return json({ id, success: true }, 201);
}

async function handleUpdateOrderStatus(orderId, request, env) {
  await requireAdmin(request, env);
  const { status, items } = await request.json().catch(() => ({}));
  
  let query = 'UPDATE orders SET status = ?';
  const params = [status];
  
  if (items) {
    query += ', items = ?';
    params.push(JSON.stringify(items));
  }
  
  if (status === 'confirmed') {
    query += ', confirmed_at = datetime(\'now\')';
  } else if (status === 'shipped' || status === 'delivering') {
    query += ', shipped_at = datetime(\'now\')';
  } else if (status === 'delivered') {
    query += ', delivered_at = datetime(\'now\')';
  }
  
  query += ' WHERE id = ?';
  params.push(orderId);
  
  await env.DB.prepare(query).bind(...params).run();
  return json({ success: true });
}

// ════════════════════════════════════════════════════════════════════════════
// Street Styles Handlers
// ════════════════════════════════════════════════════════════════════════════

async function handleGetStyles(request, env) {
  const user = await getUser(request, env);
  const userId = user ? user.sub : '';

  const stylesResult = await env.DB.prepare(`
    SELECT 
      s.*,
      (SELECT COUNT(*) FROM style_likes WHERE style_id = s.id) AS likes_count,
      (SELECT COUNT(*) FROM style_likes WHERE style_id = s.id AND user_id = ?) AS user_liked
    FROM street_styles s
    ORDER BY s.created_at DESC
    LIMIT 50
  `).bind(userId).all();

  const styles = stylesResult.results || [];
  if (styles.length === 0) {
    return json({ styles: [] });
  }

  const styleIds = styles.map(s => s.id);
  const placeholders = styleIds.map(() => '?').join(',');
  const commentsResult = await env.DB.prepare(`
    SELECT * FROM style_comments 
    WHERE style_id IN (${placeholders}) 
    ORDER BY created_at ASC
  `).bind(...styleIds).all();

  const comments = commentsResult.results || [];
  const commentsByStyle = {};
  for (const c of comments) {
    if (!commentsByStyle[c.style_id]) {
      commentsByStyle[c.style_id] = [];
    }
    commentsByStyle[c.style_id].push({
      id: c.id,
      style_id: c.style_id,
      user_id: c.user_id,
      username: c.username,
      comment: c.comment,
      created_at: c.created_at
    });
  }

  const formattedStyles = styles.map(s => {
    return {
      id: s.id,
      username: s.username || '',
      location: s.location || '',
      description: s.description || '',
      images: parseJsonArray(s.images),
      created_at: s.created_at,
      likes_count: s.likes_count || 0,
      is_liked: (s.user_liked || 0) > 0,
      comments: commentsByStyle[s.id] || []
    };
  });

  return json({ styles: formattedStyles });
}

async function handleLikeStyle(styleId, request, env) {
  const user = await requireUser(request, env);
  const userId = user.sub;

  const existing = await env.DB.prepare(
    'SELECT 1 FROM style_likes WHERE style_id = ? AND user_id = ?'
  ).bind(styleId, userId).first();

  if (existing) {
    await env.DB.prepare(
      'DELETE FROM style_likes WHERE style_id = ? AND user_id = ?'
    ).bind(styleId, userId).run();
    return json({ success: true, liked: false });
  } else {
    await env.DB.prepare(
      'INSERT INTO style_likes (style_id, user_id) VALUES (?, ?)'
    ).bind(styleId, userId).run();
    return json({ success: true, liked: true });
  }
}

async function handleCommentStyle(styleId, request, env) {
  const user = await requireUser(request, env);
  const userId = user.sub;
  const { comment } = await request.json().catch(() => ({}));

  if (!comment || !comment.trim()) {
    return json({ error: 'Comment text is required' }, 400);
  }

  const dbUser = await env.DB.prepare('SELECT full_name, email FROM users WHERE id = ?').bind(userId).first();
  const username = dbUser ? (dbUser.full_name || dbUser.email.split('@')[0]) : 'User';

  const id = crypto.randomUUID();
  await env.DB.prepare(`
    INSERT INTO style_comments (id, style_id, user_id, username, comment)
    VALUES (?, ?, ?, ?, ?)
  `).bind(id, styleId, userId, username, comment.trim()).run();

  return json({
    success: true,
    comment: {
      id,
      style_id: styleId,
      user_id: userId,
      username,
      comment: comment.trim(),
      created_at: new Date().toISOString()
    }
  }, 201);
}

async function handleCreateStyle(request, env) {
  await requireAdmin(request, env);
  const data = await request.json().catch(() => ({}));
  const id = crypto.randomUUID();
  await env.DB.prepare(
    'INSERT INTO street_styles (id, images, username, location, description) VALUES (?, ?, ?, ?, ?)'
  ).bind(id, JSON.stringify(data.images || []), data.username || '', data.location || '', data.description || '').run();
  return json({ id, success: true }, 201);
}

async function handleDeleteStyle(id, request, env) {
  await requireAdmin(request, env);
  await env.DB.prepare('DELETE FROM street_styles WHERE id = ?').bind(id).run();
  return json({ success: true });
}

// ════════════════════════════════════════════════════════════════════════════
// Version / APK Handler
// ════════════════════════════════════════════════════════════════════════════

async function handleGetVersion(env) {
  try {
    const obj = await env.R2.get('version.json');
    if (!obj) return json({ version: '1.0.2', build: 2, apk_url: '', changelog: 'Initial release' });
    return json(JSON.parse(await obj.text()));
  } catch {
    return json({ version: '1.0.2', build: 2, apk_url: '', changelog: 'Initial release' });
  }
}

async function handleSetVersion(request, env) {
  // Accept either a valid admin JWT *or* the ADMIN_SECRET environment variable
  const secret = request.headers.get('X-Admin-Secret');
  if (!secret || secret !== env.ADMIN_SECRET) {
    await requireAdmin(request, env);
  }
  const data = await request.json().catch(() => ({}));
  const versionData = JSON.stringify(data);
  await env.R2.put('version.json', versionData, {
    httpMetadata: { contentType: 'application/json' }
  });

  // Trigger push notification on app update
  const title = 'New Update Available! 🚀';
  const body = data.changelog
    ? `Version ${data.version || ''} is live: ${data.changelog}`
    : `A new version ${data.version || ''} of Zanny Collection is available. Update now!`;
  const route = '/profile';
  await broadcastFcmNotification(env, title, body, route);

  return json({ success: true });
}

// ════════════════════════════════════════════════════════════════════════════
// Upload Handler
// ════════════════════════════════════════════════════════════════════════════

async function handleUpload(request, env) {
  // Accept either a valid admin JWT *or* the ADMIN_SECRET environment variable
  const secret = request.headers.get('X-Admin-Secret');
  if (!secret || secret !== env.ADMIN_SECRET) {
    await requireAdmin(request, env);
  }
  const formData = await request.formData().catch(() => null);
  if (!formData) return jsonError('Invalid form data', 400);

  const file = formData.get('file');
  if (!file) return jsonError('File field is required', 400);

  const key = formData.get('key') || file.name || crypto.randomUUID();
  const arrayBuffer = await file.arrayBuffer();

  await env.R2.put(key, arrayBuffer, {
    httpMetadata: { contentType: file.type || 'application/octet-stream' }
  });

  return json({ key, success: true }, 201);
}

async function handleGetImage(key, env) {
  try {
    const decodedKey = decodeURIComponent(key);
    const object = await env.R2.get(decodedKey);
    if (!object) {
      return new Response('Image not found', { status: 404 });
    }
    const headers = new Headers();
    object.writeHttpMetadata(headers);
    headers.set('etag', object.httpEtag);
    headers.set('Cache-Control', 'public, max-age=31536000');
    return new Response(object.body, { headers });
  } catch (err) {
    return new Response(err.message, { status: 500 });
  }
}

function getR2Key(urlStr) {
  if (!urlStr) return '';
  if (urlStr.startsWith('http://') || urlStr.startsWith('https://')) {
    try {
      const u = new URL(urlStr);
      if (u.pathname.startsWith('/api/images/')) {
        return u.pathname.slice(12);
      }
      return u.pathname.startsWith('/') ? u.pathname.slice(1) : u.pathname;
    } catch {
      return urlStr;
    }
  }
  if (urlStr.startsWith('/api/images/')) {
    return urlStr.slice(12);
  }
  if (urlStr.startsWith('/')) {
    return urlStr.slice(1);
  }
  return urlStr;
}

function resolveImage(urlStr, publicUrl, origin) {
  if (!urlStr) return '';
  const key = getR2Key(urlStr);
  if (origin) {
    return `${origin}/api/images/${key}`;
  }
  if (publicUrl) {
    return `${publicUrl}/${key}`.replace(/([^:]\/)\/+/g, "$1");
  }
  return urlStr;
}

// ════════════════════════════════════════════════════════════════════════════
// Cart Sync Handlers
// ════════════════════════════════════════════════════════════════════════════

async function handleGetCart(request, env, origin = '') {
  const payload = await requireUser(request, env);
  const publicUrl = env.CF_R2_PUBLIC_URL || '';

  const items = await env.DB.prepare(`
    SELECT 
      c.id as [key],
      c.product_id as id,
      c.quantity as qty,
      c.size,
      c.color,
      p.name,
      p.price,
      p.image_url as image,
      p.image_url,
      p.gallery_urls,
      p.images,
      p.colors,
      p.sizes,
      p.category,
      p.badge,
      p.is_new,
      p.is_sale,
      p.stock
    FROM cart_items c
    JOIN products p ON c.product_id = p.id
    WHERE c.user_id = ?
  `).bind(payload.sub).all();

  const parsedItems = (items.results || []).map(row => {
    const product = parseProduct(row, env, origin);
    return {
      key: row.key,
      product: product,
      selectedColor: row.color || '',
      selectedSize: row.size || '',
      quantity: row.qty || 1
    };
  });

  return json({ success: true, items: parsedItems });
}

async function handlePostCart(request, env) {
  const payload = await requireUser(request, env);
  const { items } = await request.json().catch(() => ({}));
  if (!Array.isArray(items)) {
    return json({ error: 'Invalid items array' }, 400);
  }

  // Delete existing cart items for this user
  await env.DB.prepare("DELETE FROM cart_items WHERE user_id = ?").bind(payload.sub).run();

  // Batch insert new items if there are any
  if (items.length > 0) {
    const statements = items.map(item => {
      const prodId = item.product_id || item.product?.id;
      const qty = item.quantity || item.qty || 1;
      const size = item.selected_size || item.selectedSize || item.size || '';
      const color = item.selected_color || item.selectedColor || item.color || '';
      const key = `${payload.sub}-${prodId}-${color}-${size}`;
      
      return env.DB.prepare(`
        INSERT INTO cart_items (id, user_id, product_id, quantity, size, color)
        VALUES (?, ?, ?, ?, ?, ?)
      `).bind(
        key,
        payload.sub,
        prodId,
        qty,
        size,
        color
      );
    });
    
    await env.DB.batch(statements);
  }

  return json({ success: true });
}

// ════════════════════════════════════════════════════════════════════════════
// Native FCM Notification Broadcast Utilities (No external deps)
// ════════════════════════════════════════════════════════════════════════════

function pemToArrayBuffer(pem) {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "")
    .replace(/\\n/g, ""); // handle literal newlines if present
  const binary = atob(b64);
  const buffer = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    buffer[i] = binary.charCodeAt(i);
  }
  return buffer.buffer;
}

function base64url(str) {
  return btoa(str).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

function arrayBufferToString(buf) {
  return String.fromCharCode.apply(null, new Uint8Array(buf));
}

async function signJwtRS256(header, payload, privateKeyPem) {
  const headerStr = base64url(JSON.stringify(header));
  const payloadStr = base64url(JSON.stringify(payload));
  const data = new TextEncoder().encode(`${headerStr}.${payloadStr}`);

  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKeyPem),
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256"
    },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    data
  );

  const signatureStr = base64url(arrayBufferToString(signature));
  return `${headerStr}.${payloadStr}.${signatureStr}`;
}

async function getFcmAccessToken(env) {
  const header = { alg: "RS256", typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: env.FIREBASE_CLIENT_EMAIL,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now
  };

  const jwt = await signJwtRS256(header, payload, env.FIREBASE_PRIVATE_KEY);

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`
  });
  const data = await res.json();
  if (data.error) {
    throw new Error(`Google OAuth error: ${data.error_description || data.error}`);
  }
  return data.access_token;
}

async function broadcastFcmNotification(env, title, body, route) {
  if (!env.FIREBASE_PROJECT_ID || !env.FIREBASE_CLIENT_EMAIL || !env.FIREBASE_PRIVATE_KEY) {
    console.info("⚠️ FCM credentials not fully configured, skipping push notification.");
    return { success: false, reason: "Credentials missing" };
  }

  try {
    const accessToken = await getFcmAccessToken(env);

    // Get all registered FCM tokens
    const { results } = await env.DB.prepare(
      "SELECT fcm_token FROM users WHERE fcm_token IS NOT NULL AND fcm_token != ''"
    ).all();

    if (results.length === 0) {
      return { success: true, count: 0 };
    }

    const promises = results.map(row => {
      return fetch(`https://fcm.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/messages:send`, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          message: {
            token: row.fcm_token,
            notification: { title, body },
            data: { route: route || "/orders" }
          }
        })
      }).catch(err => {
        console.error(`Failed to send notification to device: ${err.message}`);
        return null;
      });
    });

    await Promise.all(promises);
    return { success: true, count: results.length };
  } catch (e) {
    console.error(`FCM Broadcast failed: ${e.message}`);
    return { success: false, error: e.message };
  }
}

