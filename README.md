# music-room

docker-compose up --build

docker compose down -v

http://localhost:8000/admin admin/admin

## Backend Code requirements

1. use flake8 for checking your python code

## Frontend

Refer to this link to setup flutter in linux https://docs.flutter.dev/get-started/install/linux/web

After you have flutter installed and configured, `cd frontend-dart` then `flutter run` for mobile version, else `docker compose up` will suffice for web version.

If you face network issue for windows run this command in powershell as admin `net stop winnat`, restart docker desktop, `net start winnat`.

## Google Sign-In Android Fix

Missing `android/app/google-services.json`:
1. Go to Firebase Console, add Android app with package `com.example.music_room`
2. Download `google-services.json` and place in `android/app/`
3. Add your debug SHA keys to Firebase (run `android/get_sha_keys.bat`)
4. Clean rebuild: `flutter clean && flutter pub get && flutter run`
