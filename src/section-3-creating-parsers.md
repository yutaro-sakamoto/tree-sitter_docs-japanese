[前のページ(パーサを使う)](./section-2-using-parsers.md) <---- [目次](../README.md) ----> [次のページ(シンタックスハイライター)](./section-4-syntax-highlighting.md)

# パーサを作る

Tree-sitterによるパーサの開発は学習が難しいものの、一度コツをつかめば楽しく、禅のような感覚さえ覚えるだろう。
このドキュメントは、開発を始め方を示し、開発を進める上での考え方を身につける一助となるだろう。

## はじめに

### 依存するソフトウェア

Tree-sitterパーサを開発するためには、いくつかのソフトウェアをインストールする必要がある。

* **Node.js** - Tree-sitterの文法規則はJavaScriptで記述され、Tree-sitterはJavascript処理系として[Node.js](https://nodejs.org/ja/)を利用する。したがって、`node`コマンドの存在するディレクトリを環境変数`PATH`に追加する必要がある。また、Node.jsのバージョンが6.0以上であることも必要である。
* **Cコンパイラ** - Tree-sitterはC言語で記述されたパーサを生成する。パーサの実行とテストを行う`tree-sitter parse`と`tree-sitter test`コマンドを使うにはC/C++コンパイラがインストールされている必要がある。Tree-sitterは各プラットフォーム規定する標準的なディレクトリからC/C++コンパイラを検索して利用する。

### インストール

Tree-sitterパーサを生成するには、[the `tree-sitter` CLI](https://github.com/tree-sitter/tree-sitter/tree/master/cli)が必要であり、複数の方法でインストールできる。

* `tree-sitter-cli` [Rustクレート](https://github.com/tree-sitter/tree-sitter/tree/master/cli) をRustパッケージマネージャである[`cargo`](https://doc.rust-lang.org/cargo/getting-started/installation.html)を使ってソースコードからビルドする。これは任意のプラットフォームで有効なインストール方法である。詳細は[コントリビュート](./section-6-contributing.md)を参照すること。
`tree-sitter-cli`[Node.jsモジュール](https://www.npmjs.com/package/tree-sitter-cli)をNodeパッケージマネージャの[`npm`](https://docs.npmjs.com/)を使ってインストールする。
<!-- textlint-disable -->
この方法は手軽だが、pre-builtバイナリを使うため、限られたプラットフォームでのみ利用可能な方法である。
<!-- textlint-enable -->
* 使用するプラットフォーム向けのバイナリを[最新のGitHubリリースページ](https://github.com/tree-sitter/tree-sitter/releases)からダウンロードし、そのバイナリを格納したディレクトリのパスを環境変数`PATH`に追加する。

### プロジェクトの新規作成

<!-- textlint-disable -->
パーサのリポジトリ名は「tree-sitter-」後に言語名を付けたものが好ましい。
<!-- textlint-enable -->

```sh
mkdir tree-sitter-${YOUR_LANGUAGE_NAME}
cd tree-sitter-${YOUR_LANGUAGE_NAME}
```

`npm` コマンドを使って、プロジェクトに関する情報を格納する`package.json`を作成し、Node.jsから開発したパーサを利用できるようする。

```sh
# 下記のコマンドでは、対話モードでプロジェクトに関する情報を入力する。
npm init

# 下記のコマンドにより、Nodeから開発したパーサを利用可能にするためのモジュールをインストールする。
npm install --save nan

# 下記のコマンドにより、Tree-sitter CLIをインストールする。
npm install --save-dev tree-sitter-cli
```

最後のコマンドにより、作業ディレクトリの`node_modules`ディレクトリにCLIツールをインストールする。
実行可能ファイル`tree-sitter`が`node_modules/.bin`ディレクトリに作成される。
Node.jsの慣習に従って、このフォルダを環境変数`PATH`に追加しておくと、このディレクトリで作業しているときに簡単にプログラムを実行できる。

```sh
# In your shell profile script
export PATH=$PATH:./node_modules/.bin
```

CLIのインストールを完了したら、`grammar.js`に下記の内容を書き込む。

```js
module.exports = grammar({
  name: 'YOUR_LANGUAGE_NAME',

  rules: {
    // TODO: add the actual grammar rules
    source_file: $ => 'hello'
  }
});
```

その後、下記のコマンドを実行する。

```sh
tree-sitter generate
```

これは、この些細な言語を解析するのに必要なCコードと、このネイティブパーサーをNode.jsモジュールとしてコンパイルしてロードするために必要ないくつかのファイルを生成する。

下記のように「hello」と書き込まれたソースファイルを用意すれば、生成したパーサをテストできる。

```sh
echo 'hello' > example-file
tree-sitter parse example-file
```
WindowsのPowerShellを使う場合は下記のコマンドを実行する。

```pwsh
"hello" | Out-File example-file -Encoding utf8
tree-sitter parse example-file
```

これにより、下記のメッセージが出力される。

```
(source_file [0, 0] - [1, 0])
```

実際に動作するパーサを作成できた。

## Tool Overview

コマンドラインツール`tree-sitter`の機能を紹介する。

### `generate`コマンド

最も重要なのは`tree-sitter generate`コマンドである。
このコマンドはカレントディレクトリの`grammar.js`を読み込み、`src/parser.c`にパーサの実装を書き出す。
文法を変更したら、`tree-sitter generate`コマンドを再度実行する必要がある。

`tree-sitter generate`を最初に実行したとき、下記のファイルも生成される。

* `binding.gyp` -Node.jsが作成した言語をどのようにコンパイルするかが記述されるたファイル。
* `bindings/node/index.js` - 作成した言語を使用する際にNode.jsが内部で読み込むファイル。
* `bindings/node/binding.cc` - Node.jsが使用するJavaScriptオブジェクトのラッパーが記述されるたファイル。
* `bindings/rust/lib.rs` - 作成した言語をRustから利用するためのラッパーが記述されたファイル。
* `bindings/rust/build.rs` - Rustクレート向けのビルド処理が記述されるたファイル。
* `src/tree_sitter/parser.h` - 生成した`parser.c`が使用するヘッダファイル。

文法に曖昧さや局所的な曖昧さ（原文：local ambiguity）がある場合、Tree-sitterはパーサの生成時にそれを検出し、
Unresolved conflictというエラーメッセージを表示して終了する。
これらのエラーの詳細については、以下を参照せよ。

### Command: `test`

`tree-sitter test`コマンドを使ってパーサを簡単にテストできる。

新たな文法規則を追加するたびに、パースするたびに構文木がどのような形式になるかを検証するテストを作成すべきである。
これらのテストはプロジェクトルートの`corpus/`または`test/corpus/`ディレクトリ以下のテキストファイルに専用フォーマットで記述する。

例えば、下記の内容が書き込まれた`test/corpus/statements.txt`ファイルを考える。

```
==================
Return statements
==================

func x() int {
  return 1;
}

---

(source_file
  (function_definition
    (identifier)
    (parameter_list)
    (primitive_type)
    (block
      (return_statement (number)))))
```

* `=`がの間に**テスト名**を書く。
* その後にパーサの**入力**となるソースコードを書き、3つ以上の`-`を含む行を書く。
* その後に**出力として期待される構文木**を[`S式`](https://ja.wikipedia.org/wiki/S%E5%BC%8F)で書く。S式中の空白は無視されるが、理想的には構文木は読みやすい方が良い。S式は、`func`、`(`、`;`といった、分包機そうでは文字列や正規表現で表される構文ノードを表示しないことに注意せよ。構文木は、[「パーサの使う」のこの節](./section-2-using-parsers.md#名前付きノードと匿名ノード)で説明した名前付きノード*のみを表示する。

  期待出力を示すセクションには、各子ノードに関連付けられた[*フィールド名*][field-names-section]をオプションで表示できる。テストにフィールド名を含める場合、S式内のノードの前に、コロンに続いてノード自体を記述する前に、ノードのフィールド名を記述する。

```
(source_file
  (function_definition
    name: (identifier)
    parameters: (parameter_list)
    result: (primitive_type)
    body: (block
      (return_statement (number)))))
```

* もし言語の構文が`===`と`---`のテストセパレータと衝突する場合、同一のサフィックス（下記の例では`|||`）を追加して曖昧さを解消できる。


```
==================|||
Basic module
==================|||

---- MODULE Test ----
increment(n) == n + 1
====

---|||

(source_file
  (module (identifier)
    (operator (identifier)
      (parameter_list (identifier))
      (plus (identifier_ref) (number)))))
```

これらのテストは重要である。
テストはパーサのAPIドキュメントとして機能し、文法を変更するたびにすべてが正しくパースされていることを確認するために実行できる。

デフォルトで`tree-sitter test`コマンドは`corpus`または`test/corpus/`フォルダ内のすべてのテストを実行する。
特定のテストを実行するには、`-f`フラグを使う。

```sh
tree-sitter test -f 'Return statements'
```

包括的なテストを追加することが推奨される。
もし非可視性のノードがある場合、`corpus`ディレクトリ内のテストファイルに追加することが良いだろう。
通常、各言語構造のすべての組み合わせをテストすることが良い。
これによりテストカバレッジが向上し、言語の「エッジ」を理解するための方法を読者に二重で提供できる。

<!-- textlint-disable -->

#### 自動コンパイル

`tree-sitter test`を実行するたびに、パーサのCコードを再コンパイルするので、最初の実行時には少し時間がかかる場合がある。
これは、Tree-sitterが自動的にCコードを動的ロード可能なライブラリにコンパイルするためである。
`tree-sitter generate`を再実行してパーサを更新するたびに、必要に応じてパーサを再コンパイルする。

#### シンタックスハイライトのテスト

`tree-sitter test`コマンドは、`test/highlight`フォルダ内にシンタックスハイライトのテストが存在する場合、それらも実行する。
詳細は[シンタックスハイライトのページ][syntax-highlighting-tests]を参照すること。

### `parse`コマンド

`tree-sitter parse`コマンドを使って任意のファイルをパースできる。
これにより、下記のような範囲とフィールド名を含む構文木が表示される。

```
(source_file [0, 0] - [3, 0]
  (function_declaration [0, 0] - [2, 1]
    name: (identifier [0, 5] - [0, 9])
    parameters: (parameter_list [0, 9] - [0, 11])
    result: (type_identifier [0, 12] - [0, 15])
    body: (block [0, 16] - [2, 1]
      (return_statement [1, 2] - [1, 10]
        (expression_list [1, 9] - [1, 10]
          (int_literal [1, 9] - [1, 10]))))))
```

`tree-sitter parse`コマンドには、任意のファイルパスとグロブパターンを渡すことができ、指定されたすべてのファイルを解析する。
パースエラーが発生した場合、コマンドはゼロ以外のステータスコードで終了する。
`--quiet`フラグを使用して、構文木の出力を抑制することもできる。
さらに、`--stat`フラグを使用すると、処理されたすべてのファイルに対する集計されたパース成功/失敗情報が出力される。
これにより、`tree-sitter parse`を二次的なテスト戦略として使用できるようになります。
つまり、多数のファイルがエラーなしでパースされることを確認できます。

```sh
tree-sitter parse 'examples/**/*.go' --quiet --stat
```

### `highlight`コマンド

`tree-sitter highlight`コマンドを使って任意のファイルにシンタックスハイライトの処理を実行できる。
これにより、ターミナルに直接色を出力することも可能だし、`--html`フラグを渡すことでHTMLを生成することもできる。
詳細は[シンタックスハイライトのページ][syntax-highlighting]を参照すること。

### 文法DSL

下記は`grammar.js`で使用できる組み込み関数の一覧である。
これらの関数の使用例は、後のセクションで詳しく説明される。

* **シンボル(`$`オブジェクト)** - すべての文法規則は、通常`$`と呼ばれるパラメータを取るJavaScript関数として記述される。`$.identifier`という構文は、規則内で他の文法シンボルを参照する方法である。`$.MISSING`または`$.UNEXPECTED`で始まる名前は、`tree-sitter test`コマンドに特別な意味があるため避けるべきである。
* **文字列と正規表現リテラル** - 文法の終端記号は、JavaScriptの文字列と正規表現を使って記述される。もちろん、パーサは実際にはJavaScriptの正規表現エンジンを使ってこれらの正規表現を評価しない。パーサは、各パーサの一部として独自の正規表現マッチングロジックを生成する。正規表現リテラルは、文法内で正規表現を書く便利な方法である。
* **シーケンス: `seq(rule1, rule2, ...)`** - この関数は、他のルールに一つずつ順番にマッチするルールを作成する。これは[EBNF記法][ebnf]で複数のシンボルを隣り合わせに書くのと同様である。
* **選択: `choice(rule1, rule2, ...)`** - この関数は、可能なルールのセットの*1つ*にマッチするルールを作成する。引数の順序は重要ではない。これは、EBNF記法の`|`（パイプ）演算子に類似している。
* **繰り返し: `repeat(rule)`** - この関数は、指定されたルールの*0個以上*の出現にマッチするルールを作成する。以前の`repeat`ルールは`repeat1`を使って実装されているが、非常に一般的であるため含まれている。
* ** 繰り返し1: `repeat1(rule)`** - この関数は、指定されたルールの*1個以上*の出現にマッチするルールを作成する。以前の`repeat`ルールは`repeat1`を使って実装されているが、非常に一般的であるため含まれている。
* **オプション: `optional(rule)`** - この関数は、指定されたルールの*0個または1個*の出現にマッチするルールを作成する。これは、EBNF記法の`[x]`（角括弧）構文に類似している。
* **優先: `prec(number, rule)`** - この関数は、指定されたルールに数値の優先度を付与し、パーサ生成時に[*LR(1)コンフリクト*][lr-conflict]を解決するために使用される。2つのルールが、1つのトークンの先読みを考慮して真の曖昧さまたは*局所的な*曖昧さを表す方法で重なる場合、Tree-sitterは、より高い優先度を持つルールをマッチングしてコンフリクトを解決しようとする。すべてのルールのデフォルトの優先度はゼロである。これは、Yacc文法の[優先度ディレクティブ][yacc-prec]と同様に機能する。
* **左結合 : `prec.left([number], rule)`** - この関数は、指定されたルールを左結合としてマークし（オプションで数値の優先度を適用）、LR(1)コンフリクトが発生した場合、すべてのルールが同じ数値の優先度を持つ場合、Tree-sitterはルールの結合性を参照する。左結合ルールがある場合、Tree-sitterは、より早く終了するルールをマッチングすることを優先する。これは、Yacc文法の[結合性ディレクティブ][yacc-prec]と同様に機能する。
* **右結合 : `prec.right([number], rule)`** - この関数は`prec.left`と同様であるが、Tree-sitterに対して後で終了するルールをマッチングすることを優先するように指示する。
* **動的優先度: `prec.dynamic(number, rule)`** - この関数はprecと類似するが、指定された数値の優先度が*パーサ生成時*ではなく*ランタイム*で適用される。これは、文法内の`conflicts`フィールドを使用してコンフリクトを動的に処理し、本当の*曖昧さ*がある場合にのみ必要である。複数のルールが正しく特定のコードにマッチする場合、Tree-sitterは、各ルールに関連付けられた動的優先度の合計を比較し、最も高い合計を持つものを選択する。これは、Bison文法の[動的優先度ディレクティブ][bison-dprec]と似ている。
* **Tokens : `token(rule)`** - This function marks the given rule as producing only a single token. Tree-sitter's default is to treat each String or RegExp literal in the grammar as a separate token. Each token is matched separately by the lexer and returned as its own leaf node in the tree. The `token` function allows you to express a complex rule using the functions described above (rather than as a single regular expression) but still have Tree-sitter treat it as a single token.
* **Immediate Tokens : `token.immediate(rule)`** - Usually, whitespace (and any other extras, such as comments) is optional before each token. This function means that the token will only match if there is no whitespace.
* **Aliases : `alias(rule, name)`** - This function causes the given rule to *appear* with an alternative name in the syntax tree. If `name` is a *symbol*, as in `alias($.foo, $.bar)`, then the aliased rule will *appear* as a [named node][named-vs-anonymous-nodes-section] called `bar`. And if `name` is a *string literal*, as in `alias($.foo, 'bar')`, then the aliased rule will appear as an [anonymous node][named-vs-anonymous-nodes-section], as if the rule had been written as the simple string.
* **Field Names : `field(name, rule)`** - This function assigns a *field name* to the child node(s) matched by the given rule. In the resulting syntax tree, you can then use that field name to access specific children.

In addition to the `name` and `rules` fields, grammars have a few other optional public fields that influence the behavior of the parser.

* **`extras`** - an array of tokens that may appear *anywhere* in the language. This is often used for whitespace and comments. The default value of `extras` is to accept whitespace. To control whitespace explicitly, specify `extras: $ => []` in your grammar.
* **`inline`** - an array of rule names that should be automatically *removed* from the grammar by replacing all of their usages with a copy of their definition. This is useful for rules that are used in multiple places but for which you *don't* want to create syntax tree nodes at runtime.
* **`conflicts`** - an array of arrays of rule names. Each inner array represents a set of rules that's involved in an *LR(1) conflict* that is *intended to exist* in the grammar. When these conflicts occur at runtime, Tree-sitter will use the GLR algorithm to explore all of the possible interpretations. If *multiple* parses end up succeeding, Tree-sitter will pick the subtree whose corresponding rule has the highest total *dynamic precedence*.
* **`externals`** - an array of token names which can be returned by an [*external scanner*](#external-scanners). External scanners allow you to write custom C code which runs during the lexing process in order to handle lexical rules (e.g. Python's indentation tokens) that cannot be described by regular expressions.
* **`precedences`** - an array of array of strings, where each array of strings defines named precedence levels in descending order. These names can be used in the `prec` functions to define precedence relative only to other names in the array, rather than globally. Can only be used with parse precedence, not lexical precedence.
* **`word`** - the name of a token that will match keywords for the purpose of the [keyword extraction](#keyword-extraction) optimization.
* **`supertypes`** an array of hidden rule names which should be considered to be 'supertypes' in the generated [*node types* file][static-node-types].


## 文法を記述する

文法の記述には創造性が必要である。与えられた言語を記述するために使用できるCFG（文脈自由文法）は無限に存在する。良いTree-sitterパーサを作成するためには、2つの重要な特性を持つ文法を作成する必要がある。

1. **直感的な構造** - Tree-sitterの出力は[具象構文木][cst]であり、木の各ノードは文法内の[端末記号または非端末記号][non-terminal]に直接対応している。したがって、解析しやすい木を生成するためには、文法内の記号と言語内の認識可能な構造との間に直接的な対応関係がある必要がある。これは当たり前のことのように思えるかもしれないが、[言語仕様][language-spec]や[Yacc][yacc]/[Bison][bison]パーサのような文脈で文脈自由文法が書かれる方法とは非常に異なる。

2. **LR(1)の遵守** - Tree-sitterは[GLRパーサ][glr-parsing]アルゴリズムに基づいている。これは、任意の文脈自由文法を処理できるが、[LR(1)文法][lr-grammars]と呼ばれる文脈自由文法のクラスで最も効率的に動作する。この点で、Tree-sitterの文法は[Yacc][yacc]や[Bison][bison]の文法に似ているが、[ANTLR文法][antlr]、[Parsing Expression Grammars][peg]、または言語仕様で一般的に使用される[曖昧な文法][ambiguous-grammar]とは異なる。

既存の文脈自由文法を直接Tree-sitterの文法形式に変換するだけでは、これらの2つの特性を満たすことはできない可能性が高い。多くの場合、次の種類の調整が必要となる。次のセクションでは、これらの調整について詳しく説明する。

### まず最初に遵守すべきルール

構文解析しようとする言語に対して厳密な仕様を見つけることは、通常は良いアイデアである。
この仕様には、おそらく文脈自由文法が含まれているであろう。
このCFGのルールを読み進めると、複雑で循環的な関係のグラフが見つかるかもしれない。
このグラフをナビゲートする方法が不明確になるかもしれませんが、文法を定義する際にどのように進めるべきかを理解するために、このグラフを読み進めることが重要である。

言語は全く違った構造を持つが、その構造はしばしば*宣言*、*定義*、*文*、*式*、*型*、*パターン*のような似たようなグループに分類されることがある。
文法を記述する際に、これらの基本的な*グループ*の記号を含むだけの構造を作成することが最初のステップとして良い。
Goのような言語の場合、次のように始めることができる。

```js
{
  // ...

  rules: {
    source_file: $ => repeat($._definition),

    _definition: $ => choice(
      $.function_definition
      // TODO: other kinds of definitions
    ),

    function_definition: $ => seq(
      'func',
      $.identifier,
      $.parameter_list,
      $._type,
      $.block
    ),

    parameter_list: $ => seq(
      '(',
       // TODO: parameters
      ')'
    ),

    _type: $ => choice(
      'bool'
      // TODO: other kinds of types
    ),

    block: $ => seq(
      '{',
      repeat($._statement),
      '}'
    ),

    _statement: $ => choice(
      $.return_statement
      // TODO: other kinds of statements
    ),

    return_statement: $ => seq(
      'return',
      $._expression,
      ';'
    ),

    _expression: $ => choice(
      $.identifier,
      $.number
      // TODO: other kinds of expressions
    ),

    identifier: $ => /[a-z]+/,

    number: $ => /\d+/
  }
}
```

この文法の詳細は後に説明するが、`TODO`コメントに焦点を当てると、全体的な戦略が*幅優先*であることがわかる。
特筆すべきは、この初期のスケルトンは、言語仕様の文脈自由文法の正確なサブセットに直接マッチする必要はないということである。
単に、できるだけシンプルで明確な方法で主要なルールのグループに触れるだけでよい。

With this structure in place, you can now freely decide what part of the grammar to flesh out next. For example, you might decide to start with *types*. One-by-one, you could define the rules for writing basic types and composing them into more complex types:

この構造ができたら、次にどの部分の文法を詳細にするかを自由に決定できる。
例えば、*型*から始める場合、一つずつ基本的な型を書くためのルールを定義し、それらをより複雑な型に組み合わせることができる。

```js
{
  // ...

  _type: $ => choice(
    $.primitive_type,
    $.array_type,
    $.pointer_type
  ),

  primitive_type: $ => choice(
    'bool',
    'int'
  ),

  array_type: $ => seq(
    '[',
    ']',
    $._type
  ),

  pointer_type: $ => seq(
    '*',
    $._type
  )
}
```

型のサブ言語をさらに発展させた後、*文*や*式*に取り組むことに切り替えることができる。
`tree-sitter parse`を使用して実際のコードを解析して進捗状況を確認すると良い。

**そして、`corpus`フォルダ内の各ルールに対して必ずテストを追加すること**

### ルールの適切な構造化

[Tree-sitter Javascript parser][tree-sitter-javascript]の作業を始めたとする。
単純に、[ECMAScript Language Spec][ecmascript-spec]の構造を直接反映しようとするかもしれない。
このアプローチの問題を説明するために、次のコード行を考えてみる。

```js
return x + y;
```

仕様によると、この行は`ReturnStatement`であり、フラグメント`x + y`は`AdditiveExpression`であり、`x`と`y`はどちらも`IdentifierReferences`である。
これらの構造の関係は、複雑な一連の生成規則によって表される。

```
ReturnStatement          ->  'return' Expression
Expression               ->  AssignmentExpression
AssignmentExpression     ->  ConditionalExpression
ConditionalExpression    ->  LogicalORExpression
LogicalORExpression      ->  LogicalANDExpression
LogicalANDExpression     ->  BitwiseORExpression
BitwiseORExpression      ->  BitwiseXORExpression
BitwiseXORExpression     ->  BitwiseANDExpression
BitwiseANDExpression     ->  EqualityExpression
EqualityExpression       ->  RelationalExpression
RelationalExpression     ->  ShiftExpression
ShiftExpression          ->  AdditiveExpression
AdditiveExpression       ->  MultiplicativeExpression
MultiplicativeExpression ->  ExponentiationExpression
ExponentiationExpression ->  UnaryExpression
UnaryExpression          ->  UpdateExpression
UpdateExpression         ->  LeftHandSideExpression
LeftHandSideExpression   ->  NewExpression
NewExpression            ->  MemberExpression
MemberExpression         ->  PrimaryExpression
PrimaryExpression        ->  IdentifierReference
```

言語仕様は、`IdentifierReference`と`Expression`の間に20の間接レベルを使用してJavaScript式の20の異なる優先度レベルをエンコードしている。
もし、言語仕様に従ってこのステートメントを表す具象構文木を作成すると、20のネストレベルがあり、実際のコードとは関係のない`BitwiseXORExpression`のような名前のノードが含まれる。

### 優先度を使用する

読みやすい構文木を生成するために、次のようなJavaScript式をより平らな構造でモデル化したい。

```js
{
  // ...

  _expression: $ => choice(
    $.identifier,
    $.unary_expression,
    $.binary_expression,
    // ...
  ),

  unary_expression: $ => choice(
    seq('-', $._expression),
    seq('!', $._expression),
    // ...
  ),

  binary_expression: $ => choice(
    seq($._expression, '*', $._expression),
    seq($._expression, '+', $._expression),
    // ...
  ),
}
```

もちろん、この平坦な構造は非常に曖昧である。
もしパーサを生成しようとすると、Tree-sitterはエラーメッセージを表示する。

```
Error: Unresolved conflict for symbol sequence:

  '-'  _expression  •  '*'  …

Possible interpretations:

  1:  '-'  (binary_expression  _expression  •  '*'  _expression)
  2:  (unary_expression  '-'  _expression)  •  '*'  …

Possible resolutions:

  1:  Specify a higher precedence in `binary_expression` than in the other rules.
  2:  Specify a higher precedence in `unary_expression` than in the other rules.
  3:  Specify a left or right associativity in `unary_expression`
  4:  Add a conflict for these rules: `binary_expression` `unary_expression`
```

`-a * b`のような式では、`-`演算子が`a * b`に適用されるか、単に`a`に適用されるかが明確ではない。
これは、上記で説明した`prec`関数が役立つ場面である。
`prec`でルールをラップすることで、特定のシンボルのシーケンスが他のシーケンスよりも*密接に結びつく*べきであることを示すことができる。
例えば、`unary_expression`の`'-', $._expression`シーケンスは、`binary_expression`の`$._expression, '+', $._expression`シーケンスよりも密接に結びつくべきである。

```js
{
  // ...

  unary_expression: $ => prec(2, choice(
    seq('-', $._expression),
    seq('!', $._expression),
    // ...
  ))
}
```

### Using Associativity

`unary_expression`の優先度を上げることで、このコンフリクトは解決されるが、別のコンフリクトが残る。

```
Error: Unresolved conflict for symbol sequence:

  _expression  '*'  _expression  •  '*'  …

Possible interpretations:

  1:  _expression  '*'  (binary_expression  _expression  •  '*'  _expression)
  2:  (binary_expression  _expression  '*'  _expression)  •  '*'  …

Possible resolutions:

  1:  Specify a left or right associativity in `binary_expression`
  2:  Add a conflict for these rules: `binary_expression`
```

`a * b * c`のような式では、`a * (b * c)`または`(a * b) * c`を意味するかが明確ではない。
これは`prec.left`と`prec.right`が使用される場面である。
ここでは2番目の解釈を選択したいので、`prec.left`を使用する。

```js
{
  // ...

  binary_expression: $ => choice(
    prec.left(2, seq($._expression, '*', $._expression)),
    prec.left(1, seq($._expression, '+', $._expression)),
    // ...
  ),
}

```js
{
  // ...

  binary_expression: $ => choice(
    prec.left(2, seq($._expression, '*', $._expression)),
    prec.left(1, seq($._expression, '+', $._expression)),
    // ...
  ),
}
```

### 隠蔽ルール

上記の例では、`_expression`や`_type`のような構文ルールはアンダースコアから始まる。
アンダースコアから始まるルール名は、構文木で*隠される*。
これは、上記の文法の`_expression`のように常に単一の子ノードをラップするルールに便利である。
もしこれらのノードが隠されていない場合、構文木に大きな深さとノイズを追加し、理解が難しくなる。

### フィールドを使用する

しばしば、構文ノードを解析する際に、順序付けられたリスト内の位置ではなく、名前で子ノードを参照できると便利である。
Tree-sitter文法は、`field`関数を使用してこれをサポートしています。
この関数を使用すると、ノードの一部またはすべての子に一意の名前を割り当てることができる。

```js
function_definition: $ => seq(
  'func',
  field('name', $.identifier),
  field('parameters', $.parameter_list),
  field('return_type', $._type),
  field('body', $.block)
)
```

このようなフィールドを追加することで、[field API][field-names-section]を使用してノードを取得できるようになる。

## 字句解析

Tree-sitterの構文解析処理は、2つのフェーズに分かれている。
1つは構文解析（上記で説明した）で、もう1つは[字句解析][lexing]であり、字句解析は、個々の文字を言語の基本的な*トークン*にグループ化する処理である。
Tree-sitterの字句解析がどのように機能するかについて、いくつか重要なことがある。

### トークンの衝突

文法はしばしば、同じ文字にマッチする複数のトークンを含んでいる。
例えば、文法には(`"if"`と`/[a-z]+/`)のトークンが含まれているかもしれない。
Tree-sitterは、これらのトークンの衝突をいくつかの方法で区別している。

1. **外部スキャナー** - 文法に外部スキャナーがある場合、`externals`配列内の1つ以上のトークンが現在の位置で有効である場合、外部スキャナーが常に最初に呼び出され、これらのトークンが存在するかどうかを決定する。

1. **Context-Aware Lexing** - Tree-sitterは、パーサ実行時に必要に応じて字句解析を行う。ソースドキュメントの任意の位置で、字句解析器はその位置で*有効な*トークンのみを認識しようとする。

1. **Earliest Starting Position** - Tree-sitterは、最初に開始された位置のトークンを優先する。これは、非常に許容的な正規表現（`/.*/`に類似）で最もよく見られ、貪欲で可能な限り多くのテキストを消費しようとする。この例では、正規表現は改行に達するまですべてのテキストを消費するが、その行のテキストが異なるトークンとして解釈できる場合でも、改行に達するまですべてのテキストを消費する。

1. **明示的な字句解析の優先度** - 上記で説明した優先度関数が`token`関数内で使用されると、与えられた優先度値は字句解析器に対する指示として機能する。文書内の特定の位置で文字にマッチする2つの有効なトークンがある場合、Tree-sitterはより高い優先度を持つトークンを選択する。

1. **最長一致** - もし複数の正当なトークンに同じ優先度で同じ場所でマッチした場合、Tree-sitterは最も長いものを選択する。

1. **Match Specificity** - もし同じ優先度で同じ数の文字にマッチする2つの有効なトークンがある場合、Tree-sitterは、`String`として指定されたトークンを`RegExp`として指定されたトークンよりも優先する。

1. **ルールの表記順序** - もし上記のいずれの基準も使用できない場合、Tree-sitterは文法内で先に現れるトークンを選択する。

### 字句解析の優先度と構文解析の優先度

よくある間違いの一つに、字句解析の優先度と構文解析の優先度を区別しないことがある。
構文解析の優先度は、与えられたトークンの列を解釈するために選択されるルールを決定する。
字句解析の優先度は、与えられたテキストのセクションを解釈するために選択されるトークンを決定する。
字句解析の優先度は、構文解析の優先度よりも低いレベルで行われる。
上記のリストは、Tree-sitterの字句解析の優先度ルールを完全に捉えており、
おそらく他のどのセクションよりも頻繁にこのセクションを参照することになるでしょう。
ほとんどの場合、本当に行き詰まると、字句解析の優先度の問題に直面していることになります。
`prec`が`token`関数の中で使用されるか、外側で使用されるかによって、意味が異なることに特に注意してください。

### キーワード

多くの言語では、一連の*キーワード*トークン（例：`if`、`for`、`return`）と、より一般的なトークン（例：`identifier`）があります。
このトークンは任意の単語にマッチし、キーワードにもマッチします。
例えば、JavaScriptには`instanceof`というキーワードがあり、次のように2項演算子として使用されます。

```js
if (a instanceof Something) b();
```

しかし、次のコードは有効なJavaScriptではありません。

```js
if (a instanceofSomething) b();
```

`instanceof`のようなキーワードは、たとえ識別子がその位置で有効でない場合でも、他の文字が直後に続いてはなりません。
Tree-sitterは、[上記](#conflicting-tokens)で説明したように、コンテキストに応じた字句解析を使用しているため、通常、この制限を課しません。
デフォルトでは、Tree-sitterは`instanceofSomething`を2つの別々のトークンとして認識します。
つまり`instanceof`キーワードの後に`identifier`が続くものと認識します。

### キーワード抽出

幸い、Tree-sitterには、他の標準パーサの動作に合わせるためにこれを修正する`word`トークンという機能がある。
もし`word`トークンを文法で指定すると、Tree-sitterは`word`トークンにもマッチする文字列にマッチする*キーワード*トークンの集合を見つける。
その後、字句解析中に、各キーワードを個別にマッチさせる代わりに、Tree-sitterは`word`トークンを*最初に*マッチさせる2段階のプロセスを使用してキーワードをマッチさせます。

例えば、JavaScriptの文法に`identifier`を`word`トークンとして追加したとします。

```js
grammar({
  name: 'javascript',

  word: $ => $.identifier,

  rules: {
    _expression: $ => choice(
      $.identifier,
      $.unary_expression,
      $.binary_expression
      // ...
    ),

    binary_expression: $ => choice(
      prec.left(1, seq($._expression, 'instanceof', $._expression)
      // ...
    ),

    unary_expression: $ => choice(
      prec.left(2, seq('typeof', $._expression))
      // ...
    ),

    identifier: $ => /[a-z_]+/
  }
});
```

Tree-sitterは、`typeof`と`instanceof`をキーワードとして識別します。
その後、上記の無効なコードを解析する際、`instanceof`トークンを個別にスキャンする代わりに、まず`identifier`をスキャンし、`instanceofSomething`を見つけます。
これにより、コードが無効であると正しく認識されます。

エラー検知に加えて、キーワード抽出にはパフォーマンスの利点もあります。
これにより、Tree-sitterはより小さく、シンプルな字句解析関数を生成できるため、**パーサのコンパイルがはるかに速くなります**。

### External Scanners

Many languages have some tokens whose structure is impossible or inconvenient to describe with a regular expression. Some examples:
* [Indent and dedent][indent-tokens] tokens in Python
* [Heredocs][heredoc] in Bash and Ruby
* [Percent strings][percent-string] in Ruby

Tree-sitter allows you to handle these kinds of tokens using *external scanners*. An external scanner is a set of C functions that you, the grammar author, can write by hand in order to add custom logic for recognizing certain tokens.

To use an external scanner, there are a few steps. First, add an `externals` section to your grammar. This section should list the names of all of your external tokens. These names can then be used elsewhere in your grammar.

```js
grammar({
  name: 'my_language',

  externals: $ => [
    $.indent,
    $.dedent,
    $.newline
  ],

  // ...
});
```

Then, add another C or C++ source file to your project. Currently, its path must be `src/scanner.c` or `src/scanner.cc` for the CLI to recognize it. Be sure to add this file to the `sources` section of your `binding.gyp` file so that it will be included when your project is compiled by Node.js and uncomment the appropriate block in your `bindings/rust/build.rs` file so that it will be included in your Rust crate.

In this new source file, define an [`enum`][enum] type containing the names of all of your external tokens. The ordering of this enum must match the order in your grammar's `externals` array; the actual names do not matter.

```c
#include <tree_sitter/parser.h>

enum TokenType {
  INDENT,
  DEDENT,
  NEWLINE
}
```

Finally, you must define five functions with specific names, based on your language's name and five actions: *create*, *destroy*, *serialize*, *deserialize*, and *scan*. These functions must all use [C linkage][c-linkage], so if you're writing the scanner in C++, you need to declare them with the `extern "C"` qualifier.

#### Create

```c
void * tree_sitter_my_language_external_scanner_create() {
  // ...
}
```

This function should create your scanner object. It will only be called once anytime your language is set on a parser. Often, you will want to allocate memory on the heap and return a pointer to it. If your external scanner doesn't need to maintain any state, it's ok to return `NULL`.


#### Destroy

```c
void tree_sitter_my_language_external_scanner_destroy(void *payload) {
  // ...
}
```

This function should free any memory used by your scanner. It is called once when a parser is deleted or assigned a different language. It receives as an argument the same pointer that was returned from the *create* function. If your *create* function didn't allocate any memory, this function can be a noop.

#### Serialize

```c
unsigned tree_sitter_my_language_external_scanner_serialize(
  void *payload,
  char *buffer
) {
  // ...
}
```

This function should copy the complete state of your scanner into a given byte buffer, and return the number of bytes written. The function is called every time the external scanner successfully recognizes a token. It receives a pointer to your scanner and a pointer to a buffer. The maximum number of bytes that you can write is given by the `TREE_SITTER_SERIALIZATION_BUFFER_SIZE` constant, defined in the `tree_sitter/parser.h` header file.

The data that this function writes will ultimately be stored in the syntax tree so that the scanner can be restored to the right state when handling edits or ambiguities. For your parser to work correctly, the `serialize` function must store its entire state, and `deserialize` must restore the entire state. For good performance, you should design your scanner so that its state can be serialized as quickly and compactly as possible.

#### Deserialize

```c
void tree_sitter_my_language_external_scanner_deserialize(
  void *payload,
  const char *buffer,
  unsigned length
) {
  // ...
}
```

This function should *restore* the state of your scanner based the bytes that were previously written by the `serialize` function. It is called with a pointer to your scanner, a pointer to the buffer of bytes, and the number of bytes that should be read.
It is good practice to explicitly erase your scanner state variables at the start of this function, before restoring their values from the byte buffer.

#### Scan

```c
bool tree_sitter_my_language_external_scanner_scan(
  void *payload,
  TSLexer *lexer,
  const bool *valid_symbols
) {
  // ...
}
```

This function is responsible for recognizing external tokens. It should return `true` if a token was recognized, and `false` otherwise. It is called with a "lexer" struct with the following fields:

* **`int32_t lookahead`** - The current next character in the input stream, represented as a 32-bit unicode code point.
* **`TSSymbol result_symbol`** - The symbol that was recognized. Your scan function should *assign* to this field one of the values from the `TokenType` enum, described above.
* **`void (*advance)(TSLexer *, bool skip)`** - A function for advancing to the next character. If you pass `true` for the second argument, the current character will be treated as whitespace; whitespace won't be included in the text range associated with tokens emitted by the external scanner.
* **`void (*mark_end)(TSLexer *)`** - A function for marking the end of the recognized token. This allows matching tokens that require multiple characters of lookahead. By default (if you don't call `mark_end`), any character that you moved past using the `advance` function will be included in the size of the token. But once you call `mark_end`, then any later calls to `advance` will *not* increase the size of the returned token. You can call `mark_end` multiple times to increase the size of the token.
* **`uint32_t (*get_column)(TSLexer *)`** - A function for querying the current column position of the lexer. It returns the number of codepoints since the start of the current line. The codepoint position is recalculated on every call to this function by reading from the start of the line.
* **`bool (*is_at_included_range_start)(const TSLexer *)`** - A function for checking whether the parser has just skipped some characters in the document. When parsing an embedded document using the `ts_parser_set_included_ranges` function (described in the [multi-language document section][multi-language-section]), your scanner may want to apply some special behavior when moving to a disjoint part of the document. For example, in [EJS documents][ejs], the JavaScript parser uses this function to enable inserting automatic semicolon tokens in between the code directives, delimited by `<%` and `%>`.
* **`bool (*eof)(const TSLexer *)`** - A function for determining whether the lexer is at the end of the file. The value of `lookahead` will be `0` at the end of a file, but this function should be used instead of checking for that value because the `0` or "NUL" value is also a valid character that could be present in the file being parsed.

The third argument to the `scan` function is an array of booleans that indicates which of your external tokens are currently expected by the parser. You should only look for a given token if it is valid according to this array. At the same time, you cannot backtrack, so you may need to combine certain pieces of logic.

```c
if (valid_symbols[INDENT] || valid_symbol[DEDENT]) {

  // ... logic that is common to both `INDENT` and `DEDENT`

  if (valid_symbols[INDENT]) {

    // ... logic that is specific to `INDENT`

    lexer->result_symbol = INDENT;
    return true;
  }
}
```

#### Other External Scanner Details

If a token in your `externals` array is valid at the current position in the parse, your external scanner will be called first before anything else is done.
This means your external scanner functions as a powerful override of tree-sitter's lexing behavior, and can be used to solve problems that can't be cracked with ordinary lexical, parse, or dynamic precedence.

If a syntax error is encountered during regular parsing, tree-sitter's first action during error recovery will be to call your external scanner's `scan` function with all tokens marked valid.
Your scanner should detect this case and handle it appropriately.
One simple method of detection is to add an unused token to the end of your `externals` array, for example `externals: $ => [$.token1, $.token2, $.error_sentinel]`, then check whether that token is marked valid to determine whether tree-sitter is in error correction mode.

If you put terminal keywords in your `externals` array, for example `externals: $ => ['if', 'then', 'else']`, then any time those terminals are present in your grammar they will be tokenized by your external scanner.
It is equivalent to writing `externals: [$.if_keyword, $.then_keyword, $.else_keyword]` then using `alias($.if_keyword, 'if')` in your grammar.

External scanners are a common cause of infinite loops.
Be very careful when emitting zero-width tokens from your external scanner, and if you consume characters in a loop be sure use the `eof` function to check whether you are at the end of the file.

[ambiguous-grammar]: https://en.wikipedia.org/wiki/Ambiguous_grammar
[antlr]: http://www.antlr.org/
[bison-dprec]: https://www.gnu.org/software/bison/manual/html_node/Generalized-LR-Parsing.html
[bison]: https://en.wikipedia.org/wiki/GNU_bison
[c-linkage]: https://en.cppreference.com/w/cpp/language/language_linkage
[cargo]: https://doc.rust-lang.org/cargo/getting-started/installation.html
[crate]: https://crates.io/crates/tree-sitter-cli
[cst]: https://en.wikipedia.org/wiki/Parse_tree
[dfa]: https://en.wikipedia.org/wiki/Deterministic_finite_automaton
[ebnf]: https://en.wikipedia.org/wiki/Extended_Backus%E2%80%93Naur_form
[ecmascript-spec]: https://262.ecma-international.org/6.0/
[ejs]: https://ejs.co
[enum]: https://en.wikipedia.org/wiki/Enumerated_type#C
[glr-parsing]: https://en.wikipedia.org/wiki/GLR_parser
[heredoc]: https://en.wikipedia.org/wiki/Here_document
[indent-tokens]: https://en.wikipedia.org/wiki/Off-side_rule
[language-spec]: https://en.wikipedia.org/wiki/Programming_language_specification
[lexing]: https://en.wikipedia.org/wiki/Lexical_analysis
[longest-match]: https://en.wikipedia.org/wiki/Maximal_munch
[lr-conflict]: https://en.wikipedia.org/wiki/LR_parser#Conflicts_in_the_constructed_tables
[lr-grammars]: https://en.wikipedia.org/wiki/LR_parser
[multi-language-section]: ./using-parsers#multi-language-documents
[named-vs-anonymous-nodes-section]: ./using-parsers#named-vs-anonymous-nodes
[field-names-section]: ./using-parsers#node-field-names
[nan]: https://github.com/nodejs/nan
[node-module]: https://www.npmjs.com/package/tree-sitter-cli
[node.js]: https://nodejs.org
[static-node-types]: ./using-parsers#static-node-types
[non-terminal]: https://en.wikipedia.org/wiki/Terminal_and_nonterminal_symbols
[npm]: https://docs.npmjs.com
[path-env]: https://en.wikipedia.org/wiki/PATH_(variable)
[peg]: https://en.wikipedia.org/wiki/Parsing_expression_grammar
[percent-string]: https://docs.ruby-lang.org/en/2.5.0/doc/syntax/literals_rdoc.html#label-Percent+Strings
[releases]: https://github.com/tree-sitter/tree-sitter/releases/latest
[s-exp]: https://en.wikipedia.org/wiki/S-expression
[syntax-highlighting]: ./syntax-highlighting
[syntax-highlighting-tests]: ./syntax-highlighting#unit-testing
[tree-sitter-cli]: https://github.com/tree-sitter/tree-sitter/tree/master/cli
[tree-sitter-javascript]: https://github.com/tree-sitter/tree-sitter-javascript
[yacc-prec]: https://docs.oracle.com/cd/E19504-01/802-5880/6i9k05dh3/index.html
[yacc]: https://en.wikipedia.org/wiki/Yacc

<!-- textlint-enable -->

[前のページ(パーサを使う)](./section-2-using-parsers.md) <---- [目次](../README.md) ----> [次のページ(シンタックスハイライター)](./section-4-syntax-highlighting.md)