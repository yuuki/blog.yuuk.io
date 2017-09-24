---
Title: "Linuxのブロックデバイスレベルで実現するrsyncより高速な差分バックアップについて"
Category:
- Kernel
- Linux
- 論文
Date: 2014-05-26T09:30:00+09:00
URL: http://blog.yuuk.io/entry/dsync-paper
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/12921228815724925853
---

社内で論文輪読会みたいなことやってて、そこで紹介した論文の内容についてです。

最近、Graphite に保存しているデータのバックアップ（データ同期）に rsync 使ってて、かなり遅いので困ってた。
[https://www.usenix.org/conference/lisa13:title=LISA] っていう 大規模システム、sysadmin 系のカンファレンスがあって、ここから論文探してたら、ちょうど巨大データの高速バックアップの実装の話があったので読んでみた。

# 論文概要

<strong>dsync: Efficient Block-wise Synchronization of Multi-Gigabyte Binary Data</strong>
- https://www.usenix.org/conference/lisa13/technical-sessions/presentation/knauth
- Thomas Knauth and Christof Fetzer, Technische Universität Dresden
- In Proceedings of the 27th Large Installation System Administration Conference (LISA ’13)

GB単位のデータだと、rsyncがとにかく遅い。
rsync はブロック分割されたデータのハッシュ値の比較により差分検知して、ネットワーク転送するデータ量をとにかく減らそうとしている。
その反面、同期させたいデータサイズに対してハッシュ値計算のCPU時間は線形に増加する。
さらに、ハッシュ値計算のために全データブロックを読み出す必要があり、I/Oコストも高い。
バックアップ時に、差分を事後計算しようとすると、どうしてもこうなる。
そこで発想を変えて、カーネルのブロックデバイスレベルで、更新のあったブロックを常に記録（トラッキング）しておき、バックアップ時にフラグのあったブロックだけを転送することにする。

発想自体はシンプルだけど、既存の device mapper の Snapshot 機能だけでは実現できなくて、パッチをあてる必要があったのがやや難点。
カーネルのメインラインに取り込まれてほしい。

実装はこちら。 https://bitbucket.org/tknauth/devicemapper/
Linuxカーネル 3.2 の device mapper モジュールにパッチを当てるような感じになってそう。

# 追記 2014/05/26 16:10 

それ ZFS でできるよと DRBD でいいのでは系のコメントをいくつかいただきました。
ちなみに論文の本文には両者に関して言及があります。

<blockquote class="twitter-tweet" lang="ja"><p>zfs send | zfs receive # ですでに実現されている&gt;id:y_uuki / “Linuxのブロックデバイスレベルで実現するrsyncより高速な差分バックアップについて - ゆううきブログ” <a href="http://t.co/D6xl1HUYTe">http://t.co/D6xl1HUYTe</a></p>&mdash; Dan Kogai (@dankogai) <a href="https://twitter.com/dankogai/statuses/470812368197271552">2014, 5月 26</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

>
"どうせブロックデバイス使うなら実績のあるDRBDでいいんじゃないかと思う。非同期モードで。"
http://b.hatena.ne.jp/n314/20140526#bookmark-196769866

## ZFS について

ブロックデバイスレベルで実現できてうれしい点は、ZFS など特殊なファイルシステムに依存しないことだと思います。
ext3 のような<del>壊れにくい</del>Linux環境で実績と運用ノウハウがある ファイルシステムを使いつつ、差分バックアップできるのは実運用上でうれしいことが結構あると思います。
あとは、ZFS で定期的に差分バックアップとるときに、スナップショット分のディスクサイズオーバヘッドが気になります。（これは論文にも比較データはないのでどれほどかわかりませんが）
ちなみに dsync のオーバヘッドは、10 TiB データに対して、320 MiB 程度のようです。（ただしディスクではなくメモリオーバヘッド）

## DRBD について

そもそも非同期モードだろうが同期モードだろうが、DRBD はオンラインなレプリケーションには使えても、定期バックアップに使うものではない気がします。
例えば、プライマリノードで、間違えて重要なファイルを rm してしまったときに、即座にセカンダリノードにその rm の結果が伝播してしまうので、データが壊れた時に復旧するためのバックアップ用途には向いてない気がします。

何か勘違いがありましたらご指摘いただけると幸いです。

# スライド

<script async class="speakerdeck-embed" data-id="a5f9c990c4cd01312236661bc0325f6c" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>

Keynote のテンプレートは、[https://github.com/sanographix/azusa-keynote:title=Azusa] にお世話になっています。

# LISA の他の論文

LISA はオペレーションエンジニアにとって興味深い論文が結構ある。
一例をあげてみる。
今回のように実装が公開されてたいたりするので、あんまりアカデミック感がなくてよい。

- Live Upgrading Thousands of Servers from an Ancient Red Hat Distribution to 10 Year Newer Debian Based One
  - 2013
  - Marc Merlin, Google, Inc.
  - https://www.usenix.org/conference/lisa13/technical-sessions/presentation/merlin

- Bayllocator: A Proactive System to Predict Server Utilization and Dynamically Allocate Memory Resources Using Bayesian Networks and Ballooning
  - 2012
  - Evangelos Tasoulas, University of Oslo; Hârek Haugerud, Oslo and Akershus University College; Kyrre Begnum, Norske Systemarkitekter AS
  - https://www.usenix.org/conference/lisa12/technical-sessions/presentation/tasoulas

- Extensible Monitoring with Nagios and Messaging Middleware
  - 2012
  - Jonathan Reams, CUIT Systems Engineering, Columbia University
  - https://www.usenix.org/conference/lisa12/technical-sessions/presentation/reams

- On the Accurate Identification of Network Service Dependencies in Distributed Systems
  - 2012
  - Barry Peddycord III and Peng Ning, North Carolina State University; Sushil Jajodia, George Mason University
  - https://www.usenix.org/conference/lisa12/technical-sessions/presentation/peddycord

# 所感
たまにサーバ管理ツールとか作ってて、サーバ負荷の未来予測とかサービス間のトラッフィク依存関係（AサービスがBサービスのDB引いてるとか）を可視化できたらいいねとか言ってたりしてた。
今回、LISAの論文眺めてたらちょうどそういうのあって驚きがあった。
研究の世界はできないことができるようになる系統の技術において先を行っていて、ブログとかウォッチしているだけでは追いつけないので、たまに論文もよみたい。

カーネルのI/Oシステム周りの知識に乏しいので、詳解Linuxカーネルを読みつつ知識を補填していた。

[asin:487311313X:detail]
