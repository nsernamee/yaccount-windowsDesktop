# Flutter 混淆配置

# 保持 Flutter 相关类
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# 保持 sqflite
-keep class com.tekartik.sqflite.** { *; }

# 保持 crypto
-keep class org.bouncycastle.** { *; }
-keep class javax.crypto.** { *; }

# 保持 excel 包
-keep class org.apache.poi.** { *; }
-keep class org.apache.xmlbeans.** { *; }

# 忽略 Google Play Core 库的缺失类（Flutter 延迟组件）
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }

# 移除日志
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# 代码压缩优化
-optimizationpasses 5
-dontusemixedcaseclassnames
-verbose
-dontpreverify
