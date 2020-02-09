---
Title: SRE NEXT基調講演を終えて
Category:
- SRE
- 日記
Date: 2020-01-27T15:55:43+09:00
URL: https://blog.yuuk.io/entry/2020/srenext
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/26006613503275750
---

1月25日に開催された[SRE NEXT 2020 IN TOKYO](https://sre-next.dev/)にて，「分散アプリケーションの信頼性観測技術に関する研究」と題して，基調講演をさせていただきました．
これまで一環してWebオペレーション・SREに取り組んできて，今ではSRE Researcherと名乗っている身からすると，国内初のSREのカンファレンスで基調講演にお声がけいただいたことは大変名誉なことだと思っています．

# 基調講演について

カンファレンスの基調講演は実ははじめての経験で，どのような発表をするかについては，いくらか逡巡することになりました．
SRE NEXTのオーガナイザーをされている[@katsuhisa__](https://twitter.com/katsuhisa__)さんからは，現在僕が取り組んでいる研究内容や，その研究背景として考えていることを講演してほしいという期待をいただきました。
同時に，カンファレンスのタイトルに含まれる「NEXT」には，参加者の皆様とSREの次の役割を一緒に考えたいという願いを込めていると伺いました。

まず，基調講演の「基調」には，「作品・行動・思想などの根底を一貫して流れる基本的な考え方。」（スーパー大辞林より）という意味があるようです．
SREの定義は未だはっきりとは定まっていないことから，自分が考えるSREのあり方を述べることが，SREの「基調」として適切であろうと考えました．
そのSREのあり方とは，昨年のブログポストでも述べた(([https://blog.yuuk.io/entry/2019/thinking-sre:title:bookmark]))ように，失敗を許容するという前提にたって，信頼性を制御対象としてみなし，変更速度（Agility，開発速度，リリース速度，Productivityなど）を高めていくというものです．
そうして実現した高い変更速度により，信頼性を脅かすリスクのサイズを小さくしていき，結果的には失敗を許容していても，信頼性も高くなっていくはずです。

次に，工学の研究というものは，世の中の未解決の問題を設定して解くものであるため，研究の話をすれば「NEXT」にはなります．
ただし，SRE全体の「NEXT」を客観的に示すことは容易ではなく，一人の人間が主観的に話してしまうにはすこし傲慢に聴こえてしまうでしょう．
しかし，ひとつの論文にまとまる具体的な研究の話では，「NEXT」というにはスケール不足です．

そこで，自分の取り組んできた複数の各研究と[さくらインターネット研究所のビジョン](https://research.sakura.ad.jp/2019/02/22/concept-vision-2019/)である超個体型データセンターを統合する形で，「NEXT」の一部を示すという形をとりました．
その形とは，クラウドコンピューティングのような集中型のコンピューティングの次の形として，利用者の近傍にコンピューティングが近づく形で地理的に分散した構造をとるエッジコンピューティングやフォグコンピューティングの存在があります．
このような地理敵に分散したコンピューティング自体は，過去にも研究されてきており，広域のネットワーク上にある計算資源を連携させてひとつの大きな計算機システムとしてみなすグリッドコンピューティングや，コンピューティングを遍在させるユビキタスコンピューティングなどが代表的です．
しかし，昨今の技術の変遷を踏まえて，現在主流のクラウドコンピューティングそのものや，クラウドを前提としたCloudNative技術のソフトウェア資産を活かす形で，地理分散アプリケーションを構成することに関心が移ってきているように感じています((KubeCon NA 19でのWallmartの発表など https://kccncna19.sched.com/event/UdJf/keynote-seamless-customer-experience-at-walmart-stores-powered-by-kubernetesedge-maneesh-vittolia-principal-architect-sriram-komma-principal-product-owner-walmart))．
このような地理分散環境でアプリケーションを構成し，運用することを想定したときの，SRE視点の問題にアプローチするというのが，現在僕がさくらインターネット研究所で取り組んでいることになります．

最後には，より大きなNEXTの流れを示すために，このような地理分散環境に関わるクラウド以外のコンピューティング領域への拡張，人と組織に関わる経営学，人と機械に関わる認知システム工学などの分野との関わりを提示しました．
組織については，マイクロサービスやCloudNative技術の目的が組織パフォーマンスの向上であると言われるようになってきている流れから，ここ数年で無視できない要素になっています．
そこで，IT技術の学問であるコンピュータサイエンスを学ぶように，組織の学問である経営学を学び，それを活かした実践が必要となってくるのではないかと思います．
また，クラウド技術の発展により，すでにソフトウェアによる自動化は前提となっており，それによってシステムが複雑化したとしても，人間の認知負荷をうまく抑え込むための手法が今後は必要となってくると考えています．

[f:id:y_uuki:20200127155657p:plain]

基調講演かつ当日のトップバッターでもあったので，全参加者にとって，発表内容のすべてではないにしろ一部でも持ち帰るものがあること，後続のセッションに話をつなげることの2点を意識して，内容を構成しました．
発表後には，発表内容のいずれかのトピック（信頼性制御，地理分散全般，個別の研究内容，組織，人間中心の自動化など）に対して，別々の参加者の方々からまんべんなく言及いただいたことから，目論見はうまくいったと自己満足しています．
全参加者に向けて，個別の具体的な研究内容を，5分程度の短い時間で伝えるということが今回のチャレンジでしたが，そこはわからなかったという声もあり，課題が残りました．
とはいえ，一部のうまく前提を汲んでいただいた方々には，議論可能な状態まではもっていけたので多少の手応えはありました。

以下は講演のスライド資料へのリンクです．

[https://speakerdeck.com/yuukit/a-study-of-sre:embed]

内容に興味をもっていただいたのであれば，今回の講演のベースになった過去の僕の成果物が参考になるでしょう．

1. [https://blog.yuuk.io/entry/2019/thinking-sre:title:bookmark]
1. [https://employment.en-japan.com/engineerhub/entry/2019/12/05/103000:title:bookmark]
1. [https://speakerdeck.com/yuukit/organized-sre:title:bookmark]
1. <u>Yuuki Tsubouchi</u>, Asato Wakisaka, Ken Hamada, Masayuki Matsuki, Hiroshi Abe, Ryosuke Matsumoto, "**[HeteroTSDB: An Extensible Time Series Database for Automatically Tiering on Heterogeneous Key-Value Stores](https://ieeexplore.ieee.org/abstract/document/8754289)**", [Proceedings of The 43rd Annual IEEE International Computers, Software & Applications Conference (COMPSAC)](https://ieeecompsac.computer.org/2019/), pp. 264-269, July 2019. [[paper](https://yuuk.io/papers/heterotsdb_compsac2019.pdf)] [[slide](https://speakerdeck.com/yuukit/heterotsdb-an-extensible-time-series-database-for-automatically-tiering-on-heterogeneous-key-value-stores)]
1. <u>坪内佑樹</u>, 古川雅大, 松本亮介, "**[Transtracer: 分散システムにおけるTCP/UDP通信の終端点の監視によるプロセス間依存関係の自動追跡](http://id.nii.ac.jp/1001/00200765/)**", [インターネットと運用技術シンポジウム論文集, 2019, 64-71 (2019-11-28)](https://www.iot.ipsj.or.jp/symposium/2019-program/), 2019年12月. [[論文](https://yuuk.io/papers/transtracer_iots2019.pdf)] [[発表資料](https://speakerdeck.com/yuukit/udptong-xin-falsezhong-duan-dian-falsejian-shi-niyoruhurosesujian-yi-cun-guan-xi-falsezi-dong-zhui-ji-8bc9ca63-0751-40fd-9ad5-2f1ea692b9b0)]
1. 1. <u>坪内佑樹</u>, 松本亮介, "**[超個体型データセンターにおける分散協調クエリキャッシュ構想](http://id.nii.ac.jp/1001/00195697/)**", 情報処理学会研究報告インターネットと運用技術（IOT）, No.2019-IOT-45, Vol.14, pp.1-7, 2019年5月. [[論文]](https://yuuk.io/papers/concept-of-quorumcache_iot45.pdf) [[発表資料](https://speakerdeck.com/yuukit/quorumcache-architecture)]


# セッションについて

最近は，アカデミアの学会参加や家に引きこもって研究する時間が支配的なので，テックカンファレンスに来たら人と話すように心がけていて，一部のセッションしか直接は聴けていません．
しかし，公開資料やTwitterの反応を眺めていると，組織的アプローチによる問題解決の話がずいぶんと増えてきていたように，SREの実践がすでに開始段階ではなく洗練段階にはいっているように感じました。

## SRE Practices in Mercari Microservices / @deeeet

deeeeeeetくんの発表はひさびさに生で観た気がします．
SLI・SLOを決めても，タスク優先度などの意思決定に使わなければ意味はなく，そのためにスクラムを利用しているという考え方は，まさに僕も2年前に始めたことがあったので我が意を得たりという気持ちになりました．
あとは，SLI・SLOをリクエストベースのシステムへ適用する事例が多い中，リリースパイプラインシステム自体にSLI・SLOを設定するという事例は新鮮でした．
全体的に，[グローバルで議論されている内容](https://gist.github.com/tcnksm/cc7ce8d7edc5b31a4710633574664c61)が発表のベースになっていて，deeeeetくんの普段のインプットの質の高さが伺えました．

## 基調講演 Webサービスを1日10回デプロイするための取り組み / @fujiwara

リバートを含むデプロイ処理自体の高速化，エラー検知の高速化，デプロイ時間と内容の記録など，リスクが顕在化したときにどれだけすぐに回復できるかという観点でどれも重要な実践であると感じました．
fujiwaraさんの取り組みやOSSはずっとウォッチしてきているのですが，取り組まれていることを学術的に整理するとおもしろい論文になりそうだなと今回の発表を聴いて改めて思いました．

[https://twitter.com/yuuk1t/status/1220998732751130624:embed]

fujiwaraさんから現場の話をしていただけそうだったので，運用の現場を離れた僕は安心してフィロソフィカルな議論と研究開発の話に専念できました．

# むすび

SRE NEXTの運営スタッフの皆様，すばらしいイベントをありがとうございました．
SREどころか，Webオペレーション，インフラの分野のカンファレンスは昔から国内ではほとんどなかったことから，こうしたカンファレンスを日本で開催されるということが，国内でのSREの発展に大きく寄与するものだと信じています．
