[前のページ(シンタックスハイライター)](./section-4-syntax-highlighting.md) <---- [目次](../README.md) ----> [次のページ(コントリビュート)](./section-6-contributing.md)

# 実装

Tree-sitterCライブラリ（`libtree-sitter`）とコマンドラインツール（`tree-sitter` CLI）の2つのコンポーネントで構成されている。

`libtree-sitter`はCLIで生成されたパーサーと組み合わせて、ソースコードから構文木を生成し、ソースコードが変更されるたびに構文木を最新の状態に保つ。
`libtree-sitter`はプレーンなC言語で書かれ、アプリケーションに埋め込むことを想定して設計されている。
そのインターフェースはヘッダファイル[`tree_sitter/api.h`](https://github.com/tree-sitter/tree-sitter/blob/master/lib/include/tree_sitter/api.h)で定義されている。

CLIは、言語を記述する文脈自由文法を提供することで、言語のパーサーを生成できる。
CLIはビルドツールであり、一度パーサーが生成されると不要になる。
パーサはRustで書かれており、[crates.io](https://crates.io)や[npm](http://npmjs.com)から利用でき、またビルド済みバイナリを[GitHub](https://github.com/tree-sitter/tree-sitter/releases/latest)からダウンロードできる。

## The CLI

`tree-sitter` CLIの最も重要な機能は、サブコマンドの`generate`である。
このサブコマンドは文脈自由文法を`grammar.js`というファイルから読み込み、`parser.c`というCファイルとしてパーサを出力する。
[`cli/src`](https://github.com/tree-sitter/tree-sitter/tree/master/cli/src)ディレクトリのソースコードは、`parser.c`の生成に使用される。
このセクションでは、この生成プロセスのいくつかの重要な部分について説明する。

<!-- textlint-disable -->

### 文法のパース

はじめに、Tree-sitterは`grammar.js`のJavaScriptコードを評価し、文法をJSON形式に変換する必要がある。
これは`node`を使って行われる。 
文法のフォーマットは[grammar-schema.json](https://github.com/tree-sitter/tree-sitter/blob/master/cli/src/generate/grammar-schema.json)によって規定される。
パースは[parse_grammar.rs](https://github.com/tree-sitter/tree-sitter/blob/master/cli/src/generate/parse_grammar.rs)に実装される。

### 文法ルール

tree-sitterの文法はルールの集合からなる
。これらのルールは、構文ノードが他の構文ノードからどのように構成されるかを記述するオブジェクトである。
ルールにはいくつかのタイプがある: シンボル、文字列、正規表現、シーケンス、選択、繰り返し、その他。
内部ではこれらはすべて[`Rule`](https://github.com/tree-sitter/tree-sitter/blob/master/cli/src/generate/rules.rs)と呼ばれる[enum](https://doc.rust-lang.org/book/ch06-01-defining-an-enum.html)を使って表現される。

### Preparing a Grammar

一度文法が解析されると、パーサを生成するためにいくつかの方法で変換する必要がある。
各変換は[`prepare_grammar`](https://github.com/tree-sitter/tree-sitter/tree/master/cli/src/generate/prepare_grammar)ディレクトリの中の
個々のファイルで実装され、最終的には`prepare_grammar/mod.rs`で統合される。

これらの変換の最後に、初期の文法は*構文文法*と*レキシカル文法の*2つの文法に分割される。
構文の文法は、言語の[*非終端記号*](https://en.wikipedia.org/wiki/Terminal_and_nonterminal_symbols)が
他の文法記号からどのように構成されるかを記述し、字句の文法は文法の*終端記号*（文字列と正規表現）が個々の文字からどのように構成されるかを記述する。

### Building Parse Tables



## The Runtime

WIP

<!-- textlint-enable -->

[前のページ(シンタックスハイライター)](./section-4-syntax-highlighting.md) <---- [目次](../README.md) ----> [次のページ(コントリビュート)](./section-6-contributing.md)