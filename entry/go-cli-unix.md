---
Title: "Go言語によるCLIツール開発とUNIX哲学について"
Category:
- Go
- UNIX
- Mackerel
Date: 2014-12-08T08:30:00+09:00
URL: http://blog.yuuk.io/entry/go-cli-unix
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/8454420450076430034
---

この記事は[はてなエンジニアアドベントカレンダー2014](http://developer.hatenastaff.com/entry/2014/12/01/164046)の8日目です。

今回は、Go言語でサーバ管理ツール Mackerel のコマンドラインツール[`mkr`](https://github.com/mackerelio/mkr) を作るときに調べたこと、考えたこと、やったことについて紹介します。（`mkr` は現時点では開発版での提供になります。）

# コマンドラインツールについて

コマンドラインツールを作るにあたって、[twitter:@deeeet] さんの YAPC Asia 2014 での発表資料が非常に参考になります。
書籍 [http://www.amazon.co.jp//dp/4274064069:title=UNIXという考え方ーその思想と哲学] の内容をベースに、コマンドラインツールはどうあるべきかということが丁寧に説明されています。

<!-- more -->

<script async class="speakerdeck-embed" data-id="be2e75b011500132bed77eaf0ae1314a" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>

上記資料から引用させていただくと、コマンドラインツールにおいて重要なポイントは以下の7つであるとされています。

>
1. 1つのことに集中している
1. 直感的に使える
1. 他のツールと連携できる
1. 利用を助けてくれる
1. 適切なデフォルト値を持ち設定もできる
1. 苦痛なくインストールできる
1. すぐに改修できる

また、「いかに"良い"CLIツールを作り始めるか？」について、以下の4つの手順が示されています。

>
1. どんなツールを作るか考える
1. 言語を選ぶ
1. README.mdを書く
1. 高速にプロトタイプを作る

さらに、同じく[twitter:@deeeet] さんのエントリ [http://deeeet.com/writing/2014/08/27/cli-reference/:title:bookmark] も参考になります。

# Go言語におけるコマンドラインツール

Go言語は依存のないバイナリ生成とクロスコンパイルができるので、"苦痛なくインストールできる"という点で、コマンドラインツールを書くことに向いていると思います。
Goで書くとRubyなどと比べて基本的には動作が高速なため、Heroku や GitHub のコマンドラインツールがGoで書きなおされているというのも注目すべきポイントです。
`hk` は使ってないのでわかりませんが、`hub` は体感でもはっきりわかるほど動作が高速になりました。

- [https://github.com/heroku/hk:title]
- [https://github.com/github/hub:title]
- [https://github.com/jingweno/gh:title]
- [https://github.com/motemen/ghq:title]
- [https://github.com/tcnksm/dmux:title]
- [https://github.com/walter-cd/walter:title]

余談ですが、Heroku ではGoでコマンドラインツールを書く仕事を募集していたようです。 [http://www.golangprojects.com/golang-go-job-gz-Command-Line-Interface-Developer-remote-work-possible-San-Francisco-Heroku.html:title]

Go でコマンドラインツールを作る上で、コマンドラインツールのインタフェース部分の実装を助けてくれる[`cli`](https://github.com/codegangsta/cli) というライブラリが非常に便利です。
これを使うとサブコマンドをもつインタフェースや、ヘルプ機能などを簡単に作ることができます。（Ruby でいうとこるの thor のライブラリ部分に近いかも）
使い方は motemen さんの [ghq](https://github.com/motemen/ghq) や `cli` の作者の[Goのコード](https://github.com/search?l=Go&p=2&q=user%3Acodegangsta+&ref=searchresults&type=Repositories&utf8=%E2%9C%93)をみるとよいと思います。


またコマンドラインツールとは関係ないですが、Go でのよいコードの書き方について、先日のGoConの資料が参考になります。
[http://ukai-go-talks.appspot.com/2014/gocon.slide#1:title:bookmark]

Go については、以前便利リンク集をまとめました。
[http://yuuki.hatenablog.com/entry/go-links:title:bookmark]

# `mkr` 

`mkr` は、サーバ管理ツール [Mackerel](https://mackerel.io) の [REST API](http://help-ja.mackerel.io/entry/spec/api/v0) を利用したコマンドラインツールです。

Mackerel のような管理ツール系のサービスは、ある操作を一括で行いたいなどの柔軟な操作性を求められますが、それをWebUIで表現することが難しいこともあると思います。
そんなときに、APIによる一括操作などができると、操作が自動化しやすいので一石二鳥といえます。
特にサーバ管理ツールの場合、他のツールのAPIなどの出力をサーバ管理ツールに反映したり、逆にサーバ管理ツールのAPIの出力を他のツールに渡したいなどの要求はよくあると思います。

例えば、Mackerel API と tssh を組み合わせて複数ホストに同時にログインするなどの応用があります。[http://yuuki.hatenablog.com/entry/tmux-ssh-mackerel:title:bookmark]

サーバ管理ツールとAPIについては、昨年のYAPCで発表した資料が参考になるかもしれません。

[https://speakerdeck.com/yuukit/hatenafalsesabaguan-li-turufalsehua:title:bookmark]


`mkr` は各種APIの操作とコマンドが対応しており、APIの入出力とコマンドラインでの入出力のパイプとしてだけ機能するように意識しています。
"1つのことに集中する"ことができるように、出力のフィルタリング/加工機能などは最小限の実装にしています。
代わりに、APIの出力を余分な情報を多少除いてそのままJSONで出力するようにして、`jq`で自在にフィルタリング/加工すれば"他のツールと連携できる"ことがしやすいと考えました。

例えば、特定ロールのホスト群のIPアドレス一覧を出力したいときには mkr の hosts サブコマンドに service と role オプションを付けて、jq で eth0 のみをフィルターします。

```bash
$ mkr hosts --service Mackerel --role proxy | jq -r -M ".[].ipAddresses.eth0"
```

同等のフィルタリングを `mkr` 側もしくはAPI側で実装しようと思うとかなり大変で、実装したとしても表現力が汎用フィルターの `jq` に劣る可能性が高いため、あらゆるツールと組み合わせるというわけにはいかなくなるかもしれません。

他のサービスのAPIと組み合わせとして例えば、EC2 と Mackerel 連携があります。
`mkr retire <hostIds>` と `aws-cli` の [descrive-instances](http://docs.aws.amazon.com/cli/latest/reference/ec2/describe-instances.html)を組み合わせると、EC2上で Terminated になったインスタンスリストを `mkr retire`コマンドに渡せば、一括で退役処理ができます。

さらに、`mackerel-agent-plugins` と `mkr throw`を組み合わせると、Sensu 形式のプラグインの出力をホストメトリックやサービスメトリックに投げ込めます。
cron で定期投稿させることで、mackerel-agentがなくてもメトリック投稿ができます。
ELB や RDS など、特定のインスタンスに紐付かないメトリックはこれを使うと楽かもしれません。

```bash
$ /usr/local/bin/mackerel-plugin-aws-elb | mkr throw --service <hostId>
```

## mkr と Go

`mkr` を Go で実装した最大の理由は、mackerel-agent がインストールされたホスト上で、`mkr status` とうつとログインするホストの情報を簡単にみたり、ステータスを変更できるようにしたいというものです。
mackerel-agent が動作していれば、`/etc/mackerel-agent/mackerel-agent.conf` や `/var/lib/mackerel-agent/id` にAPIキーやホストIDが書かれています。
指定がなければこれらを読むようにすることで、入力を省略できるようにします。
各ホストにインストールされている必要があるので、配布の簡単な Go で実装するのが適当だと思いました。

## mkr 作成手順

下記の手順で作りました。

1. インタフェースを決める
1. READMEを書く
1. go 版のAPIライブラリがなかったので作る [https://github.com/mackerelio/mackerel-client-go]
1. ひな形を作る https://github.com/tcnksm/cli-init [http://deeeet.com/writing/2014/06/22/cli-init/:title:bookmark]
1. [`ghq`](https://github.com/motemen/ghq) を参考に実装。とにかく参考になる。
1. `go vet`, `golint` を通す
1. CI環境を整える (TravisCI)
1. リリースフローを整える (goxc, travisci)
1. Dockerfile を書いて、DockerHub で Automated Build [https://registry.hub.docker.com/u/mackerel/mkr/]
1. Homebrew Formulaを書く [https://github.com/y-uuki/homebrew-mkr] (これも motemen さんの [https://github.com/motemen/homebrew-ghq] をそのまま）



### インタフェース

`mkr` はインタフェースにこだわって作っています。
例えば、Ruby のCLIツールのインタフェースは https://github.com/mackerelio/mackerel-client-ruby#cli のようになっていますが、コマンド名 + リソース名 + 動詞 となっており、REST をそのまま表現しやすいですが、タイプ数が多くなってしまうという欠点があります。
(一応サブサブコマンド的なものも`cli`ライブラリで実装できるようです。）

そこで、`mkr` はコマンド名 + 動詞で表現するようにして、タイプ数が短くなるようにしています。
代わりに操作したいリソースの表現力が落ちますが、実際には"service"(リソース)を"create"(動詞)するなどの操作は通常コマンドラインからは行いません。
このようにWebUIで十分事足りる操作については、コマンドラインでは表現しないもしくはタイプ数をあまり気にしないインタフェースにしています。
頻繁にコマンドラインで操作したいと思うのは"host"であるため、基本的には"host"(リソース)に対する操作を動詞としています。

また、APIでは異なるエンドポイントとして設計されていても、ユーザの直感では1コマンドとして表現されていたいと思うものもあります。
例えば[API](http://help-ja.mackerel.io/entry/spec/api/v0)では、ホスト情報の更新とホストのステータスの更新が分かれていますが、どちらもホスト情報の更新であるため、`mkr` では update コマンドにまとめてあります。

### リリースフロー

今は [GitHub の releases](https://github.com/mackerelio/mkr/releases)にアップロードすることをリリースとしています。
"苦痛なくインストールできる"ことを考えると、yumリポジトリやaptリポジトリ、Homebrewで提供することを考えたほうがよりよいとは思います。

CI環境と合わせて GitHub の releases へのアップロードは TravisCI, CircleCI、wercker を使うと便利です。

[http://docs.travis-ci.com/user/deployment/releases/:title]

さらに、複数環境の同時クロスコンパイルには [`gox`](https://github.com/mitchellh/gox) または [`goxc`](https://github.com/laher/goxc)が便利です。
toolchain の細かい validation や Zip や tar.gz へのアーカイブ、バージョニングなどができる点から `goxc` を使ってみました。
このあたりは、[Makefile](https://github.com/mackerelio/mkr/blob/master/Makefile)や[travis.yml](https://github.com/mackerelio/mkr/blob/master/.travis.yml)を参照してください。

### Dockerfile

モダン感を出すために、とりあえず置いておくとよいでしょう。
2行で済みます。(ビルドに make を使えなかったりするので、ちゃんとやろうとすると onbuild image 使わずにやるけどとりあえず動く)

```
FROM golang:1.3.3-onbuild
ENTRYPOINT ["/go/bin/app"]
```

Go でないツールで docker さえ入っていればコマンド一発でインストールできるので、Ruby や Python のコマンドラインツールでは有用かもしれません。

# まとめ

UNIX哲学最高。Go最高。


[asin:4274064069:detail]

次回は id:hatz48 さんです。よろしくお願いします！

はてなでは、Perlだけでなく、Scala, Goのエンジニア、さらに自社開発のツールでサーバ管理がしたいWebオペレーションエンジニアも募集しております。

<div style="border: 1px solid #DED6CF; padding: 10px; margin-top: 20px;">
株式会社はてなではインターネットで生活を楽しく豊かにしたいスタッフを募集しています<br>
<a href="http://hatenacorp.jp/recruit/" target="_blank">採用情報 - 株式会社はてな</a>
</div>
