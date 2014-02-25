package PDA::Simple;
use 5.008005;
use Mouse;

our $VERSION = "0.01";

has 'init_state' => (
    is => 'rw',
    isa => 'Str',
    default => '__INIT__'
    );
has 'final_state' => (
    is => 'rw',
    isa => 'Str',
    default => '__FINAL__'
    );
has 'acceptable_state' => (
    is => 'rw',
    isa => 'Str',
    default => '__ACCEPTABLE__'
    );
has 'acceptable' => (
    is => 'rw',
    isa => 'Num',
    default => 0
    );
has 'stack_s' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub {[]}
    );

has 'stack_a' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub {[]}
    );

has 'stack_b' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub {[]}
    );

has 'model' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub {
	{
	    '__INIT__' => {},
	    '__FINAL__' => {}
	}
    }
    );

has 'acceptables' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub {{}}
    );



sub add_state{
    my $self = shift;
    my $state_name = shift;
    my $model = $self->model;
    if(defined($model->{$state_name})){
	warn "$state_name : Already exist\n";
    }else{
	$model->{$state_name} = {};
	$self->model($model);
    }
}

sub add_acceptables{
    my $self = shift;
    my $state = shift;
    my $acceptables = $self->acceptables;
    if(($state eq $self->init_state) or ($state eq $self->final_state)){
	warn "can't add acceptables\n";
    }else{
	unless(defined($acceptables->{$state})){
	    $acceptables->{$state} = 1;
	}
    }
}


sub add_trans{
    my $self = shift;
    my $from_state = shift;
    my $input = shift;
    my $to_state = shift;
    my $model = $self->model;
    if($from_state eq $self->final_state){
	warn "can't add this transition: from final state\n";
	return 0;
    }elsif($to_state eq $self->init_state){
	warn "can't add this transition: to initial state\n";
	return 0;
    }else{
	if(defined($model->{$from_state})){
	    my $trans_func = $model->{$from_state};
	    if(defined($trans_func->{$input})){
		warn "$input of $from_state : Already exist\n";
		return 0;
	    }else{
		$trans_func->{$input} = $to_state;
		$model->{$from_state} = $trans_func;
		return 1;
	    }
	}else{
	    warn "$from_state : No such state.\n";
	    return 0;
	}
    }
}

sub add_trans_to_final{
    my $self = shift;
    my $from_state = shift;
    my $input = shift;
    my $to_state = $self->final_state;
    my $model = $self->model;
    if($from_state eq $self->final_state){
	warn "can't add this transition: from final state\n";
	return 0;
    }else{
	if(defined($model->{$from_state})){
	    my $trans_func = $model->{$from_state};
	    if(defined($trans_func->{$input})){
		warn "$input of $from_state : Already exist\n";
		return 0;
	    }else{
		$trans_func->{$input} = $to_state;
		$model->{$from_state} = $trans_func;
		return 1;
	    }
	}else{
	    warn "$from_state : No such state.\n";
	    return 0;
	}
    }
}

sub add_trans_from_init{
    my $self = shift;
    my $input = shift;
    my $to_state = shift;
    my $from_state = $self->init_state;
    my $model = $self->model;
    if($to_state eq $self->init_state){
	warn "can't add this transition: to initial state\n";
	return 0;
    }else{
	if(defined($model->{$self->init_state})){
	    my $trans_func = $model->{$self->init_state};
	    if(defined($trans_func->{$input})){
		warn "$input of ".$self->init_state." : Already exist\n";
		return 0;
	    }else{
		$trans_func->{$input} = $to_state;
		$model->{$self->init_state} = $trans_func;
		return 1;
	    }
	}else{
	    warn $self->init_state." : No INIT state!!\n";
	    return 0;
	}
    }
}

sub reset_stack{
    my $self = shift;
    $self->stack_s([]);
    $self->stack_a([]);
    $self->stack_b([]);
    $self->acceptable(0);
    return 1;
}

sub export_model{
    my $self = shift;
    return($self->model);
}

sub import_model{
    my $self = shift;
    my $model = shift;
    if(defined($model->{$self->init_state}) and
       defined($model->{$self->final_state})){
	$self->model($model);
	return 1;
    }else{
	warn "import_model : this model has no init state or final state\n";
	return;
    }
}

sub transit{
    my $self = shift;
    my $input = shift;
    my $attr = shift;
    my $model = $self->model;

    my $stack_s = $self->stack_s;
    my $stack_a = $self->stack_a;
    my $stack_b = $self->stack_b;
    
    my $current_state = $self->init_state;
    if(defined($stack_s->[$#$stack_s])){
	$current_state = $stack_s->[$#$stack_s];
    }

    my $trans = $model->{$current_state};
    if(defined($trans->{$input})){
	my $next_state = $trans->{$input};
	if(defined(${$self->acceptables}->{$next_state})){
	    $self->acceptable(1);
	}
	if($next_state eq $self->final_state){
	    push(@$stack_s,$next_state);
	    push(@$stack_a,$input);
	    push(@$stack_b,$attr);
	    $self->reset_state();
	    return ({
		state => $next_state,
		stack_s => $stack_s,
		stack_a => $stack_a,
		stack_b => $stack_b
		    });
	}else{
	    push(@$stack_s,$next_state);
	    push(@$stack_a,$input);
	    push(@$stack_b,$attr);
	    $self->stack_s($stack_s);
	    $self->stack_a($stack_a);
	    $self->stack_b($stack_b);
	    return;
	}
    }else{
	if($self->acceptable == 1){
	    push(@$stack_s,$self->acceptable_state);
	    push(@$stack_a,$input);
	    push(@$stack_b,$attr);
	    $self->reset_state();
	    return ({
		state => $self->acceptable,
		stack_s => $stack_s,
		stack_a => $stack_a,
		stack_b => $stack_b
		    });
	}else{
	    $self->reset_state();
	    return;
	}
    }
}

sub delete_dead_state{
    my $self = shift;
    my $model = $self->model;
    my $refered;
    my $delete_count = 0;
    foreach my $key (sort keys %$model){
	my $state = $model->{$key};
	foreach my $input (sort keys %$state){
	    $refered->{$state->{$input}} = 1;
	}
    }
    foreach my $key (sort keys %$model){
	if(($key ne $self->init_state) and ($key ne $self->final_state)){
	    unless(defined($model->{$key}) or defined($refered->{$key})){
		delete $model->{$key};
		$delete_count++;
	    }
	}
    }
    $self->model($model);
    return($delete_count);
}




1;
__END__

=encoding utf-8

=head1 PDA::Simple

PDA::Simple - Push Down Automaton Simple

=head1 SYNOPSIS

    use PDA::Simple;

=head1 DESCRIPTION

PDA::Simple is ...

=head1 LICENSE

Copyright (C) Toshiaki Yokoda.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Toshiaki Yokoda E<lt>E<gt>

=cut

