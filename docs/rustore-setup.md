# Publishing IU Alumni to RuStore

One-time setup for the `Release to RuStore` workflow
(`.github/workflows/release-rustore.yml`). It replaces the removed
`build-apk.sh` and the old Google Play workflow.

The app is Android-ready: package `com.innopolis.alumni`, label "IU Alumni",
and `android/app/build.gradle` reads its signing config from environment
variables (which the workflow provides from GitHub Secrets).

Steps marked **[you]** must be done by a human.

---

## Two sets of credentials — do not mix them up

| Purpose | Where it comes from | Secret names |
|---|---|---|
| **Sign the APK** | Your **own** release keystore (`.jks`). RuStore does *not* re-sign your app. | `ANDROID_KEYSTORE_*` |
| **Upload to RuStore** | Private key + key ID generated in the RuStore Console. | `RUSTORE_KEY_ID`, `RUSTORE_PRIVATE_KEY` |

The first is about making the APK carry a valid release signature; the second
authenticates the API calls that push the build.

---

## 1. Create the app in RuStore **[you]**

1. Go to <https://console.rustore.ru> and sign in.
2. Create the app (package `com.innopolis.alumni`, name "IU Alumni").
3. Complete the store listing (description, screenshots, icon, category,
   age rating, privacy policy, etc.) — the workflow only uploads a build and
   release notes; it does **not** manage the store listing.
4. **Upload the first version manually** through the console. The RuStore API
   can only create a new draft when an active app version already exists, so
   the very first release must be done by hand.

## 2. Your release keystore **[you]**

Generate it once and back it up somewhere durable — unlike Google Play, RuStore
cannot reset a lost key for you. Losing it means your existing users can no
longer update.

```bash
keytool -genkeypair -v -keystore ~/iu-alumni-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Remember the keystore password and the key password you enter.

> Keep using the **same** keystore for every release. RuStore (like Android
> itself) will reject an update signed with a different key.

## 3. RuStore API key **[you]**

1. RuStore Console → **Company** (or **Developer** for individuals) tab.
2. Left sidebar → **API RuStore**.
3. Click **Create a key**, pick a name (e.g. `CI upload`), select the
   **IU Alumni** app, and grant the **App upload and publication** methods.
4. Click **Generate key** and copy the **key ID** and the **private key**.

The private key is shown as a base64 string starting `MII…`. Convert it to a PEM
file so the workflow's `openssl` step can use it directly:

```bash
# paste the base64 string from the console into a file, then:
printf '%s' 'MII…' | base64 -d > rustore-key.p8
openssl rsa -in rustore-key.p8 -out rustore-key.pem
rm rustore-key.p8
```

> The key is tied to the **company**, not to your user. Rotate it if the person
> who created it leaves.

## 4. Add repository secrets **[you]**

`Settings → Secrets and variables → Actions` in `iu-alumni-mobile`. The workflow
uses the **production** environment, so add them there (create the environment
if it does not exist) or at repo level.

| secret | value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -i ~/iu-alumni-release.jks` (macOS) / `base64 -w0` (Linux) |
| `ANDROID_KEYSTORE_PASSWORD` | keystore password from step 2 |
| `ANDROID_KEY_ALIAS` | `upload` |
| `ANDROID_KEY_PASSWORD` | key password (often the same as the keystore password) |
| `RUSTORE_KEY_ID` | key ID from step 3 |
| `RUSTORE_PRIVATE_KEY` | full contents of `rustore-key.pem` from step 3 (with `BEGIN`/`END` lines) |

`API_BASE_URL`, `APP_METRICA_KEY` and `IU_ALUMNI_WEB_SALT` already exist.

> **PEM pasting gotcha:** pasting a multi-line PEM into the GitHub secret UI can
> turn newlines into literal `\n`. Safer to set it from the CLI:
>
> ```bash
> gh secret set RUSTORE_PRIVATE_KEY --env production < rustore-key.pem
> ```

## 5. Run the pipeline

The workflow runs automatically when a **GitHub Release is published**
(`release` → `published`), or manually:

Actions → **Release to RuStore** → Run workflow:

- `version_name`: leave empty to take it from the release tag (`v1.2.0` → `1.2.0`)
  or `pubspec.yaml`.
- `whats_new`: release notes in **Russian** (required by RuStore). On a published
  Release this defaults to the GitHub Release body.
- `publish_type`:
  - `INSTANTLY` — auto-publish as soon as moderation passes (default)
  - `MANUAL` — a human publishes after moderation
  - `DELAYED` — schedule publication (not wired up here)
- `submit_for_review`: uncheck to only upload the build (leave it as a draft) and
  submit from the console yourself.

The signed APK is also attached to the workflow run as an artifact
(`iu-alumni-<version>-<code>.apk`), retained for 14 days.

### Versioning

`versionCode` is `100 + github.run_number`, so it always increases — RuStore
rejects a build whose code is not higher than the last one. `versionName` comes
from the release tag if present, otherwise `pubspec.yaml`, and can be overridden
per run.

The `100` offset (`VERSION_CODE_OFFSET`) exists so codes stay above anything
published before this pipeline. If you have already shipped a build with a code
above 100, raise it in the workflow.

---

## Behaviour notes

- **One draft at a time.** RuStore allows a single draft per app. The workflow
  deletes any existing draft before creating a new one, so re-running a failed
  release is safe — but it will also discard a draft you were editing by hand.
- **First version is manual.** The API cannot create a draft until an active
  version exists in the console (see step 1).
- **Store listing is not managed by CI.** Only the build + release notes are
  uploaded; everything else stays in the console.

## What is not automated

- **iOS / App Store** — separate pipeline, needs an Apple Developer account and a
  macOS runner.
- **Screenshots / icon / full description** — set once in the console; the API
  methods exist if you want to manage them from CI later.
- **`DELAYED` publication** — the `publish_type` input accepts it, but the
  workflow does not yet pass a `publishDateTime`.
