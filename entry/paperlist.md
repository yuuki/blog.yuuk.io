---
Title: 研究室ニートの読みたい論文リスト (TCP and GPU) 
Category:
- 論文
- GPU
- Linux
- TCP
Date: 2012-12-09T00:22:38+09:00
URL: http://blog.yuuk.io/entry/paperlist
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/12704830469096306037
---

研究科や研究室という組織についてはあんまりよく思ってはいないけど，研究自体は嫌いではないので，最近徐々に論文読みたい感じになってきている．

TCPまたはGPU関連で読みたい論文リストのメモ．

## TCP

### 2002
- [TCP Servers: Offloading TCP Processing in Internet Servers. Design, Implementation, and Performance](http://www.google.co.jp/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&ved=0CC4QFjAA&url=http%3A%2F%2Fdiscolab.rutgers.edu%2Fsplit-os%2Fdcs-tr-481.pdf&ei=zlLDUKTwBa_ImAXYq4C4Bw&usg=AFQjCNEapg0MVEstKLiPARkS1pJSekpZIA&sig2=99Ps0fu27PTicL6mjF1bZA)

WebサーバにおけるTCP処理をNICにオフロードするための設計と実装と評価．  
SMP環境において専用のネットワークプロセッサを用いるアーキテクチャとクラスタ環境において専用のノードを用いるアーキテクチャの両方を評価  

### 2005
- [CUBIC: A New TCP-Friendly High-Speed TCP Variant](http://www.google.co.jp/url?sa=t&rct=j&q=&esrc=s&source=web&cd=9&cad=rja&ved=0CJEBEBYwCA&url=http%3A%2F%2Fcnds.eecs.jacobs-university.de%2Fcourses%2Fnds-2009%2Ffeyzabadi-cubic.pdf&ei=8zPDUM_OG42UmQWR_YCgAQ&usg=AFQjCNHWwA7WoQxVEd7DIKIAXdOG398_Mg&sig2=UXI43TeehIzxTHZXsu2D3g)

前半部分は読んだ．  
CUBICは高速ネットワーク環境に適したTCP輻輳制御アルゴリズムであり，BIC-TCPを改良したものである．  
CUBICはBICのウィンドウサイズ制御を簡素化し，既存のTCPとの公平性およびRTT（Round Trip Time）公平性を改善している．  
Linux2.6.19以降でデフォルトの輻輳制御アルゴリズムとして採用された．[該当コミット]  (http://git.kernel.org/?p=linux/kernel/git/torvalds/linux-2.6.git;a=commit;h=597811ec167fa01c926a0957a91d9e39baa30e64)

- [Performance Analysis of the TCP/IP Stack of Linux Kernel 2.6.9](http://www.google.co.jp/url?sa=t&rct=j&q=&esrc=s&source=web&cd=2&cad=rja&ved=0CDkQFjAB&url=http%3A%2F%2Fuser.informatik.uni-goettingen.de%2F~kperf%2Fgaug-ifi-tb-2005-03.pdf&ei=P0nDUJ-bCKaBiQeGjIDIDQ&usg=AFQjCNE5eaR92DuZl0L2ZmkDN5YOD4Nx_w&sig2=LRGyAXUgPXwLoSkEDIkq_Q)

LinuxのTCP/IPスタック処理におけるsocket, TCP/UDP, IP and Ethernetの各レイヤーごとのパフォーマンス解析．  
異なるシチュエーションにおけるそれぞれの性能ボトルネックを明らかにする．  

- [Performance Characterization of a 10-Gigabit Ethernet TOE](http://www.google.co.jp/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&ved=0CDEQFjAA&url=http%3A%2F%2Fciteseerx.ist.psu.edu%2Fviewdoc%2Fdownload%3Fdoi%3D10.1.1.62.4534%26rep%3Drep1%26type%3Dpdf&ei=0ErDUP-VB8nOmAXvjYDADA&usg=AFQjCNH-wAGBSTFF9JS96q0J_DN_26aQbg&sig2=fkkb9piY9rZHl0xLXyUyVg)

TCP Offload Engineを有効にしたChelsio T110 10-Gigabitイーサネットアダプタのパフォーマンス評価．  
-- ソケット層のマイクロベンチマークパフォーマンス評価  
-- ソケットインタフェース上のMPI層のパフォーマンス評価  
-- Apacheサーバを用いたアプリケーションレベルのパフォーマンス評価  
10Gbpsのうち7.6Gbpsの性能．  
(TCP Offload EngineとはTCPの一部ないし全ての処理のNIC（上記のイーサネットアダプタなど）にオフロードする仕組みのこと)  

- [Server Network Scalability and TCP Offload](https://www.google.co.jp/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&ved=0CDQQFjAA&url=https%3A%2F%2Fcs.uwaterloo.ca%2F~brecht%2Fservers%2Freadings-new2%2Fusenix05-scalability.pdf&ei=LU_DUKGXGqebmQWAoIC4Bg&usg=AFQjCNFk9s4a1B2Exf6_TGT9nLy6AVu1Wg&sig2=l5demuEA_Mym0AJpU9jWGQ)

I/Oバス経由のデータアクセスやキャッシュミス，割り込みのオーバヘッドなどの処理はCPUコアの増加によるネットワークやI/Oバスの帯域幅のスケーラビリティを低下させる．  
これらの処理に関わる命令を削減するために，TCP Offload Engineを採用した新しいホスト/NIC間のインタフェースを設計し，プロトタイプを実装した．  



### 2006

- [A Measurement Study of the Linux TCP/IP Stack Performance and Scalability on SMP systems](http://dspace.library.iitb.ac.in/xmlui/bitstream/handle/10054/1645/34859.pdf?sequence=3)

Linux2.4および2.6におけるTCP/IPスタックをSMP環境で性能評価．  
（SMPはSymmetric Multiprocessingの略で各コアに対称的に処理を割り振る．つまり，普通のマルチコア環境）  
1TCPコネクションあたり1プロセッサのアーキテクチャが優位性を示す．  
Linux2.4と2.6ではCPUのコストは大差ないが，2.6はカーネルのスケジューリングとロック機構が改良されているので，スケーラビリティに優れている．  

- [NS-2 TCP-Linux: An NS-2 TCP Implementation with Congestion Control Algorithms from Linux](http://www.google.co.jp/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&ved=0CDQQFjAA&url=http%3A%2F%2Fdl.acm.org%2Fft_gateway.cfm%3Fid%3D1190463%26type%3Dpdf&ei=HDLDUI1s5KOIB9W3gZAE&usg=AFQjCNGtxlpl9lrHHEHREvzcPmDGErwVvA&sig2=0cXjRc8J_6kVutBGDE8Usw)

NS2におけるTCP輻輳制御アルゴリズムの設計，実装および評価．  
輻輳制御アルゴリズムの実装はLinux2.6と似ている．  
NS2は有名なネットワークシミュレータでC++で実装されている．  
次期バージョンであるNS3はPythonで実装されているらしいけど，ドキュメントが整ってなくて厳しい感じらしい．  

- [Potential Performance Bottleneck in Linux TCP](http://www.google.co.jp/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&ved=0CDEQFjAA&url=http%3A%2F%2Fciteseerx.ist.psu.edu%2Fviewdoc%2Fdownload%3Fdoi%3D10.1.1.62.4534%26rep%3Drep1%26type%3Dpdf&ei=0ErDUP-VB8nOmAXvjYDADA&usg=AFQjCNH-wAGBSTFF9JS96q0J_DN_26aQbg&sig2=fkkb9piY9rZHl0xLXyUyVg)

これもLinux2.6のTCPスタックのパフォーマンスを数学モデルにより解析．  
カーネルのプリエンプションがネットワーキングシステムに相互に悪影響があることに気づいた．  
ボトルネックを解決するためのソリューションを提案する．  

- [The Need for Asynchronous Zero-Copy Network i/o](http://www.google.co.jp/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&ved=0CDEQFjAA&url=http%3A%2F%2Fwww.kernel.org%2Fdoc%2Fols%2F2006%2Fols2006v1-pages-247-260.pdf&ei=SFTDULzRNsifmQWFy4DIDQ&usg=AFQjCNF928RMtNw0b1h4PmskdukL2pS-Xw&sig2=E4pXiXEPLlnLuOXMkHAW8w)

Red Hat社の中の人の論文．[C10K問題](http://www.kegel.com/c10k.html) で有名な人でもある．  
NICからアプリケーションレベルへデータをコピーするときに一旦カーネルにコピーしてからアプリケーションにコピーする問題のいくつかのソリューションを説明する．  

### 2007

- [THE PERFORMANCE ANALYSIS OF LINUX NETWORKING – PACKET RECEIVING](http://www.google.co.jp/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&ved=0CDYQFjAA&url=http%3A%2F%2Fcd-docdb.fnal.gov%2Fcgi-bin%2FRetrieveFile%3Fdocid%3D1261%3Bfilename%3D132paper.pdf%3Bversion%3D1&ei=Y1bDUPqcNe6KmQWGlYG4Aw&usg=AFQjCNFNeDjVz256xlGlKu6G-siLmq4dAw&sig2=THdVU3NQmEzmyMwwb6QnWg)

高エネルギー物理学の計算のようなグリッドコンピューティングにおいて，ペタバイトレベルのデータを転送する必要がある．  
NICからアプリケーションに渡されるまでのLinuxのパケット受信の特性を解析するための数学モデルを開発．  


### 2008

- [Optimizing TCP Receive Performance](http://www.google.co.jp/url?sa=t&rct=j&q=&esrc=s&source=web&cd=2&cad=rja&ved=0CEEQFjAB&url=http%3A%2F%2Fwww.usenix.org%2Fevent%2Fusenix08%2Ftech%2Ffull_papers%2Fmenon%2Fmenon.pdf&ei=-D_DULvuCoeViAfsloDgBg&usg=AFQjCNFzXEAOk4ihU2ufIBl2hCkOxt8c3w&sig2=db6SBVgEPFClo-nsMiU1lQ)

TCPの受信側に着目したパフォーマンス改善手法の提案．  
もともと主要なボトルネックと言われていたデータコピーやチェックサム計算のような"1バイトあたりの処理"コストから，現在のプロセッサにおけるコネクション管理構造体へのメモリアクセスのような"1パケットあたりの処理"コストにボトルネックがシフトしている．  
"1パケットあたりの処理"コストを削減するためにACKパケットの送信とパケットの結合をオフロードする．  
ハードウェアへのオフロードはせずにソフトウェアのみによるパフォーマンス改善．  
ネイティブのLinuxで45-67%の性能向上，Xenで仮想化されたゲストOSとしてのLinuxで86%の性能向上．  

### 不明
- [Daytona : A User-Level TCP Stack](http://www.google.co.jp/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&ved=0CDEQFjAA&url=http%3A%2F%2Fnms.lcs.mit.edu%2F~kandula%2Fdata%2Fdaytona.pdf&ei=CSzDUOWBKKiYiAekg4CgBQ&usg=AFQjCNHIzEC1ElMdPxW0UuB8JGY2rSiNeg&sig2=Vpiz-uaR0iC9qLrcUPh7hA)

多分2002年ぐらい．  
本来カーネルで実装されているTCP/IPスタックをアプリケーション側で実装．  
ソースコードはGitHubにあった．(https://github.com/jamesbw/tcp-daytona)  

## GPU

### 2009
- [GPU-Accelerated Text Mining](http://www.google.co.jp/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&ved=0CDYQFjAA&url=http%3A%2F%2Fmoss.csc.ncsu.edu%2F~mueller%2Fftp%2Fpub%2Fmueller%2Fpapers%2Fepham09.pdf&ei=MDvDUPL7MI-ciAf9oYHQDQ&usg=AFQjCNErWdRf7K49plaYcfMucneB5hoWGg&sig2=7IsJxgFbznnrQmfr-kt8Ug)

テキスト検索アルゴリズムをGPUで高速化．  


### 2010
- [A GPU Accelerated Storage System](http://www.google.co.jp/url?sa=t&rct=j&q=&esrc=s&source=web&cd=2&cad=rja&ved=0CEEQFjAB&url=http%3A%2F%2Fwww.ece.ubc.ca%2F~samera%2Fpapers%2FStoreGPU-HPDC10.pdf&ei=JCrDUJvtD6-YiAeEo4CICQ&usg=AFQjCNHqe81QbPAwwmLo7Y2B023WvyynWw&sig2=MTFAPy0NuiKBvHsAFZZuoA)

ストレージシステムにおけるハッシュの計算をGPUにオフロードする話．  
最近のストレージは，データの重複を排除するために，データをブロックに分割し，各ブロックに対してハッシュ値を計算しておき，ハッシュ値を比較することにより，データの重複を検出する．  

- [Debunking the 100X GPU vs. CPU Myth: An Evaluation of Throughput Computing on CPU and GPU](http://www.google.co.jp/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&ved=0CDkQFjAA&url=http%3A%2F%2Fwww.hwsw.hu%2Fkepek%2Fhirek%2F2010%2F06%2Fp451-lee.pdf&ei=GjXDUNWFFq2kiAeX14D4Ag&usg=AFQjCNGyVKIPL6kM9ohlCdWT8L_FSRJSPw&sig2=tNSag4MS5NQAtuS0th-dwA)

GPU使えばCPUの100倍の性能でるよとか言ってるけど，CPU実装をちゃんと最適化すれば数倍の差程度でしかないよ，みたいな感じ．  
GTX280とCorei7 970との比較．  

- [Dynamic Load Balancing on Single- and Multi-GPU Systems](http://www.google.co.jp/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&ved=0CDYQFjAA&url=http%3A%2F%2Fcacs.usc.edu%2Feducation%2Fcs653%2FChen-LoadBalanceGPU-IPDPS10.pdf&ei=3zXDUNiTBe2iiAfvnYHoBA&usg=AFQjCNFv0Fbic3dm_1u0pyYOcQuuqizvrQ&sig2=HNksKbtLne-rv89roQlGQg)

単一または複数GPU構成のシステムにおけるタスクの負荷分散．  
CUDA APIレベルよりももっと抽象的なAPIを用いていいかんじにタスクを分散する．  
CUDAのスケジューラの改良的な感じ．  

### 2011
- [Augmenting Operating Systems With the GPU](http://www.google.co.jp/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&ved=0CDIQFjAA&url=http%3A%2F%2Fwww.cs.utah.edu%2F~wbsun%2Fkgpu.pdf&ei=SD7DUPgGj56IB8DEgbAJ&usg=AFQjCNFh8nHHhdyItL58t6C7JgoMsbjRAA&sig2=68HzTy3u0kSBdnovqzCTYg)

OSのカーネルのいくつかの機能をGPUにより高速化できる．  
OSのカーネルの補助的なプロセッサとしてGPUを使用するためのフレームワークを提案し，Linuxにおけるプロトタイプを示す．  

### 2012
- [Efficient Data Management for GPU Databases](http://www.google.co.jp/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&ved=0CDYQFjAA&url=http%3A%2F%2Fwww.eecis.udel.edu%2F~cavazos%2Fcisc879%2Fpapers%2Fdatamanagement.pdf&ei=5TfDUMSGEMefiQeR3YHQCA&usg=AFQjCNFCzZOeFCWdttLmo0Zd7oXFuKSlTw&sig2=8hxRBlTf1_G3vsSUyzPxUQ)

RDBMSにおけるクエリをCPUとGPUの両方で実行できるデータベースフレームワークの実装．  
GPUメモリでのキャッシュが効くようにメモリマッピングを工夫して，GPUメモリの容量を超えるデータに対しても高速化できることを示す．  
マルチコアCPUと比較して4倍から8倍の性能．  

</br>
</br>

TCPとGPUの論文を輪講してると，カーネルという言葉がOSのカーネルなのかGPUプログラムの実行単位のことなのかを他人に説明するのがめんどくさくなってくる．  
