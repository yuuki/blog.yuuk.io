---
Title: " TCP Performance Re-Visitedを読んだ"
Category:
- 論文
- Linux
- TCP
Date: 2012-11-24T21:51:36+09:00
URL: http://blog.yuuk.io/entry/2012/11/24/_TCP_Performance_Re-Visited%E3%82%92%E8%AA%AD%E3%82%93%E3%81%A0
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/12704830469095894001
---

2003年の論文．Linux2.4のTCPスタック実装についてのパフォーマンス測定と解析．
LinuxのTCP実装に関するちゃんとした測定はまだ誰もやってなくて，我々がちゃんとした測定をする，みたいな感じの一文が5箇所くらいあって，意識高い感じだった．

##Abstract
現行のネットワークアダプタとプロセッサにおけるLinux2.4のTCPスタック実装のパフォーマンスについて詳細な測定と解析を行う．
我々は，TCPパフォーマンスにおけるCPUスケーリングとメモリバスの影響について記述する．
CPUの速度とメモリの帯域幅が増加するにつれて，TCPのパフォーマンスに関して一般的に受け入れられている見解があてにならなくなってきている．
以前より抱かれていたTCPパフォーマンス信仰の詳細な検査と説明が提供されており，我々はこれらの憶説と経験説が現行の実装にはあてはまらないケースを明らかにする．
アーキテクチャの主要な変更が採用されない限り，1GHz/1Gbpsの経験則に頼り続けるのは困難であると我々は結論づけた．

##Slide
<iframe style="border:0; padding:0; margin:0; background:transparent;" mozallowfullscreen="true" webkitallowfullscreen="true" frameborder="0" allowtransparency="true" id="talk_frame_24851" src="//speakerdeck.com/embed/f15061e018600130081322000a1d8a59" width="600" height="401"></iframe>

##Reference
- Annie P. Foong, Thomas R. Huff , Herbert H. Hum , Jaidev P. Patwardhan,Greg J. Regnier, ISPASS '03 Proceedings of the 2003 IEEE International Symposium on Performance Analysis of Systems and Software.
