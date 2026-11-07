# OkHttp (pulled in by the VK SDK) optionally uses these TLS providers when present.
# https://square.github.io/okhttp/features/r8_proguard/
-dontwarn org.bouncycastle.jsse.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**
