---
Title: "Docker を用いた rpm / deb パッケージ作成の継続的インテグレーション"
Category:
- Docker
- Mackerel
Date: 2014-05-12T08:53:56+09:00
URL: http://blog.yuuk.io/entry/docker-package-ci
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/12921228815723807041
---

[http://help-ja.mackerel.io/entry/howto/install-agent:title=サーバ管理ツールのエージェント] みたいなソフトウェアをインストールしやすくするために、rpm / deb パッケージを作りたい。

しかし、rpm / deb パッケージ化するためには、それぞれ CentOS(RedHat)、Debian(Ubuntu) 環境でパッケージ化することになる。
社内ではこれまでパッケージ化の専用ホストがいて、そこで spec ファイルや init スクリプトを置いて rpmbuild コマンドとか debuild コマンドを叩いてパッケージを作成していた。
さらに、アプリケーションエンジニアからインフラエンジニアに依頼するという形をとっていた。

この方法の問題点として、以下の3つがある。

- spec ファイルや init スクリプトなどをプロジェクトの Git リポジトリで管理しづらい。つまり、レビューとかがやりにくい。
- リリースフローを自動化しづらい。具体的には、リリースの度に専用ホストにログインして手でコマンド叩いてことになる。（社内リリース的なのは毎日やる）
- 1台の専用ホストを複数人で共有することになるので、コンフリクトしやすい。

# Docker で解決

![](https://www.docker.io/static/img/homepage-docker-logo.png)

rpm / deb パッケージを Docker コンテナ内で作成することにより、上記の問題点が解決できる。

>
- spec ファイルや init スクリプトなどをプロジェクトの Git リポジトリで管理しづらい。つまり、レビューとかがやりにくい。

boot2docker とか Vagrant を使えば開発者の Mac でもビルドできるようになったので、いちいち専用ホストでファイル編集とかしなくてよくなった。
リポジトリ内で完結しているので、アプリケーションエンジニアでもインフラエンジニアでも、普通のアプリケーションと同じ間隔で、specファイルとか編集して、pullreq & レビューできる。

>
- リリースフローを自動化しづらい。具体的には、リリースの度に専用ホストにログインして手でコマンド叩いてことになる。（社内リリース的なのは毎日やる）

Jenkins でテスト成功後に、同じジョブでパッケージビルドさせることで、明示的にパッケージ化するコストがなくなった。
さらに、テストが成功しているものだけパッケージ化されるので、変なリビジョンのコードがパッケージされてないか人間が確認しなくてよい。

>
- 1台の専用ホストを複数人で共有することになるので、コンフリクトしやすい。

Docker コンテナという隔離環境を毎回作っては捨てるので作業がコンフリクトしない。コード的なコンフリクトはGitで解決できる。

# ディレクトリ構成と Dockerfile

- ディレクトリ構成 (rpm)

```
.
├── BUILD
│   └── mackerel-agent
├── Dockerfile
├── RPMS
│   └── noarch
├── SOURCES
│   ├── mackerel-agent.conf
│   ├── mackerel-agent.initd
│   ├── mackerel-agent.logrotate
│   └── mackerel-agent.sysconfig
├── SPECS
│   └── mackerel-agent.spec
└── SRPMS
```

- ディレクトリ構成 (deb)

```
.
├── Dockerfile
└── debian
    ├── README.Debian
    ├── changelog
    ├── compat
    ├── control
    ├── copyright
    ├── docs
    ├── mackerel-agent
    ├── mackerel-agent.bin
    ├── mackerel-agent.conf
    ├── mackerel-agent.debhelper.log
    ├── mackerel-agent.default
    ├── mackerel-agent.initd
    ├── mackerel-agent.logrotate
    ├── rules
    └── source
        └── format
```

- Dockerfile (rpm)

```
FROM centos
RUN yum update -y
RUN yum install -y rpmdevtools

RUN mkdir -p /rpmbuild
ADD ./ /rpmbuild/  # 上記のディレクトリをまとめてDockerコンテナ内に取り込む
RUN chown root:root -R /rpmbuild
CMD rpmbuild -ba /rpmbuild/SPECS/mackerel-agent.spec
```

- Dockerfile (deb)

```shell
FROM tatsuru/debian
RUN apt-get update && apt-get install -yq --force-yes build-essential devscripts debhelper fakeroot --no-install-recommends

RUN mkdir -p /debuild/debian /deb
ADD ./debian /debuild/debian
RUN chown -R root:root /debuild
WORKDIR /debuild
CMD debuild --no-tgz-check -uc -us; mv ../*.deb /deb/
```

ディレクトリ構成と Dockerfile は上記のような感じで、

```shell
docker build -t 'hatena/mackerel/rpm-builder' .
docker run -t 'hatena/mackerel/rpm-builder' -v ./build/:/rpmbuild/RPMS/noarch:rw
```

とかやると、Docker のボリューム機能により、手元の build ディレクトリに rpm ファイルができる。
（Mac の場合は、ホストOS上のVM上でコンテナが動くので、VMのファイルシステムに設置される）。
これで、パッケージファイルの出来上がりで、こういうのをJenkinsにやらせてる。
Jenkins の成果物にしておくと、適当なところからダウンロードしやすくて便利。

# 思うところ

別に Docker である必要もなくて Vagrant 使ってもよい。
ただ、古いファイルとかが紛れ込まないように環境をどんどん使い捨てたいので、Vagrant よりは Docker のほうが起動が速いのでうれしさがある。
さらに、Jenkins サーバで Vagrant 動かすよりは Docker のほうがセットアップしやすい。

あと、Jenkins で何回も Docker コンテナを立てては殺す場合に、ゴミ掃除に気を使うことになる。
[http://yuuki.hatenablog.com/entry/ii-conference01:title:bookmark]

Dockerは、アプリケーションをコンテナで動作させるような Immutable Infrastructure 的なコンテキストで注目されてる。
しかし、今まで特別な環境でしかできなかったことを気軽に手元でできるようになったりするので、もっと幅広い使い道があると思う。
今回は Docker のおかげで、アプリエンジニアとインフラエンジニアで無駄なコミュニケーションコストが発生することなく、いい感じの開発フローができた。

なんか DevOps っぽい。

# TODO

serverspec 的なもので、パッケージインストール後の状態を自動テストしたい。
さらに、agent 起動後の振る舞いテストとかまでできるとよい。
