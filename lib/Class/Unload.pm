package Class::Unload;
# ABSTRACT: Unload a class

use warnings;
use strict;
no strict 'refs'; # we're fiddling with the symbol table

use Class::Inspector;

=head1 SYNOPSIS

    use Class::Unload;
    use Class::Inspector;

    use Some::Class;

    Class::Unload->unload( 'Some::Class' );
    Class::Inspector->loaded( 'Some::Class' ); # Returns false

    require Some::Class; # Reloads the class

=method unload $class

Unloads the given class by clearing out its symbol table and removing it
from %INC.

=cut

sub unload {
    my ($self, $class) = @_;

    return unless Class::Inspector->loaded( $class );

    # Flush inheritance caches
    @{$class . '::ISA'} = ();

    my $symtab = $class.'::';
    # Delete all symbols except other namespaces
    for my $symbol (keys %$symtab) {
        next if $symbol =~ /\A[^:]+::\z/;
        delete $symtab->{$symbol};
    }
    
    my $inc_file = join( '/', split /(?:'|::)/, $class ) . '.pm';
    delete $INC{ $inc_file };
    
    return 1;
}

=head1 SEE ALSO

L<Class::Inspector>

=head1 ACKNOWLEDGEMENTS

Thanks to Matt S. Trout, James Mastros and Uri Guttman for various tips
and pointers.

=cut

1; # End of Class::Unload
