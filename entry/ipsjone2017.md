---
Title: 高度に発達したシステムの異常は神の怒りと見分けがつかない - IPSJ-ONE2017
Category:
- 日記
Date: 2017-03-21T23:48:00+09:00
URL: http://blog.yuuk.io/entry/ipsjone2017
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/10328749687229412687
---

名古屋大学で開催された[IPSJ-ONE2017](http://ipsj-one.org/) で登壇しました。
IPSJ-ONEというのは、情報処理学会の各研究会から選ばれた日本の若手トップ研究者17人が集まり、自身の研究を高校生でもわかるように発表するイベントです。
1000人ぐらい入る講堂で、しかもニコニコ生放送で配信されるというとても大掛かりなイベントです。

ちなみに、昨年は、同じ研究会からの推薦で、 id:matsumoto_r:detail (matsumotory) さんが登壇されています。 [http://hb.matsumoto-r.jp/entry/2016/03/15/163320:title:bookmark]

# 発表

「高度に発達したシステムの異常は神の怒りと見分けがつかない」という、一見何の話かわからないやばそうな話なんですが、大真面目に話してきました。

スライドを以下に公開しています。ただ、スライドだと何の話をしているかおそらくわからないので、ニコ生のタイムシフト試聴でたぶん一週間くらいは動画をみれるようです。 http://live.nicovideo.jp/watch/lv289955409#6:40:12 (その後におそらくアーカイブされるはず？)

<div style="width:65%">
<script async class="speakerdeck-embed" data-id="7c9690c9cf9d4ff5962733dda495a43d" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>
</div>

IPSJ-ONEの趣旨として、登壇者個人の成果や考えを表に出すことを求められており、実際には会社やチームでやっていることの中で、僕個人がやっていることについて話をしたつもりです。

5分の発表なので、10秒レベルで無駄を削って、エッセンスのみを抽出しました。特に、一般の方がわかるような内容であることに最重視しており、専門用語を使わないように徹底しました。

## 内容と補足

補足を追加した内容を以下に書き留めておきます。

インターネットのシステムは、24時間365日動き続けることが求められている一方で、人手による運用でカバーしている部分がたくさんあります。
これをどうにかしたいと思って、全自動化へ向けて頑張るんですが、全然うまくいきません。
なぜうまくいかないのか。それは、自動化に対する恐れがあると考えています。
実際に現場では、このオペレーションを自動化したいけど、本番にいれるのはかなり検証つまないと怖いよね、というような話を頻繁にしています。
もちろん、開発工数がとれないとか別の次元の話もありますが、怖さを取り除くまでに手間がかかると言い換えることもできます。

なぜそんなに恐れるのか。今のインターネットのシステムは、極めて高度に発達しており、生物/自然を連想するような複雑な系をなしています。
この自然は普段はおとなしいですが、時として天災のような異常となって我々人間に襲いかかってきます。
情報システムの場合は、システム障害ですね。
このような異常が発生するために、人は未知に対する恐れを抱いてしまいます。
これに似た構造があり、古来より人々は、例えば神話のような世界で、未知の異常を神の怒りと表現していました。
実際には、雷や地震といった災害になるかと思いますが、今ではこれらの現象が神様の仕業だと考えることは少ないように思います。
そのギャップを埋めたものは何かと考えたときに、思い浮かんだのが、「観測」でした。

「観測」することで、わからないものがわかるようになった事例はたくさんあります。
情報システムの世界では、「観測」にあたるものを監視と呼びます。
監視というのは、人間でいうところの健康診断に似ていて、人間の場合は、体重とか血圧とかその他もっと細かいメトリックを計測しチェックします。
ウェブサービスのような情報システムの場合は、CPU利用率とかメモリ使用量とかそういったものになります。
これらの情報をなるべく頻繁に大量に集めるためには、専用のデータベースが必要です。いわゆる時系列データベースというものになります。

このデータベースの課題として、お金と性能というトレードオフに取り組んでいます。
観測により、自然科学の観測のような世紀の大発見があるわけではなく、ソフトウェアのバグだとかリソースが足りないとか、相対的に価値の低いものしか得られないので、お金が重要になってきます。
発表では、簡単にアイデアを紹介していますが、より具体的には [https://speakerdeck.com/yuukit/the-study-of-time-series-database-for-server-monitoring:title:bookmark] をみてください。(ところで、ここからさらに発展した内容を5月にそれっぽい舞台で発表することになっています。)

さて、観測の次にやりたいことがあり、それは「実験」です。要は、コンピュータシステムの未知について、科学のアプローチを実施しようというような考えです。
実験というのは、Netflixの [Chaos Engineering](http://principlesofchaos.org/) から連想しています。
ただし、Netflixの一連のツール群を使っているという話はあまり聞きません。本番に導入するにはやはりハードルが高いと感じています。
そこで、観測して得たデータを使って、システムモデルを構築し、シミュレーションのような安全な手段で、システム特性を明らかにし、弱点などをシステム本体にフィードバックするというビジョンを考えました。
ここは本当にジャストアイデアの段階で、例えばモデルって具体的になんですかと言われても答えられません。今のところ、フィードバック制御の理論あたりからヒントを得られないかと考えています。

このようなシステムを作って、人間をコンピュータの未知への恐れから解放したい、そう考えています。

神の怒りというのは、比喩ではありますが、単なる比喩ではなく話の根幹となるような話作りを意識しました。
観測と実験という概念は、最初から考えていたわけではなく、神の怒りからの連想ゲームから、うまく情報システムに落とし込める概念を見つけられたと思っています。

ipsjoneとは関係なく、昨年matsumotoryさんが発表されたなめらかなシステムとは違うものを提案しようとずっと考えていました。 (なめらかなシステムについては [http://hatenanews.com/articles/201701/24117:title:bookmark])

[https://twitter.com/y_uuk1/status/843505058931073024:embed]
[https://twitter.com/y_uuk1/status/843506249308168192:embed]
[https://twitter.com/y_uuk1/status/843506420607721472:embed]
[https://twitter.com/y_uuk1/status/843507288124022788:embed]

残念ながら僕は名前を付けられませんでしたが、観測と実験というのをテーマにこれからやっていこうと思います。

# いただいた反応

[https://twitter.com/TakeshiOhkawa/status/842999028220489728:embed]
[https://twitter.com/SIshihara/status/842997318982889472:embed]
[https://twitter.com/rgbten084/status/842998989041541120:embed]
[https://twitter.com/z_me_8/status/842997301010350081:embed]
[https://twitter.com/t312371/status/842997747863117824:embed]
[https://twitter.com/itkq/status/843142611003047936:embed]

[https://twitter.com/matsumotory/status/843494140079816705:embed]
[https://twitter.com/matsumotory/status/843647819122524160:embed]
[https://twitter.com/rrreeeyyy/status/843994660770992128:embed]
[https://twitter.com/pyama86/status/844212214676439041:embed]

別分野の研究者の方からおもしろかった、スライドがよいとフィードバックいただいたのはうれしいですね。
その他、また聞きですが研究者の方から、一番おもしろかった、我々は神の怒りと戦っていかねばならん、というようなコメントをいただいたと伺っています。
システムビジョンにも共感の声があり、思った以上に伝わっているという手応えを得ることができました。

# 登壇に至るまで

さて、そもそもなんでお前がそんな場所で発表しているんだという話ですね。
僕はそもそも研究者どころか、修士課程を中退しています。
そこからはてなに入社し、いわゆる現場で運用をやっているエンジニアをやっています。今月にEOLを迎えるCentOS 5の撤退みたいな10年前のシステムを相手にすることもやっていたりしました。
技術者としての実績はそれなりに積んでいるつもりですが、アカデミアにおける実績はほとんどありません。なぜこんな人間が採択されたのかは、今だによくわかっていません。

きっかけは、昨年の登壇者である matsumotory さんに、昨年の6月ごろに、IPSJ-ONEというものがあるので、登壇しないかと声をかけていただいたことです。そのときは、雑にいいですよみたいなことを言っていました。
そのときは、いつもの話で大丈夫と言われた記憶があるのですが、ある意味いつもの話ではあるものの、とんでもない無茶振りであることが後々わかってきます。
その頃はIPSJ-ONEというものがどういうものかあまりわかっておらず、matsumotory さんがちょっと前に登壇したやつぐらいの認識でした。
家に帰って改めて2016年の動画をみていたら、おいおいこれなんか違うやつなんじゃない？、そもそもトップの研究者が集まるとか書いてるじゃんって思いはじめて、その話を忘れていた11月ごろに、matsumotory さんから声がかかってきました。

今、声をかけていただいたDMを見直してみると、めちゃめちゃ大風呂敷を広げた上で、それを回収するみたいな方法で頑張ったのでそれがよさそうと書かれていて、本当にその通りになって笑ってしまいました。加えて、y_uukiが一番得意でかつ、そこに本番までに+アルファできるようなものを提案できると最高とも書かれていました。これも、僕の認識ではその通りになっていて、結果的に、DiamonDBの実装に加えて、観測と実験によるフィードバックループを回すというアプローチの紹介ということになりました。

しかし、最終的に自分のやっていることが世界にとってどういう意味があるかということを加えるとよいという話もあったのですが、ここは本番では組み込めなかった部分です。自動化されて、運用から解放されて、遊んで暮らせるようになるだけなのか？という漠然とした疑念はありました。科学の歴史をみてみると、例えば未知であった電気現象を逆に利用して、今ではコンピュータのような複雑なものを動かすことができるようになっています。そこからさらにメタなレイヤで、同じようなことが起きないかといったことを考えているのですが、これはこれからの宿題ということにします。

そこから、IOT研究会のほうで講演をしないかとという話になったので、招待講演させていただくことになりました。その経緯はブログに書いています。 [http://blog.yuuk.io/entry/iots2016:title:bookmark]

ipsjoneの5分は、僕の発表経験でも3本の指に入る大変さだったので是非頑張ってくださいとも書かれていました。はい、がんばりましたよ。最初は、そんなに大変なことがわかっていなかったのですが、準備を進めるたびに、とにかく大変であることがわかってきました。僕の感覚では、6ヶ月連続200users以上のブログ書いたり、1000usersのブログ書くよりはるかに大変でした。

何が大変だったのか。今までのアウトプットは、自分がやったこととやったことを汎用的な視点で捉えるだけで済みました。
しかし、今回は逆に未来を描いて、自分がやっていることに紐付けるという、頭が痛くなるような手法でした。
しかも、それを一般向けかつLTで伝えることは、余分なものを削ぎ落として、専門家だからこそ難しく書きたくなるようなことを削っていく作業になりました

さらに、僕は自身のテーマというものが、そもそも固まっているわけではありませんでした。ざっくりWebオペレーション技術、SREといった職種/分野の専門性を高めているという程度で、会社の仕事とはまた別の軸で何をやりたいのか、ということを発表準備を通してつくろうとしていました。
テーマがなければ実績もないわけで、実績がある研究者はいいな〜と思いながら、matsumotoryさんの去年のスライドをみると、それまで積み上げてこられた実績が1ページにさくっと書いているだけで、あとはこれからやっていくことが書かれていました。

ようやく、matsumotoryさんの無茶振り具合がわかってきて、初見ハードモードで放り込まれたような気分になっていきました。matsumotoryさんには感謝しています。

[https://twitter.com/y_uuk1/status/842631963420708865:embed]

ところでこれはトークが採択されたときのmatsumotoryさんの様子です。

[f:id:y_uuki:20170321233516p:plain]

# あとがき

スライドだけみると、なんてことのない単なるライトニングトークにみえるかもしれませんが、その裏でいろいろと試行錯誤したことを記しておきたかったという気持ちで、この記事を書きました。

前述したように、最もこだわったことは、一般の方にちゃんとわかるように話をするということです。
見て動くような内容であれば、工夫をこらさなくてもなんとなく伝わります。我々がいつもやっているような、見えないものをどう伝えるのか、ということを深く考えさせられました。

実は、事前に社内の勉強会で発表したときは、驚くほど無反応でした。だいたい予想はしていたものの、考えすぎて全然だめなのかなーと思って、かなり落ち込んでいました。

しかし、そこから5分の制約を相手に、ボツスライドのほうが多くなるぐらいブラッシュアップを繰り返して、何度も練習して、全然専門家じゃないはずの両親がニコ生で発表をみていて、内容がわかった、わかりやすかったと言ってもらえたことで、発表してよかったと思えるようになりました。

フィードバックの数で言えば、普段書くブログのほうが圧倒的に多いです。しかし、普段のブログや発表はコンテキストを共有しているので、フィードバックが多いのは当たり前です。ちょうど id:Soudai:detail さんが書かれているように、アウェーの舞台で伝えることに向き合った結果、伝えることの難しさ/うれしさを再確認できました。

[http://soudai.hatenablog.com/entry/2017/03/18/223005:title:bookmark]

最後になりますが、ipsjone運営委員の皆様のご尽力には頭が上がりません。1回目を立ち上げるのももちろん大変なことだったと思いますが、その後「継続」することは、立ち上げ時の苦労とはまた異なる種類の苦労をされたのだろうと、「運用」を生業とする者としてご推察します。本当にありがとうございました。

