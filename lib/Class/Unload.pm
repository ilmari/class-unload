package Class::Unload;
# ABSTRACT: Unload a class

use warnings;
use strict;
no strict 'refs'; # we're fiddling with the symbol table

use Class::Inspector;
BEGIN { eval "use Hash::Util"; } # since 5.8.0

=encoding UTF-8

=head1 SYNOPSIS

    use Class::Unload;
    use Class::Inspector;

    use Some::Class;

    Class::Unload->unload( 'Some::Class' );
    Class::Inspector->loaded( 'Some::Class' ); # Returns false

    require Some::Class; # Reloads the class

=method unload $class

Unloads the given class by clearing out its symbol table and removing it
from %INC.  If it's a L<Moose> class, the metaclass is also removed.

Avoids unloading internal core classes, like main, CORE, Internals,
utf8, UNIVERSAL, PerlIO, re.

Handles restricted class (protected stashes) and ISA's.

=cut

sub unload {
    my ($self, $class) = @_;

    return unless Class::Inspector->loaded( $class );

    if ($class =~ /\A(main|CORE|Internals|utf8|UNIVERSAL|PerlIO|re)\z/) {
        require Carp;
        Carp::carp("Cannot unload $class");
        return;
    }

    my $symtab = $class.'::';
    my ($was_locked, $was_readonly);
    if (defined $Hash::Util::VERSION) {
        if (Hash::Util::hash_locked %{$symtab}) {
            Hash::Util::unlock_hash %{$symtab};
            $was_locked++;
        }
    }
    elsif (Internals::SvREADONLY(%{$symtab})) {
        Internals::SvREADONLY(%{$symtab}, 0);
        $was_readonly++;
    }

    # Flush inheritance caches
    if (Internals::SvREADONLY(@{"$class\::ISA"})) {
        Internals::SvREADONLY(@{"$class\::ISA"}, 0);
    }
    @{$class . '::ISA'} = ();

    # Delete all symbols except other namespaces
    for my $symbol (keys %$symtab) {
        next if $symbol =~ /\A[^:]+::\z/;
        delete $symtab->{$symbol};
    }

    # Policy: could be restricted further, but perl5 cannot properly handle
    # restricted stashes yet. Avoid AUTOLOAD/DESTROY surprises and keep em unlocked.
    #if ($was_locked) {
    #    Hash::Util::lock_hash %{$symtab};
    #}
    #elsif ($was_readonly) {
    #    Internals::SvREADONLY(%{$symtab}, 1);
    #}

    my $inc_file = join( '/', split /(?:'|::)/, $class ) . '.pm';
    delete $INC{ $inc_file };

    if (Class::Inspector->loaded('Class::MOP')) {
        Class::MOP::remove_metaclass_by_name($class);
    }

    return 1;
}

=head1 SEE ALSO

L<Class::Inspector>

=head1 ACKNOWLEDGEMENTS

Thanks to Matt S. Trout, James Mastros and Uri Guttman for various tips
and pointers.

=cut

1; # End of Class::Unload
