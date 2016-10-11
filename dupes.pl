#!/usr/bin/perl

#use strict;
use Data::Dumper;
use File::Find;
use Digest::MD5;

my $md5_list = undef;
my $dir_list = undef;
my $file_score = undef;

my $searchdir=(defined ($ARGV[0])) ? $ARGV[0] : '.';

find({ wanted => \&process, 
       follow => 1,
       no_chdir => 1}, 
     $searchdir);


mod_score ();

check_dupes ();

#print Dumper($dir_list);
#print Dumper($md5_list);
#print Dumper($file_score);

sub check_dupes {

    if ( defined $file_score ){
	foreach (keys %{$file_score }) {
	    my $cur_md5 = $_;
	    my $list_file = $file_score->{$cur_md5};
	    
#	print Dumper ($list_file);
	    
	    my @file_list = sort {$list_file->{$a} <=> $list_file->{$b} } keys %{$list_file};
#	print Dumper (@file_list);
	    
	    print "# Keep : " . $file_list[0] . ' ' . $list_file->{$file_list[0]} . "\n";
	    shift @file_list;
	    
	    foreach (@file_list) {
		print "# Remove : " . $_ . ' ' . $list_file->{$_}. "\n";
		
		
#	    print 'rm \'' . $_ . '\'' . "\n";
		print 'rm ' . quotemeta($_) .  "\n";
	    }
	    
	}
    }
}

sub mod_score {
    foreach (keys %{$md5_list}) {
	my $cur_md5 = $_;
	my $list_md5_file = $md5_list->{$cur_md5};
#	print Dumper($list_md5_file);

	# get score only for dup to reduce size of hash
	my $nb_file = scalar keys %{$list_md5_file};
	if ( $nb_file > 1 ) {
	    foreach (keys %{$list_md5_file}) {
		my $name = $list_md5_file->{$_}->{name};
		my $dir = $list_md5_file->{$_}->{dir};
		my $score = $dir_list->{$dir};
		$file_score->{$cur_md5}->{$name} = $score;
	    }
	}
    }
}

sub process {
    my $filename = $File::Find::name; # $File::Find::dir.$_;    
    my $file_info = undef;
    
    if ( -f $filename ) {
	update_dir ($File::Find::dir);
	$file_info->{md5} = find_md5 ($filename);
	$file_info->{name} = $filename;
	$file_info->{dir} =  $File::Find::dir;
	$file_info->{size} = -s $filename;
	$md5_list->{$file_info->{md5}}->{$file_info->{name}} = $file_info;

#	print Dumper ($file_info);

    }
}

sub update_dir {
    my $dirname = shift @_;
    
    if ( exists ($dir_list->{$dirname})) {
	$dir_list->{$dirname}++;
    } else {
	$dir_list->{$dirname} = 1;
    }	
}

sub find_md5 {
    my $filename = shift @_;
    open (my $fh, '<', $filename) or die "Can't open '$filename': $!";
    binmode ($fh);
    my $md5 = Digest::MD5->new->addfile($fh)->hexdigest;
    return $md5;
}
