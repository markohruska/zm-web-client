#!/usr/bin/perl

use strict;
use warnings;

use Config;
use Cwd;
use Data::Dumper;
use File::Basename;
use File::Copy;
use File::Path qw/make_path/;
use Getopt::Long;
use IPC::Cmd qw/run can_run/;
use Term::ANSIColor;

my %DEFINES = ();

sub parse_defines()
{
   Die("wrong commandline options")
     if ( !GetOptions( "defines=s" => \%DEFINES ) );
}

sub cpy_file($$)
{
   my $src_file = shift;
   my $des_file = shift;

   my $des_dir = dirname($des_file);
   make_path($des_dir)
     if ( !-d $des_dir );
   Die("copy '$src_file' -> '$des_file' failed!")
     if ( !copy( $src_file, $des_file ) );
}

sub git_timestamp_from_dirs($)
{
   my $dirs = shift || [];

   print Dumper($dirs);

   my $ts;
   if ( $dirs && @$dirs )
   {
      foreach my $dir (@$dirs)
      {
         chomp( my $ts_new = `git log --pretty=format:%ct -1 '$dir'` );
         Die("failed to get git timestamp from $dir")
            if(! defined $ts_new);
         $ts = $ts_new
           if ( !defined $ts || $ts_new > $ts );
      }
   }

   return $ts;
}


my %PKG_GRAPH = (
   "zimbra-mbox-webclient-war" => {
      summary    => "Zimbra WebClient War",
      version    => "1.0.0",
      revision   => 1,
      hard_deps  => [],
      soft_deps  => [],
      other_deps => ["zimbra-store-components"],
      replaces   => ["zimbra-store"],
      file_list  => ['/opt/zimbra/*'],
      stage_fun  => sub { &stage_zimbra_mbox_webclient_war(@_); },
   },
   "zimbra-mbox-admin-common" => {
      summary    => "Zimbra Admin Common",
      version    => "1.0.0",
      revision   => 1,
      hard_deps  => [],
      soft_deps  => [],
      other_deps => ["zimbra-store-components"],
      replaces   => ["zimbra-store, zimbra-mbox-admin-console-war"],
      file_list  => ['/opt/zimbra/*'],
      stage_fun  => sub { &stage_zimbra_mbox_admin_common(@_); },
   },

);


sub stage_zimbra_mbox_webclient_war($)
{
   my $stage_base_dir = shift;
   make_path("$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbra");
   make_path("$stage_base_dir/opt/zimbra/jetty_base/work");
   make_path("$stage_base_dir/opt/zimbra/conf/templates");
   System("cd $stage_base_dir/opt/zimbra/jetty_base/webapps/zimbra && jar -xf @{[getcwd()]}/build/dist/jetty/webapps/zimbra.war");
   System("cp -r WebRoot/templates $stage_base_dir/opt/zimbra/conf/");
   System("cp -r @{[getcwd()]}/build/dist/jetty/work $stage_base_dir/opt/zimbra/jetty_base/");
   cpy_file( "WebRoot/WEB-INF/jetty-env.xml", "$stage_base_dir/opt/zimbra/jetty_base/etc/zimbra-jetty-env.xml.in");
   System("cat build/WebRoot/WEB-INF/web.xml | sed -e '/REDIRECTBEGIN/ s/\$/ %%comment VAR:zimbraMailMode,-->,redirect%%/' -e '/REDIRECTEND/ s/^/%%comment VAR:zimbraMailMode,<!--,redirect%% /' > $stage_base_dir/opt/zimbra/jetty_base/etc/zimbra.web.xml.in");   
   return ["."];
}
sub stage_zimbra_mbox_admin_common($)
{
   my $stage_base_dir = shift;
   make_path("$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/img");
   make_path("$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/templates/abook");
   make_path("$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/templates/calendar");
   make_path("$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/WEB-INF/classes/messages");
   System("cp -f -r WebRoot/img/animated $stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/img/");
   System("cp -f -r WebRoot/img/dwt $stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/img/");
   cpy_file("build/WebRoot/img/arrows.png", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/img");
   cpy_file("build/WebRoot/img/deprecated.gif", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/img");
   cpy_file("build/WebRoot/img/deprecated2.gif", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/img");
   cpy_file("build/WebRoot/img/deprecated3.gif", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/img");
   cpy_file("build/WebRoot/img/docelements.gif", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/img");
   cpy_file("build/WebRoot/img/docquicktables.gif", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/img");
   cpy_file("build/WebRoot/img/dwt.gif", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/img");
   cpy_file("build/WebRoot/img/dwt.png", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/img");
   cpy_file("build/WebRoot/img/flags.png", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/img");
   cpy_file("build/WebRoot/img/large.png", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/img");
   cpy_file("build/WebRoot/img/mail.png", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/img");
   cpy_file("build/WebRoot/img/oauth.png", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/img");
   cpy_file("build/WebRoot/img/offline.gif", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/img");
   cpy_file("build/WebRoot/img/offline.png", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/img");
   cpy_file("build/WebRoot/img/offline2.gif", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/img");
   cpy_file("build/WebRoot/img/partners.png", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/img");
   cpy_file("build/WebRoot/img/startup.png", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/img");
   cpy_file("build/WebRoot/img/table.png", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/img");
   cpy_file("build/WebRoot/img/voicemail.gif", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/img");
   cpy_file("build/WebRoot/img/voicemail.png", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/img");
   cpy_file("build/WebRoot/public/jsp/TinyMCE.jsp", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/public/jsp/TinyMCE.jsp");
   cpy_file("build/WebRoot/public/jsp/XForms.jsp", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/public/jsp/XForms.jsp");
   cpy_file("WebRoot/public/access.jsp", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/public/");
   cpy_file("WebRoot/public/authorize.jsp", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/public/");
   cpy_file("WebRoot/public/launchSidebar.jsp", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/public/");
   cpy_file("WebRoot/public/setResourceBundle.jsp", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/public/");
   cpy_file("WebRoot/public/TwoFactorSetup.jsp", "$stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/public/");
   System("cp -f -r WebRoot/public/proto $stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/public/");
   System("cp -f -r WebRoot/public/flash $stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/public/");
   System("cp -f -r WebRoot/public/sounds $stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/public/");
   System("cp -f -r WebRoot/public/tmp $stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/public/");
   System("cp -f build/WebRoot/templates/abook/*.properties $stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/templates/abook/");
   System("cp -f build/WebRoot/templates/calendar/*.properties $stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/templates/calendar/");
   System("cp -f WebRoot/messages/Z*.* $stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/WEB-INF/classes/messages/");
   System("cp -f WebRoot/messages/A*.* $stage_base_dir/opt/zimbra/jetty_base/webapps/zimbraAdmin/WEB-INF/classes/messages/");
   return ["."];
}



sub make_package($)
{
   my $pkg_name = shift;

   my $pkg_info = $PKG_GRAPH{$pkg_name};

   print Dumper($pkg_info);

   my $stage_fun = $pkg_info->{stage_fun};

   my $stage_base_dir = "build/stage/$pkg_name";

   make_path($stage_base_dir) if ( !-d $stage_base_dir );

   my $timestamp = git_timestamp_from_dirs( &$stage_fun($stage_base_dir) );

   $pkg_info->{_version_ts} = $pkg_info->{version} . ( $timestamp ? ( "." . $timestamp ) : "" );

   my @cmd = (
      "../zm-pkg-tool/pkg-build.pl",
      "--out-type=binary",
      "--pkg-name=$pkg_name",
      "--pkg-version=$pkg_info->{_version_ts}",
      "--pkg-release=$pkg_info->{revision}",
      "--pkg-summary=$pkg_info->{summary}",
      "--pkg-install=/opt/zimbra/*"
   );

   push( @cmd, @{ [ map { "--pkg-replaces=$_"; } @{ $pkg_info->{replaces} } ] } )                                                              if ( $pkg_info->{replaces} );
   push( @cmd, @{ [ map { "--pkg-depends=$_"; } @{ $pkg_info->{other_deps} } ] } )                                                             if ( $pkg_info->{other_deps} );
   push( @cmd, @{ [ map { "--pkg-depends=$_ (>= $PKG_GRAPH{$_}->{version})"; } @{ $pkg_info->{soft_deps} } ] } )                               if ( $pkg_info->{soft_deps} );
   push( @cmd, @{ [ map { "--pkg-depends=$_ (= $PKG_GRAPH{$_}->{_version_ts}-$PKG_GRAPH{$_}->{revision})"; } @{ $pkg_info->{hard_deps} } ] } ) if ( $pkg_info->{hard_deps} );

   System(@cmd);
}

sub depth_first_traverse_package($)
{
   my $pkg_name = shift;

   my $pkg_info = $PKG_GRAPH{$pkg_name} || Die("package configuration error: '$pkg_name' not found");

   return
     if ( $pkg_info->{_state} && $pkg_info->{_state} eq "BUILT" );

   Die("dependency loop detected...")
     if ( $pkg_info->{_state} && $pkg_info->{_state} eq "BUILDING" );

   $pkg_info->{_state} = 'BUILDING';

   foreach my $dep_pkg_name ( ( sort @{ $pkg_info->{hard_deps} }, sort @{ $pkg_info->{soft_deps} } ) )
   {
      depth_first_traverse_package($dep_pkg_name);
   }

   make_package($pkg_name);

   $pkg_info->{_state} = 'BUILT';
}

sub main
{
   parse_defines();

   # cleanup
   system( "rm", "-rf", "build/stage" );

   foreach my $pkg_name ( sort keys %PKG_GRAPH )
   {
      depth_first_traverse_package($pkg_name);
   }
}

sub System(@)
{
   my $cmd_str = "@_";

   print color('green') . "#: pwd=@{[Cwd::getcwd()]}" . color('reset') . "\n";
   print color('green') . "#: $cmd_str" . color('reset') . "\n";

   $! = 0;
   my ( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) = run( command => \@_, verbose => 1 );

   Die( "cmd='$cmd_str'", $error_message )
     if ( !$success );

   return { msg => $error_message, out => $stdout_buf, err => $stderr_buf };
}

sub Run(%)
{
   my %args  = (@_);
   my $chdir = $args{cd};
   my $child = $args{child};

   my $child_pid = fork();

   Die("FAILURE while forking")
     if ( !defined $child_pid );

   if ( $child_pid != 0 )    # parent
   {
      local $?;

      while ( waitpid( $child_pid, 0 ) == -1 ) { }

      Die( "child $child_pid died", einfo($?) )
        if ( $? != 0 );
   }
   else
   {
      Die( "chdir to '$chdir' failed", einfo($?) )
        if ( $chdir && !chdir($chdir) );

      $! = 0;
      &$child;
      exit(0);
   }
}

sub einfo()
{
   my @SIG_NAME = split( / /, $Config{sig_name} );

   return "ret=" . ( $? >> 8 ) . ( ( $? & 127 ) ? ", sig=SIG" . $SIG_NAME[ $? & 127 ] : "" );
}

sub Die($;$)
{
   my $msg  = shift;
   my $info = shift || "";
   my $err  = "$!";

   print "\n";
   print "\n";
   print "=========================================================================================================\n";
   print color('red') . "FAILURE MSG" . color('reset') . " : $msg\n";
   print color('red') . "SYSTEM ERR " . color('reset') . " : $err\n"  if ($err);
   print color('red') . "EXTRA INFO " . color('reset') . " : $info\n" if ($info);
   print "\n";
   print "=========================================================================================================\n";
   print color('red');
   print "--Stack Trace--\n";
   my $i = 1;

   while ( ( my @call_details = ( caller( $i++ ) ) ) )
   {
      print $call_details[1] . ":" . $call_details[2] . " called from " . $call_details[3] . "\n";
   }
   print color('reset');
   print "\n";
   print "=========================================================================================================\n";

   die "END";
}

##############################################################################################

main();
