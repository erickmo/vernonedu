APP_NAME=app_student

.PHONY: get run run-dev test analyze gen clean

get:
	flutter pub get

run-dev:
	flutter run --dart-define=ENV=dev

test:
	flutter test

analyze:
	flutter analyze

clean:
	flutter clean && flutter pub get
