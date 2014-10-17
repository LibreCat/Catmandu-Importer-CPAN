package Catmandu::Importer::Purr;

use Catmandu::Sane;
use MetaCPAN::API::Tiny;
use Moo;

with 'Catmandu::Importer';

our $VERSION = '0.03';

has prefix => (is => 'ro' , default => sub { "Catmandu" });

# http://api.metacpan.org/v0/release/_mapping
our $RELEASE_FIELDS = [qw(
    abstract archive author authorized date dependency distribution
    download_url first id license maturity name provides resources stat status
    tests version version_numified
)];

has fields => (
    is => 'ro', 
    default => sub { [ qw(id date distribution version abstract) ] },
    coerce => sub {
        ref $_[0] ? $_[0] 
                  : ($_[0] eq 'all' ? $RELEASE_FIELDS 
                                    : [ split /,/, $_[0] ]);
    }
);

has mcpan => (is => 'ro', builder => sub { MetaCPAN::API::Tiny->new });

sub generator {
	my $self = $_[0];
	my $prefix = $self->prefix;
	my $result = $self->mcpan->post(
        'release',
        {   
            query  => {
        	  bool => {
            	should => [{
                	term => {
                    	"release.status" => "latest"
                	}
            	}]
              }
        	},
            fields => $self->fields,
            size   => 1024,
            filter => { prefix => { archive => $prefix } },
        },
 	);

	my @hits = @{$result->{hits}->{hits}};

	return sub {
		my $hit = shift @hits;
		return undef unless $hit;
		return {
            map { $_ => $hit->{fields}->{$_} } @{$self->fields}
		}
	};
}

1;
__END__

=head1 NAME 

Catmandu::Importer::Purr - Perl Utility for Recent Releases

=head1 SYNOPSIS

 use Catmandu::Importer::Purr;

 my $importer = Catmandu::Importer::Purr->new(prefix => 'Catmandu');
 
 $importer->each(sub {
	my $module = shift;
	print $module->{id} , "\n";
	print $module->{date} , "\n";
	print $module->{distribution} , "\n";
	print $module->{version} , "\n";
	print $module->{abstract} , "\n";
 });
 
 # or

 $ catmandu convert Purr

=head1 CONFIGURATION

=over

=item prefix

=item fields

Array reference or comma separated list of fields to get.  The special value
C<all> will return all fields.  Set to C<id,date,distribution,version,abstract>
by default.

=back

=head1 CONTRIBUTORS

Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

Jakob Voß C<< <jakob.voss at gbv.de> >>

=head1 SEE ALSO

L<Catmandu>, L<Catmandu::Importer>

=cut
