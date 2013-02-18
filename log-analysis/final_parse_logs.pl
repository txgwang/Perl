#! /usr/bin/perl
use ExceptionObject;

sub usage {
	my $msg = shift;
	print <<END

        [$0]  [$msg]

        Script to generate the top 10 Exeption by Anaylysis on the production logs for CS project.

		$0 --final_parse_cs_prod_logs.pl --logFiles [FileOrFolder] --stacktrace [0|1] --central [0|1]

        [File]      full directory path with wildcard to analysis file or folder
        [stacktrace] [1|0], whether stacktrace for the exception is needed to print out or not
        [central]    [1|0], central log server format, Retesh's RFC.
        [example]   perl final_parse_logs.pl  --logFiles ../xfsdcsv1 --stacktrace 1 --central 0

END
	  ;
}

###########################################################################################
# Utility Section
###########################################################################################
sub getArgument {
	my $args          = shift;
	my $argument_name = shift;
	my $argument;

	for ( my $i = 0 ; $i < scalar @$args ; $i += 2 ) {
		if ( $$args[$i] =~ /\-?\-?$argument_name/ ) {
			$argument = $$args[ $i + 1 ];
		}
	}
	if ( !( defined($argument) ) ) {
		die usage( "Missing required argument:" . $argument_name );
	}
	return $argument;
}


###########################################################################################
# Read and Analysis Section
###########################################################################################
my $fileName = getArgument(\@ARGV, "logFiles");
#my $fileName = "E:\\ProductionErrorMessage\\xfsdcsv1";
my $stacktrace_needed = getArgument(\@ARGV, "stacktrace");
#my $stacktrace_needed = 1;
my $isCentral = getArgument(\@ARGV, "central");
#my $isCentral = 1;

if ( -d $fileName ) {
	print "$fileName is a directory! \n";

	#parse  the  *.txt files, which came from Cheetach.pl
	#put all files' name into @fileNameArray
	my $file;
	if($isCentral){
		$file = "$fileName/./*.log"; #xfsdcsv1.2012-08-30.log
	}
	else{
		$file = "$fileName/./cs.log.*"; #cs.log.2012-04-22
	}
	print STDOUT "[INFO] globbing $file  \n";
	@fileNameArray = glob($file);
}
elsif ( -T $fileName ) {
	@fileNameArray = ( $fileName, );
}

my $newException = 1;
my $_line_message;
my $_module_name;
my $_exception_line_number_msg;
my $exceptionName;

my @exceptionCollection;
my $totalExceptions = 0;
my $matched         = 0;
my $exceptionRef    = ExceptionObject->new();
my $whichDate       = '';

foreach $fileInArray (@fileNameArray) {
	##########################################################
	if ( -z $fileInArray ) {
		next;    # file should be empty.
	}

	my $file_open_success = open analysis_log, $fileInArray;
	if ( !$file_open_success ) {
		print "cannot open $fileInArray!";
		die;
	}
	
	#cs.log.2012-04-26-x
	if ( $fileInArray =~ /^.*(\d{4}-\d*-\d*).*/ ) {
		$whichDate = $1 
	}
	print STDOUT "[INFO] processing $fileInArray ...  \n";

	while (<analysis_log>) {
		chomp();
		my $line = $_;

		if ( $line =~ /WARN|INFO/ ) {
			next;
		}
		
		if($isCentral){
			# trim first 25 characters, <Aug 30 10:21:33 xfsdcsv1 >java.lang.NullPointerException
			$line = substr($_, 25); 
		}

		#print $line;

		##########################################################
		# Data Sample
		##########################################################
#2012-04-28 00:04:42,843 ERROR [startup] Newsfeed Purging: Failed to clear newsfeed counter.
#java.util.ConcurrentModificationException
#at java.util.AbstractList$Itr.checkForComodification(AbstractList.java:449)

		##########################################################
		# [module-name], message, Exception-Class
		##########################################################
		#step 1, get the timestamp
		#step 2, get the [module-name]
		if ( $line =~ /\s*ERROR\s*/ ) {
			$exceptionRef->adjust_location();

			aggregateExceptionIntoCollection($exceptionRef, \@exceptionCollection);

			#=============================================
			# ERROR variable initiated necessary,
			#new Exception end after the WARN|INFO line.
			#=============================================
			my $newException               = 0;
			my $_line_message              = '';
			my $_module_name               = '';
			my $_exception_line_number_msg = 0;
			my $exceptionName              = '';
			$exceptionRef = ExceptionObject->new();

			#=============================================
# a new Exception created after ERROR line, until $newException == 0, i.e. WARN|INFO line appear afterwards.
			$newException    = 1;
			$totalExceptions = 1 + $totalExceptions;

			# step 3, get the Message
			if ( $line =~ /^(.*)\s*ERROR\s*\[(.*)\](.*)/ ) {
				$_module_name  = $2;
				$_line_message = $3;

				$exceptionRef->set_module($_module_name);
				$exceptionRef->set_message($_line_message);
				$exceptionRef->set_date($whichDate);
				
				#$line = substr($line, 30)
			}

			$exceptionRef->append_content($line);
			#			print $_module_name;
			next;    #ignore ERROR line for now
		}
		if ($newException) {

# step 4, get the Exception Class, the last Exception-class name for one specific ERROR
			if ( $line =~ /\SException/ ) {
				####org.directwebremoting.extend.MarshallException: Error marshalling int: Format error converting NaN. See the logs for more details.
				$exceptionName = $line;
#				$exceptionRef->{"name"} = $exceptionName;
				$exceptionRef->set_name($exceptionName);

				#flag to retain next-line as part of the message.
				$_exception_line_number_msg = 1;
				$exceptionRef->append_content($line);
				#go-to next line
				next;
			}
		}

		$exceptionRef->append_content($line);
		# step 5, get the Exception content
		if ($_exception_line_number_msg) {
			$exceptionRef->set_location($line);
			bless( $exceptionRef, ExceptionObject );
			#############################################
			$_exception_line_number_msg = 0;
		}
	}
	#append the exception, which is the last in a file, into collection.
	if(!$exceptionRef->get_aggregated()){
		aggregateExceptionIntoCollection($exceptionRef, \@exceptionCollection);
	}
}

##########################################################
# sort the Exception Hash by count, and print out
##########################################################

@sorted_exceptions =
  sort { $b->get_count() <=> $a->get_count() } @exceptionCollection;
print "category sorted in total: $#sorted_exceptions \n";
#print "unsorted: $#exceptionCollection \n";

foreach $exceptionObj (@sorted_exceptions) {
	print "Exception Name        : $exceptionObj->{'name'}  \n";
	print "Exception Message     : $exceptionObj->{'message'} \n";
	print "Exception Count       :$exceptionObj->{'count'} \n";
	print "Exception Line Number* :$exceptionObj->{'location'} \n";
	print "Dates happened        :$exceptionObj->{'dates'} \n";
	if($stacktrace_needed){
		print "stack trace           :$exceptionObj->{'content'} \n";
	}
	print "============================================================= \n";
}
print "woww, total Exception Number is: $totalExceptions \n";

#there are two places call the same routine.
#refer to, http://www.troubleshooters.com/codecorn/littperl/perlsub.htm#ListInputOutputArgs
sub aggregateExceptionIntoCollection {
	my $exceptionRef = $_[0];
	my @exceptionCollection = @{$_[1]};

	my $matched = 0;
	if(@exceptionCollection > 0){
		foreach my $tempExcep (@exceptionCollection) {
			my $temp = $tempExcep;
			bless( $temp, ExceptionObject );

			#$tempExcep->equals($exceptionRef)
			if ( $temp->equals($exceptionRef) ) {

				$matched = 1;
				#find the contained ExceptionObject, and increase count by one.
				$temp->increase_count_by_one();
				$temp->appendNewDate($exceptionRef->get_date());
				$exceptionRef->set_aggregated(1);
				last;
			}
		}
	}
			#content cannot be empty, ignore the first empty exception
	if ( !$matched && $exceptionRef->get_content()){   
		 #not contained by @exceptionCollection, add it into list
		#push( @exceptionCollection, $exceptionRef );
		push(@{$_[1]}, $exceptionRef);
		$exceptionRef->set_aggregated(1);
	}
}
