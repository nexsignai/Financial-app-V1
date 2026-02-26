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

# Build with Supabase (replace with your project values)
flutter build web --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY

# Or build without Supabase (app works with in-memory store)
flutter build web
```

Output is in **`build/web/`** (static files: `index.html`, `main.dart.js`, assets).

## 3. Deploy as website

### Option A: Vercel

1. Install Vercel CLI: `npm i -g vercel`
2. From project root, deploy the built folder:
   ```bash
   cd build/web && vercel --prod
   ```
   Or: **Vercel Dashboard → New Project → Import** and set:
   - **Root Directory:** `financial_app`
   - **Build Command:** `flutter build web` (requires Flutter in Vercel environment; otherwise build locally and set **Output Directory** to `build/web` after a script that runs `flutter build web`)

   Simpler: build locally, then deploy the built folder:
   ```bash
   cp vercel.json build/web/
   cd build/web && vercel --prod
   ```
   (Copying `vercel.json` into `build/web` enables SPA rewrites.)

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

### SPA routing (all routes → index.html)

For Vercel, add **`vercel.json`** in the **root that contains the deployed files** (e.g. inside `build/web` if you deploy that folder):

```json
{
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
}
```

For Netlify, add **`build/web/_redirects`** (or **`netlify.toml`** in project root with `publish = "build/web"`):

```
/*    /index.html   200
```

## 4. Verify after deploy

- Open the deployed URL.
- Add a remittance, tour, or exchange transaction → **Cash Flow** and **Profit Breakdown** should update immediately (dynamic updates are wired to `HistoryStore`).
- If you connected Supabase, configure Auth and tables as needed; the app currently runs with in-memory data until you switch to Supabase persistence.
