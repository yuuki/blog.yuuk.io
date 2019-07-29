---
Title: 時系列データベースの論文を国際会議IEEE COMPSACで発表した
Category:
- 日記
Date: 2019-07-29T17:02:08+09:00
URL: https://blog.yuuk.io/entry/2019/compsac2019
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/26006613379400662
---

先日、アメリカのウィスコンシン州ミルウォーキーで開催された国際会議 [IEEE COMPSAC 2019](https://ieeecompsac.computer.org/2019/)で時系列データベースHeteroTSDBの論文を発表してきました。

[f:id:y_uuki:20190729171845p:plain]

IEEE COMPSACは、IEEE内のコンピュータソフトウェア分野の分科会IEEE Computer Societyのフラグシップカンファレンスとして開催されている国際会議です。
COMPSACが対象とする分野は、ソフトウェア、ネットワーク、セキュリティ、アプリケーションなど非常に幅広く、様々なテーマの発表がありました。
COMPSACは、メインシンポジウムと併設のワークショップにより構成されており、[メインシンポジウムのregular paperの採択数は63本(24.5%)、short paperの採択数は50本](https://ieeecompsac.computer.org/2019/wp-content/uploads/sites/7/2019/07/2019_COMPSACprintprogram_July15.pdf)となっています。
投稿時にregularとshortの区別はなく、今回の我々の論文は、メインシンポジウムのshort paperとして採択されました。
一般にアカデミアの国際会議にはランク付けがあり、[CORE](http://www.core.edu.au/)のカンファレンスランキングによると、COMPSACはA*(4%)、A(14%)に次ぐB(26%)ランクとなっています。いわゆるトップカンファレンスとは呼ばないかもしれませんが、実績として十分に認められる会議であるというように自分は認識しています。

- [https://www.sakura.ad.jp/information/pressreleases/2019/07/22/1968200714/:title:bookmark]
- [https://developer.hatenastaff.com/entry/2019/07/22/113000:title:bookmark]

## 予稿

- [HeteroTSDB: An Extensible Time Series Database
for Automatically Tiering on Heterogeneous Key-Value Stores](https://yuuk.io/papers/heterotsdb_compsac2019.pdf)

## スライド

[https://speakerdeck.com/yuukit/heterotsdb-an-extensible-time-series-database-for-automatically-tiering-on-heterogeneous-key-value-stores:embed]

## 発表内容

投稿した論文の内容自体は、昨年に国内の学会で発表したものとほぼ同じ内容になります [https://blog.yuuk.io/entry/2018/writing-the-tsdb-paper:title:bookmark]。
日本語論文の時点でページ数は8で、そのまま英語化すると8ページ弱となり、最終的にはページ数6のshort paperに収める必要があるため、もともと日本語論文にあった冗長な記述を削減しました。
その結果、元の論文と比べて、すっきりした形になったかなと思います。

投稿論文の査読の中で、実環境の運用を基にした議論となっており、読者にとって有益であるというようなコメントをいただきました。
まさに実運用から出発している研究であるため、我が意を得たりというコメントでした。
その一方で、新規性や他手法と比較した有用性の記述が弱いとの指摘もありました。
もともとこの研究は、プロダクト開発から始まっているため、どうしても新規性を強く打ち出すことは難しくなります。
また、定量的な性能を追求する研究ではなく、拡張性や互換性といった定性的な観点にフォーカスした研究であるため、定量的な評価が難しく、他の手法と比べて有用であることを実験で示すことが難しいという性質があります。
このあたりは、難しいながらも記述を工夫し、研究のまとめとしてジャーナルへ投稿する予定です。

さて、会議での口頭発表ですが、昨年の国内の発表では、論文に記述した内容を全部含めようとした結果、分量が大きくなってしまい、要点を絞れていなかったという反省がありました。
そこで、今回は序盤のIntoroductionを時系列データベースが利用される背景 => 既存のチャレンジ(性能要求) => 新しいチャレンジ(拡張性) => 新旧チャレンジの内容を満たすアーキテクチャの概要といった流れで、4ページでコンパクトに研究をまとめるように工夫してみました。
さらに、提案手法の詳細の記述が、もともとの日本語のスライドではテキスト主体になっていたため、なるべく図で表現するように改善しました。
英語のスキルは残念ながらいきなり上がったりしないので、特定の言語に依存しない工夫により、英語スキルの不足を補うように努めました。
むしろ日本語の発表だとその場のアドリブで、なんとなくごまかしてしまえることも、英語だとそうはいかないため、スキルの低い英語で発表することで、結果的に論旨を明瞭にするスキルを鍛えるきっかけになることに気づきました。

<figure class="figure-image figure-image-fotolife" title="発表の様子">[f:id:y_uuki:20190729171443p:plain]<figcaption>発表の様子</figcaption></figure>

当日の発表では、国内の研究会で見知っている方も多いこともあって、日本の学会とさほど緊張感は変わらず臨むことができました。
発表後に(英語の)発音がうまいと言っていただいたのはうれしく思いました。
そもそも自分は、普段の日本語の発表でさえ、抑揚がないと言われがちなので、強く抑揚が求められる英語では、めちゃくちゃ平坦に聞こえてしまうだろうなと危惧していました。
そこで、事前の発表練習で自分の声を録音して、USENIX FASTやLisaの発表音声と比較しつつ、抑揚がでていない部分を発見し、強引に抑揚をつける練習をしていたりしていました。
加えて、"database"、"datapoints"、"architecture"などの自分の発表で頻出する
しかし、マイクにうまく声が乗っていたなかったようで、普段手に持っていたマイクをなぜか当日はマイクスタンドに置きっぱなしにしていたのは失敗でした。
質疑応答では、たどたどしくも質問にはしっかり答えられたかなと思います。
とはいっても、いずれも日本人の先生方からの質問であったため、質問文が聞き取りやすかっただけとも言えます。

## 会議の様子

開催地のマーケット大学は緑のあるゆったりとした美しいキャンパスでした。
学会会場には、コーヒーやクッキーが常備され、昼食時間にはランチボックスが積まれ、棟内で自由に食べることができました。
情報処理学会がCOMPSACのスポンサーとなっている関係で、日本の研究者の方々が数多く参加されているのも印象的でした。

<figure class="figure-image figure-image-fotolife" title="マーケット大学の様子">[f:id:y_uuki:20190729171512p:plain]<figcaption>マーケット大学の様子</figcaption></figure>

学会の対象分野自体が広いため、リサーチセッションは自分の関心領域の内容を楽しむというよりは、普段関わりのない分野の発表を聴いて見識を広めたり、英語での発表スタイルや質疑応答での言い回しを学んだりする場として活用できました。
ずっと発表を聴いているとそれはそれで疲れるので、バルコニーのベンチに座って、発表の感想について談笑していたりしました。

キーノートや特別セッションは、Wireless AIという新しい研究分野の創出、A Smart World(COMPSAC 2019のテーマ)に向けてテクノロジーが何をもたらすか、表彰された3名のトップ研究者のパネルディスカッション、IEEE Computer Societyの歴代の会長によるパネルディスカッションといった内容でした。
いずれの内容も興味深く、テクニカルな内容を楽しむというよりは、研究のあり方を考えたり、他の分野とのコラボレーションを楽しむといったもので、いずれもそこでしか聴けないであろう内容でした。
普段ならはいはいっと聞き流しそうな内容でも、こういった場に来るとちゃんと聴こうとするので現金ですね。

- [https://ieeecompsac.computer.org/2019/keynotes/:title]
- [https://ieeecompsac.computer.org/2019/presidents-panel/:title]

会議期間中にずっと考えていたのは、"Is a Smarter World a Better World? Key Questions at the Intersection of Technology, Intelligence, and Ethics"というタイトルのキーノートの中で提起されていた、我々はテクノロジーにより自分たち自身を"enhance make-decision's capacity"できているかという問いについてでした。
日本語では、人間の意思決定能力を高めるという意味になりますが、例えば、AIの活用により、自分の過去の情報をもとに推薦される情報のみを拠り所にすると偏りが生じて、かえって人間の意思決定能力を低下させてしまうこともあり得るが、本当にそれでいいのかという問いを投げかけるような内容だったと思います。

抽象度の高い問いなのでそのまま考えてもなかなか思考はまとまらないので、僕が専門とするSREの分野に置き換えて考えました。
例えば、今業界で起きている大きな流れは、一部のメガクラウド事業者がマネージドサービスを提供することで、短期的には利用者の仕事を削減して、利用者は空いた時間で他のことをできるようにするというものです。
しかし、この流れの先にあるものは、中央集権による技術の寡占構造とみることもできます。
提供されているマネージドサービスがあまりにも便利なために、マネージドサービスを組み合わせてできることの範囲内でしか物事を徐々に考えなくなってしまい、結果としてコンピューティングとネットワークの技術が世の中全体としては失われていく可能性もあります。
そうすると、長期的には、却って技術が発展しなくなるという仮説も考えることができます。

別のキーノートセッションでも健康状態などの個人のプライバシーの情報をクラウドに格納しておくことや医者が情報を専有していることの是非を考える話がありました。そして，これらの問題を解決するのは，個人の情報はその個人が所有するということではないかとも。
このように複数の分野で、一時的な効率のために、長期的に犠牲にしているものがあるというパターンをみてとることができます。
そして、そのパターンの中にある共通の構造として、一時的な効率のための中央集権構造と、それに対抗する分散構造のトレードオフを帰納的に見出すことができます。
ここまで考えて、さくらインターネット研究所のビジョンである[超個体型データセンター](https://research.sakura.ad.jp/2019/02/22/concept-vision-2019/)を連想しました。というのは、超個体型データセンターは、中央集権構造に対するインターネットの技術階層でのアンチテーゼになっているためです。
超個体型データセンターを突き詰めて考えていくと、プライバシー、倫理、哲学などの観点からも興味深いものとして捉えることができるかもしれません。

## あとがき

[https://hb.matsumoto-r.jp/entry/2018/07/27/234649:title:bookmark]。

今では同僚であるid:matsumoto_r:detailさんが昨年のCOMPSACで発表されたことは、当時はもちろん知っていましたが、その翌年に自分が発表することになるとは思いもしませんでした。とはいうものの、イメージしていないことは実現しないともいうので、覚えていないだけでイメージはしていたのかもしれません。[2年前のIPSJ-ONEで発表したときのこと](https://blog.yuuk.io/entry/ipsjone2017)を思い出しました。

セッションプログラムをみるとちょうどHeteroTSDBとFastContainerの発表が並んでいて、感慨深いものがあります。
さくらインターネットの名前で2人続けて発表したので参加者の印象にも残ったのではないかと思います。

[f:id:y_uuki:20190729171636p:plain:w400]

大学院の学生だったころは、国際会議で発表することはなかったどころか中退してしまったため、国際会議への発表は初めてで、単に参加すること自体も初めてでした。
そもそも海外へ赴くのは、高校時代のホームステイ研修みたいな旅行以来だったこともあり、発表よりも現地に無事に到着して滞在できるかどうかのほうが気がかりなぐらいでした。
英語学習そのもののモチベーションが低く、TOEICのリスニングの点数で平均以下しかとったことがない自分でも国際会議で英語で発表できたことは、グローバルでのアウトプットへの心理的ハードルを下げてくれました。
また、さくらインターネット研究所では、出張費用を全額サポートされるのはもちろんのこと、少なくとも研究員自身が行う手続きには面倒なことがないので、参加のためのハードルを下げてもらっています。
どちらかというと、家からあまり動きたくなくてのんびりしたい自分であっても、こうやって活動の幅が広がることは純粋に楽しいものです。