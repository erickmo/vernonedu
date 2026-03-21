APP_NAME=vernonedu_mentors

.PHONY: get run run-dev test analyze clean

get:
	flutter pub get

run:
	flutter run

run-dev:
	flutter run --dart-define=BASE_URL=http://localhost:8081/api/v1

run-staging:
	flutter run --dart-define=BASE_URL=https://staging-api.vernonedu.com/api/v1

test:
	flutter test

analyze:
	flutter analyze

clean:
	flutter clean && flutter pub get
