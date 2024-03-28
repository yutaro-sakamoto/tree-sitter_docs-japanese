[前のページ(パーサを作る)](./section-3-creating-parsers.md) <---- [目次](../README.md) ----> [次のページ(Tree-sitterの実装)](./section-5-implementation.md)


# シンタックスハイライト

シンタックスハイライトはコードを扱うアプリケーションで使われることが多い機能である。
Tree-sitterはシンタックスハイライトをサポートする[`tree-sitter-highlight`](https://github.com/tree-sitter/tree-sitter/tree/master/highlight)
ライブラリをビルトインで提供する。
`tree-sitter-highlight`は現在、GitHub.comにおいて多くの言語のシンタックスハイライトで使用されている。
<!-- textlint-disable -->
コマンドラインから`tree-sitter highlight`コマンドを使うことで、シンタクスハイライト機能を実行できる。
<!-- textlint-enable -->

このページでは、CLIを使って、どのようにTree-sitterのシンタックスハイライト機能が動作するのかを解説する。
もし`tree-sitter-highlight`ライブラリ（CまたはRustから使用可能）を利用する場合、これらの考え方は有用であるが、設定データはファイルではなくメモリ上のオブジェクトである。

<!-- textlint-disable -->
**注意 - もしテキストエディタの[Atom](https://atom.io/)のシンタックスハイライトを開発する場合は、このドキュメントでなくAtom Flight Mantualの[このページ](https://flight-manual.atom.io/hacking-atom/sections/creating-a-grammar/)を参照せよ。**
<!-- textlint-enable -->
**Atomは現在Tree-sitterベースの別のシンタックスハイライトシステムを採用していいて、それはここで説明するよりも古いものである。**

<!-- textlint-disable -->

## 概要

通常、与えられた言語のハイライトに必要なファイルは、その言語のTree-sitterの文法と同じgitリポジトリに含まれている。
（例えば、[`tree-sitter-javascript`](https://github.com/tree-sitter/tree-sitter-javascript), [`tree-sitter-ruby`](https://github.com/tree-sitter/tree-sitter-ruby))
コマンドラインからシンタックスハイライトを実行するためには、次の3つが必要である。

1. `~/.config/tree-sitter/config.json`に記載されたユーザ固有の設定。
2. 文法リポジトリの`package.json`ファイルに記載された言語の設定。
3. 文法リポジトリの`queries`フォルダにある3つのクエリ。

言語固有のファイルの例については、`tree-sitter-ruby`リポジトリの[`package.json`ファイル](https://github.com/tree-sitter/tree-sitter-ruby/blob/master/package.json)と[`queries`ディレクトリ](https://github.com/tree-sitter/tree-sitter-ruby/tree/master/queries)を参照せよ。
以下のセクションでは、各ファイルの動作について説明する。

## ユーザ固有の設定

tree-sitterのCLIは自動的にホームフォルダに2つのディレクトリを作成する。
一方のディレクトリには、CLIの動作を規定するJSON形式の設定ファイルが格納される。
もう一方のディレクトリには、言語ごとのコンパイル済みのパーサが格納される。

これらのディレクトリは、各プラットフォームの「通常の」場所に作成される。

- Linuxでは、`~/.config/tree-sitter`と`~/.cache/tree-sitter`
- Macでは、`~/Library/Application Support/tree-sitter`と`~/Library/Caches/tree-sitter`
- Windowsでは、`C:\Users\[ユーザ名]\AppData\Roaming\tree-sitter` と `C:\Users\[ユーザ名]\AppData\Local\tree-sitter`

CLIは設定ファイルが存在しない場合、各設定オプションのデフォルト値を使用して動作する。
設定ファイルを作成し、編集するためには、次のコマンドを実行する。

```sh
tree-sitter init-config
```

(これにより、作成されたファイルの場所が表示されるため、簡単に見つけて編集できる。)

### パス

`tree-sitter highlight`コマンドは1つ以上のファイルパスを取り、それらのファイルをハイライトするためにどの言語を使用するかを自動的に決定しようとする。
これを行うためには、ファイルシステム上でTree-sitterの文法を探す場所を知る必要がある。
これは設定ファイルの`"parser-directories"`キーを使って制御できる。

```json
{
  "parser-directories": [
    "/Users/my-name/code",
    "/Users/my-name/other-code"
  ]
}
```

今のところ、これらの*parser-directories*のいずれかにある、名前が`tree-sitter-`で始まるフォルダは、Tree-sitterの文法リポジトリとして扱われる。

### テーマ

Tree-sitterのハイライトシステムは、`function.method`、`type.builtin`、`keyword`などの論理的な「ハイライト名」でソースコードの範囲を注釈付けすることで動作する。
各ハイライトのレンダリングに使用する色を決定するためには、*theme*が必要である。

```json
{
  "theme": {
    "function.method": "blue",
    "type.builtin": "green",
    "keyword": "purple"
  }
}
```

設定ファイルにおいて、`"theme"`の値は、`function.builtin`や`keyword`のようなドットで区切られたハイライト名であり、その値はテキストのスタイリングパラメータを表すJSONの式である。

#### ハイライト名

テーマは共通の部分文字列を持つ複数のキーを含むことができる。
例えば、

* `variable`,  `variable.parameter`
* `function`, `function.builtin`,  `function.method`

与えられたハイライトに対して、スタイリングに合致するテーマキーが複数存在する場合**最も長いテーマキー**が選択される。
例えば、`function.builtin.static`というハイライトは、`function`よりも`function.builtin`にマッチする。

#### スタイリング値

スタイリング値は以下のいずれかである。

* ASNIのターミナルカラーIDを表す0から255までの整数。
* `"#e45649"`のような16進RGBカラーを表す文字列。
* `"red"`, `"black"`, `"purple"`, `"cyan"`といったANSIカラーを表す文字列。
* 以下のキーを持つオブジェクト。
  * `color` - 整数または上記の文字列。
  * `underline` - テキストを下線にするかどうかを示すブール値。
  * `italic` - テキストを斜体にするかどうかを示すブール値。
  * `bold` - テキストを太字にするかどうかを示すブール値。

## 言語設定

`package.json`ファイルは`npm`のようなパッケージマネージャによって使用される。
このファイルでは、Tree-sitter CLIはトップレベルの`"tree-sitter"`キーの下にネストされたデータを探す。
このキーは、以下のキーを持つオブジェクトの配列を含むことが期待される。

### 基本

これらのキーはパーサに関する基本的な情報を指定する。

* `scope` (必須) - `"source.js"`のような言語を識別する文字列。現在我々は人気のある[TextMate grammars](https://macromates.com/manual/en/language_grammars)や[Linguist](https://github.com/github/linguist)で使用されるスコープ名に一致するよう努めている。

* `path` (任意) - `package.json`を含むディレクトリから、実際の生成されたパーサを含む`src/`フォルダへの相対パス。デフォルト値は`"."`（つまり`src/`は`package.json`と同じフォルダにある）であり、これを上書きする必要がある場合は非常に稀である。

### 言語の検出

These keys help to decide whether the language applies to a given file:
これらのキーは、与えられたファイルにどの言語を適用するかを決定するのに役立つ。

* `file-type` - ファイル名の接尾辞の配列。文法は、これらの接尾辞のいずれかで終わるファイルに使用される。接尾辞は*ファイル名全体*に一致する可能性があることに注意。
* `first-line-regex` - ファイルの最初の行に対してテストされる正規表現パターン。この言語がファイルに適用されるかどうかを決定するために使用される。この正規表現が指定されている場合、この正規表現は言語がいずれの文法の`file-types`にも一致しないファイルに使用される。
* `content-regex` - 上記の2つの基準を使用してファイルに複数の文法が一致した場合に、ファイルの内容に対してテストされる正規表現パターン。この正規表現に一致する場合、この文法は`content-regex`を持たない他の文法よりも優先される。正規表現が一致しない場合、`content-regex`を持たない文法がこの文法よりも優先される。

* `injection-regex` - この言語が潜在的な*言語インジェクション*サイトに使用されるかどうかを決定するために、*言語名*に対してテストされる正規表現パターン。言語インジェクションについては、[後のセクション](#言語インジェクション)で詳しく説明する。

### クエリパス

これらのキーは、`package.json`を含むディレクトリから、シンタックスハイライトを制御するファイルへの相対パスを指定する。

* `highlights` - *ハイライトクエリ*へのパス。デフォルト値は`queries/highlights.scm`である。
* `locals` - *ローカル変数クエリ*へのパス。デフォルト値は`queries/locals.scm`である。
* `injections` - *インジェクションクエリ*へのパス。デフォルト値は`queries/injections.scm`である。

これらの3つのファイルの動作については、次のセクションで説明する。

### 例

一般的に、`"tree-sitter"`配列は1つのオブジェクトだけを含めば十分で、そのオブジェクトにはいくつかのキーを指定するだけでよい。

```json
{
  "tree-sitter": [
    {
      "scope": "source.ruby",
      "file-types": [
        "rb",
        "gemspec",
        "Gemfile",
        "Rakefile"
      ],
      "first-line-regex": "#!.*\\bruby$"
    }
  ]
}
```

## クエリ

Tree-sitterのシンタックスハイライトの仕組みは、Tree-sitterの構文木にパターンマッチングする一般的なシステムである*tree queries*に基づいている。
tree queriesについての詳細は[このセクション](./using-parsers#pattern-matching-with-queries)を参照せよ。

Syntax highlighting is controlled by *three* different types of query files that are usually included in the `queries` folder. The default names for the query files use the `.scm` file. We chose this extension because it commonly used for files written in [Scheme](https://en.wikipedia.org/wiki/Scheme_%28programming_language%29), a popular dialect of Lisp, and these query files use a Lisp-like syntax.

シンタックスハイライトは、`queries`フォルダに格納される3種類のクエリファイルによって制御される。
デフォルトでは、クエリファイルの名前は`.scm`ファイルを使用する。
この拡張子を採用した理由は、クエリがLispの一般的な方言である[Scheme](https://ja.wikipedia.org/wiki/Scheme)に似た構文を使用しているためである。

また、`.scm`を「Source Code Matching」の略と考えることもできる。

### ハイライトクエリ

最も重要なクエリは、ハイライトクエリである。
ハイライトクエリは、異なるノードに任意の*ハイライト名*を割り当てるために*キャプチャ*を使用する。
各ハイライト名には、それぞれ色が割り当てられる（[上記](#theme)参照）。
一般的に使用されるハイライト名には、`keyword`、`function`、`type`、`property`、`string`などがある。
ハイライト名は、`function.builtin`のようにドットで区切ることもできる。

#### 例

例として、下記のGo言語のコードを考える。

```go
func increment(a int) int {
    return a + 1
}
```

構文木は下記の通りである。

```
(source_file
  (function_declaration
    name: (identifier)
    parameters: (parameter_list
      (parameter_declaration
        name: (identifier)
        type: (type_identifier)))
    result: (type_identifier)
    body: (block
      (return_statement
        (expression_list
          (binary_expression
            left: (identifier)
            right: (int_literal)))))))
```

#### クエリの例

下記の色でこのコードをレンダリングしたいとする。

* キーワード`func`と`return`は紫色
* 関数`increment`は青色
* 型`int`は緑色
* 数字`5`は茶色

下記のようなクエリを使用することで、それぞれのカテゴリに*ハイライト名*を割り当てることができる。

```
; highlights.scm

"func" @keyword
"return" @keyword
(type_identifier) @type
(int_literal) @number
(function_declaration name: (identifier) @function)
```

設定ファイルでは、これらのハイライト名を色にマッピングすることができる。

```json
{
  "theme": {
    "keyword": "purple",
    "function": "blue",
    "type": "green",
    "number": "brown"
  }
}
```

#### 結果

`tree-sitter highlight`をこのGoファイルで実行すると、次のような出力が得られる。

<pre class='highlight' style='border: 1px solid #aaa;'>
<span style='color: purple;'>func</span> <span style='color: #005fd7;'>increment</span>(<span>a</span> <span style='color: green;'>int</span>) <span style='color: green;'>int</span> {
    <span style='color: purple;'>return</span> <span>a</span> <span style='font-weight: bold;color: #4e4e4e;'>+</span> <span style='font-weight: bold;color: #875f00;'>1</span>
}
</pre>

### ローカル変数

優れたシンタックスハイライトは、コード内の異なる*エンティティ*を素早く区別できるようにする。
理想的には、特定のエンティティが*複数*の場所に現れる場合、それぞれの場所で同じ色で表示されるべきである。
Tree-sitterのシンタックスハイライトシステムは、ローカルスコープと変数を追跡することで、これを実現する。

The *local variables* query is different from the highlights query in that, while the highlights query uses *arbitrary* capture names which can then be mapped to colors, the locals variable query uses a fixed set of capture names, each of which has a special meaning.

*ローカル変数*クエリは、*任意の*キャプチャ名を使用しそれを色にマッピングするハイライトへクリと異なり、特別な意味を持つ固定されたキャプチャ名を使用する。

キャプチャ名は以下の通りである。

* `@local.scope` - シンタックスノードが新しいローカルスコープを導入することを示す。
* `@local.definition` - シンタックスノードが現在のローカルスコープ内の定義の*名前*を含むことを示す。
* `@local.reference` - シンタックスノードが、いくつかの包含スコープ内の以前の定義を参照する*名前*を含むことを示す。

ファイルをハイライトするとき、tree-sitterは与えられた位置を含むスコープの集合と、各スコープ内の定義の集合を追跡する。
`local.reference`としてキャプチャされた構文ノードを処理するとき、Tree-sitterはノードのテキストに一致する名前の定義を検索する。
一致するものが見つかった場合、Tree-sitterは*参照*と*定義*が同じ色で表示されるようにする。

このクエリによって生成された情報は、ハイライトクエリによっても*使用*される。
ローカル変数として識別されたノードに対して`(#is-not? local)`述語をパターンに追加することで、そのパターンを無効にすることができる。

#### 例

下記のRubyコードを考える。

```ruby
def process_list(list)
  context = current_context
  list.map do |item|
    process_item(item, context)
  end
end

item = 5
list = [item]
```

構文木は下記の通りである。

```
(program
  (method
    name: (identifier)
    parameters: (method_parameters
      (identifier))
    (assignment
      left: (identifier)
      right: (identifier))
    (method_call
      method: (call
        receiver: (identifier)
        method: (identifier))
      block: (do_block
        (block_parameters
          (identifier))
        (method_call
          method: (identifier)
          arguments: (argument_list
            (identifier)
            (identifier))))))
  (assignment
    left: (identifier)
    right: (integer))
  (assignment
    left: (identifier)
    right: (array
      (identifier))))
```

メソッドの中にはいくつかの異なる種類の名前がある。

* `process_list`はメソッドである。
* メソッド内で`list`は形式パラメータである。
* `context`はローカル変数である。
* `current_context`はローカル変数ではないので、メソッドである。
* doブロック内で、`item`は形式パラメータである。
* さらに、`item`と`list`はどちらもローカル変数である（形式パラメータではない）。


#### クエリの例

これらの名前の種類を明確に区別できるようにするために、いくつかのクエリを示す。
まず、前のセクションで説明したように、ハイライトクエリを設定する。
メソッド呼び出し、メソッド定義、形式パラメータに異なる色を割り当てる。

```
; highlights.scm

(call method: (identifier) @function.method)
(method_call method: (identifier) @function.method)

(method name: (identifier) @function.method)

(method_parameters (identifier) @variable.parameter)
(block_parameters (identifier) @variable.parameter)

((identifier) @function.method
 (#is-not? local))
```

その後、変数とスコープを追跡するためのローカル変数クエリを設定する。
ここでは、メソッドとブロックがローカル*スコープ*を作成し、パラメータと代入が*定義*を作成し、他の識別子は*参照*として扱われることを示している。

```
; locals.scm

(method) @local.scope
(do_block) @local.scope

(method_parameters (identifier) @local.definition)
(block_parameters (identifier) @local.definition)

(assignment left:(identifier) @local.definition)

(identifier) @local.reference
```

#### 結果

rubyファイルで`tree-sitter highlight`を実行すると、次のような出力が得られる。

<pre class='highlight' style='border: 1px solid #aaa;'>
<span style='color: purple;'>def</span> <span style='color: #005fd7;'>process_list</span><span style='color: #4e4e4e;'>(</span><span style='text-decoration: underline;'>list</span><span style='color: #4e4e4e;'>)</span>
  <span>context</span> <span style='font-weight: bold;color: #4e4e4e;'>=</span> <span style='color: #005fd7;'>current_context</span>
  <span style='text-decoration: underline;'>list</span><span style='color: #4e4e4e;'>.</span><span style='color: #005fd7;'>map</span> <span style='color: purple;'>do</span> |<span style='text-decoration: underline;'>item</span>|
    <span style='color: #005fd7;'>process_item</span>(<span style='text-decoration: underline;'>item</span><span style='color: #4e4e4e;'>,</span> <span>context</span><span style='color: #4e4e4e;'>)</span>
  <span style='color: purple;'>end</span>
<span style='color: purple;'>end</span>

<span>item</span> <span style='font-weight: bold;color: #4e4e4e;'>=</span> <span style='font-weight: bold;color: #875f00;'>5</span>
<span>list</span> <span style='font-weight: bold;color: #4e4e4e;'>=</span> [<span>item</span><span style='color: #4e4e4e;'>]</span>
</pre>

### 言語インジェクション

いくつかのソースファイルには、複数の異なる言語で書かれたコードが含まれている。例としては、

* HTMLファイルは、`<script>`タグ内にJavaScript、`<style>`タグ内にCSSを含めることができる。
* [ERB](https://en.wikipedia.org/wiki/ERuby)ファイルは、`<% %>`タグ内にRubyを含み、それ以外の部分にHTMLを含めることができる。
* PHPファイルは、`<php`タグ内にHTMLを含めることができる。
* JavaScriptファイルは、正規表現リテラル内に正規表現構文を含む。
* Rubyはヒアドキュメント内にコードスニペットを含むことができ、ヒアドキュメントの区切り文字にはそのコードスニペットの言語を示す語が使われる。

All of these examples can be modeled in terms of a *parent* syntax tree and one or more *injected* syntax trees, which reside *inside* of certain nodes in the parent tree. The language injection query allows you to specify these "injections" using the following captures:

* `@injection.content` - indicates that the captured node should have its contents re-parsed using another language.
* `@injection.language` - indicates that the captured node's text may contain the *name* of a language that should be used to re-parse the `@injection.content`.

The language injection behavior can also be configured by some properties associated with patterns:

* `injection.language` - can be used to hard-code the name of a specific language.
* `injection.combined` - indicates that *all* of the matching nodes in the tree should have their content parsed as *one* nested document.
* `injection.include-children` - indicates that the `@injection.content` node's *entire* text should be re-parsed, including the text of its child nodes. By default, child nodes' text will be *excluded* from the injected document.

#### Examples

Consider this ruby code:

```ruby
system <<-BASH.strip!
  abc --def | ghi > jkl
BASH
```

With this syntax tree:

```
(program
  (method_call
    method: (identifier)
    arguments: (argument_list
      (call
        receiver: (heredoc_beginning)
        method: (identifier))))
  (heredoc_body
    (heredoc_end)))
```

The following query would specify that the contents of the heredoc should be parsed using a language named "BASH" (because that is the text of the `heredoc_end` node):

```
(heredoc_body
  (heredoc_end) @injection.language) @injection.content
```

You can also force the language using the `#set!` predicate.
For example, this will force the language to be always `ruby`.

```
((heredoc_body) @injection.content
 (#set! injection.language "ruby"))
```

## Unit Testing

Tree-sitter has a built-in way to verify the results of syntax highlighting. The interface is based on [Sublime Text's system](https://www.sublimetext.com/docs/3/syntax.html#testing) for testing highlighting.

Tests are written as normal source code files that contain specially-formatted *comments* that make assertions about the surrounding syntax highlighting. These files are stored in the `test/highlight` directory in a grammar repository.

Here is an example of a syntax highlighting test for JavaScript:

```js
var abc = function(d) {
  // <- keyword
  //          ^ keyword
  //               ^ variable.parameter
  // ^ function

  if (a) {
  // <- keyword
  // ^ punctuation.bracket

    foo(`foo ${bar}`);
    // <- function
    //    ^ string
    //          ^ variable
  }
};
```

From the Sublime text docs:

> The two types of tests are:
>
> **Caret**: ^ this will test the following selector against the scope on the most recent non-test line. It will test it at the same column the ^ is in. Consecutive ^s will test each column against the selector.
>
> **Arrow**: <- this will test the following selector against the scope on the most recent non-test line. It will test it at the same column as the comment character is in.

<!-- textlint-enable -->

[前のページ(パーサを作る)](./section-3-creating-parsers.md) <---- [目次](../README.md) ----> [次のページ(Tree-sitterの実装)](./section-5-implementation.md)