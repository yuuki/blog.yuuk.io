---
Title: "Perlはもう古い、これからはDocker"
Category:
- docker
- perl
Date: 2014-12-19T08:30:00+09:00
URL: http://blog.yuuk.io/entry/next-is-docker
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/8454420450077455616
---

本記事の内容はWEB+DB Vol.88 Perl Hackers Hub 第34回 に「DockerによるPerlのWebアプリケーション開発」という記事にまとめなおしていますのでそちらをご覧ください。
[https://twitter.com/wdpress/status/634890753521508352:embed]


この記事は [Perl Advent Calendar 2014](http://qiita.com/advent-calendar/2014/perl) の19日目の記事です。
Plack/Carton で構築したモダンな Perl の Web アプリケーションの開発環境を Docker 化するための試行錯誤を紹介します。

普段は、Plack, Router::Simple, Text::Xslate, DBIx::Sunnyなどを組み合わせたフレームワークでアプリケーションを書く/運用することが多いですが、今回はサンプルとして Amon2 を使いました。
サンプルは GitHub に置いています。
[https://github.com/y-uuki/dockerized-perl-app:embed]

<!-- more -->

# Perl アプリケーションを Docker 化するメリット

まず、なぜ Docker 化するかについてですが、Perl にかぎらずアプリケーションが巨大であればあるほど環境構築と環境運用がどんどんめんどうになっていくからです。
だいたいいつも困っている例として以下の様なものがあります。

- 開発環境ではスーパーバイザなどでデーモン化せずに、フォアグランドで起動しているが、本番環境では daemontools 用のスクリプトで起動している。
- 各環境で何かのバージョンが違う。
- 開発環境では `carton install` できるけど、CI 環境では失敗する。
- 開発環境ではテスト通るけど、CI 環境ではテストが落ちる。
- ImageMagick や RRDtool みたいなそもそもビルドが面倒なソフトウェアに依存している。 [http://techlife.cookpad.com/entry/ffmpeg_and_imagemagick_setup_with_docker:title:bookmark]
- 開発環境では、`carton exec` を使ってるけど、本番環境では `carton exec` を使っていない。
- `cpanfile.snapthot` が気づいたら壊れている（`carton install --deployment` が失敗する)。
- マイクロサービスのローカル環境構築が面倒。

これについて、Docker 化することにより、次のようなメリットがあります。

- 各環境でバージョンの統一が簡単（バージョンというか実行環境そのものを統一）
- 各環境の構築を `docker pull` してくるだけで終わらせられる。
- CI 環境や本番環境を手元で簡単に再現できる。

一方で、デメリットも当然あります。

- Docker デーモン自体の運用をしなければならない
- docker コマンドによるオペレーション、バッドノウハウを覚えなければならない
- デバッグが面倒になることもある (環境の差異によるバグのデバッグは逆にやりやすいかもしれない

他にも、例えば Docker は手元とリモート環境で Dockerfile のビルドの成否が変わったりはします。
これは、一度作成した Docker image の動作のポータビリティはある程度保証されているが、Docker image の作成自体のポータビリティは一切保証されていないためです。
ビルド環境がインターネットに出られる環境でなければ、apt-get なんて当然絶対失敗しますよね。
したがって、Dockerfile ではなく、Docker image をなるべく使いまわしていくことが必要です。

Docker、気づいたらデメリットがメリットを上回っているなんてこともあると思うのでうまくメリットがでる用途や手法を確立していきたいですね。

# Perl アプリケーションの Docker 化パターン

1年くらい Docker をやりつづけた知見を書きます。要点を以下に列挙します。

- Perl, cpanm, Carton が入ったベースイメージを作る。DockerHub やプライベート Docker registry にアップしておいて、それをベースにする。
- cpanfile は先に ADD(COPY) しておく。 `carton install` の結果をなるべくキャッシュできる。
- fig を使う。アプリケーション、MySQL、memcached など実行プロセス単位で、コンテナを分ける。
- 複数の実行コマンドがある場合はスクリプト化する。ローカル起動、プロダクション起動、テスト実行など、それぞれについてスクリプトを用意しておく。
- CI も fig で実行する。
- CI ではテスト成否だけでなく、ビルドした Docker image を `docker push` する。

## Perl, cpanm, Carton が入ったベースイメージを作る

あちこちで使いまわすので、作っておくと楽です。
あまり、ONBUILD や ENTRYPOINT を使ってフックを作らないほうが、継承先のイメージビルドでハマらないかもしれません。
ベストプラクティスがたくさんあるので、適当に従いましょう。

- [https://docs.docker.com/articles/dockerfile_best-practices/:title:bookmark]
- [http://crosbymichael.com/dockerfile-best-practices.html:title:bookmark]
- [http://d.hatena.ne.jp/mainyaa/20140203/p1:title:bookmark]

例えば、自分の場合は、下記のような Dockerfile を書いて、DockerHub に Automate Build させてどこでもシュッと使えるようにしています。
サイズの小さめな debian イメージをベースにする、パッケージのミラーをCDNのものに指定する、パッケージのキャッシュは消してイメージサイズを抑えるなどの工夫などがあります。

https://github.com/y-uuki/dockerfiles/blob/master/perl/5.20.1/Dockerfile
https://registry.hub.docker.com/u/yuuk1/perl/

```
FROM debian:wheezy
MAINTAINER y_uuki

ENV DEBIAN_FRONTEND noninteractive

RUN echo "deb http://cdn.debian.net/debian/ wheezy main contrib non-free" > /etc/apt/sources.list.d/mirror.jp.list
RUN echo "deb http://cdn.debian.net/debian/ wheezy-updates main contrib" >> /etc/apt/sources.list.d/mirror.jp.list
RUN rm /etc/apt/sources.list

RUN apt-get update && \
    apt-get install -yq --no-install-recommends build-essential curl ca-certificates tar bzip2 patch && \
    apt-get clean && \
    rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

ENV PERL_VERSION 5.20.1
ENV PATH /opt/perl-$PERL_VERSION/bin:$PATH
ENV CPAN_INSTALL_PATH /cpan

# Perl
RUN curl -sL https://raw.githubusercontent.com/tokuhirom/Perl-Build/master/perl-build > /usr/bin/perl-build
RUN perl -pi -e 's%^#!/usr/bin/env perl%#!/usr/bin/perl%g' /usr/bin/perl-build
RUN chmod +x /usr/bin/perl-build
RUN perl-build $PERL_VERSION /opt/perl-$PERL_VERSION
RUN curl -sL http://cpanmin.us/ | /opt/perl-$PERL_VERSION/bin/perl - --notest App::cpanminus Carton
```

もちろん、[公式の言語スタック](https://registry.hub.docker.com/_/perl/) を使ってもよいですが、Carton が入っていなかったり、`WORKDIR` や`ONBUILD`、`ENTRYPOINT`などが勝手に設定されていたりして、ハマりポイントになるかもしれないので、自分で作った素直なベースイメージを使うことを推奨します。

## cpanfile は先に ADD(COPY) しておく。

Ruby の Bundler の場合の方法そのままです。[http://ilikestuffblog.com/2014/01/06/how-to-skip-bundle-install-when-deploying-a-rails-app-to-docker/:title]
`COPY ./ $APPROOT` してから `RUN carton install` するとリポジトリのファイルをどれか変更するだけで、`COPY ./ $APPROOT`の行のキャッシュが切れてしまい、それ以降の cpanfile に変更がなくても `carton install` のフルインストールが走ってしまいます。
そこで、cpanfile を先に COPY しておくことで、cpanfile に変更がない場合は、その行はキャッシュされます。

```
FROM yuuk1/perl:5.20.1

RUN apt-get update && \
    apt-get install -yqq --no-install-recommends mysql-client-5.5 libmysqlclient-dev libssl-dev && \
    apt-get clean && \
    rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

ENV APPROOT /src/app
RUN mkdir -p $APPROOT
WORKDIR /src/app

COPY cpanfile $APPROOT/cpanfile
RUN carton install
COPY ./ $APPROOT

EXPOSE 5000
CMD ["script/app"]
```

cpanfile.snapshot をどうするかという問題があります。
Docker は、cpanfile.snapshot の CPAN モジュールバージョン固定の世界から Linux のユーザランドの固定の世界に拡張したものと捉えることができるので、Git管理せずに CI でビルドしたイメージをそのまま本番にデプロイすればあんまり意識しなくていいかなという気がしています。

もちろん、本番は Docker 化してないこともあると思うので、CI でビルドしたイメージから cpanfile.snapshot を `docker cp` で持ってきて、Git のリポジトリに自動で含めるようにするなどの工夫をすれば良い気がしています。
参考: [http://www.songmu.jp/riji/entry/2014-02-19-carton.html:title]

## Fig を使う

MySQL や memcached などのミドルウェアをアプリケーションと同じコンテナに入れるのか別々のコンテナにいれるのがいいかを以前、id:papix さんに聞かれたことがありました。
Docker は複数のデーモンを立ち上げる綺麗な方法を基本的にサポートしていないので、1デーモン1コンテナな世界だと思っています。（supervisor を使うなどの方法は一応ある。https://docs.docker.com/articles/using_supervisord/ )

そもそも全部入りの Docker image を本番で使うことはまずないと思うので、開発環境とその他の環境で Dockerfile を分けることになり、二重管理するハメになりそうです。
ただ、あくまで複数ホスト構成が当たり前なWebアプリケーションを前提しているので、個人で作ったちょっとしたアプリケーションであれば、全部入りのほうがやりやすければそれでもよいような気はしています。

ただ、デーモン単位でコンテナをわけると、コンテナの管理が面倒ではあります。
そこで、Fig を使います。
Fig は Docker 社が開発している Docker 版の Foreman、Proclet みたいなものだと勝手に思っています。
要は、複数コンテナの立ち上げや停止の管理をサポートしてくれるいいやつです。

Fig で開発環境を作る方法は Fig のチュートリアルがわかりやすいです。

[http://www.fig.sh/rails.html:title]

今回は、Perl アプリケーションの例を紹介します。
Fig を使うにはまず、`fig.yml` を作る必要があります。
db, web などのロール名に対して、docker コマンドのオプションを定義していくやり方です（setup はスキーマを流すためのコマンドコンテナです）。

互いのロールの参照には、[Docker のコンテナリンク](https://docs.docker.com/userguide/dockerlinks/) を使います。
コンテナリンクを使うと、リンク先のホスト名と公開ポートなどがリンク元では環境変数として参照できます (https://github.com/y-uuki/dockerized-perl-app/blob/master/config/development.pl#L5-6 ) 。
本来は、links にはコンテナ名を指定しなければならないのですが、Fig ならロール名という抽象的な名称で指定できるので、名前指定の煩わしさがなくなっています。

```
db:
  image: mysql:5.5.40
  environment:
    - MYSQL_USER=nobody
    - MYSQL_PASSWORD=nobody
    - MYSQL_ROOT_PASSWORD=root
    - MYSQL_DATABASE=mydocker
  ports:
    - "3306"
setup:
  build: .
  command: script/db
  links:
    - db
web:
  build: .
  command: carton exec perl script/my-docker-server
  ports:
    - "5000:5000"
  volumes:
    - ./:/src/app
  links:
    - db
```

イメージのビルドは

```shell
$ fig build
```

するだけです。コンテナの起動方法はいくつかありますが、全コンテナをまとめて起動するなら

```shell
$ fig up
```

すればよいだけです。
コンテナを一つづつ起動したい場合は、`fig run` を使います。

```shell
$ fig run -d mysql
$ fig run setup
$ fig run web 
```

## 複数の実行コマンドがある場合はスクリプト化する

実行環境は `web` (linked with `db`) を使いたいが、Webサーバの起動以外のことをしたいときはよくあります。
このようなときには、各コマンドをスクリプト化しておくと便利です。
例えばテスト実行は

```shell
$ fig run web script/test
```

のようにできると手軽です。
他にも、スキーマの流しこみを

```shell
$ fig run web script/db # (fig up 時にもやってほしいので、fig run setup で実行できるようにしてはいる)
```

でできたりすると簡単です。

script/test は以下のような簡単なスクリプトですが、これを逐一実行するのは面倒です。

```
#!/bin/bash

DIR=$(dirname $0)
APPDIR=$DIR/../
carton exec -- prove -I$APPDIR/lib $APPDIR/t
```

## CircleCI

Jenkins または Docker が使える CircleCI を使うのが今のところの CI サーバの選択肢かなと思っています。
CircleCI の環境では、Docker 1.2.0 が動いていて、古いのでいくつかのバグやサポートしていない機能があって真面目にやっていません。
雰囲気はだいたい以下の様な感じです。
deployment セクションで DockerHub か DockerRegistry にアップロードできれば完璧。

```
machine:
  services:
    - docker
  timezone: Asia/Tokyo

dependencies:
  cache_directories:
    - "~/docker"
  override:
    - mkdir -p ~/docker
    - sudo sh -c "curl -L https://github.com/docker/fig/releases/download/1.0.1/fig-Linux-x86_64 > /usr/local/bin/fig"; sudo chmod +x /usr/local/bin/fig
    - script/ci/load_images ~/docker; fig build; script/ci/save_images ~/docker
test:
  override:
    - fig run -d db
    - fig run --rm setup
    - fig run web script/test
```

## ボツにしたやつ 

### ssh 

supervisor で sshd も起動するようにするという方法。起動中のコンテナの中に入る手段は Docker 1.3 から入った `docker exec -it <container> /bin/bash` で確立されたといえるので、無理してやる必要はなさそうです。
何より鍵の管理とかが面倒すぎる。

### 差分ビルド

cpanfile を先に ADD するという発想がなかったため、cron かなにかで定期的に docker build してそのイメージを使うという面倒なことをやろうとしていた時期もありました。

### Data-only Container and Runtime Container Pattern)

なるべく `carton install` のキャッシュを効かせるために、[Docker の Volume 機能](https://docs.docker.com/userguide/dockervolumes/) を使うことを考えました。

- [http://qiita.com/sokutou-metsu/items/b83b275198fc9594f5a4:title]
- [http://qiita.com/mopemope/items/b05ff7f603a5ad74bf55:title]

具体的には、永続化したいデータ(`carton install`したモジュール)を Data Volume Container という専用のコンテナに置き、それを Perl や Carton などの実行環境を積んだコンテナ（Runtime Container）からマウントするという方法です。
Data Volume Container はリポジトリのファイル群を ADD して、そのディレクトリを VOLUME として公開するだけで、`carton install` や `carton exec` は Runtime Container から実行する。

それなりにいいアイデアだと思ったものの、常にアプリケーションにつき 2種類の Docker image とコンテナを管理することになり、仕組みが煩雑になります。さらに、Data Volume Container に状態を持たせることになるので、クリーンな環境を作りやすい Docker を使っているメリットが薄くなってしまうという問題があります。
cpanfile.snapshot が壊れたりすることを考えると、cpanfile にモジュールを追加したときくらいは最初から `carton install` して作りなおしても悪くないと思います。

# 課題

まだやってないことです。

## Git のブランチごとのイメージ管理

CI 環境でビルドした後に、DockerHub や Registry にブランチ名やSHA1をタグとして push すればよいと思っています。
ブランチが削除されたら Registry から削除するなどの仕組みの整理は結構面倒。

## ホットデプロイ

Perl の世界では Server::Starter を使った無停止デプロイが有名ですが、Server::Starter と Docker 化したアプリケーションは相性が悪いと思っています。
例えば、アプリコンテナの起動時にコンテナの中で Server::Starter を起動するようにしたとしても、デプロイ前後で同じコンテナを使うことになり、せっかくクリーンなコンテナを使っているメリットがあまりありません。
Blue Green Deployment のような Docker コンテナごと入れ替える運用が推奨されていると思うので、ロードバランサの設定を動的に書き換えるなどの運用方法の確立が必須となりそうです。

他にもなんかいろいろある。

# 参考

- [http://blog.nomadscafe.jp/2013/06/psgiplack.html:title:bookmark]
- [http://astj.hatenablog.com/entry/2014/12/17/233823:title:bookmark]
- [http://yuuki.hatenablog.com/entry/tokyo-is-too-old:title:bookmark]

どうでもいいけど、クジラの祖先がラクダであるとかいうめちゃくちゃ雑な情報をゲットしました。

明日は id:ar_tama:detail さんです。よろしくお願いします！



はてなでは新プロダクトで Scala, Go などが採用されていますが、まだまだ Perl も現役なので、Perl エンジニアもとにかく募集しております。

<div style="border: 1px solid #DED6CF; padding: 10px; margin-top: 20px;">
株式会社はてなではインターネットで生活を楽しく豊かにしたいスタッフを募集しています<br>
<a href="http://hatenacorp.jp/recruit/" target="_blank">採用情報 - 株式会社はてな</a>
</div>
