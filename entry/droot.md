---
Title: "Dockerとchrootを組み合わせたシンプルなコンテナデプロイツール"
Category:
- Docker
- Linux
- Go
Date: 2015-12-01T09:00:00+09:00
URL: http://blog.yuuk.io/entry/droot
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/6653586347147020606
---

この記事は[はてなエンジニアアドベントカレンダー2015](http://developer.hatenastaff.com/entry/developers-advent-calendar-2015)の1日目です。今回は、既存の運用フローに乗せやすいDockerイメージへのchrootによるデプロイの考え方と自作のコンセプトツール [droot](https://github.com/yuuki/droot) を紹介します。

[https://github.com/yuuki/droot:embed:cite]

<!-- more -->

[:contents]

# 背景

[Docker](https://www.docker.com)がリリースされてから3年近く経過しました。
Web界隈において、確か初期には、テスト環境をすばやく作れて便利な高速に動くVagrantのようなものという扱いだったと思います。そこから、ローカルやCIで作成したコンテナをイメージ化し、本番環境までもっていけるというポータビリティの高さが注目されました。
とはいえ、実際にDockerコンテナを本番環境、特にアプリケーションサーバとして動作させるためには、いくつもの課題があります。
2年前はまだいつか本番に投入するぞぐらいの気持ちでした。当時のブログエントリの様子です。 

- [http://yuuki.hatenablog.com/entry/2013/12/22/174813:title:bookmark]
- [http://yuuki.hatenablog.com/entry/ii-conference01:title:bookmark]

しかし、Docker自体がリリースを重ねて機能が増えて、動作が安定してきた結果、本番環境での利用が現実的になってきているかもしれません。
実際に、本番環境に導入された事例もいくつか見聞きしています。

- [https://speakerdeck.com/spesnova/docker-meetup-tokyo-number-4-docker-at-wantedly:title:bookmark]
- [https://speakerdeck.com/ixixi/d-evelopment-and-deployment-with-docker-at-dwango:title:bookmark]
- [http://techlife.cookpad.com/entry/2015/04/20/134758:title:bookmark]
- [http://ameblo.jp/principia-ca/entry-12071871177.html:title:bookmark]

## Docker 本番導入の課題

変更があればコンテナを捨てて新しいコンテナを立ち上げるImmutable Infrastructure要素と、1度作成したホストを使いまわしていく既存の運用フローと、どうすり合わせるかがDocker導入の壁です。
少なくとも僕が課題だと認識しているもしくはしていたのは以下のようなものです。（他にもあった気がしますがとりあえず今思い出せる範囲で）

- ChefやAnsibleとの兼ね合い
- Dockerイメージの管理
- Dockerコンテナの監視
- コンテナのゴミ掃除
- Server::Starter動かないんでは問題
- ネットワークまわりのパフォーマンス劣化（[http://yuuki.hatenablog.com/entry/docker-performance-on-web-application:title:bookmark]）、docker 
- docker コンテナ内の問題調査の手間
- dockerコンテナ内のログの取り扱い
- docker pull が遅い
- storage driverがdevice mapperのとき、`docker build`と`docker run`がたまに失敗する問題
- dockerコンテナ内でたまに名前解決が失敗する

特に、本番に導入するということで、ゼロダウンタイムでのデプロイをどうするかが問題です。
よくみかける基本的なアイデアは、デプロイするたびに、Dockerコンテナを現在稼働中のコンテナとは別にもう１セット構築し、前段のロードバランサでそちらに切り替える（スタティックデプロイ）というものです。いわゆるBlue Green Deployment的な手法ですね。
その他は、より高度なクラスタマネージャやスケジューラを用いた手法があります。[http://www.infoq.com/jp/news/2015/06/twenty-minutes-production:title:bookmark]

## Docker 導入の目的

１つ１つの課題は手間をかけたりDocker自体が成熟すれば解決するかもしれませんが、これらを同時に相手するのは非常にやっかいだと感じていました。解決したとしても、解決のために作った仕組みの運用コストも増えます。
そもそもDockerを使って何がやりたかったのか、ポータビリティだとかコンテナを毎回捨ててクリーンな状態が保てるとかいろいろなDocker導入のメリットはありますが、なんとなくDockerが謳っているメリットを鵜呑みにして、それに振り回されているのではないか、本当に目の前の環境に導入して価値がでるのか、といったことを考えるようになりました。

そこで、どんなときにDockerが欲しかったかを振り返ると、Linuxディストリのパッケージ依存関係に苦しんでいるときだったり、アプリケーションエンジニアがほしいものをいれようとしたらインフラエンジニアにお願いしないといけないときだったと思います。
つまり、OSのユーザランド（`/usr/bin`とか`/usr/lib`とかもろもろのOSのシステムファイル群）を丸ごと固めてコンテナとして実行することで、ホスト側のパッケージと衝突しないことと、アプリケーションエンジニアが作ったイメージをそのまま本番で動かせることが重要だということがわかりました。

# Docker + chroot のアイデア

ここまでくると、Dockerでイメージを作るまではよいけど、本番サーバで無理してDockerを使わなくても、自分の用途に沿ったもっとシンプルなコンテナがあるのではないかと思いました。
最初は、rocketやsystemd-nspawnなどをみていましたが、どちらもそれなりに重たい印象でした。
もっとシンプルなコンテナ（的な）ツールとして、kazuhoさんの[jailing](http://blog.kazuhooku.com/2015/05/jailing-chroot-jail.html)や[virtuald](http://www.tldp.org/HOWTO/Virtual-Services-HOWTO-3.html)などがあります。
まぁつまり実体はchrootです。
chrootはDockerが利用しているLinuxコンテナとは当然別物です。Linuxコンテナを使えば様々なOSのリソースを分離することができます。ただ、別にホスティング事業をやっているわけでもないので、ホストの仮想化のためのプロセス分離もネットワーク分離も自分の用途にはいらないどころかかえって邪魔だということがわかってきました。

Docker + chrootのアイデアの核は非常に単純で以下のようなコマンドで表現できます。

```bash
$ docker pull mysql
$ export CONTAINER_ID=$(docker create mysql)
$ docker export $CONTAINER_ID -o mysql.tar
(mysql.tar をMySQLを動かしたいホストへコピーする。)

$ tar xvfz /var/containers/mysql/mysql.tar 
$ sudo chroot /var/containers/mysql mysqld
```

`docker export`により、コンテナのファイルシステムの`/`をtarで固めた状態のイメージ（厳密にはDockerイメージとは呼ばない気もしますが、以降ではこれをDockerイメージと呼ぶことにします。）を抽出し、リモートで展開して、展開先のディレクトリでchrootするだけです。
chroot 部分は`docker run`に相当します。

`docker run`に対する`chroot`のメリットはシンプルな分だけ「既存の運用フローに組み込みやすい」ことです。
例えば、PerlのデプロイにはServer::Starterのようなsupervisor型のホットデプロイツールがよく利用されますが、supervisor的なプロセスの下にアプリケーションのプロセスがぶら下がる形になるので、そもそもDockerのようなdockerデーモンプロセスに各コンテナがぶら下がる形とは相性が悪いと考えます。
chroot(1)は自分のファイルパスの探索ポイントを変更して、引数のコマンドをexecするだけなのでプロセスツリーを崩しません。
単にstart_serverへの引数にchrootコマンドを指定すればよいだけです。
daemontools/supervisorの利用も今までと同様のはずですし、ログは単にchroot先のディレクトリを見にいけばよいし、なによりデプロイ時にアプリケーションサーバの前段のロードバランサで新コンテナ群に振り分け先を切り替えるといった新しい仕組みの導入がいりません。

あとは`docker export`でとりだしたイメージをどのようにして管理し、本番に配布するかです。

Dockerとは直接関係ないですが、次世代デプロイ手法として、[Mamiya](https://speakerdeck.com/sorah/scalable-deployments-how-we-deploy-rails-app-to-150-plus-hosts-in-a-minute) や [Stretcher](http://tech.kayac.com/archive/10_stretcher.html) に代表されるようなアプリケーション成果物をイメージ化し、そのイメージをpull型でデプロイするという手法が昨年あたりから注目されています。（ここでいうイメージはDockerイメージのことではなく、Perlならソースコード+依存するCPANモジュール+静的ファイルなどをtar.gzに固めたものを指します）

これらのフローのうち、アプリケーション成果物をイメージ化する部分をDockerイメージに置き換えるのがよいと考えました。
つまり上記の`mysql.tar`（実際にはgzip化します）をCIなどでS3のようなストレージにアップして、本番サーバ上にConsulやCapistranoで配置し、アプリケーションの起動はchrootで行うというような流れです。

とはいえ、chrootするだけとはいっても、chrootするときはホスト側の`/sys`、`/dev`、`/etc/hosts`、`/etc/resolv.conf`などのシステムファイルをchroot環境から見えるようにしたいことも多いですし、chrootの実行にはroot権限が必要なので、rootのまま実行せずに[Linuxのcapabilities](http://man7.org/linux/man-pages/man7/capabilities.7.html)を調整するといった下ごしらえが必要です。
さらに、ちょっとしたイメージをデプロイするのに自分の手でS3にアップロードしたりS3からダウンロードするのもちょっと面倒だなと感じます。

# [droot](https://github.com/yuuki/droot): Dockerイメージにchrootするコンテナツール 

そこで、Dockerイメージとchrootによる一連のデプロイフローをサポートするためのツール [droot](https://github.com/yuuki/droot)を作りました。

drootの動作概要を次の図に示しています。

[f:id:y_uuki:20151129193210p:image]

`droot`はコマンドラインツールであり、`push`、`pull`、`run` の3つのサブコマンドが基本となります。
それぞれのサブコマンドの機能は、ちょうど`docker`コマンドのそれと近いイメージをもってもらうとよいかもしれません。

以下ではdroot の使い方と実装を紹介します。

## droot の使い方

### `droot push`: Dockerイメージをtar ball化しS3にpushする

```
$ docker pul yuuk1:perl:5.20.1
$ droot push --to s3://droot-examples/perl.tar.gz perl:5.20.1
```

perlのコンテナをDockerHubからもってきてpushしています。
`docker build`でビルドした自前のDockerイメージでももちろん動作します。

### `droot pull`: S3にpushしたイメージをダウンロードし展開する

Perlを動かしたいサーバ上で下記のコマンドを実行します。

```
$ droot pull --dest /var/containers/perl --src s3://droot-examples/perl.tar.gz
```

### `droot run`: 展開先のディレクトリにchrootする

```
$ droot run --root /var/containers/perl perl -v
```

これら一連のコマンドをすべて使う必要はありません。
他のデプロイツール、例えばstretcherと組み合わせるときは、`droot push`でS3にイメージをpushし、イメージの配布はstretcherにまかせてアプリケーション実行時に`droot run`を叩きます。

S3を使っていますが、今のところイメージファイルを1つ1つ素朴に管理しているだけです。
もう少しバージョニングのようなイメージを抽象管理できるような仕組みを持たせてもよいかもしれません。

その他、詳しくは[README](https://github.com/yuuki/droot/blob/master/README.md)を参照してください。
まだ環境によっては動作しないオプションなどがあるかもしれませんが、順次対応していきます。(DockerイメージのディストリがDebian 8の場合、setuid/setgid周りの問題で --user/--group オプションが動かない問題など)

## droot の実装

drootは各サーバに配る必要があるため、ワンバイナリを生成できるGo言語で実装しました。

### droot push/pull の実装

`droot push/pull`についてですが、それほど特別なことはしていません。docker exportやS3へのアップロード、gzip化などをUNIXパイプを用いてストリームとして扱い効率化したことと、[AWS SDKのGo実装がついにGeneral Releaseされた](http://aws.amazon.com/releasenotes/0851971756004824) のでそれを使ったぐらいです。

### droot run の実装

[jailing](https://github.com/kazuho/jailing)を参考したり真似したりしています。
jailingのREADMEにありますが、jailingがやっているのは基本的に以下のようなものだと認識しています。

- `/bin`、`/lib`、`/sbin`などのシステムディレクトリをjail環境から参照できるように、それらのディレクトリをchrootディレクトリ以下にbind mountする
- chroot ディレクトリ以下にmknodで `/dev/zero`、`/dev/random`などを作成
- `/etc/hosts`, `/etc/resolv.conf` などを chroot ディレクトリ以下にコピー
- root権限でchroot(2) したのち、root権限の一部だけ残して、権限を落とせるものはすべて落とす。([capabilities](http://man7.org/linux/man-pages/man7/capabilities.7.html) 

`droot run`の実装はこれに近いものになっていますが、違いは実装の違いというよりは目的の違いにあります。
chroot先のディレクトリはLinuxディストリが動作するために必要なファイル/ディレクトリ群が配置されている必要があります。それらのファイル群をホスト側のものを再利用することで、jailingは即座にjail環境を作成できます。
一方で、`droot run`はこれらのファイル/ディレクトリ一式はイメージ内に含まれて配布されている前提なので、`/bin`や`/lib`はホスト側のものを参照する必要はありません。
ただし、`/etc/resolv.conf`のような本番サーバとそれ以外で異なる設定にしたいファイルもあるので、本番サーバではホスト側の`/eyc/resolve.conf`を参照したいということもあります。そのようなファイルはオプションでコピーしたり、bind mountできるようにしています。

# あわせて読みたい

- [http://blog.nomadscafe.jp/2015/01/docker-so-reuseport-1.html:title:bookmark]
  - 最もおもしろいと思ったDocker本番導入の工夫です。
- [https://github.com/tcnksm/awesome-container:title:bookmark]
  - コンテナ技術一覧
- [http://lwn.net/Articles/531114/:title:bookmark]
- [https://speakerdeck.com/tenforward/kof-2015:title:bookmark]
- [http://runc.io/:title:bookmark]
- [http://blog.kazuhooku.com/2015/05/jailing-chroot-jail.html:title:bookmark]
  - chroot 周りの技術はjailingですべて学びました
- [http://www.tldp.org/HOWTO/Virtual-Services-HOWTO-3.html:title:bookmark]
  - chrootを使ったシンプルなコンテナ
- [http://blog.terminal.com/docker-without-containers-pulldocker/:title:bookmark]
  - drootに近いなにか
- [https://chimeracoder.github.io/docker-without-docker:title:bookmark]

# あとがき

Dockerのコンセプト「Build, Ship, Run」に立ち返り、dependency hellを解決するために、CIやstaging環境で動作した環境をイメージ化し、そのまま本番環境にもっていくリーズナブルなやり方を探していました。
結果として、「Build」のみDockerを使用し、Ship、Runは別のシンプルなツールに任せるという方法を自作ツールとともに提案しました。

近いうちに本番環境でのデプロイの具体的な様子を紹介したいと思います。

<blockquote class="twitter-tweet" lang="ja"><p lang="ja" dir="ltr">&quot;Dockerはもう古い これからはchroot&quot;という話をしました</p>&mdash; ゆううき (@y_uuk1) <a href="https://twitter.com/y_uuk1/status/614712907415162880">2015, 6月 27</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

はてなでは、地に足をつけて、モダンな技術も伝統的な技術も取り入れて、シンプルに課題を解決したいエンジニアを募集しています。

[http://hatenacorp.jp/recruit/career/operation-engineer:embed]
[http://hatenacorp.jp/recruit/career/application-engineer:embed]

はてなの2017年度 新卒採用サイトがオープンしました。
[http://developer.hatenastaff.com/entry/2015/12/01/120330:embed:cite]

kazuho さんから最高のコメント？いただきました。SIGHUP契機でディレクトリにイメージ展開もやるのかなるほど。

[https://twitter.com/kazuho/status/671489245895221248:embed#５年くらいまえに勉強会で話したことだけど、server-starter が SIGHUP 受け取ると pull 型のデプロイツールが起動して、そいつが新しいディレクトリにイメージを展開して、そこに chroot してアプリケーションが動き出すスタイルがオススメです]

[https://twitter.com/kazuho/status/671489766689341440:embed#まあ具体的な構成は他の形でもいいけど、chroot の「上」に server-starter を置くことで、「デプロイ時のファイルの置き換えを atomic にする」ことと「graceful restart」を両立することができるのです]
