# Backend URL Configuration

## Quick Setup

The app defaults to production (`https://app.onpu.app`). To use a local backend during development:

### 1. Start Local Backend

In separate terminals:

```bash
# Terminal 1: Redis
redis-server

# Terminal 2: Backend API
cd backend
npm run dev

# Terminal 3: Backend Worker
cd backend
npm run worker:dev
```

### 2. Configure iOS App

1. Run the app in Xcode
2. Go to **Home** tab
3. Tap the **🔧 wrench icon** (top right)
4. In "Override base URL" field, enter: `http://localhost:3001`
5. Tap outside the field to save

The app will now connect to your local backend.

### 3. Switch Back to Production

In AuthDebugView:
- Tap **"Clear override"** button

OR manually:
- Clear the "Override base URL" field

## Backend URLs

- **Local Development**: `http://localhost:3001`
- **Production**: `https://app.onpu.app`

## Verify Connection

In AuthDebugView, check:
- **Base URL**: Should show your configured URL
- **Last API response**: Should show `200` after successful requests

You can also tap **"Ping /v1/auth/me"** to test the connection.

## Backend Compatibility

The new iOS client with stage updates is **fully backwards compatible**:

- ✅ New iOS client + Old backend → Shows "Processing…"
- ✅ New iOS client + New backend → Shows "Translating…", "Drawing pitch lines…", etc.

To see the new stage updates, rebuild and restart your local backend:

```bash
cd backend
npm run build
npm run dev        # (in one terminal)
npm run worker:dev # (in another terminal)
```

## Troubleshooting

### Backend not responding

Check that all services are running:

```bash
# Test Redis
redis-cli ping
# Should return: PONG

# Test Backend API
curl http://localhost:3001/healthz
# Should return: {"ok":true}

# Test with auth
curl -H "tarukingu: tarukingu" -H "X-Dev-Token: dev123" http://localhost:3001/v1/auth/me
# Should return: {"ok":true,"sub":"dev-user"}
```

### Jobs stuck in "Queued"

Check the worker is running and consuming jobs:

```bash
curl -H "tarukingu: tarukingu" -H "X-Dev-Token: dev123" http://localhost:3001/v1/debug/queue
```

This shows queue status and job counts.
