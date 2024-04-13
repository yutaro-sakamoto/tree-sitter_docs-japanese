<!-- textlint-disable -->
[前のページ(Playground)](./section-7-playground.md) <---- [目次](../README.md)


# コードナビゲーションシステム

Tree-sitterは、コードナビゲーションシステムの一部として、
[tree query language](https://tree-sitter.github.io/tree-sitter/using-parsers#pattern-matching-with-queries)を使用できます。
そのようなシステムの例として、`tree-sitter tags`コマンドがあります。
このコマンドは、ファイル引数内の特定の構文ノードをテキスト形式で出力します。
この機能の利用例として、GitHubの[search-based code navigation](https://docs.github.com/en/repositories/working-with-files/using-files/navigating-code-on-github#precise-and-search-based-navigation)があります。
このドキュメントは、このようなシステムとの統合方法、およびTree-sitterの文法を持つ任意の言語にこの機能を拡張する方法について説明します。

## タグ付けとキャプチャ

タグ付けとは、プログラムで名前を付けられるエンティティを特定することです。
Tree-sitterのクエリを使用してこれらのエンティティを見つけたら、構文キャプチャを使用してエンティティとその名前をラベル付けします。

特定のタグ付けの本質は、一致したエンティティの_役割_（つまり、定義か参照か）と、そのエンティティの_種類_の2つのデータです。
種類は、エンティティがどのように使用されるかを説明します（クラス定義、関数呼び出し、変数参照など）。
慣習的に、`@role.kind`キャプチャ名形式に続く構文キャプチャを使用し、常に`@name`と呼ばれる別の内部キャプチャを使用して、特定の識別子の名前を取り出します。

オプションで、docstringを紐づけるに`@doc`という名前のキャプチャを含めることができます。
便宜上、タグ付けシステムは、コメント構文をdocstringから削除するのに便利な2つの組み込み関数、
`#select-adjacent!`と`#strip!`を提供します。
`#strip!`は、最初の引数としてキャプチャを取り、2番目に引数として正規表現を取り、クォートされた文字列として表現します。
正規表現に一致するテキストパターンは、渡されたキャプチャに関連付けられたテキストから削除されます。
`#select-adjacent!`は、2つのキャプチャ名を渡すと、最初のキャプチャに関連付けられたテキストをフィルタリングし、2番目のキャプチャに隣接するノードのみを保持します。
これは、一致したコメントに含まれる情報が多すぎる場合に便利です。

## Examples

This [query](https://github.com/tree-sitter/tree-sitter-python/blob/78c4e9b6b2f08e1be23b541ffced47b15e2972ad/queries/tags.scm#L4-L5) recognizes Python function definitions and captures their declared name. The `function_definition` syntax node is defined in the [Python Tree-sitter grammar](https://github.com/tree-sitter/tree-sitter-python/blob/78c4e9b6b2f08e1be23b541ffced47b15e2972ad/grammar.js#L354).

``` scheme
(function_definition
  name: (identifier) @name) @definition.function
```

A more sophisticated query can be found in the [JavaScript Tree-sitter repository](https://github.com/tree-sitter/tree-sitter-javascript/blob/fdeb68ac8d2bd5a78b943528bb68ceda3aade2eb/queries/tags.scm#L63-L70):

``` scheme
(assignment_expression
  left: [
    (identifier) @name
    (member_expression
      property: (property_identifier) @name)
  ]
  right: [(arrow_function) (function)]
) @definition.function
```

An even more sophisticated query is in the [Ruby Tree-sitter repository](https://github.com/tree-sitter/tree-sitter-ruby/blob/1ebfdb288842dae5a9233e2509a135949023dd82/queries/tags.scm#L24-L43), which uses built-in functions to strip the Ruby comment character (`#`) from the docstrings associated with a class or singleton-class declaration, then selects only the docstrings adjacent to the node matched as `@definition.class`.

``` scheme
(
  (comment)* @doc
  .
  [
    (class
      name: [
        (constant) @name
        (scope_resolution
          name: (_) @name)
      ]) @definition.class
    (singleton_class
      value: [
        (constant) @name
        (scope_resolution
          name: (_) @name)
      ]) @definition.class
  ]
  (#strip! @doc "^#\\s*")
  (#select-adjacent! @doc @definition.class)
)
```

The below table describes a standard vocabulary for kinds and roles during the tagging process. New applications may extend (or only recognize a subset of) these capture names, but it is desirable to standardize on the names below.

| Category                 | Tag                         |
|--------------------------|-----------------------------|
| Class definitions        | `@definition.class`         |
| Function definitions     | `@definition.function`      |
| Interface definitions    | `@definition.interface`     |
| Method definitions       | `@definition.method`        |
| Module definitions       | `@definition.module`        |
| Function/method calls    | `@reference.call`           |
| Class reference          | `@reference.class`          |
| Interface implementation | `@reference.implementation` |

## Command-line invocation

You can use the `tree-sitter tags` command to test out a tags query file, passing as arguments one or more files to tag. We can run this tool from within the Tree-sitter Ruby repository, over code in a file called `test.rb`:

``` ruby
module Foo
  class Bar
    # won't be included

    # is adjacent, will be
    def baz
    end
  end
end
```

Invoking `tree-sitter tags test.rb` produces the following console output, representing matched entities' name, role, location, first line, and docstring:

```
    test.rb
        Foo              | module       def (0, 7) - (0, 10) `module Foo`
        Bar              | class        def (1, 8) - (1, 11) `class Bar`
        baz              | method       def (2, 8) - (2, 11) `def baz`  "is adjacent, will be"
```

It is expected that tag queries for a given language are located at `queries/tags.scm` in that language's repository.

## Unit Testing

Tags queries may be tested with `tree-sitter test`. Files under `test/tags/` are checked using the same comment system as [highlights queries](https://tree-sitter.github.io/tree-sitter/syntax-highlighting#unit-testing). For example, the above Ruby tags can be tested with these comments:

```ruby
module Foo
  #     ^ definition.module
  class Bar
    #    ^ definition.class

    def baz
      #  ^ definition.method
    end
  end
end
```

[前のページ(Playground)](./section-7-playground.md) <---- [目次](../README.md)
<!-- textlint-enable -->