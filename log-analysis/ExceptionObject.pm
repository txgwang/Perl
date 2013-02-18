package ExceptionObject;    #Class

sub new {
	my $class = shift;

	my $ref = {
		"name"     => '',   #exception name
		"message"  => '',   #exception message
		"content"  => '',  #stack trace content, a list of lines of stack-trace
		"count"    => 1,    #how many times it occurs, default is zero.
		"location" => "",   #the first line of stack-trace
		"module"   => '',   #module name
		"dates"     => '',   #the dates where this exception happened
		"aggregated" => 0,  #standalone or not.
	};

	bless( $ref, $class );
	return $ref;
}

##################################################
# getter/setter below
##################################################
sub set_name {
	my $self = shift;
	$self->{"name"} = shift;
}

sub get_name() {
	my $self = shift;
	return $self->{"name"};
}

sub set_message {
	my $self = shift;
	$self->{"message"} = shift;
}

sub get_message() {
	my $self = shift;
	return $self->{"message"};
}

sub set_content {
	my $self = shift;
	$self->{"content"} = shift;
}

sub get_content() {
	my $self = shift;
	return $self->{"content"};
}

sub set_count {
	my $self = shift;
	$self->{"count"} = shift;
}

sub get_count() {
	my $self = shift;
	return $self->{"count"};
}

sub set_location {
	my $self = shift;
	$self->{"location"} = shift;
}

sub get_location() {
	my $self = shift;
	return $self->{"location"};
}

sub set_module {
	my $self = shift;
	$self->{"module"} = shift;
}

sub get_module() {
	my $self = shift;
	return $self->{"module"};
}

sub set_date {
	my $self = shift;
	$self->{"dates"} = shift;
}

sub get_date() {
	my $self = shift;
	return $self->{"dates"};
}

sub set_aggregated {
	my $self = shift;
	$self->{"aggregated"} = shift;
}

sub get_aggregated() {
	my $self = shift;
	return $self->{"aggregated"};
}
####################################################################
# getter/setter end
####################################################################

sub append_content(){
	my $self = shift;
	$self->{"content"} .= shift;
	$self->{"content"} .= "\n";
}

sub appendNewDate(){
	my ( $self, $new_date ) = @_;
	
	my $original_date = $self->get_date();
	if($original_date =~/$new_date/){
		#already contained, do nothing
	} else {
		$self->set_date($original_date.", ".$new_date);
	}
}

sub adjust_location(){
	my $self = shift;
	#com.mycompany, first occurrence of stack-trace
	my @onefbusa = grep(/mycompany/, split("\n", $self->get_content()));
	#print $onefbusa[0];
	if($#onefbusa >= 0){
		$self->set_location($onefbusa[0]);
	} else {
		$self->set_location($self->get_message());
	}
	
#	my @exceptions = grep(/\SException/, split("\n", $self->get_content()));
#	if($#exceptions){
#		$self->set_name($exceptions[0]);
#	}
}

sub increase_count_by_one() {
	my $self = shift;
	$self->{"count"} = $self->{"count"} + 1;
}

sub display() {
	my $self = shift;
	print "name		    =>$self->{'name'} ";
	print "message		=>$self->{'message'}";
	print "count		=>$self->{'count'}\n";
	print "location		=>$self->{'location'}";
	print "module		=>$self->{'module'}\n";
}

sub equals() {
	
	my ( $self, $other ) = @_;
	bless( $other, ExceptionObject );

	my $equal = 1;


	if ( $self->{"location"} eq $other->{"location"} ) {
		#do nothing, pass this validation
	}
	else {
		$equal = 0;
	}

#	if ( $self->{"name"} eq $other->{"name"} ) {
#		#do nothing, pass this validation
#	}
#	else {
#		$equal = 0;
#	}

#	if ( $self->{"message"} eq $other->{"message"} ) {
#		#do nothing, pass this validation
#	}
#	else {
#		$equal = 0;
#	}
	#	print "equal?		        =>$equal  \n";
	#	print "self location		=>$self->{'location'} \n";
	#	print "other location		=>$other->{'location'} \n";

	#	$self->display();
	#	print "=======================\n";
	#	$other->display();
	#	print "xxxxxxxxxxxxxxxxxxx\n";

	return $equal;
}

1;
