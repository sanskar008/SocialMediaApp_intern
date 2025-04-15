@echo off
"C:\\Users\\Sanskar\\AppData\\Local\\Android\\sdk\\cmake\\3.22.1\\bin\\cmake.exe" ^
  "-HC:\\Users\\Sanskar\\AppData\\Local\\Pub\\Cache\\hosted\\pub.dev\\agora_rtc_engine-6.5.0\\android\\src\\main\\cpp" ^
  "-DCMAKE_SYSTEM_NAME=Android" ^
  "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" ^
  "-DCMAKE_SYSTEM_VERSION=21" ^
  "-DANDROID_PLATFORM=android-21" ^
  "-DANDROID_ABI=armeabi-v7a" ^
  "-DCMAKE_ANDROID_ARCH_ABI=armeabi-v7a" ^
  "-DANDROID_NDK=C:\\Users\\Sanskar\\AppData\\Local\\Android\\sdk\\ndk\\25.1.8937393" ^
  "-DCMAKE_ANDROID_NDK=C:\\Users\\Sanskar\\AppData\\Local\\Android\\sdk\\ndk\\25.1.8937393" ^
  "-DCMAKE_TOOLCHAIN_FILE=C:\\Users\\Sanskar\\AppData\\Local\\Android\\sdk\\ndk\\25.1.8937393\\build\\cmake\\android.toolchain.cmake" ^
  "-DCMAKE_MAKE_PROGRAM=C:\\Users\\Sanskar\\AppData\\Local\\Android\\sdk\\cmake\\3.22.1\\bin\\ninja.exe" ^
  "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=C:\\Users\\Sanskar\\Documents\\Projects\\SocialMediaApp\\SocialMediaFrontend\\build\\agora_rtc_engine\\intermediates\\cxx\\Debug\\6kvp4g6j\\obj\\armeabi-v7a" ^
  "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=C:\\Users\\Sanskar\\Documents\\Projects\\SocialMediaApp\\SocialMediaFrontend\\build\\agora_rtc_engine\\intermediates\\cxx\\Debug\\6kvp4g6j\\obj\\armeabi-v7a" ^
  "-DCMAKE_BUILD_TYPE=Debug" ^
  "-BC:\\Users\\Sanskar\\AppData\\Local\\Pub\\Cache\\hosted\\pub.dev\\agora_rtc_engine-6.5.0\\android\\.cxx\\Debug\\6kvp4g6j\\armeabi-v7a" ^
  -GNinja
