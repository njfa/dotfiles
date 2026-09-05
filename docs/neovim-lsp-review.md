# LSP・デバッグ構成の検証（2026-09-06）

Java、Python、GoのLSPとデバッグは実プロセスで動作した。Javaは小規模な再現プロジェクトに加え、
Spring Bootの実在するMavenマルチモジュール2件で全モジュールを認識した。
大規模Java開発用の初期値としてCPU・メモリ設定も妥当な範囲に収まっている。

## 検証環境

Linux ARM64、Neovim 0.11.7で、リポジトリの `lazy-lock.json` に固定されたnvim-lspconfig、
nvim-jdtls、nvim-dapを使用した。主な外部ツールはJDT LS 1.60.0、Microsoft JDK 21.0.9、
Pyright 1.1.413、Ruff 0.16.6、gopls 0.21.0、Go 1.25.14、
java-debug 0.59.0、java-test 0.46.0、debugpy 1.8.21、Delve 1.27.1である。

検証用のプラグインとサーバーは `/tmp/nvim-lsp-review` に隔離した。
設定ファイルはこのリポジトリから読み込み、補完UIやwhich-keyなど検証対象外のUIだけをスタブ化した。

## LSPとデバッグ

| 対象 | 確認結果 |
| --- | --- |
| Java LSP | 2モジュール間の定義ジャンプ、集約ルートの共有、JDT LSが二重起動しないことを確認 |
| Python LSP | Pyrightの型不一致診断とRuffの未使用import診断を受信 |
| Go LSP | `go.work` に含まれる2モジュール間の定義ジャンプを確認 |
| Java DAP | mainクラスを検出してlaunchし、ブレークポイント停止、ローカル変数 `x=43`、再開、終了を確認 |
| Java test DAP | JUnit 6.0.1のテストクラスをlaunchし、テストメソッド内のブレークポイント停止を確認 |
| Python DAP | debugpyでファイルをlaunchし、ブレークポイント停止、ローカル変数 `x=2`、再開、終了を確認 |
| Go DAP | Delveでパッケージをlaunchし、ブレークポイント停止、ローカル変数 `x=2`、再開、終了を確認 |

Java DAP検証時のJDT LS JVMのRSSは約730〜780 MiBだった。JUnitのブレークポイント停止中は
JDT LSが約753 MiB、テストJVMが約457 MiBで、両Javaプロセスだけで約1.18 GiBだった。
NeovimやOSの使用量を含まないため、実運用の必要量はこれより大きくなる。

Java test拡張は `extension/package.json` の `contributes.javaExtensions` が宣言するOSGi bundleから、
JDT LS内蔵版と同じファイル名のbundleを除いてロードした。`server` ディレクトリ内の全JARを渡す方式では
runnerや依存JARがJDT LSと競合する。Java mainクラスの全体探索は起動時に実行せず、`mdc` の手動操作に限定した。

java-test 0.46.0とJUnit 5.11.4の組合せでは、テストrunnerが
`org.junit.platform.engine.OutputDirectoryCreator` を見つけられず起動に失敗した。
JUnit 6.0.1では成功している。古いJUnitを使うプロジェクトではMavenからテストを実行するか、
そのJUnit世代に対応するjava-testの版を選ぶ必要がある。

祖先の `.vscode/launch.json` はGit境界まで探索し、`${workspaceFolder}` がlaunch.jsonのある
プロジェクトを基準に展開されることをテストした。子ディレクトリからNeovimを起動してもルートの構成を利用できる。

## 実プロジェクト

日常的な使用感の確認には
[Spring Petclinic Microservices](https://github.com/spring-petclinic/spring-petclinic-microservices)
を第一候補とする。Spring Boot 4.0.1、Java 17のサービス群で、設定・discovery・gateway・customers・vets・visitsなど
役割が分かれており、各サービスを個別に起動しやすい。検証したスナップショットは
`3858f9c630cf989bb6809a86edf47c2be78dc9f1`、POM 9件、Java 62ファイルだった。

より大きなインデックス負荷の確認には
[Pig](https://github.com/pig-mesh/pig)
を併用する。検証スナップショットは `388e7fe1ac1fcc115277dec431b6817b80050aeb`、
POM 25件、Java 552ファイルだった。フルスタック起動にはMySQL、Redis、Nacosなどが必要なので、
エディタの負荷試験と全モジュールビルドに向いている。

両方ともMaven 3.9.8とJDK 21でpackageまで成功した。

| プロジェクト | Mavenコマンド | 結果 |
| --- | --- | --- |
| Petclinic | `mvn -DskipTests package` | 親と8サービスが成功、初回依存取得込み4分44秒 |
| Pig | `mvn -Dmaven.test.skip=true -Ddocker.skip=true package` | Reactor 24項目が成功、初回依存取得込み6分14秒 |

ビルド時間にはネットワークとローカルMavenキャッシュの状態が含まれるため、プロジェクト間の性能比較には使えない。
サービス群の同時起動までは行っていない。

## Javaの初回インポートとリソース

JDT LSのworkspaceを毎回新規作成し、`JDTLS_CPUS=2`、`JDTLS_MAX_HEAP=2g`、
java-debug/java-test bundle有効の条件で測った。

| プロジェクト | 初期化 | 全プロジェクト準備 | 準備数 | 観測ピークRSS |
| --- | ---: | ---: | ---: | ---: |
| Petclinic | 13.32秒 | 15.15秒 | 9/9 | 265.9 MiB |
| Pig | 11.73秒 | 20.24秒 | 25/25 | 285.4 MiB |

RSSはNeovim直下のJDT LS JVMを250 ms間隔で観測し、全プロジェクト準備後も10秒間サンプリングした値である。
Maven、Neovim、ほかのLSP、デバッグ対象サービスを含むシステム全体のピークではない。
Maven依存キャッシュも完全な初期状態ではないため、初回利用時の上限保証にはならない。

どちらもJDT LS初期化直後にnvim-jdtlsから
`Couldn't retrieve source path settings` と通知される場合があった。
nvim-jdtlsが `ServiceReady` 直後に `java.project.getSettings` を呼ぶ一方、
Mavenプロジェクトのインポートがまだ進行中であることが原因で、全プロジェクト準備後のLSP機能には影響しなかった。

既定の `JDTLS_CPUS` は利用可能CPUの半分と4の小さい方、`JDTLS_MAX_HEAP` は2 GiBである。
`java.import.maxConcurrentBuilds=1` とLinux上の `nice -n 10` も維持している。
これらは初回インポートが端末全体を占有しにくくする設定として妥当である。

`ActiveProcessorCount` はJVM内部の並列度を調整する値で、CPU使用率を強制的に制限しない。
`-Xmx2g` はJavaヒープだけに適用され、メタスペース、ネイティブメモリ、複数のJDT LSや
デバッグ対象JVMは別に消費する。8 GiB程度の環境で複数Spring Bootサービスを同時起動する場合は、
JDT LSを1 GiBへ下げるか同時起動数を抑え、実機で合計RSSを確認する必要がある。
JVMオプションの意味は [Java 21の公式リファレンス](https://docs.oracle.com/en/java/javase/21/docs/specs/man/java.html) を参照。

benchmarkは `tests/manual/nvim-java-benchmark.lua` にあり、普段使う構成と任意のプロジェクトで再実行できる。
workspace symbol検索はインポート直後の1回では結果が返らなかったため、今回の利用可能判定には含めていない。
