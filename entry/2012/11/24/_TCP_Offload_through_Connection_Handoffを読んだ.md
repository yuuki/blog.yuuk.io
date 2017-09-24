---
Title: " TCP Offload through Connection Handoffを読んだ"
Category:
- 論文
- TCP
Date: 2012-11-24T21:27:06+09:00
URL: http://blog.yuuk.io/entry/2012/11/24/_TCP_Offload_through_Connection_Handoff%E3%82%92%E8%AA%AD%E3%82%93%E3%81%A0
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/12704830469095892741
---

最近，TCP Offload Engine周りの論文を読んでる．

##Abstract
本論文ではOSとNIC間のコネクションハンドオフ・インタフェースを提案する．
このインタフェースを使用することにより，一部のTCPコネクションをホストCPUで処理しつつ，残りのTCPコネクションをNICに対してオフロードできる．
オフローディングにより，ホストCPU上におけるパケット処理のために必要な計算資源とメモリバンド幅を削減できる．
しかし，フルTCPオフローディングを使用するならば，NICの計算資源およびメモリ資源が有限であるため，パケット処理の量とコネクションの個数が制限される．
ハンドオフを使用することにより，OSはNICをオーバーロードすることなくNICを最適化するために，オフロードするコネクション数を制限する．
ハンドオフはアプリケーションに対して透明であり，OSはNICにコネクションをオフロードするかまたはそれらをNICから取り戻すかどうかをいつでも選択できる．
修正版FreeBSDベースのプロトタイプによると，ハンドオフがホストCPUの命令数とキャッシュミスを削減することがわかった．
結果として，パケット処理に消費されるCPUサイクル数が16%（84%まで）削減した．
シミュレーションの結果，短命なコネクションにもかかわらず，ハンドオフがWebサーバのスループトットを15%削減した．

##Slide
<iframe style="border:0; padding:0; margin:0; background:transparent;" mozallowfullscreen="true" webkitallowfullscreen="true" frameborder="0" allowtransparency="true" id="talk_frame_24850" src="//speakerdeck.com/embed/18eba9c0185b01303f571231392da12d" width="600" height="401"></iframe>

##Reference
- Hyong-youb Kim and Scott Rixner Rice University, "TCP Offload through Connection Handoff", In Proceedings of EuroSys 2006.
