---
Title: "DockerとS3を用いた、yum / apt リポジトリ作成・運用の継続的インテグレーション"
Category:
- Mackerel
- Docker
Date: 2014-05-28T09:00:00+09:00
URL: http://blog.yuuk.io/entry/docker-package-repository
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/12921228815725068438
---

[http://yuuki.hatenablog.com/entry/docker-package-ci:title:bookmark] の続き。
前回は、rpm / deb パッケージを作るために、CentOS、Debianなど各種ディストリビューションを揃える手間をかけずに、Docker コンテナ上でパッケージングして、ついでに Jenkins で CI するみたいなことを書いた。

今回は、作成したパッケージを yum / apt リポジトリに登録して yum / apt コマンドでパッケージインストール/アップデートできるようになるまで継続的インテグレーションするという話。

# 問題点

- yum / apt リポジトリ用の専用ホストを立てて、そこで apache とかで静的ファイルをホストするのはめんどくさい。
  - 特に、[https://github.com/mackerelio/mackerel-agent:title=mackerel-agent] みたいなユーザにインストールしてもらうパッケージの場合、リポジトリを公開しないといけなくて、冗長化とか面倒はさらに増える。
- リポジトリ作成のために必要なメタファイル群を作成するために、createrepo や reprepro コマンドがインストールされた環境が必要となる。
  - OSX とかではインストールできない。（がんばったらできるのかもしれない）

# Docker と S3 で解決

>
- yum / apt リポジトリ用の専用ホストを立てて、そこで apache とかで静的ファイルをホストするのはめんどくさい。

前者については、S3 に静的ファイルをアップロードすることにより、サーバもたなくてよいので簡単。
手順は簡単で、S3のWebコンソールで適当にバケットを作って、createrepo または reprepro で作成したファイルをs3cmd とか aws-cli でバケットにアップロードする。
バケットには、bucket-name.s3.amazonaws.com. のようなエンドポイントがつくので、各ホストで リポジトリの設定を書くだけ。

さらに、Jenkins で master ブランチが更新されたときにパッケージの作成と同時に S3 にアップロードすることで、勝手にリポジトリに最新パッケージが入るので便利。今触ってるのは一般公開する代物なので、リリースは慎重に手でやってるけど、社内リポジトリとかならJenkinsで自動化したらよさそう）

>
- リポジトリ作成のために必要なファイル群を作成するために、createrepo や reprepro コマンドがインストールされた環境が必要となる。

手元は OSX でも、Docker 上の各ディストリビューションでディストリ依存な createrepo や reprepro をインストール・実行できる。

# ディレクトリ構成と Dockerfile

- ディレクトリ構成 (yum)

```shell
tree -a
.
├── .s3cfg
├── Dockerfile
├── files
│   └── mackerel-agent-x.x.x.noarch.rpm
└── macros
```

- ディレクトリ構成 (apt)

- Dockerfile (yum)

```
# docker build -t 'hatena/mackerel/yum-repo' .
# docker run -t 'hatena/mackerel/yum-repo'

FROM centos
ENV PATH /usr/local/bin:/usr/sbin:/sbin:/usr/bin:/bin
RUN yum update -y
RUN rpm -ivh http://ftp.iij.ad.jp/pub/linux/fedora/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN yum install --enablerepo=epel -y createrepo s3cmd

RUN install -d -m 755 /centos/x86_64
ADD files /centos/x86_64/
RUN /usr/bin/createrepo --checksum sha /centos/x86_64

ADD .s3cfg /.s3cfg
WORKDIR /centos/
CMD /usr/bin/s3cmd -P sync . s3://yum.mackerel.io/centos/
```


- Dockerfile (apt)

```
# docker build -t 'hatena/mackerel/apt-repo' .
# docker run -t 'hatena/mackerel/apt-repo'

FROM tatsuru/debian
ENV PATH /usr/local/bin:/usr/sbin:/sbin:/usr/bin:/bin
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update
RUN apt-get -y install reprepro s3cmd
RUN apt-get clean

RUN mkdir -p /deb
ADD files /deb/
WORKDIR /debian
RUN mkdir -p db dists pool
ADD conf /debian/conf
RUN reprepro includedeb mackerel /deb/*.deb
RUN reprepro export

ADD .s3cfg /.s3cfg
CMD /usr/bin/s3cmd -P sync . s3://apt.mackerel.io/debian/
```

## リポジトリの設定
独自リポジトリなので、インストール先ホストではリポジトリを設定する必要がある。
yum / apt で、それぞれ次のように設定するとよい。

- yum の場合

/etc/yum.repos.d/mackerel.repo
```
[mackerel]
name=mackerel-agent
baseurl=http://yum.mackerel.io/centos/\$basearch
```
- apt の場合

```shell
echo "deb http://apt.mackerel.io/debian/ mackerel contrib" >> /etc/apt/sources.list.d/mackerel.list
```

# 所感
Docker または Vagrnat を使うと、いちいちディストリビューション環境用意しなくてよいし、余分なサーバをもたなくて済む。
これは、Virtualbox や VMware で仮想ホストを立ち上げても同じだけど、Docker や Vagrant は CLI で操作できてプログラマブル（特に Docker はREST APIがある）なので、自動化しやすい。
さらに、Docker なら毎回クリーンな環境からリポジトリを構築しやすいのでゴミが入りにくいというメリットがある。
（Vagrnat でもできるけど、壊して再構築するのに時間がかかる）

前にも書いたけど、Docker 使うと、今まで特別な環境でしかできなかったことを気軽に手元でできるようになったりする。
Docker が Immutable Infrastructure 専用の何かみたいに言われることがあって、結局まだそんなにうまく使えないよねみたいな話あるけど、用途はいろいろあると思う。
