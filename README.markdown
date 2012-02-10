#1. Name
BiLE-Public
#2. Author
Roelof Temmingh
#3. License, version & release date
License : GPLv2  
Version : v1.0  
Release Date : Unknown

#4. Description
BiLE stands for Bi-directional Link Extraction. It is used in the footprinting process to find non-obvious relationships between different web sites
#5. Usage
##5.1 Configuration
configure the constants listed in bile-public-ext.pl.   

my $GOOGLEPAGECOUNT=5; 
- How many seconds to wait for a page on Google

my $HTTRACKTIMEOUT=60; 
- How long to wait for the mirror of a site to complete

my $HTTRACKTEMPDIR="/tmp"; 
- Where to store temporary mirrors

my $HTTRACKCMD="/usr/bin/httrack";
- The location of the HTTtrack executable

my $GOOGLEKEY="<<INSERT YOUR GOOGLE API KEY HERE>>";
- Your Google API key

my $GOOGLE_WSDL="file:GoogleSearch.wsdl";
- Location of the Google WSDL file

##5.2 run bile-public-ext.pl
takes two arguments:  

- argument one: the web site (e.g. www.abc.com)
- argument two: the output file (where the pairs will be written to)

##5.3 Compute the weights:
use bile-public-weigh.pl  

- argument one: the web site 
- argument two: the input file containing the pairs (generated in step one)
- argument three: the output file - where the weights will be written

#6. Requirements
httrack (just about any version would do)  
CPAN modules:  

- SOAP::Lite  
- HTML::LinkExtor  
And a valid Google API key (api.google.com).


