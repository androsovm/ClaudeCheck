.PHONY: build app run clean release-zip

VERSION ?= 0.1.0

build:
	swift build -c release

app:
	VERSION=$(VERSION) ./Scripts/build-app.sh

# Build universal binary for release
release-app:
	VERSION=$(VERSION) ARCHS="arm64 x86_64" ./Scripts/build-app.sh

release-zip: release-app
	cd dist && ditto -c -k --keepParent ClaudeCheck.app ClaudeCheck-$(VERSION).zip
	@echo "✓ dist/ClaudeCheck-$(VERSION).zip"

run: app
	open dist/ClaudeCheck.app

clean:
	rm -rf .build dist
