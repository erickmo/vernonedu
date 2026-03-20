APP_NAME=vernonedu_entrepreneurship_app

.PHONY: get build run clean test analyze gen

## Setup
get:
	flutter pub get

## Run
run:
	flutter run -d chrome

run-dev:
	flutter run -d chrome --dart-define=BASE_URL=http://localhost:8080/api/v1

run-staging:
	flutter run -d chrome --dart-define=BASE_URL=https://staging-api.vernonedu.com/api/v1

run-prod:
	flutter run -d chrome --dart-define=BASE_URL=https://api.vernonedu.com/api/v1

## Build
build-web:
	flutter build web --release \
		--dart-define=BASE_URL=https://api.vernonedu.com/api/v1 \
		--pwa-strategy offline-first

build-web-staging:
	flutter build web --release \
		--dart-define=BASE_URL=https://staging-api.vernonedu.com/api/v1 \
		--pwa-strategy offline-first

## Testing
test:
	flutter test

test-coverage:
	flutter test --coverage
	@echo "Coverage: coverage/lcov.info"

## Code Quality
analyze:
	flutter analyze

lint:
	dart fix --dry-run

fix:
	dart fix --apply

## Code Generation
gen:
	dart run build_runner build --delete-conflicting-outputs

gen-watch:
	dart run build_runner watch --delete-conflicting-outputs

## Utilities
clean:
	flutter clean
	flutter pub get

upgrade:
	flutter pub upgrade
