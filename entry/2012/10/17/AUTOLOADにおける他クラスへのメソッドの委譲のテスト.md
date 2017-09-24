---
Title: "AUTOLOADによる他クラスへのメソッドの委譲のテスト"
Category:
- Perl
Date: 2012-10-17T00:07:49+09:00
URL: http://blog.yuuk.io/entry/2012/10/17/AUTOLOAD%E3%81%AB%E3%81%8A%E3%81%91%E3%82%8B%E4%BB%96%E3%82%AF%E3%83%A9%E3%82%B9%E3%81%B8%E3%81%AE%E3%83%A1%E3%82%BD%E3%83%83%E3%83%89%E3%81%AE%E5%A7%94%E8%AD%B2%E3%81%AE%E3%83%86%E3%82%B9%E3%83%88
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/12704591929891209553
---

最近，Net::Qiita [http://search.cpan.org/~yuuki/Net-Qiita-0.03/lib/Net/Qiita.pm] というモジュールを作った．
そのモジュールの中で，Net::QiitaクラスのAUTOLOADで，Net::Qiita::Clientが持っているメソッドを動的に呼び出す（委譲するとかいうらしい）ということをやった．
Rubyでmethod_missingでメソッド名を取得してrespond_toしてsendする感じ．

```perl
use Net::Qiita::Client;

sub new {
    my ($class, %options) = @_;

    Net::Qiita::Client->new(\%options);
}

# Delegate method to Net::Qiita::Client object
sub AUTOLOAD {
    my $func = our $AUTOLOAD;
       $func =~ s/.*://g;
    my (@args) = @_;

    {
        no strict 'refs';

        *{$AUTOLOAD} = sub {
            my $class  = shift;
            my $client = $class->new;
            defined $client->can($func) || croak "no such func $func";
            shift @args;
            $client->$func(@args);
        };
    }
    goto &$AUTOLOAD;
}
```


そもそも，わざわざメタなことをする必要があったのかということはまた別に書くとして，メソッドの委譲処理が仕様どおりかどうかテストする方法を考えていた．

## まず考えたこと
Test::Moreの can を使ってクラスがメソッドをもっているかどうかを確認できると考えた．

```perl
ok Net::Qiita->can('user_items'); #Net::Qiitaクラスがuser_itemsメソッドをもっているかどうか

# can_okを使うほうがスマートだけど，説明の都合上直接canを直接使う
```

これは結論から言うとダメで，理由は perldoc に書いてあった．

> can はオブジェクトが AUTOLOAD を通してメソッドを提供可能かどうかは 知ることができません, そのため undef が返ってきてもオブジェクトが そのメソッド呼び出しを処理することができないとは限りません. これを 回避するにはモジュールの作者が AUTOLOAD を使って処理するメソッドに対して 前方宣言を使うことです(perlsub参照). そのような'ダミー'の関数は can はコードリファレンスを返しますが, それが呼び出された時には AUTOLOAD へとフォールスルーされます. 

UNIVERSAL::canは現在のクラスと親クラスのメソッドしか探さないみたい．
（UNIVERSALクラスの"system"を引数にとるとundefになるので，UNIVERSALクラスは探さないっぽい．）

解決策は，perldocに書いてある通り，use subsを使って前方宣言すればよいらしい．
ただし，use subsを使うやり方のデメリットとして以下の2つを考えた，
- 委譲を許すメソッド名を列挙しなければいけなくてDRYに反する．
- AUTOLOAD内の処理をテストできない（前方宣言さえしていればcanはコードリファレンスを返してしまってAUTOLOADを実行しない）

メリットとしてはhitodeさんに言われたけれど補完が効くことが挙げられる．

## 採用したやり方
AUTOLOAD内の処理をテストできないのが一番よくないと思っていて，（何かやり方ないかな）
結局テストは以下のように書いた．

```perl
use Test::More;
use Test::Fatal;
use Test::Mock::Guard;

my $stub_ref = sub { return 1 };

my $user_mock_funcs = +{
    user_items           => $stub_ref,
    user_following_tags  => $stub_ref,
    user_following_users => $stub_ref,
    user_stocks          => $stub_ref,
    user                 => $stub_ref,
};

my $mock = mock_guard 'Net::Qiita::Client::Users', $user_mock_funcs;

for (keys %$user_mock_funcs) {
    is Net::Qiita->$_, 1;
}

like exception {Net::Qiita->nainai; }, qr(no such func);
```
<S>委譲するメソッドを例外を投げるだけのスタブにして，その例外をキャッチできたら，正しく委譲できているとしている．</S>
hitodeさん「例外投げなくても1とか返せばいいんじゃないですか」「はい」

例外投げる意味何もなかったので，1返すようにした．

デメリットは，Test::Mock::GuardとかTest::MockObjectでスタブ化しないといけないので，テストコードが冗長になってしまうこと．
ただ，本体のコードが冗長になるよりは，テストコードが冗長になる方がマシだと思っているのでとりあえずこうしている．

サボるとしたら，スタブ化をやめてno such func以外の例外メッセージをキャッチしたら正しいみたいにするか．
```perl
unlike exception {Net::Qiita->user_items}, qr(no such func)
```
ただし，今回の場合はuser_itemsの中でHTTPリクエストを投げるので，タイムアウトするまでテストが終わらないとかになってダサいので，スタブにしてる．


ベストプラクティスほしい．
