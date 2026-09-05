# NeovimのLSPとデバッグ

Neovim 0.11.7以降を前提に、LSPは `vim.lsp.config` / `vim.lsp.enable`、ツールはMasonで管理する。
プラグインのバージョンは `dot_config/nvim/lazy-lock.json` に固定している。
実サーバーと実プロジェクトによる検証結果は [構成レビュー](neovim-lsp-review.md) を参照。

| 言語 | LSP | 整形 | デバッガ |
| --- | --- | --- | --- |
| Java | nvim-jdtls / JDT LS | google-java-format | java-debug、java-test |
| Python | Pyright、Ruff | Ruff（Conform経由） | debugpy |
| Go | gopls | gopls（Conform経由） | Delve |

設定反映後にNeovimを再起動し、`:Mason` で `jdtls`、`openjdk-21`、`java-debug-adapter`、
`java-test`、`pyright`、`ruff`、`gopls`、`debugpy`、`delve` の導入完了を確認する。
導入中に対象ファイルを開いた場合は完了後に開き直す。旧 `pylsp` はインストール済みでも自動起動しない。

## Java / Maven

`ftplugin/java.lua` がJDT LSを起動する。Mason側の自動起動から `jdtls` を除外し、クライアントの二重起動を防いでいる。
ファイルの位置から次の順にルートを選ぶため、Neovimを起動したディレクトリには依存しない。

1. Git境界までにある最寄りの `.jdtls-root`。
2. Git境界までにある最上位の `<modules>` を持つ `pom.xml`。
3. 最寄りの `pom.xml`、Gradle設定、wrapper、`.git` など。

通常のMavenマルチモジュール構成では、子モジュールのJavaファイルを開いても集約POMをルートとして共有する。
XMLコメント内の `<modules>` は無視する。この判定は祖先POMのタグを読むもので、Maven profileの有効性や
`<module>` の参照先までは評価しない。別Gitリポジトリや共通祖先の外にある兄弟モジュールをまとめる場合は、
各ファイルからGit境界内で見える共通ディレクトリに `.jdtls-root` を置く。

JDT LSのデータは `stdpath("cache")/jdtls/workspace/<ルート名>-<パスのハッシュ>` に保存する。
同名の別リポジトリは分離される。POM変更後は `:JdtUpdateConfig`、キャッシュを作り直す場合は
Neovimを終了して該当ディレクトリを削除する。

JDT LSの起動にはJDK 21以降が必要で、次の順に実行ファイルを選び、起動前にバージョンを検査する。

1. `JDTLS_JAVA_HOME`
2. Masonの `openjdk-21`
3. `JAVA_HOME`
4. PATH上の `java`

JDT LS用JDKとプロジェクトの対象JDKは別である。既定ではSDKMANにあるAmazon Corretto 8/11/17/21を
プロジェクト用runtimeとして登録する。ほかの配置を使う場合はNeovim設定の早い段階で
`vim.g.jdtls_runtimes` にJDT LS形式のruntime一覧を設定する。

```lua
vim.g.jdtls_runtimes = {
    { name = "JavaSE-17", path = "/opt/jdk-17" },
    { name = "JavaSE-21", path = "/opt/jdk-21", default = true },
}
```

JDT LSは初回インポート時の負荷を抑えるため、Mavenビルドを1並列、ヒープを最大2 GiB、
JVMが認識するCPUを利用可能数の半分か4の小さい方にしている。1 CPU未満にはしない。
環境に合わせて次の値をNeovim起動前に変更できる。

```sh
JDTLS_CPUS=2 JDTLS_MAX_HEAP=2g nvim
```

`ActiveProcessorCount` はJVM内部の並列度を決める値であり、CPU使用率の強制上限ではない。
`-Xmx` もJVM全体のメモリ上限ではない。複数リポジトリのJDT LS、Maven、デバッグ対象サービスを
同時に動かす場合は、それぞれのプロセス分の余裕が必要になる。

## Python

Pyrightは `basic` の型チェックを開いているファイルに対して行い、Ruffはlintとimport整理を担当する。
重複を避けるためRuffのhoverとPyrightのimport整理を無効にしている。この役割分担は
[RuffのNeovim設定例](https://docs.astral.sh/ruff/editors/setup/#neovim) に沿っている。

Pyright用にNode.js/npmを用意し、依存パッケージはプロジェクトの仮想環境へ導入する。
`.venv` が自動認識されないプロジェクトでは `pyrightconfig.json` に設定する。

```json
{
  "venvPath": ".",
  "venv": ".venv"
}
```

`pyproject.toml` の `[tool.pyright]` でも指定できる。詳細は
[Pyrightの環境設定](https://github.com/microsoft/pyright/blob/main/docs/configuration.md) を参照。
一時的な切替は `:LspPyrightSetPythonPath /absolute/path/to/python` を使う。
プロジェクトがmypyを要求する場合はCLIやCIでも引き続き実行する。

## Go

PATHにプロジェクトで使うGo toolchainを用意する。goplsは `go.work`、`go.mod`、`.git` を基準に
ワークスペースを決める。複数モジュールを同時に編集する場合は共通ディレクトリで
`go work init ./module-a ./module-b` を実行する。詳細は
[goplsのワークスペース設定](https://go.dev/gopls/workspace) を参照。
import整理は `<leader>la` のコードアクションから実行できる。

## デバッグ

共通操作は次の通り。

| キー | 操作 |
| --- | --- |
| `F4` | 条件付きブレークポイント |
| `F5` | ブレークポイント切替 |
| `F6` / `F8` / `F9` | step into / over / out |
| `F7` | 開始、構成選択、再開 |
| `F10` | セッション一覧 |
| `F11` | セッション終了 |
| `F12` | DAP UI切替 |

祖先ディレクトリの `.vscode/launch.json` をGit境界まで探索し、`${workspaceFolder}` はそのファイルがある
プロジェクトを基準に展開する。個別プロジェクトの引数、環境変数、mainクラス、作業ディレクトリはここに記述できる。

Javaのmainクラス探索は大規模プロジェクトで高コストになり得るため自動実行しない。
launch方式を使うときだけJavaバッファで `mdc` を押し、生成された構成を `F7` で選ぶ。
`mtc` は現在のテストクラス、`mtn` はカーソル位置に最も近いテストをデバッグする。
検証済みのjava-test 0.46.0はJUnit 6.0.1で動作したが、JUnit 5.11.4とはrunnerの互換性がなかった。
古いJUnitのプロジェクトではMavenからテストを実行するか、対応するjava-testの版を使う。
実行中のSpring Bootへattachする場合は、サービスをデバッグポート付きで起動して `F7` から
「実行中のJVMにアタッチ」を選ぶ。

```sh
./mvnw -pl spring-petclinic-customers-service spring-boot:run \
  -Dspring-boot.run.jvmArguments='-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005'
```

複数サービスを同時にデバッグするときはポートを分ける。Pythonは現在のファイルのlaunchと
debugpyの `127.0.0.1:5678` へのattach、Goは現在のパッケージ、パッケージテスト、
ローカルプロセスへのattachを選択できる。

## 確認

`:checkhealth vim.lsp` で有効な設定と接続を確認する。Javaは同じ集約ルートで1つのjdtls、
PythonはPyrightとRuff、Goはgoplsが接続する。整形設定は `:ConformInfo` で確認できる。

外部サーバーを起動しない設定テストはリポジトリ直下で実行する。

```sh
nvim --headless -u NONE -l tests/nvim-lsp.lua
nvim --headless -u NONE -l tests/nvim-debugging.lua
```

JDT LSの初回インポート時間とRSSを測る場合は、普段使うNeovim構成で実行する。

```sh
JDTLS_BENCHMARK_FILE=/path/to/project/src/main/java/example/App.java \
JDTLS_BENCHMARK_PROJECTS=9 \
nvim --headless -l tests/manual/nvim-java-benchmark.lua
```
