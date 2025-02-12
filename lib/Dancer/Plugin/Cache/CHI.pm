package Dancer::Plugin::Cache::CHI;
# ABSTRACT: Dancer plugin to cache response content (and anything else)

use strict;
use warnings;

use Dancer 1.1904 ':syntax';
use Dancer::Plugin;

use CHI;

=head1 SYNOPSIS

In your configuration:

    plugins:
        'Cache::CHI':
            driver: Memory
            global: 1

In your application:

    use Dancer ':syntax';
    use Dancer::Plugin::Cache::CHI;

    # caching pages' response
    
    check_page_cache;

    get '/cache_me' => sub {
        cache_page template 'foo';
    };

    # using the helper functions

    get '/clear' => sub {
        cache_clear;
    };

    put '/stash' => sub {
        cache_set secret_stash => request->body;
    };

    get '/stash' => sub {
        return cache_get 'secret_stash';
    };

    # using the cache directly

    get '/something' => sub {
        my $thingy = cache->compute( 'thingy', sub { compute_thingy() } );

        return template 'foo' => { thingy => $thingy };
    };

=head1 DESCRIPTION

This plugin provides Dancer with an interface to a L<CHI> cache. Also, it
includes a mechanism to easily cache the response of routes.

=head1 CONFIGURATION

The plugin's configuration is passed directly to the L<CHI> object's
constructor. For example, the configuration given in the L</SYNOPSIS>
will create a cache object equivalent to

    $cache = CHI->new( driver => 'Memory', global => 1, );

=head1 KEYWORDS

=head2 cache

Returns the L<CHI> cache object.

=cut

my $cache;
register cache => sub {
    return $cache ||= CHI->new(%{ plugin_setting() });
};

=head2 check_page_cache

If invoked, returns the cached response of a route, if available.

The C<path_info> attribute of the request is used as the key for the route, 
so the same route requested with different parameters will yield the same
cached content. Caveat emptor.

=cut

register check_page_cache => sub {
    before sub {
        if ( my $cached =  cache()->get(request->{path_info}) ) {
            halt $cached;
        }
    };  
};

=head2 cache_page($content, $expiration)

Caches the I<$content> to be served to subsequent requests. The I<$expiration>
parameter is optional.

=cut

register cache_page => sub {
    return cache()->set( request->{path_info}, @_ );
};

=head2 cache_set, cache_get, cache_clear, cache_compute

Shortcut to the cache's object methods.

    get '/cache/:attr/:value' => sub {
        # equivalent to cache->set( ... );
        cache_set $params->{attr} => $params->{value};
    };

=cut 

for my $method ( qw/ set get clear compute / ) {
    register 'cache_'.$method => sub {
        return cache()->$method( @_ );
    }
}

register_plugin;

__END__

=head1 SEE ALSO

Dancer Web Framework - L<Dancer>

L<Dancer::Plugin::Memcached> - plugin that heavily inspired this one.

=cut
