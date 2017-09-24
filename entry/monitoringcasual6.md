---
Title: "ヘビーなGraphite運用について"
Category:
- Graphite
- Monitoring
Date: 2014-06-13T09:30:00+09:00
URL: http://blog.yuuk.io/entry/monitoringcasual6
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/12921228815726015778
---

[http://www.zusaar.com/event/11447004:title="Monitoring Casual Talks #6"]に参加して、「ヘビーなGraphite運用」についてしゃべってきた。
Graphite ここ数ヶ月ずっと運用してて、そこそこのリクエスト数さばけるようになるまでと冗長化の話をだいたいしてた。
Graphiteのパフォーマンス・チューニングで結構苦労してて、@sonots さんが発表されてた[https://github.com/sonots/growthforecast-tuning:title="GrowthForecast/RRDtool チューニング秘伝の書"] がすごい参考になった。（Graphite(whisper) のデータ構造と RRdtool のデータ構造はよく似ている。）
fadvise(2)とか知らなかった。
ぜひ試してみたい。

## スライド

<div style="width: 80%;">
<script async class="speakerdeck-embed" data-id="a0b2b400d4ae01312e0e2a4d531fd829" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>
</div>

結構口頭で補足してた。Graphite 秘伝の書書きたい。

## 感想
今回の勉強会、かなり刺さる内容が揃っててよかった。
形式が30~100人くらいいて、数人の発表者がプレゼンするっていう感じじゃなくて、14人くらいで全員発表とかいう形式だったので、カジュアルに議論とかできてよかった。
あと、結構 Mackerel について言及していただいて関係者としては緊張感あった。
Nagios とか Zabbix の話は意外と少なめで Sensu とかあと、Docker のメトリクス収集とか、Auto Scale時のモニタリング方法とかの議論があって、みんなモダンなことにチャレンジにしててすごい。
また参加したい。

関係ないけど、今週 Docker 1.0 がリリースされて、Dockerそのもの + 周辺ツールが充実してきた感があるので、今回と同じような形式の Docker Casual とかあったらよさそう。

会場の提供/準備をしていただいた @takus さん、@sonotsさん ありがとうございました。


[https://twitter.com/y_uuk1/status/477014251291160576:embed#東京体調悪い]

[https://twitter.com/y_uuk1/status/477019921441120258:embed#40万近い http://t.co/MwOJZRXxPL]

[https://twitter.com/y_uuk1/status/477020934558085121:embed#40万たくさんある http://t.co/uE3GN1rN0N]

[https://twitter.com/y_uuk1/status/477022045197197312:embed#ヒカリエ入ってお金の匂いしてきて体調悪くなった http://t.co/vltul5ZnMq]
