#!/usr/bin/perl
use SOAP::Lite;
use HTML::LinkExtor;
$|=1;

my $GOOGLEPAGECOUNT=5;
my $HTTRACKTIMEOUT=60;
my $HTTRACKTEMPDIR="/tmp";
my $HTTRACKCMD="/usr/bin/httrack";
my $GOOGLEKEY="<<INSERT YOUR GOOGLE API KEY HERE>>";
my $GOOGLE_WSDL="file:GoogleSearch.wsdl";

@exclusions=(
"dmoz.org","microsoft.com","216.239","yahoo.com","ultraseek.com",
"ananzi.co.za","macromedia.com","clickstream","w3.org","adobe.com",
"google.com","geocities.com","linkexchange","zdnet");

if ($#ARGV<1){
	print "Bile-links.pl sitename output_file\n";
	exit;
}
my $input=@ARGV[0];
my $output=@ARGV[1];
open (WRITE,">$output") || die "Cannot write output file $output\n";

#### Round one
@allpairs=get_bile($input);

#report
foreach $pair (@allpairs){
	push @bigpairs,"$pair";
}

#### Round two
foreach $bpair (@allpairs){
	print "## Now working on [$bpair]\n";
	($src,$dst)=split(/\:/,$bpair);
	if ($src ne $input) {
#		print "Bile on [$src]\n";
		push (@allpairs2,get_bile($src));
	}

	if ($dst ne $input) {
#		print "Bile on [$dst]\n";
		push (@allpairs2,get_bile($dst));
	}
}

#report
foreach $pair (@allpairs2){
	push @bigpairs,"$pair";
}


foreach $pair (@bigpairs){
	print WRITE "$pair\n";
}



####################
sub get_bile{
	my ($source)=@_;
	
	my $moo; 
	my $pair; 
	my @pairs; 
	my @temppairs; 
	my @list;
		
	undef @pairs;

	print "\n##Link to $source\n";
	@list=google_api_url("link:$source",$GOOGLEPAGECOUNT);
	foreach $moo (@list){
		$pair="$moo:$source";
		print "$pair\n";
		push @pairs,$pair;
	}

	print "\n##Links from $source\n";
	@list=getlinks($source,3,"",$HTTRACKTIMEOUT);
	foreach $moo (@list){
		$pair="$source:$moo";
		print "$pair\n";
		push @pairs,$pair;
	}
	
	@pairs=dedupe(@pairs);

	## Exclusions
	foreach $pair (@pairs){
		$exflag=0;
		my ($src,$dst)=split(/\:/,$pair);
		if ($src eq $dst){
			$exflag=1;
		} else {
			foreach $exclusion (@exclusions){
				if ($pair =~ /$exclusion/i) {
					$exflag=1;
					$last;
				}
			}
		}
		if ($exflag==0){
			push @temppairs,$pair;
		}
	}
	return @temppairs;	
}

## -------------------------------
sub google_api_url{
## -------------------------------

        my ($query,$numloops)=@_;

        local *ermm = sub {return "timeout" };
        $SIG{"ALRM"}  = \&ermm;

        if ($numloops == 0){
                $numloops=20;
        }
        my @allsites; my $results;
        my $re; my $right;

        # Initialise with local SOAP::Lite file
        my $service = SOAP::Lite
            -> service($GOOGLE_WSDL);

        for (my $i=0; $i<$numloops; $i++){

                my $googleerror="No results";
                my $googleerrorcount=0;

                while (($googleerror ne "") && ($googleerrorcount<5)){
                        eval {
                                alarm(20);
                                $results = $service->doGoogleSearch($GOOGLEKEY,$query,(10*$i),10,"false","","false","","latin1","latin1");
                                alarm(0);
                                $googleerrorcount++;
                        };

                        $googleerror=$@;
                        if ($googleerror =~ /timeout/) {print "Google:timeout\n";}
                }

                $re=(@{$results->{resultElements}});
                foreach my $results(@{$results->{resultElements}}){
                        my $site=$results->{URL};
                        if ($site =~ /http/i){
				(undef,$right)=split(/http:\/\//,$site);
                                ($right,undef)=split(/\//,$right);
                                push @allsites,$right;
                                                }
                }
                if ($re !=10){last;}
        }

        @allsites=dedupe(@allsites);
        return @allsites;
}



#	----------------------------
sub getlinks($$$$)	{		my(	$site, 
						$depth, 
						$proxy, 
						$timeout, )	= @_;
#	----------------------------
	my @get_links				= ();
	
	$SIG{ALRM} = sub {die "timeout" };

# ----------------

	local *callback_links		= sub($%)	{my($tag,%links, )	= @_;
	#	----------------------------
		if ( $tag eq 'a' )	{
			my ( $a, $ref )			= @{[%links]};
			my $want;
			if ( $ref =~ /http\:/ )	{
				( undef, $want )	= split /http:\/\//, $ref;
				( $want, undef )	= split /[\/\?\&\%]/,		$want;
				push @get_links, $want;	}
			if ( $ref =~ /mailto\:/ )	{
				( undef, $want )	= split /\@/, $ref;
				( $want, undef )	= split /\?/, $want;
				push @get_links, "www.$want";	}
			}		# end if ( $tag eq 'a' )
		};		# end sub callback_links
#	----------------------------
	if ( length($site) < 3 )	{	return "";			}
	if ( length($timeout) < 1 )	{	$timeout	= 600;	}
	if ( $timeout == 0 )		{	$timeout	= 1000;	}
	if ( $depth == 0 )			{	$depth		= 3;	}
	my $rc						= system("rm -Rf $HTTRACKTEMPDIR/bigredwork.$site");
	my $mc;
	if ( length($proxy) > 1 )	{
		$mc						= "$HTTRACKCMD $site -P $proxy --max-size=350000 --max-time=$timeout -I0 --quiet --do-not-log -O $HTTRACKTEMPDIR/bigredwork.$site --depth=$depth -%v-K -*.gif -*.jpg -*.pdf -*.zip -*.dat -*.exe -*.doc -*.avi -*.pps -*.ppt 2>&1 /dev/null";	}
	else	{
		$mc						= "$HTTRACKCMD $site --max-size=350000 --max-time=$timeout -I0 --quiet --do-not-log -O $HTTRACKTEMPDIR/bigredwork.$site --depth=$depth -%v-K -*.gif -*.jpg -*.pdf -*.zip -*.dat -*.exe -*.doc -*.avi -*.pps -*.ppt 2>&1 /dev/null";	}
	eval {
		alarm ($timeout);
		$rc						= system($mc);
		alarm(0);
	};

	if ($@ =~ /timeout/) {
                # this is nasty, but we have to kill the process - line the boot with plastic
                print "[$HTTRACKCMD] : Time out - killing process\n";

                # not nice..not nice..but else you could zomebie out
                my @res=`ps -ax | grep $HTTRACKCMD | grep $site`;
				foreach my $kak (@res){
					$kak =~ s/ +/ /g;
					my ($pid,undef)=split(/ /,$kak);
	                kill 9, $pid;
				}
	}

	my $mirror= HTML::LinkExtor->new( \&callback_links );
	$mirror->parse_file("$HTTRACKTEMPDIR/bigredwork.$site/hts-cache/new.dat");
	$rc=system("rm -Rf $HTTRACKTEMPDIR/bigredwork.$site");

	return dedupe(@get_links);
}		# end sub getlinks


########## dedupe
sub dedupe
{
        (@keywords) = @_;
        my %hash = ();
        foreach (@keywords) {
                $_ =~ tr/[A-Z]/[a-z]/;
                chomp;
                if (length($_)>1){$hash{$_} = $_;}
        }
        return keys %hash;
}
