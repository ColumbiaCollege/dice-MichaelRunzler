import java.util.Random;
import java.awt.event.KeyEvent;
import java.util.Locale;

Random rng;
PImage die;

final color BG_COLOR = color(128);
final color DICE_COLOR = color(0);
final color NUMBER_COLOR = color(0, 255, 255);
final color HELP_TEXT_COLOR = color(0);

static final String HELP_TEXT_BASE = "# of sides: %d\n# of dice: %d\nPress F1 to show controls.";
static final String ADV_HELP_TEXT = "Use the mousewheel to adjust the number of sides per die.\n" +
                  "Use the up/down arrow keys to adjust the number of dice.\n" +
                  "Right-click or press F1 to hide this help message.";
                  
static final int MIN_CANVAS_SIZE = 360;
static final int DIE_SIZE = 250;
static final int INTER_DIE_GAP = DIE_SIZE / 10;
static final int MAX_DIE_SIDES = Integer.MAX_VALUE;
static final int MIN_DIE_SIDES = 4;
static final int MAX_DIE_COUNT = 10;
static final int MIN_DIE_COUNT = 1;
static final int DIE_Y_COORD = 100;
static final int HELP_TEXT_HEIGHT = DIE_Y_COORD - INTER_DIE_GAP;

int currentSides = MIN_DIE_SIDES; // User cannot set fewer than this many sides per die
int currentCount = MIN_DIE_COUNT; // User cannot use fewer than this many dice

// State flags used by the rest of the program
boolean showHelp = false;
boolean firePreDraw = false;
boolean fireReRoll = false;

void setup()
{
  // Set canvas size and background color
  size(480,480);
  background(BG_COLOR);
  
  // Enable dynamic runtime resizing of the canvas and window
  surface.setResizable(true);
  
  // Initialize the pseudorandom generator and seed it with the current time
  rng = new Random(System.currentTimeMillis());
  
  // Load die image from data folder
  die = loadImage("die.png");
  
  // Turn off outline drawing
  noStroke();
  
  // Size window to proper width/height to fit contents
  autosize();
 
  // Delay initial display of the help interface to give the background elements time to finish drawing.
  // Must be done on a separate thread to allow the rest of the program to continue initializing in the background.
  new Thread(){
    public void run(){
      try{
        // Set the draw flag for the on-screen help interface as soon as the timer expires, it will be drawn on the next draw phase
        Thread.sleep(100);
        firePreDraw = true;
      }catch(InterruptedException e){
        e.printStackTrace();
      }
    }
  }.start();
}

void draw()
{
  // Draw the help interface and initial die once the draw flag is set by the timer thread, then reset the flag.
  if(firePreDraw){
    generateHelpMsg();
    roll(MIN_DIE_COUNT, MIN_DIE_SIDES);
    firePreDraw = false;
  }
  
  // If the size changed during the roll stage, fire the roll routine 
  if(fireReRoll){
    roll(currentCount, currentSides);
    fireReRoll = false;
  }
  
  // The draw loop will do nothing except listen for key and mouse events after the above event(s) are fired.
}

/**
 * Rolls the number and size of dice specified in the arguments.
 * May chain-call by way of a daemon thread back to the main loop, do not separate from the
 * rest of the program!
 */
void roll(int num, int sides)
{
  // Cache the current window dimensions and call autosize
  int prevDim = width + height;
  autosize();
  
  // If the window has been resized, we need to wait until the redraw is complete WITHOUT freezing the main thread
  if(prevDim != (width + height))
  {
    // Delegate to a daemon timer thread, and have it set the reroll flag when it completes
    new Thread(){
      public void run()
      {
        try{ Thread.sleep(500); }catch(InterruptedException ignored){}
        println("Resize complete, rerolling...");
        fireReRoll = true;
      }
    }.start();
    
    // Exit this method call and wait for the flag to trigger another roll
    return;
  }else{
    // Clear the screen in preparation for redrawing if the canvas is already the proper size
    clearScreen();
  }
  
  // If the canvas is the proper size, continue and draw as many dice as we need
  int offset = INTER_DIE_GAP;
  for(int i = 0; i < num; i++){
    drawDie(offset, sides);
    offset += DIE_SIZE + INTER_DIE_GAP;
  }
  
  // Since the canvas will have been cleared, regenerate the other UI elements
  generateHelpMsg();
  updateAdvHelp();
}

/**
 * Draws a single die with the specified number of sides at the specified X-offset.
 */
void drawDie(int offset, int sides)
{
  // Tint and draw the die image
  tint(DICE_COLOR);
  image(die, offset, DIE_Y_COORD, DIE_SIZE, DIE_SIZE);
  
  // Generate the value for the die, then set the text side, color, alignment, and draw mode
  int i = rng.nextInt(sides) + 1;
  textSize(36);
  textAlign(CENTER, CENTER);
  fill(NUMBER_COLOR);
  rectMode(CENTER);
  
  // Draw the text and reset the draw mode to its default
  text("" + i, offset + (int)(DIE_SIZE / 2), DIE_Y_COORD + (int)(DIE_SIZE / 2));
  rectMode(CORNER);
}

/**
 * Resizes the current canvas to the minimum size required to display the currently
 * set number of dice and associated text. Takes a few dozen milliseconds to complete the refresh,
 * during which time the canvas is cleared. Any further draw operations should be postponed until
 * this refresh is complete.
 */
void autosize()
{
  // Calculate the needed X and Y sizes
  int calcSizeX = (DIE_SIZE * currentCount) + (INTER_DIE_GAP * (currentCount + 1));
  calcSizeX  = calcSizeX < MIN_CANVAS_SIZE ? MIN_CANVAS_SIZE : calcSizeX;
  
  int calcSizeY = ((HELP_TEXT_HEIGHT + INTER_DIE_GAP) * 2) + DIE_SIZE;
  
  // Only resize the canvas if one or both of the required dimensions are different from their current values
  if(calcSizeX != width || calcSizeY != height) {
    println(String.format("Resizing from %d,%d to %d,%d, please wait!", width, height, calcSizeX, calcSizeY));
    surface.setSize(calcSizeX, calcSizeY);
  }
}

void generateHelpMsg()
{  
  // Overwrite the current help text with a rectangle of equivalent size, and match it to the background color
  fill(BG_COLOR);
  rect(0, 0, width, HELP_TEXT_HEIGHT);
  
  // Set text size, alignment, and color, and display the help text
  fill(HELP_TEXT_COLOR);
  textSize(12);
  textAlign(LEFT, TOP);
  text(String.format(Locale.ENGLISH, HELP_TEXT_BASE, currentSides, currentCount), 0, 0, width, HELP_TEXT_HEIGHT);
}

void clearScreen(){
  background(BG_COLOR);
}

void updateAdvHelp()
{
  // If the advanced help message should be showing, display it. Otherwise, overwrite it with an
  // appropriately sized and colored rectangle.
  if(showHelp){
    fill(HELP_TEXT_COLOR);
    textSize(12);
    textAlign(LEFT, BOTTOM);
    text(ADV_HELP_TEXT, 0, height - HELP_TEXT_HEIGHT, width, HELP_TEXT_HEIGHT);
  }else{
    fill(BG_COLOR);
    rect(0, height - HELP_TEXT_HEIGHT, width, HELP_TEXT_HEIGHT); 
  }
}

void mouseClicked()
{
  // When the mouse is clicked, check which button it is. If it is the left
  // button, roll the dice with the current settings. If it is the right button,
  // hide the advanced help if it is showing. If it is any other button, ignore it.
  if(mouseButton == LEFT) roll(currentCount, currentSides);
  else if(mouseButton == RIGHT){
    showHelp = false;
    updateAdvHelp();
  }
}

void mouseWheel(MouseEvent event)
{
  // Increment or decrement the die side counter depending on the direction of the scroll
  if(event.getCount() > 0) currentSides --;
  else if(event.getCount() < 0) currentSides ++;
  
  // Make sure the side count is still within the bounds of the side limiters
  currentSides = currentSides > MAX_DIE_SIDES ? MAX_DIE_SIDES : currentSides;
  currentSides = currentSides < MIN_DIE_SIDES ? MIN_DIE_SIDES : currentSides;
  
  // Update the help status message to account for the change
  generateHelpMsg();
}

void keyPressed()
{ 
  // Evaluate which key code has been pressed:
  switch(keyCode)
  {
    // If the key is the up or down arrow, increment or decrement the die count value
    case KeyEvent.VK_UP:
      currentCount ++;
    break;
    
    case KeyEvent.VK_DOWN:
      currentCount --;
    break;
    
    // If the key is the F1 key, toggle the advanced help display and update it
    case KeyEvent.VK_F1:
      showHelp = !showHelp;
      updateAdvHelp();
    break;
    
    // THIS SHOULD NEVER HAPPEN
    case KeyEvent.VK_F24:
      boolean bg_select = false;
      while(true){
        background(bg_select ? color(255, 0, 255) : color(255, 255, 0));
        text("EVERYTHING WENT WRONG OH GOD PLEASE SEND HELP", width / 2, height / 2, 400, 400);
        try{ Thread.sleep(500); }catch(InterruptedException ignored) {}
      }
  }
  
  // Make sure the die count is still within the bounds of the count limiters
  currentCount = currentCount > MAX_DIE_COUNT ? MAX_DIE_COUNT : currentCount;
  currentCount = currentCount < MIN_DIE_COUNT ? MIN_DIE_COUNT : currentCount;
  
  // Update the help status message to account for the change
  generateHelpMsg();
}
