---
Title: Facebookの数千台規模のmemcached運用について
Category:
- memcached
Date: 2014-07-09T09:30:00+09:00
URL: https://blog.yuuk.io/entry/facebook-memcached-paper
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/12921228815727749940
---

[http://yuuki.hatenablog.com/entry/dsync-paper:title:bookmark]の続きとして、Facebook の memcached 運用に関する論文を読んだ。
タイトルなどは以下の通り。
NSDI はネットワークシステムに関するトップレベルのカンファレンス。

- Scaling Memcache at Facebook
  - Rajesh Nishtala, Hans Fugal, Steven Grimm, Marc Kwiatkowski, Herman Lee, Harry C. Li, Ryan McElroy, Mike Paleczny, Daniel Peek, Paul Saab, David Stafford, Tony Tung, Venkateshwaran Venkataramani
  - NSDI'13 In Proceedings of the 10th USENIX conference on Networked Systems Design and Implementation
  - [https://www.usenix.org/conference/nsdi13/technical-sessions/presentation/nishtala]

Facebook のキャッシュシステムがどのようにスケールしてきたか、各スケール規模の勘所は何かについて書かれた論文だった。
内容はかなり盛りだくさんで、基本的なデータベースクエリキャッシュ戦略から、マルチリージョン分散の話まで多岐に渡る。
memcached に依存しない話も多いので、memcached というよりは、超大規模キャッシュシステムの運用例として読むのがよさそう。

## 論文概要
memcached はよく知られたシンプルなインメモリキャッシュシステムである。
論文では、memcached を基本単位として、世界最大のソーシャル・ネットワークを支える分散KVSをどのように構築し、スケールさせたかについて書かれている。
Facebook のキャッシュシステムは、秒間数十億リクエストを捌いていて、10億人を超えるユーザにリッチな体験を届けるために、数兆個のアイテムをキャッシュに保持している。

システムは、以下の4段階でスケールしてきた。

- 数台のmemcachedサーバ
- 多数のmemcachedサーバを含むシングルmemcachedクラスタ
- マルチmemcachedクラスタ
- マルチリージョン

### 1. 数台のmemcachedサーバ
- demand-filled look-aside cache 方式
- 並列 memcache set 問題 (stale sets)
- Thundering Herd 問題
- memcache プロトコルの拡張 "leases"

### 2. シングルクラスタ
- consistent-hashing
- TCP incast congestion 問題
- Layer 7でスライディングウィンドウでフロー制御
- get リクエストは UDP にしてパケット減らす
- 独自ルータを挟んでコネクション永続化

### 3. マルチクラスタ
- フロントエンドクラスタ + ストレージクラスタ
- 一貫性の保持
- 全クラスタのキャッシュ無効化処理
- SQL文に無効化キーを埋め込んでおきて、MySQLのコミットログをtailして埋め込みキーを無効化するデーモン

### 4. マルチリージョン
- (フロントエンドクラスタ + ストレージクラスタ) x リージョン
- リージョン間レプリ遅延を考慮して、キャッシュミス時にマスタDBをreadするかスレーブDBをreadするかマーカーをつける

### Conclusion
- キャッシュと永続ストレージを分離して、独立してスケールさせる
- モニタリング、デバッギング、オペレーション効率を改善する機能はパフォーマンスと同じくらい重要
- ロジックは stateless なクライアントに置くほうが混乱しない
- システムは新機能の段階的なロールアウトとロールバックをサポートしなければならない
- Simplicity is vital.

## スライド
より具体的な内容はスライド参照。
相当はしょっているので、詳細な内容は論文参照。
はしょった内容については、後日ブログにするかも。

<div style="width:75%">
  <script async class="speakerdeck-embed" data-id="11bf0aa0e8db0131563f028221fe0025" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>
</div>

## 関連記事

- https://www.facebook.com/notes/facebook-engineering/scaling-memcache-at-facebook/10151411410803920:title:bookmark]
- [http://www.publickey1.jp/blog/09/facebook8php.html:title:bookmark]
  - この記事によると2009年の時点でサーバ台数は3万台らしい
- [http://www.publickey1.jp/blog/10/facebookmemcached300tb.html:title:bookmark]
- [https://www.facebook.com/publications:title:bookmark]
  - Facebook が出している論文を含む出版物のリスト

## 感想
TCP incast問題を回避するために、TCPのスライディングウィンドウ的なロジックをアプリレイヤで実装していたりして、OSレイヤでの解決方法を大規模運用にあてはめてスケールさせているのが印象的だった。
仕事でそのロジックを実装するリソースを割けない、もしくはそもそもそんなスケール必要がないとかはあるにしても、話としては結構おもしろかった。
あと、memcached 自体には機能を追加せずに、クライアントサイドにロジックを入れていたのも気になるところだった。
Facebook はストレージにHBaseを使っている話 ([https://www.facebook.com/notes/facebook-engineering/the-underlying-technology-of-messages/454991608919:title])もあって、こっちはミドルウェアにロジックをもたせてたりするので、このへんの方針の違いも気になる。

関連記事にも載せてるけど、 https://www.facebook.com/publications で Facebook の出してる論文とか読めるので、いろいろ勉強になりそう。
