Next steps:
1) Open: ../../../quickstart_wordlist_app
2) Ensure Flutter SDK is set in android/local.properties (Flutter does this automatically on first run)
3) Get packages:
   cd ../../../quickstart_wordlist_app/mobile_app && flutter pub get
4) Build & run:
   - APK (debug):   ../../../quickstart_wordlist_app/scripts/build_apk.sh --debug
   - APK (release): ../../../quickstart_wordlist_app/scripts/build_apk.sh --release --no-install --no-launch
   - AAB (release): ../../../quickstart_wordlist_app/scripts/build_aab.sh
5) Rename remaining identifiers as desired and set up release signing when ready.