import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'progresso.dart';

/// IDs cadastrados no Play Console (Produtos no app / Assinaturas).
abstract final class Produtos {
  static const semAnuncios = 'sem_anuncios';
  static const assinatura = 'encaixa_mais';
  static const gemas = {'gemas_100': 100, 'gemas_300': 300, 'gemas_1000': 1000};

  static const todos = {semAnuncios, assinatura, 'gemas_100', 'gemas_300', 'gemas_1000'};
}

class ProdutoLoja {
  const ProdutoLoja(this.id, this.preco);

  final String id;
  final String preco;
}

/// Compras no app. A tela só conhece esta interface.
abstract class Compras extends ChangeNotifier {
  bool get disponivel;
  Map<String, ProdutoLoja> get produtos;
  String? get erro;
  Future<void> iniciar();
  Future<void> comprar(String id);
  Future<void> restaurar();
}

/// Para testes e capturas de tela: preços fixos, compra entrega na hora.
class ComprasFicticias extends Compras {
  ComprasFicticias(this._progresso);

  final Progresso _progresso;

  @override
  bool get disponivel => true;
  @override
  String? get erro => null;
  @override
  final Map<String, ProdutoLoja> produtos = const {
    Produtos.semAnuncios: ProdutoLoja(Produtos.semAnuncios, r'R$ 14,90'),
    Produtos.assinatura: ProdutoLoja(Produtos.assinatura, r'R$ 9,90'),
    'gemas_100': ProdutoLoja('gemas_100', r'R$ 4,90'),
    'gemas_300': ProdutoLoja('gemas_300', r'R$ 12,90'),
    'gemas_1000': ProdutoLoja('gemas_1000', r'R$ 34,90'),
  };

  @override
  Future<void> iniciar() async {}
  @override
  Future<void> comprar(String id) => entregar(_progresso, id);
  @override
  Future<void> restaurar() async {}
}

/// Libera o que foi comprado.
Future<void> entregar(Progresso progresso, String id) async {
  if (id == Produtos.semAnuncios) return progresso.definirSemAnuncios(true);
  if (id == Produtos.assinatura) return progresso.definirAssinante(true);
  final gemas = Produtos.gemas[id];
  if (gemas != null) await progresso.ganharGemas(gemas);
}

/// Google Play Billing via `in_app_purchase`.
///
/// Limite conhecido: a validação é só no aparelho. A verificação no servidor
/// (e o aviso de assinatura cancelada em tempo real) está numa issue.
class ComprasPlay extends Compras {
  ComprasPlay(this._progresso);

  final Progresso _progresso;
  final _iap = InAppPurchase.instance;
  final Map<String, ProductDetails> _detalhes = {};
  StreamSubscription<List<PurchaseDetails>>? _assinatura;

  @override
  bool disponivel = false;
  @override
  String? erro;

  @override
  Map<String, ProdutoLoja> get produtos => {for (final d in _detalhes.values) d.id: ProdutoLoja(d.id, d.price)};

  @override
  Future<void> iniciar() async {
    disponivel = await _iap.isAvailable();
    if (!disponivel) return notifyListeners();
    _assinatura = _iap.purchaseStream.listen(
      _aoAtualizar,
      onError: (Object e) {
        erro = '$e';
        notifyListeners();
      },
    );
    final resposta = await _iap.queryProductDetails(Produtos.todos);
    for (final d in resposta.productDetails) {
      _detalhes.putIfAbsent(d.id, () => d); // assinatura pode vir repetida (uma por oferta)
    }
    await _sincronizarDireitos();
    notifyListeners();
  }

  /// Confere no Play o que o jogador ainda tem (assinatura vencida some daqui).
  Future<void> _sincronizarDireitos() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final android = _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final passadas = await android.queryPastPurchases();
    if (passadas.error != null) return; // sem rede: mantém o que já sabíamos
    final ids = passadas.pastPurchases
        .where((p) => p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored)
        .map((p) => p.productID)
        .toSet();
    await _progresso.definirAssinante(ids.contains(Produtos.assinatura));
    if (ids.contains(Produtos.semAnuncios)) await _progresso.definirSemAnuncios(true);
  }

  @override
  Future<void> comprar(String id) async {
    final detalhe = _detalhes[id];
    if (detalhe == null) return;
    erro = null;
    final param = PurchaseParam(productDetails: detalhe);
    if (Produtos.gemas.containsKey(id)) {
      await _iap.buyConsumable(purchaseParam: param);
    } else {
      await _iap.buyNonConsumable(purchaseParam: param);
    }
  }

  @override
  Future<void> restaurar() => _iap.restorePurchases();

  Future<void> _aoAtualizar(List<PurchaseDetails> compras) async {
    for (final compra in compras) {
      switch (compra.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await entregar(_progresso, compra.productID);
        case PurchaseStatus.error:
          erro = compra.error?.message ?? 'Não foi possível concluir a compra.';
        case PurchaseStatus.pending:
        case PurchaseStatus.canceled:
          break;
      }
      if (compra.pendingCompletePurchase) await _iap.completePurchase(compra);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _assinatura?.cancel();
    super.dispose();
  }
}
