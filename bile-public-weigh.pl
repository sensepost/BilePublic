#!/usr/bin/perl

# Bile Weigh Standalone
# Version 2.3
# Original Author: roelof@sensepost.com
# 2003-12-10 - hy - Split into standalone units again
# 2004-01-23 - rt - Cleaned up and some bug fixes
$|=1;

#We need to clean out the links before we go again so we don't waste
@exceptionlist = ( "microsoft.com", "216.239", "yahoo.com",
                   "ultraseek.com", "ananzi.co.za", "macromedia.com", "clickstream",
                  "w3.org",         "adobe.com", "google.com", "geocities.com","linkexchange");

if ($#ARGV<2){die "perl bile-weigh.pl website inputfile outputfile\n";}

$tocheck = $ARGV[0];
$infile  = $ARGV[1];
$outfile = $ARGV[2];

open(INPUT,"$infile" )     || die("No input file\n");
open(OUTPUT,"+>>$outfile" ) || die("Cant create outfile\n");

@big = <INPUT>;
close INPUT;

&bileweighmain;


#########################
sub bileweighmain {

#Now do the bile weigh...
#Clean out the list first

	foreach $test (@big) {
		$flag = 0;
		($test1, $test2) = split(/:/,$test );

		foreach $except (@exceptionlist) {
			if ($test =~ /$except/) {$flag = 1;}
		}

		if (($test1 ne $test2) && ($flag == 0)){
			push @weighlist, $test;
		}
	}

	@blast = &bile_weigh(@weighlist);

	foreach $bl(@blast){
		print OUTPUT "$bl\n";
	}
	close OUTPUT;
} 


############ Bile Weigh #############
sub bile_weigh {

	@structure = @_;
	$sites{$tocheck} = 300;

	####################compute first round cell node values
	#    print "compute nodes\n";
	#    print "Nodes alone\n";

	$ws = weight($tocheck, "s");
	$wd = weight($tocheck, "d");
	#    print "src $ws dst $wd\n";
	
	foreach $piece (@structure) {
	        ($src, $dst, $cellid) = split( /:/, $piece );
        	chomp $src;
	        chomp $dst;
        	chomp $tocheck;
		
	        ## link -from- X to node
        	if ($src eq $tocheck) {
			$newsites{$dst} = $newsites{$dst} + ($sites{$src} * (1/$ws));
            	}

	        ## link -to- X from node
        	if ($dst eq $tocheck) {
			$newsites{$src} = $newsites{$src} + ( $sites{$dst} * ( 0.6 / $wd ) );
		}
        }

	## write the new structure
	foreach $blah (keys %newsites) {
		$temp = "$blah:$newsites{$blah}\n";
		push @btotal, $temp;
	}

	## prepare for the new run
	undef $sites;
	undef %sites;
	$sites = "";

	## write in back to the old struct
	#print "CORE WEIGHTS\n\n";
	foreach $newnode (@btotal) {
		chomp $newnode;
		# print "$newnode\n";
		($node, $value) = split(/:/, $newnode);
		$sites{$node} = $value;
	}

	
	
	########## Now we test between nodes

	@mytest = %sites;
	foreach $blah ( keys %sites ) {
		chomp $blah;

		#print "\n[Testing with node $blah]\n";
		$ws = weight($blah, "s");
		$wd = weight($blah, "d");

		# print "src $ws dst $wd\n";
		foreach $piece (@structure) {
			($src, $dst, $cellid ) = split( /:/, $piece );
			chomp $src;
			chomp $dst;

			# print "src [$src] dst [$dst]\n";

			## link -from- node to other node (2/3)
			if ($src eq $blah) {
				$prev=$newsites{$dst};
				$newsites{$dst} = $newsites{$dst} + ( $sites{$src} * ( 1 / $ws ) );
				$add  = ( $sites{$src} * ( 1 / $ws ) );
				$orig = $sites{$src};

				#print "FROM:Added to $dst number $add ($orig $ws) - was $prev\n";
			}

			## link -to- node from nodes (1/3)
			if ($dst eq $blah) {
				$prev=$newsites{$src};
				$newsites{$src} = $newsites{$src} + ( $sites{$dst} * ( 0.6 / $wd ) );
		                $add  = ( $sites{$dst} * ( 0.6 / $wd ) );
                		$orig = $sites{$dst};

				#print "TO:Added to $src number $add ($orig $wd) - was $prev\n";
			}
		}
	} 

	# write to structure
	undef @btotal;
	foreach $blah (keys %newsites){
		chomp $blah;
		$temp = "$blah:$newsites{$blah}\n";
		push @btotal, $temp;
	}

	@btotal = dedupe(@btotal);
	@btotal = sort(@btotal);

	##### Sort the stuff

	undef @temp;
	$old = "";
	foreach $sort (@btotal){
		($name, $count) = split( /:/, $sort );
		if ($name ne $old) { 
			push @temp, $count.":".$name.":".sprintf("%.3f", $count );
			$old = $name;
		}
	}

	@temp = sort { $b <=> $a } @temp;
	
	undef @btotal;
	foreach $sort (@temp){
		($crap, $name, $count) = split( /:/, $sort );
		push @btotal, $name . ":" . $count;
	}  

	return @btotal;
}


########################
sub weight {
        ($site, $mode) = @_;
        $from = 0;
        $to   = 0;
        foreach $piece (@structure){
            ($src, $dst, $cellid) = split(/:/, $piece);
            chomp $src;
            chomp $dst;
            chomp $site;
            if ($dst eq $site) {$from++;}
            if ($src eq $site) {$to++;}
        } 

        if ($mode eq "s") {return $to;}
        if ($mode eq "d") {return $from;}
}

###########Dedupe ##########
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


