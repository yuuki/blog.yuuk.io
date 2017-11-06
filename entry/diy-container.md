---
Title: 自作Linuxコンテナの時代
Category:
- Linux
- Docker
- Container
Date: 2016-04-27T10:45:00+09:00
URL: http://blog.yuuk.io/entry/diy-container
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/6653812171393185239
---

最近、Docker以外のコンテナ型仮想化技術の流れとして、自作コンテナエンジンの時代が来るのではないかと感じている。

自作コンテナエンジンとは、コンテナ型仮想化技術を構成する個々の要素技術を組み合わせ、自分の用途にあわせて最適化したコンテナエンジンのことだ。
他のOSのコンテナ仮想化技術について疎いため、以下ではLinuxに限定して話を進める。

<!-- more -->

# 概要

Dockerも含めて、Linuxコンテナはコンテナを構成する複数の要素技術の組み合わせである。自分のやりたいことに対して、Dockerをはじめ既存のコンテナエンジンが複雑すぎるケースがある。そこで、自分の用途にあわせてコンテナエンジンを自作することを考えてみる。[libcontainer](https://github.com/opencontainers/runc/tree/master/libcontainer)に代表されるように、Linuxコンテナエンジンを自作しやすい環境が整いつつある。今後は、巨大なコンテナエンジンに対して、UNIX哲学に基づいて制御可能な小さなコンテナエンジンを自作する道もあるのではないか。

# 自作Linuxコンテナ

Dockerの登場により、コンテナ仮想化技術がいわゆるウェブエンジニアにとっても身近なものになってきた。

しかし、コンテナとDockerはイコールではない。
Dockerはコンテナという仕組みそのものではなく、既存のLinuxコンテナの要素技術を応用したソフトウェアだ。

Dockerはコンテナ型仮想化技術の中でも、最大レベルの複雑さを持つと思う。
コンテナの基礎となるLinux Namespacesに加えて、プログラマブルなAPI、Dockerfile、レイヤ構造をもつイメージフォーマット、DockerHub/Registry、、Machine/Compose/Swarm、最近ではオーバレイネットワークなどもある。[Kubernetes](http://kubernetes.io/)のようなDockerを前提とした3rd Partyのソフトウェアを合わせると大変なことになる。

これだけ複雑なソフトウェアであれば、用途によってはオーバテクノロジーとなりうる可能性がある。
既存の運用と整合性をとるのも一苦労だ。

そこで、コンテナを使いたい（隔離環境を作りたい）ときにDockerを使わずに、用途に合わせてコンテナエンジンを自作するという選択肢もある。
例えば、kazuhoさんの[jailing](http://blog.kazuhooku.com/2015/05/jailing-chroot-jail.html)はその一つだ。

jailingは、ホスト環境の一部（/usr/libや/etc/hostsなど) を共有したchrootベースの手頃なjail環境を提供してくれるスクリプトだ。
外部公開するサーバソフトウェアをセキュアに保つためになるべき隔離した環境で動かしたい。
しかし、Dockerやその他の既存のコンテナエンジンだとサービスごとにシステム環境を用意しなければならないため、特にディスク容量を消費する。
ホスト環境を共有するjailingであれば、ディスク容量の消費をある程度抑えられる (ディスク容量以外にもDockerや既存のコンテナエンジンはいろいろ面倒な点はある）。

他にも、Linuxコンテナの要素技術を組み合わせた軽量なコンテナエンジンはたくさんある。

[rcon](https://github.com/matsumoto-r/rcon)は任意のコマンドに対して、cgroupにより、各種リソース（CPU、メモリなど）を隔離・制限するコマンドラインツールだ。
cgroup単体でコンテナと呼ばれることはあまりないのかもしれない。rconの場合、与えたコマンドをリソース制限をかけたjailに閉じ込めるようなニュアンスをもつため、広義のコンテナといってよいのではないかと思う。

[virtuald](http://www.tldp.org/HOWTO/Virtual-Services-HOWTO-3.html) は古くからあるらしいが結構おもしろい。理解が間違っていなければ、chrootとinetdの組み合わせで、NICとIPアドレスの割り当てを意識せずに、ホストに設定した複数のIPアドレスごとに異なるサーバソフトウェアをサービスできる。IPアドレスごとにchroot jail環境を割り当て、あたかも1つのホスト上に異なるIPアドレスをもつホストが存在するようにみせている。

発想がどれもおもしろくて、どの要素技術をどう組み合わせるかが工夫のしどころだ。
自分では[Droot](https://github.com/yuuki/droot)というのを作っている。

[http://yuuki.hatenablog.com/entry/droot:embed:cite]

# 自作コンテナを作るためには

自作コンテナを作るためには、Linuxコンテナの要素技術の理解と、それらを扱うためのライブラリやモジュールが必要だ。

自作コンテナといっても、機能が多くなければ、実装するのはそれほど難しくない。
スクリプト1枚で十分ということもある。

ただし、作るもののアイデアはLinuxコンテナの要素技術をある程度理解していなければでてこないと思う。

ライブラリやモジュールがなければ、生で叩くか自分で作る必要がある。chroot程度であれば生で叩く程度でも十分だ。
幸いDockerの実装言語であるGo言語にはLinuxコンテナを扱うためのパッケージが整っていると言える。

## Linuxコンテナの要素技術

Linuxコンテナについては、@ten_forward さんの資料がわかりやすい。

<div style="width:60%">
<script async class="speakerdeck-embed" data-id="1291977097b74e51a96276ca8e965b01" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>
</div>

簡単にまとめると以下のようになる。

Linuxコンテナといっても、カーネルにコンテナという単一の機能があって、コンフィグを有効にすると使えるというものではない。
広義には、Linux Namespacesを中心に、cgroup、chroot（pivot_root）、Linux capabilities、veth、macvlan、Unionファイルシステム（AuFS、OverlayFS）などの、コンテナの要素技術を組み合わせて、OS内に作成したなんらかの隔離環境をコンテナと呼ぶ。

cgroupやLinux capabilities、veth/macvlanなどは本来コンテナ専用の機能ではない。
コンテナエンジンと組み合わされることの多い技術をコンテナの要素技術と呼ぶことにする。

狭義には、Linuxコンテナは[LXC単体かLXC関連のプロジェクト](https://linuxcontainers.org/)を指すこともある。

より詳しくは同じく @ten_forward さんの連載の第１回から第６回を読むとよい。
[http://gihyo.jp/admin/serial/01/linux_containers:embed]

拙作の[Droot](https://github.com/yuuki/droot)の場合は、chroot、Bind Mount、Linux capabilitiesを併用している。

## Go言語のコンテナ向けパッケージ

Dockerから派生したlibcontainerなど、Dockerのおかげでコンテナを自作するための足回りは揃っていると思う。
コンテナに限らず、システムプログラミングや運用ツールの作成をする上で役に立つものも多い。

- [github.com/opencontainers/runc/libcontainer](https://github.com/opencontainers/runc/tree/master/libcontainer)
  - Linux Namespaces、cgroup、CRIUなど
- [github.com/docker/docker/pkg](https://github.com/docker/docker/tree/master/pkg)
  - archive、devicemapper、directory、fileutils、loopback、mount、symlink、system など
- [github.com/syndtr/gocapability](https://github.com/syndtr/gocapability)
  - Linux capabilities
- [github.com/vishvananda/netlink](https://github.com/vishvananda/netlink)
  - veth、macvlanなど
- [github.com/seccomp/libseccomp-golang](https://github.com/seccomp/libseccomp-golang)
  - seccomp
- [github.com/docker/engine-api](https://github.com/docker/engine-api)
  - Dockerの公式APIクライアント

# これからのコンテナ仮想化技術

<div style="width:60%">
<script async class="speakerdeck-embed" data-slide="32" data-id="3b333ef473ca4180999af7a18391b802" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>
</div>

id:matsumoto_r:detailさんの資料の最後にあるように、コンテナによりホスト環境をプロセスと同レベルに高速に作れるようになり、OS機能がホストの外まで展開されるようになる。
OSの上にOSを作るようなものかもしれない。
これは、[Mesosphere](https://mesosphere.com/) が提唱するDC/OSに通じるところがある。

一方で、DC/OSを実現するようなソフトウェアであるMesosphereやKubernetesは、内部的に複数のコンポーネントに分かれているとはいえ一つの巨大で複雑な仕組みを提供するようにみえる。
ただでさえ複雑なOSの上に、さらに複雑な層を設けて、その上にアプリケーションをのせるという考え方で、人間がシステムの挙動をコントロールできるのか疑問はある。

ウェブ業界の歴史も長くなり、10年以上動き続けるシステムも珍しくなくなってきた。
ソフトウェアにはバージョンがあり、10年間動き続けるシステムを支えていくためには、ソフトウェアをアップデートしつづけていくことになる。(ハードウェアも当然壊れるので、新しくし続けていく必要がある。)

一つの大きなソフトウェアをアップデートするのは大変だが、UNIX哲学に基づいた小さなソフトウェアをアップデートしたり差し替えることは比較的容易だ。
コンテナをプロセスとして見立てるという発想はそのままに、一つ一つコントール可能なものを組み合わせて、全体でなめらかなシステムを作るのが理想だと思う。

コンテナエンジンも用途にあった制御可能なものを自作して組み込めばよいのではないか。

ちょうど似たような構造がウェブアプリケーションフレームワーク界隈にもある。
Railsのようなフルスタックのフレームワークか、小さなモジュールが組み合わさった最小の機能を提供するフレームワークか、という話だ。
特にPerlでは後者の傾向が強い。これについては、[http://yuuki.hatenablog.com/entry/large-scale-infrastructure:title:bookmark] でも触れている。
はてなだとプロジェクトごとに最小化したPlackベースのフレームワークを作成している（はず）。
もしフルスタックのフレームワークの採用を続けていたら、フレームワークをバージョンアップし続けるのはおそらく厳しかったのではないか。

# 参考

- [https://lwn.net/Articles/531114/:title]
- [https://github.com/tcnksm/awesome-container:title]
- [http://d.hatena.ne.jp/defiant/20141218/1418860851:title]
- [http://d.hatena.ne.jp/defiant/20150522/1432294501:title]
- [http://d.hatena.ne.jp/defiant/20150701/1435749116:title]
- [http://d.hatena.ne.jp/defiant/20150714/1436872695:title]
- [https://blog.docker.com/2016/03/containers-are-not-vms/:title]

[asin:487311585X:detail]

# あとがき

先日、福岡のペパボオフィスで開催された[第9回コンテナ型仮想化技術@福岡](https://ct-study.connpass.com/event/28449/)に登壇させていただいた。
都合3度目の登壇となる。
最初に登壇したのは2年前の第3回で、普通にDockerの話をした気がする。このときは、Linux Namespacesがなにか知らなかった。
次の参加はその年の11月で、その時はDockerのパフォーマンスの話をした。このときぐらいから、Linux Namespacesが少しわかってきた。
今回はコンテナを自作する話になった。
少しずつ、Linuxコンテナの要素技術そのものに近づいてきた。

実は今回登壇するまで、自作コンテナという概念を考えていたわけではなかった。
よくも悪くもDockerに囚われていたため、Docker思想である「Build, Ship, Run」を部分的にchrootで実現するという程度の気持ちだった。
当日、福岡へ向かう新幹線でこの発表って結局なにが言いたいんだっけと考えて、自然と「コンテナは自分で作れる」というスライドを足していた。
id:matsumoto_r:detail さんの発表を拝聴したり、その後の懇親会でお話させていただいてその考えは深まった。

京都に帰ってきて、mizzy(@gosukenetor)さんがおっしゃっていたことを思い出す。

[https://twitter.com/gosukenator/status/567524251175886850:embed] 

最近は、ユーザランドのサーバソフトウェアが各々実装しているような機能をカーネルの汎用機能で置き換えられないかを考えている。
ジャストアイデアだけど、例えば、[http://yuuki.hatenablog.com/entry/infra-for-newlang:title=ウェブアプリケーション開発に新言語を採用したときにインフラで考えたこと:bookmark]で書いたように、preforkが運用しやすいならば、preforkに対応できないサーバソフトウェアをコンテナに入れて、複数のコンテナを起動し、[Linux IPVS](http://www.linuxvirtualserver.org/software/ipvs.html)で内部分散してしまえばよい、といったことだ。定期的にプロセス(コンテナ)を生成しなおす仕組みやGracefulに再起動する仕組みをどうするかはまだ考えているところだが。IPVSのルーティングを動的にweight 0にしてActiveConnが0になったらコンテナごと捨てて作りなおすというところまで思いついた。これができればいわゆるワーカープロセス単位でリソース制限することも簡単だし、harakiri的なことも簡単にできるかもしれない。

はてなでは他人が書いたソフトウェアを組み合わせるだけでなく、小さなことであっても自分で新しいなにかを生み出していきたいエンジニアをお待ちしています。

[https://twitter.com/y_uuk1/status/724447190467256320:embed]

[http://hatenacorp.jp/recruit/career/operation-engineer:embed]

# 発表資料

<div style="width:66%">
<script async class="speakerdeck-embed" data-id="eac621e42c574227811f3646ab44ea48" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>
</div>
