---
Title: "Serverspec + Mackerel APIによるインフラテストの実運用化"
Category:
- Mackerel
- Serverspec
Date: 2015-12-24T09:00:30+09:00
URL: http://blog.yuuk.io/entry/mackerel-serverspec
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/6653586347149637775
---

この記事は [http://qiita.com/advent-calendar/2015/mackerel:title=Mackerel Advent Calendar 2015] の24日目の記事です。
前回は、id:hitode909:detail による [http://hitode909.hatenablog.com/entry/fitbit2mackerel:title] でした。

今回は、Mackerel APIを用いて[Serverspec](http://serverspec.org/)によるサーバ構成テストを実運用化した話を紹介します。
Serverspec単体では手の届かないかゆいところをMackerelでサポートするところがポイントです。
Mackerelはもちろんですが、他のサーバ管理ツールにも通用する汎用的な話になるように心がけています。

<!-- more -->

[:contents]

# Serverspec導入の背景

10年単位で長期運用しているサービスをいくつも運用していると、古いサービスのサーバは手作業で作られていたり、構成管理ツールで途中まで作って残りは手作業で作られていたりするということはどうしてもあります。
ハードウェアの耐用年数やディスク容量が満杯になるサイクルがサービスの寿命より短いため、これらの手作りサーバをどうにか引っ越す必要があります。
元が手作業なので、ChefやAnsibleで一から立て直すことができません。
したがって、これらのサーバをがんばって作りなおしたり、仮想ホストであればボリュームの内容をコピーして別の物理ホスト上で起動するようなオペレーションをかなり頻繁にやっています。
レシピを新しく書きなおすことも当然ありますが、それなりの時間がかかるため、コピーで済ますことも多いです。
別サブネットへの作り直しやコピーであれば、IPアドレスが変わることも当然あります。
コピーのままではまずい設定を置換スクリプトで書き変えたりします。
たまに書き換え忘れていたり、スクリプトからもれたりすると、サービスインしたときに障害につながることもあります。

一方で、比較的新しめのサービスのサーバ、つまりChefで一発でサービスイン可能な状態のサーバを作れる環境があったとしても、念のため設定ファイルを確認したり、バージョンを確かめたり、AWSであればAZが正しいかEIPがついているかとかあれこれ念のため手作業で確かめたりすることもやはりあります。
特に他のメンバーが作ったサーバと同じものを構築するときは慎重になります。
Chefのcookbookは絶えず変更が加えられていくため、新しく一からサーバを構築したときに、既存のサーバと同じものができあがる保証がないためです。

ちょうど今週 id:moznion:detail が [http://moznion.hatenablog.com/entry/2015/12/20/221921:title:bookmark] という記事を書いていました。

<blockquote cite="http://moznion.hatenablog.com/entry/2015/12/20/221921" data-uuid="6653586347149638213"><p>事故からは学習するべきで，学習した結果同じようなミスが金輪際起こらなくなれば我々はその事故の対応に時間を取られることが無くなって，もっと生産的な活動に従事することができるようになると思う．学習は尊い．</p><cite><a href="http://moznion.hatenablog.com/entry/2015/12/20/221921">じこはおこるさ - 職質アンチパターン</a></cite></blockquote>


とにかくオペレーションミスで事故を起こしたくないため、どうにかしてサーバ投入前に人間がチェックしている部分だけでも自動化したいと思っていました。
自動化、つまりコードにすることにより、過去のミスの蓄積を新しいメンバーであっても即利用できます。

そこで、Serverspecです。

## Serverspec

>
Serverspecとは、サーバの状態をコードにより自動的にテストするためのツールであり、Ruby製のテストフレームワークであるRspecをベースにしています。
> 
<i>宮下剛輔著『Serverspec』オライリージャパン、2015年、p3</i>

以前からServerspecを使いたいと思ってはいました。
Serverspecといえば、テスト駆動インフラ、インフラCIという言葉に代表されるように、ちょうどアプリケーションで継続的にテストを回すような気持ちで、インフラコードのテストを回すという印象でした。
実際、書籍[http://www.oreilly.co.jp/books/9784873117096/](「Serverspec」) には、Serverspecの本質はインフラコードのリファクタリングや開発の促進であると書かれています。

>
あくまでもServerspecの本質は、「テスト駆動によって、インフラコードのリファクタリングや開発を促進する」ことです。
> 
<i>宮下剛輔著『Serverspec』オライリージャパン、2015年、p6 </i>

導入したいと思い、いざインフラCIを始めるかと思ったとき、Chefのロール数がネックになることに思いあたりました。
Chefのロール数は今現在軽く200を超えており、さらに今後倍以上のロール数になる可能性があります。

Serverspecは構築後のサーバをテストしてオペレーションミスを防ぐことが主目的ではないかもしれません。
しかし、Serverspec以上に今回の問題解決に最適なツールを他に知らないため、採用することにしました。
テストを回す基盤を誰かが整えておけば、その上に乗っかって、テストを書いていくことにはさほど困りません。
基本的なRubyの構文が書ければ問題なかろうと考えました。

本当のことを言うとRubyというかRspecは、Rubyが主言語でないチームで、しかもインフラのテストコードを書くためだけにしては学習コストが高すぎると感じています。
そんなにがんばってテストを書きたくないというのが本音なので、状態の表現力みたいなものやテストの結果のレポーティングにはそれほど興味がありません。
RSpecについて、書籍Serverspecに以下のような言及があります。

>
RSpecは、記法のバリエーションや機能が多く、バージョン間の差異も大きいため、本質的ではないことに時間を割きたくないというケースでは、あまり適切なツールだとは言えません（自分で選択しておいてこう言うのも何ですが）。
とは言え、Serverspecでテストコードを書くにあたっては、RSpecの機能や記法をフルに覚えて活用する必要はありません。
> 
<i>宮下剛輔著『Serverspec』オライリージャパン、2015年、p30</i>

実際、RSpecについてそれほど知らずとも、公式ドキュメント [http://serverspec.org/resource_types.html:title] を眺めながら、十分書けてしまうと思います。

一方で、ChefやItamaeもそうですが、Ruby で書けるということはメリットの一つです。
要はなんでもできるため、他のツールとも連携しやすいというのは非常に重要です。

# Serverspec × Mackerel

Serverspecについては、他にもテスト方針や、[Infrataster](http://infrataster.net/)、[awspec](https://github.com/k1LoW/awspec)などのServerspec inspiredなツールとの組み合わせ方などの話題がありますが、今回は、サーバ管理ツールである[Makcerel](https://mackerel.io)との組み合わせについて紹介します。

## ロール単位でspecを書く

Serverspecのデフォルトは、ホストごとにディレクトリをつくるようなレイアウトになります。
先ほど、Chefのロール数が200を超えると書きました。
当然、ホストごとにspecを書いていくやり方には限界があるため、ロールごとにspecを書きたくなります。

id:deeeet:detail さんの [http://deeeet.com/writing/2015/03/17/serverspec-for-automation/:title:bookmark] に書かれている運用によると、ホストとロールの情報を静的に定義したファイルを使うようです。（今では違うかもしれません）

> サーバーの数が多いとホストごとにディレクトリを準備するServerspecデフォルトのやり方では限界がある．そういう場合は，ロール毎，モジュール毎ににspecをまとめ，ホストとそのロール情報を別ファイル（JSON形式など）で準備し，それを読み込みRakeタスクを定義するのが良い．
今のチームではそもそもホストとそのロールのリストを準備しそれをもとにChefを実行するという運用があったので，そのリストをそのまま利用することにした．
> 
<i>http://deeeet.com/writing/2015/03/17/serverspec-for-automation/</i>

[http://serverspec.org/advanced_tips.html:title] にも、「How to share Serverspec tests among hosts」という項目があり、ロールのようなグループごとにspecを書く構成が紹介されています。
前者の場合、Chefと共有できるのはよさそうですが、Serverspecに限らずツールを導入するたびに、ホスト情報をあちこちに書くはめになることは往々にしてあります。
そして、ホストの追加・削除があれば、それらのホスト情報を書き変えてまわることになります。
このような運用は、特にホストをどんどん捨てて新しいホストをたてるようなImmutable Infrastructure的な運用にはあまり沿いません。

そこで、Mackerelでは[API](http://help-ja.mackerel.io/entry/spec/api/v0)を用いて「ホスト情報を一元管理する」という思想を推奨しています。
Serverspecの場合は、ホスト名が与えられると、Mackerel APIを叩いてホスト情報を引き、サービスとロールから対応するspecファイルが決まるというようなことができます。もちろん、逆にロールを与えて、ロール配下のホスト群にテストを回すということも可能です。
Serverspecは良い意味で、ホスト管理機能をサポートしていないので、APIで動的にホスト情報と実行すべきspecファイルを対応づけるのは簡単です。

[f:id:y_uuki:20151223223418p:image:w600]

### ディレクトリレイアウト

チームのServerspecのディレクトリレイアウトは以下のようになっています。
`base_spec.rb` に各ロール共通のspecを書き、service ディレクトリ以下にMackerelのサービス・ロールに対応するspecを書きます。
ミドルウェア単位でspecをまとめたいこともあります。そんなときは、common というディレクトリ以下に複数のロール間で使いまわせそうなspecを書きます。（実際のレイアウトとは若干異なりますが、だいたいこのようになっています。）

```
spec
├── common
│   ├── nginx
│   │   ├── default.rb
│   │   └── proxy.rb
│   └── postgresql
│       ├── default.rb
│       ├── master.rb
│       └── slave.rb
├── base_spec.rb
├── service
│   ├── myblog
│   │   └── proxy_spec.rb
│   │   └── app_spec.rb
│   │   └── db-master_spec.rb
│   └── mybookmark
│       ├── proxy_spec.rb
│       ├── app_spec.rb
│       ├── db-master_spec.rb
│       ├── db-slave_spec.rb
└── spec_helper.rb
```

### Thorfile

Rakefileは書き方が難しくてあまり好きではないので、[Thor](http://whatisthor.com/) を使ってみました。
Thorは簡単にコマンドラインのインタフェースを作れて便利です。
もちろん、Serverspecデフォルトのrakeを使っても問題ありません。

例えば、以下のようなThorfileを用意してやります。[mackerel-client-ruby](https://github.com/mackerelio/mackerel-client-ruby)を使って、与えられたホスト名からAPIを引いてホスト情報を取得し、サービス・ロール名から適用するspecファイルの一覧をだし、rspec コマンドに渡してやります。

```ruby
require 'mackerel/client'

RSPEC_OPT = ENV['SABASPEC_RSPEC_OPT'] || '--format doc -c'

class Spec < Thor
  include Thor::Actions
  default_task :host

  desc 'host', 'run spec for a host'
  def host(hostname)
    mackerel = ::Mackerel::Client.new(mackerel_api_key: MACLEREL_API_KEY)

    host = mackerel.get_hosts(name: hostname).first # 同じ名前のホストが2つ以上存在しない前提
    raise "Not found host #{hostname}" if host.nil?

    spec_files = ['spec/base_spec.rb']
    spec_files += host.roles.flat_map {|service, roles|
      roles.flat_map {|role| "spec/service/#{service}/#{role}_spec.rb" }
    }.select {|f| FileTest.exist?(f) }

    ENV['ASK_SUDO_PASSWORD'] = '1'
    ENV['RSPEC_SSH_HOST'] = hostname
    run("bundle exec rspec #{RSPEC_OPT} -r spec_helper #{spec_files.join(' ')}")
  end
end
```

以下のコマンドでホスト名を渡してやれば、実行できます。

```sh
bundle exec thor spec:host myblog001 
```

Mackerelで管理しているすべてのホストに一発で適用するといったこともタスクを実装してやれば簡単にできると思います。

## サーバ上でServerspecをローカル実行する

Mackerel APIを用いて、ホスト情報管理に余分な手間を割かなくてよくなりました。
しかし、Chefで構築したり、仮想ホストを引っ越したりするたびに、手元の端末からServerspecを実行するのも面倒です。
面倒になってしまうとやり忘れることもあり、結局は事故につながるかもしれません。
したがって、スムーズに運用に組み込むためにはもうひと工夫必要です。

そこで、今の運用ではホストのステータスを[mkr](https://github.com/mackerelio/mkr) を用いてサーバ上で変更していることが多いことに着目しました。
例えば、サービスインの前の、sshログインしているサーバのMackerel上のステータスをstandbyにする場合は、以下のようなコマンドを叩きます。

```sh
(ログイン先) mkr update --st standby
```

これの代わりに、serverspecを実行できればよいのではと考えました。具体的にはログイン先のサーバで下記のようにrunspecと打つとテストが実行され、Mackerel上のステータスがstandbyになるというようなイメージです。

```sh
(ログイン先) runspec 
```

あとはサービス投入時にworkingにするという流れのライフサイクルになります。
運用によっては、standbyを経由せずに直接workingにしてしまうというほうが面倒がなくてよいこともあるでしょう。

[f:id:y_uuki:20151223223446p:image:w600]

サーバ上でserverspecを実行するには、各サーバでビルド済みのRubyを配布して、Serverspecのspecが入ったリポジトリをcloneして、bundle installするなどのセットアップが必要です。さらにspecファイルの更新に追従していく必要があるため、cronで毎日git pullさせています。
サーバの数が少なければ、cronまでは必要ないとは思います。
Ansbleを使って何かを配布する方法は [http://yuuki.hatenablog.com/entry/ansible-mackerel-1000:title:bookmark] で紹介しました。

補足ですが、サーバ上でRubyやらbundle installやらあれこれ用意するのが面倒なら、[droot](https://github.com/yuuki1/droot)を使うのもよさそうです。Dockerfile さえ書いてしまえば、drootバイナリとdrootで作成したS3上のアーカイブを配布するだけで動くはずです。

[http://yuuki.hatenablog.com/entry/droot:title:bookmark]

Serverspecはssh先で実行するモードとローカル実行するモードがあります。ローカル実行するモードは spec_helper.rb で`set :backend, :exec` で指定できます。
とはいえ、テストコードの開発時はssh先で実行するモードを使いたいので、以下のように環境変数で分岐するようなspec_helper.rbにしています。

```ruby
require 'serverspec'
require 'pathname'
require 'net/ssh'

RSpec.configure do |c|
  if ENV['SERVERSPEC_LOCAL_MODE'] # サーバ上で実行する
    set :backend, :exec
  else
    set :backend, :ssh
    if ENV['ASK_SUDO_PASSWORD']
      require 'highline/import'
      set :sudo_password, ask("Enter sudo password: ") { |q| q.echo = false }
    else
      set :sudo_password, ENV['SUDO_PASSWORD']
    end
    c.before :all do
      host = ENV['RSPEC_SSH_HOST']
      options = Net::SSH::Config.for(host)

      options[:user] ||= Etc.getlogin

      set :host,        options[:host_name] || host
      set :ssh_options, options
    end
  end
  c.path = '/usr/sbin:/sbin:$PATH'
end
```

<!--- ## Serverspecでチェック監視する --->
<!---  --->
<!--- サーバ上でローカル実行できるので、mackerel-agentによるチェック監視と相性がよくなります。 --->
<!---  --->
<!--- [http://help-ja.mackerel.io/entry/custom-checks:title] --->
<!---  --->
<!--- サーバ上でgit diffが残ったままみたいなこともありえなくはないので、そういうのも監視するとよいかもしれません。 --->

# あとがき

Serverspecをうまく運用にのせるためのMackerel APIの活用について紹介しました。

APIによるホスト情報の一元化というMackerelの思想がとても好きで、プログラマブルなインフラの可能性を感じました。
[mkr](https://github.com/mackerelio/mkr) や [http://yuuki.hatenablog.com/entry/tmux-ssh-mackerel:title:bookmark]、[http://yuuki.hatenablog.com/entry/ansible-mackerel-1000:title:bookmark] はMackerelを中心としたプログラマブルなインフラを促進するものです。
myfinderさんに以前のmeetupで良い紹介の仕方をしていただきました [https://github.com/myfinder/mackerel-meetup-3/blob/master/slide.md:title:bookmark] 。

最後に、１年近く前の話になりますが、[Serverspec](http://www.oreilly.co.jp/books/9784873117096/)本の献本をどうもありがとうございました。


はてなではMackerelを中心としたインフラ運用環境の開発に興味があるエンジニアを募集しています。

[http://hatenacorp.jp/recruit/career/operation-engineer:embed]
[http://hatenacorp.jp/recruit/career/application-engineer:embed]

明日はアドベントカレンダー最終日です。お楽しみに。

[asin:4873117097:detail]

