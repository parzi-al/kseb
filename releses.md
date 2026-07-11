# Release Cycle

Use this branch flow for production releases:

1. Build and test feature work on `v7` or a feature branch.
2. Merge tested work into `staging`.
3. Let the `Aumlux Release Cycle` GitHub Action build the staging artifact.
4. Test the staging artifact before promoting.
5. Merge `staging` into `releases`.
6. Push `releases` to deploy production.

## Branches

- `v7`: active development for the current app version.
- `staging`: production-mode test build branch.
- `releases`: production deployment branch.

## Commands

```bash
git checkout staging
git merge v7
git push origin staging
```

After staging is tested:

```bash
git checkout releases
git merge staging
git push origin releases
```

## Firebase Rules

Tender records use Firestore only. Deploy rules with:

```bash
firebase deploy --only firestore:rules
```

Do not deploy Storage for the tender flow. PDF and XLSX files are generated in the app and downloaded locally.
