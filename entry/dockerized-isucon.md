---
Title: "ISUCONでNginxとMySQLをDocker化したときのパフォーマンス"
Category:
- Docker
- ISUCON
Date: 2014-11-25T09:00:00+09:00
URL: http://blog.yuuk.io/entry/dockerized-isucon
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/8454420450074955017
---

現実的なWebサービス環境において、Docker化によるパフォーマンス低下がどの程度のものか調査するために、
[https://github.com/isucon/isucon4/tree/master/qualifier:title=ISUCON4 の予選問題]のうち、Nginx と MySQL 部分を Docker 化してベンチマークをとってみた。
典型的なWebサービスシステムの3層構造（Proxy, App, DB）を構築し、ベンチマーカーにより高ワークロードを実現できるので、ISUCON の予選問題は適当な題材といえる。
Docker のパフォーマンスについて留意することは先日書いたエントリに全て書いてる。

[http://yuuki.hatenablog.com/entry/docker-performance:embed]

上記のエントリを要約すると、Docker のパフォーマンスについて重要なこととは

- storage-driver の選択 (AUFS or Device mapper or ...)
- Volume の ON / OFF
  - AUFS などの差分ファイルシステムをバイパスするかしないか
- Host networking の ON / OFF
  - NAPT（ポートマッピング） しないかするか

<!-- more -->

の3つであり、前者2つがブロックI/O集約なアプリケーション、後者がネットワークI/O集約なアプリケーションにおいて特に重要であることがわかった。
予選では、自チームはNginx, MySQL, memcached, Perl(Webアプリサーバ)を使っていたが、全部 Docker 化するのも面倒なので、上述のエントリの知見から、ブロックI/O集約な MySQL と ネットワークI/O集約な Nginx を Docker 化すれば十分だろうと考えた。

## ベンチマーク条件

基本的に、ISUCON4予選のレギュレーションに則ってる。

>
インスタンスタイプ: m3.xlarge
CPU: Xeon E5-2670 v2 @ 2.50GHz 4 vCPU
メインメモリ: 16GB RAM
ストレージ: EBS Magnetic volumes
OS: Amazon Linux 3.14.19-17.43

自チームのISUCON4予選時の構成を基準にしている。(Docker化する都合上、UNIXドメインソケットを切ってあるので、スコアは多少落ちてる）

- スコア 39982 (約 3000 req/s)
  - 試行ごとに +-1000 スコア程度の誤差はでる
- 予選突破レベル
- データは全部メモリに乗る
- セッション情報などは memcached
- Nginx で静的ファイルを返す
- ネットワークスタック、Nginx, MySQL は普通のチューニング

<p><span itemscope itemtype="http://schema.org/Photograph"><img src="http://cdn-ak.f.st-hatena.com/images/fotolife/y/y_uuki/20141124/20141124005422.png" alt="f:id:y_uuki:20141124005422p:plain" title="f:id:y_uuki:20141124005422p:plain" class="hatena-fotolife" itemprop="image"></span></p>

## ベンチマーク結果と考察

- MySQL と Nginx 両方ので Host Networking on/off 比較
- Volume の on/off 比較は MySQL のみ
- benchmarker の workload 指定は全て 22 (一定)
- Docker 1.2.0
- Docker のリンク機能は使ってない
- storage-driver には device-mapper を選択
  - 本当は AUFS と比較するべきだが、Amazon Linux では AUFS のインストールが面倒...

結果は以下のとおり。net=bridge は Host Networking を OFF、net=host は ON にしている状態である。

| 構成 | スコア |
|:--------------------|------------:|
| default             |       39982 |
| Nginx(net=bridge)   |       32368 |
| Nginx(net=host)     |       38976 |
| MySQL(net=bridge)   |       38346 |
| MySQL(net=host)     |       40802 |
| MySQL(net=host, no-volume)    |    39335 |

まず、Nginx(net=bridge) が20%ほど遅い。
これはNAPT処理のオーバヘッドによるものと推測できる。
一方で、MySQL(net=bridge) の場合はデフォルトとほとんど変わらないところをみると、リバースプロキシのようなネットワークI/O集約なワークロードのアプリケーションの場合、オーバヘッドがより大きいと言える。

次に、MySQL(net=host, no-volume)のスコアがデフォルトあまり変わらない。
[http://yuuki.hatenablog.com/entry/docker-performance] のエントリでは、I/O集約なアプリケーションでは Volume を使わないと、AUFS の場合、I/Oレイテンシが大きいという結論になった。 今回使った Device mapper だと、ブロックデバイスを束ねて層を作る実装なので、AUFSのようにそもそもI/O要求が各層を通過するオーバヘッドがない可能性もある。
とはいえ、今回は書き込みI/Oがそれほど多くなく、データもメモリに全てのっているので、ファイルシステム層をバイパスしてもあまり効果がなかったのかもしれない。

その他については、net=host だとNAPTオーバヘッドがないため、デフォルトとほぼ変わらないなど、予想どおりの結果だった。
ISUCONのような高負荷環境においても、オプションを適切に選べばDocker化により、パフォーマンスが落ちることはそれほどないということがわかった。

## 【補足】 docker-proxy について

Nginx(net=bridge) のとき、docker-proxy とかいうプロセスが top でみて CPU 45%消費してた。そりゃ遅いはずだ。

```
docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 80 -container-ip x.x.x.x -container-port 80
```

docker-proxy は Docker 1.2.0 から導入されたアウトバンドトラフィックを各コンテナへルーティングするものらしい。

>The Docker userland proxy that routes outbound traffic to your containers now has its own separate process (one process per connection). This greatly reduces the load on the daemon, which considerably increases stability and efficiency.
>
[http://blog.docker.com/2014/08/announcing-docker-1-2-0/:title]

ポートマッピングするユーザランドプロセスがDocker本体と別プロセスで起動されるようになった。1コネクションあたり1プロセスとあるけど、HTTP keepalive 切ってあるベンチマーカーがいても1プロセスしか上がってなかったようなので、どちらかというと one process per port な気がする（要調査）。
Docker 1.2.0 以前ならばもっと遅かったということになる。
そもそも、ポートマッピングってユーザランドでやらないとダメなのか、このあたりはまだよくわかってない。

実装はこの辺。https://github.com/docker/docker/blob/master/daemon/networkdriver/portmapper/proxy.go

## その他

この内容は [http://ct-study.connpass.com/event/9068/:title] でも発表させていただいた。
@tenforward さんの [https://speakerdeck.com/tenforward/linuxkontenafalseji-ben-tozui-xin-qing-bao-2014-11-14:title:bookmark] がLinuxコンテナを理解する上で参考になった。

ちなみに、ISUCONは今年初出場して本戦で負けた。

- [http://motemen.hatenablog.com/entry/isucon4-final:title]
- [http://www.songmu.jp/riji/entry/2014-11-21-isucon4.html:title]

チームメンバー、ならびに運営の皆様、本当におつかれさまでした。
