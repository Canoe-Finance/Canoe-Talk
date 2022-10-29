import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:solana_defi_sdk/api.dart';
import 'package:solana_defi_sdk/solana_defi_sdk.dart';

import '../helpers/logger.dart';

final sdk = SolanaDeFiSDK.instance;

final clusterIDProvider =
    StateProvider.family<SolanaID, SolanaID>((_, env) => SolanaID.mainnet);

final loadBalanceProvider =
    FutureProvider.family<int, String>((_, address) => sdk.getBalance(address));

final loadNFTsProvider =
    FutureProvider.family<List<GetAllAssetsDataElementAsset>, String>(
        (_, address) async {
  final List<GetAllAssetsDataElementAsset> assets = [];
  final response = await sdk.getNFTsGroupByCollection(address);
  if (response.data?.isNotEmpty ?? false) {
    response.data?.forEach((element) {
      assets.addAll(element.assets ?? []);
    });
  }
  return assets;
});

final loadTokenAccountsProvider =
    FutureProvider.family<List<TokenInfo>, String>((_, address) async {
  final balances = <TokenInfo>[];
  /*
  try {
    final accounts = await sdk.getTokenAccountsBySolScan(address);
    for (final element in accounts) {
      if (num.parse(element.tokenAmount?.amount ?? '0') > 0) {
        balances.add(TokenInfo(
            symbol: element.tokenSymbol,
            mint: element.tokenAddress ?? '',
            amount: int.parse(element.tokenAmount?.amount ?? '0'),
            uiAmount: element.tokenAmount?.uiAmountString ?? ''));
      }
    }
  } catch (e) {
    logger.severe('get token accounts error: $e');
  }

  if (balances.isNotEmpty) return balances;*/

  /// show USDC/USDT only
  // try another way if error occurred
  try {
    final accounts = await sdk.getTokenAmounts(address, includeZero: true);
    for (final element in accounts.entries) {
      // if (num.parse(element.value.amount) > 0) {
      balances.add(TokenInfo(
          symbol: element.key,
          mint: TokenSymbols.getAddress(element.key)!,
          amount: int.parse(element.value.amount),
          uiAmount: element.value.uiAmountString));
      // }
    }
  } catch (e) {
    logger.severe('get token amounts error: $e');
  }
  return balances;
});

final loadBalancesProvider =
    FutureProvider.family<List<TokenInfo>, String>((ref, address) async {
  final balances = <TokenInfo>[];
  final sol = await ref.watch(loadBalanceProvider(address).future);
  final accounts = await ref.watch(loadTokenAccountsProvider(address).future);
  if (sol > 0) {
    balances.add(TokenInfo(
        symbol: 'SOL',
        mint: 'So11111111111111111111111111111111111111112',
        amount: sol,
        uiAmount: sdk.uiAmount(sol)));
  }
  balances.addAll(accounts);

  logger.fine('balances is $balances');
  return balances;
});

class TokenInfo {
  String? symbol;
  String mint;
  int amount;
  String? uiAmount;

  TokenInfo(
      {this.symbol, required this.mint, required this.amount, this.uiAmount});

  @override
  String toString() {
    return 'TokenInfo{symbol: $symbol, mint: $mint, amount: $amount, uiAmount: $uiAmount}';
  }
}
