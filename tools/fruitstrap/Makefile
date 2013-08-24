IOS_CC = clang
IOS_SDK = /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.1.sdk

all: clean fruitstrap

demo.app: demo Info.plist
	mkdir -p demo.app
	cp demo demo.app/
	cp Info.plist ResourceRules.plist demo.app/
	codesign -f -s "iPhone Developer" --entitlements Entitlements.plist demo.app

demo: demo.c
	$(IOS_CC) -arch armv7 -isysroot $(IOS_SDK) -framework CoreFoundation -o demo demo.c

fruitstrap: fruitstrap.c
	$(IOS_CC) -o fruitstrap -framework CoreFoundation -framework MobileDevice -F/System/Library/PrivateFrameworks fruitstrap.c

install: fruitstrap demo.app
	./fruitstrap -b demo.app

debug: fruitstrap demo.app
	./fruitstrap -d -b demo.app

clean:
	rm -rf *.app demo fruitstrap