# App-ads.txt Setup

This repo now includes a deployable `app-ads.txt` file for AdMob verification.

## Included

- Hosted file: `public/app-ads.txt`
- Expected live URL: `https://nikahblessing.com/app-ads.txt`
- Current record:

```txt
google.com, pub-7680801902697776, DIRECT, f08c47fec0942fa0
```

## Hosting notes

- `firebase.json` now includes a `hosting` section that serves files from `public/`
- `privacy_policy.html` is mirrored to `public/privacy-policy/index.html`
- `child_safety_standards.html` is mirrored to `public/child-safety-standards/index.html`

## Deploy

```bash
firebase deploy --only hosting
```

## Verify

After deployment, confirm these URLs load in a browser:

- `https://nikahblessing.com/app-ads.txt`
- `https://nikahblessing.com/privacy-policy`
- `https://nikahblessing.com/child-safety-standards`

Once `app-ads.txt` is reachable, use the AdMob or Play Console verification flow to crawl the file.

## Assumption

This setup assumes your developer website domain is `nikahblessing.com`, which matches the URLs already referenced in the Android manifest and project docs.
