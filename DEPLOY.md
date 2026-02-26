# Deploy Financial App (Flutter Web + Supabase)

## 1. Supabase setup

1. Create a project at [supabase.com](https://supabase.com).
2. In **Settings → API** copy:
   - **Project URL** → use as `SUPABASE_URL`
   - **anon public** key → use as `SUPABASE_ANON_KEY`
3. **Create tables**: In Supabase Dashboard go to **SQL Editor** → **New query**, paste the contents of **`supabase_schema.sql`** (in the project root), and run it. This creates `remittance_transactions`, `exchange_transactions`, `tour_transactions`, `daily_sold_profits`, and `app_settings` (for opening cash), plus RLS policies so the app can read/write with the anon key.

## 2. Build for web

From the project root (`financial_app/`):

```bash
# Install dependencies
flutter pub get

# Production build with Supabase (uses HTML/CanvasKit, not WASM)
flutter build web --no-wasm-dry-run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY

# Or build without Supabase (app works with in-memory store, login will show "Supabase not configured")
flutter build web --no-wasm-dry-run
```

- **`--no-wasm-dry-run`** avoids WASM compatibility warnings and keeps the build on the standard HTML/CanvasKit renderer (no WASM).
- **Supabase values** are injected at build time via `--dart-define`; never commit real keys. Use env vars or CI secrets in production (e.g. `SUPABASE_URL` / `SUPABASE_ANON_KEY`).

Output is in **`build/web/`**. The contents of **`web/`** (including `vercel.json` and `_redirects`) are copied into `build/web/` so SPA routing works after deploy.

## 3. Deploy as website

### Option A: Vercel

1. Build locally (see step 2 above). The **`web/vercel.json`** is copied into **`build/web/`** automatically, so SPA rewrites are already in the deploy folder.
2. Deploy the built folder:
   ```bash
   cd build/web && vercel --prod
   ```
   Or: **Vercel Dashboard → New Project → Deploy** and upload or connect repo; set **Output Directory** to `build/web` and **Build Command** to your `flutter build web ...` with dart-defines (use env vars for secrets).

### Option B: Netlify

1. Build locally: `flutter build web`
2. **Netlify Dashboard → Add new site → Deploy manually**: drag and drop the **`build/web`** folder.
   Or with Netlify CLI: `netlify deploy --dir=build/web --prod`

### Option C: Firebase Hosting

```bash
firebase init hosting
# Set public directory to: build/web
# Configure as SPA: add rewrites to index.html

flutter build web
firebase deploy
```

### SPA routing (no 404 on refresh)

The repo already includes:

- **`web/vercel.json`** – rewrites all routes to `/index.html` (Vercel). Flutter copy puts it in `build/web/`.
- **`web/_redirects`** – Netlify rule `/* /index.html 200`. Also copied to `build/web/`.

So after `flutter build web`, **`build/web/`** is ready for both Vercel and Netlify without extra steps.

## 4. Verify after deploy

- Open the deployed URL.
- Add a remittance, tour, or exchange transaction → **Cash Flow** and **Profit Breakdown** should update immediately (dynamic updates are wired to `HistoryStore`).
- If you connected Supabase, configure Auth and tables as needed; the app currently runs with in-memory data until you switch to Supabase persistence.
