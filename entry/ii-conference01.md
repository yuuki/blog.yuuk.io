---
Title: "Docker 使ってたらサーバがゴミ捨て場みたいになってた話 #immutableinfra"
Category:
- Docker
- Linux
- ImmutableInfra
Date: 2014-03-26T08:47:58+09:00
URL: http://blog.yuuk.io/entry/ii-conference01
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/12921228815720666047
---

[http://atnd.org/events/47786:title:bookmark]

でLTしてきた。

<div style="width:80%">
<script async class="speakerdeck-embed" data-id="0a5ae5e096770131f0373e762bb67ced" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>
</div>

内容はきれいにゴミを捨てましょうという話以上のものは特にない。

背景の説明が少し雑だったので補足すると、Jenkins のジョブスクリプトで、git push する度に docker run していたら ゴミがどんどんたまっていったという感じ。
1 push あたり、アプリコンテナ、DBコンテナとか合わせて3コンテナぐらい起動してるから開発が活発だと、どんどんゴミがたまる。
さらに補足すると、Device mapper がらみのゴミは、aufs 使うとかなり解決できそうな感じはしてる。
(Device mapper だとブロックデバイスレベルでイメージ差分を表現するので、デバイス毎(差分)毎に mount が走るみたいな実装になってるけど、aufs だとファイルシステム単位で複数のディレクトリを束ねてマウントするみたいなことができるので、無駄なマウントが走りにくそう。多分。)

Disposable Infrastructureを特にコンテナ型仮想化技術を使って実現しようとする場合は、ゴミがどれくらいできるのかは結構重要な指標なんじゃないかと思う。
(ゴミがひどいから枯れてるハイパーバイザ型仮想化でやるという選択もあるかもしれない)

バッドノウハウがたまったり、Docker 自体が安定してきたので、最近は rpm/deb パッケージのビルドを Docker on Jenkins でやらせるようにして開発効率をあげたりしてる。

ともあれ、今現在ゴミ掃除にしか興味がなくなってる。

効率よくゴミ掃除するために、Docker の内部実装の勉強してて、そういう話をコンテナ型仮想化勉強会とかいうやつでしゃべるかもしれない。

[http://atnd.org/events/46446:title]
