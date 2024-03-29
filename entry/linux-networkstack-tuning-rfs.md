---
Title: Linuxでロードバランサやキャッシュサーバをマルチコアスケールさせるためのカーネルチューニング
Category:
- Linux
- Kernel
- Network
- NIC
- Performance
- TCP
Date: 2015-03-31T08:30:00+09:00
URL: https://blog.yuuk.io/entry/linux-networkstack-tuning-rfs
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/8454420450089846829
---

本記事の公開後の2016年7月にはてなにおけるチューニング事例を紹介した。 [https://speakerdeck.com/yuukit/linux-network-performance-improvement-at-hatena:title:bookmark]

HAProxy や nginx などのソフトウェアロードバランサやリバースプロキシ、memcached などの KVS のような高パケットレートになりやすいネットワークアプリケーションにおいて、単一の CPU コアに負荷が偏り、マルチコアスケールしないことがあります。
今回は、このようなネットワークアプリケーションにおいて CPU 負荷がマルチコアスケールしない理由と、マルチコアスケールさせるための Linux カーネルのネットワークスタックのチューニング手法として RFS (Receive Flow Steering) を紹介します。

Redis や Nodejs のような1プロセス1スレッドで動作するアプリケーションをマルチコアスケールさせるような話ではありませんのでご注意ください。

<!-- more -->

[:contents]

# 問題と背景

前述のように高負荷なネットワークアプリケーションにおいて、下記のように他のコアが空いているにも関わらず、CPU0 の softirq(%soft) に負荷が集中した結果、CPU0 のみ idle(%idle) が著しく低いということがよくあります。

```
CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest   %idle
all   31.73    0.00    1.47    0.13    0.00    0.96    0.06    0.00   65.64
  0   70.41    0.00    5.10    0.00    0.00   15.31    0.00    0.00    9.18
  1   68.04    0.00    3.09    0.00    0.00    0.00    0.00    0.00   28.87
  2   53.06    0.00    3.06    0.00    0.00    0.00    0.00    0.00   43.88
  3   47.47    0.00    2.02    0.00    0.00    0.00    1.01    0.00   49.49
  4   49.45    0.00    1.10    0.00    0.00    0.00    0.00    0.00   49.45
  5   44.33    0.00    2.06    0.00    0.00    0.00    0.00    0.00   53.61
  6   38.61    0.00    2.97    0.99    0.00    0.00    0.00    0.00   57.43
  7   32.63    0.00    1.05    0.00    0.00    0.00    0.00    0.00   66.32
  8   29.90    0.00    1.03    1.03    0.00    0.00    0.00    0.00   68.04
  9   10.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00   90.00
 10    8.08    0.00    1.01    0.00    0.00    0.00    0.00    0.00   90.91
 11    6.12    0.00    0.00    0.00    0.00    0.00    0.00    0.00   93.88
 12   10.00    0.00    2.00    0.00    0.00    0.00    0.00    0.00   88.00
 13   11.00    0.00    1.00    0.00    0.00    0.00    0.00    0.00   88.00
 14   17.71    0.00    0.00    0.00    0.00    0.00    0.00    0.00   82.29
 15   11.22    0.00    1.02    0.00    0.00    0.00    0.00    0.00   87.76
```

softirq というのはソフト割り込みと呼ばれますが、ソフト割り込みの負荷が高いというのはどういうことかというのと、なぜ CPU0 に負荷が集中するのかについて議論してみます。

## ソフト割り込みの負荷が高いとはどういうことか

Linux のソフト割り込みについては、[http://sourceforge.jp/projects/linux-kernel-docs/wiki/2.2%E3%80%80Linux%E3%82%AB%E3%83%BC%E3%83%8D%E3%83%AB%E3%81%AE%E5%89%B2%E3%82%8A%E8%BE%BC%E3%81%BF%E5%87%A6%E7%90%86%E3%81%AE%E7%89%B9%E5%BE%B4:title] を参照してください。

まず、Linux における割り込みを用いたパケットの受信フローをみてみます。Linux 2.6 からは割り込みとポーリングを組み合わせた NAPI という仕組みでパケットを受信します。NAPI についてはこの記事の最後のおまけの章をみてください。

[f:id:y_uuki:20150330235452p:plain]

1. 【NICハードウェア受信】NIC はパケットを受信すると NIC の内部メモリにパケットを置く。
1. 【ハードウェア割り込み】パケットを受信したことを知らせるために、NIC からホストの CPU にむけてハードウェア割り込みをかける。ハードウェア割り込みがかけられた CPU (NIC ドライバ) は NIC 上のパケットをカーネル上のリングバッファに置く 。移行のパケット処理は同期的に処理しなくてよいため、ソフト割り込みをスケジュールして、そちらに任せる。(厳密には、リングバッファに渡しているのはソケットへのポインタ的なもので、パケットデータは DMA で CPU を介さずに、カーネルのメモリ領域に渡されるはず)
1. 【ソフト割り込み】スケジュールされたソフト割り込みが発生し、リングバッファからパケットを取り出し、ソフト割り込みハンドラでプロトコル処理したのち、ソケットキューにパケットが積まれる。
1. 【アプリケーション受信】`read`、`recv`、`recvfrom` などが呼ばれるとソケットキューからアプリケーションへ受信データがコピーされる。

一回一回のハードウェア割り込みおよびソフト割り込み負荷は当然大したことはありません。しかし、64 バイトフレームで 1Gbps のワイヤーレートでトラヒックを流したとすると、約 1,500,000回/sec もの割り込みが発生することになります。ソフト割り込みは優先度の高いタスクなので、割り込みを受けている CPU は割り込みハンドラの処理以外何もできなくなります。

CPU のクロック周波数が頭打ちになり、10 Gbps イーサネットなどのワイヤーレートが向上すると、このように CPU 処理のうち割り込み処理の割合が大きくなっていきます。

パケット受信の流れについては、下記の文献が詳しいです。

- [http://www.ece.virginia.edu/cheetah/documents/papers/TCPlinux.pdf:title=TCP Implementation in Linux: A Brief Tutorial:bookmark]
- [https://access.redhat.com/documentation/ja-JP/Red_Hat_Enterprise_Linux/6/html/Performance_Tuning_Guide/s-network-packet-reception.html:title:bookmark]
- [http://www.slideshare.net/m-asama/linux-packetforwarding:title:bookmark]
- [http://test-docdb.fnal.gov/0013/001343/001/CHEP06_Talk_132_Wu-Crawford_LinuxNetworking.pdf:title=The Performance Analysis of Linux Networking – Packet Receiving:bookmark]


## なぜマルチコアスケールしないのか（なぜ CPU 負荷が特定コアに偏るのか）

まず、マルチキュー対応(MSI-X 対応、RSS 対応) NIC でない場合、NIC からのハードウェア割り込み先は特定の CPU に固定されます。
もしランダムに複数の CPU に割り込みをかけたとすると、パケットを並列処理することになり、TCP のような一つのフロー(コネクション)中のパケットの順序保証があるプロトコルの場合、パケットの並べ直しが必要になります。 これを TCP reordering 問題といいます。reordering によりパフォーマンスを下げないために、同じ CPU にハードウェア割り込みをかけています。

さらに、ハードウェア割り込みハンドラでソフト割り込みをスケジュールします。このとき Linux ではハードウェア割り込みを受けた CPU と同じ CPU にソフト割り込みを割り当てるようになっています。これは、ハードウェア割り込みハンドラでメモリアクセスした構造体をソフト割り込みハンドラにも引き継ぐので、CPUコアローカルな L1, L2キャッシュを効率よく利用するためです。

したがって、特定の CPU にハードウェア割り込みとソフト割り込みが集中することになります。

実環境では、割り込み負荷に加えて、アプリケーション処理の CPU負荷 (%user) も割り込みがかかっている CPU に偏っています。
これは、`accept()` で待ち状態のアプリケーションプロセスが、データ到着時にプロセススケジューラにより、プロトコル処理した CPU と同じ CPU に優先してアプリケーションプロセスを割り当てているような気がしています。
これも、L1, L2キャッシュの効率利用のためだと思いますが、ちゃんと確認できていません。

# ネットワークスタックをマルチコアスケールさせるための技術

ネットワークスタックをマルチコアスケールさせるための技術は、NIC(ハードウェア)の機能によるものか、カーネル(ソフトウェア)の機能によるものか、その両方かに分類できます。
今回紹介するのは、NICの機能で実現する RSS(Receive Side Scaling) と RPS/RFS です。
RPS の発展した実装が RFS なので、実質 RSS と RFS ということになります。

RSS/RPS/RFS については、[https://www.kernel.org/doc/Documentation/networking/scaling.txt:title=Scaling in the Linux Networking Stack] が詳しいです。
RPS/RFS は Linux カーネル 2.6.35 以降で実装されていますが、RHLE 系は 5.9 ぐらい以降でバックポートされていたと思います。

他にも、論文ベースでは、[1][ATransport-FriendlyNICforMulticore/MultiprocessorSystems] や [2][mTCP: a Highly Scalable User-level TCP Stack for Multicore Systems] など、ネットワークスタックを高速化させるための様々な手法が提案されています。

[1]: http://www.computer.org/csdl/trans/td/2012/04/ttd2012040607-abs.html "ATransport-FriendlyNICforMulticore/MultiprocessorSystems"
[2]: http://shader.kaist.edu/mtcp/ "mTCP: a Highly Scalable User-level TCP Stack for Multicore Systems"

## RSS（Receive Side Scaling)

マルチコアスケールしないそもそもの原因は、特定の CPU にのみハードウェア割り込みが集中するからです。
そこで、NIC に複数のパケットキューを持たせて、キューと CPU のマッピングを作り、キューごとにハードウェア割り込み先 CPU を変えます。

TCP reordering を回避するために、"フィルタ"により同じフローのパケットは同じキューにつなげるようにします。
フィルタの実装は大抵、IPヘッダとトランスポート層のヘッダ、例えば src/dst IPアドレスと src/dst ポート番号の4タプルをキーとして、キュー番号をバリューとしたハッシュテーブルになります。

ハッシュテーブルのエントリ数は 128 で、フィルタで計算したハッシュ値の下位 7 bit をキーとしているハードウェア実装が多いようです。

## RPS (Receive Packet Steering)

RSS は NIC の機能なので、NIC が対応していなければ使えません。
RSS 相当の機能をソフトウェア(Linuxカーネル)で実現したものが RPS です。

RPS はソフト割り込みハンドラで NIC のバッファからパケットをフェッチした後、プロトコル処理をする前に、他の CPU へコア間割り込み(IPI: Inter-processor interrupt)します。そして、コア間割り込み先の CPU がプロトコル処理して、アプリケーション受信処理をします。

他の CPU の選択方法は RSS とよく似ており、src/dst IPアドレスと src/dst ポート番号の4タプルをキーとして、Consistent-Hashing により分散先の CPU が選択されます。

[f:id:y_uuki:20150330235500p:plain]

RPS のメリットは以下の3点が考えられます。

- ソフトウェア実装なので、 NIC に依存しない
- フィルタの実装がソフトウェアなので、新しいプロトコル用のフィルタも簡単に追加できる
- ハードウェア割り込み数を増やさない
  - ハードウェア割り込みを CPU 間で分散させるために、通常1回で済むハードウェア割り込みを全ての CPU に対して行い、ロックを獲得した CPU のみソフト割り込みをスケジュールするという非効率なやり方もある？ (RSS で MSI-X が使えないとこうなる？)

RPS の使い方は簡単で、NIC のキューごとに下記のようなコマンドを叩くだけです。シングルキュー NIC なら `rx-0` のみで、マルチキュー NIC ならキューの数だけ `rx-N` があります。

```
# echo "f" > /sys/class/net/eth0/queues/rx-0/rps_cpus
```

`rps_cpus` は分散先のの CPU の候補をビットマップで表しています。
`"f"` の2進数表現は `1111` となり、各ビットが下位から順番に CPU0  ~ CPU3 まで対応しています。ビットが 1 ならば、対応する CPU は分散先の候補となるということです。
つまり、`"f"` なら CPU0,1,2,3 が分散先の候補となります。
通常は全てのコアを分散先に選択すればよいと思います。
RPS を有効にしても、ハードウェア割り込みを受けている CPU に分散させたくないときは、その CPU の対応ビットが 0 になるような16進数表現にします。
詳細は https://www.kernel.org/doc/Documentation/IRQ-affinity.txt に書かれています。

## RFS (Receive Flow Steering)

RPS はアプリケーションプロセスまで含めた L1, L2キャッシュの局所性の観点では問題があります。
RPS ではフローとフローを処理する分散先のCPUのマッピングはランダムに決定されます。
これでは、`accept(2)` や `read(2)` を呼んでスリープ中のアプリケーションプロセスがスリープ前に実行されていた CPU とは異なる CPU に割り当てられる可能性があります。

そこで、RFS は RPS を拡張して、アプリケーションプロセスをトレースできるようになっています。
具体的には、フローに対するハッシュ値からそのまま Consistent-Hashing で分散先CPU を決めるのではなく、フローに対するハッシュ値をキーとしたフローテーブルを用意して、テーブルエントリには分散先の CPU 番号を書いておきます。
該当フローを最後に処理した CPU が宛先 CPU になるように、`recv_message` などのシステムコールが呼ばれたときに、フローテーブルの宛先 CPU を更新します。

RFS の設定は、RPS の設定の `rps_cpus` に加えて、`rps_flow_cnt` と `rps_sock_flow_entries` を設定するだけです。

```
# echo "f" > /sys/class/net/eth0/queues/rx-0/rps_cpus
# echo 4096 > /sys/class/net/eth0/queues/rx-0/rps_flow_cnt
# echo 32768 > /proc/sys/net/core/rps_sock_flow_entries
```

`rps_sock_flow_entries` はシステムグローバルなフローテーブルのエントリ数を設定します。
ローカルポート数(最大接続数)以上を設定しても意味はないので、65536 以下の数値を設定すればよいはずです。
32768 が設定されている例をよく見かけます。

`rps_flow_cnt` は NIC キューごとのフロー数を設定できます。
16 個のキューをもつ NIC であれば、`rps_sock_flow_entries` を 32768 に設定したとすると、`rps_flow_cnt` は 2048 に設定するのが望ましいと思います。
シングルキュー NIC であれば、`rps_flow_cnt` は `rps_sock_flow_entries` と同じ設定でよいです。

設定の永続化については、[http://netmark.jp/2014/06/centos6-sys-sysfs.html:title=CentOS6で/sys/の変更を永続化する方法] が非常に参考になります。

# 実験

ベンチマークツール( [https://iperf.fr/:title=iperf] )によるベンチマークと実アプリケーションへの適用をやってみました。
いずれも 10GBps NIC を使用しています。

## iperfによるベンチマーク

ベンチマーク環境は以下の通りです。

- CPU: Intel Core i5 3470 3.2GHz 2コア (Hyper Threading有効)
- NIC: Mellanox ConnectX-3 EN 10GbE PCI Express 3.0
- OS: CentOS 5.9

CPU クロック周波数を BIOS で 1.6 GHz に制限して、無理やりCPUネックな環境を作っています。
iperfのプロセス数(コネクション数)を4として、パケットサイズを64バイトにしてトラヒックを流すと、iperfサーバ側では、下記のように CPU0 の softirq コンテキストの使用率が 100% になります。


```
CPU   %user   %nice    %sys %iowait    %irq   %soft  %steal   %idle
all    0.74    0.00   16.75    0.00    0.00   27.83    0.00   54.68
  0    0.00    0.00    0.00    0.00    0.00  100.00    0.00    0.00
  1    2.00    0.00   52.00    0.00    0.00    9.00    0.00   37.00
  2    0.00    0.00   14.95    0.00    0.00    3.74    0.00   81.31
  3    0.00    0.00    1.00    0.00    0.00    0.00    0.00   99.00
```

そこで、下記の設定で RFS を有効にすると、CPU1,CPU2,CPU3にも system と softirq が分散される形になりました。

```
# echo "f" > /sys/class/net/eth0/queues/rx-0/rps_cpus
# echo 4096 > /sys/class/net/eth0/queues/rx-0/rps_flow_cnt
# echo 32768 > /proc/sys/net/core/rps_sock_flow_entries
```

```
CPU   %user   %nice    %sys %iowait    %irq   %soft  %steal   %idle
all    0.24    0.00   11.86    0.00    0.00   23.00    0.00   64.89
  0    0.00    0.00   11.11    0.00    0.00   38.38    0.00   50.51
  1    0.95    0.00   12.38    0.00    0.00   19.05    0.00   67.62
  2    0.00    0.00   13.21    0.00    0.00   18.87    0.00   67.92
  3    0.00    0.00   12.50    0.00    0.00   16.35    0.00   71.15
```

## 実アプリケーション(Starlet)への適用

次に、Perl の [https://github.com/kazuho/Starlet:title=Starlet] で動作しているプロダクション環境のアプリケーションサーバに RFS を適用してみました。
アプリケーションサーバ環境は以下の通りです。

- EC2 c3.4xlarge SR-IOV有効
- CPU: Intel Xeon E5-2680 v2 @ 2.80GHz 16コア
- NIC: Intel 82599 10 Gigabit Ethernet Controller
- NIC driver: ixgbevf 2.7.12
- OS: 3.10.23 Debian Wheezy

RFS の設定は標準的です。

```
# echo "ffff" > /sys/class/net/eth0/queues/rx-0/rps_cpus
# echo 32768 > /sys/class/net/eth0/queues/rx-0/rps_flow_cnt
# echo 32768 > /proc/sys/net/core/rps_sock_flow_entries
```

RFS 有効前は下記の通り、CPU0 以外の CPU コアはがら空きなのにもかかわらず、CPU0 の softirq(%soft)  が 15% を占めており、idle が 9% しかないという状況です。

```
CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest   %idle
all   31.73    0.00    1.47    0.13    0.00    0.96    0.06    0.00   65.64
  0   70.41    0.00    5.10    0.00    0.00   15.31    0.00    0.00    9.18
  1   68.04    0.00    3.09    0.00    0.00    0.00    0.00    0.00   28.87
  2   53.06    0.00    3.06    0.00    0.00    0.00    0.00    0.00   43.88
  3   47.47    0.00    2.02    0.00    0.00    0.00    1.01    0.00   49.49
  4   49.45    0.00    1.10    0.00    0.00    0.00    0.00    0.00   49.45
  5   44.33    0.00    2.06    0.00    0.00    0.00    0.00    0.00   53.61
  6   38.61    0.00    2.97    0.99    0.00    0.00    0.00    0.00   57.43
  7   32.63    0.00    1.05    0.00    0.00    0.00    0.00    0.00   66.32
  8   29.90    0.00    1.03    1.03    0.00    0.00    0.00    0.00   68.04
  9   10.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00   90.00
 10    8.08    0.00    1.01    0.00    0.00    0.00    0.00    0.00   90.91
 11    6.12    0.00    0.00    0.00    0.00    0.00    0.00    0.00   93.88
 12   10.00    0.00    2.00    0.00    0.00    0.00    0.00    0.00   88.00
 13   11.00    0.00    1.00    0.00    0.00    0.00    0.00    0.00   88.00
 14   17.71    0.00    0.00    0.00    0.00    0.00    0.00    0.00   82.29
 15   11.22    0.00    1.02    0.00    0.00    0.00    0.00    0.00   87.76
```

RFS 有効後は、softirq(si) が他のコアに分散され、ついでに、user(%usr) や system(%sys) の負荷も分散されています。

```
CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest   %idle
all   27.41    0.00    3.07    0.00    0.00    0.70    0.13    0.00   68.69
  0   36.08    0.00    8.25    0.00    0.00    6.19    0.00    0.00   49.48
  1   30.43    0.00    3.26    0.00    0.00    0.00    0.00    0.00   66.30
  2   31.96    0.00    4.12    0.00    0.00    2.06    0.00    0.00   61.86
  3   35.64    0.00    3.96    0.00    0.00    0.00    0.99    0.00   59.41
  4   44.12    0.00    1.96    0.00    0.00    0.98    0.00    0.00   52.94
  5   37.00    0.00    9.00    0.00    0.00    0.00    0.00    0.00   54.00
  6   38.78    0.00    1.02    0.00    0.00    1.02    0.00    0.00   59.18
  7   39.00    0.00    6.00    0.00    0.00    1.00    1.00    0.00   53.00
  8   19.59    0.00    3.09    0.00    0.00    0.00    0.00    0.00   77.32
  9   23.16    0.00    3.16    0.00    0.00    0.00    0.00    0.00   73.68
 10   17.17    0.00    4.04    0.00    0.00    0.00    0.00    0.00   78.79
 11   18.00    0.00    3.00    0.00    0.00    0.00    0.00    0.00   79.00
 12   16.49    0.00    0.00    0.00    0.00    0.00    0.00    0.00   83.51
 13   16.33    0.00    0.00    0.00    0.00    1.02    0.00    0.00   82.65
 14   16.00    0.00    1.00    0.00    0.00    0.00    0.00    0.00   83.00
 15   16.67    0.00    0.00    0.00    0.00    0.00    0.00    0.00   83.33
```

softirq だけでなく、user や system も分散されているというのが重要で、前述したようにプロトコル処理が実行される CPU が分散されると、アプリケーション処理負荷も分散されます。

過去には Starlet 以外に HAProxy、pgpool、Varnish などのアプリケーションで RFS を試したことがありますが、特に副作用なく動いています。

識者の皆様方は memcached や LVS、Linux ルータに適用されているようです。

- [http://blog.nomadscafe.jp/2012/08/centos-62-rpsrfs.html:title:bookmark]
- [http://nekoya.github.io/blog/2012/11/13/centos5-rps-rfs/:title:bookmark]
- [http://myfinder.hatenablog.com/entry/2012/11/14/000633:title:bookmark]

# 参考資料

- [https://www.kernel.org/doc/Documentation/networking/scaling.txt:title=Scaling in the Linux Networking Stack:bookmark]
  - カーネルドキュメント
- [http://lwn.net/Articles/381955/:title]
  - RFS のパッチ
- [http://www.slideshare.net/syuu1228/10-gbeio:title:bookmark]
  - RSS/RFS に限らないネットワークスタック全体の最適化の話
- [http://www.slideshare.net/m-asama/linux-packetforwarding:title:bookmark]
- [http://www.valinux.co.jp/technologylibrary/document/linux/interrupts0001/:title:bookmark]

RFS は直接関係ないですが @ten_forward さんに良い資料教えていただきました。

[https://twitter.com/ten_forward/status/582695103703035904:embed]


# まとめ

Linuxカーネルのネットワークスタック処理の最適化について紹介しました。
その中でとくに RFS に着目して、ベンチマークと実アプリケーションに適用してみて、マルチコアスケールさせられることを確認できました。
RFS はハードウェア依存がなく、カーネルのバージョンさえそれなりに新しければ使えてしまうので、結構手軽な上に効果が高いので、コスパがよいチューニングといえると思います。

間違っている記述などがあれば斧ください。


【追記】コメントいただいたように、ソフトウェア割り込みという言葉を使うと、CPUのソフトウェア割り込みと混同していますので、Linux カーネルの softirq を「ソフト割り込み」と呼ぶように修正しました。(http://www.slideshare.net/syuu1228/10-gbeio の資料などから softirq をソフトウェア割り込みと呼ぶこともあるようです)

【追記2】C社の喜びの声

[https://twitter.com/mikeda/status/583633823419670530:embed]

# おまけ: ネットワークスタック処理の CPU 負荷を最適化する技術

[http://www.slideshare.net/syuu1228/10-gbeio:title:bookmark] に全て書いてあります。

ネットワークスタックのCPU負荷がボトルネックと言われるようになって久しいですが、その間ネットワークスタック処理のCPU負荷を低減させるための手法が登場しています。(代表的なものだけ抜粋)

まず、チェックサム計算などのネットワークスタック処理の中で比較的重い処理をCPU(カーネル)でやらずに、NICのASICにオフロードするという手法があります。
NICが対応している必要がありますが、オンボードNICでなければだいたい対応している気がします。
`ethtool -k eth0 rx-checksumming`などのコマンドで有効化できます。
スタック処理の一部だけでなく、TCPスタック処理のほとんどをNICにやらせる TCP Offload Engine (TOE) などもあります。

次に、NICからの割り込み回数が多いなら、1パケットごとにNICからCPUへハードウェア割り込みをかけるのではなく、複数パケットの受信を待ってから、1つの割り込みにまとめてしまえばよいという方法です。これは、Interrupt Coalescing と呼ばれています。これもNICオフロードの一種といえるかもしれません。
Interrupt Coalescing は負荷を下げられる一方で、後続パケットの受信待つ分、レイテンシは上がってしまうというデメリットもあります。
Interrupt Coalescing は今も普通に使われており、去年、EC2環境で割り込み頻度などのパラメータチューニングをしていたりしました。 [http://yuuki.hatenablog.com/entry/2014/03/20/085600:title:bookmark] 。

NIC へのオフロードは実際は問題が起きやすく、無効にすることが多いです。

ソフトウェアベースの手法として、Linux 2.6 から使える NAPI というカーネルが提供する NIC ドライバフレームワークがあります。
NAPI は Interrupt Coalescing と同様、1パケットごとにNICからCPUへハードウェア割り込みをかけることを防ぎますが、CPU から NIC へポーリングをかけるところが異なります。
具体的には、一旦パケットを受信したらハードウェア割り込みを禁止して、CPU が NIC の受信バッファ上のパケットをフェッチします。
パケットレートが高ければ、禁止からフェッチまでの間にNIC受信バッファに複数のパケットが積まれるはずなので、1回のポーリングでそれらをまとめてフェッチできます。
e1000 や igb などの主要なNICドライバは NAPI に対応しているはずなので、典型的な Linux 環境であれば、NAPI で動作していると思って良いと思います。

[asin:487311313X:detail]

[asin:4873115019:detail]
