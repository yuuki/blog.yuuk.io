---
Title: "Kansai.pmでORMのパフォーマンスチェッカの構想についてLTしてきた"
Category:
- Perl
- 日記
Date: 2013-02-24T01:32:55+09:00
URL: http://blog.yuuk.io/entry/kansaipm15
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/6435922169449341984
---

[http://www.zusaar.com/event/476003:title=Kansai.pm #15]に参加してきた．　　

JPA派遣講師として来ていただいた[http://www.slideshare.net/yusukebe/web-16710062:title=@yusukebeさんの話]が今回の目玉だった．

BoketeのValidationの話聞いて，そういえばPerlのValidationを真面目に考えたことなかったなと思って，FormのValidationにはForm::Validator::Lite，ModelのValidationにはData::Validatorというところだけ覚えておいてあとは自分で試してみる．

id:shiba_yu36 さんが作ってるCinnamon、普通に便利そうだし，Capもよくわからずに適当に使ってる感があるからCapにこだわってないし使ってみたい．
次回のKyoto.pmを4月か5月くらいにやるみたいな感じらしい．参加します．

LT枠が空いていてやりますといっていたけれど，前日までネタを作ってなくて，とりあえずプロファイラ便利ツールみたいなのに興味あったから，前日から作り始めた分と構想についてしゃべった．

単純なテーブルに対して単純なクエリ発行したときに，DBIからそのままSQL叩く場合とTengのRowクラスでラップしない場合とで実行時間はそんなに差がないということがわかったりした．
ちなみにRowクラスでラップした場合の実行時間は，ラップしない場合と比較して2倍ほど遅かった．

<script async class="speakerdeck-embed" data-id="500cbb305fb00130abc822000a8e850c" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>

Perl，一般的にはもうそんなに流行らんだろみたいなテンションだけど，今日は普通に盛り上がってたし，Perlコミュニティ力感じた．

yusukebeさん、普通に気さくな感じだったし普通にしゃべっていただいた．

あと，Mixiの@goccy54さんが１人で作ったというコピペ検出器やばかった． [https://github.com/goccy/p5-Compiler-Tools-CopyPasteDetector:title]  
Perl5の言語処理系つくれるとかやばすぎるし，Mixi社の技術力の高さを垣間見た．  
Mixiの中の話もいろいろ教えていただいて参考になった．


今日こういう雰囲気で激しい感じだった．
[https://twitter.com/y_uuki_/status/305219671911723008:embed#Girlsやめろ！ #kansaipm]
