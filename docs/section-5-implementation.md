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

The `tree-sitter` CLI's most important feature is the `generate` subcommand. This subcommand reads context-free grammar from a file called `grammar.js` and outputs a parser as a C file called `parser.c`. The source files in the [`cli/src`](https://github.com/tree-sitter/tree-sitter/tree/master/cli/src) directory all play a role in producing the code in `parser.c`. This section will describe some key parts of this process.

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

Once a grammar has been parsed, it must be transformed in several ways before it can be used to generate a parser. Each transformation is implemented by a separate file in the [`prepare_grammar`](https://github.com/tree-sitter/tree-sitter/tree/master/cli/src/generate/prepare_grammar) directory, and the transformations are ultimately composed together in `prepare_grammar/mod.rs`.

At the end of these transformations, the initial grammar is split into two grammars: a *syntax grammar* and a *lexical grammar*. The syntax grammar describes how the language's [*non-terminal symbols*](https://en.wikipedia.org/wiki/Terminal_and_nonterminal_symbols) are constructed from other grammar symbols, and the lexical grammar describes how the grammar's *terminal symbols* (strings and regexes) can be composed from individual characters.

### Building Parse Tables



## The Runtime

WIP

<!-- textlint-enable -->

[前のページ(シンタックスハイライター)](./section-4-syntax-highlighting.md) <---- [目次](../README.md) ----> [次のページ(コントリビュート)](./section-6-contributing.md)