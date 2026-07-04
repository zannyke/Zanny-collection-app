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

    const clientOrigin = request.headers.get('Origin') || '';
    const allowedOrigins = [
      'https://zannycollection.com',
      'https://www.zannycollection.com',
      'https://zanny-collection.pages.dev'
    ];

    let corsOrigin = '*';
    if (clientOrigin) {
      const isLocalhost = /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(clientOrigin);
      if (allowedOrigins.includes(clientOrigin) || isLocalhost) {
        corsOrigin = clientOrigin;
      } else {
        corsOrigin = 'https://zannycollection.com';
      }
    }

    const corsHeaders = {
      'Access-Control-Allow-Origin': corsOrigin,
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };
    if (clientOrigin) {
      corsHeaders['Vary'] = 'Origin';
    }

    if (method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders, status: 204 });
    }

    try {
      let response;

      // Proactive D1 & R2 binding validation to avoid production failures
      if (!env.DB) {
        response = json({ error: 'Database connection failed: Cloudflare D1 DB binding is missing.' }, 500);
      } else if (!env.R2) {
        response = json({ error: 'Storage connection failed: Cloudflare R2 binding is missing.' }, 500);
      } else if (path === '/api/auth/signup' && method === 'POST') {
        response = await handleSignup(request, env);
      } else if (path === '/api/auth/verify-email' && method === 'POST') {
        response = await handleVerifyEmail(request, env);
      } else if (path === '/api/auth/signin' && method === 'POST') {
        response = await handleSignin(request, env);
      } else if (path === '/api/auth/profile' && method === 'GET') {
        response = await handleGetProfile(request, env);
      } else if (path === '/api/auth/profile' && method === 'PUT') {
        response = await handleUpdateProfile(request, env);
      } else if (path === '/api/auth/profile' && method === 'DELETE') {
        response = await handleDeleteProfile(request, env);
      } else if (path === '/api/auth/fcm-token' && method === 'POST') {
        response = await handleFcmToken(request, env);
      } else if (path === '/api/auth/forgot-password' && method === 'POST') {
        response = await handleForgotPassword(request, env);
      } else if (path === '/api/auth/reset-password' && method === 'POST') {
        response = await handleResetPassword(request, env);
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
      } else if (path === '/api/feedback/pending' && method === 'GET') {
        response = await handleGetPendingFeedback(request, env);
      } else if (path === '/api/feedback' && method === 'POST') {
        response = await handlePostFeedback(request, env);
      } else if (/^\/api\/products\/[^/]+\/reviews$/.test(path) && method === 'GET') {
        response = await handleGetProductReviews(path.split('/')[3], request, env);
      } else if (path === '/api/admin/reviews' && method === 'GET') {
        response = await handleGetAdminReviews(request, env);
      } else if (/^\/api\/orders\/[^/]+\/dismiss-review$/.test(path) && method === 'POST') {
        response = await handleDismissReview(path.split('/')[3], request, env);
      } else if (/^\/api\/orders\/[^/]+\/reviewed-products$/.test(path) && method === 'GET') {
        response = await handleGetOrderReviewedProducts(path.split('/')[3], request, env);


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
      } else if (path === '/api/advertise' && method === 'POST') {
        response = await handleSendAdvertisement(request, env);

      // ── File Upload (APK / Images) ────────────────────────────────────────
      } else if (path === '/api/upload' && method === 'POST') {
        response = await handleUpload(request, env);

      } else if (/^\/api\/settings\/[^/]+$/.test(path) && method === 'GET') {
        response = await handleGetSetting(path.split('/')[3], env);
      } else if (/^\/api\/settings\/[^/]+$/.test(path) && method === 'PUT') {
        response = await handleUpdateSetting(path.split('/')[3], request, env);
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
  const body = await request.json().catch(() => ({}));
  const { email, password, full_name } = body;
  if (!email || !password) return jsonError('Email and password are required', 400);
  const em = email.trim().toLowerCase();

  // Validate that only Gmail addresses are allowed to register (excluding admin)
  if (!em.endsWith('@gmail.com') && em !== 'admin@zannycollection.com') {
    return jsonError('Only Gmail addresses (@gmail.com) are supported for registration', 400);
  }

  const existing = await env.DB.prepare('SELECT id, is_verified FROM users WHERE email = ?').bind(em).first();
  if (existing) {
    if (existing.is_verified === 1) {
      return jsonError('Email already registered', 409);
    } else {
      // User signed up but did not verify. We can resend code instead of throwing 409.
      const code = Math.floor(100000 + Math.random() * 900000).toString();
      const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();
      await env.DB.prepare('INSERT OR REPLACE INTO password_resets (email, token, expires_at) VALUES (?, ?, ?)')
        .bind(em, code, expiresAt)
        .run();

      const name = full_name || 'Valued Customer';
      const subject = "Verify Your Zanny Collection Account";
      const html = `
        <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 12px; background-color: #fafafa;">
          <h2 style="color: #000000; border-bottom: 2px solid #000000; padding-bottom: 10px; font-weight: 800; letter-spacing: 0.5px;">Account Verification</h2>
          <p>Hello ${name},</p>
          <p>Welcome back! Please use the following 6-digit verification code to activate your Zanny Collection account:</p>
          <p style="text-align: center; margin-top: 30px; margin-bottom: 30px;">
            <span style="background-color: #f3f4f6; color: #000000; padding: 14px 28px; border-radius: 8px; font-size: 26px; font-weight: 900; letter-spacing: 6px; border: 1px solid #e5e7eb; display: inline-block;">${code}</span>
          </p>
          <p>This code is valid for 15 minutes. If you did not request this, you can ignore this email.</p>
        </div>
      `;
      const emailResult = await sendResendEmail(env, em, subject, html);
      if (!emailResult.success) {
        return jsonError(`Failed to send verification email: ${emailResult.error}`, 500);
      }
      return json({ success: true, verified: false, email: em, message: 'Verification code resent successfully.' });
    }
  }

  const id = crypto.randomUUID();
  const hashObj = await hashPassword(password);
  
  const parts = (full_name || '').trim().split(/\s+/);
  const first_name = parts[0] || '';
  const last_name = parts.slice(1).join(' ') || '';

  const isAdmin = em === 'admin@zannycollection.com';
  
  // Insert with is_verified = 0 (except admin which is pre-verified)
  const isVerified = isAdmin ? 1 : 0;
  await env.DB.prepare(
    'INSERT INTO users (id, email, password_hash, salt, first_name, last_name, role, is_verified, full_name, is_admin) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
  ).bind(id, em, hashObj.hash, hashObj.salt, first_name, last_name, isAdmin ? 'admin' : 'customer', isVerified, full_name || '', isAdmin ? 1 : 0).run();

  if (!isAdmin) {
    // Generate and send verification code
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();
    await env.DB.prepare('INSERT OR REPLACE INTO password_resets (email, token, expires_at) VALUES (?, ?, ?)')
      .bind(em, code, expiresAt)
      .run();

    const name = full_name || 'Valued Customer';
    const subject = "Verify Your Zanny Collection Account";
    const html = `
      <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 12px; background-color: #fafafa;">
        <h2 style="color: #000000; border-bottom: 2px solid #000000; padding-bottom: 10px; font-weight: 800; letter-spacing: 0.5px;">Account Verification</h2>
        <p>Hello ${name},</p>
        <p>Thank you for registering with Zanny Collection. Please use the following 6-digit verification code to activate your account:</p>
        <p style="text-align: center; margin-top: 30px; margin-bottom: 30px;">
          <span style="background-color: #f3f4f6; color: #000000; padding: 14px 28px; border-radius: 8px; font-size: 26px; font-weight: 900; letter-spacing: 6px; border: 1px solid #e5e7eb; display: inline-block;">${code}</span>
        </p>
        <p>This code is valid for 15 minutes.</p>
      </div>
    `;
    const emailResult = await sendResendEmail(env, em, subject, html);
    if (!emailResult.success) {
      return jsonError(`Failed to send verification email: ${emailResult.error}`, 500);
    }
    return json({ success: true, verified: false, email: em, message: 'Verification code sent.' });
  }

  // Pre-verified admin fallback login token
  const token = await createJwt(
    { sub: id, email: em, is_admin: isAdmin, exp: Math.floor(Date.now() / 1000) + 30 * 86400 },
    env.JWT_SECRET
  );
  return json({ token, user: { id, email: em, full_name: full_name || '', is_admin: isAdmin } }, 201);
}

async function handleVerifyEmail(request, env) {
  const { email, code } = await request.json().catch(() => ({}));
  if (!email || !code) return jsonError('Email and code are required', 400);
  const em = email.trim().toLowerCase();

  const reset = await env.DB.prepare('SELECT * FROM password_resets WHERE email = ? AND token = ?').bind(em, code.trim()).first();
  if (!reset) return jsonError('Invalid verification code', 400);

  if (new Date(reset.expires_at) < new Date()) {
    await env.DB.prepare('DELETE FROM password_resets WHERE email = ?').bind(em).run();
    return jsonError('Verification code has expired', 400);
  }

  // Set user as verified
  await env.DB.prepare('UPDATE users SET is_verified = 1 WHERE email = ?').bind(em).run();
  await env.DB.prepare('DELETE FROM password_resets WHERE email = ?').bind(em).run();

  const user = await env.DB.prepare('SELECT * FROM users WHERE email = ?').bind(em).first();
  const isAdmin = user.is_admin === 1 || user.role === 'admin' || user.email === 'admin@zannycollection.com';
  const token = await createJwt(
    { sub: user.id, email: user.email, is_admin: isAdmin, exp: Math.floor(Date.now() / 1000) + 30 * 86400 },
    env.JWT_SECRET
  );

  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    event: "USER_EMAIL_VERIFIED",
    user_id: user.id,
    email: user.email,
    status: "success"
  }));

  return json({
    token,
    user: {
      id: user.id,
      email: user.email,
      full_name: user.full_name || '',
      phone: user.phone || user.phone_number || '',
      avatar_url: user.avatar_url || '',
      is_admin: isAdmin
    }
  });
}

async function handleSignin(request, env) {
  const body = await request.json().catch(() => ({}));
  const { email, password } = body;
  if (!email || !password) return jsonError('Email and password are required', 400);
  const em = email.trim().toLowerCase();

  const user = await env.DB.prepare('SELECT * FROM users WHERE email = ?').bind(em).first();
  if (!user) return jsonError('Invalid email or password', 401);

  const valid = await verifyPassword(password, user.password_hash, user.salt);
  if (!valid) return jsonError('Invalid email or password', 401);

  // Enforce email verification (excluding admin account)
  if (user.is_verified !== 1 && user.email !== 'admin@zannycollection.com') {
    // Resend a new verification code
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();
    await env.DB.prepare('INSERT OR REPLACE INTO password_resets (email, token, expires_at) VALUES (?, ?, ?)')
      .bind(em, code, expiresAt)
      .run();

    const name = user.full_name || user.first_name || 'Valued Customer';
    const subject = "Verify Your Zanny Collection Account";
    const html = `
      <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 12px; background-color: #fafafa;">
        <h2 style="color: #000000; border-bottom: 2px solid #000000; padding-bottom: 10px; font-weight: 800; letter-spacing: 0.5px;">Account Verification</h2>
        <p>Hello ${name},</p>
        <p>Please use the following 6-digit verification code to verify your email address and activate your Zanny Collection account:</p>
        <p style="text-align: center; margin-top: 30px; margin-bottom: 30px;">
          <span style="background-color: #f3f4f6; color: #000000; padding: 14px 28px; border-radius: 8px; font-size: 26px; font-weight: 900; letter-spacing: 6px; border: 1px solid #e5e7eb; display: inline-block;">${code}</span>
        </p>
        <p>This code is valid for 15 minutes.</p>
      </div>
    `;
    await sendResendEmail(env, em, subject, html);
    return jsonError('Please verify your email address. A verification code has been sent.', 403);
  }

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
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    event: "USER_SIGNIN",
    user_id: user.id,
    email: user.email,
    is_admin: isAdmin,
    status: "success"
  }));
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

async function handleDeleteProfile(request, env) {
  const payload = await requireUser(request, env);
  const { password } = await request.json().catch(() => ({}));
  if (!password) return jsonError('Password is required to confirm deletion', 400);

  const user = await env.DB.prepare('SELECT password_hash, salt FROM users WHERE id = ?').bind(payload.sub).first();
  if (!user) return jsonError('User not found', 404);

  const isValid = await verifyPassword(password, user.password_hash, user.salt);
  if (!isValid) return jsonError('Incorrect password. Account deletion aborted.', 401);

  // Permanently delete user record
  await env.DB.prepare('DELETE FROM users WHERE id = ?').bind(payload.sub).run();
  
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    event: "USER_DELETED_ACCOUNT",
    user_id: payload.sub,
    status: "success"
  }));

  return json({ success: true, message: 'Account deleted permanently.' });
}

async function handleFcmToken(request, env) {
  const payload = await requireUser(request, env);
  const { token } = await request.json().catch(() => ({}));
  if (token) {
    await env.DB.prepare('UPDATE users SET fcm_token = ? WHERE id = ?').bind(token, payload.sub).run();
  }
  return json({ success: true });
}

async function handleForgotPassword(request, env) {
  const { email } = await request.json().catch(() => ({}));
  if (!email) return jsonError('Email is required', 400);
  const em = email.trim().toLowerCase();

  // 1. Verify if user exists
  const user = await env.DB.prepare('SELECT id, full_name, first_name FROM users WHERE email = ?').bind(em).first();
  if (!user) {
    // Return success to prevent email enumeration (security best practice)
    return json({ success: true, message: 'If the email exists, a verification code will be sent.' });
  }

  // 2. Generate secure 6-digit verification code
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString(); // 15 minutes expiry

  // 3. Store code in DB
  await env.DB.prepare('INSERT OR REPLACE INTO password_resets (email, token, expires_at) VALUES (?, ?, ?)')
    .bind(em, code, expiresAt)
    .run();

  // 4. Send email
  const name = user.full_name || user.first_name || 'Valued Customer';
  
  const subject = "Your Password Verification Code";
  const html = `
    <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 12px; background-color: #fafafa;">
      <h2 style="color: #000000; border-bottom: 2px solid #000000; padding-bottom: 10px; font-weight: 800; letter-spacing: 0.5px;">Verification Code</h2>
      <p>Hello ${name},</p>
      <p>We received a request to reset the password for your Zanny Collection account. Please use the following 6-digit verification code to proceed:</p>
      <p style="text-align: center; margin-top: 30px; margin-bottom: 30px;">
        <span style="background-color: #f3f4f6; color: #000000; padding: 14px 28px; border-radius: 8px; font-size: 26px; font-weight: 900; letter-spacing: 6px; border: 1px solid #e5e7eb; display: inline-block;">${code}</span>
      </p>
      <p>This code is valid for the next 15 minutes. If you did not request this, you can safely ignore this email.</p>
      <p style="color: #666; font-size: 11px; text-align: center; margin-top: 40px; border-top: 1px solid #eee; padding-top: 20px;">
        Zanny Collection. All rights reserved.
      </p>
    </div>
  `;

  const emailResult = await sendResendEmail(env, em, subject, html);
  if (!emailResult.success) {
    return jsonError(`Failed to send verification email: ${emailResult.error}`, 500);
  }
  
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    event: "PASSWORD_RESET_REQUESTED",
    email: em,
    status: "success"
  }));

  return json({ success: true, message: 'Verification code sent successfully.' });
}

async function handleResetPassword(request, env) {
  const { email, code, password } = await request.json().catch(() => ({}));
  if (!email || !code || !password) return jsonError('Email, code, and password are required', 400);
  if (password.length < 6) return jsonError('Password must be at least 6 characters long', 400);
  const em = email.trim().toLowerCase();

  // 1. Verify token/code
  const reset = await env.DB.prepare('SELECT * FROM password_resets WHERE email = ? AND token = ?').bind(em, code.trim()).first();
  if (!reset) return jsonError('Invalid verification code or email', 400);

  // Check expiration
  if (new Date(reset.expires_at) < new Date()) {
    await env.DB.prepare('DELETE FROM password_resets WHERE email = ?').bind(em).run();
    return jsonError('Verification code has expired', 400);
  }

  // 2. Hash new password
  const hashObj = await hashPassword(password);

  // 3. Update user password
  await env.DB.prepare('UPDATE users SET password_hash = ?, salt = ? WHERE email = ?')
    .bind(hashObj.hash, hashObj.salt, em)
    .run();

  // 4. Delete the token
  await env.DB.prepare('DELETE FROM password_resets WHERE email = ?').bind(em).run();

  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    event: "PASSWORD_RESET_COMPLETED",
    email: em,
    status: "success"
  }));

  return json({ success: true, message: 'Password has been reset successfully.' });
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
    is_active: row.is_deleted === 0 || row.is_active === 1,
    avg_rating: Math.round((row.avg_rating || 0) * 10) / 10,
    review_count: row.review_count || 0,
    is_preorder: row.is_preorder === 1
  };
}

async function handleGetProducts(request, env, origin = '') {
  const url = new URL(request.url);
  const category = url.searchParams.get('category');
  const search = url.searchParams.get('search');
  const sort = url.searchParams.get('sort') || 'default';
  
  let limit = parseInt(url.searchParams.get('limit') || '200', 10);
  if (isNaN(limit) || limit <= 0) {
    limit = 200;
  }
  limit = Math.min(limit, 500);

  let query = 'SELECT *, ROUND(COALESCE((SELECT AVG(f.rating) FROM feedback f WHERE f.product_id = products.id), 0), 1) as avg_rating, COALESCE((SELECT COUNT(f.id) FROM feedback f WHERE f.product_id = products.id), 0) as review_count FROM products WHERE is_deleted = 0';
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
  const res = json({ products: result.results.map(row => parseProduct(row, env, origin)) });
  res.headers.set('Cache-Control', 'public, max-age=10, s-maxage=10');
  return res;
}

async function handleGetProduct(id, env, origin = '') {
  const row = await env.DB.prepare('SELECT *, ROUND(COALESCE((SELECT AVG(f.rating) FROM feedback f WHERE f.product_id = products.id), 0), 1) as avg_rating, COALESCE((SELECT COUNT(f.id) FROM feedback f WHERE f.product_id = products.id), 0) as review_count FROM products WHERE id = ? AND is_deleted = 0').bind(id).first();
  if (!row) return jsonError('Product not found', 404);
  const res = json({ product: parseProduct(row, env, origin) });
  res.headers.set('Cache-Control', 'public, max-age=10, s-maxage=10');
  return res;
}

async function handleCreateProduct(request, env, origin = '') {
  await requireAdmin(request, env);
  const data = await request.json().catch(() => ({}));
  const id = data.id || crypto.randomUUID();
  
  const mainImage = (data.images && data.images.length > 0) ? data.images[0] : null;
  const galleryUrls = (data.images && data.images.length > 1) ? JSON.stringify(data.images.slice(1)) : '[]';
  const badge = data.is_new ? 'NEW' : (data.is_sale ? 'SALE' : null);

  await env.DB.prepare(`
    INSERT INTO products (id, name, subtitle, category, description, price, original_price, image_url, gallery_urls, colors, sizes, badge, is_new, is_sale, stock, is_preorder, is_deleted)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
  `).bind(
    id, data.name || '', data.subtitle || '', data.category || data.category_slug || '', data.description || '',
    data.price || 0, data.original_price || null, mainImage, galleryUrls,
    JSON.stringify(data.colors || []), JSON.stringify(data.sizes || []), badge,
    data.is_new ? 1 : 0, data.is_sale ? 1 : 0,
    data.stock !== undefined ? data.stock : 10,
    data.is_preorder ? 1 : 0
  ).run();

  if (data.send_push === true) {
    const title = `New Arrival: ${data.name}! 🚀`;
    const body = data.push_body || `Check out the new drop: ${data.name} is in stock now in ${data.category || 'New Arrivals'}. Tap to view!`;
    const route = `/product/${id}`;
    await broadcastFcmNotification(env, title, body, route);
  }
  
  const product = await env.DB.prepare('SELECT * FROM products WHERE id = ?').bind(id).first();
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    event: "PRODUCT_CREATED",
    product_id: id,
    name: data.name || '',
    stock: data.stock !== undefined ? data.stock : 10,
    status: "success"
  }));
  return json({ product: parseProduct(product, env, origin) }, 201);
}

async function handleUpdateProduct(id, request, env, origin = '') {
  await requireAdmin(request, env);
  const data = await request.json().catch(() => ({}));
  
  const mainImage = (data.images && data.images.length > 0) ? data.images[0] : null;
  const galleryUrls = (data.images && data.images.length > 1) ? JSON.stringify(data.images.slice(1)) : '[]';
  const badge = data.is_new ? 'NEW' : (data.is_sale ? 'SALE' : null);

  await env.DB.prepare(`
    UPDATE products SET name=?, subtitle=?, category=?, description=?, price=?, original_price=?,
    image_url=?, gallery_urls=?, colors=?, sizes=?, badge=?, is_new=?, is_sale=?, stock=?, is_preorder=?, is_deleted=?
    WHERE id=?
  `).bind(
    data.name || '', data.subtitle || '', data.category || data.category_slug || '', data.description || '',
    data.price || 0, data.original_price || null, mainImage, galleryUrls,
    JSON.stringify(data.colors || []), JSON.stringify(data.sizes || []), badge,
    data.is_new ? 1 : 0, data.is_sale ? 1 : 0,
    data.stock !== undefined ? data.stock : 10,
    data.is_preorder ? 1 : 0,
    data.is_deleted === true || data.is_active === false ? 1 : 0,
    id
  ).run();

  if (data.send_push === true) {
    const title = `Restocked: ${data.name}! 🚀`;
    const body = data.push_body || `${data.name} is back in stock. Tap to view!`;
    const route = `/product/${id}`;
    await broadcastFcmNotification(env, title, body, route);
  }

  const product = await env.DB.prepare('SELECT * FROM products WHERE id = ?').bind(id).first();
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    event: "PRODUCT_UPDATED",
    product_id: id,
    name: data.name || '',
    stock: data.stock !== undefined ? data.stock : 10,
    status: "success"
  }));
  return json({ product: parseProduct(product, env, origin) });
}

async function handleDeleteProduct(id, request, env) {
  await requireAdmin(request, env);
  
  // Fetch product to find associated images
  const product = await env.DB.prepare('SELECT image_url, gallery_urls FROM products WHERE id = ?').bind(id).first();
  if (product) {
    const keysToDelete = [];
    if (product.image_url) {
      const mainKey = getR2Key(product.image_url);
      if (mainKey) keysToDelete.push(mainKey);
    }
    if (product.gallery_urls) {
      const gallery = parseJsonArray(product.gallery_urls);
      for (const img of gallery) {
        const galKey = getR2Key(img);
        if (galKey) keysToDelete.push(galKey);
      }
    }
    
    // Delete files from Cloudflare R2
    for (const key of keysToDelete) {
      try {
        console.log(`Deleting R2 object: ${key}`);
        await env.R2.delete(key);
      } catch (err) {
        console.error(`Failed to delete R2 object ${key}:`, err);
      }
    }
  }

  await env.DB.prepare('UPDATE products SET is_deleted = 1 WHERE id = ?').bind(id).run();
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    event: "PRODUCT_DELETED",
    product_id: id,
    status: "success"
  }));
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

async function sendResendEmail(env, to, subject, html) {
  if (!env.RESEND_API_KEY) {
    const msg = "env.RESEND_API_KEY not configured, skipping email.";
    console.warn("⚠️ " + msg);
    return { success: false, error: msg };
  }
  const fromEmail = env.RESEND_SENDER || "Zanny Collection <onboarding@resend.dev>";
  try {
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${env.RESEND_API_KEY}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        from: fromEmail,
        to: to,
        subject: subject,
        html: html
      })
    });
    const result = await res.json().catch(() => ({}));
    if (!res.ok) {
      const errMsg = result.message || JSON.stringify(result);
      console.error("❌ Resend error:", result);
      return { success: false, error: `Resend API error: ${errMsg}` };
    }
    console.log(`✅ Email sent successfully: ${result.id}`);
    return { success: true, id: result.id };
  } catch (e) {
    console.error("❌ Resend fetch failed:", e.message);
    return { success: false, error: `Resend fetch failed: ${e.message}` };
  }
}

async function handleCreateOrder(request, env) {
  const payload = await requireUser(request, env);
  const data = await request.json().catch(() => ({}));
  
  // 1. Fetch user to check restricted_from_cod
  const user = await env.DB.prepare('SELECT restricted_from_cod, email FROM users WHERE id = ?').bind(payload.sub).first();
  const paymentMethod = data.payment_method || 'cod';

  if (paymentMethod === 'cod' && user && user.restricted_from_cod === 1) {
    return json({ error: 'Cash on Delivery is currently restricted for your account. Please pay upfront using M-Pesa.' }, 400);
  }

  // 2. Live Stock Check
  const items = data.items || [];
  const preOrderMap = new Map();
  for (const item of items) {
    const prodId = item.product_id || item.product?.id || '';
    if (!prodId) return json({ error: 'Invalid product details' }, 400);
    const prod = await env.DB.prepare('SELECT name, stock, is_preorder FROM products WHERE id = ? AND is_deleted = 0').bind(prodId).first();
    if (!prod) {
      return json({ error: `Product not found: ${item.product_name || prodId}` }, 400);
    }
    preOrderMap.set(prodId, prod.is_preorder === 1);
    if (prod.is_preorder !== 1 && prod.stock < item.quantity) {
      return json({ error: `Insufficient stock for item: ${prod.name}. Available: ${prod.stock}, requested: ${item.quantity}.` }, 400);
    }
  }

  // 3. Generate unique Order ID in the format ORD-XXXXXX (last 6 digits of current timestamp)
  const orderId = 'ORD-' + String(Date.now()).slice(-6);

  // 4. Update Inventory and Insert Order Atomically (via batch transaction)
  const statements = [];
  for (const item of items) {
    const prodId = item.product_id || item.product?.id || '';
    const isPre = preOrderMap.get(prodId) || false;
    if (isPre) {
      statements.push(
        env.DB.prepare('UPDATE products SET sold = sold + ? WHERE id = ?')
          .bind(item.quantity, prodId)
      );
    } else {
      statements.push(
        env.DB.prepare('UPDATE products SET stock = stock - ?, sold = sold + ? WHERE id = ?')
          .bind(item.quantity, item.quantity, prodId)
      );
    }
  }

  // 5. Insert into DB (serialize Snapshots of items)
  statements.push(
    env.DB.prepare(`
      INSERT INTO orders (id, user_id, items, total_amount, status, delivery_address, shipping_address, recipient_name, recipient_phone, phone_number, mpesa_receipt)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      orderId, payload.sub,
      JSON.stringify(items), data.total_amount || 0,
      'pending',
      data.delivery_address || '', data.delivery_address || '',
      data.recipient_name || '', data.recipient_phone || '', data.recipient_phone || '',
      paymentMethod === 'mpesa' ? (data.mpesa_receipt || 'STK_PUSH_PENDING') : ''
    )
  );

  try {
    await env.DB.batch(statements);
    console.log(JSON.stringify({
      timestamp: new Date().toISOString(),
      event: "ORDER_CREATED",
      user_id: payload.sub,
      order_id: orderId,
      amount: data.total_amount || 0,
      payment_method: paymentMethod,
      status: "success"
    }));
  } catch (err) {
    console.error("Order batch execution failed:", err);
    console.error(JSON.stringify({
      timestamp: new Date().toISOString(),
      event: "ORDER_CREATION_FAILED",
      user_id: payload.sub,
      error: err.message || err.toString(),
      status: "error"
    }));
    if (err.message && (err.message.includes('Insufficient stock') || err.message.includes('ABORT'))) {
      return json({ error: 'One or more items in your cart are out of stock. Please adjust your cart and try again.' }, 400);
    }
    return json({ error: 'Failed to place order due to a database/concurrency error. Please try again.' }, 500);
  }

  // 6. Send Placement Emails (Customer Confirmation & Admin Notification)
  const customerEmail = user ? user.email : '';
  const adminEmail = 'zannykenya254@gmail.com';
  
  let itemsHtml = '';
  for (const item of items) {
    itemsHtml += `
      <tr style="border-bottom: 1px solid #eee;">
        <td style="padding: 10px 0;">
          <strong>${item.product_name || item.product?.name || 'Product'}</strong><br/>
          <span style="color: #666; font-size: 11px;">Size: ${item.selected_size || ''} | Color: ${item.selected_color || ''}</span>
        </td>
        <td style="padding: 10px 0; text-align: center;">${item.quantity}</td>
        <td style="padding: 10px 0; text-align: right;">KES ${(item.product_price || item.product?.price || 0) * item.quantity}</td>
      </tr>
    `;
  }

  // Customer Email
  if (customerEmail) {
    const subject = `Your Zanny Collection Order #${orderId} Confirmation`;
    const html = `
      <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 12px; background-color: #fafafa;">
        <h2 style="color: #0A0A0A; border-bottom: 2px solid #0A0A0A; padding-bottom: 10px;">Order Confirmation</h2>
        <p>Hello,</p>
        <p>Thank you for shopping with <strong>Zanny Collection</strong>! Your order has been successfully placed.</p>
        <div style="background-color: #ffffff; padding: 15px; border-radius: 8px; border: 1px solid #ddd; margin: 20px 0;">
          <p><strong>Order ID:</strong> ${orderId}</p>
          <p><strong>Total Amount:</strong> KES ${data.total_amount}</p>
          <p><strong>Delivery Address:</strong> ${data.delivery_address || ''}</p>
          <p><strong>Recipient Name:</strong> ${data.recipient_name || ''}</p>
          <p><strong>Payment Method:</strong> ${paymentMethod === 'cod' ? 'Cash on Delivery' : 'M-Pesa'}</p>
        </div>
        <h3>Items Ordered:</h3>
        <table style="width: 100%; border-collapse: collapse; margin-bottom: 20px;">
          <thead>
            <tr style="border-bottom: 1px solid #ddd; text-align: left;">
              <th style="padding: 8px 0;">Item</th>
              <th style="padding: 8px 0; text-align: center;">Qty</th>
              <th style="padding: 8px 0; text-align: right;">Price</th>
            </tr>
          </thead>
          <tbody>
            ${itemsHtml}
          </tbody>
        </table>
        <p style="text-align: center; margin-top: 30px;">
          <a href="https://zannycollection.com/orders?id=${orderId}" style="background-color: #1E88E5; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block;">TRACK ORDER</a>
        </p>
        <p style="color: #666; font-size: 12px; text-align: center; margin-top: 40px; border-top: 1px solid #eee; padding-top: 20px;">
          Zanny Collection. All rights reserved.
        </p>
      </div>
    `;
    await sendResendEmail(env, customerEmail, subject, html);
  }

  // Admin Email
  {
    const subject = `New Zanny Collection Order Received: #${orderId}`;
    const html = `
      <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 12px; background-color: #fafafa;">
        <h2 style="color: #d32f2f; border-bottom: 2px solid #d32f2f; padding-bottom: 10px;">New Order Received</h2>
        <p>A new order has been placed on Zanny Collection.</p>
        <div style="background-color: #ffffff; padding: 15px; border-radius: 8px; border: 1px solid #ddd; margin: 20px 0;">
          <p><strong>Order ID:</strong> ${orderId}</p>
          <p><strong>Customer Email:</strong> ${customerEmail || 'Guest'}</p>
          <p><strong>Total Amount:</strong> KES ${data.total_amount}</p>
          <p><strong>Delivery Address:</strong> ${data.delivery_address || ''}</p>
          <p><strong>Recipient Name:</strong> ${data.recipient_name || ''}</p>
          <p><strong>Recipient Phone:</strong> ${data.recipient_phone || ''}</p>
          <p><strong>Payment Method:</strong> ${paymentMethod === 'cod' ? 'Cash on Delivery' : 'M-Pesa'}</p>
        </div>
        <h3>Items Ordered:</h3>
        <table style="width: 100%; border-collapse: collapse; margin-bottom: 20px;">
          <thead>
            <tr style="border-bottom: 1px solid #ddd; text-align: left;">
              <th style="padding: 8px 0;">Item</th>
              <th style="padding: 8px 0; text-align: center;">Qty</th>
              <th style="padding: 8px 0; text-align: right;">Price</th>
            </tr>
          </thead>
          <tbody>
            ${itemsHtml}
          </tbody>
        </table>
        <p style="text-align: center; margin-top: 30px;">
          <a href="https://zanny-collection.pages.dev/admin" style="background-color: #0A0A0A; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block;">GO TO ADMIN DASHBOARD</a>
        </p>
        <p style="color: #666; font-size: 12px; text-align: center; margin-top: 40px; border-top: 1px solid #eee; padding-top: 20px;">
          Zanny Collection. All rights reserved.
        </p>
      </div>
    `;
    await sendResendEmail(env, adminEmail, subject, html);
  }

  // 7. Push Notifications — admin (new order alert) + customer (confirmation)
  try {
    const adminUsers = await env.DB.prepare(
      "SELECT id FROM users WHERE is_admin = 1 OR email = 'admin@zannycollection.com'"
    ).all();
    const adminPushPromises = (adminUsers.results || []).map(a =>
      sendFcmToUser(env, a.id, '🛍️ New Order!', `Order #${orderId} placed for KES ${data.total_amount || 0} — tap to review.`, '/orders')
    );
    await Promise.all([...adminPushPromises,
      sendFcmToUser(env, payload.sub, '✅ Order Confirmed!', `Your order #${orderId} has been placed. We'll get it ready for you!`, '/orders')
    ]);
  } catch (e) {
    console.warn('FCM order placement push failed:', e.message);
  }

  return json({ id: orderId, success: true }, 201);
}

async function handleUpdateOrderStatus(orderId, request, env) {
  const userPayload = await requireUser(request, env);
  const { status, items, tracking_number } = await request.json().catch(() => ({}));

  // Fetch current order state
  const order = await env.DB.prepare('SELECT * FROM orders WHERE id = ?').bind(orderId).first();
  if (!order) return jsonError('Order not found', 404);

  // If status is the same, just update other properties
  if (order.status === status && !items && !tracking_number) {
    return json({ success: true });
  }

  // Authorize user: either admin, or the customer themselves (only if status is cancelled and current status is pending)
  const isAdmin = userPayload.is_admin || userPayload.email === 'admin@zannycollection.com';
  if (!isAdmin) {
    if (order.user_id !== userPayload.sub) {
      return jsonError('Unauthorized', 403);
    }
    if (status !== 'cancelled' || order.status !== 'pending') {
      return jsonError('Customers can only cancel pending orders', 400);
    }
  }

  let query = 'UPDATE orders SET status = ?';
  const params = [status];

  if (items) {
    query += ', items = ?';
    params.push(JSON.stringify(items));
  }

  if (tracking_number !== undefined) {
    query += ', tracking_number = ?';
    params.push(tracking_number);
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
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    event: "ORDER_STATUS_UPDATED",
    user_id: userPayload.sub,
    order_id: orderId,
    old_status: order.status,
    new_status: status,
    status: "success"
  }));

  // If status has changed, perform side effects (emails, inventory, trust system)
  if (order.status !== status) {
    // Retrieve user email
    const dbUser = await env.DB.prepare('SELECT email FROM users WHERE id = ?').bind(order.user_id).first();
    const customerEmail = dbUser ? dbUser.email : '';

    const itemsList = parseJsonArray(items || order.items);
    let itemsHtml = '';
    for (const item of itemsList) {
      itemsHtml += `
        <tr style="border-bottom: 1px solid #eee;">
          <td style="padding: 10px 0;">
            <strong>${item.product_name || item.product?.name || 'Product'}</strong><br/>
            <span style="color: #666; font-size: 11px;">Size: ${item.selected_size || ''} | Color: ${item.selected_color || ''}</span>
          </td>
          <td style="padding: 10px 0; text-align: center;">${item.quantity}</td>
          <td style="padding: 10px 0; text-align: right;">KES ${(item.product_price || item.product?.price || 0) * item.quantity}</td>
        </tr>
      `;
    }

    if (status === 'shipped' || status === 'delivering') {
      // Send Shipped Email to customer
      if (customerEmail) {
        const finalTracking = tracking_number || order.tracking_number || '';
        const subject = `Your Order #${orderId} has Shipped!`;
        const html = `
          <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 12px; background-color: #fafafa;">
            <h2 style="color: #8e24aa; border-bottom: 2px solid #8e24aa; padding-bottom: 10px;">Your Order has Shipped!</h2>
            <p>Great news! Your order <strong>#${orderId}</strong> has been shipped and is on its way to you.</p>
            ${finalTracking ? `
              <div style="background-color: #ffffff; padding: 15px; border-radius: 8px; border: 1px solid #ddd; margin: 20px 0;">
                <p><strong>Tracking Identifier:</strong> ${finalTracking}</p>
              </div>
              <p style="text-align: center; margin-top: 30px;">
                <a href="${finalTracking.startsWith('http') ? finalTracking : 'https://www.google.com/search?q=' + encodeURIComponent(finalTracking)}" style="background-color: #8e24aa; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block;">TRACK SHIPMENT</a>
              </p>
            ` : ''}
            <p style="color: #666; font-size: 12px; text-align: center; margin-top: 40px; border-top: 1px solid #eee; padding-top: 20px;">
              Zanny Collection. All rights reserved.
            </p>
          </div>
        `;
        await sendResendEmail(env, customerEmail, subject, html);
      }
      // Push notification to customer: order shipped
      await sendFcmToUser(env, order.user_id, '📦 Your Order is on the Way!', `Order #${orderId} has shipped! We'll notify you when it arrives.`, '/orders').catch(() => {});
    } else if (status === 'delivered') {
      // Send Delivered Email to customer (Styled Receipt & Review Link)
      if (customerEmail) {
        const subject = `Your Order #${orderId} has been Delivered!`;
        const html = `
          <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 12px; background-color: #fafafa;">
            <h2 style="color: #43a047; border-bottom: 2px solid #43a047; padding-bottom: 10px;">Your Order has been Delivered!</h2>
            <p>Hello,</p>
            <p>Your order <strong>#${orderId}</strong> has been successfully delivered. Thank you for shopping with us!</p>
            <div style="background-color: #ffffff; padding: 15px; border-radius: 8px; border: 1px solid #ddd; margin: 20px 0;">
              <p><strong>Order ID:</strong> ${orderId}</p>
              <p><strong>Total Paid:</strong> KES ${order.total_amount}</p>
              <p><strong>Shipping Address:</strong> ${order.delivery_address || order.shipping_address || ''}</p>
            </div>
            <h3>Receipt Summary:</h3>
            <table style="width: 100%; border-collapse: collapse; margin-bottom: 20px;">
              <thead>
                <tr style="border-bottom: 1px solid #ddd; text-align: left;">
                  <th style="padding: 8px 0;">Item</th>
                  <th style="padding: 8px 0; text-align: center;">Qty</th>
                  <th style="padding: 8px 0; text-align: right;">Price</th>
                </tr>
              </thead>
              <tbody>
                ${itemsHtml}
              </tbody>
            </table>
            <p style="text-align: center; margin-top: 35px;">
              <a href="https://zannycollection.com/account" style="background-color: #43a047; color: white; padding: 14px 28px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block;">LEAVE A REVIEW</a>
            </p>
            <p style="color: #666; font-size: 12px; text-align: center; margin-top: 40px; border-top: 1px solid #eee; padding-top: 20px;">
              Zanny Collection. All rights reserved.
            </p>
          </div>
        `;
        await sendResendEmail(env, customerEmail, subject, html);
      }
      // Push notification to customer: order delivered
      await sendFcmToUser(env, order.user_id, '🎉 Order Delivered!', `Your order #${orderId} has arrived! Tap to leave a review.`, '/orders').catch(() => {});

      // Trust system: increment successful orders, check COD privilege restoration
      const user = await env.DB.prepare('SELECT consecutive_successful_orders FROM users WHERE id = ?').bind(order.user_id).first();
      if (user) {
        const successes = (user.consecutive_successful_orders || 0) + 1;
        if (successes >= 3) {
          await env.DB.prepare('UPDATE users SET consecutive_cancellations = 0, restricted_from_cod = 0, consecutive_successful_orders = 0 WHERE id = ?').bind(order.user_id).run();
        } else {
          await env.DB.prepare('UPDATE users SET consecutive_successful_orders = ? WHERE id = ?').bind(successes, order.user_id).run();
        }
      }
    } else if (status === 'cancelled') {
      // 1. Inventory Restoration
      for (const item of itemsList) {
        const prodId = item.product_id || item.product?.id || '';
        if (prodId) {
          await env.DB.prepare('UPDATE products SET stock = stock + ?, sold = sold - ? WHERE id = ?')
            .bind(item.quantity, item.quantity, prodId)
            .run();
        }
      }

      // 2. Trust system penalty
      const user = await env.DB.prepare('SELECT consecutive_cancellations FROM users WHERE id = ?').bind(order.user_id).first();
      if (user) {
        const cancellations = (user.consecutive_cancellations || 0) + 1;
        const restrict = cancellations >= 3 ? 1 : 0;
        await env.DB.prepare('UPDATE users SET consecutive_cancellations = ?, restricted_from_cod = ?, consecutive_successful_orders = 0 WHERE id = ?').bind(cancellations, restrict, order.user_id).run();
      }

      // 3. Admin Notification Email of cancellation
      const adminEmail = 'zannykenya254@gmail.com';
      const subject = `Order Cancelled: #${orderId}`;
      const html = `
        <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 12px; background-color: #fafafa;">
          <h2 style="color: #e53935; border-bottom: 2px solid #e53935; padding-bottom: 10px;">Order Cancelled by Customer</h2>
          <p>Order <strong>#${orderId}</strong> has been cancelled by the customer.</p>
          <div style="background-color: #ffffff; padding: 15px; border-radius: 8px; border: 1px solid #ddd; margin: 20px 0;">
            <p><strong>Order ID:</strong> ${orderId}</p>
            <p><strong>Total Amount:</strong> KES ${order.total_amount}</p>
          </div>
          <p style="color: #666; font-size: 12px; text-align: center; margin-top: 40px; border-top: 1px solid #eee; padding-top: 20px;">
            Zanny Collection. All rights reserved.
          </p>
        </div>
      `;
      await sendResendEmail(env, adminEmail, subject, html);
      // Push notification to customer: order cancelled
      await sendFcmToUser(env, order.user_id, 'Order Cancelled', `Your order #${orderId} has been cancelled. We hope to serve you again!`, '/orders').catch(() => {});
      // Push notification to admin: customer cancelled
      const cancelAdmins = await env.DB.prepare("SELECT id FROM users WHERE is_admin = 1 OR email = 'admin@zannycollection.com'").all();
      await Promise.all((cancelAdmins.results || []).map(a =>
        sendFcmToUser(env, a.id, '❌ Order Cancelled', `Customer cancelled order #${orderId} for KES ${order.total_amount}.`, '/orders').catch(() => {})
      ));
    }
  }

  return json({ success: true });
}

async function handleGetPendingFeedback(request, env) {
  const payload = await requireUser(request, env);
  const userId = payload.sub;

  // Fetch the last 5 delivered orders that are not permanently dismissed
  const ordersResult = await env.DB.prepare(`
    SELECT * FROM orders
    WHERE user_id = ? 
      AND status = 'delivered'
      AND (review_prompt_dismissed = 0 OR review_prompt_dismissed IS NULL)
    ORDER BY created_at DESC
    LIMIT 5
  `).bind(userId).all();

  const orders = ordersResult.results || [];
  if (orders.length === 0) {
    return json({ pending: false });
  }

  const ONE_HOUR_MS = 60 * 60 * 1000;
  const now = Date.now();

  for (const order of orders) {
    // Enforce 1-hour delay after delivery before showing review prompt
    if (order.delivered_at) {
      const deliveredTime = new Date(order.delivered_at).getTime();
      if (now - deliveredTime < ONE_HOUR_MS) {
        continue; // Skip this order — not enough time has passed
      }
    }

    // Fetch all feedback entries submitted for this order
    const feedbacksResult = await env.DB.prepare(
      'SELECT product_id FROM feedback WHERE order_id = ?'
    ).bind(order.id).all();
    const feedbacks = feedbacksResult.results || [];
    const reviewedProductIds = new Set(feedbacks.map(f => f.product_id).filter(Boolean));

    const allItems = parseJsonArray(order.items);
    // Filter to keep only the items that have not been reviewed yet
    const unreviewedItems = allItems.filter(item => {
      const productId = item.product?.id || item.product_id;
      return productId && !reviewedProductIds.has(productId);
    });

    if (unreviewedItems.length > 0) {
      return json({
        pending: true,
        order: {
          id: order.id,
          items: unreviewedItems,
          total_amount: order.total_amount,
          created_at: order.created_at
        }
      });
    } else {
      // All items in this order have been reviewed. Mark the order as dismissed permanently.
      await env.DB.prepare(
        'UPDATE orders SET review_prompt_dismissed = 1 WHERE id = ?'
      ).bind(order.id).run();
    }
  }

  return json({ pending: false });
}

async function handleGetOrderReviewedProducts(orderId, request, env) {
  const payload = await requireUser(request, env);
  const userId = payload.sub;

  // Verify the order belongs to this user
  const order = await env.DB.prepare(
    'SELECT id FROM orders WHERE id = ? AND user_id = ?'
  ).bind(orderId, userId).first();

  if (!order) {
    return jsonError('Order not found', 404);
  }

  const feedbacksResult = await env.DB.prepare(
    'SELECT product_id FROM feedback WHERE order_id = ? AND product_id IS NOT NULL'
  ).bind(orderId).all();

  const reviewedProductIds = (feedbacksResult.results || []).map(f => f.product_id);
  return json({ reviewed_product_ids: reviewedProductIds });
}

async function handlePostFeedback(request, env) {
  const payload = await requireUser(request, env);
  const userId = payload.sub;
  const { order_id, product_id, rating, comment } = await request.json().catch(() => ({}));

  if (!order_id || !rating) {
    return jsonError('order_id and rating are required', 400);
  }

  const order = await env.DB.prepare(
    'SELECT * FROM orders WHERE id = ? AND user_id = ?'
  ).bind(order_id, userId).first();

  if (!order) {
    return jsonError('Order not found', 404);
  }

  if (order.status !== 'delivered') {
    return jsonError('Order must be delivered to leave feedback', 400);
  }

  let existingFeedback;
  if (product_id) {
    existingFeedback = await env.DB.prepare(
      'SELECT id FROM feedback WHERE order_id = ? AND product_id = ?'
    ).bind(order_id, product_id).first();
  } else {
    existingFeedback = await env.DB.prepare(
      'SELECT id FROM feedback WHERE order_id = ?'
    ).bind(order_id).first();
  }

  if (existingFeedback) {
    return jsonError('Feedback has already been submitted for this item', 409);
  }

  const sanitizedComment = (comment || '').replace(/<[^>]*>?/gm, '').substring(0, 1000);
  const id = `FB-${crypto.randomUUID().slice(-12)}`;

  // Insert feedback
  await env.DB.prepare(
    'INSERT INTO feedback (id, order_id, product_id, user_id, rating, comment) VALUES (?, ?, ?, ?, ?, ?)'
  ).bind(id, order_id, product_id || null, userId, rating, sanitizedComment).run();
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    event: "FEEDBACK_SUBMITTED",
    user_id: userId,
    order_id: order_id,
    product_id: product_id || null,
    rating: rating,
    status: "success"
  }));

  // Send Thank You Email to customer
  try {
    const user = await env.DB.prepare('SELECT email, full_name FROM users WHERE id = ?').bind(userId).first();
    if (user && user.email) {
      const customerEmail = user.email;
      const customerName = user.full_name || 'Valued Customer';
      const subject = 'Thank You for Your Feedback! - Zanny Collection';
      const html = `
        <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 12px; background-color: #fafafa;">
          <h2 style="color: #8e24aa; border-bottom: 2px solid #8e24aa; padding-bottom: 10px;">Thank You for Your Review!</h2>
          <p>Hello ${customerName},</p>
          <p>Thank you so much for sharing your feedback on your recent purchase (Order <strong>#${order_id}</strong>).</p>
          <p>We read every review to make sure we are delivering the best fashion and service in Kenya. Your feedback helps us grow and keep improving!</p>
          <div style="background-color: #ffffff; padding: 15px; border-radius: 8px; border: 1px solid #ddd; margin: 20px 0; font-style: italic;">
            "&ldquo;${sanitizedComment || 'Rating: ' + rating + '/5 stars'}&rdquo;"
          </div>
          <p>As always, we look forward to styling you again soon.</p>
          <p style="color: #666; font-size: 12px; text-align: center; margin-top: 40px; border-top: 1px solid #eee; padding-top: 20px;">
            Zanny Collection. All rights reserved.
          </p>
        </div>
      `;
      await sendResendEmail(env, customerEmail, subject, html);
    }
  } catch (e) {
    console.error("❌ Failed to send review thank-you email:", e.message);
  }

  // Check if there are any remaining unreviewed items in this order
  const feedbacksResult = await env.DB.prepare(
    'SELECT product_id FROM feedback WHERE order_id = ?'
  ).bind(order_id).all();
  const feedbacks = feedbacksResult.results || [];
  const reviewedProductIds = new Set(feedbacks.map(f => f.product_id).filter(Boolean));

  const allItems = parseJsonArray(order.items);
  const unreviewedItems = allItems.filter(item => {
    const pId = item.product?.id || item.product_id;
    return pId && !reviewedProductIds.has(pId);
  });

  if (unreviewedItems.length === 0) {
    // All items reviewed! Mark order as dismissed permanently.
    await env.DB.prepare(
      'UPDATE orders SET review_prompt_dismissed = 1 WHERE id = ?'
    ).bind(order_id).run();
  }

  return json({ success: true, id });
}

async function handleDismissReview(orderId, request, env) {
  const payload = await requireUser(request, env);
  const userId = payload.sub;

  const order = await env.DB.prepare(
    'SELECT id FROM orders WHERE id = ? AND user_id = ?'
  ).bind(orderId, userId).first();

  if (!order) {
    return jsonError('Order not found', 404);
  }

  await env.DB.prepare(
    'UPDATE orders SET review_prompt_dismissed = 1 WHERE id = ?'
  ).bind(orderId).run();

  return json({ success: true });
}

async function handleGetProductReviews(productId, request, env) {
  const reviews = await env.DB.prepare(`
    SELECT f.id, f.rating, f.comment, f.created_at, u.full_name, u.avatar_url
    FROM feedback f
    LEFT JOIN users u ON f.user_id = u.id
    WHERE f.product_id = ?
    ORDER BY f.created_at DESC
  `).bind(productId).all();

  const reviewsList = reviews.results || [];
  
  let sum = 0;
  const distribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
  
  for (const r of reviewsList) {
    sum += r.rating;
    const rate = Math.min(5, Math.max(1, Math.round(r.rating)));
    distribution[rate] = (distribution[rate] || 0) + 1;
  }
  
  const total = reviewsList.length;
  const average = total > 0 ? parseFloat((sum / total).toFixed(1)) : 0.0;
  
  const distributionPercentage = {};
  for (let i = 1; i <= 5; i++) {
    distributionPercentage[i] = total > 0 ? parseFloat(((distribution[i] / total) * 100).toFixed(0)) : 0;
  }

  return json({
    productId,
    average,
    total,
    distribution: distributionPercentage,
    reviews: reviewsList
  });
}

async function handleGetAdminReviews(request, env) {
  try {
    await requireAdmin(request, env);
    const reviews = await env.DB.prepare(`
      SELECT f.id, f.order_id, f.rating, f.comment, f.created_at, 
             u.email, u.full_name, p.name as product_name, p.image_url as product_image
      FROM feedback f
      LEFT JOIN users u ON f.user_id = u.id
      LEFT JOIN products p ON f.product_id = p.id
      ORDER BY f.created_at DESC
    `).all();

    return json({ reviews: reviews.results || [] });
  } catch (err) {
    if (err.status) {
      return jsonError(err.message, err.status);
    }
    throw err;
  }
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
  const defaultVersion = { version: '1.0.2', build: 2, apk_url: '', changelog: 'Initial release' };
  try {
    const obj = await env.R2.get('version.json');
    if (!obj) {
      return new Response(JSON.stringify(defaultVersion), {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache, no-store, must-revalidate'
        }
      });
    }
    return new Response(await obj.text(), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache, no-store, must-revalidate'
      }
    });
  } catch {
    return new Response(JSON.stringify(defaultVersion), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache, no-store, must-revalidate'
      }
    });
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
  const body = `A new version of Zanny Collection is available. Update now to get the latest features and enhancements!`;
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

// Send a push notification to a single user by their user ID
async function sendFcmToUser(env, userId, title, body, route) {
  if (!env.FIREBASE_PROJECT_ID || !env.FIREBASE_CLIENT_EMAIL || !env.FIREBASE_PRIVATE_KEY) return;
  try {
    const user = await env.DB.prepare("SELECT fcm_token FROM users WHERE id = ?").bind(userId).first();
    if (!user || !user.fcm_token) return;
    const accessToken = await getFcmAccessToken(env);
    await fetch(`https://fcm.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/messages:send`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        message: {
          token: user.fcm_token,
          notification: { title, body },
          data: { route: route || '/orders' },
          android: {
            priority: 'high',
            notification: {
              channel_id: 'zanny_high_importance',
              notification_priority: 'PRIORITY_MAX',
              sound: 'default',
              default_sound: true,
              default_vibrate_timings: true
            }
          }
        }
      })
    });
  } catch (e) {
    console.error(`sendFcmToUser(${userId}) failed: ${e.message}`);
  }
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
      "SELECT DISTINCT fcm_token FROM users WHERE fcm_token IS NOT NULL AND fcm_token != ''"
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
            data: { route: route || "/orders" },
            android: {
              priority: "high",
              notification: {
                channel_id: "zanny_high_importance",
                notification_priority: "PRIORITY_MAX",
                sound: "default",
                default_sound: true,
                default_vibrate_timings: true
              }
            }
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

async function handleSendAdvertisement(request, env) {
  await requireAdmin(request, env);
  const data = await request.json().catch(() => ({}));
  const title = data.title;
  const body = data.body;
  const route = data.route || '/profile';
  if (!title || !body) {
    return json({ error: 'Title and body are required' }, 400);
  }
  const result = await broadcastFcmNotification(env, title, body, route);
  return json({ success: true, count: result.count || 0 });
}

async function handleGetSetting(key, env) {
  const row = await env.DB.prepare('SELECT value FROM app_settings WHERE key = ?').bind(key).first();
  return json({ key, value: row ? row.value : null });
}

async function handleUpdateSetting(key, request, env) {
  await requireAdmin(request, env);
  const data = await request.json().catch(() => ({}));
  const value = data.value;
  if (value === undefined) {
    return json({ error: 'Value is required' }, 400);
  }
  await env.DB.prepare('INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)')
    .bind(key, value)
    .run();
  return json({ success: true, key, value });
}


