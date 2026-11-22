package com.agsterr.encaixa

import android.util.Log
import com.google.android.gms.auth.blockstore.Blockstore
import com.google.android.gms.auth.blockstore.RetrieveBytesRequest
import com.google.android.gms.auth.blockstore.StoreBytesData
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Além da tela do Flutter, guarda e devolve o progresso do jogador no Block Store do Google Play services.
 * Ele sobrevive a desinstalar e reinstalar (com o Backup do Google ligado) e vai para o backup na nuvem
 * quando o aparelho permite. Qualquer falha vira erro para o Dart, que a ignora: o jogo nunca fecha por isso.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CANAL).setMethodCallHandler { chamada, resultado ->
            when (chamada.method) {
                "salvar" -> salvar(chamada.argument<ByteArray>("bytes"), resultado)
                "ler" -> ler(resultado)
                else -> resultado.notImplemented()
            }
        }
    }

    private fun salvar(bytes: ByteArray?, resultado: MethodChannel.Result) {
        if (bytes == null) {
            resultado.error("sem_dados", "faltou o campo bytes", null)
            return
        }
        try {
            val cliente = Blockstore.getClient(this)
            // Backup na nuvem só com criptografia ponta a ponta (Android 9+ e tela de bloqueio).
            // Sempre mandamos o mesmo valor do indicador: mandar "falso" apaga a cópia antiga da nuvem.
            cliente.isEndToEndEncryptionAvailable().addOnCompleteListener { tarefa ->
                val nuvem = tarefa.isSuccessful && tarefa.result == true
                val dados = StoreBytesData.Builder()
                    .setBytes(bytes)
                    .setKey(CHAVE)
                    .setShouldBackupToCloud(nuvem)
                    .build()
                cliente.storeBytes(dados)
                    .addOnSuccessListener { gravados ->
                        Log.i(TAG, "salvo: $gravados bytes (nuvem=$nuvem)")
                        resultado.success(mapOf("bytes" to gravados, "nuvem" to nuvem))
                    }
                    .addOnFailureListener { erro ->
                        Log.w(TAG, "falha ao salvar", erro)
                        resultado.error("falha", erro.message, null)
                    }
            }
        } catch (erro: Exception) {
            Log.w(TAG, "indisponível ao salvar", erro)
            resultado.error("indisponivel", erro.message, null)
        }
    }

    private fun ler(resultado: MethodChannel.Result) {
        try {
            val pedido = RetrieveBytesRequest.Builder().setKeys(listOf(CHAVE)).build()
            Blockstore.getClient(this).retrieveBytes(pedido)
                .addOnSuccessListener { resposta ->
                    val bytes = resposta.blockstoreDataMap[CHAVE]?.bytes
                    Log.i(TAG, "lido: ${bytes?.size ?: 0} bytes")
                    resultado.success(bytes)
                }
                .addOnFailureListener { erro ->
                    Log.w(TAG, "falha ao ler", erro)
                    resultado.error("falha", erro.message, null)
                }
        } catch (erro: Exception) {
            Log.w(TAG, "indisponível ao ler", erro)
            resultado.error("indisponivel", erro.message, null)
        }
    }

    companion object {
        private const val CANAL = "encaixa/copia"
        private const val CHAVE = "com.agsterr.encaixa.progresso"
        private const val TAG = "EncaixaCopia"
    }
}
