---
Title: 2017年のエンジニアリング振り返り
Category:
- 日記
CustomPath: 2017/review
---

はてなに入社して4年経った。

[https://twitter.com/y_uuk1/status/936763941115478016:embed]

2017年のエンジニアリング活動を一言でまとめてみよう。

[時系列データベースの開発](http://blog.yuuk.io/entry/the-rebuild-of-tsdb-on-cloud)にはじまり、なぜか[IPSJ-ONEで登壇](http://blog.yuuk.io/entry/ipsjone2017)し、その後IPSJ-ONEでの構想をベースに[はてなシステム構想](https://speakerdeck.com/yuukit/the-concept-of-hatena-system)を考え始め、[ウェブサイエンス研究会](http://blog.yuuk.io/entry/2017/the-concept-of-autonomous-web-system)でストーリーとしてまとめ上げつつ新たな可能性に気づき、それを実践していく場として[ウェブシステムアーキテクチャ(WSA)研究会](http://websystemarchitecture.hatenablog.jp/)を立ち上げた。

一方で、仕事では、[昨年の振り返り](http://blog.yuuk.io/entry/looking-back-2016)に書いているように、エンジニアとしての専門性を発揮する機会が薄れてきたという問題意識が、いよいよ深刻な課題へと変貌したように感じている。それも残念ながら自分一人だけの問題ではなくなってきた。
この課題をエンジニアリングそのものではなく、人間のスケールアウトでは解決できない、組織アーキテクチャの課題であると捉えている。
組織アーキテクチャの課題を解くための鍵は、今のところ「未来を定義する」「未来に向かって集中して取り組める環境をつくる」ことだろうと仮定している。
前者の未来については前述のシステム構想があり、後者の方法論として今年実践する機会のあった[プロジェクトマネジメント](https://confengine.com/regional-scrum-gathering-tokyo-2018/proposal/5430/mackerel)がある。

したがって、来年は、今年構想したビジョンを技術と組織の両輪を回し、実現し始める、ということが目標になる。
そしてその裏には、エンジニア個人としては[技術を作る技術](https://geek-out.jp/column/entry/2017/12/28/110000)をやっていきたいと思いつつ、生活時間の大半である業務の課題はマネジメントであるというギャップをどう埋めて一つのストーリーとしていくかが重要になるだろう。

ここまで、いきなりまとめに入ったのだけれど、2017年に力を注いだ各トピックについて細かく振り返ってみる。

- 時系列データベースの設計・開発・運用
- 学術研究のアプローチとの出会いとビジョンの構想
- プロジェクトマネジメント
- アウトプット

# 時系列データベースの設計・開発・運用

[http://blog.yuuk.io/entry/the-rebuild-of-tsdb-on-cloud:embed]

開発した時系列データベース(TSDB)は、運用にのることに成功し、今のところクリティカルな問題を起こすことなく動いている。実装・運用面では、同僚のid:itchyny:detailさん、id:astj:detail さん、id:kizkoh:detail さんの力によるところが大きい。

このTSDBのオレオレ実装を、[半年毎日コード書いて](http://memo.yuuk.io/entry/2017/05/07/225123)頑張っていたのだけど、リリース前に疲弊しまくって睡眠もうまくとれなくなってしまったので、途中までになってしまった。https://github.com/yuuki/diamondb/
個人でやるプロジェクトとしては、ひと通り動くまでに時間がかかりすぎ、細かくロードマップを引きづらかったので、サーベイを続けて、新たな課題を発見し、その課題を小さく解決する手法を編み出したい。

TSDBの開発は、大きな成果だと思っており、この知見を横展開するために、より汎用的なアーキテクチャにできないかと考えたのが、TimeFuzeアーキテクチャ構想だ。

[http://blog.yuuk.io/entry/2017/timefuze-architecture:embed]

時系列データベースに限らず、大規模な計算機システムのモニタリングを支えるデータ処理アーキテクチャが好きなので、今後のライフワークとしていきたい。

# 学術研究のアプローチとの出会いとビジョンの構想

突然だけど、id:matsumoto-r:detail (まつもとりー)さんの昨年の振り返りをみてみよう。

<blockquote cite="http://hb.matsumoto-r.jp/entry/2016/12/26/121135" data-uuid="8599973812331662929"><p>さらに、id:y_uuki さんとは今年1年非常に仲良くさせていただいて、12月はなぜか毎週会って何かイベントごとをこなすようなぐらい、企業・アカデミア方面で関わることが多かったように思います。いつか、企業とアカデミアの両方の要素を含む新しい研究会みたいなものを一緒に作っていけるといいな、ぐらいに一方的に信頼しており、色々と今年は無茶をお願いしましたが、できるだけその無茶をちゃんと責任をもってサポートできるようにしたいと思います。</p><cite><a href="http://hb.matsumoto-r.jp/entry/2016/12/26/121135">エンジニア・研究者とはどうあるべきか - 2016年振り返りと新生ペパボ福岡基盤チームの紹介 - 人間とウェブの未来</a></cite></blockquote>

今年は、まつもとりーさんのおかげもあって、学術研究コミュニティとの関わりが深くなった年だった。
前述の [http://blog.yuuk.io/entry/ipsjone2017:title:bookmark] に始まり、まつもとりーさんの5年間の挑戦の最後を見届け [http://blog.yuuk.io/entry/2017/05/03/201215:title:bookmark]、[ペパボ・はてな技術大会](http://developer.hatenastaff.com/entry/2017/10/20/140829)では考えたビジョンをみてもらって、[自分なりにウェブシステム全体をみてストーリー化し](http://blog.yuuk.io/entry/2017/the-concept-of-autonomous-web-system)、それに対して[議論していただいて](https://twitter.com/matsumotory/status/937137992094834688)、最後は「企業とアカデミアの両方の要素を含む新しい研究会」として[ウェブシステムアーキテクチャ研究会](http://websystemarchitecture.hatenablog.jp/)を一緒に立ち上げることができた。

その中で気づいたのは、学術研究のアプローチにより、ウェブシステムの分野におけるある種の限界を突破できるかもしれないということ。
ここでの限界というのは、同じことの繰り返しで積み上げによる進化をしていないじゃないか感と、シリコンバレーの巨人の西洋技術を取り入れるだけで自分たちの存在価値とはなんなのだろう感を指している。
それらに対するアプローチは既にあり、前者は体系化、後者は徹底したサーベイと自分なりの思考からの新規性ということになる。
[このあたりのよもやまについてはTwitterにあれこれ書いていた](https://twitter.com/y_uuk1/status/909455717693775872)。

ちなみに、学術研究のアプローチを企業でのエンジニアリングに導入することで何が起きるかについては、まつもとりーさんの下記の2つの記事にすべて書かれている。((前者は僭越ながら[はてなブログ大賞](http://blog.hatenablog.com/entry/2016/12/20/140000)に選出させていただきました。))

- [http://hb.matsumoto-r.jp/entry/2017/09/18/001913:title:bookmark]
- [https://geek-out.jp/column/entry/2017/12/28/110000:title:bookmark]

なにより重要なのは、そもそもなにがやりたいのかという自分の欲求と、それが実現したらどんな世界になるのかをイメージすることだとまつもとりーさんは何度もおっしゃっていた。((イメージすることについては、[以前書いた記事](http://blog.yuuk.io/entry/the-best-entries-of-2015)で紹介させていただいた、[イメージできることを実践する](http://meymao.hatenablog.com/entry/2015/04/14/%E3%82%A4%E3%83%A1%E3%83%BC%E3%82%B8%E3%81%A7%E3%81%8D%E3%82%8B%E3%81%93%E3%81%A8%E3%82%92%E5%AE%9F%E8%B7%B5%E3%81%99%E3%82%8B)を連想する。))
前者はともかく後者はまあいいんじゃないと思いがちだし、実際何度もそう思った。
特に現場の泥臭い運用をやっていれば、なおさらそう思う。
しかし、前者だけであれば個人の趣味でしかないので、食べていくために仕事をしないといけないとなると費やせる時間は限られる。
そこで、欲求が世界にどう作用するかを考えることで、やりたいことを仕事にできる...はず((本当はもうすこし深い意味があると思うのだけど、現状はこういう理解でいる))。

こういうことをずっと考えていた1年だった。
こうしてちょっとずつ自分なりの道をつくりつつあるのも、まつもとりーさんのおかげだなあとしみじみ思います。いつもありがとうございます。

そういえば、同じように同僚の id:masayoshi:detail にも僕のほうからいろいろ無茶を投げつけたのだけど、彼は僕よりもアカデミックのアプローチに精通していたり、技術力も上なのでもっと無茶振りしていこうと思った。来年こそはなんとかしたいねいろいろと。

# プロジェクトマネジメント

時系列データベース開発とクラウド移行のプロジェクトを丸ごと任された結果、物事を前に進めるための条件というものがあることを体感で理解したように思う。
これをウェブオペレーションチームの一部で実践しはじめ、小さな範囲でうまくできそうだということがわかってきたので、来年はチームというか部署全体で適用していきたい。
これらについては、まだアウトプットしていないのでどこかでアウトプットしたい。daiksyさんの薦めで、RGST2018に応募していたのだけど、残念ながら選考で落ちてしまった。

[https://confengine.com/regional-scrum-gathering-tokyo-2018/proposal/5430/mackerel:embed]

SREの分野のマネジメントって、SRE本以外に世の中に知見があまりなく、逆にチャンスだと思うが、自分が追求することではないと思っているので、誰かこれをはてなで追求したい人がいないかを探している。

# アウトプット

## OSS

f:id:y_uuki:20171231081203p:image

- [https://github.com/yuuki/diamondb/:title]
- [https://github.com/yuuki/binrep:title]
- [https://github.com/yuuki/albio:title]
- [https://github.com/yuuki/mkr-check:title]
- [https://github.com/yuuki/rlq:title]
- [https://github.com/yuuki/portpinger-rs:title]

以前開発していた[droot](https://github.com/yuuki/droot)が、[capze](https://github.com/yuuki/capze]とともにオンプレミス上の大きめのサービスで稼働しはじめ、明らかになったバグを修正したりしていた。

アーキテクチャ設計に関わった [http://blog.yuuk.io/entry/go-and-mysql-jobqueue:title:bookmark] では、id:tarao:detail さんにより [Fireworq](https://github.com/fireworq/fireworq) として実装され、公開された。今、1200 starsとかになっていてすごい。

## ブログ

登壇内容をベースにそれをできるかぎりしっかり文章にまとめるということをやり続けている。
なぜかというと、アウトプットのスケーラビリティを非常に強く重視していて、登壇資料はあくまで当日その場のためのものであり、文章として後に残すことが自分のためにも重要だと考えているためだ。
最小のインプットで最大のアウトプットが鉄則。

- [http://blog.yuuk.io/entry/ipsjone2017:title:bookmark]
- [http://blog.yuuk.io/entry/2017/05/03/201215:title:bookmark]
- [http://blog.yuuk.io/entry/the-rebuild-of-tsdb-on-cloud:title:bookmark]
- [http://blog.yuuk.io/entry/redis-cpu-load:title:bookmark]
- [http://blog.yuuk.io/entry/2017/lambda-disadvantages-from-a-cost-viewpoint:title:bookmark]
- [http://blog.yuuk.io/entry/2017/the-origin-of-mackerel:title:bookmark]
- [http://blog.yuuk.io/entry/2017/the-concept-of-autonomous-web-system:title:bookmark]
- [http://blog.yuuk.io/entry/2017/timefuze-architecture:title:bookmark]

- [http://developer.hatenastaff.com/entry/2017/10/12/184721:title:bookmark]
- [http://developer.hatenastaff.com/entry/2017/10/20/140829:title:bookmark]

- [http://memo.yuuk.io/entry/2017/03/26/144328:title:bookmark]
- [http://memo.yuuk.io/entry/2017/04/03/232142:title:bookmark]
- [http://memo.yuuk.io/entry/2017/04/08/002821:title:bookmark]
- [http://memo.yuuk.io/entry/2017/04/10/002914:title:bookmark]
- [http://memo.yuuk.io/entry/2017/04/16/174747:title:bookmark]
- [http://memo.yuuk.io/entry/2017/05/04/165801:title:bookmark]
- [http://memo.yuuk.io/entry/2017/05/07/225123:title:bookmark]
- [http://memo.yuuk.io/entry/2017/08/28/222807:title:bookmark]
- [http://memo.yuuk.io/entry/2017/systems-performance-7-memory:title:bookmark]
- [http://memo.yuuk.io/entry/2017/11/05/203425:title:bookmark]
- [http://memo.yuuk.io/entry/2017/mackerel-advent-calendar:title:bookmark]

## 登壇

過去最多の10本。とはいっても、数とかどこで登壇したかは問題ではなく、何を考え何を話したか、それぞれの登壇に何かしらの挑戦があったかが重要だと思う。

- [高度に発達したシステムの異常は神の怒りと見分けがつかない](https://speakerdeck.com/yuukit/ipsj-one-2017-y-uuki), [IPSJ-ONE 2017](http://ipsj-one.org/), 2017-03-18
- [mkr + peco + tmux + ssh](https://speakerdeck.com/yuukit/mkr-plus-peco-plus-tmux-plus-ssh), [Mackerel Meetup #10 Tokyo](https://mackerelio.connpass.com/event/54302/), 2017-04-27
- AWSでつくる時系列データベース, リクルートテクノロジーズ社内勉強会, 2017-04-28
- [Go言語をほぼ毎日書いている話 (序) ](https://speakerdeck.com/yuukit/daily-coding-in-go), [そうだ Go、京都。](https://go-kyoto.connpass.com/event/55599/), 2017-04-28
- [RedisのCPU負荷対策パターン](https://speakerdeck.com/yuukit/redisfalsecpufu-he-dui-ce-patan), [Kyoto.なんか #3](https://kyoto-nanka.connpass.com/event/62617/), 2017-08-19
- [人はなぜミドルウェアを作ってしまうのか?](http://2017.cross-party.com/program/x4), [CROSS 2017](http://2017.cross-party.com), 2017-09-07
- Webシステムをデータセンター移行するときに考えること, [Hosting Casual Talks #4](https://connpass.com/event/62208/), 2017-09-30
- [時系列データベースという概念をクラウドの技で再構築する](https://speakerdeck.com/yuukit/the-rebuild-of-time-series-database-on-aws), [AWS Summit Tokyo 2017](http://www.awssummit.tokyo/)), 2017-06-01
- [はてなシステム構想](https://speakerdeck.com/yuukit/the-concept-of-hatena-system), [ペパボ・はてな技術大会@福岡](https://pepabo.connpass.com/event/65932/), 2017-10-07
- [自然のごとく複雑化したウェブシステムの自律的運用に向けて](https://speakerdeck.com/yuukit/experimentable-infrastructure), [人工知能学会 合同研究会 第3回ウェブサイエンス研究会](http://www.ai-gakkai.or.jp/sigconf/)(招待講演), 2017-11-24
- [TimeFuzeアーキテクチャ構想 - 処理とデータとタイマーを一体化したデータパイプライン](https://speakerdeck.com/yuukit/the-concept-of-timefuze-architecture), [ウェブシステムアーキテクチャ(WSA)研究会 第1回](http://websystemarchitecture.hatenablog.jp/entry/2017/12/17/133301), 2017-12-23

# あとがき

エンジニアとしてやりたいことと、仕事で実際にやっていることとの乖離が大きくなってきた。
そもそも、仕事ではだいたいその場しのぎの解決しかできず、あとは家に帰ってがんばるということがこれまでほとんどではなかったかとすら思う。
世の中のすごいエンジニアもみんなそんなもので、もっとたくさんのプライベート時間を費やしているか、技術力が圧倒的だから少ない時間できれいに解決できるに違いない、自分はまだまだなのだという気持ちでいたのだけど、どうやら必ずしもそういうわけではなさそうだと感じている。
人が増えれば解決するはずだと、信じていたが脆くもその願望が打ち砕かれつつある。サーバ増やしてもスケールしないのと同じでアーキテクチャの問題。

乖離を埋めるためには、どうしたらいいのか。
技術力を発揮するというより、組織やプロジェクトをマネジメントすることが必要だと自分で導出してしまったため、矛盾しているような気もする。
マネジメント、あれほどやりたくないと言っていたのだけど、それが課題となればやるしかない。
マネジメントといっても、人と調整したり強調したりすることはあまり得意ではないため、[自分の資質](https://twitter.com/y_uuk1/status/866293965544226816)にしたがい、ビジョンとか戦略をつくって、それを達成するアーキテクチャを考え、アイディアをだして、最上志向だから不得手な部分は仲間にどんどん任せていくというようにしてやっていきたい。

自分の技術力向上については、WSA研を目安に研究志向でアイデアをOSSとして実現しつつ、より高みを目指したアウトプットとして論文を書いていきたい。
