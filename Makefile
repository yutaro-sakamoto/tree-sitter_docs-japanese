lint:
	npx textlint README.md docs

install-lint:
	npm install --save-dev \
	textlint \
	textlint-rule-preset-jtf-style \
	textlint-rule-ja-simple-user-dictionary \
	textlint-rule-max-ten \
	textlint-rule-no-mix-dearu-desumasu \
	textlint-rule-no-doubled-joshi \
	textlint-rule-no-double-negative-ja \
	textlint-rule-no-hankaku-kana \
	textlint-rule-ja-no-weak-phrase \
	textlint-rule-ja-no-redundant-expression \
	textlint-rule-ja-no-abusage \
	textlint-rule-no-mixed-zenkaku-and-hankaku-alphabet \
	textlint-rule-no-dropping-the-ra \
	textlint-rule-no-doubled-conjunctive-particle-ga \
	textlint-rule-no-doubled-conjunction \
	textlint-rule-ja-no-mixed-period \
	textlint-rule-ja-hiragana-hojodoushi \
	textlint-rule-ja-unnatural-alphabet \
	@textlint-ja/textlint-rule-no-insert-dropping-sa \
	textlint-rule-prefer-tari-tari \
	@textlint-ja/textlint-rule-no-synonyms \
	textlint-rule-ja-no-orthographic-variants \
	textlint-rule-use-si-units \
	textlint-rule-ja-joyo-or-jinmeiyo-kanji \
	textlint-rule-ja-no-inappropriate-words \
	@textlint-ja/textlint-rule-no-filler \
	textlint-filter-rule-comments \
	textlint-rule-preset-ja-technical-writing \
	textlint-rule-prh