#!perl -T

use Class::Inspector;
use Class::Unload;
use lib 't/lib';

use Test::More tests => 10;

for my $class ( qw/ MyClass MyClass::Sub / ) {
    eval "require $class" or diag $@;
    ok( Class::Inspector->loaded( $class ), "$class loaded" );
}

ok( Class::Unload->unload( 'MyClass' ), 'Unloading MyClass' );
ok( ! Class::Inspector->loaded( 'MyClass' ), 'MyClass is not loaded' );
ok( Class::Inspector->loaded( 'MyClass::Sub' ), 'MyClass is still loaded' );

ok( Class::Unload->unload( 'MyClass::Sub' ), 'Unloading MyClass::Sub' );
ok( ! Class::Inspector->loaded( 'MyClass::Sub' ), 'MyClass::Sub is not loaded');

ok( Class::Unload->unload( 'Class::Unload' ), 'Unloading Class::Unload' );
ok( ! Class::Inspector->loaded( 'Class::Unload' ), 'Class::Unload is not loaded' );

eval { Class::Unload->unload( 'dummy' ) };
like( $@, qr /Can't locate object method "unload" via package "Class::Unload"/,
      "Can't call method on unloaded class" );
