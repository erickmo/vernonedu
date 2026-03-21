APP_NAME=vernonedu_blockcoding

.PHONY: get run run-android run-ios build-android build-apk test analyze clean gen

## Setup
get:
	flutter pub get

## Run
run:
	flutter run

run-android:
	flutter run -d android

run-ios:
	flutter run -d ios

## Build
build-android:
	flutter build appbundle --release

build-apk:
	flutter build apk --release --split-per-abi

build-ios:
	flutter build ios --release

## Testing
test:
	flutter test

test-coverage:
	flutter test --coverage
	@echo "Coverage: coverage/lcov.info"

## Code Quality
analyze:
	flutter analyze

fix:
	dart fix --apply

## Utilities
clean:
	flutter clean
	flutter pub get

upgrade:
	flutter pub upgrade
