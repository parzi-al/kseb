# Release Process

This repo uses a two-step release cycle:

1. Merge feature work into `staging`.
2. Validate the release build artifact from the `Aumlux Release Cycle` GitHub Action.
3. Merge `staging` into `releases` only after staging validation passes.
4. Push to `releases` to deploy the production GitHub Pages build.

## Branch Responsibilities

- `v7` and feature branches: active development.
- `staging`: production-mode test builds. The workflow builds the APK and web app and uploads the generated site/APK artifact for testing.
- `releases`: production deployment branch. A push to this branch deploys the GitHub Pages production site.

## Commands

```bash
git checkout staging
git merge v7
git push origin staging
```

After the staging artifact is tested:

```bash
git checkout releases
git merge staging
git push origin releases
```
