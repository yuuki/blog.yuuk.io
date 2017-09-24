---
Title: "最近使ったPerlのテスト系モジュール"
Category:
- Perl
Date: 2012-09-27T20:19:07+09:00
URL: http://blog.yuuk.io/entry/2012/09/27/%E6%9C%80%E8%BF%91%E4%BD%BF%E3%81%A3%E3%81%9FPerl%E3%81%AE%E3%83%86%E3%82%B9%E3%83%88%E7%B3%BB%E3%83%A2%E3%82%B8%E3%83%A5%E3%83%BC%E3%83%AB
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/12704591929890725825
---

最近Perlを書いていて，便利なテスト系モジュールをいくつか使ったのでメモ．

- [http://search.cpan.org/~mschwern/Test-Simple-0.98/lib/Test/More.pm:title=Test::More]のsubtestメソッド
- [https://metacpan.org/module/Test::Mock::LWP::Conditional:title=Test::Mock::LWP::Conditional]
- [http://search.cpan.org/~chromatic/Test-MockObject-1.20120301/lib/Test/MockObject/Extends.pm:title=Test::MockObject::Extends]
- [http://search.cpan.org/dist/Test-Exception/:title=Test::Exception]
- [http://search.cpan.org/~xaicron/Test-Mock-Guard-0.08/lib/Test/Mock/Guard.pm:title=Test::Mock::Guard]

**[http://search.cpan.org/~mschwern/Test-Simple-0.98/lib/Test/More.pm:title=Test::More]のsubtestメソッド

RSpecのitメソッドみたいな感じ．
テストをブロックに分けてそれぞれのブロックに名前を付けることができるイメージ．

>|perl|
use Test::More;

subtest "description" => sub {
    # テスト書く
}; 
||<

**[https://metacpan.org/module/Test::Mock::LWP::Conditional:title=Test::Mock::LWP::Conditional]
LWP::UserAgentのリクエストスタブ．
LWP::UserAgentで任意のURLに対応するレスポンスを指定できる．

>|perl|
    my $res = HTTP::Response->new(200);
    $res->content("インターネット");
    Test::Mock::LWP::Conditional->stub_request("www.internet.com" => $res);
    
    # 以降，LWP::UserAgentで"www.internet.com"をGETしたらステータスコード200でcontentが"インターネット"で返ってくる
||<


** [http://search.cpan.org/~chromatic/Test-MockObject-1.20120301/lib/Test/MockObject/Extends.pm:title=Test::MockObject::Extends]
既存のクラスに含まれるメソッドをMockに置き換える．（Test::Mockは既存のクラスをMockに置き換える）

>|perl|
    # インスタンスメソッドをMockに置き換え
    my $internet = Net::Internet->new;
    my $mock = Test::MockObject::Extends->new($internet);
    $mock->set_always("service", +{ hatena => "www.hatena.ne.jp" });

    is $mock->service->{hatena}, "www.hatena.ne.jp";

    # newの引数にクラス名を指定することで，クラスメソッドを置き換えることもできる
    my $mock = Test::MockObject::Extends->new("Net::Internet");
    $mock->set_always("static_service", +{ twitter => "twitter.com" });

    is $mock->static_service->{hatena}, "twitter.com";
||<

** [http://search.cpan.org/dist/Test-Exception/:title=Test::Exception]
croakやdieで投げた例外をテストできるモジュール．

>|perl|
    # doメソッドがcroak "No Such Internetを含むエラーメッセージ"を投げるかどうかテスト
    throws_ok {
        my $internet = Net::Internet->do("Facebook");
    } qr(No Such Internet);
||<

** [http://search.cpan.org/~xaicron/Test-Mock-Guard-0.08/lib/Test/Mock/Guard.pm:title=Test::Mock::Guard]
Mockオブジェクトを作成するモジュール．
Test::MockObjectよりもシンプル．

>|perl|
    # Net::InternetクラスをMock化する
    my $mock = mock_guard 'Net::Internet',
        +{
            do => sub { 
                my $self = shift;
                return +{ SAO => 'SwordArtOnline' };
             },
        };

    my $internet = Net::Internet->new;
    is $internet->do->{SAO}, 'SwordArtOnline';
||<

** 参考
- [http://blog.64p.org/entry/20100118/1263800343:title]
- [http://perl-users.jp/articles/advent-calendar/2011/test/16:title]
- [http://perldoc.jp/docs/modules/Test-Exception-0.31/Exception.pod:title]
- [http://d.hatena.ne.jp/yokkuns/20090920/1253410002:title]
- [http://d.hatena.ne.jp/ZIGOROu/20110308/1299605305:title]


テストかこう
