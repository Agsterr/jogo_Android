# O otimizador (R8) apagava a classe gerada do banco do WorkManager (usado pelo SDK de anúncios),
# e o app fechava ao abrir: "Failed to create an instance of androidx.work.impl.WorkDatabase".
# Bancos Room são criados por reflexão; mantenha as implementações geradas.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**
