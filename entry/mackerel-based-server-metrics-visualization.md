---
Title: "Mackerel を使ったサーバメトリクス可視化の背景っぽいやつ #可視化"
Category:
- Mackerel
- Graphite
Date: 2014-06-05T11:30:00+09:00
URL: http://blog.yuuk.io/entry/mackerel-based-server-metrics-visualization
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/12921228815725533981
---

[http://www.zusaar.com/event/7437003:title:bookmark]

可視化ツール現状確認会で Mackerel-Based Server Metrics Visualization とかいう話をしました。
僕はアルバイト入社したときからサーバ管理ツールにずっと関わってて、周辺ツールとかもウォッチしてて、そういう流れで Mackerel がどういう位置づけにあるかみたいな話だったはず。

かつて自作社内サーバ管理ツールで、RRDtool の最悪の引数をURLクエリで互換するようなパーサ作ってたりして、異常な努力をしていましたが、ここ半年くらいで、モダンな Graphite とか Sensu をサーバ管理ツールと組み合わせようとしていて、気づいたら https://macekrel.io っていうサービスができてたという感じです。
Graphite と Sensu(Collectd) を導入しようとそれはそれで運用が思ったより面倒で、パフォーマンスがでないとかモニタリング用のサーバを用意したくないというようなことがあってかけた労力に見合わないという感じなら普通に Mackerel 使うと便利。
あと、サーバのIPアドレスとかホスト情報とサーバメトリクスビューが分散している場合（Munin と AWS consoleとか）に、統合管理するために Mackerel 使ってもらうのも便利。

ちなみに読み方はマケレルではなくてマカレル（英語読みはマッカレル？）っぽい。
なんでもいいけどとにかく RRDtool を使うべきではないと思います。

## 資料

軽くロードマップみたいなものも書かれています。
もうちょっと突っ込んだ使い方とか何ができるのかみたいな話は来週の[http://www.zusaar.com/event/11447004:title=モニカジ]で喋れたら良さそうです。

<div  style="width: 80%;">
<script async class="speakerdeck-embed" data-id="82b30a90ce3501316bf71e853270e897" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>
</div>

会場の提供、準備、運営をしていただいた Voyage Groupの皆様ありがとうございました。

## インターネットの様子

[https://twitter.com/suzu_v/status/474132320970997761:embed#"RRDToolっていう残念な" #可視化]

[https://twitter.com/shoichimasuhara/status/474132346023604224:embed#RRDtool残念言うなｗ #可視化]

[https://twitter.com/hid_tgc/status/474132347546136576:embed#RRDtoolは残念なやつ #可視化]

[https://twitter.com/takus/status/474132383461933057:embed#RRDTool はひたすら厳しいらしい #可視化]

[https://twitter.com/sonots/status/474132462025441280:embed#RRDtool キビシーーーーーー #可視化]

[https://twitter.com/hid_tgc/status/474132600575893504:embed#HatenaのMackerelはPerlからScalaに。デーモンはgolang #可視化]

[https://twitter.com/repeatedly/status/474133477164453888:embed#fluent-plugin-mackerel！ #可視化 #fluentd]

[https://twitter.com/kenjiskywalker/status/474133635558146048:embed#架空のサービスのグラフ見てた。 #makerelio 便利っぽい #可視化]

[https://twitter.com/kenjiskywalker/status/474143373909958657:embed#VOYAGE GROUPのキラキラおねーさんたちが目の前を行き来していてそっちに集中している]
