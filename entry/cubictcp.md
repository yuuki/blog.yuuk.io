---
Title: "\"CUBIC: A new TCP-friendly high-speed TCP variant\"を読んだ  "
Date: 2012-12-29T00:07:45+09:00
URL: http://blog.yuuk.io/entry/cubictcp
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/12704830469097005476
---

Linux2.6.19以降でデフォルトのTCP輻輳制御アルゴリズムとなった((http://git.kernel.org/?p=linux/kernel/git/torvalds/linux-2.6.git;a=commit;h=597811ec167fa01c926a0957a91d9e39baa30e64))CUBIC-TCPの提案論文(( I. Rhee and L. Xu, "CUBIC: A new TCP-friendly high-speed TCP variant", In Proceedings of PFLDnet, 2005.))の前半部分についてまとめてみた．


文中に出現する「ウィンドウ」は特に断りがない限り，TCP輻輳ウィンドウを指すものとする．

**CUBIC-TCPの概要
CUBIC-TCPは高速ネットワーク環境に適したTCP輻輳制御アルゴリズムであり，BIC-TCP((L. Xu, K. Harfoush, and I. Rhee, "Binary increase congestion control for fast long-distance networks", in Proceedings of IEEE INFOCOM, 2004.))を改良したものである．
CUBICはBICのウィンドウサイズ制御を簡素化し，既存のTCPとの公平性およびRTT（Round Trip Time）公平性を改善している．
具体的には，CUBICは最後のパケット廃棄が発生してからの経過時間を基にして，リアルタイムにウィンドウサイズを制御する．
その結果，RTTを輻輳制御の指標としないため，RTTが大きいTCPコネクションとRTTが小さいTCPコネクションが混在していても，公平性を保つことができる．
ここでのRTT公平性とは，全てのTCPコネクションのRTTを等しくするという意味ではなく，物理的に遠いノード間の通信や帯域幅の小さいリンクを経路とする場合に輻輳制御を行わないという意味である．
また，既存とのTCP公平性とは，TCP Renoのようなパケット廃棄が発生するまでウィンドウサイズを増加し続けるようなプロトコルと競合した場合に，新しいTCPのスループットがRenoのスループットと等しくするという意味である．

CUBICでは，TCPの輻輳指標をウィンドウサイズではなく輻輳している期間，すなわち連続した2つのパケット廃棄発生時間の差により定義するべきであると考えられている．
CUBICの主な特徴はウィンドウサイズ増加関数がリアルタイムに定義されていることであり，その結果，ウィンドウサイズの増加はRTTに依存しない．
CUBICの輻輳期間はパケット廃棄率のみにより決定される．
TCPのスループットは，RTTだけでなく，パケット廃棄率により定義されるため，CUBICのスループットはパケット廃棄率のみにより定義される．
したがって，パケット廃棄率が高いかつRTTが小さい状況において，たとえRTTが小さくてもCUBICはウィンドウサイズを上述のscalableモードのように増加させない．
さらに，ウィンドウ増加関数はRTT独立であるため，他の輻輳制御アルゴリズムで動作するコネクションのRTTが小さくなり，ウィンドウサイズが増加したとしても，CUBICのRTT公平性は保証される．


** BIC-TCPの概要
CUBICはBICを改良したものである．したがって，CUBICの詳細について述べる前に，BICの概要をまとめる．

BIC以前に提案されてきたHSTCPやSTCPのようなTCP輻輳制御アルゴリズムは既存のTCPとの公平性と帯域幅のスケーラビリティを改善してきた．
ここで，帯域幅のスケーラビリティは帯域幅の増加に応じたスループットの増加率を意味する．
高速ネットワーク環境において，HSTCPやSTCPは帯域幅を最大限に利用している間，改善される前のアルゴリズムの帯域を不当に消費する問題がある．
そこで，BICには新たな制限としてRTT公平性が導入された．
HSTCPやSTCPのようなアルゴリズムは，ウィンドウサイズが増加するにつれてウィンドウサイズ増加率が増加するため，RTT公平性を損なう．
特に，Tail Dropバッファをもつルータ上で複数のコネクションのパケットが同時に廃棄されるときに，一方のコネクションがLoss-basedな場合にRTT公平性が損なわれる．
一方，BICはウィンドウ増加関数を示した図1のように，additive increaseおよびbinary search increaseという2つのウィンドウ増加フェイズを導入した．
ウィンドウサイズが増加したとき，additive increaseが高いスケーラビリティだけでなくRTT公平性を保証する．
ウィンドウサイズが小さいとき，binary search increaseが既存のTCPとの公平性を保証する．

[f:id:y_uuki:20121228232524j:plain]
<center>図1: BIC-TCPウィンドウ増加関数</center>

しかし，BICは高速・高遅延ネットワーク環境ではRTT公平性および高いスループットを保ちつつ動作するが，RTTの小さいネットワークや低速ネットワーク環境においては前節で述べたように帯域幅を不当に消費する問題がある．
さらに，複数のウィンドウ増加フェイズが必要であるため，プロトコルの解析が複雑になる．


**CUBIC-TCPの詳細
CUBIC-TCPのウィンドウ増加関数について説明する．

CUBICの増加関数は，BICの増加関数に非常に似ている．
CUBICはBICのウィンドウ制御を単純かつ高度化するように設計されている．
具体的には，CUBICの増加関数は，式(1)で定義される．

[tex:W_{cubic}=C(t - K)^3+W_{max}] (1)

C，tおよび[tex:W_{max}]はそれぞれscaling factor，最後にパケット廃棄が発生した時点からの経過時間および最後にパケット廃棄が発生した時点のウィンドウサイズである．
さらに，Kは式(2)で定義される．

[tex:K=\sqrt\[3\]{\beta W_{max} / C}] (2)

[tex:\beta]は増加係数である．つまり，ウィンドウ増加量は[tex:\beta W_{max}]である．

図2にCUBICのウィンドウ増加関数を示す．

[f:id:y_uuki:20121228232525j:plain]
<center>図2: CUBIC-TCPウィンドウ増加関数</center>

パケット廃棄を検出したとき，CUBICはウィンドウサイズを減少させる．
減少前のウィンドウサイズを[tex:W_{max}]とする．
減少後は速やかに[tex:W_{max}]に近づくようにウィンドウサイズを増加させる．
[tex:W_{max}]の近傍で，ウィンドウの増加はほぼ0となる．
さらに，CUBICはウィンドウサイズをより大きするために，max probingフェイズに入る．
max probingでは，直線[tex:W_{cubic}=W_{max}]に対称的な増加を行う．
つまり，最初の増加率は小さく，[tex:W_{max}]から離れるほど増加率は大きくなる．
[tex:W_{max}]近傍において増加率が小さいため，プロトコルの安定性を高め，[tex:W_{max}]から離れたときの高い増加率が帯域幅のスケーラビリティを保証する．

この関数はウィンドウ増加率は経過時間であるtに依存しているため，高いRTT公平性を実現している．
