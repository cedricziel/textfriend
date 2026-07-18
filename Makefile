SCHEME := TextFriend
DEST ?= platform=iOS Simulator,name=iPhone 17 Pro

.PHONY: generate build test lint format icon clean

generate:
	xcodegen generate

build: generate
	xcodebuild -project TextFriend.xcodeproj -scheme $(SCHEME) -destination '$(DEST)' build

test: generate
	xcodebuild -project TextFriend.xcodeproj -scheme $(SCHEME) -destination '$(DEST)' test

lint:
	xcrun swift format lint --recursive App Tests

format:
	xcrun swift format --in-place --recursive App Tests

icon:
	python3 scripts/generate_icon.py

clean:
	rm -rf DerivedData build TextFriend.xcodeproj
