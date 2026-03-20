APP_NAME=vernonedu_website

.PHONY: get run run-web build-web analyze test clean

## Setup
get:
	flutter pub get

## Run
run-web:
	cd app-website && flutter run -d chrome --web-renderer html

run-dev:
	flutter run -d chrome --web-renderer html --dart-define=ENV=development

## Build
build-web:
	flutter build web --web-renderer html --release --base-href "/"

build-web-canvaskit:
	flutter build web --web-renderer canvaskit --release

## Code Quality
analyze:
	flutter analyze

## Test
test:
	flutter test

## Utilities
clean:
	flutter clean && flutter pub get

upgrade:
	flutter pub upgrade
