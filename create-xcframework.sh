FRAMEWORK_NAME="Llama"
IOS_FRAMEWORK="build-ios/$FRAMEWORK_NAME.framework"
SIMULATOR_FRAMEWORK="build-ios-simulator/$FRAMEWORK_NAME.framework"
MACOS_FRAMEWORK="build-macos/$FRAMEWORK_NAME.framework"

mkdir -p build-ios
cd build-ios
cmake .. -DCMAKE_TOOLCHAIN_FILE=../ios.toolchain.cmake -DPLATFORM=OS -DDEPLOYMENT_TARGET=14.0 -DENABLE_BITCODE=0 -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF
cmake --build . --config Release
cd ..

mkdir -p build-ios-simulator
cd build-ios-simulator
cmake .. -DCMAKE_TOOLCHAIN_FILE=../ios.toolchain.cmake -DPLATFORM=SIMULATOR64 -DDEPLOYMENT_TARGET=14.0 -DENABLE_BITCODE=0 -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF
cmake --build . --config Release
cd ..

mkdir -p build-macos
cd build-macos
cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF
cmake --build . --config Release
cd ..

mkdir -p "$IOS_FRAMEWORK/Headers"
mkdir -p "$IOS_FRAMEWORK/Modules"
cp build-ios/src/libllama.a "$IOS_FRAMEWORK/$FRAMEWORK_NAME"
cp ggml/include/ggml.h "$IOS_FRAMEWORK/Headers/"
cp ggml/include/ggml-cpu.h "$IOS_FRAMEWORK/Headers/"
cp ggml/include/ggml-backend.h "$IOS_FRAMEWORK/Headers/"
cp ggml/include/ggml-alloc.h "$IOS_FRAMEWORK/Headers/"
cp include/llama.h "$IOS_FRAMEWORK/Headers/"
echo 'framework module Llama {
    umbrella header "llama.h"
    header "ggml.h"
    header "ggml-cpu.h"
    header "ggml-backend.h"
    header "ggml-alloc.h"
    export *
    module * { export * }
}' > "$IOS_FRAMEWORK/Modules/module.modulemap"

# Create iOS Simulator framework
mkdir -p "$SIMULATOR_FRAMEWORK/Headers"
mkdir -p "$SIMULATOR_FRAMEWORK/Modules"
cp build-ios-simulator/src/libllama.a "$SIMULATOR_FRAMEWORK/$FRAMEWORK_NAME"
cp ggml/include/ggml.h "$SIMULATOR_FRAMEWORK/Headers/"
cp ggml/include/ggml-cpu.h "$SIMULATOR_FRAMEWORK/Headers/"
cp ggml/include/ggml-backend.h "$SIMULATOR_FRAMEWORK/Headers/"
cp ggml/include/ggml-alloc.h "$SIMULATOR_FRAMEWORK/Headers/"
cp include/llama.h "$SIMULATOR_FRAMEWORK/Headers/"
cp "$IOS_FRAMEWORK/Modules/module.modulemap" "$SIMULATOR_FRAMEWORK/Modules/"

# Create macOS framework
mkdir -p "$MACOS_FRAMEWORK/Headers"
mkdir -p "$MACOS_FRAMEWORK/Modules"
cp build-macos/src/libllama.a "$MACOS_FRAMEWORK/$FRAMEWORK_NAME"
cp ggml/include/ggml.h "$MACOS_FRAMEWORK/Headers/"
cp ggml/include/ggml-cpu.h "$MACOS_FRAMEWORK/Headers/"
cp ggml/include/ggml-backend.h "$MACOS_FRAMEWORK/Headers/"
cp ggml/include/ggml-alloc.h "$MACOS_FRAMEWORK/Headers/"
cp include/llama.h "$MACOS_FRAMEWORK/Headers/"
cp "$IOS_FRAMEWORK/Modules/module.modulemap" "$MACOS_FRAMEWORK/Modules/"

cat > "$IOS_FRAMEWORK/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Llama</string>
    <key>CFBundleIdentifier</key>
    <string>com.sublimebytes.llama</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Llama</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>14.0</string>
</dict>
</plist>
EOF

cp "$IOS_FRAMEWORK/Info.plist" "$SIMULATOR_FRAMEWORK/Info.plist"
cp "$IOS_FRAMEWORK/Info.plist" "$MACOS_FRAMEWORK/Info.plist"

xcodebuild -create-xcframework \
    -framework "$IOS_FRAMEWORK" \
    -framework "$SIMULATOR_FRAMEWORK" \
    -framework "$MACOS_FRAMEWORK" \
    -output "./Llama.xcframework"
