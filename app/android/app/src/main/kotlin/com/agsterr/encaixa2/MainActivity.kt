package com.agsterr.encaixa2

import android.os.Bundle
import android.util.Log
import com.google.android.gms.auth.blockstore.Blockstore
import com.google.android.gms.auth.blockstore.RetrieveBytesRequest
import com.google.android.gms.auth.blockstore.StoreBytesData
import com.google.android.gms.games.PlayGames
import com.google.android.gms.games.PlayGamesSdk
import com.google.android.gms.games.SnapshotsClient
import com.google.android.gms.games.snapshot.SnapshotMetadataChange
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Além da tela do Flutter, guarda e devolve o progresso do jogador no Block Store do Google Play services.
 * Ele sobrevive a desinstalar e reinstalar (com o Backup do Google ligado) e vai para o backup na nuvem
 * quando o aparelho permite. Qualquer falha vira erro para o Dart, que a ignora: o jogo nunca fecha por isso.
 */
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Play Games Services v2 entra sozinho com a conta Google; sem a conta ou sem rede, só não salva na nuvem.
        try {
            PlayGamesSdk.initialize(this)
        } catch (erro: Exception) {
            Log.w(TAG_NUVEM, "Play Games indisponível", erro)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        configurarNuvem(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CANAL).setMethodCallHandler { chamada, resultado ->
            when (chamada.method) {
                "salvar" -> salvar(chamada.argument<ByteArray>("bytes"), resultado)
                "ler" -> ler(resultado)
                else -> resultado.notImplemented()
            }
        }
    }

    // ---- Play Games Services: Jogo salvo na conta Google (canal "encaixa/nuvem") ----

    private fun configurarNuvem(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CANAL_NUVEM).setMethodCallHandler { chamada, resultado ->
            when (chamada.method) {
                "salvar" -> nuvem(resultado) { salvarNaNuvem(chamada.argument<ByteArray>("bytes"), resultado) }
                "ler" -> nuvem(resultado) { lerDaNuvem(resultado) }
                "jogador" -> nuvem(resultado) { nomeDoJogador(resultado) }
                "conectar" -> conectarAoPlayGames(resultado)
                "rankingDisponivel" -> resultado.success(getString(R.string.leaderboard_id).isNotBlank())
                "enviarPontos" -> nuvem(resultado) { enviarPontos(chamada.argument<Number>("pontos"), resultado) }
                "abrirRanking" -> nuvem(resultado) { abrirRanking(resultado) }
                else -> resultado.notImplemented()
            }
        }
    }

    /** Abre o login do Play Games (o jogador escolhe a conta). Devolve `true` se ficou conectado. */
    private fun conectarAoPlayGames(resultado: MethodChannel.Result) {
        try {
            PlayGames.getGamesSignInClient(this).signIn()
                .addOnCompleteListener { tarefa ->
                    resultado.success(tarefa.isSuccessful && tarefa.result.isAuthenticated)
                }
        } catch (erro: Exception) {
            Log.w(TAG_NUVEM, "não deu para conectar", erro)
            resultado.error("indisponivel", erro.message, null)
        }
    }

    /** Manda a pontuação para o placar do Google (ele guarda só a melhor de cada jogador). */
    private fun enviarPontos(pontos: Number?, resultado: MethodChannel.Result) {
        val id = getString(R.string.leaderboard_id)
        if (pontos == null || id.isBlank()) {
            resultado.error("sem_placar", "placar não configurado", null)
            return
        }
        PlayGames.getLeaderboardsClient(this).submitScore(id, pontos.toLong())
        resultado.success(true)
    }

    /** Abre a tela do placar do Google. */
    private fun abrirRanking(resultado: MethodChannel.Result) {
        val id = getString(R.string.leaderboard_id)
        if (id.isBlank()) {
            resultado.error("sem_placar", "placar não configurado", null)
            return
        }
        PlayGames.getLeaderboardsClient(this).getLeaderboardIntent(id)
            .addOnSuccessListener { intent ->
                startActivityForResult(intent, CODIGO_RANKING)
                resultado.success(true)
            }
            .addOnFailureListener { erro -> resultado.error("falha", erro.message, null) }
    }

    /** Nome do jogador conectado ao Play Games (mostrado na tela Salvar progresso). */
    private fun nomeDoJogador(resultado: MethodChannel.Result) {
        PlayGames.getPlayersClient(this).currentPlayer
            .addOnSuccessListener { jogador -> resultado.success(jogador.displayName) }
            .addOnFailureListener { erro -> resultado.error("falha", erro.message, null) }
    }

    /** Só segue se o jogador estiver conectado ao Play Games; senão devolve `desconectado` (o Dart ignora). */
    private fun nuvem(resultado: MethodChannel.Result, acao: () -> Unit) {
        try {
            PlayGames.getGamesSignInClient(this).isAuthenticated.addOnCompleteListener { tarefa ->
                if (tarefa.isSuccessful && tarefa.result.isAuthenticated) {
                    try {
                        acao()
                    } catch (erro: Exception) {
                        Log.w(TAG_NUVEM, "erro na nuvem", erro)
                        resultado.error("falha", erro.message, null)
                    }
                } else {
                    resultado.error("desconectado", "sem conta do Play Games", null)
                }
            }
        } catch (erro: Exception) {
            resultado.error("indisponivel", erro.message, null)
        }
    }

    private fun salvarNaNuvem(bytes: ByteArray?, resultado: MethodChannel.Result) {
        if (bytes == null) {
            resultado.error("sem_dados", "faltou o campo bytes", null)
            return
        }
        val cliente = PlayGames.getSnapshotsClient(this)
        // Se dois aparelhos salvaram ao mesmo tempo, vale o mais recente.
        cliente.open(NOME_JOGO_SALVO, true, SnapshotsClient.RESOLUTION_POLICY_MOST_RECENTLY_MODIFIED)
            .addOnSuccessListener { aberto ->
                val jogo = aberto.data
                if (jogo == null) {
                    resultado.error("conflito", "conflito não resolvido", null)
                    return@addOnSuccessListener
                }
                jogo.snapshotContents.writeBytes(bytes)
                cliente.commitAndClose(jogo, SnapshotMetadataChange.EMPTY_CHANGE)
                    .addOnSuccessListener { resultado.success(mapOf("bytes" to bytes.size, "nuvem" to true)) }
                    .addOnFailureListener { erro -> resultado.error("falha", erro.message, null) }
            }
            .addOnFailureListener { erro -> resultado.error("falha", erro.message, null) }
    }

    private fun lerDaNuvem(resultado: MethodChannel.Result) {
        val cliente = PlayGames.getSnapshotsClient(this)
        cliente.open(NOME_JOGO_SALVO, false, SnapshotsClient.RESOLUTION_POLICY_MOST_RECENTLY_MODIFIED)
            .addOnSuccessListener { aberto ->
                val jogo = aberto.data
                if (jogo == null) {
                    resultado.error("conflito", "conflito não resolvido", null)
                    return@addOnSuccessListener
                }
                val bytes = jogo.snapshotContents.readFully()
                cliente.discardAndClose(jogo)
                resultado.success(if (bytes.isEmpty()) null else bytes)
            }
            // Ainda não existe jogo salvo (primeira vez): não é erro para o jogador.
            .addOnFailureListener { erro ->
                Log.i(TAG_NUVEM, "sem jogo salvo: ${erro.message}")
                resultado.success(null)
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
        private const val CANAL_NUVEM = "encaixa/nuvem"
        private const val NOME_JOGO_SALVO = "progresso"
        private const val TAG_NUVEM = "EncaixaNuvem"
        private const val CODIGO_RANKING = 9004
    }
}
