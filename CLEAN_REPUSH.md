# Clean Re-Push for Same Names

Use this when you want to keep the same GitHub repo name and the same Render service idea, but replace the old contents with this cleaned project.

## 1. Keep only the real project files

This repo should mainly contain:

- `client/`
- `server/`
- `package.json`
- `README.md`
- `render.yaml`
- `SECURITY.md`
- `CLEAN_REPUSH.md`

The root `.gitignore` already excludes local build output, duplicate upload folders, and temporary room data.

## 2. Reuse the same GitHub repo name

If you want the old repo name, you do not need a new name at all.

You have two clean options:

1. Delete everything in the old GitHub repo, then push this project into that same repo again.
2. Delete the old GitHub repo, create a new empty repo with the exact same name, then push this project.

From the project root:

```powershell
git init
git add .
git commit -m "Clean KnightLink repo"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_OLD_REPO_NAME.git
git push -u origin main --force
```

## 3. Reuse or reset Render

If you want to keep the same Render setup name:

1. Open Render.
2. Either reconnect the existing service to the cleaned repo state, or delete and recreate the service with the same name.
3. Let Render read `render.yaml`.
4. Confirm these values:

- `rootDir`: `server`
- `buildCommand`: `npm install`
- `startCommand`: `npm start`
- `healthCheckPath`: `/health`

## 4. Only change the app URL if Render gives you a new domain

If Render keeps the same domain, you do not need to change the app.

If the Render URL changes, update:

- [online_service.dart](</C:/Users/shank/Documents/New project 2/client/lib/features/online/online_service.dart>)

Change `hostedServerUrl` to the new Render domain, then rebuild the APK.

## 5. Verify before pushing

From the project root:

```powershell
npm run server:test
```

From `client/`:

```powershell
flutter analyze
flutter test
```
