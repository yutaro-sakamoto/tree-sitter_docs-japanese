[前のページ(Tree-sitterの実装)](./section-5-implementation.md) <---- [目次](../README.md) ----> [次のページ(Playground)](./section-7-playground.md)

<!-- textlint-disable -->

# コントリビュート

## Code of Conduct

Tree-sitterへのコントリビュータは[Contributor Covenant](https://www.contributor-covenant.org/version/1/4/code-of-conduct)を遵守してください。

## Tree-sitterの開発

### 事前条件

tree-sitterを変更するには、以下が必要です:

1. コアライブラリや生成されたパーサをコンパイルするためのCコンパイラ。
2. Rustバインディングのコンパイル・ハイライトのライブラリ・CLIのコンパイルに必要な[Rustツールチェイン](https://rustup.rs/)。
3. grammer.jsファイルからパーサを生成するために必要なNode.jsとNPM。
4. WASMライブラリをビルドするために、[Emscripten](https://emscripten.org/)または[Docker](https://www.docker.com/)がインストールされているか。

### ビルド

リポジトリをクローンする。

```sh
git clone https://github.com/tree-sitter/tree-sitter
cd tree-sitter
```

(任意)WASMライブラリをビルドする。
もしこのステップをスキップすると、`tree-sitter playground`コマンドの実行にはインターネット接続が必要になります。
Emscriptenがインストールされている場合、`emcc`コンパイラが使用されます。それ以外の場合、Dockerが使用されます。

```sh
./script/build-wasm
```

RustライブラリとCLIをビルドする。

```sh
cargo build --release
```

これにより、`target/release`フォルダに`tree-sitter`CLI実行ファイルが作成されます。

### テスト

テストが実行可能になる前に、テストに使用されるいくつかの文法をクローンする必要があります。

```sh
script/fetch-fixtures
```

CLIに施した変更をテストするために、現在のCLIコードを使用してこれらのパーサを再生成します。

```sh
script/generate-fixtures
```

その後、テストを実行できます。

```sh
script/test
```

同様に、WASMバインディングをテストするには、これらのパーサをWASMにコンパイルする必要があります。

```sh
script/generate-fixtures-wasm
script/test-wasm
```

### デバッグ

テストスクリプトはいくつかの便利なフラグを持っています。
`script/test -h`を実行することですべてのフラグの一覧を確認できます。
以下は主なフラグの一部です。

特定のユニットテストを実行したい場合は、その名前（またはその一部）を引数として渡します。

```sh
script/test test_does_something
```

-gフラグを使用してデバッガ（`lldb`または`gdb`）でテストを実行できます。

```sh
script/test test_does_something -g
```

Tree-sitterのテストスイートの一部は、いくつかの異なる言語のコーパステストを解析し、コーパス内の各例に対してランダムな編集を行うことです。
特定の言語のテストのみを実行したい場合は、`-l`フラグを渡します。
また、コーパスから特定の_例_を実行したい場合は、`-e`フラグを渡します。

```sh
script/test -l javascript -e Arrays
```

## パッケージの公開

メインリポジトリである[`tree-sitter/tree-sitter`](https://github.com/tree-sitter/tree-sitter)は、さまざまな言語のパッケージレジストリに公開されているいくつかのパッケージのソースコードを含んでいます。

- Rustクレート [crates.io](https://crates.io):
  - [`tree-sitter`](https://crates.io/crates/tree-sitter) - Rustバインディング
  - [`tree-sitter-highlight`](https://crates.io/crates/tree-sitter-highlight) - シンタックスハイライトのライブラリ
  - [`tree-sitter-cli`](https://crates.io/crates/tree-sitter-cli) - コマンドラインツール
- JavaScriptモジュール [npmjs.com](https://npmjs.com):
  - [`web-tree-sitter`](https://www.npmjs.com/package/web-tree-sitter) - コアライブラリ向けWASMベースのJavaScriptバインディング
  - [`tree-sitter-cli`](https://www.npmjs.com/package/tree-sitter-cli) - コマンドラインツール

さらに、他のいくつかの依存リポジトリには、別の公開パッケージが含まれています。

- [`tree-sitter/node-tree-sitter`](https://github.com/tree-sitter/node-tree-sitter) - npmjs.comで[`tree-sitter`](https://www.npmjs.com/package/tree-sitter)として公開されているコアライブラリ向けのNode.jsバインディング
- [`tree-sitter/py-tree-sitter`](https://github.com/tree-sitter/py-tree-sitter) - [PyPI.org](https://pypi.org)で[`tree-sitter`](https://pypi.org/project/tree-sitter)として公開されているコアライブラリ向けのPythonバインディング

## 新リリースの公開

CLIの新リリースを公開するには、以下の手順が必要です。

1. すべての変更をコミットしてプッシュし、CIが成功することを確認します。

   ```sh
   git commit -m "Fix things"
   git push
   ```

2. 新しいタグを作成します。

   ```sh
   script/version patch
   ```

これは、現在のバージョンを決定し、_patch_バージョン番号を増やし、RustとNode CLIパッケージの`Cargo.toml`と`package.json`ファイルを更新します。
その後、新しいバージョンのためのコミットとタグを作成します。
使用できる引数についての詳細は、[`npm version`](https://docs.npmjs.com/cli/version)コマンドのドキュメントを参照してください。

3. タグとコミットをプッシュします。

   ```sh
   git push
   git push --tags
   ```

4. CIが成功するのを待ちます。
gitタグのため、CIジョブはアーティファクトを[GitHubリリース](https://github.com/tree-sitter/tree-sitter/releases)を公開します。
`tree-sitter-cli`のnpmモジュールは、インストール中に対応するGitHubリリースから適切なバイナリをダウンロードすることで動作します。
そのため、バイナリがアップロードされるまでnpmパッケージを公開しない方が良いです。

5. npmパッケージを公開します。

   ```sh
   cd cli/npm
   npm publish
   ```
<!-- textlint-enable -->

[前のページ(Tree-sitterの実装)](./section-5-implementation.md) <---- [目次](../README.md) ----> [次のページ(Playground)](./section-7-playground.md)