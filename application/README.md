# web — Next.js service

A single Next.js (App Router) app that serves both the frontend and a small
backend-for-frontend (BFF).

| Path | What it is |
| --- | --- |
| `/` | Frontend: a large "Hello World" page, with the running version (`APP_VERSION`) under it |
| `/api/health` | BFF health check: `{"status":"ok","version":"<git sha>","uptimeSeconds":n}` |

## Scripts

```bash
npm ci              # install exact versions from package-lock.json
npm run dev         # local dev server on http://localhost:3000
npm run lint        # ESLint (fails on any warning)
npm run typecheck   # TypeScript, no emit
npm run build       # production build (standalone output, used by the Dockerfile)
```

## Configuration

| Variable | Default | Purpose |
| --- | --- | --- |
| `PORT` | `3000` | Port the server listens on |
| `HOSTNAME` | `0.0.0.0` in the container | Bind address of the standalone server |
| `APP_VERSION` | `dev` | Version reported by `/api/health`; set to the git SHA at image build time |
