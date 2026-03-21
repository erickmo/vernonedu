APP_NAME=app_mcb_junior

.PHONY: get run build test analyze gen clean

## Setup
get:
	flutter pub get

## Run
dev:
	flutter run -d chrome --web-port 3000

dev-pwa:
	flutter run -d chrome --web-renderer html --dart-define=BASE_URL=http://localhost:8080/api/v1

staging:
	flutter run -d chrome --dart-define=BASE_URL=https://staging-api.mcbjunior.com/api/v1

## Build
build-web:
	flutter build web --release \
		--dart-define=BASE_URL=https://api.mcbjunior.com/api/v1

build-web-pwa:
	flutter build web --release \
		--web-renderer html \
		--dart-define=BASE_URL=https://api.mcbjunior.com/api/v1

## Testing
test:
	flutter test

test-coverage:
	flutter test --coverage
	genhtml coverage/lcov.info -o coverage/html
	@echo "Coverage report: coverage/html/index.html"

## Code Quality
analyze:
	flutter analyze

fix:
	dart fix --apply

## Code Generation
gen:
	flutter pub run build_runner build --delete-conflicting-outputs

gen-watch:
	flutter pub run build_runner watch --delete-conflicting-outputs

## Utilities
clean:
	flutter clean
	flutter pub get

upgrade:
	flutter pub upgrade
