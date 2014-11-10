start gimp^
	-b "(resize-image 512 512 \"icon.xcf\" \"android-high-res.png\")"^
	-b "(resize-image 192 192 \"icon.xcf\" \"android/drawable-640dpi/icon.png\")"^
	-b "(resize-image 144 144 \"icon.xcf\" \"android/drawable-xxhdpi/icon.png\")"^
	-b "(resize-image 96 96 \"icon.xcf\" \"android/drawable-xhdpi/icon.png\")"^
	-b "(resize-image 72 72 \"icon.xcf\" \"android/drawable-hdpi/icon.png\")"^
	-b "(resize-image 48 48 \"icon.xcf\" \"android/drawable-mdpi/icon.png\")"^
	-b "(resize-image 36 36 \"icon.xcf\" \"android/drawable-ldpi/icon.png\")"^
	-b "(gimp-quit 0)"

start gimp^
	-b "(resize-image 1024 1024 \"icon-ios.xcf\" \"ios-high-res.png\")"^
	-b "(resize-image 152 152 \"icon-ios.xcf\" \"ios/Icon-76@2x.png\")"^
	-b "(resize-image 144 144 \"icon-ios.xcf\" \"ios/Icon-72@2x.png\")"^
	-b "(resize-image 144 144 \"icon-ios.xcf\" \"ios/Icon-144.png\")"^
	-b "(resize-image 120 120 \"icon-ios.xcf\" \"ios/Icon-60@2x.png\")"^
	-b "(resize-image 114 114 \"icon-ios.xcf\" \"ios/Icon@2x.png\")"^
	-b "(resize-image 114 114 \"icon-ios.xcf\" \"ios/Icon-114.png\")"^
	-b "(resize-image 100 100 \"icon-ios.xcf\" \"ios/Icon-Small-50@2x.png\")"^
	-b "(resize-image 80 80 \"icon-ios.xcf\" \"ios/Icon-Small-40@2x.png\")"^
	-b "(resize-image 76 76 \"icon-ios.xcf\" \"ios/Icon-76.png\")"^
	-b "(resize-image 72 72 \"icon-ios.xcf\" \"ios/Icon-72.png\")"^
	-b "(resize-image 58 58 \"icon-ios.xcf\" \"ios/Icon-Small@2x.png\")"^
	-b "(resize-image 57 57 \"icon-ios.xcf\" \"ios/Icon.png\")"^
	-b "(resize-image 57 57 \"icon-ios.xcf\" \"ios/Icon-57.png\")"^
	-b "(resize-image 50 50 \"icon-ios.xcf\" \"ios/Icon-Small-50.png\")"^
	-b "(resize-image 40 40 \"icon-ios.xcf\" \"ios/Icon-Small-40.png\")"^
	-b "(resize-image 29 29 \"icon-ios.xcf\" \"ios/Icon-Small.png\")"^
	-b "(gimp-quit 0)"