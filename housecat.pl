#!/usr/bin/perl
use strict;

###################################################################################################################################
use SDL; 
use SDL::Video; 
use SDLx::App; 
use SDL::Surface; 
use SDL::Rect; 
use SDL::Image; 
use SDL::Event; 
use SDL::Mouse;
use SDLx::Sound;
use SDL::Cursor; 
use SDLx::Text;
use SDL::GFX::Rotozoom;
use SDLx::Music;
use SDL::Time;
use Time::HiRes;

use constant backgroundRefreshCounter=>1;
use constant repeatDuration => 50;
use constant everyDuration => 100;
use constant catstartX => 960;
use constant catstartY => 470;
use constant screenWidth => 1350;
use constant screenHeight => 600;
my $time = 0;
my $calc = 1;
my $catX_min = -10;
my $catX_max = 1200;
my $catcounter = 1;
my $application = 'housecat.pl';
my ($catX, $catY, $catY_max, $catY_min, $app, $old_cat_x, $old_cat_y, $catMaster,$application, $background, $background_rect, $event, $exiting, $cover_rect, $backgroundRect);
my ($title_screen, $text_box, $text_box_01, $filename, $filename2, $background, $cover, $screenHeight, $screenWidth, $background_Rect);
my $granularity = 30;
$catX = catstartX;
$catY = catstartY;
############################MUSIC######################################################################################################
my $music = SDLx::Music->new();
$music->data(music => 'Audio/Music/603041_Dig-It.ogg');
$music->play($music->data('music'), loops => 0);

##########################Images#######################################################################################################





$app = SDLx::App->new(
  title  => "House Cat",
  width  => screenWidth, # use same width as background image  # 1350/3 = 450
  height => screenHeight, # use same height as background image
  depth  => 16,
  exit_on_quit => 1, # Enable 'X' button
  dt => 1.0, # units: sec - duration of one game loop
  delay=>10, # units: ms - delay between game loop iterations
);

#Calling in splash screen (splash screen not working)
$app->add_show_handler(\&showSplashScreen);

SDL::Events::enable_key_repeat(repeatDuration, everyDuration);


#Background
$filename = "Images/background.png";
$filename2 = "Images/background2.png";
$background = SDL::Image::load( $filename);
$cover = $background;
$backgroundRect = SDL::Rect->new(0,0,$background->w,$background->h);
$screenWidth=$background->w;
$screenHeight=$background->h;
my $backgroundRefresh=backgroundRefreshCounter;
my $bkgrndX=0;
my $bkgrndY=0;
my $rectVisible=SDL::Rect->new($bkgrndX,$bkgrndY,screenWidth,screenHeight);

# scores:
my ($printedTime, $scoreBanner, $scoreMaster, $scoreRect, $scoreText, @scoreDigits);
$filename = "Images/ScoreBanner.png";
$scoreBanner = SDL::Image::load( $filename);
$scoreMaster=SDL::Rect->new(0,0, $scoreBanner->w,$scoreBanner->h);
# a text box for the score
$scoreText = SDLx::Text->new(size=>'48',
                            font=>'font/LCD_Solid.ttf',# font can also be specified
                            color=>[000,000,000], # [R,G,B]
                            x =>165,
                            y=> 20);
$printedTime=0;
$scoreText->write_to($app,"$printedTime");
$scoreRect= SDL::Rect->new(0,0,$scoreBanner->w,$scoreBanner->h);

#Goodguy
my $right =     SDL::Image::load('Images/kittenright.png');
my $left =    SDL::Image::load('Images/kittenleft.png');
my $cat = $left;
my $catRect = SDL::Rect->new($catX,$catY,$cat->w,$cat->h);



SDL::Video::blit_surface($background, $backgroundRect, $app, $backgroundRect);
$app->add_move_handler(\&scoreCalculate);
$app->add_show_handler(\&show_background);
$app->add_show_handler(\&showGoodGuy);
$app->add_show_handler(\&scoreUpdate);
$app->add_event_handler(\&key_event);
$app->add_event_handler(\&mouse_event);

$app->add_show_handler(sub{$app->sync()});

$app->run;

#############################SUBROUTINES###############################################################################################
sub mouse_event {
  my ($event, $app) = @_;
  my ($mouse_mask,$mouse_x,$mouse_y)  = @{SDL::Events::get_mouse_state()};
  my ($r, $g, $b, $pixel, $hex); 
  if ($mouse_mask & SDL_BUTTON_LMASK) {
    # left clicked!
    # so get a ppixel at the mouse
    $pixel =SDL::Surface::get_pixel($app, $background->w*$mouse_y+$mouse_x);
    # convert it to RGB (5:6:?)
    ($r, $g, $b) = @{SDL::Video::get_RGB($app->format(), $pixel)};
    # show those values
    print "R[$r] G[$g] B[$b]\n";
    print "Decimal[$pixel]\n";
    # get a Hexadecimal representation
    $hex = sprintf("%x",$pixel);
    # and show it
    print "Hex[$hex]\n";
  }
}
###########################(NOT WORKING)#########################################
# routine is called with name of program valriable, image to
# display, and for how long in seconds
# showSplashScreen ($application, 'title_screen.jpg', 2);
# showSplashScreen ($application, 'hero.jpg', 2);
# showSplashScreen ($application, 'intro.jpg', 2);


sub showSplashScreen {
  use Time::HiRes; # needed for usleep
  # must pass in the variable in which the program is stored
  my $program=shift;
  # must pass in an image file name
  my $imageFile=shift;
  # How long to sleep, in seconds
  my $howlong=shift;
  my ($image);
  # avoid some errors by testing for file existance
  if (-e $imageFile) {
    $image = SDL::Image::load($imageFile);
  }
  else {
    return "Error: Image file not found."; # 
  }
  # this code will always try to display top left at 0,0
  my $imageRect = SDL::Rect->new(0,0, $image->w, $image->h);
  # put it on screen
  SDL::Video::blit_surface($image, $imageRect, $program, $imageRect );
  # swap video buffers as required
  SDL::Video::update_rects($program, $imageRect);
  # convert seconds to millseconds, allows for decimal part
  $howlong *= 1000;
  usleep ($howlong);
  return 0;
}
################################################################
sub show_background {
  my ($delta, $app) = @_;
  $backgroundRefresh--;
  if ($backgroundRefresh == 0) {
    SDL::Video::blit_surface($background, $backgroundRect, $app, $backgroundRect);
    $backgroundRefresh=backgroundRefreshCounter;
  }
}  
 
sub key_event {
  my ($event, $app) = @_;
  my $key_name = SDL::Events::get_key_name( $event->key_sym );  
  my ( $new_ship_rect, $coverRect);
  if (($key_name eq "x") || ($key_name eq "X") ) {
    $app->stop;
  }
  elsif ($key_name eq "left") {  
    print "L($catX, $catY)\n";
    $cat=$left;
    $catX -=$granularity;
    if ($catX < $catX_min) {
      $catX = $catX_min;
    }
  }
  elsif ($key_name eq "right") {
    print "R($catX, $catY)\n";
    $cat=$right;
    $catX +=$granularity;
    if ($catX > $catX_max) {
      $catX = $catX_max;
    }
  }
  elsif ($key_name eq "up") {
    print "U($catX, $catY)\n";
    $catY -=$granularity;
    if ($catY < $catY_min) {
      $catY = $catY_min;
    }
  }
  elsif ($key_name eq "down") {
    print "D($catX, $catY)\n";
    $catY +=$granularity;
    if ($catY < $catY_max) {
      $catY = $catY_max;
    }
  }
  elsif (($key_name eq "space")){
    $filename = 'Images/background2.png';
    $background = SDL::Image::load( $filename);
    $cover = $background;
    $backgroundRect = SDL::Rect->new(0,0,$background->w,$background->h);
    $screenWidth=$background->w;
    $screenHeight=$background->h;
    my $backgroundRefresh=backgroundRefreshCounter;
  }
}
# This is the part that need attention, I cant get the printed time to slow down.
sub scoreCalculate {
    $time++;
    if ($time = 40) {
      $printedTime += 1;
      $time = 0;
  }
}

sub scoreUpdate {
  my ($delta, $app) = @_;
  SDL::Video::blit_surface ( $scoreBanner, $scoreMaster, $app, $scoreRect);
  $scoreText->write_to($app, $printedTime);
}

sub showGoodGuy {
  my ($delta, $app) = @_;
  my ($new_cat_rect, $coverRect);
  $coverRect = SDL::Rect->new($old_cat_x, $old_cat_y, $cat->w, $cat->h);
  $new_cat_rect = SDL::Rect->new($catX,$catY,$cat->w,$cat->h);
  SDL::Video::blit_surface( $cover, $coverRect, $app, $coverRect );
  SDL::Video::blit_surface ( $cat, $catMaster, $app, $new_cat_rect);
}
