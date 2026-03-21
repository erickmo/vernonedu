APP_NAME=vernonedu_dashboard

.PHONY: get run run-dev run-prod build-web test analyze gen clean

get:
	flutter pub get

run:
	flutter run -d chrome --web-port=3001

run-dev:
	flutter run -d chrome --web-port=3001 --dart-define=BASE_URL=http://localhost:8081/api/v1

run-prod:
	flutter run -d chrome --dart-define=BASE_URL=https://api.vernonedu.com/api/v1

build-web:
	flutter build web --release \
		--dart-define=BASE_URL=https://api.vernonedu.com/api/v1 \
		--pwa-strategy offline-first

test:
	flutter test

analyze:
	flutter analyze

gen:
	dart run build_runner build --delete-conflicting-outputs

clean:
	flutter clean && flutter pub get
