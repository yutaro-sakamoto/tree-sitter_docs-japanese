lint:
	npx textlint README.md docs

lint-fix:
	npx textlint --fix README.md docs

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
	textlint-rule-prh \
	textlint-rule-preset-japanese \
	textlint-rule-no-nfd \
	@textlint-ja/textlint-rule-no-dropping-i \
	@textlint-ja/textlint-rule-no-insert-re \
	@textlint-ja/textlint-rule-no-insert-dropping-sa \
	textlint-rule-ja-no-successive-word \
	textlint-rule-no-duplicated-bunmatsu-hyougen \
	textlint-rule-no-dead-link \
	textlint-rule-no-empty-section \
	textlint-rule-no-empty-element \
	textlint-rule-date-weekday-mismatch \
	textlint-rule-terminology \
	@textlint-rule/textlint-rule-no-invalid-control-character \
	@textlint-rule/textlint-rule-no-unmatched-pair \
	textlint-rule-footnote-order \
	textlint-rule-no-zero-width-spaces \
	textlint-rule-doubled-spaces \
	@textlint-rule/textlint-rule-no-duplicate-abbr
