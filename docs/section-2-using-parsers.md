[前のページ(トップページ)](./index.md) <---- [目次](../README.md) ----> [次のページ(パーサを作る)](./section-3-creating-parsers.md)

# パーサを使う

Tree-sitterのパーサ機能はすべてC言語のAPIから利用可能である。高級言語で書かれたアプリケーションは、[node-tree-sitter](https://github.com/tree-sitter/node-tree-sitter)や[tree-sitter rust crate](https://github.com/tree-sitter/tree-sitter/tree/master/lib/binding_rust)のようなバインディングライブラリを介してTree-sitterを利用できる。また、これらには独自のドキュメントが存在する。

この文書では、使用している言語に関係なく関連する、Tree-sitterの使用方法に関する一般的な概念について説明する。また、C言語APIを直接使用している場合や、異なる言語への新しいバインディングを構築している場合に役立つ、C言語固有の詳細についても説明する。

ここで紹介するAPI関数は、[`tree_sitter/api.h`](https://github.com/tree-sitter/tree-sitter/blob/master/lib/include/tree_sitter/api.h)で宣言され、文書化されている。また、C言語APIと密接に対応する[Rust APIドキュメント](https://docs.rs/tree-sitter/latest/tree_sitter/)を参照するとよい。

## はじめに

### ライブラリのビルド

POSIXシステム上でライブラリをビルドするには、Tree-sitterディレクトリで`make`を実行するだけである。これにより、動的ライブラリの他に、`libtree-sitter.a`という静的ライブラリが作成される。

また、大規模なプロジェクトのビルドシステムにこのライブラリを組み込むには、下記のソースファイルを追加する。このソースファイルをコンパイルするには、インクルードパスに下記の2つのディレクトリを追加する必要がある。

**ソースファイル:**

- `tree-sitter/lib/src/lib.c`

**インクルードディレクトリ:**

- `tree-sitter/lib/src`
- `tree-sitter/lib/include`

### 基本オブジェクト

Tree-sitterを使用する際には、言語・パーサ・構文木・構文ノードに対応する4種類のオブジェクトを利用する。C言語APIでは、これらを`TSLanguage`・`TSParser`・`TSTree`・`TSNode`として定義する。

- `TSLanguage`は、解析対象のプログラミング言語をどのようにパースするかを定義するオブジェクトである。各`TSLanguage`のコードは、Tree-sitterによって生成される。多くの言語は、[Tree-sitterのGitHub Organization](https://github.com/tree-sitter)の個別のGitリポジトリから利用可能である。新しい言語のパーサを作成するには[次のページ](./section-3-creating-parsers.md)を参照せよ。
- `TSParser`は、`TSLanguage`を割り当てられ、あるソースコードに基づいてTSTreeを生成するために使用できるステートフルなオブジェクトである。
- `TSTree`は、ソースコード全体の構文木を表す。この構文木は、ソースコードの構造を示す`TSNode`インスタンスを含む。またソースコードが変更時に、`TSTree`を編集することで新しい`TSTree`を生成できる。
- `TSNode`は、構文木に含まれるある1つのノードを表す。`TSNode`はソースコード内における開始位置・終了位置や親ノード・兄弟ノード・子ノードなどの他のノードとの関係に関する情報を保持する。


### サンプルプログラム

以下はTree-sitterの[JSONパーサ](https://github.com/tree-sitter/tree-sitter-json)を利用するC言語のサンプルプログラムである。

```c
// ファイル名 - test-json-parser.c

#include <assert.h>
#include <string.h>
#include <stdio.h>
#include <tree_sitter/api.h>

// `tree-sitter-json`ライブラリで実装された`tree_sitter_json`関数の宣言
TSLanguage *tree_sitter_json();

int main() {
  // パーサの作成
  TSParser *parser = ts_parser_new();

  // パーサの言語(この例ではJSON)を設定する
  ts_parser_set_language(parser, tree_sitter_json());

  // ソースコードを格納した文字列から構文木を作成する
  const char *source_code = "[1, null]";
  TSTree *tree = ts_parser_parse_string(
    parser,
    NULL,
    source_code,
    strlen(source_code)
  );

  // 構文木のルートノードを取得する
  TSNode root_node = ts_tree_root_node(tree);

  // 子ノードを取得をする
  TSNode array_node = ts_node_named_child(root_node, 0);
  TSNode number_node = ts_node_named_child(array_node, 0);

  // ノードが期待通りの型を持つかを検査する
  assert(strcmp(ts_node_type(root_node), "document") == 0);
  assert(strcmp(ts_node_type(array_node), "array") == 0);
  assert(strcmp(ts_node_type(number_node), "number") == 0);

  // ノードが期待通りの数の子ノードを持つかを検査する
  assert(ts_node_child_count(root_node) == 1);
  assert(ts_node_child_count(array_node) == 5);
  assert(ts_node_named_child_count(array_node) == 2);
  assert(ts_node_child_count(number_node) == 0);

  // 構文木をS式として出力する
  char *string = ts_node_string(root_node);
  printf("Syntax tree: %s\n", string);

  // ヒープメモリに確保したデータを解放する
  free(string);
  ts_tree_delete(tree);
  ts_parser_delete(parser);
  return 0;
}
```

このプログラムは`tree-sitter/api.h`で宣言されたC言語APIを利用しているため、`tree-sitter/lib/include`をインクルードパスに追加する必要がある。
また、`libtree-sitter.a` をバイナリにリンクする必要もある。
JSONのソースコードもバイナリに直接コンパイルしている。

```sh
clang                                   \
  -I tree-sitter/lib/include            \
  test-json-parser.c                    \
  tree-sitter-json/src/parser.c         \
  tree-sitter/libtree-sitter.a          \
  -o test-json-parser

./test-json-parser
```

## 構文解析の基礎

### ソースコードを引き渡す

上記の例では`ts_parser_parse_string`を使って、stringに格納されたソースコードをパースした。

```c
TSTree *ts_parser_parse_string(
  TSParser *self,
  const TSTree *old_tree,
  const char *string,
  uint32_t length
);
```

[piece table](https://en.wikipedia.org/wiki/Piece_table)や[rope](<https://en.wikipedia.org/wiki/Rope_(data_structure)>)等の独自のデータ構造に格納されたデータを構文解析したい場合は、`ts_parser_parse`関数を使用する。

```c
TSTree *ts_parser_parse(
  TSParser *self,
  const TSTree *old_tree,
  TSInput input
);
```

`TSInput`構造体を使うことで、与えられたバイトオフセットと行/列の位置でテキストのチャンクを読み取るための独自の関数を指定できる。この関数は、UTF-8またはUTF-16でエンコードされたテキストを返す。このインタフェースにより、独自のデータ構造に格納されたテキストを効率的に解析できる。

```c
typedef struct {
  void *payload;
  const char *(*read)(
    void *payload,
    uint32_t byte_offset,
    TSPoint position,
    uint32_t *bytes_read
  );
  TSInputEncoding encoding;
} TSInput;
```

### 構文ノード

Tree-sitterは構文木を検査するために、[DOM](https://ja.wikipedia.org/wiki/Document_Object_Model)に類似したインタフェースを提供する。構文ノードの型は、そのノードがどの文法規則を表しているかを示す文字列である。

```c
const char *ts_node_type(TSNode);
```

構文ノードは、ソースコード内の位置を先頭バイトからのオフセットと行／列の両方の形式で保持する。

```c
uint32_t ts_node_start_byte(TSNode);
uint32_t ts_node_end_byte(TSNode);

typedef struct {
  uint32_t row;
  uint32_t column;
} TSPoint;

TSPoint ts_node_start_point(TSNode);
TSPoint ts_node_end_point(TSNode);
```

### ノードの取得

すべての構文木はルートノードを持つ。

```c
TSNode ts_tree_root_node(const TSTree *);
```

任意のノードに対して、その子ノードにアクセスできる。

```c
uint32_t ts_node_child_count(TSNode);
TSNode ts_node_child(TSNode, uint32_t);
```

兄弟ノードや親ノードにもアクセスできる。

```c
TSNode ts_node_next_sibling(TSNode);
TSNode ts_node_prev_sibling(TSNode);
TSNode ts_node_parent(TSNode);
```

これらの関数はnullノードを返す場合がある。例えば、`ts_node_next_sibling`関数がnullノードを返した場合、次の兄弟ノードが存在しないことを示す。
与えられたノードがnullノードかを検査できる。

```c
bool ts_node_is_null(TSNode);
```

### 名前付きノードと匿名ノード

Tree-sitterは[具象構文木](https://ja.wikipedia.org/wiki/%E6%A7%8B%E6%96%87%E6%9C%A8)を生成する。具象構文木はコンマやカッコを含めたソースコードの全トークンの情報を保持する。[シンタックスハイライト](https://ja.wikipedia.org/wiki/%E3%82%B7%E3%83%B3%E3%82%BF%E3%83%83%E3%82%AF%E3%82%B9%E3%83%8F%E3%82%A4%E3%83%A9%E3%82%A4%E3%83%88)のように全トークンを処理する場合は、この機能は重要である。
しかし、使用用途によっては[抽象構文木](https://ja.wikipedia.org/wiki/%E6%8A%BD%E8%B1%A1%E6%A7%8B%E6%96%87%E6%9C%A8)を利用するほうが、解析が簡単である。抽象構文木とは具象構文木から重要度の低い情報を削除した木構造のデータである。
Tree-sitterの構文木は、_名前付きノード_ と _匿名ノード_ の2つのノードを使うことで両方の使用方法をサポートする。

下記のような文法定義を考える。

```js
if_statement: ($) => seq("if", "(", $._expression, ")", $._statement);
```

この言語における`if_statement`が表す構文木は、条件式・（条件式がtrueのときに実行すべき）文・`if`・`(`・`)`の5つの子ノードを持つ。
条件式（`$._expression`）と文（`$._statement`）は、文法定義の中で明示的に名前を与えられているため _名前付きノード_ である。
一方で`if`・`(`・`)`は、文法定義上は単なる文字列のため、名前付きノードではない（_匿名ノード_ である）。

与えられたノードが名前付きノードであるかを検査できる。

```c
bool ts_node_is_named(TSNode);
```

構文木を走査するときに、`_named_`を関数名に含む関数を使用することで、匿名ノードを読み飛ばせる。

```c
TSNode ts_node_named_child(TSNode, uint32_t);
uint32_t ts_node_named_child_count(TSNode);
TSNode ts_node_next_named_sibling(TSNode);
TSNode ts_node_prev_named_sibling(TSNode);
```

これらの関数を使用することで、構文木は抽象構文木のように扱える。

### ノードのフィールド名
<!-- textlint-disable -->
構文木の解析を容易にするために、多くの文法定義では一意な _フィールド名_ を一部の子ノードに付与する。
<!-- textlint-enable -->
フィールドが存在する場合、フィールド名を介して子ノードにアクセスできる。

```c
TSNode ts_node_child_by_field_name(
  TSNode self,
  const char *field_name,
  uint32_t field_name_length
);
```

フィールドは数値のIDも持っており、文字列の比較を繰り返したくない場合に利用できる。文字列とIDの変換には `TSLanguage` を使用できる。

```c
uint32_t ts_language_field_count(const TSLanguage *);
const char *ts_language_field_name_for_id(const TSLanguage *, TSFieldId);
TSFieldId ts_language_field_id_for_name(const TSLanguage *, const char *, uint32_t);
```

フィールドIDはフィールド名の代わりに使用できる。

```c
TSNode ts_node_child_by_field_id(TSNode, TSFieldId);
```

## 応用的な構文解析

### 編集

テキストエディタのようなアプリケーションでは、ソースコードが変更されたら再度ソースコードを構文解析する必要がある。Tree-sitterはこのようなユースケースにも対応できるように設計されている。まず最初に、構文木を編集し、ノードの範囲を調整し、ソースコードと同期させる必要がある。

```c
typedef struct {
  uint32_t start_byte;
  uint32_t old_end_byte;
  uint32_t new_end_byte;
  TSPoint start_point;
  TSPoint old_end_point;
  TSPoint new_end_point;
} TSInputEdit;

void ts_tree_edit(TSTree *, const TSInputEdit *);
```

そして、古い構文木を渡して再び `ts_parser_parse` を呼び出す。これは、内部的に古い構文木と構造を共有する新しい構文木を作成しする。

構文木を編集すると、そのノードの位置が変化する。`TSTree`の外側に`TSNode`インスタンスを保存している場合、キャッシュされた位置を更新するために、同じ`TSInput`値を使用して、それらの位置を個別に更新する必要がある。

```c
void ts_node_edit(TSNode *, const TSInputEdit *);
```

この`ts_node_edit`関数は、構文木を編集する前に`TSNode`インスタンスを取得しておき、構文木を編集した後もその特定のノードインスタンスを使用したい場合にのみ必要である。多くの場合、編集したツリーからノードを再取得したいだけのため、`ts_node_edit`関数は必要ない。

### 複数の言語を含む言語の構文解析
<!-- textlint-disable -->
1つのファイルに複数の言語が記載される場合がある。
<!-- textlint-enable -->
例えば[EJS](https://ejs.co/)や[ERB](https://ruby-doc.org/stdlib-2.5.1/libdoc/erb/rdoc/ERB.html)といったテンプレート言語では、JavascriptやRubyのような別の言語を混ぜて書くことでHTMLを生成する。

Tree-sitterは、ファイルの特定の範囲にあるテキストを基に構文木を作成することで、このような種類のドキュメントを扱う。

```c
typedef struct {
  TSPoint start_point;
  TSPoint end_point;
  uint32_t start_byte;
  uint32_t end_byte;
} TSRange;

void ts_parser_set_included_ranges(
  TSParser *self,
  const TSRange *ranges,
  uint32_t range_count
);
```

例えば、以下のようなERBドキュメントを考える。

```erb
<ul>
  <% people.each do |person| %>
    <li><%= person.name %></li>
  <% end %>
</ul>
```

概念的には、範囲が重複する3つの構文木（ERB構文木、Ruby構文木、HTML構文木）で表せる。
これらの構文木は次のようなコードによって生成できる。

```c
#include <string.h>
#include <tree_sitter/api.h>

// これらの関数は各リポジトリで実装されている
const TSLanguage *tree_sitter_embedded_template();
const TSLanguage *tree_sitter_html();
const TSLanguage *tree_sitter_ruby();

int main(int argc, const char **argv) {
  const char *text = argv[1];
  unsigned len = strlen(src);

  // テキスト全体をERBとして構文解析を実行する
  TSParser *parser = ts_parser_new();
  ts_parser_set_language(parser, tree_sitter_embedded_template());
  TSTree *erb_tree = ts_parser_parse_string(parser, NULL, text, len);
  TSNode erb_root_node = ts_tree_root_node(erb_tree);

  // ERB構文木において、HTMLを示す`content`ノードと挿入されたRubyを示す`code`ノードの範囲を見つける。
  TSRange html_ranges[10];
  TSRange ruby_ranges[10];
  unsigned html_range_count = 0;
  unsigned ruby_range_count = 0;
  unsigned child_count = ts_node_child_count(erb_root_node);

  for (unsigned i = 0; i < child_count; i++) {
    TSNode node = ts_node_child(erb_root_node, i);
    if (strcmp(ts_node_type(node), "content") == 0) {
      html_ranges[html_range_count++] = (TSRange) {
        ts_node_start_point(node),
        ts_node_end_point(node),
        ts_node_start_byte(node),
        ts_node_end_byte(node),
      };
    } else {
      TSNode code_node = ts_node_named_child(node, 0);
      ruby_ranges[ruby_range_count++] = (TSRange) {
        ts_node_start_point(code_node),
        ts_node_end_point(code_node),
        ts_node_start_byte(code_node),
        ts_node_end_byte(code_node),
      };
    }
  }

  // HTMLを解析するために、HTMLの範囲を指定する
  ts_parser_set_language(parser, tree_sitter_html());
  ts_parser_set_included_ranges(parser, html_ranges, html_range_count);
  TSTree *html_tree = ts_parser_parse_string(parser, NULL, text, len);
  TSNode html_root_node = ts_tree_root_node(html_tree);

  // Rubyを解析するために、Rubyの範囲を指定する
  ts_parser_set_language(parser, tree_sitter_ruby());
  ts_parser_set_included_ranges(parser, ruby_ranges, ruby_range_count);
  TSTree *ruby_tree = ts_parser_parse_string(parser, NULL, text, len);
  TSNode ruby_root_node = ts_tree_root_node(ruby_tree);

  // 3つの構文木すべてを出力する
  char *erb_sexp = ts_node_string(erb_root_node);
  char *html_sexp = ts_node_string(html_root_node);
  char *ruby_sexp = ts_node_string(ruby_root_node);
  printf("ERB: %s\n", erb_sexp);
  printf("HTML: %s\n", html_sexp);
  printf("Ruby: %s\n", ruby_sexp);
  return 0;
}
```

このAPIにより、言語をどのように構成するかについて、高い柔軟性を持つ。
Tree-sitterは言語間のインタラクションを媒介する責任はない。
その代わり、任意のアプリケーション固有のロジックを使って、自由にそれを行える。

### 並行性

Tree-sitterは構文木のコピーを非常に軽量に実装することで、マルチスレッド処理もサポートする。

```c
TSTree *ts_tree_copy(const TSTree *);
```

内部的には、構文木をコピーすると、原子参照カウント（原文：atomic reference count）が増加するだけである。概念的には、異なるスレッドで元の構文木を使用しながら、新しいスレッドで自由に問い合わせ、編集、解析、削除できる新しい構文木を提供するものである。
個々の`TSTree`インスタンスはスレッドセーフではないので、複数のスレッドで同時に使用したい場合は、構文木をコピーする必要があることに注意すること。

## 構文木に対するその他の操作

### カーソルを使った構文木の走査

[上記](#retrieving-nodes)の`TSNode` APIを使用して構文木のすべてのノードにアクセスできるが、多数のノードにアクセスする必要がある場合、カーソルを使用する方法が最も効率的である。
カーソルは、最大限の効率で構文木を走査することを可能にするステートフルなオブジェクトである。

任意のノードからカーソルの初期化を行える。

```c
TSTreeCursor ts_tree_cursor_new(TSNode);
```

カーソルを構文木の中で移動させられる。

```c
bool ts_tree_cursor_goto_first_child(TSTreeCursor *);
bool ts_tree_cursor_goto_next_sibling(TSTreeCursor *);
bool ts_tree_cursor_goto_parent(TSTreeCursor *);
```

これらの関数はカーソルの移動が成功した場合に`true`を返し、移動先のノードが存在しない場合は`false`を返す。

カーソルの現在のノードと、現在のノードに関連するフィールド名を常に取得できる。

```c
TSNode ts_tree_cursor_current_node(const TSTreeCursor *);
const char *ts_tree_cursor_current_field_name(const TSTreeCursor *);
TSFieldId ts_tree_cursor_current_field_id(const TSTreeCursor *);
```

## パターンマッチを使ったクエリ

コード解析の多くは、構文木からパターンを探し出す作業である。
Tree-sitterは、これらのパターンを表現し、マッチングを検索するための小さな宣言型言語を提供する。
この言語はTree-sitterの[ユニットテストシステム](./section-3-creating-parsers.md#command-test)のフォーマットと類似していする。

### クエリの文法

クエリは1つ以上のパターンから構成され、各パターンは構文木における特定のノードの集合にマッチする[S式](https://ja.wikipedia.org/wiki/S%E5%BC%8F)である。
与えられたノードにマッチする式は、ノードの型と、オプションでそのノードの子にマッチする一連のS式を含む2つの括弧で構成される。
たとえば、このパターンは、子ノードが両方とも`number_literal`ノードである`binary_expression`ノードにマッチする。

``` scheme
(binary_expression (number_literal) (number_literal))
```

子ノードは省略できる。
例えば、以下のクエリは`string_literal`の子ノードとして少なくとも1つ含むような`binary_expression`にマッチする。

``` scheme
(binary_expression (string_literal))
```

#### フィールド

一般に、子ノードに関連する[フィールド名](#node-field-names)を指定して、パターンをより具体的に指定するのがよい。
これは、子パターンの前にフィールド名を付け、その後にコロンを付けることで実現する。
例えば、下記のパターンは、フィールド名`object`の子ノード`call_expression`とフィールド名`left`の子ノード`member_expression`を持つ`assignment_expression`ノードにマッチする。

``` scheme
(assignment_expression
  left: (member_expression
    object: (call_expression)))
```

#### フィールド条件の反転

指定したフィールドを *持たない* ようなパターンを構成できる。
これを実現するには、フィールド名の直前に`!`を付与すれば良い。
例えば、下記のパターンは型パラメータを含まないクラス宣言にマッチする。

``` scheme
(class_declaration
  name: (identifier) @class_name
  !type_parameters)
```

#### 匿名ノード

ノードを記述するための括弧付きの構文は、[名前付きノード](#named-vs-anonymous-nodes)にのみ適用される。
特定の匿名ノードにマッチさせるには、その名前を""で囲んで記述する。
例えば、下記のパターンは演算子が`!=`で右辺が`null`であるような`binary_expression`にマッチする。

``` scheme
(binary_expression
  operator: "!="
  right: (null))
```

#### ノードをキャプチャする

パターンにマッチするノードを見つけたら、そのノードの中の特定のノードに対して処理を行う場合がある。
また、パターンマッチングを行う際、パターン内の特定のノードを処理したい場合もある。
キャプチャを使うと、パターン内の特定のノードに名前を割り当てることができ、後でその名前でノードを参照できる。
キャプチャの名前は、参照するノードの後に書かれ、`@`文字で始まる。

たとえば、下記のパターンは識別子への関数の割り当てにマッチし、関数名`the-function-name`という名前を識別子に割り当てる。

``` scheme
(assignment_expression
  left: (identifier) @the-function-name
  right: (function))
```

下記のパターンはメソッド定義にマッチし、`the-method-name`をメソッド名に割り当て、`the-class-name`をクラス名に割り当てる。

``` scheme
(class_declaration
  name: (identifier) @the-class-name
  body: (class_body
    (method_definition
      name: (property_identifier) @the-method-name)))
```

#### 量化演算子

後置修飾子`+`および`*`繰り返し演算子は、[正規表現](https://ja.wikipedia.org/wiki/%E6%AD%A3%E8%A6%8F%E8%A1%A8%E7%8F%BE#%E5%9F%BA%E6%9C%AC%E7%9A%84%E3%81%AA%E6%A6%82%E5%BF%B5)における`+`および`*`演算子と同様に機能する。
演算子はパターンの1回以上の繰り返しにマッチし、*演算子は0回以上の繰り返しにマッチする。

例えば、下記のパターンは、1つ以上のコメントの並びにマッチする。

``` scheme
(comment)+
```

下記のパターンはクラス宣言にマッチし、デコレータがあればすべてキャプチャする。

``` scheme
(class_declaration
  (decorator)* @the-decorator
  name: (identifier) @the-name)
```

また、`?`演算子を使うと、ノードをオプションとしてマークする。
例えば、このパターンはすべての関数呼び出しにマッチし、文字列引数が存在する場合はそれをキャプチャする。

``` scheme
(call_expression
  function: (identifier) @the-function
  arguments: (arguments (string)? @the-string-arg))
```

#### グループ化

カッコを使うことでノードの並びを1つのグループにできる。
例えば、下記のパターンはコメントと関数宣言の並びにマッチする。

``` scheme
(
  (comment)
  (function_declaration)
)
```

`+`・`*`・`?`といった量化演算子をグループ内で利用できる。
例えば、このパターンはコンマ区切りの数字の並びにマッチする。

``` scheme
(
  (number)
  ("," (number))*
)
```

#### 選言

`[]`により選言を記述できる。
これは正規表現における _文字クラス_ に類似する。（`[abc]`はa,b,cのいずれかにマッチする）

例えばこのパターンは、変数またはオブジェクトのプロパティのいずれかの呼び出すにマッチする。
変数にマッチする場合は、`@function`としてキャプチャし、プロパティの場合は`@method`としてキャプチャする。

``` scheme
(call_expression
  function: [
    (identifier) @function
    (member_expression
      property: (property_identifier) @method)
  ])
```

下記のパターンはキーワードにマッチし、`@keyword`としてキャプチャする。

``` scheme
[
  "break"
  "delete"
  "else"
  "for"
  "function"
  "if"
  "return"
  "try"
  "while"
] @keyword
```

#### ワイルドカード

`_`はワイルドカードであり、任意のノードにマッチする。
これは正規表現の`.`に類似する。
`(_)`は任意の名前付きノードにマッチし、`_`は任意の名前付きノードと匿名ノードのいずれにもマッチする。

例えば、下記はcall内の任意のノードにマッチする。

``` scheme
(call (_) @call.inner)
```

#### アンカー

アンカー演算子 `.` は、子パターンのマッチング方法を制限するために使われる。
`.`はクエリ内の位置によって動作が変わる。

`.`がパターン内の先頭の子ノードより前に位置する場合、そのノードは親ノードの先頭の名前付き子ノードにのみマッチする。
例えば、下記のパターンは`array` ノードにマッチし、 `@the-element`キャプチャを親 `array` の最初の`identifier`ノードに代入しする。

``` scheme
(array . (identifier) @the-element)
```

このアンカーがないとき、上記のパターンは`array`の各`identifier`にマッチし、それぞれのマッチは`@the-element`としてキャプチャされる。
同様に、`.`がパターン内の最後尾の子ノードより後ろに位置する場合、そのノードは親ノードの最後尾の名前付き子ノードにのみマッチする。
下記のパターンは`block`内の最後の名前付き子ノードにのみマッチする例である。

``` scheme
(block (_) @last-expression .)
```
最後に、2つの子パターンの間にアンカーを置くと、パターンが直接の兄弟関係にあるノードにのみマッチする。
下記のパターンは、`a.b.c.d`のような長いドット付きの名前が与えられた場合、連続した識別子である `a, b`, `b, c`, `c, d` の組にのみマッチする例である。

``` scheme
(dotted_name
  (identifier) @prev-id
  .
  (identifier) @next-id)
```

アンカーがない場合、`a, c`や`b, d`といった組み合わせにもマッチする。

アンカー演算子がパターンに加える制限は、匿名ノードを無視する。

#### 述語

パターン内の任意の場所に _述語_ S式を追加することによって、パターンに関連する任意のメタデータや条件を指定できる。
述語S式は`#述語名`で始まるS式である。
`#述語名`の後、任意の数の `@` を接頭辞に持つキャプチャ名や文字列を記述して良い。

例えば、下記のパターンは[`SCREAMING_SNAKE_CASE`](https://en.wikipedia.org/?title=SCREAMING_SNAKE_CASE&redirect=no)の識別子にマッチする。

``` scheme
(
  (identifier) @constant
  (#match? @constant "^[A-Z][A-Z_]+")
)
```

下記のパターンはキーと値が同じkey-valueのペアにマッチする。

``` scheme
(
  (pair
    key: (property_identifier) @key-name
    value: (identifier) @value-name)
  (#eq? @key-name @value-name)
)
```
_注意_ - 述語はTree-sitter Cライブラリでは直接扱えない。上位のコードがフィルタリングを実行できるように、構造化された形で公開されるだけである。しかし、[Rustクレート](https://github.com/tree-sitter/tree-sitter/tree/master/lib/binding_rust)や[WebAssemblyバインディング](https://github.com/tree-sitter/tree-sitter/tree/master/lib/binding_web)のようなTree-sitterの上位バインディングでは、`#eq?`や`#match?`のようないくつかの共通の述語を実装している。

### クエリAPI

1つ以上のパターンを含む文字列をクエリとして作成する。

```c
TSQuery *ts_query_new(
  const TSLanguage *language,
  const char *source,
  uint32_t source_len,
  uint32_t *error_offset,
  TSQueryError *error_type
);
```

クエリにエラーがある場合は、`error_offset` 引数にエラーのバイトオフセットを設定し、`error_type` 引数にエラーの種類を示す値を設定する。

```c
typedef enum {
  TSQueryErrorNone = 0,
  TSQueryErrorSyntax,
  TSQueryErrorNodeType,
  TSQueryErrorField,
  TSQueryErrorCapture,
} TSQueryError;
```

`TSQuery`の値は不変であるため、スレッド間で安全に共有できる。
クエリを実行するには、クエリ処理のための状態を保持する`TSQueryCursor`を作成する。
クエリカーソルはスレッド間で共有すべきでないが、クエリの繰り返し実行のために再利用できる。

```c
TSQueryCursor *ts_query_cursor_new(void);
```

構文木のノードを指定してクエリを実行できる。

```c
void ts_query_cursor_exec(TSQueryCursor *, const TSQuery *, TSNode);
```

そのマッチを繰り返し処理できる。

```c
typedef struct {
  TSNode node;
  uint32_t index;
} TSQueryCapture;

typedef struct {
  uint32_t id;
  uint16_t pattern_index;
  uint16_t capture_count;
  const TSQueryCapture *captures;
} TSQueryMatch;

bool ts_query_cursor_next_match(TSQueryCursor *, TSQueryMatch *match);
```

この関数はマッチが存在しない場合は`false`を返す。そうでない場合は、どのパターンにマッチし、どのノードがキャプチャされたかという情報を `match` に格納する。

## 静的なノードの型
<!-- textlint-disable -->
静的型付けを行う言語では、構文木が個々の構文ノードに関する特定の型情報を提供することが有益な場合がある。
<!-- textlint-enable -->
Tree-sitterでは、この情報を `node-types.json` という生成されたファイルを通して利用できるようにする。この _ノード型ファイル_ は、文法中のすべての可能な構文ノードに関する構造化されたデータを提供する。

このデータを使って、静的型付けされたプログラミング言語の型宣言を生成できる。
例えば、GitHubの[Semantic](https://github.com/github/semantic)はこれらのノード型ファイルを使って、可能なすべての構文ノードに対して[Haskellデータ型を生成](https://github.com/github/semantic/tree/main/semantic-ast)し、コード解析アルゴリズムがHaskell型システムによって構造的に検証されることを可能にしている。

ノード型ファイルにはオブジェクトの配列が含まれており、各オブジェクトは以下の項目を使用して特定の型の構文ノードを記述する。

#### 基本情報

この配列中の各オブジェクトは下記の2つのエントリを持つ。

- `"type"` - どの文法規則を表すかを示す文字列。これは[前述](#syntax-nodes)の`ts_node_type`関数に相当する。
- `"named"` - この種のノードが、文法中のルール名に対応するか、それとも単なる文字列リテラルに対応するかを示すブール値。詳細は[ここ](#named-vs-anonymous-nodes)を参照すること。

<!-- textlint-disable -->
例
<!-- textlint-enable -->

```json
{
  "type": "string_literal",
  "named": true
}
{
  "type": "+",
  "named": false
}
```

これら2つのフィールドは、合わせてノードタイプの一意な識別子を構成する。
`node-types.json` 内の2つのトップレベルオブジェクトは、 `"type"`と`"named"`の両方が同じ値であるべきではない。

#### 内部ノード

多くの構文ノードは子ノードを持つ。
ノードの型オブジェクトは、ノードが持つことのできる子ノードを以下の項目で記述する。

- `"fields"` - ノードが持つことのできる[フィールド](#node-field-names)を記述したオブジェクト。このオブジェクトのキーはフィールド名で、値は以下に説明する子ノードの型オブジェクトである。
- `"children"` - フィールドを持たない、ノードの可能な名前の付いた子ノードをすべて記述した、子ノードの型オブジェクト。

子ノードの型オブジェクトは、以下の項目を使用して子ノードの集合を記述する。

- `"required"` - この集合に少なくとも1つのノードが常に存在するかどうかを示す真偽値。
- `"multiple"` - この集合に複数のノードが存在できるかどうかを示す真偽値。
- `"types"`- この集合に含まれるノードの可能なタイプを表すオブジェクトの配列。各オブジェクトは2つのキーを持つ。
その意味は前述した通りである。

<!-- textlint-disable -->
例
<!-- textlint-enable -->

```json
{
  "type": "method_definition",
  "named": true,
  "fields": {
    "body": {
      "multiple": false,
      "required": true,
      "types": [{ "type": "statement_block", "named": true }]
    },
    "decorator": {
      "multiple": true,
      "required": false,
      "types": [{ "type": "decorator", "named": true }]
    },
    "name": {
      "multiple": false,
      "required": true,
      "types": [
        { "type": "computed_property_name", "named": true },
        { "type": "property_identifier", "named": true }
      ]
    },
    "parameters": {
      "multiple": false,
      "required": true,
      "types": [{ "type": "formal_parameters", "named": true }]
    }
  }
}
```

<!-- textlint-disable -->
例
<!-- textlint-enable -->

```json
{
  "type": "array",
  "named": true,
  "fields": {},
  "children": {
    "multiple": true,
    "required": false,
    "types": [
      { "type": "_expression", "named": true },
      { "type": "spread_element", "named": true }
    ]
  }
}
```

#### スーパータイプ・ノード

Tree-sitterの文法では、通常、構文ノードの抽象的なカテゴリを表す特定のルールがある（例えば、「式」、「型」、「宣言」等）。
`grammar.js`では、これらのルールは[隠しルール](./section-3-creating-parsers#hiding-rules)として記述され、
その定義は各メンバーが1つのシンボルである単純な[選択](./section-3-creating-parsers#the-grammar-dsl)である場合が多い。

通常、隠れルールは構文ツリーには現れないので、ノードタイプファイルには記述されない。
しかし、文法の[スーパータイプのリスト](./section-3-creating-parsers#the-grammar-dsl)に隠しルールを追加すると、ノード型ファイルに次のような特別な項目とともに表示されるようになる。

- `"subtypes"` - この 'supertype' ノードがラップできるノードの型を指定するオブジェクトの配列。

<!-- textlint-disable -->
例
<!-- textlint-enable -->

```json
{
  "type": "_declaration",
  "named": true,
  "subtypes": [
    { "type": "class_declaration", "named": true },
    { "type": "function_declaration", "named": true },
    { "type": "generator_function_declaration", "named": true },
    { "type": "lexical_declaration", "named": true },
    { "type": "variable_declaration", "named": true }
  ]
}
```

スーパータイプ・ノードは、ノードタイプ・ファイル内の他の場所でも、文法でスーパータイプ・ルールがどのように使われたかに対応する形で、他のノードタイプの子として表示される。これは、1つのスーパータイプが複数のサブタイプの代わりとなるため、ノードタイプをより短く、読みやすくできる。

<!-- textlint-disable -->
例
<!-- textlint-enable -->

```json
{
  "type": "export_statement",
  "named": true,
  "fields": {
    "declaration": {
      "multiple": false,
      "required": false,
      "types": [{ "type": "_declaration", "named": true }]
    },
    "source": {
      "multiple": false,
      "required": false,
      "types": [{ "type": "string", "named": true }]
    }
  }
}
```

[前のページ(トップページ)](./index.md) <---- [目次](../README.md) ----> [次のページ(パーサを作る)](./section-3-creating-parsers.md)
