#!perl -T

use Class::Inspector;
use Class::Unload;
use lib 't/lib';
BEGIN { eval "use Hash::Util"; } # since 5.8.0

use Test::More tests => 12;

for my $class ( qw/ MyClass::Sub::Sub MyClass::Sub MyClass / ) {
    no strict 'refs';
    eval "require $class" or diag $@;
    if (defined $Hash::Util::VERSION) {
        Hash::Util::lock_keys(%{$class."::"});
    } else {
        Internals::SvREADONLY(%{$class."::"}, 1);
    }
}

ok( Class::Unload->unload( 'MyClass' ), 'Unloading MyClass' );
ok( ! Class::Inspector->loaded( 'MyClass' ), 'MyClass is not loaded' );
ok( ! exists(${'MyClass::'}{'::ISA::CACHE::'}), 'Stash cruft deleted' );
ok( Class::Inspector->loaded( 'MyClass::Sub' ), 'MyClass::Sub is still loaded' );

ok( Class::Unload->unload( 'MyClass::Sub' ), 'Unloading MyClass::Sub' );
ok( ! Class::Inspector->loaded( 'MyClass::Sub' ), 'MyClass::Sub is not loaded');

ok( Class::Unload->unload( 'MyClass::Sub::Sub' ), 'Unloading MyClass::Sub::Sub' );
ok( ! Class::Inspector->loaded( 'MyClass::Sub::Sub' ), 'MyClass::Sub::Sub is not loaded');

ok( ! Class::Unload->unload('MyClass'), 'Unloading not-loaded class');

ok( Class::Unload->unload( 'Class::Unload' ), 'Unloading Class::Unload' );
ok( ! Class::Inspector->loaded( 'Class::Unload' ), 'Class::Unload is not loaded' );

eval { Class::Unload->unload( 'dummy' ) };
if ($^V =~ /c$/ and $] >= 5.027002) {
    is( $@, '', "unload unloaded class");
} else {
    like( $@, qr/Can't locate object method "unload" via package "Class::Unload"/,
          "Can't call method on unloaded class" );
}
