---
Title: "Dockerは速いのか？Dockerのパフォーマンスについて重要なことは何か？"
Category:
- Docker
- 論文
Date: 2014-11-10T09:00:00+09:00
URL: http://blog.yuuk.io/entry/docker-performance
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/8454420450073066942
---

だいぶ前からDocker（Linuxコンテナ）のパフォーマンスについて、速いことは速いだろうけどどの程度速いのか、もし遅いことがあるなら何がパフォーマンスにとって重要なのか（AUFSが遅いとかそういうの）が気になっていたので、今回は

[http://www.infoq.com/news/2014/08/vm-containers-performance:embed]

で紹介されていた Docker のパフォーマンス検証に関する IBM の Research Report を読んだ。Report の内容をベースに、Docker のパフォーマンスの勘所などをまとめてみた。
Report のタイトルは *[http://domino.research.ibm.com/library/cyberdig.nsf/papers/0929052195DD819C85257D2300681E7B/$File/rc25482.pdf:title=An Updated Performance Comparison of Virtual Machines and Linux Containers]* 。
GitHub にベンチマークコードと実験データが置いてあってちゃんとしてる。
[https://github.com/thewmf/kvm-docker-comparison:embed]

<!-- more -->

# 前提

まず、VMとコンテナの歴史を振り返るのに[http://paiza.hatenablog.com/entry/2014/10/21/%E7%9F%A5%E3%82%89%E3%81%AC%E3%81%AF%E3%82%A8%E3%83%B3%E3%82%B8%E3%83%8B%E3%82%A2%E3%81%AE%E6%81%A5%E3%80%82%E4%BB%8A%E3%81%95%E3%82%89%E8%81%9E%E3%81%91%E3%81%AA%E3%81%84%E3%80%90%E3%82%B3%E3%83%B3:title:bookmark] も併せて読んでおくとよさそう。

次に、[http://blog.etsukata.com/2014/05/docker-linux-kernel.html:title:bookmark] と [http://www.slideshare.net/enakai/docker-34668707:title:bookmark] が Docker が使ってるカーネル周りの技術についてわかりやすいので、絶対読みたい。

特に、Docker のドライバ周りについて、exec driver、storage driver、Host Networking、Volume について軽く見ておくと良さそう。

- exec-driver: [http://blog.docker.com/2014/03/docker-0-9-introducing-execution-drivers-and-libcontainer/:title]
  - Docker は LXC のラッパーとか言われてたけど、今は Linux Containers API を直接叩く Go ライブラリが使われてる。(LXC やその他の Linux コンテナのフロントエンドも選べる）

- storage-driver: [http://blog.docker.com/2013/11/docker-0-7-docker-now-runs-on-any-linux-distribution/:title]
  - Docker のイメージ差分管理機能は従来 AUFS のみが使われていて、AUFS は Linux カーネルのメインラインの機能ではないので、カーネル標準の Device Mapper (dm-thin)もドライバにできるようになった。 Btrfs も使える。
  - [http://developerblog.redhat.com/2014/09/30/overview-storage-scalability-docker/:title:bookmark] についても参考になる。

- Host Networking: [https://docs.docker.com/articles/networking/:title]
  - Docker はコンテナ内のポートをホスト側の任意のポート番号をもつポートとして公開できる。つまり、NAPTするわけだけど、NAPTのオーバヘッドを回避するために、コンテナではなくホストのネットワークスタックを使うようにできる Host Networking 機能がある。
  - 必ずしも、NAPTオーバヘッド回避のためだけではなく、ホストと同じインタフェースみえててほしいとかもある。

- Volume: [http://docs.docker.com/userguide/dockervolumes/:title]
  - コンテナ間およびホスト間のデータ共有のために、差分ファイルシステム（AUFSなど）をバイパスする特別なディレクトリ。おそらくコンテナごとにデータを格納するものではなく、Docker グローバルで参照できるディレクトリ。
  - [https://github.com/docker/docker/issues/6999:title]
  - [http://qiita.com/sokutou-metsu/items/b83b275198fc9594f5a4#2-3:title]

# 概要と考察

Report 自体は、クラウド(IaaS)事業者視点で、コンテナ(Docker), VM(KVM), Native Linux（仮想化してない普通のLinux） の3者の性能を比較してる。
性能評価の観点は、プロセッサ（FLOPS）、メモリ帯域幅、メモリIOPS、ネットワーク帯域幅、ネットワークレイテンシ、ブロックデバイスの帯域幅、ブロックデバイスのIOPSなどとなっている。
LINPACK、 netperf や fio などを用いた OS のベンチマークだけでなく、実用的なアプリケーションとして MySQL と Redis についてもベンチマークされている。
自分の場合は、EC2 インスタンスまたはオンプレの Xen Domain U で Docker コンテナを動かすことになるだろうから、VM と コンテナの比較よりは、Native Linux とコンテナの比較に興味があった。

レポートの３章のグラフをみるとわかるが、結論から言うと、Docker のオーバヘッドをなるべく削減する構成にすれば、各評価において Docker は Native Linux と同等かやや劣る程度で、実用上それほど問題になることはなさそうだ。
CPU、メモリ周りとネットワークとブロックデバイスの帯域幅については同等である。
CPU/メモリ集約なアプリケーションとか動画配信サーバみたいな帯域幅集約なアプリケーションなら気にすることは特に何もない。

逆に、 MySQL と Redis のようなストレージまたはネットワークのIOPSが支配的なアプリケーションではパフォーマンスが劣化する。 
原因は AUFS と NAPT で、NAPT のポート変換オーバヘッドと I/O 要求が AUFS の各ファイルシステム層を通過するオーバヘッドがある。
ただし、Docker の Host Networking とか Volume 機能を使って、前述のオーバヘッドをかなりの部分まで削減することができる。（それでも、MySQLについてはNativeと比べて多少性能が落ちる。レイテンシの僅かな差がスループットに影響を与えている。）ただしこれはコンテナのポータビリティとパフォーマンスのトレードオフになる。
例えば、NAPT を使わなくすると、コンテナが公開するポートとホストのポートがコンフリクトすることもあり、Dockerコンテナがどこでも動くというわけではなくなる。また、Volume 機能を使うと、Docker イメージにデータを書き出すことができないため、コンテナをデータごと他所に持って行きづらくなってしまう。

CPU、メモリ周りは通常用途にはそんなに気にするポイントなかったので、ブロックI/O or ネットワークI/O集約なアプリケーション（MySQL とか HAProxy）以外は自分が触ってるような環境の場合本番投入しても問題なさそうな印象を受けた。
MySQL や Redis についてはステートフルなので、そもそもインスタンスの増減や引っ越しがステートレスサーバほど気軽にはできないので、多少人間的なオペレーションが入ってもよい。
つまり、それほどポータビリティが重要なわけではない。実行環境はDockerなのでそのままで、データだけは Volume ディレクトリの内容をホストに書き出して別途コピーしておけばよい。
また、statefull なアプリケーションについては、同じアプリケーションを同じホストで動かさない運用にしておけば、ポート番号はウェルノウンポート決め打ちぐらいでよさそう。

# スライド
細かい実験条件などはより詳しい内容についてはスライドまたはReport 本文を参照。

<script async class="speakerdeck-embed" data-id="c5b0e3d0499a013242bc4e743bb86014" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>

# 感想

スライドの最後にも書いてるけど、コンテナは隔離されたプロセスぐらいのイメージなので、VMに比べて速いに決まってるし、Native Linuxと遜色ないのもまぁそうかという感じ。AUFS 遅いというのもまぁそうかという感じで、Device Mapper とか Btrfs との比較が気になるところ。AUFS以外の storage driver について[http://developerblog.redhat.com/2014/09/30/overview-storage-scalability-docker/:title] が参考になる。（大量のコンテナの作成と削除を以下に速くできるかが指標となっているので、やっていることはだいぶ違う）

関係ないけど、Docker の本番投入の問題はパフォーマンス云々以上に、既存のワークフローにいかに組み込むかと問題が発生したときのデバッグまたは障害対応であるというのがここ半年くらいの認識になっている。

# 気になる参考文献

今回の Report は参考文献が豊富で、いくつか気になったので紹介しておく。

[https://www.gronkulator.com/overhead.html:title:bookmark:title]

[http://bodenr.blogspot.jp/2014/05/kvm-and-docker-lxc-benchmarking-with.html:title]

[http://www.rackspace.com/blog/onmetal-the-right-way-to-scale/:embed]

[http://fabiokung.com/2014/03/13/memory-inside-linux-containers/:embed]

[https://redislabs.com/blog/i-have-500-million-keys-but-whats-in-my-redis-db:embed]


はてなでは、Docker 好きな人とか、論文読んで知見を共有したり本番投入したい人も募集しています↓↓↓

<div style="border: 1px solid #DED6CF; padding: 10px; margin-top: 20px;">
株式会社はてなではインターネットで生活を楽しく豊かにしたいスタッフを募集しています<br>
<a href="http://hatenacorp.jp/recruit/" target="_blank">採用情報 - 株式会社はてな</a>
</div>
