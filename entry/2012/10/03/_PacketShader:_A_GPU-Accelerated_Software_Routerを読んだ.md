---
Title: " PacketShader: A GPU-Accelerated Software Routerを読んだ"
Category:
- GPU
- 論文
Date: 2012-10-03T21:42:30+09:00
URL: http://blog.yuuk.io/entry/2012/10/03/_PacketShader%3A_A_GPU-Accelerated_Software_Router%E3%82%92%E8%AA%AD%E3%82%93%E3%81%A0
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/12704591929890960493
---

論文のPDFは[http://an.kaist.ac.kr/~sangjin/pub/sigcomm2010_packetshader.pdf:title=PacketShader: A GPU-Accelerated Software Router]．

ホームページは [http://shader.kaist.edu/packetshader/:title]．


ソフトウェアルータの処理をGPUにやらせるという話．
IPv4とかIPv6のルーティング，IPSecやOpenFlowの暗号化処理などをGPUで高速化したらしい．
さらに，LinuxカーネルのTCPスタック処理において，パケットが到着する度に毎回バッファを確保したりして効率が悪いので．その辺を解決した独自のパケットI/O Engineを実装しててすごい．
GPUにはあまり向いていないとされている分野に対して，なんとかして高速化したよというのがこの研究の貢献な感じがする．

詳しくは以下．

<iframe src="http://www.slideshare.net/slideshow/embed_code/14572104?hostedIn=slideshare&page=upload" width="476" height="400" frameborder="0" marginwidth="0" marginheight="0" scrolling="no"></iframe>

CUDA5とかKepler2とかを見る限り，NVIDIAのGPUはどんどん汎用化していく感じなので，今まで「それ、GPUにやらせるの？」みたいな分野にGPUを使っていくのが使っていくのが今後流行るのかもしれない．
