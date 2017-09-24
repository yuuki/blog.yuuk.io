---
Title: パフォーマンスの観点からみるDockerの仕組みと性能検証
Category:
- Performance
- Docker
Date: 2015-01-19T08:00:00+09:00
URL: http://blog.yuuk.io/entry/docker-performance-on-web-application
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/8454420450080670369
---

[http://connpass.com/event/10318/:title=Docker Meetup Tokyo #4] にて「Docker Performance on Web Application」という題で発表しました。
発表内容は、下記の2つの記事をまとめたものに加えて、最新バージョンの Docker 1.4 での ISUCON ベンチマークと、storage-driver として Device Mapper + Docker 1.4 から実装された [https://github.com/docker/docker/pull/7619:title=OverlayFS] を試しました。

- [http://yuuki.hatenablog.com/entry/docker-performance:title:bookmark]
- [http://yuuki.hatenablog.com/entry/dockerized-isucon:title:bookmark]

この記事は、上記2記事で、いくつか難しいポイントがあったとフィードバックをいただいたので、Docker Meetup での発表内容を少し詳しめに説明したものになります。

<!-- more -->

# 1. Dockerのパフォーマンスについて重要な事はなにか

Docker のパフォーマンス検証に関する IBM の Research Report である [http://domino.research.ibm.com/library/cyberdig.nsf/papers/0929052195DD819C85257D2300681E7B/$File/rc25482.pdf:title=An Updated Performance Comparison of Virtual Machines and Linux Containers]の内容などから
Linux Containers、UNION Filesystem、Volume、Portmapper、Host Networking が重要な要素であることがわかりました。

![Docker Items](http://cdn-ak.f.st-hatena.com/images/fotolife/y/y_uuki/20150118/20150118231635.png)

## Linux Containers

まず、Linux Containers については、コンテナという機能があるのではなく、カーネルの各リソース（ファイルシステム、ネットワーク、ユーザ、プロセステーブルなど）について実装されている Namespace によって区切られた空間のことをコンテナと呼んでいます。つまり、Namespace で隔離された空間でプロセスを生成するというモデルになります。(普通のプロセスと扱いが変わらないので、Dockerコンテナの起動が速いのは当然）全ての Namespace を同時に使う必要はなく、一部の Namespace を使うことも当然可能です。(例えば、`docker run` コマンドの `--net=host`オプションは、Network Namespace を使っていないだけのはず)
Linux Containers は単体のカーネルで動作するので、親と子で別々のカーネルをもつ Hypervisor による仮想化と比べて、CPU命令をトラップしたり、メモリアクセスやパケットコピーの二重処理をしなくていいので、オーバヘッドがありません。（もちろん、VT-xやSR-IOVなど、ハードウェア支援による高速化手法はある）

@ten_forward さんの記事 [http://d.hatena.ne.jp/defiant/20141218/1418860851:title:bookmark] を読むとよいと思います。

[https://twitter.com/Yuryu/status/556322403354017792:embed]

Linux Containersについて実装レベルで理解されている方々にとっては、普通のプロセスと対して変わらないし、わざわざ検証するまでもないかと思いますが、production でのサービスインを考える上で一応見ておかないといけないと思いました。

## UNION Filesystem 

次に UNION Filesystem については、下記の公式画像をみるとだいたいわかった気になれます。

![](https://docs.docker.com/terms/images/docker-filesystems-multilayer.png)

UNION Mount という手法でファイルシステムの層が実現されており、要は既にマウントされているポイントに対して重ねて別のブロックデバイス（ディレクトリ）をマウントし、最上位層のみを read-write 属性に、それ以外の層を read-only にするようなイメージです。複数のブロックデバイス（ディレクトリ）を同じマウントポイントからアクセスできます。
基本的に、任意のファイルシステムの状態から新規書き込みの分だけ上位層に書くようにすれば、最下層にベースファイルシステムがあり、その上に差分データだけを持つファイルシステム層が乗っていくようになります。

このような仕組みを実装するにあたって、ブロックデバイスレベルでの実装とファイルシステムレベルの実装があります。
Docker では storage-driver というオプションにより、UNION Filesystem の実装を切り替えることができます。
aufs,btrfs,devicemapper,vfs,overlayfs を使用可能です。
devicemapper がブロックデバイスレベルでの実装であり、aufs,btrfs,overlayfs がファイルシステムレベルでの実装となります。(vfs は docker側で無理やり層を作ってる？）
Device Mapper は特定のファイルシステムに依存しないかつ、カーネル標準の機能なので気軽に使いやすいというメリットがあります。(LVM にも使われている）
一方で、Device Mapperの場合、イメージ層の作成・削除の性能は落ちるという検証結果もあります。([http://developerblog.redhat.com/2014/09/30/overview-storage-scalability-docker/:title:bookmark])
汎用的でプリミティブな機能を持ったDevice Mapperを使って逐一、層となる仮想ブロックデバイスの作成や削除をするより、専用の機能を実装したファイルシステムレベルの実装が速そうというのはなんとなくわかる話ではあります。

発表内でデフォルトが Device Mapper とか言っていましたが、RHEL/CentOSでは事実上 Device Mapper がデフォルトであるというのが正しいです。
お詫びして訂正します。(ISUCON ベンチマークで使った Ubuntu 14.04 では、`modprobe aufs`した状態でデフォルトが devicemapper になっていたはずなんだけど、カーネルバージョン変えてたし、なんかミスってたのかもしれない）
ちゃんとコードを読んでみると https://github.com/docker/docker/blob/5bc2ff8a36e9a768e8b479de4fe3ea9c9daf4121/daemon/graphdriver/driver.go#L79-84
となっており、aufs,btrfs,devicemapper,vfs,overlayfs の順になっているようで、デフォルトが AUFS というのが正しいです。

[https://twitter.com/Yuryu/status/556325206180888577:embed]

## Volume

UNION Filesystem を使うと複数の層に対して、I/O要求もしくはその他の処理が多重に発行されるはずで（最適化はされているとは思いますが)、オーバヘッドが気になるところです。Docker には [https://docs.docker.com/userguide/dockervolumes/:title=Volume] という機能があり、これを使うと指定したディレクトリを UNION Mount しないようになります。したがって、そのディレクトリ以下のファイルへのI/O効率がよくなる可能性があります。

Volume 自体はパフォーマンス目的で使うものではなく、コンテナ間もしくはホスト・コンテナ間でデータを共有するためのものです。

## Portmapper

コンテナ間通信やホスト・コンテナ間通信では、ホスト側の iptables によるNAPTで実現されています。(172.17.0.3がコンテナのIP)

```
-A PREROUTING -m addrtype --dst-type LOCAL -j DOCKER
-A OUTPUT ! -d 127.0.0.0/8 -m addrtype --dst-type LOCAL -j DOCKER
-A POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE
-A POSTROUTING -s 10.0.3.0/24 ! -d 10.0.3.0/24 -j MASQUERADE
-A DOCKER ! -i docker0 -p tcp -m tcp --dport 80 -j DNAT --to-destination 172.17.0.3:8000
```

ただし、iptablesが利用できない環境のために、コンテナ間通信のみ `docker-proxy` というユーザランドのプロキシが使用されます。`docker-proxy`自体はiptablesを使っている使っていないに関わらず起動しているようです。

```
docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 80 -container-ip 172.17.0.3 -container-port 8000
```

iptables、つまりカーネルランドの netfilter で NAPT できるところをユーザランドのプロキシを経由すれば明らかにオーバヘッドが大きくなるという予想がつきます。

## Host Networking

Docker では Network Namespace を使わずに、ホストと同じ Namespace を利用する Host Networking 機能があります。
Host Networking は `--net=host` で使えます。
ネットワークについては、ホストでプロセスを起動するのと変わらないことになります。
これならば、先ほどの Portmapper が必要なくなるため、NAPTのオーバヘッドがなくなります。

Host Networking については @deeeetさんの [http://deeeet.com/writing/2014/05/11/docker-host-networking/:title:bookmark] が詳しいです。

# 2. Docker化したISUCONアプリケーションのベンチマーク

ベンチマークは、Nginx と MySQL をこれまで紹介したオプションを切り替えて Docker化 して、それぞれのスコアを比較しました。
環境は前回との差分はより新しい Linux カーネル 3.8.0、Docker 1.4.1 を使っている点です。
詳しい内容は下記のスライドを参照していただくとして、結果は Nginx を Docker 化したときに Host Networking を使わずNAPTさせたときに、15%程度スコアが落ちるというものでした。それ以外の、VolumeのOn/Off や storage-driver の切り替えによるパフォーマンスの変化は ISUCON4予選の環境では起きませんでした。

Host Networking と Volume ON の状態で、性能が変わらないのは予想通りですが、storage-driver の切り替えによりパフォーマンスに変化がないのは意外でした。
これはおそらく、今回の環境では、データが全てメモリにのっているため、Read I/Oはほぼ発生していないということと、Write I/Oは UNION FS の最上層のみに適用すればよいので、複数の層があることによるオーバヘッドがあまりないのではないかと考えています。

NAPTのオーバヘッドが顕著であり、これは docker-proxy プロセスがCPU を 50% ほど使用しているためです。
iptables を有効にしているのになぜ docker-proxy が使われるのかと思いましたが、iptablesのルールに宛先がループバックアドレスの場合はコンテナへルーティングされないようです。

```
-A OUTPUT ! -d 127.0.0.0/8 -m addrtype --dst-type LOCAL -j DOCKER
```

benchmarker はデフォルトでは 127.0.0.1:80 へ接続するため、benchmarker - Nginx 間での接続に、ホストの 0.0.0.0:80 で LISTEN してる docker-proxy が使われてしまうという事態になっています。
benchmarker のオプションで `--host <host eth0 ipaddr>` としてやると、iptables でルーティングされるようになるため、スコアはDocker化していない状態とほぼ同じになりました。

## なぜループバックアドレスだけ外されるのか

宛先アドレスが 127.0.0.1 のままだと、コンテナがパケットを受信して返信するときに、宛先アドレスを 127.0.0.1 にしてしまい、コンテナ自身にループバックします。
ループバックを避けるため、以下の様なPOSTROUTINGルールでNAPTする設定が必要なようです。
127.0.0.1 がコンテナのIPに書き換わり、コンテナからホストへの返信時に宛先アドレスがコンテナのIPになり、結局自分に戻ってくるようにみえます。しかし、Docker は仮想ブリッジ経由でホスト側のネットワークとコンテナ側のネットワークを接続しているので、仮想ブリッジ(docker 0)のヘアピンNAT（NATループバック）を有効にすることで、ホスト側へNATしてくれるようです。（この辺りすこし怪しい）

```
-A POSTROUTING -p tcp -s <container ipaddr>/28 -d <container ipaddr>/28 --dport <container port> -j MASQUERADE
```

ただ、RHEL/CentOS 6.5環境下で `/sys`以下が `readonly` でマウントされており、 `/sys/class/net/{ifname}/brport/hairpin_mode` に書き込めないため、仮想ブリッジ環境でヘアピンNATモードを有効にできないようです。(RHEL/CentOS 6.5環境のみかどうかはちゃんと調べてないです)
ヘアピンNAT サポートが一旦、マージされてリバートされたのもこのためです。

- [https://github.com/docker/docker/pull/9078:title]
- [https://github.com/docker/docker/pull/6810:title]
- [https://github.com/docker/docker/pull/9269:title]


# 発表スライド

さらに詳しい情報は下記スライドを参照してください。

<script async class="speakerdeck-embed" data-id="11ff4ea081470132f24b46e172331f5f" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>

Keynote テーマは弊社のデザイナ @murata_s さんが作ったテーマを使わせてもらっています。


# 関連情報

- [http://www.slideshare.net/enakai/docker-34668707:title:bookmark]

RedHatの @enakai さんの必読のスライド。コンテナとVMM、Dockerのファイルシステム、ネットワークについて詳しく書かれていて非常に参考になりました。
26枚目の、iptables でループバックアドレス宛のパケットだけ外されている理由がわからないという点についての回答は前述の仮想ブリッジでのヘアピンNATの話かなと思います。

- [http://lwn.net/Articles/531114/:title:bookmark]
- [https://guinan.ten-forward.ws/container-20131005.pdf:title:bookmark]

Linux Containers については、LWN の記事と @ten_forward さんの記事が参考になると思います。

Device mapper については、下記スライドが参考になりました。

- [http://lc.linux.or.jp/lc2009/slide/T-02-slide.pdf:title:bookmark]

UNION Mount については、Oreilly の Programmer's High のブログが参考になりました。

- [http://www.oreilly.co.jp/community/blog/2010/02/union-mount-uniontype-fs-part-1.html:title:bookmark] 


# まとめ

Docker化したWebアプリケーションにおけるパフォーマンス研究の成果について書きました。
IBMのレポートの内容から、Linuxカーネルとの接点となるUNION Filesystem や、その他 Host Networking、Volume などがパフォーマンスにおける重要な要素であることがわかりました。そこから、自分で検証してみて、ISUCON4予選問題の範疇では、iptables を使わずに docker-proxy というユーザランドのプロキシの使用を回避さえすれば、いずれのパターンでも性能の変化はないことがわかってきました。

iptablesを切って、nf_conntrack を切ってチューニングするような環境ではそもそもまともにDockerは動かせないので、ギリギリまでリソースを使い切るようなホストの場合はさすがにI/Oまわりのパフォーマンスが問題となってくると思います。
Linuxカーネル、特にUNION Filesystem周りでパフォーマンスに関する知見があればぜひ教えていただけると助かります。

パフォーマンスの観点から Docker を支える技術を調査してきてましたが、だいたい満足しました。1年半Dockerを触ってきて、知見もかなりたまってきたので、Production で Docker を投入できそうな頃合いだと思っています。

会場を提供していただいた Recruit Technologies の皆様、イベントを企画運営していただいた皆様、どうもありがとうございました。
非常に有意義なイベントでした。


はてなではWebオペレーションエンジニア（いわゆるインフラエンジニア）を募集しています。

[http://hatenacorp.jp/recruit/fresh/operation-engineer:embed]

[http://hatenacorp.jp/recruit/fresh/operation-engineer:title]
