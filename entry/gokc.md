---
Title: "Keepalivedのシンタックスチェッカ「gokc」を作った"
Category:
- Go
- Keepalived
Date: 2016-02-01T09:12:00+09:00
URL: http://blog.yuuk.io/entry/gokc
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/6653586347155456400
---

[Keepalived](http://keepalived.org/)のシンタックスチェッカ「[gokc](https://github.com/yuuki/gokc)」をGo言語で書きました。

[https://github.com/yuuki/gokc:embed:cite]

執筆時点でのKeepalived最新版であるバージョン1.2.19まで対応していることと、`include`文に対応していることがポイントです。

# 使い方

https://github.com/yuuki/gokc/releases からバイナリをダウンロードします。OSXでHomebrewを使っていれば、

```shell
$ brew tap yuuki/gokc
$ brew install gokc
```

でインストールできます。

gokcコマンドを提供しており、`-f` オプションで設定ファイルのパスを指定するだけです。

```shell
gokc -f /path/to/keepalived.conf
gokc: the configuration file /etc/keepalived/keepalived.conf syntax is ok
```

シンタックスエラーのある設定ファイルを読み込むと、以下のようなエラーで怒られて、exit code 1で終了します。

```shell
gokc -f /path/to/invalid_keepalived.conf
./keepalived/doc/samples/keepalived.conf.track_interface:7:14: syntax error: unexpected STRING
```

# なぜ作ったか

Keepalivedは[IPVS](http://www.linuxvirtualserver.org/software/ipvs.html)によるロードバランシングと、[VRRP](https://tools.ietf.org/html/rfc3768)による冗長化を実現するためのソフトウェアです。
KeepalivedはWeb業界で10年前から使われており、はてなでは定番のソフトウェアです。
社内の多くのシステムで導入されており、今なお現役で活躍しています。

KeepalivedはNginxやHAProxy同様に、独自の構文を用いた設定ファイルをもちます。


* しかし、Keepalived本体は構文チェックをうまくやってくれず、誤った構文で設定をreloadさせると、正常に動作しなくなることがありました。

そのため、これまでHaskellで書かれた [kc](https://github.com/maoe/kc) というツールを使って、シンタックスチェックしていました。
initスクリプトのreloadで、kcによるシンタックスチェックに失敗するとreloadは即中断されるようになっています。

ところが、Haskellを書けるメンバーがいないので、メンテナンスができず、Keepalivedの新機能に対応できていないという問題がありました。
（Haskell自体がこのようなものを書くのに向いているとは理解しているつもりです。）
さらに、kcについてはビルドを成功させるのが難しいというのもありました。[http://maoe.hatenadiary.jp/entry/20090928/1254159495:title]

さすがに、Keepalivedの新しい機能を使うためだけに、Haskellを学ぶモチベーションがわかなかったので、Go言語とyaccで新規にgokcを作りました。
Go言語はインフラエンジニアにとって馴染みやすい言語だと思っています。
yaccは構文解析の伝統的なツールなので、情報系の大学で習っていたりすることもあります（僕は習わなかったけど、概念は習った）。

ちなみに、C言語+flex+yacc版のシンタックスチェッカである ftp://ftp.artech.se/pub/keepalived/ というものがあります。
新しい構文には対応しているのですが、include未対応だったり、動いてない部分が結構あるので、参考にしつつも一から作りました。

# 実装

シンタックスのチェックだけであれば、コンパイラのフェーズのうち、字句解析と簡単な構文解析だけで済みました。
「簡単な」と言ったのは、構文解析フェーズで、抽象構文木を作らなくて済んだということです。

一般に字句解析器は、自分で書くか、Flexのような字句解析器の自動生成ツールを使います。
後者の実装として、自分の知る限り、Go言語には[golex](https://github.com/cznic/golex)、[nex](https://github.com/blynn/nex) があります。

ただし、`include`文のような字句解析をそこそこ複雑にする構文があるため、柔軟に書けたほうがよかろうということで自分で書くことにしました。
といっても、スキャナ部分はGo言語自体のスキャナである[text/scanner](https://golang.org/pkg/text/scanner/)を流用しました。
Go言語用のスキャナですが、多少カスタマイズできる柔軟性があるので、ユーザ定義の言語の字句解析器として利用できます。
[http://www.oki-osk.jp/esc/golang/calc.html:title] を参照。

構文解析にはパーサジェネレータであるyaccを使いました。
yaccのGo版は標準で[go tool yacc](https://golang.org/cmd/yacc/)があります。
goyaccについて詳しくは、[http://qiita.com/k0kubun/items/1b641dfd186fe46feb65:title]を参照してください。

多少面倒だったのは`include`文の対応です。
include対応とはつまり、字句解析器において、別の設定ファイルを開いて、また元の設定ファイルに戻るというコンテキストの切り替えをしつつ、トークンを呼び出し元の構文解析器に返すことが求められます。

字句解析器から構文解析器へトークンを渡す構造をどうするかが問題でした。
逐次的にトークンを構文解析器へ返すのを諦めて、一旦末尾まで字句解析した結果をメモリにすべてのせて、構文解析器から順に読ませるみたいなこともできました。

それでもよかったんですが、Rob Pikeの [http://cuddle.googlecode.com/hg/talk/lex.html#title-slide:title] の資料に、goroutineとchannelを利用して、字句解析器を作る方法が書かれており、この手法を部分的に真似てみました。

具体的には、字句解析を行うgoroutineと、構文解析を行うgoroutine（メインのgo routine）が2つがあり、字句解析goroutineが構文解析goroutineにemitetr channelを通じて、トークンを受け渡すという構造にして解決しました。
channelをキューとして扱うようなイメージです。

`include`文のもつ複雑さに対して、そこそこシンプルに書けたような気はしています。

# 参考

- [http://cuddle.googlecode.com/hg/talk/lex.html#landing-slide:title:bookmark]
- [http://www.oki-osk.jp/esc/golang/lisp.html:title:bookmark]
- [http://www.oki-osk.jp/esc/golang/calc.html:title:bookmark]
- [http://blog.zoncoen.net/blog/2015/12/22/cli-toml-processor-with-goyacc/:title:bookmark]
- [https://blog.gopheracademy.com/advent-2014/parsers-lexers/:title:bookmark]
- [http://qiita.com/k0kubun/items/1b641dfd186fe46feb65:title:bookmark]
- [http://qiita.com/draftcode/items/c9f2422fca14133c7f6a:title:bookmark]
