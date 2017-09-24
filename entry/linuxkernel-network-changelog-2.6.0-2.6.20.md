---
Title: "Linuxカーネルにおけるネットワークスタック周りのChangeLog勉強メモ (2.6.0 ~ 2.6.20) "
Category:
- Linux
- Kernel
- TCP
Date: 2012-12-30T07:38:50+09:00
URL: http://blog.yuuk.io/entry/linuxkernel-network-changelog-2.6.0-2.6.20
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/12704830469097142218
---

最近，OSのネットワークスタックに興味があって，Linuxカーネルのネットワークスタック実装の変遷について調べてみた．  
変更内容の粒度は割りと適当．

TCPとかFireWallとかNIC周りは興味があるのでだいたい書いてる．  
Wireless系は興味ないので全部削ってる．

ネットワークスタック周りだけでもかなり量が多かったので，とりあえず2.6.0から2.6.20までをまとめた．

## Linux 2.6.x

### 2.6.5 (2004/04/04)
http://kernelnewbies.org/Linux_2_6_5

- Netpoll infrastructure

[Netpoll](http://lwn.net/Articles/75944/)が導入された．  
Netpollは，I/Oシステムとネットワークシステムが完全には利用できないみたいな不安定な環境でカーネルがパケットを送受信できる仕組みのこと．受信したパケットがnetpoll宛かどうかをTCP/IPのヘッダレベルでNICが判定し，カーネルの受信キューにパケットを積む前にNICが受信処理を行う．  
組み込みデバイス環境で使ったりするらしい．  
(see http://www.spa.is.uec.ac.jp/research/2006/hama/main.pdf)  

### 2.6.6 (2004/05/10)
http://www.kernel.org/pub/linux/kernel/v2.6/ChangeLog-2.6.6

- Network packet timestamping optimization

- Binary Increase Control (BIC) TCP developed by NCSU. It is yet another TCP congestion control algorithm for handling big fat pipes. For normal size congestion windows it behaves the same as existing TCP Reno, but when window is large it uses additive increase to ensure fairness and when window is small it 

TCPの輻輳制御アルゴリズムにBICが追加された．  
BICについては前回のブログに少し書いてる．["CUBIC: A new TCP-friendly high-speed TCP variant"を読んだ](http://yuuki.hatenablog.com/entry/cubictcp)  


- IPv6 support in SELinux

- A mechanism which allows block drivers to respond to queries about the congestion state of their queues

<!-- more -->

### 2.6.7 (2004/6/16)
http://kernelnewbies.org/Linux_2_6_7

- new API for NUMA systems

ネットワーク関係ないけど，NUMA向けのAPI入った．  

### 2.6.8 (2004/08/14)
http://kernelnewbies.org/Linux_2_6_8

- TCP/IP congestion control changes from Reno to BIC

2.6.6で追加された輻輳制御アルゴリズムのBICがRenoに代わってデフォルトになった．
というか，それまでRenoがデフォルトだったのか．  
現実のインターネットでは空気読まないRenoがまだまだ使われてるって聞いてたけど，納得感がある．  

### 2.6.9 (2004/10/19)
http://kernelnewbies.org/Linux_2_6_9

- Change in TCP ICMP source quench behavior

- Ethtool support in the loopback driver

- NETIF_F_LLTX interface

[NETIF_F_LLTX](http://lwn.net/Articles/101215/)はhard_start_xmit()と呼ばれるNICのドライバ関数の一つで，送信時にネットワークケーブルにパケットをのせる．  
net_device構造体に対してlockをとるので，任意の時間に一回だけ呼ばれる．  

- Automatic TCP window scaling calculation

TCPの設定からtcp_default_win_scaleを消して，自動で計算するようにした．  

### 2.6.11 (2005/03/02)
http://kernelnewbies.org/Linux_2_6_11

- TCP port randomization

- Major problems with TCP/IP BIC (the default congestion control) are resolved

BICの輻輳ウィンドウサイズの最大値の計算にミスがあったらしい．  

>BICTCP_1_OVER_BETA/2 should be BICTCP_1_OVER_BETA*2.

まじかー．  
ちなみに，この修正の正しさの検証に以下のツールを使ったらしい．覚えておく．  

netem - http://www.linuxfoundation.org/collaborate/workgroups/networking/netem  
広範囲のネットワークをエミュレートできるらしい．  
kprobes - http://sourceware.org/systemtap/kprobes/  
カーネルのデバッガ的な．  

### 2.6.12 (2005/06/17)
http://kernelnewbies.org/Linux_2_6_12

- Remove IPV6 "experimental" status

IPv6関連の不具合がいろいろ修正されてた．  

### 2.6.13 (2005/08/29)
http://kernelnewbies.org/Linux_2_6_13

- Runtime selectable TCP congestion algorithm: Allow using setsockopt to set TCP congestion control to use on a per socket basis

TCP輻輳制御アルゴリズムをsetsockoptシステムコールを使ってソケットごとに指定できるように．  
(http://lwn.net/Articles/128681/)  

- Add several TCP congestion modules: H-TCP, TCP Hybla, High Speed TCP (HS-TCP), TCP Westwood, TCP BIC

いろいろな輻輳制御アルゴリズムをカーネルモジュールとして追加．  

### 2.6.14
http://kernelnewbies.org/Linux_2_6_14

- DCCP: "Datagram Congestion Control Protocol". Datagram protocol (like UDP), but with a congestion control mechanism. Currently a RFC draft 

DCCPは，UDPではないけど，UDPと同じデータグラム型で輻輳制御を取り入れたプロトコル．  
動画サービスなどの台頭でUDPのトラフィックが増えてきたので，まじめに輻輳を考えないといけなくなってきたみたいな背景．  
DCCPはコネクション志向で3パケットのハンドシェイクを要する．  

Linux gets DCCP - http://lwn.net/Articles/149756/

- Implement SKB fast cloning: Protocols that make extensive use of SKB cloning, for example TCP, eat at least 2 allocations per packet sent as a result. To cut the kmalloc() count in half, we implement a pre-allocation scheme wherein we allocate 2 sk_buff objects in advance, then use a simple reference count to free up the memory at the correct time

パケットバッファを管理するためのskb構造体の複製を最適化する．  
TCPの場合，パケット送信のたびに最低2回のアロケートが必要であり，kmallocの呼び出し回数を半分にするため、2個のskb構造体をあらかじめ同時にアロケートしておく実装．  

- Add netlink connector: userspace <-> kernel space easy to use communication module which implements easy to use bidirectional message bus using netlink as its backend, also a "async connector mode"

netlink はカーネルモジュールとユーザー空間のプロセス間で，情報をやりとりするために用いられる．  
ユーザプロセスからはソケットインタフェースで使用できて，カーネルモジュールからは，カーネルの内部APIがある．  

man netlink - http://linuxjm.sourceforge.jp/html/LDP_man-pages/man7/netlink.7.html


### 2.6.15 (2006/01/03)
http://kernelnewbies.org/Linux_2_6_15

- IPv4/IPv6: UFO (UDP Fragmentation Offload) Scatter-gather approach: UFO is a feature wherein the Linux kernel network stack will offload the IP fragmentation functionality of large UDP datagram to hardware. This will reduce the overhead of stack in fragmenting the large UDP datagram to MTU sized packets

UDPパケットサイズがL2プロトコルのMTU（Maximum Transmission Unit）より多いとき，パケットを分割しなければならないが，これをNICにオフロードする機能．  
TFOはすでに追加されてるのかな．  

- Randomize the port selected on bind() for connections to help with possible security attacks. 

- Add nf_conntrack subsystem: The existing connection tracking subsystem in netfilter can only handle ipv4. 

今までのコネクションのトラッキングはnetfilterによりipv4のみを扱えたが，nf_conntrack により，ipv6にも対応した．  
今までは，L4のパケットをトラッキングするのにipv4とipv6用にそれぞれ重複したコードを書かなければならなかったが，L3を意識せずにL4のトラッキングモジュールを書けるようになった．  

- Generic netlink family: The generic netlink family builds on top of netlink and provides simplifies access for the less demanding netlink users. 

- Add "revision" support for having multiple revisions for each match/target in arp_tables and ip6_tables

- Appropriate Byte Count support (RFC 3465). ABC is a way of counting bytes ack'd rather than packets when updating congestion control

ABCは，ACKによる輻輳ウィンドウの増加を緩やかにする．  
ペイロードなしACK受信時に毎回cwndを増加させると，輻輳ウィンドウの増加率が高すぎる場合があるので，ペイロードつきACKを受信したときのみcwndをインクリメントする．  
デフォルトでは無効となっている．  

man tcp - http://linuxjm.sourceforge.jp/html/LDP_man-pages/man7/tcp.7.html

- IPV6: RFC 3484 compliant source address selection

- Speed up SACK processing: Use "hints" to speed up the SACK processing. Various forms of this have been used by TCP developers (Web100, STCP, BIC) to avoid the 2x linear search of outstanding segments

SACK（Selective Acknowledgement）処理の高速化．  
まだACKを返せてないセグメントを線形探索するコストを避けるために，hints を使う．(どういう hints なのかはよくわからなかった）  

## 2.6.16 (2006/03/20)
http://kernelnewbies.org/Linux_2_6_16

- TIPC (Transparent Inter Process Communication). TIPC is a protocol designed for intra cluster communication.

TIPCは，クラスタ環境におけるアプリケーション間の高速な通信を行うためのプロトコル．  

http://tipc.sourceforge.net
論文: http://kernel.org/doc/ols/2004/ols2004v2-pages-61-70.pdf

- IPv6 support for DCCP

- TCP BIC: CUBIC window growth (2.0). Replace existing BIC version 1.1 with new version 2.0.

BICを改良した輻輳制御アルゴリズムのCUBICが追加された．  
CUBICについては ["CUBIC: A new TCP-friendly high-speed TCP variant"を読んだ] (http://yuuki.hatenablog.com/entry/cubictcp)

- Netfilter ip_tables: NUMA-aware allocation. 

iptablesにおけるメモリ確保をNUMA構成のCPUに最適化できるようになった．  

### 2.6.17 (2006/06/17)
http://kernelnewbies.org/Linux_2_6_17

- iptables support for H.323 protocol, compatibility for 32-bit iptables userspace tools running in a 64-bit kernel

iptablesが動画や音声通信のためのプロトコルであるH.323をサポートした．  

- Add support for Router Preference (RFC4191), Router Reachability Probing (RFC4191) and experimental support for Route Information Option in RA (RFC4191) in IPV6

- CCID2 support for DCCP

CCID2はウィンドウ制御による輻輳制御を行う．  
具体的にはパケットの到着に対してACKを返す．  
ただし，ACKはロスしたパケットを再送するためではなく，ACKのロスを検出することで，ネットワークの輻輳を検知する．  

NS2によるDCCPのシミュレート - http://www.net.c.dendai.ac.jp/~maeda/dccp.html#c14

### 2.6.18 (2006/09/20)
http://kernelnewbies.org/Linux_2_6_18  
このへんからLinuxChangesのドキュメントが充実してきてる．  

- this release is adding two new congestion control algorithms: TCP Veno, which aims to improve TCP performance over wireless networks and TCP "Low Priority"

TCPの輻輳制御にVenoとLow Proorityが追加された．  

- Add Generic Segmentation Offload (GSO), a feature that can improve the performance in some cases, for now it needs to be enabled through ethtool

送信時のパケット分割処理をNICにオフロードするGSOが追加された．ethtoolで有効にできる．  

- remove net.ipv4.ip_autoconfig sysctl

- Add a sysctl (ip_conntrack_checksum) to disable checksumming

ip_conntrack時にチェックサムを無効にできる．  
チェックサム計算そのものを実行しなくなるようなのでパフォーマンスもあがるかもしれない．  

- add a tcp_slow_start_after_idle sysctl that provides RFC2861 behavior if enabled

tcp_slow_start_after_idleを無効にすると，再送タイムアウトの間，idleだった場合にタイムアウトしない．つまり，ハンドシェイク不要．  

### 2.6.19 (2006/11/29)
http://kernelnewbies.org/Linux_2_6_19

- ネットワーク関係ないけど，Ext4入った

- 2.6.19 changes the default congestion algorithm from BIC-TCP to CUBIC, which should have better properties over long links

デフォルトのTCP輻輳制御アルゴリズムがBICからCUBICに変更された．  

- Add a new kernel subsystem, Netlabel, Project site to provide explicit packet labeling services (CIPSO, RIPSO, etc.) to LSM developers. 

Netlabelが追加された．  
SELinuxのような現行のカーネルレベルのセキュリティシステムはローカルリソースをセキュアにすることに着目しており，ネットワーク上の他のマシン間でセキュリティ情報を交換することには関心がない．  
そこで，NetlabelはパケットのIPオプションにラベル付けすることにより，セキュリティ情報を交換する．  

- SCTP: Enable Nagle algorithm by default

輻輳制御アルゴリズムであるSCTPにNagleアルゴリズムがデフォルトで有効になった．  
Nagleアルゴリズムは送信パケット数を減らすために細切れのパケットをまとめて送信する．  

- Replace CHECKSUM_HW by CHECKSUM_PARTIAL/CHECKSUM_COMPLETE

送信パケットのチェックサム計算をNICにオフロードする場合は，状態をCHECKSUM_PARTIALとして，受信パケットがNICにより計算されている場合は，状態をCHECKSUM_COMPLETEとする．  

- In-kernel sockets API for in-kernel users like sunrpc, cifs & ocfs2 etc and any future users

カーネル内のソケットAPIが追加された．  
kernel_bindとかkernel_listenとかが入ってる．  

- Increase number of possible routing tables to 2^32 in IPv6, IPv4 and DECNET

## 2.6.20 (2007/02/05)
http://kernelnewbies.org/Linux_2_6_20


- Node-aware allocation of skbs for the receive path.

受信時におけるskb構造体のアロケートをNUMA-awareに．  
NUMA環境でのパフォーマンスとか気になる．  
[Mainstream NUMA and the TCP/IP stack](http://blogs.msdn.com/b/ddperf/archive/2008/06/10/mainstream-numa-and-the-tcp-ip-stack-part-i.aspx) が参考になりそう．  

- TCP: Restrict congestion control choices for users via a sysctl: the list of allowed congestion control choices is set in ```/proc/sys/net/ipv4/tcp_allowed_congestion_control``` (the list of available congestion control algorithms is at ```/proc/sys/net/ipv4/tcp_available_congestion_control```) 

通常ユーザは```/proc/sys/net/ipv4/tcp_allowed_congestion_control```に書かれた輻輳制御アルゴリズムのみを利用できる．  

- TCP: MD5 Signature Option (RFC2385) support.

TCPのオプションに，MD5によるチェックサムの検証が追加された．  
通常のチェックサムは16ビットしかないので，パケットが改ざんされてもパケットの変更を検知できない可能性があるので，128ビットのMD5であればより安全になる．  
BGPでの利用を想定されている．  

- Netfilter: Add full NAT support for nf_conntrack

nf_conntrackにNATサポートが入って，IRCやFTP，SNMPなどのNATヘルパーモジュールも入った．  

---------

ChangeLog眺めて，コミット眺めて，よくわからない単語を調べるだけで結構勉強になった．  
当時の流行りのプロトコルの実装がどんどん追加されていくのを感じられた．  
特にIPv6対応が目立ってたイメージがある．  

次は Linux 2.6.21〜2.6.38までまとめたい．  

## 参考

- http://kernelnewbies.org/LinuxVersions


[asin:4873115019:image:large]
