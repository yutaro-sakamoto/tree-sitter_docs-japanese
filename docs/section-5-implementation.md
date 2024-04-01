[前のページ(シンタックスハイライター)](./section-4-syntax-highlighting.md) <---- [目次](../README.md) ----> [次のページ(コントリビュート)](./section-6-contributing.md)

<!-- textlint-disable -->

# Implementation

Tree-sitterCライブラリ（`libtree-sitter`）とコマンドラインツール（`tree-sitter` CLI）の2つのコンポーネントで構成されています。

`libtree-sitter`はCLIで生成されたパーサーと組み合わせて、ソースコードから構文木を生成し、ソースコードが変更されるたびに構文木を最新の状態に保ちます。
`libtree-sitter`はプレーンなC言語で書かれ、アプリケーションに埋め込むことを想定して設計されています。
ています。そのインターフェースはヘッダファイル[`tree_sitter/api.h`](https://github.com/tree-sitter/tree-sitter/blob/master/lib/include/tree_sitter/api.h)で定義されている。

CLIは、言語を記述する文脈自由文法を提供することで、言語のパーサーを生成できます。
CLIはビルドツールであり、一度パーサーが生成されると不要になります。
パーサはRustで書かれており、[crates.io](https://crates.io)や[npm](http://npmjs.com)から利用でき、またビルド済みバイナリを[GitHub](https://github.com/tree-sitter/tree-sitter/releases/latest)からダウンロードできる。

## The CLI

The `tree-sitter` CLI's most important feature is the `generate` subcommand. This subcommand reads context-free grammar from a file called `grammar.js` and outputs a parser as a C file called `parser.c`. The source files in the [`cli/src`](https://github.com/tree-sitter/tree-sitter/tree/master/cli/src) directory all play a role in producing the code in `parser.c`. This section will describe some key parts of this process.

### Parsing a Grammar

First, Tree-sitter must must evaluate the JavaScript code in `grammar.js` and convert the grammar to a JSON format. It does this by shelling out to `node`. The format of the grammars is formally specified by the JSON schema in [grammar-schema.json](https://github.com/tree-sitter/tree-sitter/blob/master/cli/src/generate/grammar-schema.json). The parsing is implemented in [parse_grammar.rs](https://github.com/tree-sitter/tree-sitter/blob/master/cli/src/generate/parse_grammar.rs).

### Grammar Rules

A Tree-sitter grammar is composed of a set of *rules* - objects that describe how syntax nodes can be composed from other syntax nodes. There are several types of rules: symbols, strings, regexes, sequences, choices, repetitions, and a few others. Internally, these are all represented using an [enum](https://doc.rust-lang.org/book/ch06-01-defining-an-enum.html) called [`Rule`](https://github.com/tree-sitter/tree-sitter/blob/master/cli/src/generate/rules.rs).

### Preparing a Grammar

Once a grammar has been parsed, it must be transformed in several ways before it can be used to generate a parser. Each transformation is implemented by a separate file in the [`prepare_grammar`](https://github.com/tree-sitter/tree-sitter/tree/master/cli/src/generate/prepare_grammar) directory, and the transformations are ultimately composed together in `prepare_grammar/mod.rs`.

At the end of these transformations, the initial grammar is split into two grammars: a *syntax grammar* and a *lexical grammar*. The syntax grammar describes how the language's [*non-terminal symbols*](https://en.wikipedia.org/wiki/Terminal_and_nonterminal_symbols) are constructed from other grammar symbols, and the lexical grammar describes how the grammar's *terminal symbols* (strings and regexes) can be composed from individual characters.

### Building Parse Tables



## The Runtime

WIP

<!-- textlint-enable -->

[前のページ(シンタックスハイライター)](./section-4-syntax-highlighting.md) <---- [目次](../README.md) ----> [次のページ(コントリビュート)](./section-6-contributing.md)