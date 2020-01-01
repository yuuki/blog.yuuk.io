---
Title: 2019年振り返り - エンジニアから研究者へ
Category:
- 日記
Date: 2020-01-01T16:51:29+09:00
URL: https://blog.yuuk.io/entry/2020/reviewing-2019
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/26006613491802239
Draft: true
CustomPath: 2020/reviewing-2019
---

例年のように、昨年の活動を振り返る。

昨年は、それ以前の5年と異なり、働き方もエンジニアから研究者へ転向したことにより、自分を取り巻く環境は大きく変化した。
とはいえ、1年の研究活動を通じて、エンジニア時代と比較し、働き方は変わっても、自分が目指すものはあまり変わらないことも再確認した。

エンジニアであっても、研究者であっても、SREの分野において、相変わらず特定の環境に依存しない汎用的かつオリジナルの貢献を目指している。
エンジニアか研究者かというのは、自分にとっては、単に時間の使い方の差に過ぎない。
エンジニア時代は、企業の商用システムの開発・運用経験を通して、余暇時間でブログに知見をまとめたり、ソフトウェア化したりしていたが、研究者になってからは現場経験のウェイトをほぼゼロにして、学術論文の形で深く知見をまとめて、ソフトウェア化を進めている。

## 1月

昨年の12月に前職を退職したのち、1月いっぱいは無職期間だったこともあり、疲れをとるためにのんびりと過ごしていた。
睡眠サイクルが自由運動を始めて、深夜3時くらいに深夜食堂的なところで飲んでいた日もあった。

怠惰の限りをつくしていると思いきや、意外と活動していて、IEEE COMPSAC2019に向けて国際会議論文を書いていたり、[次世代Webカンファレンス](https://blog.jxck.io/entries/2018-09-15/next-web-conf-2019.html)でSREをテーマとしたパネルディスカッションに登壇したり、福岡に遊びにいったときに体調を崩されたまつもとりーさんの代理で急遽発表したりした((入社後に出張扱いにしていただいたので、交通費と宿泊費を経費で落とせてラッキーだった。))。

次世代Webカンファレンスの流れから、SREとはつまり、「信頼性の制御」であると言語化できたので、ブログにまとめておいた。

[https://blog.yuuk.io/entry/2019/thinking-sre:title:bookmark]

## 2月

無職期間はあっという間に終わり、さくらインターネットに入社した。
所属はさくらインターネット研究所になる。
2月は特に締め切りもなかったので、これまでを振り返りつつ、研究方針を考えたり、
研究所のビジョンである[超個体型データセンター](https://research.sakura.ad.jp/2019/02/22/concept-vision-2019/)を踏まえて、研究テーマを練ったり、超個体型データセンターのいち要素である[エッジコンピューティングについて調査](https://memo.yuuk.io/entry/2019/learning-edge-computing01)していたりした。

[https://speakerdeck.com/yuukit/2019-0cfffd07-b58d-462f-8834-14e0dca15a0d:title:bookmark]

## 3月

徳島で開催された[IOT44](https://www.iot.ipsj.or.jp/meeting/44-program/)と福岡で開催された[情報処理学会 第81回全国大会](https://www.ipsj.or.jp/event/taikai/81/)に参加していた。

[Hosting Casual #5](https://connpass.com/event/120048/)で新しい研究の構想を紹介したり、機械学習のイベントでSREに機械学習を適用する研究のサーベイ結果を話していたりした。
機械学習そのものはそれ以降特に何もしていないけど、研究所の機械学習が得意なメンバーと話をするネタとして多少役に立った。

[https://speakerdeck.com/yuukit/chao-ge-ti-de-dbkuerikiyatusingugou-xiang:title:bookmark]

[https://speakerdeck.com/yuukit/a-survey-for-cases-of-applying-machine-learning-to-sre:title:bookmark]

## 4月

IOT45の研究会論文を執筆したり、自分が主催している[ウェブシステムアーキテクチャ研究会](https://websystemarchitecture.hatenablog.jp/entry/2019/02/26/100725)で発表したりしていた。

[https://speakerdeck.com/yuukit/edge-caching-survey:title:bookmark]

大学院博士課程進学を想定して、京大の研究室に訪問したりしていたのもこの頃だった。

[https://speakerdeck.com/yuukit/introduction-to-my-research:title:bookmark]

石狩のデータセンターに出張する予定があったが、体調を崩してしまって行けなかった。

## 5月

GW明けに、SanSanさんの京都のオフィスで開催されたSREとエンジニアリング組織の会に声をかけていただいた。
これを機会に、これまであまり公開していなかった、2018年にSREと組織に関わる仕事をやっていたときに実践したことをまとめた。

[https://speakerdeck.com/yuukit/organized-sre:title:bookmark]

そのあと、[DICOMO2019](http://dicomo.org/)の研究会論文の執筆も進めていた。

月末には、大阪大学で開催されたIOT45でQuorumCacheネタで研究発表した。
阪大を中退して以来、はじめてキャンパスに足を踏み入れ、当時在籍していた研究室があった場所を苦々しい気持ちで眺めた。

## 6月

6月は特に締め切りがなくて、はじめてさくらの東京支社オフィスに行ったりしていた。

<https://github.com/yuuki/transtracer>の実装を進めていたのもこのころ。

## 7月

福島で開催されたDICOMO2019でTranstracerネタを発表してきた。
知らないうちに博士号を取得していて、研究室の助教となっていた高校時代の同級生と卒業以来はじめて会って話をした。

[https://speakerdeck.com/yuukit/a-concept-of-superorganism-tracing:title:bookmark]

IEEE COMPSAC 2019ではじめて国際会議で発表してきた。研究ネタは2018年に国内で発表したHeteroTSDB。

[https://blog.yuuk.io/entry/2019/compsac2019:title:bookmark]

## 8月

[セキュリティ・キャンプ全国大会](https://www.ipa.go.jp/jinzai/camp/2019/zenkoku2019_index.html)で「クラウド時代における大規模分散Webシステムの信頼性制御」という題目で講義をしてきた。
セキュリティ・キャンプの存在は、学生時代に聞き及んでいたものの、自分とは縁のない遠い世界の話だと思っていたのが、それから7年以上経って、講師の立場で参加することになるとは思わなかった。
自分がこれまで経験を積み上げてきたWebシステムアーキテクチャの基礎、Webシステムのスケーリングの基礎とケーススタディの話を4時間講義で218ページの大作スライド((講師がスライドの著作権をもつため公開しても問題ないものの、考えがあって非公開としている。みせてほしいという人にだけ渡している))としてまとめた。
受講生の方々からは、内容はヘビーだったけど、おもしろかったと感想をいただいた。

Kyoto.なんかでエンジニア向けにTranstracerネタの話をした。

[https://speakerdeck.com/yuukit/observability-tool-focused-on-relationship-in-distributed-systems:title:bookmark]

## 9月

前月の中頃からIOTS2019の査読付き論文を執筆していた。

セキュリティ・キャンプの講義準備時にサーバーレスアーキテクチャをいかに説明するかを考えていた流れで、サーバーレスアーキテクチャについて名前の由来の考察をブログにまとめておいた。
[https://blog.yuuk.io/entry/2019/rethinking-serverless-architecture:title:bookmark]

島根で開催された[APNOMS 2019](https://www.ieice.org/~icm/apnoms/2019/)というネットワーク分野の国際会議に参加した。
APNOMS2019でよく出てきた話題は、5G、エッジ/フォグコンピューティング、SDN、MLによるトラフィック制御、ブロックチェーンのようなものだった。
それぞれが独立した話題というよりは、組み合わせる話もあり、エッジでSDNやるとか、エッジ側でオンライン学習するみたいな話もあった。

ちょうどセキュリティ・キャンプでウェブシステムアーキテクチャ分野（未定義）の一部を講義でまとめたこともあって、分野定義のような構想をウェブシステムアーキテクチャ研究会で発表した。
エンジニア時代から乱雑に散らばった知見の体系化に関心があり、全体を俯瞰しつつ、今どこにいるのかを示す現在位置と周辺との位置関係がわかるようなアウトプットに憧れがあった。
その延長線上で研究をすすめるにあたって少しずつ地図を作っていきたい。

[https://blog.yuuk.io/entry/2019/map-of-web-systems-architecture:title:bookmark]

構想レベルの話にも関わらず、思いの外反響があったことから、それなりの数の人が地図を求めていることがわかってきた。

## 10月

前職から声をかけていただいたエンジニアHubのSRE記事を書いていた。
1月に書いたSRE考の発展版という位置づけで、いかにはやく信頼性の制御ループに入り込むかという話をまとめた。

[https://employment.en-japan.com/engineerhub/entry/2019/12/05/103000:title:bookmark]

HeteroTSDBネタを完成させるために、情報処理学会の論文誌論文への投稿を準備もしていた。

## 11月

さくらの東京支社で研究所の[@amsy810](https://twitter.com/amsy810)さんに2日がかりで研究所メンバー向けにKubernetesの講義をやっていただいた。
月末のCloud Native Days KANSAI 2019に向けてKubernetes熱が高まった。
ついでに、東京の汚染された大気では呼吸ができないとかいいながら、SRE仲間と会ったり、前職の同僚と合ったりしていた。

Cloud Native Days KANSAIは、登壇者の数が東京よりは少なく、それがかえって、登壇者同士で話をしやすくてよかった。
ここ1年は家でこもって研究をしているか、アカデミア系のコミュニティに顔をだすことのほうが多かったので、その分もあってかエンジニア同士で話をすることが楽しく感じられた。
従来インフラ系と呼んでいた分野のネタは、昔はYAPCなどのプログラミング言語系のカンファレンスに応募するしかなかったのが、最近は、Cloud Native DaysやSRE NEXTのようなカンファレンスが開催されるようになってきて、ありがたい状況になってきた。

[https://speakerdeck.com/yuukit/transtracer-cndk2019:title:bookmark]

## 12月

15年ぶりに訪れる沖縄で開催されたIOTS2019でTranstracerネタを発表した。
データベース系よりもテーマの性質が研究会のテーマにマッチしたせいもあってか、前年のHeteroTSDBネタよりも質疑応答で盛り上がった。
幸いにも、最も優れている論文に与えられる優秀論文賞と、有用性を評価されて企業冠賞であるシー・オー・コンヴ賞をいただくことができ、早くも学術方面で実績をだすことに成功した。

[https://speakerdeck.com/yuukit/udptong-xin-falsezhong-duan-dian-falsejian-shi-niyoruhurosesujian-yi-cun-guan-xi-falsezi-dong-zhui-ji-8bc9ca63-0751-40fd-9ad5-2f1ea692b9b0:title:bookmark]

その後は、年末まで博士課程進学の準備を粛々と進めていた。

## むすび

知人に今の仕事はどう？と尋ねられたときに、冗談半分で「実質アーリーリタイア状態。締め切りが常に2,3個あるのを除けばね」という話をするようになったのが、今年の様子を端的に表している。
さくらインターネット研究所では、論文や発表の回数にノルマがあるわけではないので、締め切りの個数や日程は自分で制御可能になっている。
学術主体の研究会と実用主体のカンファレンスの両方にでていることもあって、ピンポイントで慌ただしいと感じることもあったが、休み休み無理なく継続して研究を進められた。

昨年の目標だった査読付き国際会議への採録と受賞を達成できたので首尾は上々といったところ。

今年以降は、所長の薦めもあって、自身の顔がみえるようなアーキテクチャを設計したり、ソフトウェアを開発したりするためのスキルを獲得することを目的に、情報学博士の学位取得を目標とすることに決めた。
現在、博士後期課程へ進む準備を進めており、無事審査に合格すれば、来年の4月から6年ぶりに学生となる。

また、昨年は論文執筆と発表に集中していたために、ソフトウェア開発がすこしおざなりになってしまった。
今年は、知人の現場環境に導入してもらうなどして、ソフトウェアとしての価値を高めていきたい。

## 2019年の研究成果リスト

### 受賞

1. [情報処理学会インターネットと運用技術シンポジウム2019（IOTS2019）優秀論文賞](https://www.iot.ipsj.or.jp/awards/symposium/) <u>坪内佑樹</u>, 古川雅大, 松本亮介, "**[Transtracer: 分散システムにおけるTCP/UDP通信の終端点の監視によるプロセス間依存関係の自動追跡](http://id.nii.ac.jp/1001/00200765/)**", インターネットと運用技術シンポジウム論文集, 2019, 64-71 (2019-11-28), 2019年12月.
1. [情報処理学会インターネットと運用技術シンポジウム2019（IOTS2019）冠賞: シー・オー・コンヴ賞](https://www.iot.ipsj.or.jp/awards/symposium/) <u>坪内佑樹</u>, 古川雅大, 松本亮介, "**[Transtracer: 分散システムにおけるTCP/UDP通信の終端点の監視によるプロセス間依存関係の自動追跡](http://id.nii.ac.jp/1001/00200765/)**", インターネットと運用技術シンポジウム論文集, 2019, 64-71 (2019-11-28), 2019年12月.

### 国際会議録（査読付き）

1. <u>Yuuki Tsubouchi</u>, Asato Wakisaka, Ken Hamada, Masayuki Matsuki, Hiroshi Abe, Ryosuke Matsumoto, "**[HeteroTSDB: An Extensible Time Series Database for Automatically Tiering on Heterogeneous Key-Value Stores](https://ieeexplore.ieee.org/abstract/document/8754289)**", [Proceedings of The 43rd Annual IEEE International Computers, Software & Applications Conference (COMPSAC)](https://ieeecompsac.computer.org/2019/), pp. 264-269, July 2019. [[paper](https://yuuk.io/papers/heterotsdb_compsac2019.pdf)] [[slide](https://speakerdeck.com/yuukit/heterotsdb-an-extensible-time-series-database-for-automatically-tiering-on-heterogeneous-key-value-stores)]

### 国内会議録（査読付き）

1. <u>坪内佑樹</u>, 古川雅大, 松本亮介, "**[Transtracer: 分散システムにおけるTCP/UDP通信の終端点の監視によるプロセス間依存関係の自動追跡](http://id.nii.ac.jp/1001/00200765/)**", [インターネットと運用技術シンポジウム論文集, 2019, 64-71 (2019-11-28)](https://www.iot.ipsj.or.jp/symposium/2019-program/), 2019年12月. [[論文](https://yuuk.io/papers/transtracer_iots2019.pdf)] [[発表資料](https://speakerdeck.com/yuukit/udptong-xin-falsezhong-duan-dian-falsejian-shi-niyoruhurosesujian-yi-cun-guan-xi-falsezi-dong-zhui-ji-8bc9ca63-0751-40fd-9ad5-2f1ea692b9b0)]

### 国内会議録（査読なし）

1. <u>坪内佑樹</u>, 古川雅大, 松本亮介, "**超個体型データセンターを目指したネットワークサービス間依存関係の自動追跡の構想**", マルチメディア、分散、協調とモバイル（DICOMO2019）シンポジウム, 6A-2, pp. 1169-1174, Jul 2019. [[論文](https://yuuk.io/papers/transtracer_dicomo2019.pdf)][[発表資料](https://speakerdeck.com/yuukit/a-concept-of-superorganism-tracing)]
1. <u>坪内佑樹</u>, 松本亮介, "**[超個体型データセンターにおける分散協調クエリキャッシュ構想](http://id.nii.ac.jp/1001/00195697/)**", 情報処理学会研究報告インターネットと運用技術（IOT）, No.2019-IOT-45, Vol.14, pp.1-7, 2019年5月. [[論文]](https://yuuk.io/papers/concept-of-quorumcache_iot45.pdf) [[発表資料](https://speakerdeck.com/yuukit/quorumcache-architecture)]
1. 松本亮介, <u>坪内佑樹</u>, 宮下剛輔, "**[分散型データセンターOSを目指したリアクティブ性を持つコンテナ実行基盤技術](http://id.nii.ac.jp/1001/00194721/)**", 情報処理学会研究報告インターネットと運用技術（IOT）, No.2019-IOT-45, Vol.12, pp.1-8, 2019年3月.

### 国内講演・講義

1. 坪内佑樹, (基調講演) **[分散アプリケーションの信頼性観測技術に関する研究]()**, [SRE NEXT 2020 IN TOKYO](https://sre-next.dev), 2020年1月25日 (to appear)
1. 坪内佑樹, **[分散システム内のプロセス間の関係性に着目したObservabilityツール](https://speakerdeck.com/yuukit/transtracer-cndk2019)**, [CloudNative Days Kansai 2019](https://cloudnativedays.jp/cndk2019/), 2019年11月28日
1. 坪内佑樹, (講義) **[クラウド時代における大規模分散Webシステムの信頼性制御](https://www.ipa.go.jp/jinzai/camp/2019/zenkoku2019_program_list.html#list_d2-b1)**, [セキュリティ・キャンプ全国大会2019](https://www.ipa.go.jp/jinzai/camp/2019/zenkoku2019_index.html), 2019年08月14日

### 国内口頭発表

1. 坪内佑樹, **[Webシステムアーキテクチャの地図を描く構想](https://blog.yuuk.io/entry/2019/map-of-web-systems-architecture)**, [第5回WebSystemArchitecture研究会](https://websystemarchitecture.hatenablog.jp/entry/2019/07/30/172650), 2019年9月29日.
1. 坪内佑樹, **[分散システム内の関係性に着目したObservabilityツール](https://speakerdeck.com/yuukit/observability-tool-focused-on-relationship-in-distributed-systems)**, [Kyoto.なんか #5](https://kyoto-nanka.connpass.com/event/141982/), 2019年8月24日.
1. 坪内佑樹, **[SREの組織的実践](https://speakerdeck.com/yuukit/organized-sre)**, [エンジニリング組織の作り方 -マネジメントとSREの観点から考える-](https://sansan.connpass.com/event/125822/), 2019年5月9日
1. 坪内佑樹, **[エッジコンピューティングに向けた分散キャッシュ技術の調査](https://speakerdeck.com/yuukit/edge-caching-survey)**, [第4回ウェブシステムアーキテクチャ(WSA)研究会](https://websystemarchitecture.hatenablog.jp/entry/2019/02/26/100725), 2019年4月13日
1. 坪内佑樹, **[わたしの研究開発紹介 - 技術者から研究者へ -](https://speakerdeck.com/yuukit/introduction-to-my-research)**, 2019年4月10日
1. 坪内佑樹, **[SREへの機械学習適用に関するサーベイ](https://speakerdeck.com/yuukit/a-survey-for-cases-of-applying-machine-learning-to-sre)**, [MACHINE LEARNING Meetup KANSAI #4 LT](https://mlm-kansai.connpass.com/event/119084/), 2019年3月27日
1. 坪内佑樹, **[超個体的DBクエリキャッシング構想](https://speakerdeck.com/yuukit/chao-ge-ti-de-dbkuerikiyatusingugou-xiang)**, [Hosting Casual Talks #5](https://connpass.com/event/120048/), 2019年3月22日
1. 坪内佑樹, **[ゆううきの研究開発まとめ (2019年2月版)](https://speakerdeck.com/yuukit/2019-0cfffd07-b58d-462f-8834-14e0dca15a0d)**, [さくらインターネット研究所 研究会 2019.02.13](https://research.matsumoto-r.jp/), 2019年2月13日
1. 松本亮介(代理発表), **[アプリケーション実行環境におけるセキュリティの話](https://speakerdeck.com/matsumoto_r/webapurikesiyonshi-xing-huan-jing-niokerusekiyuritei)**, [福岡ゆるっとIT交流会 vol.9「セキュリティの話を聞こう」](https://yurutto-it.connpass.com/event/107340/), 2019年1月25日

### パネルディスカッション

1. 坪内佑樹, **SRE(#nwc_sre)**, [次世代Webカンファレンス 2019](https://nextwebconf.connpass.com/event/103056/), 2019年01月13日 [[動画]](https://www.youtube.com/watch?v=HR1pcyQ_i3I)

### 学会誌・商業誌等解説

1. 坪内佑樹, **[SRE実践の手引 ─ 信頼性をどう制御するか？ から始める、現実的な指標と目標の設計と計測](https://employment.en-japan.com/engineerhub/entry/2019/12/05/103000)**, [エンジニアHub](https://employment.en-japan.com/engineerhub/), 2019年12月4日
1. 松本亮介, 坪内佑樹, 宮下剛輔, 青山真也, **[研究員たちが考える、さくらインターネット研究所「これから」の10年](https://ascii.jp/elem/000/001/963/1963013/)**, ASCII.jp, 2019年10月29日
