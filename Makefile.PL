use ExtUtils::MakeMaker;
my @opt=(
	 PREREQ_PM => { Test => 1, Event => '0.40' },
	 VERSION_FROM => './VERSION',
	 NAME => 'Event::tcp'
	);

WriteMakefile(@opt);
